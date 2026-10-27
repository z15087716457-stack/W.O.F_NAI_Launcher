# 提示词编辑器选区底色修复

2026-10-27。用户反馈主提示词框框选后，部分词块像浮在选区上层。

## 原因与修改

`RenderEditable` 先绘制选区，再绘制文字；`NaiSyntaxController` 的权重、双冒号和别名背景随后覆盖选区。已有 `uiSelectableTint` 修复只用于大图及 Agent，编辑器仍在使用不透明权重底色。修复前，深浅主题的实际输入框像素检查均复现：普通文字能显示蓝色选区，权重文字区域没有选区色。

控制器保留原语法／搜索／药丸缓存，返回显示副本时仅拆分选区相交的文字片段，把选中文字的背景设为透明。未选中文字保留原样，取消选中直接返回原缓存；输入框失焦、Flutter 隐藏选区时也恢复原底色。拖选与反向选区都即时响应，不必重新解析文本或重建内联块。文字和选区值本身仍由原编辑链路维护。

## 验证

- `test/presentation/widgets/prompt/nai_syntax_selection_test.dart`：新增深浅主题实际绘制的像素检查，正反向／跨行／Unicode／局部选区、语法与搜索背景、取消选中的缓存和配色恢复。
- `nai_syntax_controller_pill_test.dart`：新增跨内联块的偏移检查，选区变化沿用同一个 WidgetSpan，构建器只调用一次。
- 提示词组件全目录及生成页编辑器／后端／映射回归 **364 通过、0 失败**。实绘和日志在 `.dart_tool/prompt-selection-before/`、`prompt-selection-after/`、`prompt-selection-before.log`、`prompt-selection-regression.log`。
- 全仓 analyze 及最终修改文件复查均无问题，日志为 `.dart_tool/prompt-selection-analyze.log` 与 `prompt-selection-final-analyze.log`。本轮按共享控制器的影响范围验证，未重跑全仓 Flutter 套件或重新构建累计运行包。

用户已明确暂缓安装。正式程序仍为 +52；先前 r7 的 +53 候选仅含资源小窗两项修复，不含本项，下一次安装前需累计重建。
