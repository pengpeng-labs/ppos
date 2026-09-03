# ppos

[Simplified Chinese](README.zh-CN.md)

`ppos` is the bootable product image of the pp systems stack. It composes
independently versioned components and external standards implementations; it
does not duplicate their implementation inside the product repository.

```text
ppos 0.3.0 image
├── ossh 0.1.2       trusted system Shell and secret input
├── ppnet 0.2.2      bounded network and TLS policy
├── pphttp 0.1.0     bounded HTTP/1.1 response decoding
├── osrt 0.1.1       capability-gated WASM application host
├── oscore 0.1.4     memory, tasks, events, capabilities, services
├── osbare 0.1.3     x86-64 boot and machine mechanisms
├── WAMR 2.4.5       external WebAssembly runtime
└── fx 0.0.6-ppos    ported Agent application
```

Version 0.3.0 demonstrates an agent-native unikernel composition: pplang owns
bounded system policy and glue, C and assembly own machine-facing mechanisms,
and reviewed external implementations own complex standards such as TLS and
WebAssembly. The result is a statically linked, single-address-space QEMU
x86-64 image with a cooperative core, recovery Shell, network path, and an fx
WASM Agent using DeepSeek's OpenAI-compatible API.

## Product capabilities

- Multiboot v1 boot into x86-64 long mode, VGA and serial output;
- exceptions, timer, keyboard, physical pages, heap, and typed core services;
- cooperative tasks, explicit capabilities, structured logs, and Shell
  supervision;
- interactive Shell editing, history, completion, and masked secret input;
- bounded Ethernet, ARP, IPv4, ICMP, UDP, DNS, one-session TCP, and TLS 1.2;
- bounded HTTP/1.1 status, header, content-length, and chunked-body decoding;
- WAMR-hosted Core WebAssembly with explicit terminal, clock, random, HTTP,
  and configuration capabilities;
- a reproducible fx 0.0.6 port with a DeepSeek provider and no Vercel Gateway
  dependency;
- volatile API-key setup, configurable HTTPS base URL, runtime admission check,
  and explicit secret clearing.

## Build and run

Requirements are pplang/pplc/pptc 0.4.0, `x86_64-elf-*` GCC/binutils, QEMU,
netcat, WAMR 2.4.5, uIP 1.0, BearSSL 0.6, and the reproducibly built fx WASM
artifact. Component source paths remain Make inputs because native C archives
are outside the current pptc package artifact boundary; pplang dependencies are
locked to published Git tags in `pp.lock`.

```bash
make verify \
  PPTC=/path/to/pp \
  OSBARE_DIR=/path/to/osbare \
  PPNET_DIR=/path/to/ppnet \
  PPHTTP_DIR=/path/to/pphttp \
  OSRT_DIR=/path/to/osrt \
  WAMR_DIR=/path/to/wamr \
  UIP_SOURCE=/path/to/uip-1.0 \
  BEARSSL_SOURCE=/path/to/bearssl-0.6 \
  FX_WASM=/path/to/fx-ppos.wasm
```

See [the fx port](ports/fx-ppos/README.md) for the pinned source and build
procedure. The product artifact is `build/ppos-v0.3.0.elf`. `make run` opens
QEMU's display and mirrors serial output; `make run-headless` is serial-only.

At the `pp>` prompt, start with:

```text
help
components
status
network
ping
agent status
agent check
agent setup
agent run
agent clear
```

## Security and scope

The API key is entered through masked Shell input, excluded from history,
passed to the WASM instance at runtime, and never stored in the image, disk,
manifest, or build artifact. `agent clear` zeroes the retained key. The current
HTTP response and Agent session are bounded in memory.

ppos 0.3.0 is not POSIX, Linux, or a general-purpose multi-user OS. It has one
privileged address space, cooperative tasks rather than processes, no userspace
isolation, no SMP, no DHCP or IPv6, and no general filesystem. Capabilities
constrain reviewed interfaces but cannot contain arbitrary native memory
corruption. The release targets QEMU's x86-64 `pc` machine only.

See [Command reference](COMMANDS.md), [Architecture](ARCHITECTURE.md),
[Component matrix](COMPONENTS.md), and [Compatibility](COMPATIBILITY.md).

## License

Licensed under either the Apache License, Version 2.0 or the MIT License, at
your option. External components retain their upstream licenses.
