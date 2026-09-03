const std = @import("std");
const stream_provider = @import("../core/agent/stream_provider.zig");
const types = @import("../core/shared/types.zig");
const model_tool_schema = @import("../core/tooling/model_tool_schema.zig");
const io_mod = @import("../core/shared/io.zig");

const Allocator = std.mem.Allocator;
const max_sse_event_bytes = 256 * 1024;

pub const default_model = "deepseek-v4-flash";
pub const default_chat_url = "https://api.deepseek.com/chat/completions";
pub const base_url_env = "DEEPSEEK_BASE_URL";
const chat_path = "/chat/completions";
var endpoint_buffer: [2048]u8 = undefined;

pub fn agentChatUrl() []const u8 {
    const base_url = io_mod.getenv(base_url_env) orelse return default_chat_url;
    return resolveChatUrl(base_url, &endpoint_buffer) orelse default_chat_url;
}

pub fn resolveChatUrl(base_url: []const u8, out: []u8) ?[]const u8 {
    if (base_url.len == 0) return null;
    const uri = std.Uri.parse(base_url) catch return null;
    if (!std.ascii.eqlIgnoreCase(uri.scheme, "https") or uri.host == null or
        uri.user != null or uri.password != null or uri.query != null or
        uri.fragment != null)
    {
        return null;
    }
    const trimmed = std.mem.trimEnd(u8, base_url, "/");
    return std.fmt.bufPrint(out, "{s}{s}", .{ trimmed, chat_path }) catch null;
}

pub fn buildAgentRequest(
    alloc: Allocator,
    request: stream_provider.RequestData,
) anyerror![]u8 {
    if (request.budget) |budget| {
        if (budget.cancel_flag) |flag| if (flag.load(.seq_cst)) return error.Cancelled;
    }
    if (request.verified_images != null or request.response_format != null or
        request.vision_mode == .required)
    {
        return error.UnsupportedDeepSeekRequest;
    }

    var out: std.Io.Writer.Allocating = .init(alloc);
    defer out.deinit();
    try out.writer.writeAll("{\"model\":");
    try std.json.Stringify.value(request.model, .{}, &out.writer);
    try out.writer.writeAll(",\"messages\":[");
    for (request.messages, 0..) |message, index| {
        if (index > 0) try out.writer.writeByte(',');
        try writeMessage(alloc, &out.writer, message);
    }
    try out.writer.writeAll("],\"stream\":true,\"stream_options\":{\"include_usage\":true},\"thinking\":{\"type\":\"enabled\"},\"reasoning_effort\":\"high\"");
    try out.writer.writeAll(",\"tools\":[");
    var tool_count: usize = 0;

    for (request.tools.advertised_names) |name| {
        if (tool_count > 0) try out.writer.writeByte(',');
        const schema = request.tools.advertisedFunction(name) orelse blk: {
            const tool = request.tools.registry.lookup(name) orelse
                return error.AdvertisedToolNotRegistered;
            break :blk tool.model_schema;
        };
        try writeOpenAiTool(alloc, &out.writer, schema);
        tool_count += 1;
    }
    for (request.tools.additional_functions) |schema| {
        if (toolNameSelected(request.tools.advertised_names, schema.name)) continue;
        if (tool_count > 0) try out.writer.writeByte(',');
        try writeOpenAiTool(alloc, &out.writer, schema);
        tool_count += 1;
    }
    for (request.tools.selected_dynamic) |tool| {
        if (toolNameSelected(request.tools.advertised_names, tool.name)) continue;
        if (tool_count > 0) try out.writer.writeByte(',');
        try writeOpenAiDynamicTool(&out.writer, tool);
        tool_count += 1;
    }
    try out.writer.writeByte(']');
    if (tool_count > 0) {
        try out.writer.writeAll(",\"tool_choice\":");
        try std.json.Stringify.value(request.tool_choice.label(), .{}, &out.writer);
    }
    if (request.max_output_tokens) |value| try out.writer.print(",\"max_tokens\":{d}", .{value});
    try out.writer.writeByte('}');
    return out.toOwnedSlice();
}

