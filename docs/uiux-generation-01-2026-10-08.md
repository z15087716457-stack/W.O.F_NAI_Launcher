# UIUX 生图01 · 模块卡片组件交付

> 本文件记录初始任务提交；用户随后更新了图标要求，最终图标、实绘和统一回归见 [检查点①图标补充](uiux-checkpoint-01-icons-2026-10-08.md)。

日期：2026-10-08，Asia/Taipei。施工来源：工作区 `04_工具/UIUX重做/01_生图页-A精修/任务01_模块卡片组件/`，第 1 段的第一项。基线 `af54e9ac`，分支 `devin/gallery-redesign`。

## 交付范围

- `lib/presentation/screens/generation/widgets/generation_module_card.dart`：新增 `GenerationModuleCard`、`GenerationModuleRow`、`ModuleHeaderIconButton` 和类型化的 `SidebarSegment` / `SidebarSegmentTrack`。
- `generation_sidebar_style.dart`：集中定义模块尺寸、字色、数字字体及轨道尺寸；`SidebarSegmentButton` 新增可选高度和圆角，默认保持原来的 28px / 3px。
- `test/presentation/screens/generation/widgets/generation_module_card_test.dart`：16 项组件和真实字体布局测试。

模块标题行 38px，标题 13px / w600，计数徽标 18px，操作按钮 28×28。卡片圆角 6px 并裁切内容。条目自己画 1px 顶部分隔线，最小高度 46px，支持装饰背景和增长的内容；中间隐藏一个面板时没有额外分隔线或空隙。

轨道段高 28px / 22px，外层内边距和段间距均为 2px，可选择按内容宽或等宽展开。数字段使用 Geist Mono 和等宽数字。浅色选中段使用 `surfaceContainer` 和 8% 黑色阴影，深色使用 `surfaceContainerHigh`。禁用段没有回调，前景为 `onSurface` 30%；保留键盘焦点及选中 / 禁用语义。

本任务未套用到 `web_left_panel.dart` 或画风探索页，未改现有提示词卡、角色卡、窄窗参数面板或模型判断。页面替换归后续任务；本任务不新增界面文案和依赖。

## 验证

```bash
CAPTURE_STUDIO_UI=1 flutter test --no-pub \
  test/presentation/screens/generation/widgets/generation_module_card_test.dart \
  test/presentation/screens/generation/widgets/parameter_panel_test.dart \
  --reporter expanded

flutter analyze --no-pub \
  lib/presentation/screens/generation/widgets \
  test/presentation/screens/generation/widgets/generation_module_card_test.dart
```

- 测试：25 项通过、0 失败，包含新组件 16 项和原参数面板 9 项。
- 分析：修改前后均 `No issues found`，范围为整个生图页 widgets 目录；新测试文件也无诊断。
- 实绘：真实 HarmonyOS Sans SC、Geist、Geist Mono、Pretendard 和 MaterialIcons，简中 / 英 / 日 / 韩 × 浅 / 深 × 280 / 352 / 420 / 560px，共 32 张 widget 样例。
- 截图目录：`.dart_tool/uiux-task01/captures/`；单图命名 `<locale>-<light|dark>-<width>.png`，四张 `contact-<locale>.png` 为原尺寸拼接总览。测试和分析日志在 `.dart_tool/uiux-task01/`。
- 已逐张总览检查：长标题在窄宽度下省略，数量和操作仍完整；轨道没有撑高标题行，条目和卡片边界完整。截图展示基础组件及占位内容，不能视为运行中的完整生图页。

## 对照与后续

- 圆角按任务 / 页面规格采用 6px；原型中近似的 8px 不采用。
- 样例只展示组件。角色编辑器、上传 / 导入业务、图像参数排列以及 V5 / V4.5 / V3 的整页差异由后续生图02–04负责，本任务没有提前接线。
- 背景插槽用主题色块演示，后续参考图任务传入原图模糊背景。样例中的数量 32、3 和数字段为合成状态。
- 旧 `SidebarSegmentButton` 的默认高度、圆角和选中色有专门兼容测试；原参数面板测试通过。
- 本轮没有新诊断或未解释的组件偏差；第 1 段的 Opus 5.5 审查须等块01完成后进行，当前不标记检查点通过或用户实机验收。

## 工作区保护

开工时有 127 项既有未提交路径，涉及 Agent、文档、桥接、图库、国际化及生成文件等。已记录基线，73 个既有修改的跟踪文件在本任务结束时 SHA256 全部保持。提交只包含本任务源文件、测试和本记录。

没有启动、重启、热重载 Studio 或构建 / 安装运行包；没有调用 NovelAI 生成 / 编码接口，没有修改用户草稿、提示词、角色框、桥接参数、账号或图库数据。
