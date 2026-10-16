# 2.0 Preview r17 · 生图页性能本机更新

按用户“推送一下更新”，将已授权完成的五项优化安装到原桌面入口：批次边界索引、收藏查询失效范围、输入订阅与 Token 去重、流式几何复用、历史／参考预览按 DPR 解码。两侧 65%、三个悬浮条的明暗／玻璃效果及原图功能保持。[实现与计数](generation-performance-fixes-2026-10-16.md)。

内部 `2.0.0-preview+21`，性能实现 `be56f6520`，本次编译 `057e832aeedec1b06e11c243c1153aee712bb1cc`，安装 `2026-10-16T22:26:05.613359+08:00`，AOT `a1e7f5d0561d8c8d8508ad36d0622fc74aa264023bdd82fec185f6f33b56332d`。

本次从版本锁定后的源码重新运行 974 项回归，0 项跳过，覆盖生图／探索／编辑器、画布与六项接线核心、桥接、Agent 宿主和性能边界。原 PNG／排除区域保持，三个工具条明暗／动态取样与高对比度通过。全仓分析无诊断，Windows Release 构建通过。未测原生 GPU 帧率，实际交互和长会话内存仍待用户实机验收。

1926 项生产输入、15355 个完整程序文件和 224 个资源逐项核验；SQLite quick_check、19 份字体、原生数据身份／依赖、Node 24.18.0／Pi 1.1.0、Agent 合成服务和 RAG worker 启停通过。10 项安装／故障恢复／占用／私有路径保护检查通过。没有真实模型或 NAI 请求。

现场检查 Studio／随包宿主已完全退出，备份被替换的 r16 程序、完整程序 data 与旧收据后安装；安装前及每次替换均重新检查进程和旧文件哈希。回退 `.dart_tool/cumulative-r17-20261016/rollback/` 已核验，未实际回退。

原桌面快捷方式、user-data、Agent 数据、独立迁移备份、WebView2 数据根和旧 C 盘兼容联接保持；RAG 环境和已有索引不在覆盖范围。未自动启动／重启／热重载 Studio，未重打便携 ZIP 或推送 GitHub，便携包仍 r8。原有 DEVELOPMENT.md 和 .runs/ 保留。

证据：本次 `.dart_tool/cumulative-r17-20261016/` 内 `regression-result.json`、`analyze.log`、`build-verification.json`、`floating-toolbar-verification.json`、`installer-fixtures.json`、`package-verification.json`、`install-result.json` 和 `final-verification.json`；正式收据与 `installed-delivery.json` 完全一致。
