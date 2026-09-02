# 变更记录

## 0.2.0

- 在同一个 oscore 0.1.3 instance 上组合 ossh 0.1.1 与 ppnet 0.2.0。
- 增加有界 QEMU 静态网络策略，以及产品级 network/ping 命令。
- 通过 ppnet 链接锁定的 uIP/BearSSL，不复制协议代码。
- 验证产品镜像通过 ppnet ICMP 到达 QEMU gateway。

## 0.1.0

- 将 osbare、oscore 与 ossh v0.1.0 组合为可启动产品镜像。
- 增加发布身份与组件身份命令。
- 增加协作式 Shell 生命周期监督。
- 增加图形与 headless QEMU 运行目标。
- 增加产品级交互验收和组件边界检查。