fn writeMessage(alloc: Allocator, writer: *std.Io.Writer, message: types.ChatMessage) !void {
    try writer.writeAll("{\"role\":");
    try std.json.Stringify.value(@tagName(message.role), .{}, writer);
    try writer.writeAll(",\"content\":");
    if (message.content) |content| try std.json.Stringify.value(content, .{}, writer) else try writer.writeAll("null");

    if (message.role == .assistant and message.tool_calls.len > 0) {
        try writeReasoningState(alloc, writer, message.provider_state_json);
        try writer.writeAll(",\"tool_calls\":[");
        for (message.tool_calls, 0..) |call, index| {
            if (index > 0) try writer.writeByte(',');
            try writer.writeAll("{\"id\":");
            try std.json.Stringify.value(call.id, .{}, writer);
            try writer.writeAll(",\"type\":\"function\",\"function\":{\"name\":");
            try std.json.Stringify.value(call.name, .{}, writer);
            try writer.writeAll(",\"arguments\":");
            try std.json.Stringify.value(call.arguments_json, .{}, writer);
            try writer.writeAll("}}");
        }
        try writer.writeByte(']');
    }
    if (message.role == .tool) {
        try writer.writeAll(",\"tool_call_id\":");
        try std.json.Stringify.value(message.tool_call_id orelse "", .{}, writer);
    }
    try writer.writeByte('}');
}

fn writeReasoningState(alloc: Allocator, writer: *std.Io.Writer, state_json: ?[]const u8) !void {
    const state = state_json orelse return;
    var parsed = std.json.parseFromSlice(std.json.Value, alloc, state, .{}) catch return;
    defer parsed.deinit();
    if (parsed.value != .array or parsed.value.array.items.len != 1) return;
    const record = parsed.value.array.items[0];
    if (record != .object) return;
    const kind = record.object.get("type") orelse return;
    const reasoning = record.object.get("reasoning_content") orelse return;
    if (kind != .string or reasoning != .string or
        !std.mem.eql(u8, kind.string, "deepseek_reasoning")) return;
    try writer.writeAll(",\"reasoning_content\":");
    try std.json.Stringify.value(reasoning.string, .{}, writer);
}

fn writeOpenAiTool(
    alloc: Allocator,
    writer: *std.Io.Writer,
    schema: model_tool_schema.FunctionSchema,
) !void {
    try writer.writeAll("{\"type\":\"function\",\"function\":{\"name\":");
    try std.json.Stringify.value(schema.name, .{}, writer);
    try writer.writeAll(",\"description\":");
    try model_tool_schema.writeCappedDescriptionJsonString(alloc, writer, schema.description);
    try writer.writeAll(",\"parameters\":");
    try model_tool_schema.writeObjectSchema(alloc, writer, schema.input_schema);
    try writer.writeAll("}}");
}

fn writeOpenAiDynamicTool(
    writer: *std.Io.Writer,
    tool: stream_provider.DynamicFunctionTool,
) !void {
    try writer.writeAll("{\"type\":\"function\",\"function\":{\"name\":");
    try std.json.Stringify.value(tool.name, .{}, writer);
    try writer.writeAll(",\"description\":");
    try std.json.Stringify.value(tool.description, .{}, writer);
    try writer.writeAll(",\"parameters\":");
    try std.json.Stringify.value(tool.input_schema, .{}, writer);
    try writer.writeAll("}}");
}

fn toolNameSelected(names: []const []const u8, expected: []const u8) bool {
    for (names) |name| if (std.mem.eql(u8, name, expected)) return true;
    return false;
}

pub const ToolAccumulator = struct {
    id: std.ArrayList(u8) = .empty,
    name: std.ArrayList(u8) = .empty,
    arguments: std.ArrayList(u8) = .empty,
    started: bool = false,

    fn deinit(self: *ToolAccumulator, alloc: Allocator) void {
        self.id.deinit(alloc);
        self.name.deinit(alloc);
        self.arguments.deinit(alloc);
    }
};

