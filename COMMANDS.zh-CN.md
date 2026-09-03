# ppos 0.3.0 命令参考

[English](COMMANDS.md)

`pp>` 提示符由 ossh 提供。命令是在 ppos 单地址空间内同步执行的可信系统操作，
不会启动进程。

## 产品命令

| 命令 | 作用 |
|---|---|
| `version` | 输出 ppos 发布版本。 |
| `components` | 输出固定的 osbare、oscore、ossh、ppnet 和 ppos 版本。 |
| `supervisor` | 查看 Shell 任务槽位、状态、运行次数和重启次数。 |
| `network` | 查看静态网络 readiness 与 transport 上限。 |
| `ping` | 向配置的 QEMU gateway 发送一次有界 ICMP echo。 |
| `agent status` | 查看 provider、易失 key 状态、module size 与 base URL。 |
| `agent check` | 加载并实例化随镜像提供的 fx module，但不运行。 |
| `agent setup` | 将遮蔽输入的 DeepSeek key 放入易失内存。 |
| `agent base <https-url>` | 修改易失 provider base URL。 |
| `agent run` | 将 fx 作为前台 WASM Agent application 运行。 |
| `agent clear` | 清零保留的 provider key。 |

示例：

```text
pp> components
osbare 0.1.3
oscore 0.1.4
ossh 0.1.2
ppnet 0.2.2
pphttp 0.1.0
osrt 0.1.1
fx 0.0.6-ppos
ppos 0.3.0

pp> supervisor
shell_task=0 state=1 runs=32 restarts=0
```

任务状态 `1` 表示 ready，`2` 表示 waiting，`3` 表示 stopped。Shell 处理命令
时通常是 ready，没有键盘输入时通常是 waiting。

## 系统检查

| 命令 | 作用 | Capability |
|---|---|---|
| `status` | 查看核心初始化状态、单调 ticks 和服务数量。 | `system.inspect` |
| `memory` | 查看有界物理页池和 64 KiB 核心堆。 | `system.inspect` |
| `tasks` | 列出活动协作任务的槽位、状态与运行次数。 | `system.inspect` |
| `services` | 列出类型化服务、可用性、版本和所需 capability。 | `system.inspect` |
| `log` | 读取 oscore 保留的结构化日志。 | `system.inspect` |
| `ticks` | 输出当前单调时钟 tick。 | `clock` |

ppos v0.3.0 的 Shell 使用可信 root principal，因此发布镜像可以执行这些命令。
未来使用受限 principal 时，缺少对应 capability 会返回 `permission denied`。

## Shell 工具

| 命令 | 作用 |
|---|---|
| `help` | 列出所有已注册命令和摘要。 |
| `about` | 说明 ossh 及其角色。 |
| `echo <args...>` | 输出最多七个以空格分隔的参数。 |
| `history` | 列出最近十六条不连续重复的命令行。 |
| `clear` | 推进并清理有界文本视口。 |

tokenizer 最多接受八个以空白分隔的 token，包含命令名。v0.3.0 不解释引号、
转义、变量、重定向、管道、glob 或 Shell 脚本。

## 编辑按键

| 按键 | 行为 |
|---|---|
| `Tab` | 补全唯一命令名，或者列出全部匹配命令。 |
| `Up` / `Down` | 浏览命令 history。 |
| `Left` / `Right` | 移动插入光标。 |
| `Home` / `End` | 移动到行首或行尾。 |
| `Backspace` | 删除光标前一个字节。 |
| `Delete` | 删除光标位置的字节。 |
| `Enter` | 保存、解析并执行当前行。 |

输入使用 PS/2 Set-1 US ASCII 布局。可编辑行上限为 255 字节；UTF-8 组合输入和
可选键盘布局不属于 v0.3。

## Agent 输入

`agent setup` 会遮蔽输入字节、排除 history，并将 Escape 视为取消。`agent run`
会暂时把 terminal input 交给 fx；Enter、Backspace、Tab、Escape 与方向键会转换为
WASM application 所需 terminal byte sequence。退出 fx 后回到 `pp>`。

key 与 base URL 都不会跨重启持久化。不再需要 key 时应执行 `agent clear`。
