# 本机2.4.1+113交付核验

用户2026-11-15授权更新桌面版。本机原运行路径已更新到**2.4.1+113**，未启动、重启或操控Studio，未推送Git或重新发布。界面和真实输入法体验待用户打开原快捷方式实测。

## 本批内容

- 输入法重复组词修复：有效空组合区不再被改成无效范围，保留输入法开始／候选／确认生命周期。[原因与验证](semantic-inline-translation-2026-11-15.md#输入法组词补修)
- 提示词自动补全默认开启，Ctrl标签扩展原本即默认开启；两项独立可调，已有关闭偏好保持。
- 用户确认的自适应候选换行：长标签／译名完整显示，热度右对齐，限高列表按实际行高滚动，窄窗上下排栏，窗口／界面缩放时保留焦点和选中。
- 仅实际键入触发，从本次输入首字查询并限定替换范围；导入、填参、粘贴和光标移动不弹，IME确认后再查询。原生粘贴和撤销链保持。[实施与证据](autocomplete-wrap-2026-11-15.md)

## 构建与安装

| 项目 | 核验结果 |
|---|---|
| 源码 | `.devin/wt/ui-integration/`，HEAD/main `10b3424fc75963df7458aa4dbcd0b8c1fb571550` 加本轮未提交改动 |
| 冻结输入 | 2,171项生产输入、29项已有工作树改动；相对+112变化13项，包括双语README的既有排版说明更新 |
| SDK | Flutter3.47.7／Dart3.13.5，Windows Release，`--no-pub --no-tree-shake-icons` |
| 原运行目录 | `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/` |
| 版本与身份 | EXE ProductVersion为2.4.1+113、FilePrivatePart为113；存储身份仍com.example/nai_launcher |
| 交付 | 15,557项程序文件全部核验，替换7项，无新增／退役；原生DLL、资源、Agent、RAG未变 |
| 用户数据 | 14项关键文件状态、图库数据库、3项当前索引、数据根、旧入口及原快捷方式保持 |
| 回退 | +112完整data备份及本批替换文件已只读核验，保留旧收据；未实际降级 |

本批7项替换为`data/app.so`、`nai_launcher.exe`、`CHANGELOG.md`、两份README、`package-info.json`及`app_files_manifest.json`。安装前现场确认Studio及附属运行进程均已完全退出；没有自动终止任何用户进程。

AOT SHA-256：`039735846ca79a17ca3710108de7889a27f77264509d5ab933557cb3691bf0e6`。

## 验证边界

- 复用生产源码哈希一致的680项相关回归、52项最终专项、4组真实字体实绘及全仓分析0问题；输入法真实Flutter Windows文本模型改前重复／改后正确的证据继续有效。Windows／Mac平台变体检查不代表Mac实机已验收。
- 本批另跑3项打包检查、4项隔离安装／回退检查，Windows Release构建成功；版本、原生依赖、资源、Agent清单、差量载荷、源码与安装后文件核验均通过。
- 未调用真实模型或NAI、未编辑用户草稿、未重建索引、未启动应用。GitHub正式2.4.1发布继续暂缓，旧取消流程不重跑。
- 安装暂存清理仍保持暂停；没有删除本批payload、空暂存目录或历史回退材料。

## 材料与恢复

当前收据：`nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。本批材料：`.dart_tool/local-2.4.1-build113-20261115/`，含`build-inputs-start.json`、`build-result.json`、`package-verification.json`、`final-verification.json`、`user-data-preservation.json`与文档补记核验。

仅验证备份：`python .dart_tool/local-2.4.1-build113-20261115/update.py verify-backup`。

需要回退时，先由用户完全退出Studio和托盘，再运行`python .dart_tool/local-2.4.1-build113-20261115/update.py rollback`。该命令会实际恢复+112，不是检查命令；当前未执行回退。
