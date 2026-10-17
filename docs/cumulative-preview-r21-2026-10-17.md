# 2.0 Preview r21 · 共享池保存、退出与统计优化本机更新

按用户“ok，推送一下”，将已验证的检查点、退出流程和重复统计优化安装到原桌面入口。[实现与边界](rag-lifecycle-performance-fix-2026-10-17.md)。内部 `2.0.0-preview+25`，功能提交 `d9536acede0c35fdbc35490bfab9a5443db16d9a`，本次编译 `039340ebd6a05fbb6cad67985940e045ba58e3cd`，安装 `2026-10-17T09:21:56.890186+08:00`，AOT `7b3734a8359e33006653f0f84d18b78bf430ce685ca08f5b32f3a89d950b93a2`。

共享池无向量变化不重写 ANN，有变化统一保存一次；退出保留完整收尾及输出排空，新宿主等待旧宿主完成。容量改为同事务摘要，旧库每分区首次补算一次，启动复用已返回状态。现有索引格式、向量、检索算法及来源范围不变。异常退出仍可能需要恢复有效检索结构，首次摘要读取及完整大库耗时没有实机重新采样，不承诺瞬间启动。

逐字节确认生产输入与功能验证一致，仅增加内部版本号，复用 97 项 Flutter 与 75 项 Python，共 172 项不同检查及范围分析；没有写成此次重跑。本次 Windows Release、1930 个生产输入、15355 个程序文件、224 个资源、原生身份／依赖与 10 项安装／失败恢复／占用保护检查通过。SQLite quick_check、字体、随包 Node／Pi／Agent 合成服务及 RAG 原生宿主／JSON 工作进程启停通过，七份随包 RAG 模块与源码一致，未请求真实模型或 NAI。

现场两次确认退出后备份 r20 完整程序 data、被替换文件及旧收据，每次替换前重查占用与哈希。安装后完整程序、源码输入、收据、回退材料、桌面快捷方式、兼容联接与私有目录核验通过；另核对 28 个索引文件的大小、时间及文件身份未变化。未载入、重建、清除或改写用户索引。

原图、三个工具条、侧栏 65% 与画布优化保持，用户数据、RAG 环境、Agent 数据和迁移备份保留。未自动启动、热重载或重启；便携包仍 r8，未推送 GitHub。原生 coremessaging.dll APPCRASH 未宣称修复；图库“继续”的来源签名／旧数据核对等其余专项仍暂缓。

证据 `.dart_tool/cumulative-r21-20261017/`：`build-inputs-start.json`、`reused-validation.json`、`build-result.json`、`build-verification.json`、`package-verification.json`、`installer-fixtures.json`、`protected-feature-verification.json`、`protected-index-preinstall.json`、`install-result.json`、`final-verification.json`。当前回退为同目录 `rollback/`，已核验 r20 完整程序 data、替换文件及收据，未实际回退。
