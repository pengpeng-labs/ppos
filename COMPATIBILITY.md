# Compatibility

[Simplified Chinese](COMPATIBILITY.zh-CN.md)

ppos 0.3.0 targets QEMU's x86-64 `pc` machine with Multiboot v1, a PS/2
keyboard, ATA disk, and Intel e1000 device. The release is not a general PC
hardware compatibility claim.

The build requires pplang, pplc, and pptc 0.4.0. It locks ossh 0.1.2, ppnet
0.2.2, pphttp 0.1.0, osrt 0.1.1, oscore 0.1.4, and osbare 0.1.3. Native
composition was verified with WAMR 2.4.5, uIP 1.0, BearSSL 0.6, and fx 0.0.6.

Networking assumes QEMU user networking at `10.0.2.0/24`. The DeepSeek port
uses `https://api.deepseek.com`, `deepseek-v4-flash`, an OpenAI-compatible Chat
Completions stream, TLS 1.2, and the included endpoint trust anchor. Provider
behavior can change independently of this release.

POSIX, WASI Preview 2, browser Web APIs, DHCP, IPv6, multiple simultaneous TCP
sessions, a general CA store, process isolation, and general PC deployment are
not provided. The fx application uses the Core WebAssembly/WASI Preview 1
surface admitted by osrt and WAMR; arbitrary WASM applications are not implied
to be compatible.
