# 本机 2.4.1+111 交付

已安装并完成文件、用户数据与回退核验，未自动启动 Studio，界面体验待用户实测。本次只更新桌面运行包，未提交或推送源码、修改 v2.4.1 标签或重跑 GitHub 流程；公开最新仍 v2.4.0。

- 内容：用户确认的轻量翻译长文本排版。短标签保持紧凑双行，长语义段原文与完整译文依次换行，移除省略及行尾补位；保留直接编辑、输入法、跨段选区、源文复制／剪切／撤销、待更新及整段删除行为。实现见[专项报告](semantic-inline-translation-2026-11-15.md)。
- 构建来源：有效工作树 E:/A.I/NovelAI/.devin/wt/ui-integration，HEAD c326a20bf990cbcb979bb5ea66dc6bb37d986eec 加本轮未提交改动；冻结 2,171 项生产输入及 19 项已有工作树改动，相对 +110 改变 11 项生产输入。输入哈希与已通过验证的代码一致。
- Flutter 3.47.7／Dart 3.13.5 Release 构建成功，构建记录 101.78 秒，包装命令连同后验约 110.27 秒；安装 38.655 秒。
- 15,557 项程序文件全部核验，仅替换 5 项：CHANGELOG.md、package-info.json、data/app.so、nai_launcher.exe、app_files_manifest.json。无新增或退役文件；原生库、资源、Agent 与 RAG 未变。
- 14 项关键用户文件状态、图库数据库、3 个当前索引文件、历史数据入口及原快捷方式保持。用户数据不进入载荷。
- 复用同源码 561 项相关回归、133 项隔离生图接线、补充块编辑／生成投影／撤销 1 项、全仓分析 0 问题及 12 张真实字体原生实绘；本批另跑 3 项打包测试及 4 项隔离安装／失败恢复检查。未请求真实翻译模型或 NAI，未重建索引。
- AOT SHA-256：ca60aa93b8a883f53cd04fcfe73be42f2ec6c3201f080eb4b969d3eec642becb。

证据位于 .dart_tool/local-2.4.1-build111-20261115/：final-verification.json、user-data-preservation.json、package-verification.json、冻结源码与构建记录。安装后的文档修订单独记录，编译输入与代码保持。

单步回退已只读核验：完全退出 Studio 和托盘后，本批 update.py rollback 会实际恢复安装前的 2.4.1+110；只验备份使用 update.py verify-backup。保留历史回退、当前缓存、SDK 及本批暂存，不执行此前暂停的清理。
