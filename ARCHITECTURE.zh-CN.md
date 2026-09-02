# ppos 架构

[English](ARCHITECTURE.md)

## 产品，而不是另一个子系统

ppos 负责镜像组合、发布身份、启动顺序和顶层生命周期策略，不再复制硬件、核心或
Shell 逻辑。正常依赖方向只有：

```text
ppos -> ossh  -> oscore -> osbare -> x86-64 机器
     -> ppnet -> oscore
```

manifest 将 ossh 和 ppnet 声明为直接包依赖，两者共享同一个锁定的 oscore 0.1.3
instance；pptc 传递锁定 osbare。最终 ELF 组合链接 osbare 发布的入口对象，以及
ppnet 可复现构建的 uIP/BearSSL archive。启动与 native archive 组合仍在 pplang
包产物边界之外。

## 启动顺序

1. osbare 快照 Multiboot 状态并调用 `osbare_main`。
2. ppos 校验并初始化 oscore。
3. ppos 为可信系统策略创建 root principal。
4. ppos 初始化 ossh 和 ppnet oscore port。
5. ppos 安装有界的 QEMU 静态网络策略并初始化 TCP。
6. ppos 注册产品命令与 Shell 协作任务。
7. supervisor 持续推进 oscore 并观察 Shell 状态。

镜像入口类型和核心初始化前不可恢复错误的 halt，是 ppos 策略仅有的 osbare ABI
接触点；正常运行只使用 ossh、ppnet 与 oscore 合同。ppnet 持有协议状态，ppos
持有配置与 authority。

## Supervisor

Shell 是可信轮询任务，不是进程。如果任务进入 stopped 状态，ppos 记录结果、回收
旧槽位、使用同一个 root principal 创建新 Shell 任务、递增重启计数并重绘提示符。
这是生命周期恢复，不是内存或权限隔离。

## 信任边界

v0.1 所有代码共享一个地址空间并以机器特权运行。capability 用于在可审阅的服务
边界防止意外越权，不能抵御任意内存破坏。未来普通应用应放在 osrt 与外置、经过
验证的 WASM runtime 后面。

TLS code 通过 ppnet 进入镜像，但 ppos v0.2 不安装全局 trust store。未来 application
或 packaging component 必须先提供显式 trust anchor，才能打开 TLS session。
