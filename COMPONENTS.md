# Component matrix

[Simplified Chinese](COMPONENTS.zh-CN.md)

ppos 0.2.0 is reproducibly defined by `pp.toml`, `pp.lock`, and this release
matrix.

| Component | Version | Commit | Responsibility |
|---|---:|---|---|
| pplang | 0.4.0 | release tag | Language semantics |
| pplc | 0.4.0 | release tag | LLVM compiler |
| pptc | 0.4.0 | release tag | Dependency and build toolchain |
| osbare | 0.1.1 | `67a3d12` | x86-64 mechanisms |
| oscore | 0.1.3 | `155c6d0` | System core policy |
| ossh | 0.1.1 | `c514284` | System Shell policy |
| ppnet | 0.2.0 | `04e0cf1` | Network policy and adapters |
| ppos | 0.2.0 | release commit | Product composition |

`pp.lock` is normative for full commit hashes and source checksums. The short
hashes here are review aids.