pub const StreamAccumulator = struct {
    content: std.ArrayList(u8) = .empty,
    reasoning: std.ArrayList(u8) = .empty,
    generation_id: std.ArrayList(u8) = .empty,
    tools: std.ArrayList(ToolAccumulator) = .empty,
    finish_reason: ?types.ProviderFinishReason = null,
    usage: types.Usage = .{},

    pub fn deinit(self: *StreamAccumulator, alloc: Allocator) void {
        self.content.deinit(alloc);
        self.reasoning.deinit(alloc);
        self.generation_id.deinit(alloc);
        for (self.tools.items) |*tool| tool.deinit(alloc);
        self.tools.deinit(alloc);
    }
};

pub fn consumeChunk(
    alloc: Allocator,
    accumulator: *StreamAccumulator,
    json_text: []const u8,
    callback_ctx: *anyopaque,
    on_content_chunk: stream_provider.StreamCallback,
    on_tool_start: ?stream_provider.ToolStartCallback,
    on_reasoning_chunk: ?stream_provider.StreamCallback,
    on_tool_input_chunk: ?stream_provider.StreamCallback,
) !void {
    var parsed = try std.json.parseFromSlice(std.json.Value, alloc, json_text, .{});
    defer parsed.deinit();
    if (parsed.value != .object) return;
    if (accumulator.generation_id.items.len == 0) {
        if (parsed.value.object.get("id")) |id| {
            if (id == .string and id.string.len > 0)
                try accumulator.generation_id.appendSlice(alloc, id.string);
        }
    }
    if (parsed.value.object.get("usage")) |usage| consumeUsage(accumulator, usage);
    const choices = parsed.value.object.get("choices") orelse return;
    if (choices != .array or choices.array.items.len == 0) return;
    const choice = choices.array.items[0];
    if (choice != .object) return;

    if (choice.object.get("finish_reason")) |finish_value| {
        if (finish_value == .string) accumulator.finish_reason = parseFinishReason(finish_value.string);
    }
    const delta = choice.object.get("delta") orelse return;
    if (delta != .object) return;
    if (delta.object.get("content")) |content| if (content == .string and content.string.len > 0) {
        try accumulator.content.appendSlice(alloc, content.string);
        on_content_chunk(callback_ctx, content.string);
    };
    if (delta.object.get("reasoning_content")) |reasoning| if (reasoning == .string and reasoning.string.len > 0) {
        try accumulator.reasoning.appendSlice(alloc, reasoning.string);
        if (on_reasoning_chunk) |callback| callback(callback_ctx, reasoning.string);
    };
    if (delta.object.get("tool_calls")) |calls| {
        if (calls != .array) return;
        for (calls.array.items) |call| try consumeToolDelta(alloc, accumulator, call, callback_ctx, on_tool_start, on_tool_input_chunk);
    }
}

fn consumeUsage(accumulator: *StreamAccumulator, value: std.json.Value) void {
    if (value != .object) return;
    accumulator.usage.input_tokens = jsonU64(value.object.get("prompt_tokens")) orelse
        jsonU64(value.object.get("input_tokens"));
    accumulator.usage.output_tokens = jsonU64(value.object.get("completion_tokens")) orelse
        jsonU64(value.object.get("output_tokens"));
}

fn jsonU64(value: ?std.json.Value) ?u64 {
    const present = value orelse return null;
    if (present != .integer or present.integer < 0) return null;
    return @intCast(present.integer);
}

fn consumeToolDelta(
    alloc: Allocator,
    accumulator: *StreamAccumulator,
    value: std.json.Value,
    callback_ctx: *anyopaque,
    on_tool_start: ?stream_provider.ToolStartCallback,
    on_tool_input_chunk: ?stream_provider.StreamCallback,
) !void {
    if (value != .object) return;
    const index_value = value.object.get("index") orelse return;
    if (index_value != .integer or index_value.integer < 0) return;
    const index: usize = @intCast(index_value.integer);
    while (accumulator.tools.items.len <= index) try accumulator.tools.append(alloc, .{});
    const target = &accumulator.tools.items[index];
    if (value.object.get("id")) |id| if (id == .string and id.string.len > 0) try target.id.appendSlice(alloc, id.string);
    const function = value.object.get("function") orelse return;
    if (function != .object) return;
    if (function.object.get("name")) |name| if (name == .string and name.string.len > 0) {
        try target.name.appendSlice(alloc, name.string);
        if (!target.started and target.id.items.len > 0) {
            target.started = true;
            if (on_tool_start) |callback| callback(callback_ctx, target.id.items, target.name.items, null);
        }
    };
    if (function.object.get("arguments")) |arguments| if (arguments == .string and arguments.string.len > 0) {
        try target.arguments.appendSlice(alloc, arguments.string);
        if (on_tool_input_chunk) |callback| callback(callback_ctx, arguments.string);
    };
}

