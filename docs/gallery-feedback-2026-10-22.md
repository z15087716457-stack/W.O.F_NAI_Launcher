# 本地画廊五项修正 · 2026-10-22

用户先集中登记问题，再明确说“动手”后统一实施。有效源码为 `.devin/wt/ui-integration` 的 `codex/uiux-integration`。本批已随 [r36 累计更新](cumulative-preview-r36-2026-10-22.md) 安装到原桌面入口，内部版本 `2.0.0-preview+40`。

## 最终行为

1. **悬停提示**：`ShortcutTooltip` 的富文本与快捷键徽章继承 Tooltip 实际解析的文字样式。移除写死的白色文字与白色徽章底；明暗主题及局部 TooltipTheme 覆盖都保持正确的前景／背景配对。
2. **日期范围**：筛选按钮使用 `MenuAnchor`，日历在按钮下方 6px 展开，不添加页面灰幕。选择、确认、清除、取消、Esc 和点击外部关闭有效。日历给六行日期网格明确高度，独立滚动控制，短窗口可滚动查看。Ctrl+G 日期跳转没有可见锚点，继续使用复用同一日历内容的对话框。
3. **放入画布**：图库右键菜单中紧接“导入图片元数据”，在“在文件夹中显示”之前。图生图与图库共用 `ImageWorkflowLauncher.placeOnCanvas`：使用原始字节登记、按完整字节复用现有图块、选中并发起新的对焦请求。图库入口随后跳转主生图页；不修改提示词、草稿或源图文件，不自动保存图库。生成中菜单禁用，读文件之后再次检查生成状态。
4. **展开栏排版**：版本变体与日期分组共用 `GalleryChoiceMenuItem`，行高 34px、左右内边距 10px、勾选列 16px、勾与文字间距 8px，菜单上下内边距 4px。未选中项和选中项的文字起点一致。
5. **未分类归档**：默认保存入口统一写入 `<图库根>/Uncategorized/`，保持原有原子防冲突、PNG 字节／元数据及失败清理行为。跨日期使用同一目录，重名追加序号。去重优先查未分类，再兼容当日旧日期目录。分类首次加载补充默认目录；侧栏显示本地化“未分类文件夹”与现有 `StudioIcons.galleryArchive`，面包屑、搜索范围与分类选择框使用同一名称。默认入口不提供重命名／删除／创建子分类操作，可接收图片移入。

**历史数据范围**：本批不迁移旧目录或旧图片。原先仅用于展示的“日期文件夹”虚拟分组移除，原日期目录作为普通分类继续访问，分类 ID、路径和图片不变；后续新生成／补存图片不再创建日期子目录。

## 验证与证据

- 登记 SDK：Flutter 3.47.7 / Dart 3.13.5。繁体资源与 l10n 已重新生成，业务代码生成成功。
- 受影响路径合并回归 **346 项全部通过**：图库控件与实际三栏页面、分类仓库及 UUID／加载竞态、原子保存与旧路径去重、图像生成 provider、共享工作流、图生图面板、画布接线与保存、图片卡片、快捷键提示。
- 深浅主题 × 简中／繁中／英语／日语／韩语验证日期定位、确认、清除、Esc 和外部关闭；版本／分组菜单验证实际行高与文字起点。提示正文与快捷键对比度均至少 4.5:1，并覆盖自定义 TooltipTheme。
- 实际图库右键操作验证原图进入画布、保留原字节、预览选择／对焦请求和跳转主页面；共享功能验证重复导入复用同一图块，每次点击仍重新对焦，不改当前草稿。
- 临时目录验证跨日期与并发保存落在同一目录、同名不覆盖、字节一致，历史文件和分类 ID 保留。使用合成图片与隔离存储，没有实调用 NAI。
- 全仓 `flutter analyze --no-pub lib test` 无问题；`git diff --check` 通过。原有 `pubspec.lock` 改动保持原哈希，`.runs/` 未纳入本批。

日志与 78 张真实字体截图位于 `.dart_tool/gallery-feedback-20261022/`，主要记录为 `regression-final.log`、`analyze-final.log`、`codegen-final.log`、`l10n.log`。截图覆盖 30 个日期／菜单主题语言场景、2 个提示场景与图库三栏及菜单场景；未改写旧 golden 基准。

实绘：[日期范围](../.dart_tool/gallery-feedback-20261022/captures/date-zh-light.png)、[深色日历](../.dart_tool/gallery-feedback-20261022/captures/date-en-dark.png)、[变体菜单](../.dart_tool/gallery-feedback-20261022/captures/variant-zh-light.png)、[分组菜单](../.dart_tool/gallery-feedback-20261022/captures/group-en-light.png)、[快捷键提示](../.dart_tool/gallery-feedback-20261022/captures/tooltip-light.png)、[未分类入口](../.dart_tool/gallery-feedback-20261022/captures/zh-light-wide-header.png)、[放入画布](../.dart_tool/gallery-feedback-20261022/captures/canvas-context-action.png)。

原始用户截图与需求见工作区 [本批待办](../../../../04_工具/开发计划/待办清单.md)。桌面安装以工作区当前接手说明和正式安装收据为准，本批已完成构建与本机安装，未自动启动或推送 GitHub。
