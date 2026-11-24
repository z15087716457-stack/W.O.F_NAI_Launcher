# 外部 Agent 指引下发、统一入口与工具声明校正

承接[外部会话](external-agent-session-2026-11-13.md)。源码已实现，尚未构建、安装或发布。

## 指引下发

设置 › 桥接与集成 › 外部 Agent 新增「向外部 Agent 下发 Studio 指引」，存于 `AgentSettings.externalGuidance`，默认开启。开启时外部会话能拿到：

- 系统提示词前缀：工作区前缀优先，否则用全局前缀；
- 外部版基础提示词 `naiAgentExternalPromptFor`，按界面语言选中文或英文，位于 `lib/data/services/nai_agent/agent_workspace_store.dart`；
- 用户全局指令；
- 当前工作区已启用、状态正常的 Skill 清单（key、名称、说明、auto/manual）。

外部版只保留业务规则（会话、Skill、草稿保护、权限与付费确认、提示词卡导入规则、ask_user），不含 Pi 的 codemode／mcp__nai_studio 工具映射和 read/write/bash。内置基础提示词或其工作区覆盖、单个对话前缀、工作区 AGENTS.md 仍只给内置 Pi。

下发位置：

- 桥接 `agent_request` 的 `session` 结果带 `guidance`，新增无需会话的 `guidance` 操作（返回 `enabled` 及同样内容，工作区不存在报 `workspace_missing`）；
- MCP `initialize` 的 `instructions` 在原固定说明后追加指引；Studio 未开或 3 秒内无响应时只给固定说明，不影响离线初始化；
- 命令行 `--call` 在首次创建会话（会话文件不存在）时在结果 JSON 里附 `studio_guidance`（原始字段 + 拼好的 `text`），之后复用会话时不再附带。

关闭开关后只提供工具，`guidance` 返回 `{"enabled": false}`。

命令行 stdout 改为纯 ASCII JSON（非 ASCII 字符转成 `\uXXXX`），中文 Windows 的 PowerShell 默认代码页下也不会乱码；MCP stdio 仍是 UTF-8。

## 提示词卡自动展开

外部工具成功创建或更新提示词卡（`prompt_set` 非 read、返回 `set_id`）时，如果侧栏处于收起状态就自动展开，即使用户此前在同一会话里手动收起过。内部对话正在运行、输入框有文字或附件时保持选中内部对话，只展开侧栏并保留外部未读提示；其他情况切到外部会话显示卡片。其余写入仍沿用原规则：首次写入展开一次，手动收起后不再反复展开。

## 统一入口与命令行自带说明

- `studio-bridge.exe --help` 末尾说明业务工具入口；`status` 在 Studio 支持 `agent_tools_v1` 且运行包里有 `nai-agent/node(.exe)` 与 `external-mcp.mjs` 时返回 `business_tools`（`node`、`script`、`help`、`first_step`），源码直跑时不返回。
- `external-mcp.mjs` 新增 `--help`、`--list`（工具名与说明）、`--schema TOOL`（单个工具的输入 schema），三者都离线运行，不进入 MCP 模式；`--args` 接受文件路径或以 `{` 开头的内联 JSON。`--session-file` 仍必填，不在当前目录偷偷建会话文件。
- 设置页与负面页签细线标识「复制接管说明」新增第 6 条：业务工具入口的 node 与脚本绝对路径（按客户端所在 `tools/` 推出）、`--help`、命令行形式、先读 `builtin/nai-studio` Skill，以及新会话附带 `studio_guidance`。五语言同步，繁体由 `tool/l10n` 生成。

## 权限模式只由用户修改

内置 Agent 的 `agent_manage(resource=settings, action=update)` 不再接受 `permissionMode`（任何取值都报 FormatException，提示请用户在设置里改）；`read` 仍返回当前值。`skipPaidConfirmation` 原本就不在可改字段内。

## 工具声明与内置 Skill 校正

- 内置基础提示词（中英，版本 `2026-11-24.1`）与外部版：`studio_context` 只看草稿和参数，看图用 `image_read`。暴露方式固定 codemode 的写法按用户决定保留；改设置里的暴露方式时提示词不会同步。
- V5：`prompt_set` 说明 `noise_schedule`／`smea*`／`variety_plus` 只适用 V4/V4.5；`reference_manage`／`reference_library` 说明 V5 无 Vibe 与精准参考；`references.md`、`models-v5.md`、`blocks.md`（`noiseSchedule`）同步。
- `online_gallery` 与 `gallery.md`：把返回的 `next_cursor` 作为 `cursor` 传入；`gallery_manage` 写明 collection_add/remove 为 1–20 张；`image_tool` 写明 `seedvr2.blocksToSwap` 0–32（7B 为 0–36）。
- `block_manage`：`instance.icon` 用临时积木图标键，`instance.settings` 只接受原生设置键；`blocks.md` 补库内积木可改字段与实例设置取值范围。
- `workspace.md`：长期规则写根 `AGENTS.md`（旧 `.W.O.F/instructions.md` 会被并入）；`nai-prompt` Skill 去掉草稿里不存在的 workflow 字段，改为由 `reference_manage(action=list)` 报告；`tool/nai_agent/README*` 删去不存在的 `nai_agent_sdk_probe`。
- 每个业务工具说明仍控制在 600 字符内（`domain-tools.test.mjs`）。
## 验证

见本次交付记录；不调用真实生成接口。
