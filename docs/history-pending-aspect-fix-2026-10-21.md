# 历史栏生成中占位跟随批次比例

2026-10-21 用户反馈：横图生成时历史栏仍显示竖图加载卡。本项已随 [r34 累计更新](cumulative-preview-r34-2026-10-21.md) 安装到原桌面入口。

## 原因与改动

占位布局在 `gen_history.dart` 写死 `832 / 1216`；同时 `generationHistoryBatchesProvider` 为避免进度通知反复重建，只投影运行状态、runId 和数量，没有把已有的 `batchWidth / batchHeight` 传给历史视图。

- 历史数据投影增加批次宽高，优先使用点击生成时捕获的分辨率。与画布占位相同，仅缺批次尺寸时回退已有显示尺寸，不读取等待过程中修改的参数草稿。
- `GenBatch` 增加可空 `pendingWidth / pendingHeight`，一并参与结构比较。只改变尺寸也会通知界面；进度变化及旧预览尺寸变化不重建已有批次数据。
- 首图返回前用批次比例计算历史占位，返回后仍用图片自身尺寸。旧夹具未提供新字段时保留默认比例，不改已有基准图、批次计数、焦点或封面选择规则。

改动文件：`lib/presentation/ui/gen/gen_contract.dart`、`gen_history.dart`，以及 `lib/presentation/wiring/generation_data_wiring.dart`、`generation_view_mapping.dart`。施工前副本位于 `.dart_tool/history-pending-aspect-20261021/*.before`。

## 验证

- Flutter 3.47.7 / Dart 3.13.5。
- 新增 `test/presentation/wiring/generation_history_pending_layout_test.dart`，贯穿实际历史 provider → 视图契约 → 历史栏组件；只替换生成 notifier、收藏和时钟，不调用生成接口或读取用户资料。
- 六个场景：1216×832、832×1216、1024×1024，分别验证明暗主题。检查批次宽高准确传递、同 run 仅改变尺寸时刷新、成图与占位严格同尺寸替换。比例测量允许现有 1px 分隔线带来的宽度约束差。
- 修复前初版六项复现场景均失败：横图与方图都读到竖图比例 `0.6842105263`，同 run 尺寸变化也未到达历史 UI。日志 `.dart_tool/history-pending-aspect-20261021/before.log`。
- 相关 **306 项全部通过**：完整 `test/presentation/ui/gen`（含原视觉基准）、新增历史占位接线、生成视图映射、数据接线和实际页面接线。日志 `regression.log`。
- 随后加强六项专题，确认进度与旧预览尺寸更新保持批次列表实例、占位尺寸不变，再次全部通过；日志 `final-focused.log`。专题包含在 306 的范围内，不重复相加。
- 五个修改／新增文件 analyze 无问题，格式与 `git diff --check` 通过，原有 `pubspec.lock` 哈希保持。
- 六张组件实绘在 `.dart_tool/history-pending-aspect-20261021/captures/`，已查看横图明暗图核对；这是合成数据组件实绘，不是运行中用户窗口截图。

本项已完成构建与安装；未改生成参数或请求、未写用户草稿、未实际生图，未启动／重启／热重载应用。实际窗口体验由用户启动新版后确认。