fn parseFinishReason(raw: []const u8) types.ProviderFinishReason {
    if (std.mem.eql(u8, raw, "stop")) return .stop;
    if (std.mem.eql(u8, raw, "length")) return .length;
    if (std.mem.eql(u8, raw, "content_filter")) return .content_filter;
    if (std.mem.eql(u8, raw, "tool_calls")) return .tool_calls;
    if (std.mem.eql(u8, raw, "insufficient_system_resource")) return .provider_error;
    return .other;
}

pub fn finish(alloc: Allocator, accumulator: *StreamAccumulator) !types.ModelCompletion {
    var result: types.ModelCompletion = .{
        .finish_reason = accumulator.finish_reason,
        .usage = accumulator.usage,
    };
    errdefer {
        if (result.content) |content| alloc.free(@constCast(content));
        if (result.generation_id) |id| alloc.free(@constCast(id));
        if (result.provider_state_json) |state| alloc.free(@constCast(state));
        types.freeToolCallSlice(alloc, @constCast(result.tool_calls));
    }
    if (accumulator.content.items.len > 0) result.content = try alloc.dupe(u8, accumulator.content.items);
    if (accumulator.generation_id.items.len > 0)
        result.generation_id = try alloc.dupe(u8, accumulator.generation_id.items);
    const calls = try alloc.alloc(types.ToolCall, accumulator.tools.items.len);
    var initialized: usize = 0;
    errdefer {
        for (calls[0..initialized]) |call| {
            alloc.free(@constCast(call.id));
            alloc.free(@constCast(call.name));
            alloc.free(@constCast(call.arguments_json));
        }
        alloc.free(calls);
    }
    for (accumulator.tools.items, 0..) |tool, index| {
        calls[index] = .{
            .id = try alloc.dupe(u8, tool.id.items),
            .name = try alloc.dupe(u8, tool.name.items),
            .arguments_json = try alloc.dupe(u8, if (tool.arguments.items.len > 0) tool.arguments.items else "{}"),
            .argument_integrity = try types.ToolArgumentIntegrity.classifySerialized(alloc, if (tool.arguments.items.len > 0) tool.arguments.items else "{}"),
        };
        initialized += 1;
    }
    if (calls.len > 0 and accumulator.reasoning.items.len > 0)
        result.provider_state_json = try buildReasoningState(alloc, accumulator.reasoning.items);
    result.tool_calls = calls;
    return result;
}

fn buildReasoningState(alloc: Allocator, reasoning: []const u8) ![]u8 {
    var out: std.Io.Writer.Allocating = .init(alloc);
    defer out.deinit();
    try out.writer.writeAll("[{\"type\":\"deepseek_reasoning\",\"reasoning_content\":");
    try std.json.Stringify.value(reasoning, .{}, &out.writer);
    try out.writer.writeAll("}]");
    return out.toOwnedSlice();
}

