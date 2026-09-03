import "@osrt/src/osrt.pp";
import "@pphttp/src/pphttp.pp";

extern fn ppos_deepseek_trust_anchor() -> u64;

static ppos_agent_key: [512]u8;
static ppos_agent_key_size: int;
static ppos_agent_base_url: [2048]u8;
static ppos_agent_base_url_size: int;
static ppos_agent_module_address: u64;
static ppos_agent_module_size: int;
static ppos_agent_runtime_pool: u64;
static ppos_agent_input: [8]u8;
static ppos_agent_input_size: int;
static ppos_agent_shift: bool;
static ppos_agent_caps: bool;
static ppos_agent_http_response: [524288]u8;
static ppos_agent_http_header: [2048]u8;
static ppos_agent_http_host: [254]u8;
static ppos_agent_http_path: [1024]u8;
static ppos_agent_http_context: [32]u64;
static ppos_agent_http_headers: [16384]u8;
static ppos_agent_http_transport: [16384]u8;
static ppos_agent_http_host_length: int;
static ppos_agent_http_path_length: int;
static ppos_agent_http_size: int;
static ppos_agent_http_offset: int;
static ppos_agent_http_status_code: int;
static ppos_agent_http_active: bool;

fn ppos_agent_zero_key() {
    ossh_secret_zero(ptr_to_int(&ppos_agent_key[0]), 512);
    ppos_agent_key_size = 0;
}

fn ppos_agent_set_default_base_url() {
    let value: str = "https://api.deepseek.com";
    let index: int = 0;
    while (index < len(value) as int) {
        ppos_agent_base_url[index] = value[index]; index = index + 1;
    }
    ppos_agent_base_url_size = len(value) as int;
}

fn ppos_agent_init(boot_info: *OsBareBootInfo) -> bool {
    if (boot_info == (0 as *OsBareBootInfo)
        || boot_info.boot_module_count != (1 as u64)) { return false; }
    let modules: *OsBareBootModule = osbare_boot_modules(boot_info);
    if (modules == (0 as *OsBareBootModule)
        || modules[0].end <= modules[0].start
        || modules[0].end - modules[0].start > (16 * 1024 * 1024) as u64) {
        return false;
    }
    ppos_agent_module_address = modules[0].start;
    ppos_agent_module_size = (modules[0].end - modules[0].start) as int;
    ppos_agent_runtime_pool = oscore_page_alloc(32768);
    if (ppos_agent_runtime_pool == (0 as u64)
        || osrt_wamr_init(ppos_agent_runtime_pool,
            (128 * 1024 * 1024) as u32) != 0) { return false; }
    ppos_agent_zero_key();
    ppos_agent_set_default_base_url();
    ppos_agent_input_size = 0;
    if (ppnet_tls_configure(&ppos_network_authority,
            ppos_deepseek_trust_anchor(), 1) != 0) { return false; }
    return true;
}

fn ppos_agent_arg_is(line: u64, args: *OsShArgs, index: int,
    expected: str) -> bool {
    return index >= 0 && index < args.count
        && ossh_slice_equal(expected, line, args.starts[index], args.lengths[index]);
}

fn ppos_agent_setup() -> int {
    ossh_write("DeepSeek provider\n");
    ossh_write("base_url: ");
    ossh_write_bytes(ptr_to_int(&ppos_agent_base_url[0]),
        ppos_agent_base_url_size);
    ossh_write("\n");
    ossh_write("model: deepseek-v4-flash\n");
    let size: int = ossh_read_secret("api_key> ",
        ptr_to_int(&ppos_agent_key[0]), 512);
    if (size < 16) {
        ppos_agent_zero_key();
        ossh_write("agent setup cancelled\n");
        return -1;
    }
    ppos_agent_key_size = size;
    ossh_write("agent configured in volatile memory\n");
    return 0;
}

