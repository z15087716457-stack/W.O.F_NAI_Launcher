import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/atom_document.dart';
import '../../../widgets/common/inset_shadow_container.dart';
import '../../../widgets/common/dashed_rounded_border.dart';
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
    this.embedded = false,
  });

  final AtomListEditorController controller;

  /// 编辑区固定高度；内部滚动。
  final double height;

  /// 由外层输入框提供边框和高度时，只渲染内部编辑内容。
  final bool embedded;

  @override
  State<AtomListEditor> createState() => _AtomListEditorState();
}

class _AtomListEditorState extends State<AtomListEditor> {
  static const _atomBottomGap = EdgeInsets.only(bottom: 5);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;
    final content = ListenableBuilder(
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
                // EditableText 默认 forceStrutHeight 锁单行高，
                // 多行 WidgetSpan 会溢出槽位与下文交叠；关 strut
                // 让 placeholder 高度生效（纯文本行距仍由
                // style.height 决定）。
                strutStyle: StrutStyle.disabled,
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
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 6),
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
    );
    if (widget.embedded) return content;
    return SizedBox(
      height: widget.height,
      child: InsetShadowContainer(borderRadius: 8, child: content),
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
        alignment: PlaceholderAlignment.top,
        child: Padding(
          padding: _atomBottomGap,
          child: GestureDetector(
            key: Key('atom-editor-orphan-$occurrence'),
            onTap: () => widget.controller.removeOrphanMarker(marker),
            child: AtomChip(
              text: context.l10n.promptBlockLibrary_atomOrphan,
              theme: theme,
              borderColor: theme.colorScheme.error,
            ),
          ),
        ),
      );
    }
    return WidgetSpan(
      // top 对齐：行高由 chip 占位撑开，贴行顶零偏移；
      // middle 会把多行 chip 上移半个 descent（「跳一根」的成因）。
      alignment: PlaceholderAlignment.top,
      child: Padding(
        // 把留白算入占位高度：相邻两行各自的描边不会再贴在一起。
        padding: _atomBottomGap,
        child: Tooltip(
          message: context.l10n.promptBlockLibrary_atomRestoreHint,
          waitDuration: const Duration(milliseconds: 500),
          child: GestureDetector(
            key: Key('atom-editor-atom-${marker.codeUnitAt(0)}-$occurrence'),
            onTap: () => widget.controller.unAtom(marker, occurrence),
            child: AtomChip(text: atomText, theme: theme),
          ),
        ),
      ),
    );
  }
}

