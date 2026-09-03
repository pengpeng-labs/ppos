# ppos

[English](README.md)

`ppos` 是 pp 系统栈的可启动产品镜像。它组合独立发布的组件和外置标准实现，
不在产品仓库中复制各子系统的实现。

```text
ppos 0.3.0 镜像
├── ossh 0.1.2       可信系统 Shell 与 secret input
├── ppnet 0.2.2      有界网络与 TLS 策略
├── pphttp 0.1.0     有界 HTTP/1.1 response 解码
├── osrt 0.1.1       capability-gated WASM application host
├── oscore 0.1.4     内存、任务、事件、capability 与 service
├── osbare 0.1.3     x86-64 启动和机器机制
├── WAMR 2.4.5       外置 WebAssembly runtime
└── fx 0.0.6-ppos    移植后的 Agent application
```

v0.3.0 验证了一种 agent-native unikernel 组合方式：pplang 负责有界系统策略与
胶水，C 和汇编负责机器机制，TLS、WebAssembly 等复杂标准交给经过审阅的外部实现。
最终产物是静态链接、单地址空间的 QEMU x86-64 镜像，包含协作式核心、恢复 Shell、
网络路径，以及通过 DeepSeek OpenAI-compatible API 工作的 fx WASM Agent。

## 产品能力

- Multiboot v1 进入 x86-64 long mode，提供 VGA 与串口输出；
- 异常、时钟、键盘、物理页、heap 与类型化核心 service；
- 协作任务、显式 capability、结构化日志与 Shell supervision；
- Shell 行编辑、history、补全和遮蔽的 secret input；
- 有界 Ethernet、ARP、IPv4、ICMP、UDP、DNS、单 session TCP 与 TLS 1.2；
- 有界 HTTP/1.1 status、header、content-length 与 chunked body 解码；
- WAMR 托管的 Core WebAssembly，以及显式 terminal、clock、random、HTTP 和
  configuration capability；
- 可复现的 fx 0.0.6 port、DeepSeek provider，并移除 Vercel Gateway 依赖；
- 易失 API key 配置、可配置 HTTPS base URL、runtime admission check 与显式清密钥。

## 构建与运行

需要 pplang/pplc/pptc 0.4.0、`x86_64-elf-*` GCC/binutils、QEMU、netcat、
WAMR 2.4.5、uIP 1.0、BearSSL 0.6 和可复现构建的 fx WASM 产物。native C archive
仍在当前 pptc package artifact 边界之外，所以组件源码路径继续作为 Make 输入；
pplang 依赖则通过 `pp.lock` 固定到正式 Git tag。

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

锁定源码与构建过程见 [fx port](ports/fx-ppos/README.zh-CN.md)。产品产物是
`build/ppos-v0.3.0.elf`。`make run` 打开 QEMU 图形窗口并镜像串口输出，
`make run-headless` 只使用串口。

进入 `pp>` 后可以先执行：

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

## 安全与边界

API key 通过遮蔽的 Shell 输入，排除在 history 之外，只在运行时传入 WASM
instance，绝不写入镜像、磁盘、manifest 或构建产物。`agent clear` 会清零保留的
密钥。当前 HTTP response 与 Agent session 都使用有界内存。

ppos 0.3.0 不是 POSIX、Linux 或通用多用户操作系统。它只有一个特权地址空间，
使用协作任务而非进程，没有用户态隔离、SMP、DHCP、IPv6 或通用文件系统。
capability 可以约束经过审阅的接口，但不能隔离任意 native 内存破坏。本发布只面向
QEMU x86-64 `pc` machine。

详细内容见[命令参考](COMMANDS.zh-CN.md)、[架构](ARCHITECTURE.zh-CN.md)、
[组件矩阵](COMPONENTS.zh-CN.md)和[兼容性](COMPATIBILITY.zh-CN.md)。

## 许可证

用户可以选择 Apache License 2.0 或 MIT License。外部组件保留各自上游许可证。