fn ppos_agent_run() -> int {
    if (ppos_agent_key_size < 16) {
        ossh_write("agent is not configured; run: agent setup\n");
        return -1;
    }
    let error: [512]u8;
    let module: u64 = osrt_wamr_load(ppos_agent_module_address,
        ppos_agent_module_size as u32, ptr_to_int(&error[0]), 512 as u32);
    if (module == (0 as u64)) {
        ossh_write("agent module load failed\n");
        return -1;
    }
    let capabilities: u64 = osrt_cap_stdout() | osrt_cap_stdin()
        | osrt_cap_clock() | osrt_cap_random() | osrt_cap_terminal()
        | osrt_cap_http() | osrt_cap_config();
    let instance: u64 = osrt_wamr_instantiate(module, (256 * 1024) as u32,
        (4 * 1024 * 1024) as u32, 2048 as u32, capabilities,
        ptr_to_int(&error[0]), 512 as u32);
    if (instance == (0 as u64)) {
        osrt_wamr_unload(module);
        ossh_write("agent instantiate failed\n");
        return -1;
    }
    if (osrt_wamr_set_env(instance, ptr_to_int("DEEPSEEK_API_KEY"),
            16 as u32, ptr_to_int(&ppos_agent_key[0]),
            ppos_agent_key_size as u32) != 0
        || osrt_wamr_set_env(instance, ptr_to_int("DEEPSEEK_BASE_URL"),
            17 as u32, ptr_to_int(&ppos_agent_base_url[0]),
            ppos_agent_base_url_size as u32) != 0) {
        osrt_wamr_deinstantiate(instance);
        osrt_wamr_unload(module);
        ossh_write("agent environment failed\n");
        return -1;
    }
    ossh_write("starting fx 0.0.6; exit fx to return to ppos\n");
    let status: int = osrt_wamr_run(instance, osrt_entry_start() as u32,
        0x7FFFFFFF as u32, ptr_to_int(&error[0]), 512 as u32);
    let exit_code: int = osrt_wamr_result(instance, osrt_result_exit_code());
    if (status < 0) {
        ossh_write("fx runtime error: ");
        let error_size: int = 0;
        while (error_size < 511 && error[error_size] != (0 as u8)) {
            error_size = error_size + 1;
        }
        ossh_write_bytes(ptr_to_int(&error[0]), error_size);
        ossh_write("\n");
    }
    osrt_wamr_deinstantiate(instance);
    osrt_wamr_unload(module);
    ossh_write("fx exited status=");
    ossh_write_int(status);
    ossh_write(" exit_code=");
    ossh_write_int(exit_code);
    ossh_write("\n");
    return status;
}

fn ppos_agent_check() -> int {
    let error: [512]u8;
    let module: u64 = osrt_wamr_load(ppos_agent_module_address,
        ppos_agent_module_size as u32, ptr_to_int(&error[0]), 512 as u32);
    if (module == (0 as u64)) {
        ossh_write("agent module load failed\n"); return -1;
    }
    let capabilities: u64 = osrt_cap_stdout() | osrt_cap_stdin()
        | osrt_cap_clock() | osrt_cap_random() | osrt_cap_terminal()
        | osrt_cap_http() | osrt_cap_config();
    let instance: u64 = osrt_wamr_instantiate(module, (256 * 1024) as u32,
        (4 * 1024 * 1024) as u32, 1024 as u32, capabilities,
        ptr_to_int(&error[0]), 512 as u32);
    if (instance == (0 as u64)) {
        osrt_wamr_unload(module);
        ossh_write("agent module admission failed\n"); return -1;
    }
    osrt_wamr_deinstantiate(instance);
    osrt_wamr_unload(module);
    ossh_write("agent runtime ready\n");
    return 0;
}

fn ppos_agent_command(line: u64, args: *OsShArgs) -> int {
    if (args.count == 1 || ppos_agent_arg_is(line, args, 1, "status")) {
        ossh_write("agent provider=deepseek configured=");
        if (ppos_agent_key_size >= 16) { ossh_write("yes"); }
        else { ossh_write("no"); }
        ossh_write(" module_bytes=");
        ossh_write_int(ppos_agent_module_size);
        ossh_write(" base_url=");
        ossh_write_bytes(ptr_to_int(&ppos_agent_base_url[0]),
            ppos_agent_base_url_size);
        ossh_write("\n");
        return 0;
    }
    if (ppos_agent_arg_is(line, args, 1, "setup")) { return ppos_agent_setup(); }
    if (ppos_agent_arg_is(line, args, 1, "check")) { return ppos_agent_check(); }
    if (ppos_agent_arg_is(line, args, 1, "base")) {
        if (args.count != 3 || args.lengths[2] < 9 || args.lengths[2] > 2047) {
            ossh_write("usage: agent base <https-url>\n"); return -1;
        }
        let source: *u8 = (line + (args.starts[2] as u64)) as *u8;
        let prefix: str = "https://";
        let index: int = 0;
        while (index < 8) {
            if (source[index] != prefix[index]) {
                ossh_write("agent base requires https\n"); return -1;
            }
            index = index + 1;
        }
        index = 0;
        while (index < args.lengths[2]) {
            let value: int = source[index] as int;
            if (value < 33 || value > 126) {
                ossh_write("agent base contains invalid bytes\n"); return -1;
            }
            ppos_agent_base_url[index] = source[index]; index = index + 1;
        }
        while (index < 2048) {
            ppos_agent_base_url[index] = 0 as u8; index = index + 1;
        }
        ppos_agent_base_url_size = args.lengths[2];
        ossh_write("agent base updated\n");
        return 0;
    }
    if (ppos_agent_arg_is(line, args, 1, "run")) { return ppos_agent_run(); }
    if (ppos_agent_arg_is(line, args, 1, "clear")) {
        ppos_agent_zero_key();
        ossh_write("agent secret cleared\n");
        return 0;
    }
    ossh_write("usage: agent [status|setup|base|check|run|clear]\n");
    return -1;
}

