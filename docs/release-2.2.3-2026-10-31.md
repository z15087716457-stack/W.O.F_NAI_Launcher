# W.O.F NAI Studio 2.2.3 · 正式发布

显示版本 `2.2.3`，构建版本 `2.2.3+71`。GitHub 发布时间：`2026-10-31T07:28:29Z`。

- [GitHub Release v2.2.3](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/tag/v2.2.3)
- [发布构建](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/actions/runs/41179092647)
- [完整功能、修复与升级说明](../CHANGELOG.md#223---2026-10-31)

## 本版范围

汇总公开 2.2.2 之后、本机 +65 至 +70 的全部更新：图库首次 Ctrl 多选修复、最近浏览与共用画廊删除池、资源小窗功能与切换性能、存储统计缓存及服务商输入排版；Agent 对话活动排序、完整历史与按需原文回查、查询动画及独立压缩节点；标签 RAG 状态／查询排序、共现工具与平滑词频降权、批量资料读取及稳定 checkpoint 签名；工作区 `.W.O.F/` 收纳、根目录 `AGENTS.md` 加载和内置 Skill／工具说明精简。

中英文 README 同步，线上正文、release_notes 附件与 CHANGELOG 完整版本段落一致。旧工作区先备份校验后迁移，根目录仍为 Agent 工作目录；旧索引签名首次升级可对齐核对一次，未变资料复用原向量。

## 来源与验证

- 发布编译与注解标签 v2.2.3 固定于 `3cf2700e6e4cacb78bbec9703a0fcca240f5c282`。main 与新标签正常快进推送，既有标签未移动；核验文档作为后续普通提交。
- GitHub Release 三个 CI 作业全部成功，正式稳定版已成为 latest。
- 与已安装 +70 的 2109 个生产输入逐项核对，除 pubspec 版本外一致；复用匹配的功能／静态验证和 Python 136 项（133 通过／3 跳过）证据，不称为本次新跑全仓测试。
- 本次新跑版本／更新检查 **59 通过**、Node Agent 串行完整回归 **122 通过**；Windows Release 2.2.3+71、本机原生数据身份、LFS fsck 与完整发布说明／更新清单生成夹具通过。

## 正式文件

| 产物 | 字节数 | SHA-256 |
|---|---:|---|
| `WOF_NAI_Studio_Windows_2.2.3_Portable.zip` | 323026738 | `0ffe2f4c3e0a693fe4b50a8685b3492cae9ab09228714f970a2521c09ef48053` |
| `WOF_NAI_Studio_Windows_2.2.3_Setup.exe` | 200469128 | `2c0da51c47de91a93a61b55d7d2ca1c052562d98a8e0f640ed90388acc135fb2` |

另附 checksums.txt、release_manifest.json、release_notes_v2.2.3.md 与各产物的 .sha256；核验副本在工作区 `04_工具/发布包/2.2.3/`。

| 产物检查 | 结果 |
|---|---|
| 大小与校验 | GitHub digest、单独 SHA-256、checksums.txt、更新清单全部一致 |
| Portable | CRC、唯一路径与全部 15309 个文件逐项核验，无用户数据目录 |
| 版本与来源 | package-info、稳定渠道、2.2.3／2.2.3+71、编译提交及 AOT 一致 |
| 资源 | 字体与四个 SQLite 资源只读 quick_check 通过，资源小窗原生插件存在 |
| Agent | Node 24.18.0／Pi 1.3.0、内置 Skill、随包源码、默认入口与按需工具、CodeMode／MCP／会话恢复合成冒烟通过 |
| RAG | 隔离原生宿主／worker ready/shutdown；官方包内引擎 7 项 checkpoint 回归通过，不加载真实模型或用户索引 |
| Setup | 仅解包核验，全部载荷与 Portable 一致；原生版本 2.2.3+71，签名状态 NotSigned |
| 更新说明 | 线上正文、MD 附件与 CHANGELOG 完整段落一致 |

CI AOT SHA-256：`8e3d4ea409ba02efd8e8ac51cd0c94785906e3e7ce15bfb261067c487f1c9761`。CI 与本机构建环境不同，不要求二进制哈希相同。证据在有效源码 `.dart_tool/release-2.2.3/`。

## 本机状态

本次未重新安装或启动 Studio。桌面仍为 **2.2.2+70**（编译 `058b46fee9b3b2ccf4c576ef0da07fc73152a69a`），包含本版全部功能；安装收据、EXE 与 AOT 保持。公开构建 +71 仅提升版本，无功能待安装增量。

未请求真实模型／NovelAI，未改写草稿、账号或正式索引。Setup 解包检查不替代真实老用户交互式升级体验。
