# 生图02：图像模块

按方案 A 的完整 index / mock、任务02及入口 U7，将生图左栏和探索编辑列的尺寸 / 数量装进共用模块。窄窗 `ParameterPanel` 和控件默认布局保持；预设数据、模型判断、尺寸校验、计费及生成链没有改动。

- `SizeSection` / `SizeSelector` 新增 `moduleRow`：96–112px 分组、110×32 方向轨道、两只58×32宽高框；窄宽换行靠右，保留预设、自定义聚焦、手动尺寸、交换、回车 / 失焦及既有 Key。
- `ImageCountSection` 新增 `moduleRow`：张数轨道、重复步进同排；探索只显示重复；窄宽换行，合计和生成按钮仍读同一参数。
- 步进器复用 `DraggableNumberInput` 的编辑、拖动、滚轮、1–999与箭头行为，`inline` 外观只在新模块启用。
- 四语言新文案及繁体生成；删除已无生产引用的 `generation_sectionImageSettings`。混合工作树的国际化使用 `tool/uiux/stage_localizations.py` 从HEAD加本任务指定键生成提交版本，不提交其他会话的 Agent 文案。

## 原型与实绘

原型 `generation/mock.html#a / a-dark / a-v45 / a-v45-dark`；浏览器实际主题、模型、字体及1600×1120视口逐项确认，原型只读。证据在 `.dart_tool/uiux-task02/`：

- `captures/`：4语言×2主题×352 /420 /560和320探索，共32张真实字体生产widget实绘。
- `prototype-*.png`、`prototype-states.json`：四份完整原型与DOM状态；`capture-measurements.json`记录实现矩形。
- `comparison/index.html`、`原型与实现对照.png`：4组同场景原尺寸并排及50%叠加。

文字明确的出入：圆角6（HTML8）、标题w600（HTML700）、尺寸行底距8（HTML10）；数量轨道到重复间隔10、重复标签到步进间隔6（HTML分别12 /8），因此轨道按剩余宽度多4px。所有这些按页面 / 任务明确文字执行。HTML没有窄宽换行和探索只留重复的示例，这两项按任务文字并通过实绘 / 交互回归验证；字体抗锯齿差异不视为PNG字节相同。

## 验证

```bash
flutter test --no-pub test/presentation/screens/generation/widgets/size_selector_test.dart test/presentation/screens/generation/widgets/image_count_section_test.dart test/presentation/screens/generation/widgets/sidebar_official_layout_test.dart test/presentation/screens/generation/widgets/parameter_panel_test.dart --reporter expanded
flutter test --no-pub test/l10n --reporter expanded
flutter analyze --no-pub lib/presentation/screens/generation lib/presentation/screens/style_explore lib/presentation/widgets/common/draggable_number_input.dart tool/uiux/generation_image_module_capture_test.dart test/presentation/screens/generation/widgets/size_selector_test.dart test/presentation/screens/generation/widgets/image_count_section_test.dart test/presentation/screens/generation/widgets/sidebar_official_layout_test.dart
CAPTURE_STUDIO_UI=1 flutter test --no-pub tool/uiux/generation_image_module_capture_test.dart --reporter expanded
```

32项组件 / 侧栏 / 参数面板回归通过；捕获任务通过；7路径分析无诊断。含国际化的指定组合结果59通过 /1失败：唯一失败为其他会话既有7个 `naiAgent_*` 无引用键，任务前备份已包含，UIUX新增键无未引用项。没有删除其他会话的键或改它们的代码；完整日志及基线证明在证据目录。探索页5个旧测试的其他会话方法签名编译失败仍沿用复查①记录，未处理。

状态：本任务完成，段2其余任务继续，检查点②尚未审查。没有构建、安装、启动、重启、热重载 Studio、调用 NAI 或写用户数据；未推送。
