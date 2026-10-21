# 积木浮窗拖拽预览层级修正

2026-10-21 用户反馈：积木浮窗在上层，块拖到窗口处被遮住，难以拖入。本项已随 [r34 累计更新](cumulative-preview-r34-2026-10-21.md) 安装到原桌面入口。

## 原因与改动

实际主页面位于 `StatefulShellRoute` 的分支 Navigator。r33 积木浮窗放在根 Overlay，而 `BlocksDock` 的 `Draggable<Object>` 默认使用最近的页面 Overlay；拖拽预览进入浮窗区域时，被根浮层上的不透明卡片盖住。

在 `lib/presentation/ui/blocks/blocks_dock.dart` 为侧栏拖拽设置 `rootOverlay: true`，使预览在根浮层绘制，并排在已有积木浮窗上方。保留浮窗的框外操作、关闭方式、位置和现有拖放数据链路。

隔离复现中，修复前松手收纳回调已能成功，明确复现的是**预览被遮挡**，不能据此认定所有来源的拖放写入都失败。修复后同时验证预览可见和松手收纳成功。

## 验证

- 登记 Flutter 3.47.7 / Dart 3.13.5。
- 新增 `test/presentation/wiring/generation_palette_drag_test.dart`：使用真实 `BlocksDockWiring` 与积木浮窗，覆盖普通页面和嵌套 Navigator；截图区域逐像素检查拖动预览确实画在浮窗表面，同时检查收纳回调和浮窗保持打开。使用合成块库与内存积木状态，不操作用户资料。
- 修复前：普通页面通过，嵌套页面失败；预览覆盖区域变化像素数为 0。日志 `.dart_tool/palette-drag-before.log`。
- 修复后：两项均通过。日志 `.dart_tool/palette-drag-after.log`。
- 相关回归 **245 项全部通过**：新增跨层拖放、`widgets/prompt/blocks`、`ui/blocks`、生成编辑器接线与生成后端。日志 `.dart_tool/palette-drag-20261021/regression.log`。
- 修改的生产文件与新增测试 analyze 无问题；`git diff --check` 通过。原有 `pubspec.lock` 未提交改动哈希保持。

合成组件实绘位于 `.dart_tool/palette-drag-20261021/before/dragging-true.png` 和 `after/dragging-true.png`，已查看核对；不是用户正在运行的窗口截图。生产文件改动前副本保存在该目录的 `blocks_dock.before.dart`。

本项已完成构建与安装；未启动、重启或热重载应用，未写用户草稿或调用生成接口。实际窗口体验由用户启动新版后确认。
