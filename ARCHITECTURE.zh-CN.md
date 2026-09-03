# ppos 架构

[English](ARCHITECTURE.md)

## 产品组合

ppos 负责镜像组合、发布身份、启动顺序、顶层生命周期、网络配置、trust anchor
和 application authority，不再复制机器、核心、Shell、协议、HTTP 或 WASM runtime
逻辑。

```text
                    +----------------------+
                    | ppos product policy  |
                    +-----+-----+-----+----+
                          |     |     |
                 +--------+     |     +---------+
                 v              v               v
               ossh           ppnet            osrt ---- WAMR ---- fx.wasm
                 |              |                |         C        Zig port
                 |              +---- pphttp ----+
                 +--------------+----------------+
                                v
                             oscore
                                v
                             osbare
                                v
                      QEMU x86-64 machine
```

manifest 锁定 pplang package graph。由于 pptc 0.4 尚不打包 C archive，Make
负责组合 freestanding native archive。ppnet 可复现构建锁定的 uIP 与 BearSSL；
pphttp 包装 picohttpparser；osrt 包装 WAMR；fx port 记录锁定的上游 revision 和
可审阅 patch。ppos 只持有这些合同之上的产品胶水与策略。

## 启动顺序

1. osbare 进入 long mode、快照 Multiboot state 并调用 `osbare_main`。
2. ppos 初始化 oscore 并创建可信 root principal。
3. ppos 初始化 ossh、ppnet、QEMU 静态网络与 TLS trust。
4. ppos 保留有界 WAMR pool，并接纳 Multiboot 传入的 fx module。
5. ppos 注册产品命令并启动 Shell 协作任务。
6. supervisor 推进 oscore，并重启已经停止的 Shell task。
7. `agent run` 使用显式 capability set 创建新的 WAMR instance。

## Agent 数据路径

```text
遮蔽键盘输入 -> ppos 易失 key buffer -> WASM environment
fx DeepSeek provider -> osrt HTTP capability    -> ppos HTTP host
                     -> pphttp response decoder -> ppnet DNS/TCP/TLS
                     -> oscore packet service   -> osbare e1000
```

fx 发出 OpenAI-compatible streaming request。ppos 在传输前创建 Authorization
header，ppnet 使用锁定 trust anchor 验证配置的 HTTPS host，pphttp 解码有界
HTTP/1.1 response，osrt 将 response chunk 暴露给 WASM。API key 不会编译进 fx，
也不会由 ppos 持久化。

## 信任与隔离

Shell 与 native component 都是可信代码并共享 ring 0。root principal 和
capability 在 service 与 WASM host 边界明确 authority；它们是策略检查，不是
native 内存隔离。WAMR 验证并约束 WASM module，但所有 native C、汇编和 pplang
代码仍属于同一个 trusted computing base。

fx instance 只获得 terminal、clock、random、HTTP 与 configuration capability，
没有 block 或 raw packet capability。当前 trust store 只含配置的 DeepSeek endpoint
所需 anchor，不是通用系统 CA store。

## 资源上限

- QEMU memory：384 MiB；
- oscore physical page pool：32,768 pages（128 MiB）；
- WAMR runtime pool：128 MiB；
- WASM linear memory ceiling：2,048 pages（128 MiB）；
- instance host heap：4 MiB；
- buffered HTTP response：512 KiB；
- 同时一个 HTTP/TCP/TLS session；
- 同时一个前台 Agent instance。

这些是 v0.3 的显式产品选择，不是通用扩展性承诺。
