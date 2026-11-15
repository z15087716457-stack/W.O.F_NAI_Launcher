# 本机 2.4.1+112 交付

已安装并完成程序、用户数据及回退核验，未自动启动 Studio，界面体验由用户继续实测。本次只更新桌面运行包，未提交／推送源码、修改 v2.4.1 标签或重跑 GitHub；公开最新仍 v2.4.0。

- 内容：修复长语义段后接短语时漏换行的问题，避免短语译文覆盖前段的整行译文。后续短语从完整前段译文之后开始，相邻短标签仍可紧凑共行；不改模型、术语表、提示词、原文或编辑链。见[实现与复现](semantic-inline-translation-2026-11-15.md)。
- 构建来源：有效工作树 E:/A.I/NovelAI/.devin/wt/ui-integration，HEAD c326a20bf990cbcb979bb5ea66dc6bb37d986eec 加未提交改动；冻结2,171项生产输入及21项已有工作树改动，相对+111改变3项生产输入。
- Flutter3.47.7／Dart3.13.5 Release 构建成功，构建记录91.65秒，安装40.168秒。
- 15,557项程序文件全部核验，仅替换5项：CHANGELOG.md、package-info.json、data/app.so、nai_launcher.exe、app_files_manifest.json。无新增或退役，原生库、资源、Agent、RAG未变。
- 14项关键用户文件状态、图库数据库、3个当前索引文件、历史数据入口及原快捷方式保持。用户数据不进入载荷。
- 复用同源码585项相关回归、补充交界原生复制／编辑1项、全仓分析0问题及24组真实字体原生布局实绘；本批另跑3项打包及4项隔离安装／失败恢复检查。不重复运行未变的Node／RAG套件，未请求真实模型或NAI、未重建索引。
- AOT SHA-256：74b4fce2b5fbd37bb8d1d5105e9f30ccb0559c227696c843a6f839367118326a。

证据位于.dart_tool/local-2.4.1-build112-20261115/：final-verification.json、user-data-preservation.json、package-verification.json、冻结源码及构建记录。安装后的文档修订单独记录，编译输入与代码保持。

+111单步回退备份已只读核验。完全退出Studio和托盘后，本批update.py rollback会实际恢复2.4.1+111；仅验备份使用update.py verify-backup。保留历史回退、缓存、SDK及暂存，不执行此前暂停的清理。
