# 本机2.4.1+114交付核验

用户2026-11-15授权更新桌面版。本机原运行路径已更新到**2.4.1+114**，未启动或操控Studio，待用户打开原快捷方式实测。正式发布继续暂缓。

## 本批内容

- [选区细缝修复](selection-seams-2026-11-15.md)：没有译文时恢复整行选区；有译文时继续排除注释区域，保留行高、光标与输入法。
- [补全候选键盘滚动](autocomplete-scroll-2026-11-15.md)：选框先在视口内下移，接近底部后保留下方一个完整候选再滚动；两栏共用实际行高，支持换行候选。
- 保留+113的输入法修复、输入辅助默认开启、自适应候选换行及仅实际键入触发。

## 构建与安装

| 项目 | 核验结果 |
|---|---|
| 源码 | `.devin/wt/ui-integration/`，HEAD/main `10b3424fc75963df7458aa4dbcd0b8c1fb571550` 加本轮未提交改动 |
| 冻结输入 | 2,171项生产输入、34项已有工作树改动；相对+113变化4项：两处功能源码、版本号和CHANGELOG |
| SDK | Flutter3.47.7／Dart3.13.5，Windows Release，`--no-pub --no-tree-shake-icons` |
| 原运行目录 | `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/` |
| 版本与身份 | EXE ProductVersion为2.4.1+114，FilePrivatePart为114；存储身份仍com.example/nai_launcher |
| 交付 | 15,557项程序文件全部核验，替换5项，无新增／退役；原生DLL、资源、Agent和RAG未变 |
| 用户数据 | 14项关键文件、图库数据库、3项当前索引、数据根、旧入口与快捷方式保持 |
| 回退 | +113完整data和替换文件备份已核验，保留旧收据；未实际降级 |

本批替换`data/app.so`、`nai_launcher.exe`、`CHANGELOG.md`、`package-info.json`及`app_files_manifest.json`。安装前现场确认Studio及附属进程完全退出，没有终止用户进程。

AOT SHA-256：`07635d5b0778d1d387494095effa14cb7e21ce6bef22febc6a39d6eaf63b69bd`。

## 验证与边界

复用当前源码哈希一致的669项相关回归、50项浮层专项、8项新增滚动检查与全仓分析0问题；合并回归包含12项选区像素检查。另跑3项打包及4项隔离安装／回退检查，Windows Release构建、组包、安装及完整文件核验通过。未请求真实模型或NAI、编辑用户草稿、重建索引或启动应用。

本轮未提交／推送Git或重启GitHub发布。安装暂存清理继续暂停，没有删除payload、空暂存目录或历史回退材料。

## 材料与恢复

当前收据：`nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。本批材料：`.dart_tool/local-2.4.1-build114-20261115/`，含输入冻结、构建、组包、安装、用户数据、最终核验与文档补记记录。

仅验证备份：`python .dart_tool/local-2.4.1-build114-20261115/update.py verify-backup`。

需要回退时，由用户完全退出Studio和托盘后运行`python .dart_tool/local-2.4.1-build114-20261115/update.py rollback`，将实际恢复+113；当前未执行回退。
