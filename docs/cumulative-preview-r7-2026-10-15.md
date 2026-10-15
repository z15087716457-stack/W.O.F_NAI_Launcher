# 2.0 Preview r7 · 六项反馈累计本机更新

2026-10-15（Asia/Taipei）。用户要求更新并确认已保存、从托盘退出；现场复查 Studio／内置 Agent 已退出后，安装到原桌面入口。**没有制作／更新便携包、推送 GitHub 或自动启动／重启／热重载 Studio。**

## 已安装

- 内部版本 `2.0.0-preview+11`，编译提交 `16e1977adcc87c19fa66f7ecc26c11cdacc54151`；后续文档提交不代表重新编译。
- 本次纳入 F01–F06：生成前后统一背景与中央 Logo／提示，RAG 模型应用内下载，环境检测／复用及安装诊断，共同向量池与 Wiki 翻译增量，大图定位格 2px 留白及各框独立悬停翻译。详细行为见 [功能报告](r6-feedback-2026-10-15.md)。
- 安装目录 `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release`，原桌面快捷方式和存储身份 `com.example/nai_launcher` 保持。
- AOT SHA-256：`378227c8b2042cb2ca50ed6e084e66a9966aae062134df77a0ae499e38d0990a`。
- 安装时间：`2026-10-15T17:40:20.959513+08:00`。已有 r6 便携包保持原样，r7 仅本机更新。

## 核验与回退

- 本轮重新构建 Windows Release（81.0s），核对 1872 份生产输入，包括原有生成文件；相对功能提交只改变版本及 CHANGELOG。原有 DEVELOPMENT 修改保留。
- 沿用功能完成时的 58 项 Python／宿主、443 项主要 Flutter 回归、106 项生图／大图后端回归、全仓无诊断分析、真实权重 CUDA 共享池及翻译增量验证；收尾检查有重叠，不声称本轮重跑全量。
- 本轮安装器 9 项隔离检查通过，覆盖完整回退、新增／既有文件中途失败恢复、运行占用、基线漂移、同名未登记文件、损坏备份及安装 hold。
- 完整候选 15355 项登记程序文件、224 项 Flutter 资源；实际替换／新增 10 项，其中新增 2 项。保留 Glass 原生插件和 15095 项 Agent 运行文件，不整目录覆盖原生包。
- 候选逐文件哈希、原生数据身份／EXE 依赖不变、SQLite quick_check、完整字体、内置 Node 24.18.0／Pi 1.1.0、隔离本地 Agent／CodeMode／会话恢复，以及打包后 RAG 宿主／worker 启停检查通过。没有调用真实生成或远程模型。
- 安装前备份 r6 被替换文件、完整登记程序 data 与旧收据；安装后核对全量程序、收据与备份。回退目录 `E:/A.I/NovelAI/.devin/wt/ui-integration/.dart_tool/cumulative-r7-20261015/rollback`，只读核验 `update.py verify-backup`，明确恢复用 `update.py rollback`；需完全退出 Studio，未实际回退。
- 未写用户草稿、账号、图库或 RAG 设置，未运行环境安装、下载模型或给用户完整资料库建向量。共享池迁移和译文增量将在用户启动并启用相应来源后按现行授权执行。

用户运行窗口的手感、网络大文件下载和真实完整资料库的性能仍需使用中验收；已知 160px 极窄画布提示溢出仍为原前端问题。

本轮材料 `.dart_tool/cumulative-r7-20261015/`：`build-inputs-start.json`、`windows-build.log`、`installer-fixtures.json`、`build-verification.json`、`package-verification.json`、`desktop-shortcut.json`、`preflight.json`、`installed-delivery.json`、`install-result.json`、`final-verification.json`。构建产物、测试环境、日志和私有材料不提交。