fn ppos_agent_queue(value: int) {
    if (ppos_agent_input_size < 8) {
        ppos_agent_input[ppos_agent_input_size] = value as u8;
        ppos_agent_input_size = ppos_agent_input_size + 1;
    }
}

fn ppos_agent_pump_input() {
    oscore_events_pump();
    let event: OsCoreEvent;
    let result: int = oscore_event_next(&ppos_root_principal, &event);
    while (result == 1 && ppos_agent_input_size < 5) {
        let pressed: bool = (event.value & (1 as u64)) != (0 as u64);
        let extended: bool = (event.value & (2 as u64)) != (0 as u64);
        if (event.code == (0x2A as u64) || event.code == (0x36 as u64)) {
            ppos_agent_shift = pressed;
        } else if (pressed && !extended && event.code == (0x3A as u64)) {
            ppos_agent_caps = !ppos_agent_caps;
        } else if (pressed && extended && (event.code == (0x48 as u64)
            || event.code == (0x50 as u64) || event.code == (0x4B as u64)
            || event.code == (0x4D as u64))) {
            ppos_agent_queue(27); ppos_agent_queue(91);
            if (event.code == (0x48 as u64)) { ppos_agent_queue(65); }
            else if (event.code == (0x50 as u64)) { ppos_agent_queue(66); }
            else if (event.code == (0x4D as u64)) { ppos_agent_queue(67); }
            else { ppos_agent_queue(68); }
        } else if (pressed && !extended) {
            ossh_shift = ppos_agent_shift;
            ossh_caps_lock = ppos_agent_caps;
            let value: int = ossh_key_ascii(event.code);
            if (event.code == (0x1C as u64)) { value = 13; }
            else if (event.code == (0x0E as u64)) { value = 127; }
            else if (event.code == (0x0F as u64)) { value = 9; }
            else if (event.code == (0x01 as u64)) { value = 27; }
            if (value > 0) { ppos_agent_queue(value); }
        }
        result = oscore_event_next(&ppos_root_principal, &event);
    }
}

fn osrt_host_write(fd: int, source: u64, size: u32) -> int {
    if ((fd != 1 && fd != 2) || !ossh_write_bytes(source, size as int)) { return -1; }
    return size as int;
}
fn osrt_host_clock_time_ns() -> u64 {
    return oscore_clock_monotonic_ns(&ppos_root_principal);
}
fn osrt_host_random_fill(destination: u64, size: u32) -> int {
    return oscore_entropy_fill(&ppos_root_principal, destination, size as int);
}
fn osrt_host_abort() {
    ppos_fail("osrt-abort");
}
fn osrt_host_poll_input(timeout_ms: int) -> int {
    ppos_agent_pump_input();
    if (ppos_agent_input_size > 0) { return 1; }
    return 0;
}
fn osrt_host_read(destination: u64, size: u32) -> int {
    if (destination == (0 as u64) || size == (0 as u32)) { return -1; }
    ppos_agent_pump_input();
    while (ppos_agent_input_size == 0) {
        oscore_platform_wait();
        ppos_agent_pump_input();
    }
    let count: int = ppos_agent_input_size;
    if (count > size as int) { count = size as int; }
    let output: *u8 = destination as *u8;
    let index: int = 0;
    while (index < count) {
        output[index] = ppos_agent_input[index];
        index = index + 1;
    }
    index = count;
    while (index < ppos_agent_input_size) {
        ppos_agent_input[index - count] = ppos_agent_input[index];
        index = index + 1;
    }
    ppos_agent_input_size = ppos_agent_input_size - count;
    return count;
}
fn osrt_host_terminal_size(columns: u64, rows: u64) -> int {
    if (columns == (0 as u64) || rows == (0 as u64)) { return -1; }
    let column_value: *u16 = columns as *u16;
    let row_value: *u16 = rows as *u16;
    column_value[0] = 80 as u16;
    row_value[0] = 25 as u16;
    return 0;
}

