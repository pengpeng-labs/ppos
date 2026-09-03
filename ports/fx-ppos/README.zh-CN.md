# 面向 ppos 的 fx 移植层

[English](README.md)

本目录是 fx 0.0.6 面向 ppos 的可重复移植层，不纳入上游完整源码，也不
提交生成的 WASM 二进制。`SOURCE.lock` 固定已审阅源码归档，
`fx-ppos.patch` 与 `src/providers/deepseek.zig` 记录本地修改。

移植层保留 fx 的终端界面、Agent 循环、会话和工具分派。仅在 WASM
terminal 构建中，将 Vercel AI Gateway 线协议替换为 DeepSeek 的
OpenAI-compatible Chat Completions 协议；fx 原生版本的行为保持不变。

## 合同

- 默认模型：`deepseek-v4-flash`。
- 默认 Base URL：`https://api.deepseek.com`。
- 公开配置：`DEEPSEEK_BASE_URL`；只接受不含 userinfo、query 和 fragment
  的 HTTPS URL。
- 密钥输入：`DEEPSEEK_API_KEY`；由运行时提供，绝不作为构建输入。
- 流式协议：解析正文、思考内容、分片工具调用、结束原因、生成 ID 和
  token usage。
- 工具调用下一轮所需的 DeepSeek reasoning 通过 fx 的
  `provider_state_json` 传递，不使用进程级全局缓存。
- Host ABI：与上游 `fx-term.wasm` 的 import 集合保持一致。

ppos Host 负责配置界面、密钥生命周期、TLS 信任、网络传输和取消；WASM
模块不持久化明文密钥。

## 构建

```bash
FX_ARCHIVE=/path/to/fx-0.0.6.zip \
ZIG=/path/to/zig \
    ports/fx-ppos/test.sh

FX_ARCHIVE=/path/to/fx-0.0.6.zip \
ZIG=/path/to/zig \
    ports/fx-ppos/build.sh
```

也可以通过 `FX_SOURCE=/path/to/fx-0.0.6` 指定已解压源码。产物写入
`build/fx-ppos/fx-ppos.wasm`，并由 Git 忽略。

fx 使用 Apache-2.0 许可证。源码归档保留上游许可证与 notices，本移植层
单独记录本地修改。
