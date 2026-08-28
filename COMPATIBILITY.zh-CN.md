# 兼容性

[English](COMPATIBILITY.md)

ppos 0.1.0 面向 QEMU x86-64 `pc` machine，使用 Multiboot v1、模拟 PS/2
键盘、ATA 磁盘和 Intel e1000 网卡。发布镜像不代表对通用 PC 硬件的兼容承诺。

构建要求 pplang、pplc 和 pptc 0.4.0。组件源码 commit 与 checksum 固定在
`pp.lock` 中。本版本不提供 POSIX 兼容性。
