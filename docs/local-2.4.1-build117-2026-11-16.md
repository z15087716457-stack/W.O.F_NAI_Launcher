# 本机 2.4.1+117 交付核验

2026-11-16 按用户明确要求更新原桌面运行目录。**已安装 2.4.1+117，未自动启动，待用户复测。** 本批包含 [RAG恢复／GPU标记对齐](rag-recovery-fix-2026-11-16.md)和此前待交付的[Ctrl右侧大图预览](wiki-side-preview-2026-11-16.md)。公开版仍为 2.4.1+115，本次未提交、推送或发布 GitHub。

## 结果与保持

- 修复 RAG 配置后读取退役字段而终止、线程故障未断连以及重试复用失效宿主；运行环境检测按具体原因展示。本机实际环境已定点补齐 jieba，其他依赖版本保持，实际 probe 返回 ready／CUDA 可用。
- 本地放大页 GPU 能力标记恢复靠右，窄窗换行。Ctrl 缩略图使用单一右侧大图预览，同图开关、换图原位切换、窄窗下移；修复重复叠窗和连续改窗定位。
- 14 项关键用户文件、图库数据库／扫描状态、3 项当前索引文件、数据根、AppData Junction 和原桌面快捷方式核验保持；没有清库或重建正式索引。新标签多视图集合首次建立仍须明确操作，其他来源不因本次恢复要求重建。
- +116 完整程序 data、被替换文件与旧收据已备份并验证，保留单步回退。+115 及更早回退材料继续保留；安装暂存清理仍暂停。

## 构建与安装

| 项目 | 核验结果 |
|---|---|
| 有效源码 | `.devin/wt/ui-integration`，HEAD/main `517163c5455ac765158016aa9204f4a5bca57da0` 加未提交改动 |
| 冻结输入 | 2,170 项构建输入、107 项已有文件改动；相对 +116 改变 25 项输入，没有退役输入 |
| SDK | Flutter 3.47.7／Dart 3.13.5，Windows Release，`--no-pub --no-tree-shake-icons` |
| 运行目录 | `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/` |
| 版本与身份 | EXE ProductVersion `2.4.1+117`、FilePrivatePart 117，存储身份保持 `com.example/nai_launcher` |
| 程序清单 | 15,558 项核验通过；仅交付 6 项，无新增／退役程序文件 |
| 原生与 Agent | DLL 代码／依赖保持；15,280 项 Agent 文件一致，Pi 1.5.0 保持 |
| 回退 | +116 完整 data 及替换文件备份核验通过，未实际降级 |

替换文件为 AOT、EXE、随包 `tool/rag/worker.py`、CHANGELOG 与两项包清单。安装前及覆盖过程中均检查进程完全退出，没有用标准 Release 整目录覆盖 Glass 包。构建耗时约 104 秒，安装约 41 秒。

AOT SHA-256：`6968037c7514c07f73ad3a1e47ab681db681877ada77b407ec0abeaee97ffa40`。

## 验证与边界

复用当前源码已通过的 1,006 项相关 Flutter 功能／布局回归、153 项实际环境 Python 检查及全仓分析 0 问题；此次另跑 2 项随包真实 worker 进程检查和 4 项隔离安装／失败恢复／回退检查，均通过。13 项环境／GPU界面专项实绘和右侧预览证据保留。

旧设置 PNG 基线 16 项通过、11 项差异；同样差异已在本次修复前复现，未更新锁定 PNG，也没有将该组计入功能通过数。真实 worker 检查使用隔离来源与索引，不加载模型权重推理；未请求 NAI／语言模型、写用户草稿或重建正式索引。

收据：`nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。本批材料：`.dart_tool/local-2.4.1-build117-20261116/`，含输入冻结、编译、组包、安装、用户数据保持、回退和文档核验。

只读核对回退：`python .dart_tool/local-2.4.1-build117-20261116/update.py verify-backup`。实际回退须完全退出 Studio／托盘后执行同一脚本的 `rollback`，恢复 +116。
