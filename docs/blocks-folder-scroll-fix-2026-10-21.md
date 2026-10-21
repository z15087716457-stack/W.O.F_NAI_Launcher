# 块库文件夹分组跨组滚动回跳修正

2026-10-21 用户反馈：向下浏览文件夹分组时突然跳回前面，标题应随内容正常交替。本项在 r33 后完成源码修正，待下次累计安装；桌面仍为 r33。

## 复现与原因

使用合成块库复现：三组分别为 100／37／27 张不同高度卡片，向下滚轮每次 120 像素；第 33 次从 3840 像素回退到 288 像素。少量卡片分组（2／37／3／27）则会卡在前组末尾，滚不到后面。

旧结构为每组 `SliverMainAxisGroup` 内放一个 `SliverMasonryGrid`。已滚出视口的上一组仍会参与布局；当整个瀑布流离开缓存范围后，依赖的 masonry 渲染器会错误发出负向 `scrollOffsetCorrection`，校正向外传到整页。临时诊断中第一组已报告总高 3620，却在本地 scrollOffset 3916、cacheOrigin -244 时要求回退 3672 像素。诊断代码已移除，未改 SDK 或依赖缓存。

## 改动

只在开启文件夹分组的瀑布流里，改用 `SliverCrossAxisGroup` 并排承载多个懒加载 `SliverList`。按缩略图比例和文本自然高度估算最短列，卡片本身仍以自然高度布局；缩略图解码后合并到帧后更新列分配。末尾标题／计数区域约 58 像素只用于分列估算，不固定或裁切卡片高度。

原有 `SliverMainAxisGroup` 和 `PinnedHeaderSliver` 保留，标题仍由下一组推走；非分组瀑布流、网格、列表和业务存储不变。没有把整组卡片一次性构建出来，也没有用滚动控制器强行拉回某个位置。

生产改动在 `lib/presentation/ui/blocks/blocks_wall.dart`；施工前副本为 `.dart_tool/blocks-group-scroll-20261021/blocks_wall.before.dart`。

## 验证

- Flutter 3.47.7 / Dart 3.13.5。
- 新增 `test/presentation/ui/blocks/blocks_grouped_scroll_test.dart`，共 8 个场景：瀑布流／网格／列表，大组／不足一行的短组，横竖比例不同的独立缩略图与文字混排。
- 每次滚轮验证向下位置不回退、向上位置不前跳、吸顶标题按组交替；走到最后一张后再回到顶部，并检查离开视口的卡片已释放。缩略图使用独立 MemoryImage，覆盖缓存解码同步回调和各卡片比例陆续学习。
- 修复前 2 个初始复现场景均失败；`.dart_tool/blocks-group-scroll-before.log`。临时渲染诊断为 `.dart_tool/blocks-group-scroll-20261021/probe.log`。
- 相关 **154 项全部通过**：块库 UI（含原视觉基准和 8 项分组滚动）、块库后端、块库接线、上一项积木跨层拖放；日志 `.dart_tool/blocks-group-scroll-20261021/regression.log`。随后加强为独立缩略图的 8 项专题再次全部通过，日志 `final-focused.log`；不重复累计到 154。
- 修改的生产文件与新增测试 analyze 无问题，`git diff --check` 和格式检查通过；原有未提交 `pubspec.lock` 哈希保持。
- 已查看混合封面分组交替实绘：`.dart_tool/blocks-group-scroll-20261021/captures/group-transition-100.png` 和 `group-transition-2.png`。这是合成数据组件截图，不是用户正在运行的窗口。

本项和积木拖拽预览修正一起待下次本机更新。未构建或安装、未启动／重启／热重载应用，未写用户草稿、文件夹或块库数据。
