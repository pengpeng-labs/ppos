# ppos

[Simplified Chinese](README.zh-CN.md)

`ppos` is the bootable product image of the pp systems stack. It composes
versioned components instead of collecting their implementations in one
repository.

```text
ppos 0.1.0 image
├── ossh 0.1.0       system interaction policy
├── oscore 0.1.0     memory, tasks, events, capabilities, services
└── osbare 0.1.0     x86-64 boot and machine mechanisms
```

Version 0.1.0 proves that pplang components can define a small operating-system
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

## Build and run

Requirements are pplang/pplc/pptc 0.4.0, `x86_64-elf-*` GCC/binutils,
QEMU, and netcat. Keep osbare v0.1.0 nearby or pass its path explicitly:

```bash
make \
  PPTC=/path/to/pptc/target/debug/pp \
  OSBARE_DIR=/path/to/osbare

make run \
  PPTC=/path/to/pptc/target/debug/pp \
  OSBARE_DIR=/path/to/osbare
```

The product artifact is `build/ppos-v0.1.0.elf`. `make run` opens QEMU's
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
```

## Version boundary

ppos 0.1.0 intentionally contains no filesystem semantics, network protocols,
database, POSIX layer, userspace, WASM runtime, or Agent. Those are later
components and do not belong in the bootable foundation merely because earlier
experiments placed them in one source tree.

See [Command reference](COMMANDS.md), [Architecture](ARCHITECTURE.md),
[Component matrix](COMPONENTS.md), and [Compatibility](COMPATIBILITY.md).

## License

Licensed under either the Apache License, Version 2.0 or the MIT License, at
your option.