/// 紧凑描边 chip：无图标、无内部填充色，描边跟主题色。
/// 编辑器内联使用；详情面板正文原子化渲染同件复用。
///
/// 折行语义（静拍板·多层换行）：长原子文本超过可用宽度时，
/// chip 内部按 [TextPainter] 预折行渲染成**一列逐行小框**——
/// 每行一个真 widget（自带描边），行间留白；行框开口处的蓝色
/// 虚线提示「这是一个换行过的块」。
/// 一个原子仍是一个 [WidgetSpan] 占位，编辑语义零改动。
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

  /// 缺省 = bodyMedium/1.35（编辑器内联度量）；展示场景可传更小样式。
  final TextStyle? textStyle;

  static const double _radius = 5;

  /// 行框之间保留空白，避免连接线看起来越过上下框边。
  static const double _seamGap = 6;
  static const EdgeInsets _pad = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 2,
  );

  /// 行框给文字的富余宽：RenderParagraph 对行宽有 ceil 取整，
  /// 槽宽恰等于 advance 时会误判 hasVisualOverflow 把末字形
  /// overhang 啃掉；留 4px 槽余量 + overflow.visible 兜底。
  static const double _textSlack = 4;

  @override
  Widget build(BuildContext context) {
    final style =
        textStyle ?? theme.textTheme.bodyMedium?.copyWith(height: 1.35);
    final color = borderColor ?? theme.colorScheme.outlineVariant;
    // 蓝色只标记折行产生的开口；显式错误描边（孤儿原子）仍保持红色。
    final breakColor =
        borderColor ?? theme.colorScheme.primary.withValues(alpha: 0.8);
    return LayoutBuilder(
      builder: (context, constraints) {
        // WidgetSpan 子树拿 BoxConstraints(maxWidth: 段落宽)、不限高：
        // maxWidth 即文本区可用宽，扣掉内边距就是折行宽。
        // 无界场景（理论上）退化为单行 chip。
        final maxW = constraints.maxWidth;
        final wrapWidth = maxW.isFinite
            ? maxW - _pad.horizontal - 4
            : double.infinity;
        final segs = _wrapSegments(context, style, wrapWidth);

        if (segs.length <= 1) {
          return _lineBox(
            context,
            style,
            color,
            segs.first,
            topRounded: true,
            bottomRounded: true,
            solidLeft: true,
            solidRight: true,
          );
        }
        // 逐行小框：横边恒实；首行左竖边实、末行右竖边实，
        // 其余竖边是蓝色虚线。行间只留空白，不再绘制额外连接线。
        final children = <Widget>[];
        for (var i = 0; i < segs.length; i++) {
          if (i > 0) {
            children.add(const SizedBox(height: _seamGap));
          }
          children.add(
            _lineBox(
              context,
              style,
              color,
              segs[i],
              breakColor: breakColor,
              topRounded: i == 0,
              bottomRounded: i == segs.length - 1,
              solidLeft: i == 0,
              solidRight: i == segs.length - 1,
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }

  /// 预折行：返回每视觉行的文本段与整行框宽（文本宽+水平内边距）。
  List<_Seg> _wrapSegments(
    BuildContext context,
    TextStyle? style,
    double wrapWidth,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: wrapWidth.isFinite ? wrapWidth : 1e9);

    final segs = <_Seg>[];
    var start = 0;
    while (start < text.length) {
      final range = tp.getLineBoundary(TextPosition(offset: start));
      var end = range.end;
      if (end <= start) end = start + 1; // 防死循环
      var segText = text.substring(start, end);
      // 行尾空白不渲染（折点空白吃掉，拼接不靠它）。
      segText = segText.trimRight();
      if (segText.isNotEmpty) {
        final w =
            _measure(context, style, segText) + _pad.horizontal + _textSlack;
        segs.add(_Seg(segText, w));
      }
      start = end;
    }
    if (segs.isEmpty) {
      segs.add(
        _Seg(
          text,
          _measure(context, style, text) + _pad.horizontal + _textSlack,
        ),
      );
    }
    return segs;
  }

  double _measure(BuildContext context, TextStyle? style, String s) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  /// 单行框：自绘描边（静拍板·实线只留首尾）。横边恒实线；
  /// 首行左竖边实、末行右竖边实（「起点/终点」），其余竖边
  /// 全虚线；四角在相邻两边都实时画圆弧，否则直角。border
  /// 画在文字上层，overhang 墨迹被描边遮住，视觉「线在字外」。
  Widget _lineBox(
    BuildContext context,
    TextStyle? style,
    Color color,
    _Seg seg, {
    Color? breakColor,
    required bool topRounded,
    required bool bottomRounded,
    required bool solidLeft,
    required bool solidRight,
  }) {
    const r = Radius.circular(_radius);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: seg.width,
      // CustomPaint 必须包在 Padding 外：描边按 child 尺寸画，
      // 放内层会把 padding 画到框外、文字贴边。
      child: CustomPaint(
        foregroundPainter: DashedRoundedBorderPainter(
          color: color,
          dashedColor: breakColor ?? color,
          radius: r,
          topRounded: topRounded,
          bottomRounded: bottomRounded,
          solidLeft: solidLeft,
          solidRight: solidRight,
        ),
        child: Padding(
          padding: _pad,
          child: Text(
            seg.text,
            style: style,
            softWrap: false,
            // 槽已留余量，溢出=墨迹 overhang 允许画到 padding 区。
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }
}

/// 行框描边（静拍板·实线只留首尾）：横边恒实线；左右竖边
/// 由 [solidLeft]/[solidRight] 决定实线或虚线。四角仅当
/// 相邻两边都是实线时画 [radius] 圆弧（虚线边不能转弧，
/// 落直角）。普通描边 1px，折行虚线 1.5px；线心以 0.5 偏移。

/// 一行文本段 + 它的行框宽。
class _Seg {
  const _Seg(this.text, this.width);
  final String text;
  final double width;
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
