# Component matrix

[Simplified Chinese](COMPONENTS.zh-CN.md)

ppos 0.3.0 is defined by `pp.toml`, `pp.lock`, the native build inputs, and this
release matrix.

| Component | Version | Commit or revision | Responsibility |
|---|---:|---|---|
| pplang | 0.4.0 | release tag | Language semantics |
| pplc | 0.4.0 | release tag | LLVM compiler |
| pptc | 0.4.0 | release tag | Dependency and build toolchain |
| osbare | 0.1.3 | `dc88b69` | x86-64 mechanisms |
| oscore | 0.1.4 | `daf537f` | System core policy |
| ossh | 0.1.2 | `befc07e` | Shell and secret input policy |
| ppnet | 0.2.2 | `7fb2bcc` | Network and TLS policy |
| pphttp | 0.1.0 | `d3c6eef` | HTTP/1.1 response decoder |
| osrt | 0.1.1 | `9e9e4c0` | WASM host policy and WAMR adapter |
| WAMR | 2.4.5 | upstream release | External WebAssembly runtime |
| uIP | 1.0 | upstream snapshot | TCP/IP implementation |
| BearSSL | 0.6 | upstream release | TLS 1.2 implementation |
| picohttpparser | 1.2 | upstream release | HTTP header parser |
| fx | 0.0.6 | `7966639` + ppos patch | WASM Agent application |
| ppos | 0.3.0 | release commit | Product composition |

`pp.lock` is normative for complete pplang package commits and checksums.
`ports/fx-ppos/SOURCE.lock` is normative for the fx source archive. External
sources retain their own licenses and are not copied into this repository.
