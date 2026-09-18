import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/atom_document.dart';
import '../../../widgets/common/inset_shadow_container.dart';
import '../../../widgets/prompt/nai_syntax_controller.dart';

/// 块内原子编辑器（FEAT-79）：单文本流自由编辑。
///
/// 整块正文是一个连续可编辑文本，原子以药丸同款私用区标记字符
/// 嵌在流里渲染为描边 chip——光标随便插、正常打字、退格删原子，
/// 与主提示词框药丸同构。
///
/// - 回车 = 光标**前**的连续文本收成原子，光标**后**留原文
///   （静拍板，不做整段兜底）；
/// - 点击原子 = 标记原位换回原文，光标落文本末尾；
/// - 粘贴 `\n` → 每行各成一个原子，末行留作可编辑原文；
/// - 保存时调用方读 [AtomListEditorController.atoms]：标记取表内
///   原文，连续原文段按序收尾，空白/孤儿标记丢弃。
class AtomListEditor extends StatefulWidget {
  const AtomListEditor({
    super.key,
    required this.controller,
    this.height = 260,
  });

  final AtomListEditorController controller;

  /// 编辑区固定高度；内部滚动。
  final double height;

  @override
  State<AtomListEditor> createState() => _AtomListEditorState();
}

class _AtomListEditorState extends State<AtomListEditor> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;
    return SizedBox(
      height: widget.height,
      child: InsetShadowContainer(
        borderRadius: 8,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            controller.field.pillBuilder = _atomSpanBuilder;
            return Column(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('atom-editor-field'),
                    controller: controller.field,
                    focusNode: controller.focusNode,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    // middle 对齐时行高=chip 高度（行间 0 空隙），
                    // 靠文本行高撑出 chip 行之间的空隙。
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
                    decoration: InputDecoration(
                      // 主题 inputDecorationTheme 全局 filled=true：
                      // 填充色会让底部教程行露出更深的容器底色，
                      // 关掉填充让整框共用内阴影容器背景。
                      filled: false,
                      hintText: context.l10n.promptBlockLibrary_atomInputHint,
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                ),
                // 内框底部右下角操作教程（FEAT-79）
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                      bottom: 6,
                    ),
                    child: Text(
                      context.l10n.promptBlockLibrary_atomEditorTutorial,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 标记字符 → 描边 chip（无填充、点击还原）；
  /// 未知标记（外来粘贴私用区字符）= 墓碑 chip，点击删除字符。
  InlineSpan? _atomSpanBuilder(
    BuildContext context,
    String marker,
    int occurrence,
  ) {
    final theme = Theme.of(context);
    final atomText = widget.controller.atomMap[marker];
    if (atomText == null) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          key: Key('atom-editor-orphan-$occurrence'),
          onTap: () => widget.controller.removeOrphanMarker(marker),
          child: AtomChip(
            text: context.l10n.promptBlockLibrary_atomOrphan,
            theme: theme,
            borderColor: theme.colorScheme.error,
          ),
        ),
      );
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Tooltip(
        message: context.l10n.promptBlockLibrary_atomRestoreHint,
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          key: Key('atom-editor-atom-${marker.codeUnitAt(0)}-$occurrence'),
          onTap: () => widget.controller.unAtom(marker, occurrence),
          child: AtomChip(text: atomText, theme: theme),
        ),
      ),
    );
  }
}

/// 紧凑描边 chip：无图标、无内部填充色，描边跟主题色。
/// 编辑器内联使用；详情面板正文原子化渲染同件复用。
class AtomChip extends StatelessWidget {
  const AtomChip({
    super.key,
    required this.text,
    required this.theme,
    this.borderColor,
    this.textStyle,
  });

  final String text;
  final ThemeData theme;
  final Color? borderColor;

  /// 缺省 = bodyMedium/1.1（编辑器内联度量）；展示场景可传更小样式。
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        text,
        style: textStyle ?? theme.textTheme.bodyMedium?.copyWith(height: 1.1),
      ),
    );
  }
}

