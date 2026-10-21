# 本地画廊左右页头对齐

2026-10-21 用户要求将左侧“本地画廊”和加号对齐右侧“全部图片”行。本项源码完成，尚未构建或安装，等待与历史栏居中修正一起累计更新；桌面仍为 r34。

## 改动与测量

左侧固定 62px 页头中的 `Stack` 默认松开内容约束，标题和按钮实际中心为 y=19；右侧工具行中心为 y=31。该页使用独立布局，不经过上一项修正的 `WindowHeaderDragSurface`。

左侧页头改为 `StackFit.passthrough`，内容使用完整行高；原本作用于整个左栏的 -1px 平移仅保留在分类树上，让标题／加号与右侧中心同为 y=31，同时保留分类树及页脚的位置。没有改变图库数据或操作回调。

生产改动仅 `lib/presentation/screens/local_gallery/local_gallery_screen.dart`。施工前副本在 `.dart_tool/gallery-header-center-20261021/local_gallery_screen.before.dart`。

## 验证

- 使用登记 Flutter 3.47.7 / Dart 3.13.5。
- 在原有三栏实绘测试中加入左右标题与加号的中心检查，复用五语言、明暗主题及 1100／1366／1600／1920px 窗口场景；未添加或重录 PNG 基准。
- 修改前中心差 12px，复现失败见 `.dart_tool/gallery-header-center-20261021/before.log`；修改后相关 **77 项全部通过**：本地画廊三栏布局与操作、工具栏、上一项历史栏居中及 Agent 停靠时的拖窗检查。证据 `regression.log`。
- 已检查修改前后浅色页头及修改后深色实绘，裁片为同目录 `header-before.png`、`header-after.png`、`header-after-dark.png`。全部是合成数据组件截图。
- 浅色整页像素比较：62px 页头以下完全一致；页头除左侧标题／加号外，搜索框自动轮播提示文字有变化，位置 `(449,25)–(592,38)`，没有扩大视觉排除范围。完整结果见 `pixel-comparison.json`。
- 范围分析、格式与差异检查分别见 `analyze.log`、`checks.log`。

未操作安装程序、用户图库、草稿或索引，原有未提交 `pubspec.lock` 和 `.runs/` 保留。
