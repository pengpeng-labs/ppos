# 组件矩阵

[English](COMPONENTS.md)

ppos 0.2.0 由 `pp.toml`、`pp.lock` 和本发布矩阵共同给出可复现定义。

| 组件 | 版本 | Commit | 职责 |
|---|---:|---|---|
| pplang | 0.4.0 | 发布标签 | 语言语义 |
| pplc | 0.4.0 | 发布标签 | LLVM 编译器 |
| pptc | 0.4.0 | 发布标签 | 依赖与构建工具链 |
| osbare | 0.1.1 | `67a3d12` | x86-64 机器机制 |
| oscore | 0.1.3 | `155c6d0` | 系统核心策略 |
| ossh | 0.1.1 | `c514284` | 系统 Shell 策略 |
| ppnet | 0.2.0 | `04e0cf1` | 网络策略与 adapter |
| ppos | 0.2.0 | 发布 commit | 产品组合 |

完整 commit 和源码 checksum 以 `pp.lock` 为准，这里的短 hash 用于人工审阅。
