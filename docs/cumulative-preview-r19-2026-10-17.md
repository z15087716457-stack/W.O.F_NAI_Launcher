# 2.0 Preview r19 · 语义索引准备提示本机更新

按用户“ok，推送一下”，将已确认的索引准备提示及等待状态安装到原桌面入口。每次启动首次手动建立／继续／重建索引显示一次提示；等待预览／开始／继续回应时，保留已有数量并显示“正在准备索引”，阻止重复提交。关闭通知不启动任务，原计划确认保留。

弹窗使用设置页已有字体、明暗颜色、线性图标及按钮，正文与耗时说明分区，窄窗口和放大字号可用。通知仅保存于当前会话；关闭再进入设置不重复，重启后重新提示。[实现与边界](rag-startup-notice-2026-10-17.md)、[视觉核验](rag-startup-notice-design-qa-2026-10-17.md)。

内部 `2.0.0-preview+23`，功能实现 `9805ff1bd`，视觉调整 `3715966db`，本次编译 `0fba8291c115352c72bb00b264ffa4ac4ddb0df5`，安装 `2026-10-17T07:56:56.323805+08:00`，AOT `5b8403265c862b905005ff27a4077be4166f90722d0d52cfc7fea393e52cf767`。

交付前确认生产输入与已审核代码相同，仅增加内部版本号；复用最新 292 项相关检查、40 种五语言明暗／宽窄／字号实绘及范围静态分析，初版 411 项检查与全仓分析另存。两组检查存在重叠，不累计，也未声称此次重跑。Windows Release 本次重新构建通过，1928 个生产输入、15355 个完整程序文件和 224 个资源逐项核验。

本次重新执行 10 项安装／故障恢复／占用／私有路径保护检查；SQLite quick_check、19 份字体、原生身份／依赖、Node 24.18.0／Pi 1.1.0、Agent 合成服务及 RAG worker 启停通过。未调用真实模型或 NAI 接口。画布优化、中央原图、三个工具条及两侧 65% 保持；建库后端未改，图库“继续”耗时优化仍按用户要求暂缓。

安装前现场确认 Studio 与随包宿主未运行；完整备份 r18 程序 data、被替换的程序文件及旧收据，每次替换前重新检查占用和哈希。安装后完整程序、收据、源码、回退、桌面快捷方式与受保护数据根目录核验通过。user-data、Agent 数据、迁移备份及 C 盘兼容联接保持，RAG 环境和用户索引不在程序替换范围。未自动启动／重启／热重载，便携 ZIP 仍 r8，未推送 GitHub。

证据目录：`.dart_tool/cumulative-r19-20261017/`，包括 `build-inputs-start.json`、`reused-validation.json`、`build-result.json`、`build-verification.json`、`installer-fixtures.json`、`package-verification.json`、`protected-feature-verification.json`、`preflight.json`、`install-result.json` 与 `final-verification.json`。当前单步回退为同目录 `rollback/`，包含 r18 原程序 data、被替换文件及旧收据；已校验，未实际回退。用户实机体验另行记录。
