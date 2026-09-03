# 兼容性

[English](COMPATIBILITY.md)

ppos 0.3.0 面向 QEMU x86-64 `pc` machine，使用 Multiboot v1、PS/2 键盘、
ATA 磁盘和 Intel e1000 device。本发布不代表对通用 PC 硬件的兼容承诺。

构建要求 pplang、pplc 和 pptc 0.4.0，并锁定 ossh 0.1.2、ppnet 0.2.2、
pphttp 0.1.0、osrt 0.1.1、oscore 0.1.4 与 osbare 0.1.3。native 组合已使用
WAMR 2.4.5、uIP 1.0、BearSSL 0.6 和 fx 0.0.6 验证。

网络假设为 `10.0.2.0/24` 的 QEMU user networking。DeepSeek port 使用
`https://api.deepseek.com`、`deepseek-v4-flash`、OpenAI-compatible Chat
Completions stream、TLS 1.2 与仓库内 endpoint trust anchor。provider 行为可能
独立于本发布发生变化。

本版本不提供 POSIX、WASI Preview 2、browser Web API、DHCP、IPv6、多并发 TCP
session、通用 CA store、进程隔离或通用 PC 部署。fx 使用 osrt 与 WAMR 接纳的
Core WebAssembly/WASI Preview 1 surface；这不意味着任意 WASM application 都兼容。
