# 2.0 Preview r33 · 待修复清单一轮累计更新

用户 2026-10-21 说“新增一些修复内容，一起修了然后直接推送更新，我暂时不在”，按 2026-10-15 的本地交付约定安装到原桌面入口，没有推送 GitHub。内部版本 `2.0.0-preview+37`，编译提交 `a04d77867f78ce50d99860ad3fb342d86f7630ae`；之后的文档提交不代表重新编译。

## 内容（r32 之后）

| 提交 | 内容 |
|---|---|
| `7bf6f7c6c` | 服务商：显示出来的 API Key 编辑不再弹回旧值 |
| `e69921913` | Agent 设置二级弹窗重做；Agent 回收区管理（恢复不覆盖、清除需确认，Skill 回收合并） |
| `731c57562` | Agent 设置分 常规／指令／Skill／工具与扩展 标签（记住标签，搜索和“去设置”先切标签）；CodeMode 嵌套结果的标签／Wiki 小标签与设置／画廊卡片实时显示并持久化（`interaction.mjs` 写投影）；服务商去掉图片输入开关与温度／Top P（不再发送）；推理档位英文；本地画廊搜索框鸿蒙字体 |
| `9477a62d1` | 没有模型配置的旧提示词助手调用照常带图 |
| `be41a6f33` | Wiki 译文缓存：路由指纹只算 Wiki 路由、预设和语言（以前含全部模型，任何模型改动都失效）；同一正文跨路由复用；已开始的翻译关面板后做完；`force` 只在同类任务间合并 |
| `cf2e45a31` | Wiki 示例图全窗口看图器（左右切换、说明、缩略图条、来源） |
| `d54a26d47` | 全屏提示词编辑器重做（标题、正负分段、顶部清空／关闭、底部 token 与计数、填满高度） |
| `f04a053ed` | 在线画廊：卡片大小三枚瀑布流图标；未知尺寸按缩略图真实比例排版；极端比例完整显示 |
| `dccf73c9a` | 块库：默认瀑布流（`blocks_view_v2`，旧网格迁瀑布流、列表保留）；按文件夹分组（`SliverMainAxisGroup` + `PinnedHeaderSliver` 吸顶，组内排序，根目录在前）；搜索框加长 |
| `9f379dfb8` | 比例学习的 setState 移出构建期；窄工具栏把分组开关收进排序菜单 |
| `50a31b514` | 积木悬浮窗（新生成页入口）去掉屏障：改用根 Overlay 浮层，框外点击／拖块照常到达页面，只由 X 或再点按钮关闭，离开生成页收起；服务商去掉“结构化输出”能力（配置字段保留、不显示）；请求体／请求头每行加类型小标，“字段”改名“请求体”，输入框文字垂直居中 |

## 验证

- 登记 SDK 3.47.7：`flutter analyze --no-pub lib test` 无问题。
- 回归范围在 r32 基础上加 `test/core/wiki`、`test/presentation/widgets/common`、`test/presentation/widgets/prompt`：**4948 通过／31 失败**，失败集合与 `merged-fails.txt` 逐项相同（`r19.jsonl`）。
- `tool/nai_agent` 内置 Node 24.18.0：83／83。
- 截图核对：Agent 设置四个标签、看图器、全屏编辑器、在线画廊、块库瀑布流与分组、服务商请求体／请求头。

## 构建与安装

- 固定 1999 项生产输入后构建 Windows Release。改了 4 个程序文件：`tools/nai-agent/lib/extensions/interaction.mjs`、`data/app.so`、`nai_launcher.exe`、`app_files_manifest.json`；没有新增或删除文件，原生依赖不变。
- 安装时 Studio 未运行。安装前通过：打包 Agent 合成冒烟、RAG 宿主 ready／shutdown、12 项安装回退夹具。安装后逐文件哈希、收据和单步回退备份核对通过；桌面入口、`user-data`、`agent-data` 和 3 个索引文件保持不变。

AOT SHA-256：`5654a8e637542408516bbca4913d97f3dfb8d1980a65fa77d6aa9b557004db8c`。证据在 `.dart_tool/cumulative-r33-20261021/`，单步回退材料在其 `rollback/`。没有自动启动、生图、建库、打便携包或推送 GitHub。积木浮框、Wiki 译文复用和 CodeMode 卡片持久化只在测试中验证过，需要用户在真实运行中确认。
