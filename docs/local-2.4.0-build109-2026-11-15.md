# 本机2.4.0+109交付

2026-11-15，按用户要求将权重底色和手动换行修复更新到现有桌面目录，交由用户实测。**本机最终版本2.4.0+109；公开GitHub版仍为v2.4.0（+108），本次没有提交或发布Git。** 原快捷方式保持，没有启动、重启或操作Studio。

- 本轮修复：权重底色只覆盖实际原文，排除译文、空行、透明补位及选区附加尾框；同色路径合并消除接缝。行尾长译文不拉宽原文闭合符号，手动换行光标与上一行译文分开，空行保留普通行高。[源码与证据](inline-reading-paint-fix-2026-11-15.md)
- 有效源码`E:/A.I/NovelAI/.devin/wt/ui-integration/`，分支codex/uiux-integration，基于`484c90ba3ddecb06121450ea6d0de11ab9d065f8`加本轮未提交修复。冻结2170个生产输入，相对+108仅4项变化；8项未提交文件保留完整快照和哈希。输入与产物一致，并非宣称该Git提交已包含未提交源码。
- Windows Release构建成功，AOT SHA-256：`3a1a5b60414f55ad102e1196cde178d55e4df57fd1a8d75c34f328c32686a231`。差量替换5项：CHANGELOG.md、package-info.json、data/app.so、nai_launcher.exe、app_files_manifest.json；15557个程序文件核验通过，无新增／移除项，资源、原生DLL及Agent／RAG保持。
- 复用同一源码的544项回归和全仓分析0问题，含16项横纵像素检查、24项动态换行检查；本轮另跑3项打包与4项隔离安装器检查。源码哈希与前轮验证完全一致，没有重复运行未变模块的Node／RAG套件。
- 14项关键用户文件、用户根目录、图库数据库、3个索引文件、旧数据入口与桌面快捷方式保持。没有模型／NAI请求，没有重建索引、移动素材或清理历史载荷。
- 已备份+108程序data目录及旧收据，回退材料核验通过；本轮只调用只读的`verify-backup`，没有执行实际rollback。需要真正降级时，完全退出Studio与托盘后再运行`python .dart_tool/local-2.4.0-build109-20261115/update.py rollback`，恢复+108。

本批材料在`.dart_tool/local-2.4.0-build109-20261115/`：`build-inputs-start.json`、`source-snapshot/`、`reviewed-source.patch`、`test-summary.json`、`package-verification.json`、`final-verification.json`及`user-data-preservation.json`。原型和改前PNG保持，用户实机体验仍由本次桌面测试确认。