pub fn consumeDeepSeekSseStream(
    alloc: Allocator,
    reader: *std.Io.Reader,
    callback_ctx: *anyopaque,
    on_content_chunk: stream_provider.StreamCallback,
    on_tool_start: ?stream_provider.ToolStartCallback,
    on_reasoning_chunk: ?stream_provider.StreamCallback,
    cancel_flag: *std.atomic.Value(bool),
    content_capture_limit: ?usize,
) !types.ModelCompletion {
    var accumulator: StreamAccumulator = .{};
    defer accumulator.deinit(alloc);
    var pending: std.ArrayList(u8) = .empty;
    defer pending.deinit(alloc);

    while (!cancel_flag.load(.seq_cst)) {
        const fragment = reader.takeDelimiter('\n') catch |err| switch (err) {
            error.StreamTooLong => {
                const buffered = reader.buffered();
                if (buffered.len == 0 or pending.items.len + buffered.len > max_sse_event_bytes)
                    return error.DeepSeekSseEventTooLarge;
                try pending.appendSlice(alloc, buffered);
                reader.tossBuffered();
                continue;
            },
            error.ReadFailed => return error.ReadFailed,
        } orelse break;

        const line = if (pending.items.len == 0) fragment else line: {
            if (pending.items.len + fragment.len > max_sse_event_bytes) return error.DeepSeekSseEventTooLarge;
            try pending.appendSlice(alloc, fragment);
            break :line pending.items;
        };
        defer pending.clearRetainingCapacity();
        const trimmed = std.mem.trim(u8, line, " \r\t");
        if (!std.mem.startsWith(u8, trimmed, "data:")) continue;
        const data = std.mem.trim(u8, trimmed[5..], " \r\t");
        if (std.mem.eql(u8, data, "[DONE]")) break;
        consumeChunk(
            alloc,
            &accumulator,
            data,
            callback_ctx,
            on_content_chunk,
            on_tool_start,
            on_reasoning_chunk,
            null,
        ) catch |err| switch (err) {
            error.SyntaxError, error.UnexpectedEndOfInput => continue,
            else => return err,
        };
        if (content_capture_limit) |limit| {
            if (accumulator.content.items.len > limit) accumulator.content.shrinkRetainingCapacity(limit);
        }
    }
    if (cancel_flag.load(.seq_cst)) return error.Cancelled;
    return finish(alloc, &accumulator);
}

test "builds OpenAI-compatible DeepSeek request" {
    const messages = [_]types.ChatMessage{.{ .role = .user, .content = "Hello" }};
    const functions = [_]model_tool_schema.FunctionSchema{.{
        .name = "read_file",
        .description = "Read",
        .input_schema = .{
            .properties = &.{.{ .name = "path", .json_type = .string }},
            .required = &.{"path"},
            .additional_properties = false,
        },
    }};
    const names = [_][]const u8{"read_file"};
    const body = try buildAgentRequest(std.testing.allocator, .{
        .model = default_model,
        .messages = &messages,
        .tools = .{
            .advertised_names = &names,
            .advertised_functions = &functions,
        },
        .tool_choice = .auto,
        .provider_options = .{},
    });
    defer std.testing.allocator.free(body);
    try std.testing.expect(std.mem.find(u8, body, "\"messages\"") != null);
    try std.testing.expect(std.mem.find(u8, body, "\"parameters\"") != null);
    try std.testing.expect(std.mem.find(u8, body, "\"thinking\":{\"type\":\"enabled\"}") != null);
    try std.testing.expect(std.mem.find(u8, body, "\"stream_options\":{\"include_usage\":true}") != null);
    try std.testing.expect(std.mem.find(u8, body, "\"prompt\"") == null);
}

