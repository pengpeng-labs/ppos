# ppos 架构

[English](ARCHITECTURE.md)

## 产品，而不是另一个子系统

ppos 负责镜像组合、发布身份、启动顺序和顶层生命周期策略，不再复制硬件、核心或
Shell 逻辑。正常依赖方向只有：

```text
ppos -> ossh -> oscore -> osbare -> x86-64 机器
```

manifest 只把 ossh 声明为直接包依赖，pptc 传递解析并锁定 oscore 与 osbare。
最终 ELF 组合链接 osbare 发布的入口对象与静态 archive，因为启动策略仍在 pplang
包产物边界之外。

## 启动顺序

1. osbare 快照 Multiboot 状态并调用 `osbare_main`。
2. ppos 校验并初始化 oscore。
3. ppos 为可信系统策略创建 root principal。
4. ppos 初始化 ossh 并注册产品命令。
5. ppos 把 Shell 回调注册进协作任务表。
6. supervisor 持续推进 oscore 并观察 Shell 状态。

镜像入口类型和核心初始化前不可恢复错误的 halt，是 ppos 策略仅有的 osbare ABI
接触点；正常运行只使用 ossh 与 oscore 合同。

## Supervisor

Shell 是可信轮询任务，不是进程。如果任务进入 stopped 状态，ppos 记录结果、回收
旧槽位、使用同一个 root principal 创建新 Shell 任务、递增重启计数并重绘提示符。
这是生命周期恢复，不是内存或权限隔离。

## 信任边界

v0.1 所有代码共享一个地址空间并以机器特权运行。capability 用于在可审阅的服务
边界防止意外越权，不能抵御任意内存破坏。未来普通应用应放在 osrt 与外置、经过
验证的 WASM runtime 后面。
