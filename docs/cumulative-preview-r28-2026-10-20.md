# 2.0 Preview r28 · NAI Agent 侧栏修正与角色位置卡累计更新

用户 2026-10-20 说“推送一下更新”，按 2026-10-15 的本地交付约定安装到原桌面入口，没有推送 GitHub。内部版本 `2.0.0-preview+32`，编译提交 `5725263a73311049cfe678bc63e6b72d6e74cc28`；之后的文档提交不代表重新编译。

## 内容（r27 之后）

| 提交 | 内容 |
|---|---|
| `95e6a38b1` | 图片输入被挡时说明原因：是服务商的“图片输入”开关，还是模型能力，并给出服务商名和设置位置。被挡的附件不再静默丢弃，正文照常发送，侧栏提示扣下了几张。思考块文案 |
| `b3f54d4bb` | 打开 Agent 侧栏后顶部仍可拖动窗口（拖动与标题栏预留拆开）；设置导航 Agent 图标换成 `AgentMark`；对话改为自上而下，在底部时跟随、离开时显示回到底部箭头；思考内容折叠显示；工具耗时不到 1 秒时显示毫秒 |
| `17de317fd` | 待修复清单：MCP 状态不再进提示卡（设置页不再自触发、宿主读状态时不转发、去重）；内置 Skill 置顶，可开关和改调用方式；权限三档收成一个按钮；改动卡状态靠右；`@` 积木分类加搜索框，按最近使用排序（Agent 插入也记一次）；`@` 按钮再点一次撤掉空的 `@`；附件悬停改为轻量信息卡；“记忆”改名“指令”；Windows 小键盘 NumLock 关闭时可编辑（7／1 = 行首／行尾）；删掉快捷任务行 |
| `28cf81996`、`ca78cf11c` | 模型调整角色位置时显示位置卡：按画面比例的迷你 5×5 定位板，圆点颜色与生成页一致，标出原位置、箭头和定位方式切换；只提示，不能撤销 |
| `a988faae0` | “思考协议”只在 Anthropic Messages 下显示；golden 保留原图，只在选项隐藏时遮住空出来的那一格。宿主测试确认选“最高”时 DeepSeek 请求体发的是 `reasoning_effort: "max"`（之前说“最高 = 高”是误判） |

## 验证

- 登记 SDK 3.47.7：`flutter analyze --no-pub lib test` 无问题。
- `test/presentation/ui`、`wiring`、`widgets/navigation`、小键盘、`l10n`、`core/nai_agent`、`providers/nai_agent`、`prompt_assistant`、`screens/settings`、`app_test`：**3667 通过／31 失败**，失败集合与 `merged-fails.txt` 逐项相同。证据在 `.dart_tool/agent-fixes-20261019/fails6.txt`。
- `tool/nai_agent` 内置 Node 24.18.0：51／51。

## 构建与安装

- 固定 1981 项生产输入后构建 Windows Release。共改动 5 个程序文件：`data/app.so`、`nai_launcher.exe`、`app_files_manifest.json`，以及 Agent 宿主的 `tools/nai-agent/host.mjs` 和 `lib/skills.mjs`。没有新增或删除文件，原生依赖不变。
- 安装前通过：打包 Agent 合成冒烟、`list-skills`、RAG 宿主 ready／shutdown、12 项安装回退夹具。
- 覆盖前确认没有运行中的进程。安装后核对逐文件哈希、收据和单步回退备份，均通过；没有实际执行回退。桌面入口、`user-data`、`agent-data` 和 3 个索引文件的元数据保持不变。

AOT SHA-256：`b0dee33ad8f88adcef3f2753cbb35d492eae862a0d7ff4c076a9d4f1b0f8f8e0`。证据在 `.dart_tool/cumulative-r28-20261020/`，单步回退材料在其 `rollback/`。没有自动启动、生图、建库、打便携包或推送 GitHub。小键盘只做了模拟测试，没有在实体键盘上验证。
