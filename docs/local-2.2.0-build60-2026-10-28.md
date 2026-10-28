# 本机 2.2.0+60 安装记录

2026-10-28 22:16（Asia/Taipei）按用户“推送一下安装”从 +59 原位升级。**已安装并完成程序文件、回退与受保护目录核验**，当前无待安装增量。编译 `bc745f5af4bcdf3c2827a8a22e1166faa88c9ea0`；后续文档提交不触发重编，实机体验由用户自行检查。

- 权重着色区域的光标保持可见，统一提示词与翻译块原文编辑共用修复。
- 历史栏“打开详情”单击进入大图；“联动预览”和多选保持，设置即时生效。
- 批次分组同时适用于简洁查看器与无限画布，关闭时完成图纵向逐张排列、历史逐张显示；生成占位、真实批次与保存数据保持。

## 验证

核对全部 2101 个生产输入，功能源码与刚完成的回归一致，仅升级版本号至 +60。复用分轮回归：首跑 9781 通过／9 错误／5 既有跳过；旧夹具和文字基准修正后，相关套件 52 项全部通过，按文件／测试名／序号合并覆盖 9790 项通过、无待处理失败、5 既有跳过。保留原失败日志，不声称新跑一次全绿全量。

全仓 analyze 与未变的 Node 112 项结果复用；新跑版本／更新 56 项、安装回退夹具 12 项通过。登记 SDK 的 Windows Release 构建、完整程序包、SQLite 资源／字体／原生身份、Agent／CodeMode／会话恢复及隔离 RAG ready/shutdown 冒烟通过。

仅替换 3 个文件：`data/app.so`, `nai_launcher.exe`, `app_files_manifest.json`。无新增或删除程序文件。安装后 15294 个程序文件与收据一致，原桌面入口、数据目录身份、兼容联接、3 个正式索引文件元数据和回退备份保持。AOT SHA-256：`25a409bf3a7464ffcc3d940ae2481f9b80f86a0f6bceb037fc98e418384cddf7`。

## 位置与回退

- 运行目录：`E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/`；桌面入口仍为原 `W.O.F NAI Studio.lnk`。
- 交付与回退：有效源码 `.dart_tool/cumulative-2.2.0-r4-20261028/`，`installed-delivery.json`、`release-validation.json`、`package-verification.json`、`final-verification.json` 为本轮证据。
- 回退到 +59：完全退出 Studio／Agent 后，在该交付目录运行 `python update.py rollback`。

未自动启动、重启或操作 Studio，未调用真实模型／生图、读取或改写正式索引、制作 ZIP 或发布 GitHub。公开版仍为 2.2.0+56，本机 +57 至 +60 的增量未公开发布。
