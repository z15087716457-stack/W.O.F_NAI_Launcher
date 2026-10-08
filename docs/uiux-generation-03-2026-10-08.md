# 生图03 · 参考图模块交付（2026-10-08）

主生图左栏和探索编辑列通过 `ReferenceModuleScope` 将图生图、风格迁移和精准参考嵌入一个模块。默认外壳仍是原玻璃卡，窄窗 ParameterPanel 和 toolOnly 不启用作用域。模型能力判断、上传拖放、清除、放入画布、导出菜单、参考库和展开内容沿用原实现。

嵌入行高 46，标题和说明同一行；每个可见面板自己拥有顶部分隔线。模糊只作用在收起行的原图，2.4px、180px cover 和 62%→68% 遮罩保留，高对比不模糊。展开 200ms；前景与按钮保持清晰。352 左栏图生图采用紧凑按钮；精准参考保存入口改为原型 save2 路径，保留原操作。图标提取器也读取 HTML 中追加的 `P.name=...` 定义。

## 验证

- README 列出的六个组件测试文件加 reference_module_test：32 通过，0 失败（`.dart_tool/uiux-task03/test.log`）。默认玻璃、窄窗、工具入口原测试通过。
- reference_module_test 检查 V5/V5 Curated 1 行、V4.5 3 行、V4/V3 2 行及精确高度；按钮不触发展开；清除有效；前景不受模糊；展开后和高对比下无模糊。
- `flutter analyze --no-pub lib/presentation/widgets/common lib/presentation/screens/generation lib/presentation/screens/style_explore test/presentation/screens/generation/widgets/reference_module_test.dart`：No issues found。
- `CAPTURE_UIUX_REFERENCE=1 flutter test --no-pub test/presentation/screens/generation/widgets/reference_module_test.dart --reporter expanded`：3 通过；80 张原字体 widget 实绘：V5/V4.5、无图/风格迁移带图收起/图生图展开（V5 无风格迁移）、352/420、zh/en/ja/ko、浅/深。
- `.dart_tool/uiux-task03/comparison/index.html` 提供四组原尺寸并排及 50% 叠加；prototype-states.json 记录四个 HTML 状态、46px 行高、86/178px 模块高度。原型全页 PNG 复用任务02相同状态原截图，裁剪前重新在浏览器核对各状态模型、主题、字体和区域。
- gen-l10n 通过。唯一新增短标签 `generation_referenceUpload` 按 HTML「上传」给出五语言；默认卡保留原“上传图片”。提交本地化仅包含该键，不包含其他会话的 Agent 文案。

## 与 HTML 的有依据差异

1. 任务03明确图标 20px、箭头 18px（HTML 18/15）；任务01明确模块标题 w600、圆角6（HTML w700/8）。
2. 任务03明确保留导出按钮、动作→trailing→badge 顺序（HTML 没显示导出，badge 在名称后）。导出嵌入态收紧为28px，菜单与处理不变，46px行高不再被撑大。
3. 任务03明确复用 img2img_subtitle，故为现有“基于底图生成变体”（HTML“基于原图生成变体”）。沿用 `_CollapsedBackgroundImage` 的 180px cover，而 HTML 另有1.04缩放。
4. 已禁用的保存操作显示禁用色，遵循现有 hasReferences 条件；HTML静态模型未表达可用性。展开内容、其他语言和窄宽度在 HTML 没有示例，按任务要求保留行为并验证布局。

这只是施工验证，检查点②仍待独立审查和用户实机验收。未构建、安装、启动、重启或热重载 Studio；未调用 NovelAI。
