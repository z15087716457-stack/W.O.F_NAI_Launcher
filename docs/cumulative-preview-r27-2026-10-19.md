# 2.0 Preview r27 · Agent 侧栏灰屏与设置页修正累计更新

按用户“一起装到桌面”，于 2026-10-19T13:34:44.152662+08:00 安装到原桌面入口。内部版本 `2.0.0-preview+31`，编译提交 `3d7c64e0069ac0a32ba5a540deb76dd6708655af`；后续文档提交不代表重新编译。

## 内容（r26 之后）

| 提交 | 内容 |
|---|---|
| `b41946901` | 内置 Skill 简介按界面语言显示（中文／繁中显示中文，其余英文），`SKILL.md` 保持英文给模型；“自动调用／仅手动调用”标签加悬停说明 |
| `8dab9fb8b` | “本工作区规则”的“编辑”把 `instructions.md` 当文件夹打开而报错，改为用系统编辑器打开文件（缺失时建空文件），设置行补说明；内置系统提示词与拼接说明按界面语言切换中／英，自定义提示词不变 |
| `e7d908cb3` | 块库有块时 Agent 侧栏每次构建抛 `NoSuchMethodError`（`agentBlockMentions` 的 `?? []` 推成 dynamic，读了不存在的 `block.name`），展开后整块灰屏；改为类型化列表并读 `title`。提示词工具菜单的 NAI Agent 图标换成 `AgentMark` |

灰屏根因来自用户机器 `Documents/NAI_Launcher/logs/crash_diagnostics/`：最近 147 条 `NoSuchMethodError` 全部指向 `agent_context.dart:92`。新增回归测试在旧代码上复现同一错误。

## 验证

- 登记 SDK 3.47.7：`flutter analyze --no-pub lib test` 无问题。
- `test/presentation/ui`、`wiring`、`l10n`、`core/nai_agent`、`providers/nai_agent`、`prompt_assistant`、`screens/settings`、`app_test`：**3554 通过／31 失败**，失败集合与 r26 合并后 `merged-fails.txt` 逐项相同。另有一轮多出 `extensions_test` 宿主启动超时 1 项，满载偶发，单独运行通过。
- `tool/nai_agent` 内置 Node 24.18.0：48／48。

## 构建与安装

- 1978 项生产输入固定后 Windows Release。本次重链接的 16 个插件 DLL 与已装版本仅差 PE 链接时间戳（COFF 与调试目录，各 6 字节），用 `pe_stamp.py` 核对，并有改动代码字节的反向对照；已装 DLL 保留原件不替换。
- 只改动 3 个文件：`data/app.so`、`nai_launcher.exe`、`app_files_manifest.json`；资源、Agent 运行时无变化，无删除。打包 Agent 合成冒烟、`list-skills`、RAG 宿主 ready／shutdown、12 项安装回退夹具通过。
- 覆盖前确认无运行进程；安装后逐文件哈希、收据、单步回退完整性通过，未执行真实回退。桌面入口、`user-data`、`agent-data` 与 3 个索引文件元数据保持。

AOT SHA-256：`44afd141f44ab7e449a41f9c2478a5be5703811b195444277534aba90d7e6886`。证据 `.dart_tool/cumulative-r27-20261019/`。未自动启动、生图、建库、制作便携包或推送 GitHub。
