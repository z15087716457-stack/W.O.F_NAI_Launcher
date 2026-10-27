# W.O.F NAI Studio 2.2.0 · 正式发布

显示版本 `2.2.0`，构建版本 `2.2.0+56`。GitHub 发布时间：`2026-10-27T15:53:41Z`。

- [GitHub Release v2.2.0](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/tag/v2.2.0)
- [正式发布构建](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/actions/runs/40531319481)
- [完整功能、修复与升级说明](../CHANGELOG.md#220---2026-10-27)

## 本版范围

从上一正式版 v2.1.0 汇总新增功能和修复，包含此前未单独发布的 2.1.1／2.1.2 开发批次。更新说明约 5800 字，先介绍资源小窗、中文提示词补全与字号、临时积木、Agent 指令／建议／缓存保温、翻译调整、图库搜索与存储管理、生图与界面细节，再分类列出稳定性与数据保护修复。

中英文 README 同步增加 2.2 功能摘要。发布脚本提取完整版本段落；已经核对线上正文、附带 release_notes 与源码 CHANGELOG 的全部版本内容一致。

## 发布来源

- 编译提交与注解标签 v2.2.0 均指向 `f19227d70be02e7d76574efdb265edecaa5f1d9a`，正式 main 已正常快进至该版本。
- 沿用 release.yml：核对 tag/pubspec → GitHub Windows 编译 → 安装包和便携包 → 更新元数据 → 正式发布；三个作业均成功。
- Release 不是 draft／prerelease，GitHub latest 已返回 v2.2.0。
- Git 上传遇到大包 HTTP 408，使用小批量对象传输后正常快进 main；32 个本次创建的临时传输分支已全部删除，没有强制改写 main 或既有发布标签。

## 正式文件

| 产物 | 字节数 | SHA-256 |
|---|---:|---|
| `WOF_NAI_Studio_Windows_2.2.0_Portable.zip` | 322937159 | `ac94c80df00816b0dec6b46d68fb82bc1a1c36c35088d6bb3ee5b29702d9b39a` |
| `WOF_NAI_Studio_Windows_2.2.0_Setup.exe` | 200295727 | `d7ffbef4782587155f72ea8ac93d2ca670ef6379c175174354328aa153360329` |

另附 checksums.txt、release_manifest.json、release_notes_v2.2.0.md 和各产物的 .sha256；正式下载副本保存在工作区 `04_工具/发布包/2.2.0/`。

## 验证与证据

证据位于源码 `.dart_tool/release-2.2.0/`，不随程序分发。

| 检查 | 结果 |
|---|---|
| 功能回归来源 | 复用 +55 提交 d652673ac 的完整 Flutter **9708 通过／0 失败／5 项既有真机或联网审计跳过**及全仓 analyze；逐项确认发布提交的 lib、assets、tool、windows、scripts、CI 和 pubspec.lock 均未改变，仅修改版本与发布文档 |
| 本次版本／更新检查 | **32 通过**，覆盖当前版本显示、更新识别、资产与安装器相关模型及更新生命周期 |
| Node Agent | 按 package.json 串行命令全套 **110 通过／0 失败**；首轮遗漏串行参数产生的两项计时失败原日志保留，未修改断言或功能代码 |
| 本机发布前构建 | 2.2.0+56 Windows Release 通过，原生数据身份正确；功能 AOT 与已安装 +55 一致，未启动 GUI |
| 发布前源码 | 工作树干净，Git LFS fsck 通过；575 个变动文本文件扫描未发现凭据格式命中 |
| 正式产物 | 文件大小、GitHub digest、checksums.txt、单独 .sha256 和更新清单一致 |
| 便携 ZIP | CRC、唯一条目、路径、清单和 **15307 个文件**全部核验，逐项内部 SHA-256 匹配；无用户数据目录 |
| 版本与来源 | package-info 的 2.2.0／2.2.0+56、编译提交、stable 渠道、AOT 和应用旁数据目录一致 |
| 资源小窗 | 正式包包含 desktop_multi_window_plugin.dll |
| 数据库 | 四个随包 SQLite 只读 quick_check 均为 ok |
| Agent | Node v24.18.0、Pi 1.3.0、两项内置 Skill；全部随包源码与发布源码核对，CodeMode／MCP／会话恢复合成冒烟通过 |
| RAG | 正式原生宿主与 JSON worker 在隔离开发环境 ready/shutdown 通过，未加载模型、未建立用户索引 |
| 安装包 | 仅解包、不执行安装；全部载荷逐文件与便携包一致，原生版本为 2.2.0+56，签名状态 `NotSigned` |
| 发布说明 | 线上正文与 MD 附件一致，完整包含七类功能更新、分类修复与升级说明 |

CI AOT SHA-256：`002ab776b7c711a2af16d980c6ee562ba84c2a3339230a23d0255f48d3705e76`。CI 与本机构建环境不同，不要求两者二进制哈希相同。

## 本机与使用边界

本次发布流程没有再次安装 CI 包，也没有启动、热重载或操控用户正在使用的 Studio；本机已安装 +55 已包含这次功能，正式版仅增加新版本号和发布文档。本机实际安装状态单独在工作区接手说明登记，不把 GitHub 发布状态写成本机安装状态。

未调用真实模型或 NovelAI 生图，未操作账号、草稿、正式数据库或用户索引。安装器的交互式升级／卸载流程未在本次重复执行；其源代码与既有正式版保持一致，原验证见 [2.0.0 发布记录](release-2.0.0-2026-10-22.md)。
