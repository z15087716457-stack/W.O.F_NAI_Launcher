# 2.0 Preview r29 · NAI Agent 侧栏功能批次累计更新

用户 2026-10-20 说“推送更新吧”，按 2026-10-15 的本地交付约定安装到原桌面入口，没有推送 GitHub。内部版本 `2.0.0-preview+33`，编译提交 `3841249778658642f1929c4105192bd3002b5115`；之后的文档提交不代表重新编译。

## 内容（r28 之后）

| 提交 | 内容 |
|---|---|
| `13ea19e55` | 没有实际增删的改动栏（+0 −0）不再出卡；未命名角色显示“角色 N”；设置页 Skill “⋯”菜单不再闪（弹层淡入按每次打开重放） |
| `4ae841a95` | 角色位置卡改为按画面比例的自由坐标小板，只列移动了的角色，AI 选择时只显示一句说明；附件悬停卡可移入、滚动、选中，显示完整提示词与角色提示词；内置提示词删去一句 |
| `884cad396` | 生图参数改动卡（只列当前模型适用的参数），可撤销；多张可撤销卡时出“全部撤销”，一次写入草稿 |
| `550d794f7` | 欢迎页快捷信息可在设置里自定义；本地语义搜索工具 `studio_search`；“完全权限”档后端；对话／工作区回收与撤销；新对话首发前不落盘；正文搜索 |
| `191b7d49f` | 完全权限界面（首次提醒、警示色）；删除确认与撤销提示；聊天列表正文搜索；产物图悬停／右键快捷动作（Vibe、精确参考、载入参数、在文件夹中显示）；出错重试；用量弹层估算 Anlas；收起侧栏时开关小圆点 |
| `82d6156aa` | 内置提示词改为通用短版；权限菜单从低到高排列 |
| `8e41b1b72` | 测试固定 Agent 一次生成在历史栏成一组 |
| `36046fee1` | 工具与 Skill 体检：描述去掉防御性尾句（14.3k → 11.4k 字符）、修正 `blocks.md` 过时调用式、只读模式放行 `image_generate` status／cancel、语义搜索步骤中文名、设置页“工具与 Skill” |

## 验证

- 登记 SDK 3.47.7：`flutter analyze --no-pub lib test` 无问题。
- 同 r28 的回归范围另加 `test/presentation/widgets/nai_agent`：**3825 通过／31 失败**，失败集合与 `merged-fails.txt` 逐项相同（`.dart_tool/agent-fixes-20261019/fails10.txt`）。
- `tool/nai_agent` 内置 Node 24.18.0：65／65。

## 构建与安装

- 固定 1989 项生产输入后构建 Windows Release。改动 18 个程序文件、新增 1 个：`data/app.so`、`nai_launcher.exe`、`app_files_manifest.json`，Agent 宿主 `host.mjs`、`lib/domain-tools.mjs`、`lib/session.mjs`、`lib/extensions/permissions.mjs`、两份 README，以及 nai-studio Skill 的 `SKILL.md` 和 8 份 reference（新增 `references/search.md`）。没有删除文件；三个插件 DLL 只差 PE 时间戳，保留已装原件。
- 打包冒烟按新工具数（20 个 Studio 业务工具）调整断言后通过；`list-skills`、RAG 宿主 ready／shutdown、12 项安装回退夹具通过。
- 覆盖前确认没有运行中的进程。安装后逐文件哈希、收据和单步回退备份核对通过；桌面入口、`user-data`、`agent-data` 和 3 个索引文件保持不变。

AOT SHA-256：`666e0741896e952202bfb737ccae663fb2d8342ad118ad65d8253459e6d030b4`。证据在 `.dart_tool/cumulative-r29-20261020/`，单步回退材料在其 `rollback/`。没有自动启动、生图、建库、打便携包或推送 GitHub。

首次打开后：内置提示词版本变为 `2026-10-20.2`（用户未自定义系统提示词时自动生效）；快捷信息首次读取时使用四条默认项。
