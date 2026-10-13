# 页面顶部空白区域拖拽 · 2026-10-05

在线画廊、提示词块管理、Vibe 库、精准参考库、Wiki 和统计仪表盘的顶部空白区域现在可以拖动桌面窗口，双击空白区域沿用最大化/还原行为。块管理、Vibe 和 Wiki 的桌面左侧栏顶部也适用。保留各页面现有工具栏高度与窗口按钮预留布局。

共享 `WindowHeaderDragSurface` 将拖拽目标放在控件后面，`WindowHeader.dragBackground` 按页面启用；搜索框、按钮和菜单优先接收鼠标事件。有背景绘制的容器把拖拽层放在绘制层内部，静态侧栏标题通过 `IgnorePointer` 放行其占据的空白。右侧详情栏接管窗口按钮时，块管理顶部仍可拖拽。

Wiki 目录底部弹窗默认不启用窗口拖拽；新增、排序等弹窗及菜单继续隔离下层窗口区域。顺带修复精准参考库在英文 900px 窗口的工具栏溢出：搜索框在剩余空间内右对齐，最大宽度仍为 220px。

本次验证共 138 项通过：

- `test/presentation/screens/page_header_drag_test.dart`：68 项，使用实际六个页面、隔离 provider 和存储、Windows 平台鼠标。覆盖五种语言、900/1600px、深/浅主题、主工具栏和侧栏拖拽、字段交互、窗口按钮、多选、展开详情栏、刷新及弹窗隔离。
- `test/presentation/widgets/navigation/window_header_background_drag_test.dart`：5 项，覆盖 400/1000px、预留窗口按钮开启/关闭、鼠标选字且草稿保持、按钮/菜单、拖拽及双击最大化/还原、非桌面窗口容器。
- 现有窗口容器/覆盖层/按钮下方拖拽、在线画廊、块管理、精准参考、Wiki 页面/目录/书签和 Vibe 结构回归：65 项。
- 受影响八份源码与两份新增测试的 analyze 无问题，修改范围 diff check 通过。没有新增国际化文案、依赖或生成输入。

证据位于本机忽略目录 `.dart_tool/page-header-drag-20261005/`：修改前源码与状态、`page-tests.log`、`shared-tests.log`、`regression-tests.log`、`analyze.log` 和 12 张真实字体/Material 图标控件实绘。截图是隔离数据的 widget 渲染，不是运行中用户窗口截图；窗口操作由方法通道记录验证，实际 Windows 拖动仍待安装后实机验收。

已随本地超分合并包于 2026-10-05 19:06（Asia/Taipei）安装，当前运行版为 `36f4d4f0`，AOT `eefd3789840743df2a325bbd3edae28a96a89c76f775de833f8706777d153978`。安装与前版回退备份复验通过；未自动启动、重启或热重载。实际 Windows 拖动仍待用户反馈，完整检查点 `2026-10-05-studio-verified` 固定为满意版本 `09ea804f`。
