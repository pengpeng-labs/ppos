# ppos 0.3.0 command reference

[Simplified Chinese](COMMANDS.zh-CN.md)

The `pp>` prompt is provided by ossh. Commands are synchronous trusted-system
operations in the single ppos address space; they do not launch processes.

## Product commands

| Command | Purpose |
|---|---|
| `version` | Print the ppos release version. |
| `components` | Print the pinned osbare, oscore, ossh, ppnet, and ppos versions. |
| `supervisor` | Show the Shell task slot, state, run count, and restart count. |
| `network` | Show static network readiness and transport bounds. |
| `ping` | Send one bounded ICMP echo to the configured QEMU gateway. |
| `agent status` | Show provider, volatile-key state, module size, and base URL. |
| `agent check` | Load and instantiate the bundled fx module without running it. |
| `agent setup` | Read a masked DeepSeek key into volatile memory. |
| `agent base <https-url>` | Change the volatile provider base URL. |
| `agent run` | Run fx as the foreground WASM Agent application. |
| `agent clear` | Zero the retained provider key. |

Examples:

```text
pp> components
osbare 0.1.3
oscore 0.1.4
ossh 0.1.2
ppnet 0.2.2
pphttp 0.1.0
osrt 0.1.1
fx 0.0.6-ppos
ppos 0.3.0

pp> supervisor
shell_task=0 state=1 runs=32 restarts=0
```

Task states are `1` ready, `2` waiting, and `3` stopped. The Shell is normally
ready while it handles a command and waiting while no keyboard input exists.

## System inspection

| Command | Purpose | Capability |
|---|---|---|
| `status` | Show core initialization, monotonic ticks, and service count. | `system.inspect` |
| `memory` | Show the bounded physical-page pool and 64 KiB core heap. | `system.inspect` |
| `tasks` | List active cooperative task slots, states, and run counts. | `system.inspect` |
| `services` | List typed services, availability, versions, and required capabilities. | `system.inspect` |
| `log` | Read retained structured oscore log records. | `system.inspect` |
| `ticks` | Print the current monotonic clock tick. | `clock` |

The ppos v0.3.0 Shell runs with the trusted root principal, so these commands
are available in the release image. A future restricted Shell principal would
receive `permission denied` when it lacks the required capability.

## Shell utilities

| Command | Purpose |
|---|---|
| `help` | List every registered command and summary. |
| `about` | Describe ossh and its role. |
| `echo <args...>` | Write up to seven arguments separated by spaces. |
| `history` | List the sixteen most recent non-duplicate command lines. |
| `clear` | Advance and clear the bounded text viewport. |

The tokenizer accepts at most eight whitespace-separated tokens including the
command name. Version 0.3.0 does not interpret quotes, escapes, variables,
redirection, pipes, glob patterns, or shell scripts.

## Editing keys

| Key | Behavior |
|---|---|
| `Tab` | Complete a unique command name or list matching command names. |
| `Up` / `Down` | Navigate command history. |
| `Left` / `Right` | Move the insertion cursor. |
| `Home` / `End` | Move to the beginning or end of the line. |
| `Backspace` | Remove the byte before the cursor. |
| `Delete` | Remove the byte under the cursor. |
| `Enter` | Save, tokenize, and execute the current line. |

Input uses a PS/2 Set-1 US ASCII layout. The editable line is bounded to 255
bytes; UTF-8 composition and selectable keyboard layouts are not part of v0.3.

## Agent input

`agent setup` masks typed bytes, excludes them from history, and treats Escape
as cancellation. `agent run` temporarily gives terminal input to fx; Enter,
Backspace, Tab, Escape, and arrow keys are translated to the terminal byte
sequences expected by the WASM application. Exit fx to return to `pp>`.

The key and base URL are not persisted across reboot. `agent clear` should be
used when the key is no longer needed.