/// 编辑器控制器：一个 [NaiSyntaxController] 文本字段 + atoms 表。
/// [initialAtoms] 即初始原子序列（旧块 = atomsOrSplit 预切结果），
/// 播种为标记流；正文后续就是用户自由编辑的单文本。
class AtomListEditorController extends ChangeNotifier {
  AtomListEditorController(List<String> initialAtoms)
    : _document = AtomDocument.fromAtoms(initialAtoms) {
    field = NaiSyntaxController(text: _document.text)
      ..addListener(_handleTextChanged);
    focusNode = FocusNode()..onKeyEvent = _handleKey;
  }

  late final NaiSyntaxController field;
  late final FocusNode focusNode;
  AtomDocument _document;

  /// 当前 atoms 表（标记 → 原文），供 span builder 取文本。
  Map<String, String> get atomMap => _document.atoms;

  /// 底层文档文本（含标记字符）；测试观察用。
  String get documentText => _document.text;

  /// 保存口径：文档顺序扫描，标记→原文，连续原文按序收尾，
  /// 空白段/孤儿标记丢弃。
  List<String> get atoms => AtomDocumentEditor.extractAtoms(_document);

  /// 回车拦截（挂在字段 FocusNode 上，先于 EditableText 换行处理）：
  /// 光标前文本收成原子。IME 组合中不拦截（交给输入法确认）。
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    final composing = field.value.composing;
    if (composing.isValid && !composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    _commitBeforeCaret();
    return KeyEventResult.handled;
  }

  void _commitBeforeCaret() {
    final (doc, caret) = AtomDocumentEditor.commitBeforeCaret(
      _document,
      field.selection.baseOffset,
    );
    if (identical(doc, _document)) return;
    _apply(doc, caret);
  }

  /// 点击原子：该标记的本次出现换回原文，光标落还原处末尾。
  void unAtom(String marker, int occurrence) {
    final (doc, caret) = AtomDocumentEditor.unAtomAt(
      _document,
      marker,
      occurrence,
    );
    if (identical(doc, _document)) return;
    _apply(doc, caret);
  }

  /// 孤儿标记 chip 点击清除（字符连同 atoms 表残留一并清）。
  void removeOrphanMarker(String marker) {
    final text = _document.text.replaceAll(marker, '');
    final atoms = Map<String, String>.of(_document.atoms)..remove(marker);
    _apply(AtomDocument(text: text, atoms: atoms), field.selection.baseOffset);
  }

  /// 文本变化对账：粘贴换行切原子 + 清孤儿标记的表项。
  /// 直接改 field.value 走 controller 通路，撤销栈保持连贯。
  void _handleTextChanged() {
    final value = field.value;
    if (value.text == _document.text) {
      // 纯选区变化不进对账。
      return;
    }
    final (doc, caret) = AtomDocumentEditor.reconcile(
      _document,
      value.text,
      value.selection.baseOffset,
    );
    if (doc.text != value.text) {
      // 发生了换行改写：把规范化文本写回字段。
      _document = doc;
      field.value = value.copyWith(
        text: doc.text,
        selection: TextSelection.collapsed(offset: caret),
        composing: TextRange.empty,
      );
      field.refreshPillSpans();
    } else {
      // atoms 表是否变化（如删除了标记字符）：先比后赋。
      final atomsChanged = doc.atoms.length != _document.atoms.length;
      _document = doc;
      if (atomsChanged) field.refreshPillSpans();
    }
    notifyListeners();
  }

  /// 把新文档写回字段（标记操作统一入口），保持选区有效。
  void _apply(AtomDocument doc, int caret) {
    _document = doc;
    field.value = field.value.copyWith(
      text: doc.text,
      selection: TextSelection.collapsed(
        offset: caret.clamp(0, doc.text.length),
      ),
      composing: TextRange.empty,
    );
    field.refreshPillSpans();
    notifyListeners();
  }

  @override
  void dispose() {
    field.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
