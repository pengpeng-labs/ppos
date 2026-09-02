# 兼容性

[English](COMPATIBILITY.md)

ppos 0.2.0 面向 QEMU x86-64 `pc` machine，使用 Multiboot v1、模拟 PS/2
键盘、ATA 磁盘和 Intel e1000 网卡。发布镜像不代表对通用 PC 硬件的兼容承诺。

构建要求 pplang、pplc 和 pptc 0.4.0。组件源码 commit 与 checksum 固定在
`pp.lock` 中。本版本不提供 POSIX 兼容性。

本发布锁定 ossh 0.1.1、ppnet 0.2.0、oscore 0.1.3 与 osbare 0.1.1。网络假设为
`10.0.2.0/24` 的 QEMU user networking；不提供 DHCP、IPv6 或系统 CA store。
