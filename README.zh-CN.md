# ppos

[English](README.md)

`ppos` 是 pp 系统栈的可启动产品镜像。它负责组合有版本的组件，不把各组件实现
重新收进同一个仓库。

```text
ppos 0.2.0 镜像
├── ossh 0.1.1       系统交互策略
├── ppnet 0.2.0      有界网络策略与协议 adapter
├── oscore 0.1.3     内存、任务、事件、能力与服务
└── osbare 0.1.1     x86-64 启动和机器机制
```

v0.2.0 证明了 pplang 组件能够定义一个小型操作系统产品，同时让 C 和汇编继续
承担它们更适合的机器工作。最终产物是静态链接、单地址空间的 QEMU x86-64 镜像，
包含协作式系统核心与交互式恢复 Shell。

## 产品能力

- 通过 Multiboot v1 进入 x86-64 long mode；
- 原始 VGA 与串口 console；
- 异常、时钟和键盘事件机制；
- 有界物理页与核心堆分配；
- 结构化日志与 generation-safe 资源；
- 协作式轮询任务与显式 capability；
- 类型化 console、clock、entropy、block、packet、input 和 log 服务；
- 支持编辑、history、补全和命令注册的交互式 Shell；
- version、组件矩阵和 Shell supervisor 产品命令；
- Shell 任务内部失败后的自动重建策略。
- 有界 Ethernet/ARP/IPv4/ICMP/UDP/DNS 与单 session TCP/TLS 组合；
- 产品级 network 状态与 QEMU gateway ping 命令。

## 构建与运行

需要 pplang/pplc/pptc 0.4.0、`x86_64-elf-*` GCC/binutils、QEMU 和
netcat。将 osbare v0.1.1 和 ppnet v0.2.0 checkout 放在相邻目录，或显式指定路径：

```bash
make \
  PPTC=/path/to/pptc/target/debug/pp \
  OSBARE_DIR=/path/to/osbare \
  PPNET_DIR=/path/to/ppnet

make run \
  PPTC=/path/to/pptc/target/debug/pp \
  OSBARE_DIR=/path/to/osbare \
  PPNET_DIR=/path/to/ppnet
```

产品产物是 `build/ppos-v0.2.0.elf`。`make run` 打开 QEMU 平台图形窗口，
同时把串口输出写到当前终端；只使用串口时运行 `make run-headless`。

进入 `pp>` 后可以先执行：

```text
help
components
status
memory
services
tasks
supervisor
network
ping
```

## 版本边界

ppos 0.2.0 组合 ppnet，但仍明确不包含文件系统语义、数据库、POSIX 层、用户态、
WASM runtime、HTTP client 或 Agent。网络配置目前固定面向 QEMU。TLS 要求 caller
提供 trust anchor；产品不会把测试证书伪装成系统 CA store。

详细内容见[命令参考](COMMANDS.zh-CN.md)、[架构](ARCHITECTURE.zh-CN.md)、
[组件矩阵](COMPONENTS.zh-CN.md)和[兼容性](COMPATIBILITY.zh-CN.md)。

## 许可证

用户可以选择 Apache License 2.0 或 MIT License。
