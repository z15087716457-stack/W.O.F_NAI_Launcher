# 画布工具后端接线（2026-10-13）

当前在 `.devin/wt/ui-tools`／`devin/ui-tools` 从前端 `ed37520d` 施工。三块工具界面的后端已经接入并完成下列专项验证；六份旧界面清理已获用户确认并执行，分支内后端收口完成，随本记录本地提交。全仓验证及保留问题见下文；尚未整合页面分支或构建／安装真实桌面包。

## 已完成的接线

- 生图工具条通过新 `toolSheet` 槽位显示 `ToolsEnhanceSheet`／`ToolsUpscaleSheet`，替换生图页原工具浮层。增强倍率、五档幅度、自定义强度／噪声、V5 Max、本地模型摘要、额度与报价、放大方法／模型／SeedVR2 高级设置和进度接入既有 provider。增强请求与工具条提示共用报价映射；Max 展示真实目标尺寸。打开、设置及关闭增强不改草稿底图；关闭图生图后，本地增强请求也保持关闭状态。
- 已完成生图 `42392821` 的 31 份必要生产依赖按文件补入本分支，保持工具前端新增契约、文案、截图与预览。没有 merge 或 cherry-pick 其他页面分支，没有扩大成全页面整合。
- `ToolsEditorWiring` 填入真实 `EditorCanvas`，保留原编辑器 session、导出、蒙版、聚焦、扩展边缘、撤销、图层与 3D 场景逻辑。工具／颜色／笔尖／压感／方形笔刷、蒙版外观、尺寸、缩放、图层操作与 HSV 预览接到原引擎；HSV 旧结果不能覆盖新笔画，图层复制／合并／撤销保留 raster 像素和 3D 数据。蒙版覆盖／块数统计同一会话只运行一项计算，变更合并到最新快照，旧结果和销毁后的结果不回写；完整蒙版、撤销回空蒙版的统计回归通过。应用后通过入口的完整草稿备份与最新状态检查提交；“应用并生成”使用受保护的生成链路重新确认费用。
- `ToolsDirectorWiring` 接入七类工具、稳定输入／结果 ID、真实图片尺寸、全部背景移除变体、表情、像素选项、输入文件／历史／粘贴／拖入、复制／保存、继续处理、放大和图生图。报价确认期间改工具、输入、账号切回、新生成或关闭会拒绝旧确认；旧处理结果不注册到失效会话，返回图生图也不能覆盖打开后新改的草稿。关闭错误保留已有结果。
- 云端及本地放大在账号变化后取消任务，旧结果不能回写；旧账号的云放大任务不刷新新账号余额。生图请求取消不初始化尚未创建的 API provider。
- 3D 入口测试改用新工具控件，原场景、像素、窗口、撤销及失败保护断言保持。独立编辑器只读取已经初始化的生图／订阅状态来显示报价，不触发账号存储初始化。

## 当前验证

登记 SDK 为 Flutter 3.47.7／Dart 3.13.5，已现场核对。测试使用内存订阅、草稿备份、存储、账号、模拟生成与增强 API，以及隔离 Hive／临时目录；没有调用真实生成、增强、云放大或付费编码。

| 范围 | 最新结果 |
|---|---|
| 锁定 UI／截图回归 | 原始基线及最终全仓内复验均为 623 项全部通过 |
| 清理前综合专项，含整个 `test/presentation/ui`、接线、生成／导演 provider、工作流启动器及原编辑器／图层／3D／画笔／导出引擎回归 | 999 项全部通过，退出 0 |
| 全仓最终执行 | 5344 通过、5 跳过、37 失败；退出 1，不能记作全仓通过 |
| 新接线范围（最终全仓内） | 全部 157 项通过，其中画布工具新增 15 项全部通过 |
| 编辑器／蒙版／导出／图生图入口／图层／3D 接线定向回归 | 54 通过、10 失败；10 项均为 390px 锁定前端溢出 |
| 修改范围分析 | 清理后 70 个现存修改／新增 Dart 文件，退出 0，`No issues found!` |
| 接线说明要求的边界范围分析 | `lib/presentation/ui`、`lib/presentation/wiring`、`tool/ui_shell`、`test/presentation/ui` 四范围退出 0，无诊断 |
| 格式 | 清理后 70 文件，`0 changed`，退出 0 |
| 限定业务生成 | 131 个输入／303 个输出成功；旧解析器对新版 SDK 的提示保留 |
| 保护 | 426 份锁定 UI／测试／截图／预览、锁文件及四个用户原有文件已备份并核验保持 |

以上计数有覆盖，不相加。这是分支内专项结果；最终全仓执行完成但仍有下列 37 项失败，未通过全仓或真实桌面整合验收。生图分支已记录的 352px 窄栏前端问题继续保留，不在本轮修改锁定界面。

最终 37 项失败分组（没有排除失败用例）：

