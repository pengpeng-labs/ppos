# ppos architecture

[Simplified Chinese](ARCHITECTURE.zh-CN.md)

## Product, not another subsystem

ppos owns image composition, release identity, startup order, and top-level
lifecycle policy. It does not provide a fourth copy of hardware, core, or Shell
logic. The complete normal dependency direction is:

```text
ppos -> ossh -> oscore -> osbare -> x86-64 machine
```

The manifest declares only ossh as a direct package dependency. pptc resolves
and locks oscore and osbare transitively. Final ELF composition links the
published osbare entry objects and static archive because boot policy remains
outside the pplang package artifact boundary.

## Startup sequence

1. osbare snapshots Multiboot state and calls `osbare_main`.
2. ppos validates and initializes oscore.
3. ppos creates a root principal for trusted system policy.
4. ppos initializes ossh and registers product commands.
5. ppos registers the Shell callback in the cooperative task table.
6. the supervisor repeatedly advances oscore and observes Shell state.

The image entry type and fatal pre-core halt are the only direct osbare ABI
touchpoints in ppos policy. Normal operation uses ossh and oscore contracts.

## Supervision

The Shell is a trusted polling task rather than a process. If its task reaches
the stopped state, ppos records its result, reaps the old slot, creates a new
Shell task with the same root principal, increments a restart counter, and
redraws the prompt. This is lifecycle recovery, not memory or privilege
isolation.

## Trust boundary

All v0.1 code shares one address space and executes with machine privilege.
Capabilities prevent accidental authority use at reviewed service boundaries;
they do not defend against arbitrary memory corruption. Future ordinary
applications belong behind osrt and an external validated WASM runtime.
