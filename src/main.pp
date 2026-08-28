import "@ossh/src/ossh.pp";

static ppos_shell_task: int = -1;
static ppos_shell_restarts: u64;
static ppos_root_principal: OsCorePrincipal;

fn ppos_fail(message: str) {
    oscore_platform_write("PPOS FAIL ");
    oscore_platform_write(message);
    oscore_platform_write("\n");
    osbare_halt();
}

fn ppos_command_version(line: u64, args: *OsShArgs) -> int {
    ossh_write("ppos 0.1.0\n");
    return 0;
}

fn ppos_command_components(line: u64, args: *OsShArgs) -> int {
    ossh_write("osbare 0.1.0\n");
    ossh_write("oscore 0.1.0\n");
    ossh_write("ossh 0.1.0\n");
    ossh_write("ppos 0.1.0\n");
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
        && ossh_register("supervisor", "Show Shell lifecycle state",
            &ppos_command_supervisor);
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
    oscore_platform_write("ppos 0.1.0\n");
    oscore_platform_write("composition: osbare + oscore + ossh\n");
    if (!oscore_init(boot_info)) { ppos_fail("oscore-init"); }
    ppos_root_principal = oscore_principal_root();
    if (!ossh_init(ppos_root_principal)) { ppos_fail("ossh-init"); }
    if (!ppos_register_commands()) { ppos_fail("command-register"); }
    if (!ppos_start_shell()) { ppos_fail("shell-start"); }
    ossh_write("\nPPOS READY\n");
    ossh_prompt();
    while (true) {
        oscore_run_once();
        ppos_supervise_shell();
    }
}
