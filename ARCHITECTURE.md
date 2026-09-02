# ppos architecture

[Simplified Chinese](ARCHITECTURE.zh-CN.md)

## Product, not another subsystem

ppos owns image composition, release identity, startup order, and top-level
lifecycle policy. It does not provide a fourth copy of hardware, core, or Shell
logic. The complete normal dependency direction is:

```text
ppos -> ossh  -> oscore -> osbare -> x86-64 machine
     -> ppnet -> oscore
```

The manifest declares ossh and ppnet as direct package dependencies. Both share
one locked oscore 0.1.3 instance; pptc locks osbare transitively. Final ELF
composition links the published osbare entry objects plus ppnet's reproducibly
built uIP and BearSSL archives. Boot and native-archive composition remain
outside the pplang package artifact boundary.

## Startup sequence

1. osbare snapshots Multiboot state and calls `osbare_main`.
2. ppos validates and initializes oscore.
3. ppos creates a root principal for trusted system policy.
4. ppos initializes ossh and the ppnet oscore port.
5. ppos installs bounded static QEMU network policy and initializes TCP.
6. ppos registers product commands and the Shell cooperative task.
7. the supervisor repeatedly advances oscore and observes Shell state.

The image entry type and fatal pre-core halt are the only direct osbare ABI
touchpoints in ppos policy. Normal operation uses ossh, ppnet, and oscore
contracts. ppnet owns protocol state; ppos owns configuration and authority.

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

TLS code is linked through ppnet, but ppos v0.2 does not install a global trust
store. A future application or packaging component must provide explicit trust
anchors before TLS can open a session.
