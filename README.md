# ppos

[Simplified Chinese](README.zh-CN.md)

`ppos` is the bootable product image of the pp systems stack. It composes
versioned components instead of collecting their implementations in one
repository.

```text
ppos 0.2.0 image
├── ossh 0.1.1       system interaction policy
├── ppnet 0.2.0      bounded network policy and protocol adapters
├── oscore 0.1.3     memory, tasks, events, capabilities, services
└── osbare 0.1.1     x86-64 boot and machine mechanisms
```

Version 0.2.0 proves that pplang components can define a small operating-system
product while C and assembly retain the machine work for which they are suited.
The result is a statically linked, single-address-space QEMU x86-64 image with
a cooperative system core and interactive recovery shell.

## Product capabilities

- Multiboot v1 boot into x86-64 long mode;
- raw VGA and serial console;
- exception, timer, and keyboard event mechanisms;
- bounded physical-page and core-heap allocation;
- structured logging and generation-safe resources;
- cooperative polling tasks and explicit capabilities;
- typed console, clock, entropy, block, packet, input, and log services;
- interactive Shell editing, history, completion, and command registration;
- product commands for version, component matrix, and Shell supervision;
- automatic Shell task restart after an internal task failure.
- bounded Ethernet/ARP/IPv4/ICMP/UDP/DNS and one-session TCP/TLS composition;
- product-level network status and QEMU gateway ping commands.

## Build and run

Requirements are pplang/pplc/pptc 0.4.0, `x86_64-elf-*` GCC/binutils,
QEMU, and netcat. Keep osbare v0.1.1 and ppnet v0.2.0 nearby or pass their
paths explicitly:

```bash
make \
  PPTC=/path/to/pptc/target/debug/pp \
  OSBARE_DIR=/path/to/osbare \
  PPNET_DIR=/path/to/ppnet

make run \
  PPTC=/path/to/pptc/target/debug/pp \
  OSBARE_DIR=/path/to/osbare \
  PPNET_DIR=/path/to/ppnet
```

The product artifact is `build/ppos-v0.2.0.elf`. `make run` opens QEMU's
platform display and mirrors output to the invoking terminal. Use
`make run-headless` for serial-only operation.

At the `pp>` prompt, start with:

```text
help
components
status
memory
services
tasks
supervisor
network
ping
```

## Version boundary

ppos 0.2.0 composes ppnet but intentionally contains no filesystem semantics,
database, POSIX layer, userspace, WASM runtime, HTTP client, or Agent. Network
configuration is static for QEMU. TLS requires caller-provided trust anchors;
the product does not pretend that a test certificate is a system CA store.

See [Command reference](COMMANDS.md), [Architecture](ARCHITECTURE.md),
[Component matrix](COMPONENTS.md), and [Compatibility](COMPATIBILITY.md).

## License

Licensed under either the Apache License, Version 2.0 or the MIT License, at
your option.
