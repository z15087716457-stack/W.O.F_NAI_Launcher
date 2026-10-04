# 外部 Agent 与本机桥接

设置 → 连接与集成 → 本机桥接。启用后，负面页签右侧的细线标识可复制接手说明、查看最近动作或结束 Agent 连接。Krita 单独展示连接状态，可与多个外部 Agent 同时使用。客户端名称是本机密钥认证后的自报名称，不是厂商认证。

## Windows 客户端

安装包与便携包把 `studio-bridge.exe` 放在 Studio 可执行文件同级的 `tools/` 内。无需安装 Python；客户端需要能够执行本机命令的 Agent。复制说明本身不建立连接，每个命令结束自动断开。

PowerShell 示例（按实际安装路径替换）：

```powershell
$studioBridge = 'C:\Your Studio	ools\studio-bridge.exe'
& $studioBridge status --name Codex
& $studioBridge get --name Codex --out current.json
& $studioBridge set steps=28 --base current.json --name Codex
& $studioBridge set-json changes.json --base current.json --name Codex
```

`get` 的 `_draft.fields` 是可编辑原文，`_draft.documents` 是对应积木文档，`field_versions` 是冲突检查版本。顶层提示词是生效视图，可能含预设；不要重复写进原文。只写用户要求的字段。`characters` 是整个列表替换，必须保留无关角色及原 id、名称、启用状态和位置；未传此字段就不修改角色。参考图目前只读。

写入前验证整个修改、备份完整可编辑状态，再比较目标字段的最新版本。积木结构变化也算冲突；模型变化同时检查采样器。备份失败、冲突或生成忙碌均不写入。备份位于发现文件同级 `draft-backups/`，回复包含 `backup_path`；`set` 命令还返回当前回读。恢复备份应先读取当前状态并逐字段确认，不直接盲覆。

## 报价与生成

接入和填参不授权生成。只有用户明确要求生成，才先报价、报告预计单价和当前已载入余额，然后执行：

```powershell
& $studioBridge quote --out quote.json --name Codex
# 向用户报告 billing.estimated_anlas 与 billing.balance_anlas，已有明确生成授权。
& $studioBridge gen --quote quote.json --authorized --out result.png --name Codex
```

报价读取现有账号数据并进行本地估算，不请求生成或额外刷新余额；实际计费以 NovelAI 服务端为准。客户端发现余额不可用会停止。一次报价固定一张，5 分钟有效且只能用一次，绑定客户端名称、账号、当前草稿 / 积木 / 参考图和冻结参数；变化时重新报价，不能把新参数塞进旧报价。`ui-gen` 与 `gen` 使用相同约束。

可用 Studio 原停止按钮或 Esc；客户端 Ctrl+C 会取消当前任务，也可用输出的 request_id：

```powershell
& $studioBridge cancel REQUEST_ID --name Codex
```

关闭生成命令连接会取消该连接拥有的任务。关闭其他 Agent / Krita 不取消它。取消命令必须使用同一 Agent 名称和匹配的请求 id。

## 连接与协议

- 仅监听 `127.0.0.1`，端口和会话密钥从 `%APPDATA%/nai-launcher/krita-bridge.json` 发现；重新启用或重新生成会话会更换密钥。不要输出发现文件正文。
- V1 ping 可带 `client: {kind: agent|krita, name: ...}`；旧 Krita ping 不受影响。新客户端先检查 pong 的 multi_client / guarded_set / raw_draft 能力，旧 Studio 不盲写。
- 同时最多 16 个连接；未认证连接 5 秒超时。一个修改或生成任务占用写入槽，其他写入返回 busy，读取允许继续。不要无间隔重试。
- 回复、进度和结果按连接隔离，相同请求 id 在不同客户端不会串线。客户端失败或断开会释放自己的请求；未指定请求的发送图片只推给 Krita。
- 界面服务保留 8 条动作摘要，面板显示最近 5 条；不记录完整提示词、修改 JSON、图片或会话密钥。正在执行的生成不会因读取历史滚动而消失。
- Python 兼容脚本提供读写；生成迁移到独立 Windows 客户端。

## 验证边界

本轮使用隔离临时目录、模拟余额和图像完成协议 / 写入 / 客户端测试，没有向真实账号调用翻译、认证或生成接口。生产控件使用实际字体验证五语言、深浅色、360 / 480px、125% DPI。真实账号生成仅在用户明确要求后另测。