test "assembles DeepSeek content reasoning and fragmented tool calls" {
    const Capture = struct {
        content_bytes: std.ArrayList(u8) = .empty,
        reasoning_bytes: std.ArrayList(u8) = .empty,
        starts: usize = 0,
        fn content(raw: *anyopaque, bytes: []const u8) void {
            const self: *@This() = @ptrCast(@alignCast(raw));
            self.content_bytes.appendSlice(std.testing.allocator, bytes) catch unreachable;
        }
        fn reasoning(raw: *anyopaque, bytes: []const u8) void {
            const self: *@This() = @ptrCast(@alignCast(raw));
            self.reasoning_bytes.appendSlice(std.testing.allocator, bytes) catch unreachable;
        }
        fn start(raw: *anyopaque, _: []const u8, _: []const u8, _: ?[]const u8) void {
            const self: *@This() = @ptrCast(@alignCast(raw));
            self.starts += 1;
        }
    };
    var capture: Capture = .{};
    defer capture.content_bytes.deinit(std.testing.allocator);
    defer capture.reasoning_bytes.deinit(std.testing.allocator);
    var accumulator: StreamAccumulator = .{};
    defer accumulator.deinit(std.testing.allocator);
    try consumeChunk(std.testing.allocator, &accumulator, "{\"choices\":[{\"delta\":{\"reasoning_content\":\"think\",\"tool_calls\":[{\"index\":0,\"id\":\"call_1\",\"function\":{\"name\":\"read_file\",\"arguments\":\"{\\\"path\\\":\"}}]}}]}", &capture, Capture.content, Capture.start, Capture.reasoning, null);
    try consumeChunk(std.testing.allocator, &accumulator, "{\"choices\":[{\"delta\":{\"content\":\"done\",\"tool_calls\":[{\"index\":0,\"function\":{\"arguments\":\"\\\"a\\\"}\"}}]},\"finish_reason\":\"tool_calls\"}]}", &capture, Capture.content, Capture.start, Capture.reasoning, null);
    const completion = try finish(std.testing.allocator, &accumulator);
    defer {
        if (completion.content) |content| std.testing.allocator.free(@constCast(content));
        if (completion.generation_id) |id| std.testing.allocator.free(@constCast(id));
        if (completion.provider_state_json) |state| std.testing.allocator.free(@constCast(state));
        types.freeToolCallSlice(std.testing.allocator, @constCast(completion.tool_calls));
    }
    try std.testing.expectEqualStrings("done", completion.content.?);
    try std.testing.expectEqualStrings("think", capture.reasoning_bytes.items);
    try std.testing.expectEqual(@as(usize, 1), capture.starts);
    try std.testing.expectEqualStrings("{\"path\":\"a\"}", completion.tool_calls[0].arguments_json);
    try std.testing.expectEqual(types.ProviderFinishReason.tool_calls, completion.finish_reason.?);

    const followup_messages = [_]types.ChatMessage{
        .{
            .role = .assistant,
            .content = completion.content,
            .tool_calls = completion.tool_calls,
            .provider_state_json = completion.provider_state_json,
        },
        .{ .role = .tool, .content = "file", .tool_call_id = "call_1" },
    };
    const followup = try buildAgentRequest(std.testing.allocator, .{
        .model = default_model,
        .messages = &followup_messages,
        .tool_choice = .auto,
        .provider_options = .{},
    });
    defer std.testing.allocator.free(followup);
    try std.testing.expect(std.mem.find(u8, followup, "\"reasoning_content\":\"think\"") != null);
}

test "captures DeepSeek generation identity and usage" {
    var accumulator: StreamAccumulator = .{};
    defer accumulator.deinit(std.testing.allocator);
    const Capture = struct {
        fn content(_: *anyopaque, _: []const u8) void {}
    };
    var marker: u8 = 0;
    try consumeChunk(
        std.testing.allocator,
        &accumulator,
        "{\"id\":\"chat_1\",\"choices\":[{\"delta\":{},\"finish_reason\":\"stop\"}],\"usage\":{\"prompt_tokens\":7,\"completion_tokens\":3}}",
        &marker,
        Capture.content,
        null,
        null,
        null,
    );
    const completion = try finish(std.testing.allocator, &accumulator);
    defer {
        if (completion.generation_id) |id| std.testing.allocator.free(@constCast(id));
        types.freeToolCallSlice(std.testing.allocator, @constCast(completion.tool_calls));
    }
    try std.testing.expectEqualStrings("chat_1", completion.generation_id.?);
    try std.testing.expectEqual(@as(u64, 7), completion.usage.input_tokens.?);
    try std.testing.expectEqual(@as(u64, 3), completion.usage.output_tokens.?);
}

test "DeepSeek base URL accepts HTTPS origins and rejects unsafe values" {
    var buffer: [256]u8 = undefined;
    try std.testing.expectEqualStrings(
        default_chat_url,
        resolveChatUrl("https://api.deepseek.com/", &buffer).?,
    );
    try std.testing.expectEqualStrings(
        "https://gateway.example/v1/chat/completions",
        resolveChatUrl("https://gateway.example/v1", &buffer).?,
    );
    try std.testing.expect(resolveChatUrl("http://api.deepseek.com", &buffer) == null);
    try std.testing.expect(resolveChatUrl("https://user@example.com", &buffer) == null);
    try std.testing.expect(resolveChatUrl("https://example.com?key=secret", &buffer) == null);
}
