# W.O.F NAI Studio · 界面素材

## 字体角色

| 用途 | 字体 | 字重 / 尺寸 |
|---|---|---|
| 标题栏品牌名 | Geist Pixel **Line** | Regular，20px，标题栏高 40px |
| 启动 / 登录品牌名 | Geist Pixel Line | 32 / 30px |
| 正文与控件 | Geist Sans + HarmonyOS Sans SC fallback | 正文 400，控件 500，分组标题 600 / 700 |
| 参数、尺寸、快捷键、代码 | Geist Mono + HarmonyOS Sans SC fallback | 400 / 500，沿用各控件实际字号 |

Pixel 只用于品牌名，不用于小字按钮、提示词或参数。中文正文使用鸿蒙黑体，混排中的拉丁文与数字自然使用 Geist；数据字段单独用 Mono。`StudioTypography` 定义角色，16 套主题保留原有配色，共用离线字体。HarmonyOS 字体按原始 TTF 完整打包，不裁切、不改写。显式选择的系统 / Google 字体仍有效；旧默认键 `system`、空键映射到应用默认组合。

## 图标

所有应用自行绘制的 `Icon` 控件统一使用 `StudioIcon`。组件保留原始 `IconData`，遵守大小、颜色、禁用透明度、文字方向、无障碍名称；有匹配时绘制 Geist SVG，没有匹配时保留 Material 原图。需要字体阴影或混合效果的调用保留原渲染。画笔光标的底层 TextPainter、Flutter 内建组件和已有 NovelAI 专用 / DNA 图标不改动。

当前使用 150 枚单色 SVG，对应 344 个原图标名称。明确匹配见 `geist_icon_manifest.json`；剩余的性别、调色、比例、抠图等专用符号留待设计。停止操作保留方形符号，不使用上游名为 `stop-fill` 的八角警示牌。

素材来自社区 `jarvis394/geist-icons` 的 `f478dfba63570bccb7efeacd7df82df994064058` 快照，不是 Vercel 官方 Flutter 包。导入时仅把 JSX 数字宽高改为合法 SVG 属性；150 个文件的路径和其余属性逐项与上游核对。来源与许可声明随代码保留。

修改 `import_geist_icons.py` 中的明确语义映射，然后执行：

```sh
python tool/branding/import_geist_icons.py --source <Geist-SVG-directory>
dart format lib/presentation/widgets/common/studio_icon_registry.dart
```

后续自定义图标也从同一注册入口接入，先检查 16 / 20 / 24px、小尺寸留白、选中与未选中状态，再替换。不要仅凭文件名猜测含义。新增资产同步声明 `pubspec.yaml`，删除不用的 SVG 前确认注册表无引用。

## 验证

`studio_visual_system_test.dart` 加载实际字体并绘制完整图标目录，覆盖离线主题、CJK 回退、旧字体选项、SVG 语义 / 透明度 / 尺寸 / RTL 和保留图标。设置 `CAPTURE_STUDIO_UI=1` 可输出到 `.dart_tool/studio-captures/`。

侧栏测试同时设置 `CAPTURE_STUDIO_UI=1 CAPTURE_OFFICIAL_UI=1`，使用实际应用主题与字体绘制 320 / 400px、中英文及悬停状态。素材许可在应用「关于 → 界面字体、图标与许可」可查看。