fn ppos_agent_http_clear_header() {
    ossh_secret_zero(ptr_to_int(&ppos_agent_http_header[0]), 2048);
}

fn ppos_agent_http_append(source: u64, size: int, offset: int) -> int {
    if (source == (0 as u64) || size < 0 || offset < 0
        || offset + size > 2048) { return -1; }
    let index: int = 0;
    let input: *u8 = source as *u8;
    while (index < size) {
        ppos_agent_http_header[offset + index] = input[index];
        index = index + 1;
    }
    return offset + size;
}

fn ppos_agent_http_append_str(value: str, offset: int) -> int {
    return ppos_agent_http_append(ptr_to_int(value), len(value) as int, offset);
}

fn ppos_agent_http_append_decimal(value: int, offset: int) -> int {
    if (value < 0) { return -1; }
    let digits: [20]u8;
    let count: int = 0;
    let current: int = value;
    if (current == 0) { digits[0] = 48 as u8; count = 1; }
    while (current > 0 && count < 20) {
        digits[count] = (48 + (current % 10)) as u8;
        current = current / 10;
        count = count + 1;
    }
    let index: int = count - 1;
    let result: int = offset;
    while (index >= 0) {
        result = ppos_agent_http_append(ptr_to_int(&digits[index]), 1, result);
        if (result < 0) { return -1; }
        index = index - 1;
    }
    return result;
}

fn ppos_agent_http_parse_url(url: u64, size: int) -> bool {
    if (url == (0 as u64) || size < 10 || size > 2047) { return false; }
    let input: *u8 = url as *u8;
    let clear: int = 0;
    while (clear < 254) {
        ppos_agent_http_host[clear] = 0 as u8; clear = clear + 1;
    }
    clear = 0;
    while (clear < 1024) {
        ppos_agent_http_path[clear] = 0 as u8; clear = clear + 1;
    }
    let prefix: str = "https://";
    let index: int = 0;
    while (index < 8) {
        if (input[index] != prefix[index]) { return false; }
        index = index + 1;
    }
    let host_size: int = 0;
    while (index < size && input[index] != (47 as u8)) {
        let value: int = input[index] as int;
        let valid: bool = (value >= 97 && value <= 122)
            || (value >= 65 && value <= 90) || (value >= 48 && value <= 57)
            || value == 45 || value == 46;
        if (!valid || host_size >= 253) { return false; }
        ppos_agent_http_host[host_size] = input[index];
        host_size = host_size + 1;
        index = index + 1;
    }
    if (host_size < 1) { return false; }
    let path_size: int = 0;
    if (index == size) {
        ppos_agent_http_path[0] = 47 as u8;
        path_size = 1;
    } else {
        while (index < size && path_size < 1024) {
            let value: int = input[index] as int;
            if (value < 33 || value > 126 || value == 35) { return false; }
            ppos_agent_http_path[path_size] = input[index];
            path_size = path_size + 1;
            index = index + 1;
        }
        if (index != size) { return false; }
    }
    ppos_agent_http_host_length = host_size;
    ppos_agent_http_path_length = path_size;
    return true;
}

