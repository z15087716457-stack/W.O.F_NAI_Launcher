# 2.0 Preview r18 · 画布帧时间优化本机更新

按用户“推送一下更新”，将日期标注、虚线与波纹精确路径复用安装到原桌面入口。原图、三个工具条效果和两侧 65% 不透明度保持。[实现及暂停向量任务后的三轮复测](canvas-native-frame-times-2026-10-16.md)。

内部 `2.0.0-preview+22`，优化实现 `4d01bb19e`，本次编译 `730cdd1b92a8a04a89638e3ddeacf09d4105ee73`，安装 `2026-10-16T23:59:46.377750+08:00`，AOT `08047f044086c165185f6d5085ecfb5f3cf4bf6f2783bf4c790343bfc06a8ca7`。

仅新增内部版本号，四个优化文件与已验证实现哈希一致，复用此前 1022 项检查、288 场景 RGBA 对照及全仓分析，未将旧结果写成此次重跑。此次 Windows Release 重新构建通过，1926 个生产输入、15355 个完整程序文件及 224 个资源逐项核验；原图、玻璃及原 PNG 保持。原生引擎帧时间与屏幕呈现 FPS 分开，栅格阶段仍有限制，不承诺全程 144fps。

此次执行 10 项安装／故障恢复／占用／私有路径保护检查；SQLite quick_check、19 份字体、原生身份／依赖、Node 24.18.0／Pi 1.1.0、Agent 合成服务及 RAG worker 启停通过。未调用真实模型或 NAI 接口。

现场确认 Studio 及随包宿主未运行；完整备份 r17 程序 data、被替换的程序文件及旧收据，安装前及每次替换重新检查进程与文件哈希。单步回退 `.dart_tool/cumulative-r18-20261016/rollback/` 已核验，未实际回退。

原桌面快捷方式、user-data、Agent 数据、独立迁移备份、WebView2 根及旧 C 盘兼容联接保持；RAG 环境和索引不在覆盖范围。未自动启动／重启／热重载 Studio，便携包仍 r8，未推送 GitHub。DEVELOPMENT.md 与 .runs/ 原改动保持。

证据：`.dart_tool/cumulative-r18-20261016/` 的 `reused-validation.json`、`build-result.json`、`build-verification.json`、`installer-fixtures.json`、`package-verification.json`、`install-result.json`、`final-verification.json`。正式收据与 `installed-delivery.json` 一致。

2026-10-17 用户反馈“不错，流畅了很多”，确认本轮优化的实机流畅度明显改善；该反馈为主观交互体验，未据此新增 FPS 测量结论。
