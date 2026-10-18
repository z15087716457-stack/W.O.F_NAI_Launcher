# 2.0 Preview r26 · 合并三条待并分支与 Agent 指挥台累计更新

按用户“全部交给你了，合并然后推送一波更新”，于 2026-10-18T20:48:47.390378+08:00 安装到原桌面入口。内部版本 `2.0.0-preview+30`，编译提交 `f2aabde565b8d723585c4b3713589e29063ba8be`；后续文档提交不代表重新编译。

## 合并

起点 `5a9335e2a`（Agent 指挥台接线完成）。依次并入：

| 分支 | 合并提交 | 内容 |
|---|---|---|
| `devin/ui-channel-more` `6357c25ba` | 无冲突 | 画布通道新增机芯／地层／地铁／乐谱／月相，存储 v1→v2 [说明](canvas-channel-themes-v2-2026-10-18.md) |
| `devin/ui-model-providers` `c84f72aad` | `a75f9eb1a` | 服务商工作台前端（方案 B）与 3.47.7 基准 |
| `devin/model-providers-wiring` `77434c048` | 无冲突 | 工作台接到真实配置，退役旧服务商列表 [说明](model-providers-wiring-2026-10-18.md) |

l10n 冲突只出现在 ARB 末尾追加区（Agent Skill／指挥台 vs `mp_*`）。四份手写 ARB 按键做三方合并并逐键校验（无同键异值），繁中 ARB 与 `app_localizations*.dart` 重新生成，不手改。旧服务商退役的 12 个键与旧回调在 lib／test／tool 无残留引用。合并未涉及代码生成输入。

## 验证

- 登记 SDK 3.47.7：`flutter analyze --no-pub lib test tool` 无问题。
- `test/presentation/ui`、`test/presentation/wiring`、`test/l10n`、通道 provider、`prompt_assistant`、`screens/settings`、`app_test`：合并后 **3215 通过／31 失败**；合并前 `5a9335e2a` 用临时 worktree（复制生成文件与 `.dart_tool` 配置，`--no-pub`）同命令 **3103 通过／31 失败**，失败集合逐项相同，新增失败 0。31 项为既有：通道旧 PNG 24、设置页 `dictionaries`／`models`／`models-dark` 3、`tools_wiring` 2、`settings_hover_feedback` 1、`model_menu_activity` 1。
- `tool/nai_agent` 用内置 Node 24.18.0 跑 48／48。证据 `.dart_tool/merge-r26-20261018/`。

## 构建与安装

- 1978 项生产输入固定后 Windows Release；原生身份 `com.example/nai_launcher`、版本 30、15286 个程序文件、226 个资源（无删减，本次资源无变化）、四份 SQLite、字体与原生依赖 PE 导入核验通过。
- **Agent 运行时整体同步**：Pi 全家 1.1.0→1.3.0、内置 `skills/nai-studio`／`skills/nai-prompt`、`list-skills.mjs`、`lib/skills.mjs` 及宿主更新；移除旧 `manuals/` 与 1.2.0 起上游退出的 chord／esbuild 共 187 个文件。`node.exe`／许可文件沿用原件。打包后 `list-skills` 列出两个内置 Skill 无错误；打包 Agent 只对本地合成服务做 CodeMode／会话恢复冒烟；RAG 宿主只 ready／shutdown。
- 安装器在 r25 基础上增加“删除已退役文件”：删除前逐个校验哈希并备份到 `rollback/removed/`，失败时恢复删除与替换，回退时一并还原；12 项夹具（含删除失败、退役文件被改动拒装）通过。共改动 493 个（含新增 116）、删除 187 个。
- 覆盖前确认无运行进程；安装后逐文件哈希、收据、单步回退完整性通过，未执行真实回退。桌面入口、`user-data`、`agent-data`、兼容联接与 3 个索引文件元数据保持，未打开正式 SQLite。

迁移备份 `.studio-data-backup-b633375b/` 已由用户在本次安装前自行清理（用户确认）；安装器不再要求其存在。

AOT SHA-256：`18e3698abf5b8e3594ddc064346234c4d7f02f1b234c14df0af11fe985a06640`。证据 `.dart_tool/cumulative-r26-20261018/`，正式收据与 `installed-delivery.json` 一致。未自动启动／重启／热重载、生图、建库、制作便携包或推送 GitHub。
