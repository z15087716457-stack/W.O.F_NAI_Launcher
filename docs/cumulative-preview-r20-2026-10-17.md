# 2.0 Preview r20 · RAG 启动恢复修复本机更新

按用户“原来如此那就问题不大，推送一下吧”，将启动恢复、检查点失效判断与未知状态显示修复安装到原桌面入口。[实现与边界](rag-startup-timeout-fix-2026-10-17.md)。

恢复显示真实阶段和数量，configure 使用 15 分钟总时限及 2 分钟无进展保护，取消／设置变更／退出可结束初始化。未知状态不再显示未建库／0% 或提供重建入口，重连保留已有计数，启动失败重试只重新连接。处理标记更新不再使 ANN 检查点失效，完整恢复后保存。首次更新后仍可能需要完整恢复一次旧检查点，没有替用户预先恢复或清库。

内部 `2.0.0-preview+24`，修复实现 `ad09983326247106f2defc6fc00071c3aa23da82`，本次编译 `6e04196bbdbe1d1258767db89d4cb1a9cc9276eb`，安装 `2026-10-17T08:43:42.289674+08:00`，AOT `d891da2f0daf36a33033594c4ea09196b40e2101a8b0b8d36e6eca19b86bd815`。

所有生产输入与已验证修复逐字节一致，仅增加内部版本号；复用此前 390 项 Flutter、66 项 Python 共 456 项不同检查、20 种多语言明暗宽窄实绘、原 PNG 及全仓／范围分析，未将旧结果写成此次重跑。本次重新构建 Windows Release，1929 个生产输入、15355 个程序文件及 224 个资源完整核验。

本次 10 项安装／故障恢复／占用与私有路径保护检查通过；SQLite quick_check、19 份字体、原生身份／依赖、Node 24.18.0／Pi 1.1.0、Agent 合成服务及 RAG 宿主／工作进程启停通过。七份打包 RAG 模块与源码一致，未请求真实模型或 NAI。

现场确认 Studio 与随包宿主完全退出后，完整备份 r19 程序 data、被替换文件及旧收据；每次替换前重新检查占用和哈希。安装后程序、收据、源码、回退材料、桌面快捷方式、私有数据根目录及兼容联接核验通过。user-data、Agent 数据、RAG 环境／现有索引和迁移备份保留；原图、三个工具条、侧栏 65% 及画布性能保持。未自动启动／热重载／重启，便携 ZIP 仍 r8，未推送 GitHub。

原生 coremessaging.dll APPCRASH 尚缺调用栈，未宣称修复；图库“继续”完整性能专项仍暂缓。本次仅修改启动恢复必需的检查点失效判断，不代表已完成整项性能优化。真实规模恢复耗时及实机效果待用户反馈。

证据：`.dart_tool/cumulative-r20-20261017/` 的 `build-inputs-start.json`、`reused-validation.json`、`build-result.json`、`build-verification.json`、`installer-fixtures.json`、`package-verification.json`、`protected-feature-verification.json`、`preflight.json`、`install-result.json` 及 `final-verification.json`。当前单步回退为同目录 `rollback/`，已核验 r19 完整程序 data、被替换文件及旧收据，未实际回退。