fn osrt_host_http_open(method: u64, method_size: u32, url: u64,
    url_size: u32, headers: u64, headers_size: u32, body: u64,
    body_size: u32) -> int {
    if (ppos_agent_http_active || ppos_agent_key_size < 16
        || !ppos_agent_raw_equal(method, method_size, "POST")
        || body == (0 as u64) || body_size > (1024 * 1024) as u32
        || !ppos_agent_http_parse_url(url, url_size as int)) { return -1; }
    let host: str = str_from_ptr(&ppos_agent_http_host[0],
        ppos_agent_http_host_length as u64);
    let destination: u32 = ppnet_dns_resolve(&ppos_network_authority, host, 10000);
    if (destination == (0 as u32)
        || ppnet_tls_connect(&ppos_network_authority, destination, 443,
            host, 30000) != 0) { return -1; }
    ppos_agent_http_clear_header();
    let offset: int = 0;
    offset = ppos_agent_http_append_str("POST ", offset);
    offset = ppos_agent_http_append(ptr_to_int(&ppos_agent_http_path[0]),
        ppos_agent_http_path_length, offset);
    offset = ppos_agent_http_append_str(" HTTP/1.1\r\nHost: ", offset);
    offset = ppos_agent_http_append(ptr_to_int(&ppos_agent_http_host[0]),
        ppos_agent_http_host_length, offset);
    offset = ppos_agent_http_append_str("\r\nContent-Type: application/json\r\nAccept: text/event-stream\r\nAuthorization: Bearer ", offset);
    offset = ppos_agent_http_append(ptr_to_int(&ppos_agent_key[0]),
        ppos_agent_key_size, offset);
    offset = ppos_agent_http_append_str("\r\nContent-Length: ", offset);
    offset = ppos_agent_http_append_decimal(body_size as int, offset);
    offset = ppos_agent_http_append_str("\r\nConnection: close\r\n\r\n", offset);
    if (offset < 0 || ppnet_tls_send(&ppos_network_authority,
            ptr_to_int(&ppos_agent_http_header[0]), offset, 30000) != offset
        || ppnet_tls_send(&ppos_network_authority, body,
            body_size as int, 30000) != body_size as int) {
        ppos_agent_http_clear_header(); ppnet_tls_close(); return -1;
    }
    ppos_agent_http_clear_header();
    let context: u64 = ptr_to_int(&ppos_agent_http_context[0]);
    if (pphttp_response_context_size() > (32 * 8) as u32
        || pphttp_response_init(context, (32 * 8) as u32,
            ptr_to_int(&ppos_agent_http_headers[0]), 16384 as u32) != 0) {
        ppnet_tls_close(); return -1;
    }
    let total: int = 0;
    let result: int = pphttp_more();
    while (result == pphttp_more() && total < 524288) {
        let received: int = ppnet_tls_receive(&ppos_network_authority,
            ptr_to_int(&ppos_agent_http_transport[0]), 16384, 30000);
        if (received <= 0) {
            result = pphttp_response_finish(context); break;
        }
        let produced: u32 = 0 as u32;
        result = pphttp_response_feed(context,
            ptr_to_int(&ppos_agent_http_transport[0]), received as u32,
            ptr_to_int(&ppos_agent_http_response[total]),
            (524288 - total) as u32, ptr_to_int(&produced));
        total = total + produced as int;
    }
    ppnet_tls_close();
    if (result != pphttp_complete()) { return -1; }
    ppos_agent_http_status_code = pphttp_response_status(context);
    ppos_agent_http_size = total;
    ppos_agent_http_offset = 0;
    ppos_agent_http_active = true;
    return 1;
}

fn osrt_host_http_status(handle: int) -> int {
    if (!ppos_agent_http_active || handle != 1) { return -1; }
    return ppos_agent_http_status_code;
}

fn osrt_host_http_next(handle: int, destination: u64, capacity: u32) -> int {
    if (!ppos_agent_http_active || handle != 1 || destination == (0 as u64)) {
        return -1;
    }
    if (ppos_agent_http_offset >= ppos_agent_http_size) { return 0; }
    let count: int = ppos_agent_http_size - ppos_agent_http_offset;
    if (count > capacity as int) { count = capacity as int; }
    let output: *u8 = destination as *u8;
    let index: int = 0;
    while (index < count) {
        output[index] = ppos_agent_http_response[ppos_agent_http_offset + index];
        index = index + 1;
    }
    ppos_agent_http_offset = ppos_agent_http_offset + count;
    return count;
}

fn osrt_host_http_close(handle: int) {
    if (handle == 1) {
        ppos_agent_http_active = false;
        ppos_agent_http_size = 0;
        ppos_agent_http_offset = 0;
        ppos_agent_http_status_code = 0;
    }
}

fn ppos_agent_raw_equal(source: u64, size: u32, expected: str) -> bool {
    if (source == (0 as u64) || size as u64 != len(expected)) { return false; }
    let bytes: *u8 = source as *u8;
    let index: int = 0;
    while (index < size as int) {
        if (bytes[index] != expected[index]) { return false; }
        index = index + 1;
    }
    return true;
}
fn ppos_agent_config_copy(destination: u64, capacity: u32, value: str) -> int {
    if (destination == (0 as u64) || capacity as u64 < len(value)) { return -3; }
    let output: *u8 = destination as *u8;
    let index: int = 0;
    while (index < len(value) as int) {
        output[index] = value[index]; index = index + 1;
    }
    return len(value) as int;
}
fn osrt_host_config_get(id: u64, id_size: u32, destination: u64,
    capacity: u32) -> int {
    if (ppos_agent_raw_equal(id, id_size, "model")) {
        return ppos_agent_config_copy(destination, capacity, "deepseek-v4-flash");
    }
    if (ppos_agent_raw_equal(id, id_size, "mode")) {
        return ppos_agent_config_copy(destination, capacity, "ask");
    }
    return -2;
}
fn osrt_host_config_set(id: u64, id_size: u32, value: u64,
    value_size: u32) -> int { return 0; }
