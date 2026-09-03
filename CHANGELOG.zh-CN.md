# 变更记录

## 0.3.0

- 组合 osrt 0.1.1 与 WAMR 2.4.5，形成 capability-gated WASM application host。
- 增加可复现的 fx 0.0.6 port，直接使用 DeepSeek OpenAI-compatible provider。
- 增加 pphttp 0.1.0，以及面向 Agent 的有界 DNS、TCP、TLS、HTTP/1.1 与 SSE
  transport path。
- 增加遮蔽且易失的 API key 配置、HTTPS base URL 配置、runtime admission
  check、取消路径与显式 secret 清除。
- 扩展经过验证的 fx application 所需有界 page pool 与 QEMU memory，同时仍只
  允许一个前台 instance。
- 从 QEMU 镜像验证一次真实 DeepSeek model turn；CI 保持确定性且不含 provider
  secret。

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