- 10 项新编辑器 390px 顶栏溢出：五种语言 × 明暗。720px／1440px 的真实画布矩阵均通过；纯 `ToolsFixture.editor` + `ToolsEditorPage`／`ToolsFixtureStage`（没有 provider 或转接层）同样复现。中文／繁中 216px、英文 251px、日文 281px、韩文 220px，定位锁定 `tools_editor.dart` 顶栏 `_TopBar` 的 Row。无溢出原断言保持，记录为 FE-04 交前端统一收尾。
- 2 项原工程编译入口：`i18n_regression_test.dart` 引用已不存在的 `statistics_monday`；`uiux_final_capture_test.dart` 引用本分支不存在的旧 NAI Agent workspace provider。这两份测试及相关基线缺失不由本批 50 个旧键清理引入。
- 2 项独立设置字号比例预期（现有 effectiveScale 为 1.0，旧测试期待 1.1），22 项旧库页头拖动回归，以及 1 项静态配色检查指向未改动的锁定 `ui/online/online_popovers.dart`。作为分支工程／旧页面验收遗留单列，不扩大本轮锁定界面施工。

旧蒙版混合测试没有删除：32 项的真实画布／语言／宽度矩阵保留，旧控件定位迁到新工具控件；实际画布边界仍精确匹配槽位，原像素、外观不改变导出、undo、聚焦上下文及无溢出断言保持。图生图入口按兼容基类查找新宿主；提交期间保护改为实际尝试新“应用”按钮与导出入口后仍不退出、不改变图层。测试在销毁会话前等原生统计结束，防止隔离测试的待完成计算占住后续会话。

本机材料：`.dart_tool/ui-tools-backend-20261013/`，最终测试明细在 `full-final.jsonl` 与 `final-test-summary.json`；纯前端探针存为本机 `pure-width-probe.dart`／`pure-width-probe.jsonl`，临时测试入口已移除。材料还包含 `protected.json`、`originals/`、`generation-prerequisite.json`、原始 UI 基线、综合／定向日志、分析／格式范围、限定生成日志及清理候选 SHA-256。原有 `analysis_options.yaml`、三份 Windows generated plugin 文件不纳入提交；两份生成 Dart 若只有行尾状态而无有效内容差异也不纳入提交。

## 已批准并执行的六份旧文件清理

已按接线说明第 3.4 节“删之前先列清单给用户确认”列出这六份文件；用户回答“批准这 6 份清理”后核对 SHA-256、备份并执行。没有扩大文件删除范围。

| 文件 | 理由／保留方式 |
|---|---|
| `lib/presentation/screens/director_tools/director_tools_screen.dart` | 主入口已切到 `ToolsDirectorWiring`，旧导演工具布局退役；notifier、远程 service 和 Pixel Snap 引擎保留 |
| `lib/presentation/widgets/image_editor/image_editor_screen_layout.dart` | 退役旧 2D 浮层布局；其 3D 场景、图层托盘、切层提交、上下文与导出业务已迁入 `image_editor_session_models.dart`，原 `ImageEditorScreen` session 与兼容入口保留 |
| `test/presentation/screens/director_tools/director_tools_screen_test.dart` | 旧布局／工具选项适配测试；新壳中文交互／截图与真实接线回归已覆盖，原 notifier 业务测试保留 |
| `test/presentation/screens/director_tools/director_tools_layout_test.dart` | 旧布局位置测量；新前端锁定测量和基准截图保留 |
| `test/presentation/widgets/image_editor/image_editor_overlay_layout_test.dart` | 旧浮层几何断言；新壳锁定布局、实际画布、输入及 3D 回归保留 |
| `test/presentation/widgets/image_editor/edit_image_official_ui_test.dart` | 旧整页工具外观／捕获矩阵；新壳锁定 UI／截图与原图像像素、控件、导出等共享引擎回归保留 |

保留的 3D／导出实现为 `lib/presentation/widgets/image_editor/image_editor_session_models.dart`，252 行；批准前清单与 SHA-256 在 `cleanup-proposal.json`，删除前原件备份在 `before-cleanup/`。国际化静态检查迁到新接线与保留文件，保持原检查断言；旧布局退役后无调用的两个字段、三个 import 与一个旧弹窗入口方法随之移除，共享弹窗与引擎文件保留。

旧界面中出现、且在全部活动 `lib/core`／`lib/data`／`lib/presentation`／`test`／`tool` Dart 中已无引用的 50 个文案键，四份手写 ARB 同批清理；通过既有工具重生繁体、再生成 Flutter 本地化。仅删除旧键，不改新壳中文及其他语言草稿；繁体资源生成／内容回归 4 项通过。新壳多语言定稿与整合适配仍属于后续统一前端收尾。

`GenerationToolPanel`、`LocalUpscalePanel`、`CanvasUpscaleButton` 仍被旧探索／预览／图生图等共享调用方使用，暂不删除。新生图路由已用新工具槽位，本批不清理其他页面的共享依赖。没有修改 `lib/presentation/ui/`、契约、fixtures、goldens 或 `tool/ui_shell/`，没有使用 `--update-goldens`、放宽失败断言、更新桌面 UIUX Preview、操作 Studio、构建／安装或推送。
