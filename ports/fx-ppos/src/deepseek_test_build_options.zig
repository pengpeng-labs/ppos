pub const git_commit: []const u8 = "test";
pub const app_version: []const u8 = "0.0.6-ppos";
pub const update_channel: []const u8 = "stable";
pub const WasmSurface = enum { none, core, term };
pub const wasm_surface: WasmSurface = .term;
