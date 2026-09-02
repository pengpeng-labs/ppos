# ppos 0.2.0 command reference

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

Examples:

```text
pp> components
osbare 0.1.1
oscore 0.1.3
ossh 0.1.1
ppnet 0.2.0
ppos 0.2.0

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

The ppos v0.2.0 Shell runs with the trusted root principal, so these commands
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
command name. Version 0.2.0 does not interpret quotes, escapes, variables,
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
bytes; UTF-8 composition and selectable keyboard layouts are not part of v0.1.
