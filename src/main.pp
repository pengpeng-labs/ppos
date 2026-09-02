import "@ossh/src/ossh.pp";
import "@ppnet/src/ppnet.pp";
import "@ppnet/src/oscore_port.pp";

static ppos_shell_task: int = -1;
static ppos_shell_restarts: u64;
static ppos_root_principal: OsCorePrincipal;
static ppos_network_authority: PpNetAuthority;
static ppos_network_config: PpNetConfig;
static ppos_network_ready: bool;

fn ppos_fail(message: str) {
    oscore_platform_write("PPOS FAIL ");
    oscore_platform_write(message);
    oscore_platform_write("\n");
    osbare_halt();
}

fn ppos_command_version(line: u64, args: *OsShArgs) -> int {
    ossh_write("ppos 0.2.0\n");
    return 0;
}

fn ppos_command_components(line: u64, args: *OsShArgs) -> int {
    ossh_write("osbare 0.1.1\n");
    ossh_write("oscore 0.1.3\n");
    ossh_write("ossh 0.1.1\n");
    ossh_write("ppnet 0.2.0\n");
    ossh_write("ppos 0.2.0\n");
    return 0;
}

fn ppos_command_network(line: u64, args: *OsShArgs) -> int {
    if (!ossh_has_capability(oscore_cap_packet_read()
            | oscore_cap_packet_write())) {
        return ossh_denied();
    }
    ossh_write("network ready=");
    if (ppos_network_ready) { ossh_write("yes"); }
    else { ossh_write("no"); }
    ossh_write(" local=10.0.2.15 gateway=10.0.2.2");
    ossh_write(" tcp=single tls=trust-required\n");
    return 0;
}

fn ppos_command_ping(line: u64, args: *OsShArgs) -> int {
    if (!ossh_has_capability(oscore_cap_packet_read()
            | oscore_cap_packet_write())) {
        return ossh_denied();
    }
    if (!ppos_network_ready) { return -1; }
    let result: int = ppnet_ping(&ppos_network_authority,
        ppos_network_config.gateway_ipv4, 2000);
    if (result != 0) {
        ossh_write("ping gateway failed error=");
        ossh_write_int(result);
        ossh_write("\n");
        return result;
    }
    ossh_write("ping gateway 10.0.2.2 ok\n");
    return 0;
}

fn ppos_command_supervisor(line: u64, args: *OsShArgs) -> int {
    if (!ossh_has_capability(oscore_cap_system_inspect())) { return ossh_denied(); }
    ossh_write("shell_task=");
    ossh_write_int(ppos_shell_task);
    ossh_write(" state=");
    ossh_write_int(oscore_task_state(ppos_shell_task));
    ossh_write(" runs=");
    ossh_write_u64(oscore_task_runs(ppos_shell_task));
    ossh_write(" restarts=");
    ossh_write_u64(ppos_shell_restarts);
    ossh_write("\n");
    return 0;
}

fn ppos_register_commands() -> bool {
    return ossh_register("version", "Show the ppos release", &ppos_command_version)
        && ossh_register("components", "Show the pinned component matrix",
            &ppos_command_components)
        && ossh_register("network", "Show the ppnet product state",
            &ppos_command_network)
        && ossh_register("ping", "Ping the configured gateway",
            &ppos_command_ping)
        && ossh_register("supervisor", "Show Shell lifecycle state",
            &ppos_command_supervisor);
}

fn ppos_init_network() -> bool {
    if (!ppnet_oscore_port_init(ppos_root_principal)) { return false; }
    ppos_network_authority = ppnet_authority(1 as u64,
        ppnet_all_capabilities());
    ppos_network_config.local_ipv4 = 0x0A00020F as u32;
    ppos_network_config.netmask = 0xFFFFFF00 as u32;
    ppos_network_config.gateway_ipv4 = 0x0A000202 as u32;
    ppos_network_config.dns_ipv4 = 0x0A000203 as u32;
    ppos_network_config.ttl = 64 as u64;
    if (ppnet_init(&ppos_network_authority, &ppos_network_config) != 0
        || ppnet_tcp_init(&ppos_network_authority) != 0) {
        return false;
    }
    ppos_network_ready = true;
    return true;
}

fn ppos_start_shell() -> bool {
    let task: int = oscore_task_create(&ossh_task_entry, 0 as u64, ppos_root_principal);
    if (task < 0) { return false; }
    ppos_shell_task = task;
    return true;
}

fn ppos_supervise_shell() {
    if (ppos_shell_task < 0 || oscore_task_state(ppos_shell_task) != 3) { return; }
    let result: int = oscore_task_result(ppos_shell_task);
    ossh_write("\nPPOS SHELL EXIT result=");
    ossh_write_int(result);
    ossh_write("\n");
    if (!oscore_task_reap(ppos_shell_task) || !ppos_start_shell()) {
        ppos_fail("shell-restart");
    }
    ppos_shell_restarts = ppos_shell_restarts + (1 as u64);
    ossh_write("PPOS SHELL RESTARTED\n");
    ossh_prompt();
}

fn osbare_main(boot_info: *OsBareBootInfo) {
    oscore_platform_write("ppos 0.2.0\n");
    oscore_platform_write("composition: osbare + oscore + ossh + ppnet\n");
    if (!oscore_init(boot_info)) { ppos_fail("oscore-init"); }
    ppos_root_principal = oscore_principal_root();
    if (!ossh_init(ppos_root_principal)) { ppos_fail("ossh-init"); }
    if (!ppos_init_network()) { ppos_fail("ppnet-init"); }
    if (!ppos_register_commands()) { ppos_fail("command-register"); }
    if (!ppos_start_shell()) { ppos_fail("shell-start"); }
    ossh_write("\nPPOS NETWORK READY\n");
    ossh_write("PPOS READY\n");
    ossh_prompt();
    while (true) {
        oscore_run_once();
        ppos_supervise_shell();
    }
}
