# Agent 展开后的历史栏标题垂直居中

2026-10-21 用户反馈：展开 Agent 侧栏后，“历史记录”和多选图标贴在顶部。本项已随 [r35 累计更新](cumulative-preview-r35-2026-10-21.md) 安装到原桌面入口。

## 原因与改动

Agent 停靠时，历史栏不再预留窗口按钮行，改由 `WindowHeaderDragSurface` 承接标题栏空白处的拖窗操作。该组件插入的 `Stack` 默认松开子节点约束，将 40px 标题行里的内容收成 28px 并靠上放置。合成组件复现中，标题和控件中心在 y=14，标题行中心在 y=20，上偏 6px。

拖窗组件改用 `StackFit.passthrough`，让内容继续接收原来的高度约束。标题行高度、底部分隔线、按钮尺寸与回调保持；扣除 1px 底边框后，内容中心回到 y=19.5。窗口按钮仍由最右侧 Agent 承接。

生产改动仅 `lib/presentation/widgets/navigation/window_chrome_layout.dart`。施工前副本位于 `.dart_tool/history-header-center-20261021/window_chrome_layout.before.dart`。

## 验证

- Flutter 3.47.7 / Dart 3.13.5，使用工作区登记 SDK。
- 新增真实字体组件回归 `test/presentation/ui/gen/gen_history_header_layout_test.dart`：五语言、明暗主题、200/280px 历史栏，反复切换 Agent 收起／展开／收起；验证文字、收起按钮和多选图标的垂直中心、窗口按钮预留位置，以及空白拖窗和按钮独立点击。
- 修改前复现失败，中心差 6px，见 `.dart_tool/history-header-center-20261021/before.log`。
- 相关 **245 项全部通过**：新增居中回归、生图原有 PNG 基准、页面交互、多语言布局、窗口标题／拖动、Agent 实际宿主组件及历史栏交互。证据 `.dart_tool/history-header-center-20261021/regression.log`；没有重录或修改原 PNG 基准。
- 已查看修改前后中文浅色实绘；明暗截图位于 `.dart_tool/history-header-center-20261021/{before,after}/`。截图使用合成数据，不是当前安装程序。
- 范围分析与格式／差异检查见同目录 `analyze.log`、`checks.log`；原有未提交 `pubspec.lock` SHA-256 保持 `92e4a8906d8f0ae8387daa1b8bd53e3c9840b8aaf0035b16d9c8e796a5095d6c`。

本项已完成构建与安装；未启动／重启／热重载应用或操作用户数据。
