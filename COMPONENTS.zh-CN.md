# 组件矩阵

[English](COMPONENTS.md)

ppos 0.3.0 由 `pp.toml`、`pp.lock`、native build 输入和本发布矩阵共同定义。

| 组件 | 版本 | Commit 或 revision | 职责 |
|---|---:|---|---|
| pplang | 0.4.0 | 发布标签 | 语言语义 |
| pplc | 0.4.0 | 发布标签 | LLVM 编译器 |
| pptc | 0.4.0 | 发布标签 | 依赖与构建工具链 |
| osbare | 0.1.3 | `dc88b69` | x86-64 机器机制 |
| oscore | 0.1.4 | `daf537f` | 系统核心策略 |
| ossh | 0.1.2 | `befc07e` | Shell 与 secret input 策略 |
| ppnet | 0.2.2 | `7fb2bcc` | 网络与 TLS 策略 |
| pphttp | 0.1.0 | `d3c6eef` | HTTP/1.1 response decoder |
| osrt | 0.1.1 | `9e9e4c0` | WASM host 策略与 WAMR adapter |
| WAMR | 2.4.5 | 上游 release | 外置 WebAssembly runtime |
| uIP | 1.0 | 上游 snapshot | TCP/IP 实现 |
| BearSSL | 0.6 | 上游 release | TLS 1.2 实现 |
| picohttpparser | 1.2 | 上游 release | HTTP header parser |
| fx | 0.0.6 | `7966639` + ppos patch | WASM Agent application |
| ppos | 0.3.0 | 发布 commit | 产品组合 |

完整 pplang package commit 与 checksum 以 `pp.lock` 为准；fx source archive
以 `ports/fx-ppos/SOURCE.lock` 为准。外部源码保留各自许可证，不复制进本仓库。
