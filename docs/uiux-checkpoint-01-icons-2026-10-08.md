# 检查点① · 按最终要求对齐原型图标

日期：2026-10-08。此补充基于生图01 `16a5a00d` 和块01 `be90a7c8`，对应用户在本窗口的最新指示：以任务文字和 HTML 原型为准；已有原型替代的图标全部采用，不设自创图标保留例外。先前保留 DNA 或翻译动画的口头约定作废。检查点由用户在其他 Agent 工具审查，本窗口提供交接包并等待结果。

## 最终实现

- `UiuxPrototypeIcon` 直接渲染原型的 SVG path，24px 网格、圆端 / 圆连接，沿用原型的 1.8 / 2 / 2.2 描边。它保留 IconData 调用接口和已存储的块图标键名，按使用场景选择原型。
- 生图模块标题操作采用生图 HTML 的加号、上传和箭头路径；正文、侧栏、管理页和积木药丸的锁、骰子、顺序、缺失 / 失效图标以及有对应路径的块图标采用块 HTML。
- DNA 使用块原型的 `evo` 双螺旋，不再绘制旧自创字形或播放旧形状的动画。
- 药丸翻译样式使用块 HTML 的「译」字形：HarmonyOS Sans SC、700 字重，12px 图标槽里 10px 字形。其他翻译按钮使用查看器 HTML 的 `tr` 语言 SVG。忙态同样使用原型外观；旧 A 加环绕箭头的绘制与循环动画已删除。请求状态、排队、失败、重试、tooltip 和固定槽位保留。
- 原型里的 `si(...)` 字体引用按原型继续渲染对应字形；不是另外加一条“自创必须保留”的规则。没有对应原型路径的既有图标选项保持键名与语义，待其所属任务结合相应页面 HTML 处理，不改用户已保存的选择。
- active 与六样式的重叠按块 HTML 的 CSS 级联：经典底升为 16%，图案 / 实心 / 翻译各自底覆盖 `.pl.open` 底，均保留 2px / 30% 外圈。翻译图标颜色采用 HTML 的 muted 色，正文仍使用任务规定的主题色和字重。
- 尺寸、操作回调、拖拽数据、实例卡动作、编辑器投影和存储格式没有变化。

HTML 来源：`E:/A.I/NovelAI/.devin/mockups/generation/mock.html`、`blocks/mock.html`、`viewer/mock.html`。生成器为 `tool/uiux/extract_prototype_icons.py`，源码快照为 `lib/presentation/widgets/common/uiux_prototype_icon_paths.dart`。

```bash
python tool/uiux/extract_prototype_icons.py \
  --blocks E:/A.I/NovelAI/.devin/mockups/blocks/mock.html \
  --generation E:/A.I/NovelAI/.devin/mockups/generation/mock.html \
  --viewer E:/A.I/NovelAI/.devin/mockups/viewer/mock.html \
  --output lib/presentation/widgets/common/uiux_prototype_icon_paths.dart
dart format lib/presentation/widgets/common/uiux_prototype_icon_paths.dart
```

已逐项比对：块集合 64 条（63 条块路径及查看器 `tr`），生图集合 30 条，全部与 HTML 字符串一致。证明及来源 SHA256 在 `.dart_tool/uiux-checkpoint01/icon-path-parity.json`。无需新增依赖、字体注册或重新生成 StudioIcons 字体；原型已有字体引用的字形没有重画。

## 最终验证

```bash
CAPTURE_STUDIO_UI=1 flutter test --no-pub \
  test/presentation/widgets/prompt \
  test/presentation/screens/prompt_block_library \
  test/presentation/screens/generation/widgets/block_library_panel_test.dart \
  test/presentation/screens/generation/widgets/generation_module_card_test.dart \
  test/presentation/screens/generation/widgets/parameter_panel_test.dart \
  test/presentation/widgets/common/translation_icon_test.dart \
  test/presentation/widgets/common/uiux_prototype_icon_test.dart \
  --reporter expanded
```

- 379 项通过，0 失败，包含两项任务的完整必跑范围和额外的共用图标 / 翻译状态回归。
- 修改源码目录及所有修改测试的 12 项路径分析：`No issues found`。命令在 `.dart_tool/uiux-checkpoint01/validation-commands.sh`，日志在 `final-analyze.log`。
- `final-test.log` 为最终统一测试日志。初始两个任务的 25 / 324 结果是补充前的记录，最终结果以本文件为准。
- 原来的 48 张真实字体 widget 实绘已重新生成：生图 32 张、块 16 张。包括四语言、浅 / 深、四栏宽、完整药丸规范格、正文四药丸行高对照和真实积木浮窗。截图测试启用正常阴影模糊，返回前恢复 debug 变量。
- 布局和状态测试通过；原型图标不是图片贴图或 Material 近似字形。翻译排队 / 执行 / 失败 / 重试的槽位不变；不同 TextScaler 的文字和图标对齐回归保留。

## 提交与保护

这是检查点①的用户追加要求，不是 Opus 审查结论。对应补充提交与初始两项提交均列于工作区交接包。检查点仍为待外部审查，第二段尚未施工。

未构建、安装、启动、重启或热重载 Studio，未推送；未调用 NovelAI 接口，未改用户草稿、桥接参数或图库数据。起始 73 个已修改跟踪文件再次核对全部保持原 SHA256。
