# 本机2.4.1+115交付核验

用户2026-11-15授权更新桌面版，原运行目录已更新为**2.4.1+115**。未启动或操控Studio，待用户打开原快捷方式实测。正式发布继续暂缓。

## 本批内容

- 首次补全宽度按底部快捷键提示完整一行计算；窄窗保留自然换行。
- 关联提示统一「Tab / 回车追加」，五语言同步。
- 热度数字按实际宽度单行右对齐，修复629.4k的k被挤到下一行。
- 保留+114的选区细缝与候选滚动修复，以及此前输入法和补全优化；Ctrl标签扩展定位保持。

## 构建与安装

| 项目 | 核验结果 |
|---|---|
| 源码 | `.devin/wt/ui-integration/`，HEAD/main `10b3424fc75963df7458aa4dbcd0b8c1fb571550` 加未提交改动 |
| 冻结输入 | 2,171项生产输入、46项已有改动；相对+114变化13项，含浮层源码、五语言源／生成文件、版本及CHANGELOG |
| SDK | Flutter3.47.7／Dart3.13.5，Windows Release，`--no-pub --no-tree-shake-icons` |
| 运行目录 | `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/` |
| 版本／身份 | EXE ProductVersion为2.4.1+115，FilePrivatePart为115；存储身份com.example/nai_launcher保持 |
| 载荷 | 15,557项程序文件全部核验，替换5项，无新增／退役；资源、原生DLL、Agent和RAG保持 |
| 用户数据 | 14项关键文件、图库、3项当前索引、数据根、旧入口及快捷方式保持 |
| 回退 | +114完整data与替换文件备份已核验；保留旧收据，未实际降级 |

本批替换`data/app.so`、`nai_launcher.exe`、`CHANGELOG.md`、`package-info.json`及`app_files_manifest.json`。安装前现场确认Studio和附属进程完全退出，没有终止用户进程。

AOT SHA-256：`7177e3333a815d977939dc9abf9f5d42b2224081153aee70b676d10715ff26f5`。

## 验证与材料

复用源码哈希一致的66项浮层与4项繁中资源检查、4组真实字体部件实绘及全仓分析0问题；本批另跑3项打包与4项隔离安装／回退检查。Windows Release构建、组包、安装及完整文件核验通过。[功能证据](autocomplete-width-2026-11-15.md)

未请求真实模型或NAI、编辑用户草稿、重建索引、启动应用或操作GitHub发布。安装暂存清理继续暂停，保留payload、空暂存目录及历史回退。

当前收据：`nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。本批材料：`.dart_tool/local-2.4.1-build115-20261115/`，含冻结、构建、组包、安装、数据保持、最终核验及文档补记记录。

仅验证备份：`python .dart_tool/local-2.4.1-build115-20261115/update.py verify-backup`。

实际回退须先由用户完全退出Studio和托盘，再运行`python .dart_tool/local-2.4.1-build115-20261115/update.py rollback`，恢复+114；当前未执行回退。
