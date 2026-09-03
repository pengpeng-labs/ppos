# ppos architecture

[Simplified Chinese](ARCHITECTURE.zh-CN.md)

## Product composition

ppos owns image composition, release identity, startup order, top-level
lifecycle, network configuration, trust anchors, and application authority. It
does not provide another copy of machine, core, Shell, protocol, HTTP, or WASM
runtime logic.

```text
                    +----------------------+
                    | ppos product policy  |
                    +-----+-----+-----+----+
                          |     |     |
                 +--------+     |     +---------+
                 v              v               v
               ossh           ppnet            osrt ---- WAMR ---- fx.wasm
                 |              |                |         C        Zig port
                 |              +---- pphttp ----+
                 +--------------+----------------+
                                v
                             oscore
                                v
                             osbare
                                v
                      QEMU x86-64 machine
```

The manifest locks the pplang package graph. Make composes freestanding native
archives because pptc 0.4 does not package C archives. ppnet reproducibly builds
the pinned uIP and BearSSL sources; pphttp wraps picohttpparser; osrt wraps WAMR;
the fx port records a pinned upstream revision and a reviewable patch. ppos owns
only product glue and policy around those contracts.

## Startup sequence

1. osbare enters long mode, snapshots Multiboot state, and calls `osbare_main`.
2. ppos initializes oscore and creates the trusted root principal.
3. ppos initializes ossh, ppnet, static QEMU networking, and TLS trust.
4. ppos reserves a bounded WAMR pool and admits the Multiboot fx module.
5. ppos registers product commands and starts the Shell cooperative task.
6. the supervisor advances oscore and restarts a stopped Shell task.
7. `agent run` creates a fresh WAMR instance with an explicit capability set.

## Agent data path

```text
masked keyboard input -> volatile ppos key buffer -> WASM environment
fx DeepSeek provider  -> osrt HTTP capability    -> ppos HTTP host
                      -> pphttp response decoder -> ppnet DNS/TCP/TLS
                      -> oscore packet service   -> osbare e1000
```

fx emits an OpenAI-compatible streaming request. ppos creates the Authorization
header immediately before transport, ppnet authenticates the configured HTTPS
host with the pinned trust anchor, pphttp decodes the bounded HTTP/1.1 response,
and osrt exposes response chunks to WASM. No API key is compiled into fx or
persisted by ppos.

## Trust and isolation

The Shell and native components are trusted and share ring 0. A root principal
and capabilities make authority explicit at service and WASM host boundaries;
they are policy checks, not native memory isolation. WAMR validates and bounds
the WASM module, but all native C, assembly, and pplang code remains in the same
trusted computing base.

The fx instance receives only terminal, clock, random, HTTP, and configuration
capabilities. It receives no block or raw packet capability. The current trust
store contains only the anchor needed for the configured DeepSeek endpoint; it
is not a general system CA store.

## Resource bounds

- QEMU memory: 384 MiB;
- oscore physical page pool: 32,768 pages (128 MiB);
- WAMR runtime pool: 128 MiB;
- WASM linear memory ceiling: 2,048 pages (128 MiB);
- instance host heap: 4 MiB;
- buffered HTTP response: 512 KiB;
- one active HTTP/TCP/TLS session;
- one foreground Agent instance.

These are explicit v0.3 product choices, not general scalability claims.
