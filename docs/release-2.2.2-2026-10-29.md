# W.O.F NAI Studio 2.2.2 · 正式发布

显示版本 `2.2.2`，构建版本 `2.2.2+64`。GitHub 发布时间：`2026-10-29T14:16:59Z`。

- [GitHub Release v2.2.2](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/tag/v2.2.2)
- [发布构建](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/actions/runs/40886361802)
- [完整功能、修复与升级说明](../CHANGELOG.md#222---2026-10-29)

## 本版范围

汇总 v2.2.1 后本机 +62、+63 的六项更新：Windows 应用内更新进程启动／工作目录与中文路径修复；移除顶部更新胶囊；外部桥接成图保留角色元数据；外部 Agent 跟随共享 Krita 桥接开关灰显与提示；保存提示条留白对齐；Agent 流式性能与平滑思考。Agent 原有静态 UI 保持。

中英文 README 同步，线上正文、release_notes 附件与 CHANGELOG 完整版本段落一致。旧客户端仍受重启更新缺陷影响时需手动升级，已丢失角色字段的旧图不会自动恢复，详见升级说明。

## 来源与验证

- 发布编译与注解标签 v2.2.2 固定于 `0d9af178cc6171c2a15157ef6806599acec411ef`。main 与新标签正常推送，既有标签未移动；核验文档作为后续普通提交推送。
- GitHub Release 三个 CI 作业全部成功，正式稳定版已成为 latest。
- 与已安装 +63 的 2101 个生产输入逐项核对，只有 pubspec 版本变化，功能代码、资源、工具及构建脚本一致；本机发布前 AOT 与已安装 +63 相同。
- 按源码匹配复用 +63 的 1389 项相关回归、业务目录静态分析与原生性能／静态逐像素证据；不称为本次新跑全仓全量。
- 本次新跑版本／更新检查 **59 通过**、Node Agent 串行完整回归 **112 通过**；本机 Windows Release 2.2.2+64 构建和原生数据身份通过。
- LFS fsck、60 个变更文本文件凭据格式扫描、完整说明与更新清单生成夹具通过。夹具首次使用本机旧 PowerShell 时 Get-FileHash 不可用，改用与 CI 一致的 pwsh 7 后通过；原日志保留，生产脚本未改。

## 正式文件

| 产物 | 字节数 | SHA-256 |
|---|---:|---|
| `WOF_NAI_Studio_Windows_2.2.2_Portable.zip` | 322977951 | `db625fb5bc58bebec6f24a438db9e357b7312ed713bf93638316c8087d7425b3` |
| `WOF_NAI_Studio_Windows_2.2.2_Setup.exe` | 200255970 | `e4ee80733fdc9b34d23048ac33a5408dd6b2df7b8504aa8c0bf60c2838fe9a8b` |

另附 checksums.txt、release_manifest.json、release_notes_v2.2.2.md 与各产物的 .sha256；下载核验副本在工作区 `04_工具/发布包/2.2.2/`。

| 产物检查 | 结果 |
|---|---|
| 大小与校验 | GitHub digest、单独 SHA-256、checksums.txt、更新清单全部一致 |
| Portable | CRC、唯一条目、路径检查通过；15307 个文件逐项核验，无用户数据目录 |
| 版本与来源 | package-info、稳定渠道、2.2.2／2.2.2+64、编译提交及 AOT 一致 |
| 资源 | 字体与四个 SQLite 资源只读 quick_check 通过，资源小窗原生插件存在 |
| Agent | Node 24.18.0／Pi 1.3.0、内置 Skill、随包源码、CodeMode／MCP／会话恢复合成冒烟通过 |
| RAG | 正式原生宿主与 JSON worker 在隔离环境 ready/shutdown 通过，不加载模型或用户索引 |
| Setup | 仅解包核验，全部载荷与 Portable 逐文件一致；原生版本 2.2.2+64，签名状态 NotSigned |
| 更新说明 | 线上正文、MD 附件与 CHANGELOG 完整版本段落一致 |

CI AOT SHA-256：`f54ceaacf9c4dbcb41b8c5d246b759460e2b4065c9c7e0676bd610319353f409`。CI 与本机构建环境不同，不要求二进制哈希相同。证据在有效源码 `.dart_tool/release-2.2.2/`。

## 本机边界

本次未重新安装或启动 Studio。桌面仍为 **2.2.1+63**（编译 `4bb17a1a2b89e361623e162e03f5c5e61843ecd5`），包含本版全部功能修复；正式安装收据 SHA-256 与发布前一致。公开版本与本机安装分别记录，没有未安装的功能增量。

未调用真实模型／NovelAI，未改写草稿、账号或正式索引。Setup 的交互式升级／卸载本次未重复执行，产物解包检查不替代真实老用户升级体验。
