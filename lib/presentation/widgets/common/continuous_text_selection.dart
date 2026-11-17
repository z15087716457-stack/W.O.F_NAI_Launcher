import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../utils/text_editing_projection.dart';

/// A source highlight whose fill follows the editor's source-line boxes, rather
/// than the paragraph height reserved for annotations. Padding stays unpainted.
class TextLineBackgroundSpan extends TextSpan {
  TextLineBackgroundSpan({
    required this.backgroundColor,
    this.horizontalInset = 0,
    TextStyle? style,
    super.text,
    super.children,
  }) : super(style: style?.copyWith(backgroundColor: Colors.transparent));

  final Color backgroundColor;
  final double horizontalInset;

  @override
  RenderComparison compareTo(InlineSpan other) {
    final comparison = super.compareTo(other);
    return other is TextLineBackgroundSpan &&
            (backgroundColor != other.backgroundColor ||
                horizontalInset != other.horizontalInset) &&
            comparison.index < RenderComparison.paint.index
        ? RenderComparison.paint
        : comparison;
  }

  @override
  bool operator ==(Object other) =>
      other is TextLineBackgroundSpan &&
      super == other &&
      backgroundColor == other.backgroundColor &&
      horizontalInset == other.horizontalInset;

  @override
  int get hashCode =>
      Object.hash(super.hashCode, backgroundColor, horizontalInset);
}

/// Paints multiline selection as one shape so fractional line edges don't
/// leave hairlines between the highlight boxes.
class ContinuousTextSelection extends StatelessWidget {
  const ContinuousTextSelection({super.key, required this.child});

  final TextField child;

  @override
  Widget build(BuildContext context) {
    final selectionStyle = DefaultSelectionStyle.of(context);
    // Inline editors can be inside another field's WidgetSpan.
    final inheritedColor = selectionStyle.selectionColor == Colors.transparent
        ? context.dependOnInheritedWidgetOfExactType<_SelectionColor>()?.color
        : null;
    final color = inheritedColor ?? selectionStyle.selectionColor;
    if (color == null) return child;
    return _SelectionColor(
      color: color,
      child: DefaultSelectionStyle(
        cursorColor: selectionStyle.cursorColor,
        mouseCursor: selectionStyle.mouseCursor,
        selectionColor: Colors.transparent,
        child: _SelectionPaintHost(color: color, child: child),
      ),
    );
  }
}

class _SelectionColor extends InheritedWidget {
  const _SelectionColor({required this.color, required super.child});

  final Color color;

  @override
  bool updateShouldNotify(_SelectionColor oldWidget) =>
      color != oldWidget.color;
}

class _SelectionPaintHost extends SingleChildRenderObjectWidget {
  const _SelectionPaintHost({required this.color, required super.child});

  final Color color;

  @override
  _RenderSelectionPaintHost createRenderObject(BuildContext context) =>
      _RenderSelectionPaintHost(color);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSelectionPaintHost renderObject,
  ) {
    renderObject.painter.color = color;
  }
}

class _RenderSelectionPaintHost extends RenderProxyBox {
  _RenderSelectionPaintHost(Color color) : painter = _SelectionPainter(color);

  final _SelectionPainter painter;

  @override
  void performLayout() {
    // TextField owns the editor; attach to its native painter so selection
    // geometry, scrolling, and clipping all use the same layout as the text.
    void attachPainter(RenderObject node) {
      if (node is RenderEditable) {
        node.painter = painter;
        return;
      }
      node.visitChildren(attachPainter);
    }

    if (child case final field?) attachPainter(field);
    super.performLayout();
  }

  @override
  void dispose() {
    painter.dispose();
    super.dispose();
  }
}

class _SelectionPainter extends RenderEditablePainter {
  _SelectionPainter(this._color);

  static final _sourceRuns = RegExp(r'[^\r\n]+');

  Color _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    notifyListeners();
  }

  @override
  bool shouldRepaint(RenderEditablePainter? oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size size, RenderEditable editable) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    var offset = 0;
    final backgrounds = <Color, Path>{};
    final plainText = editable.text?.toPlainText() ?? '';
    bool padding(int index) =>
        plainText[index].trim().isEmpty || plainText[index] == '\u2060';
    void paintBackground(InlineSpan span) {
      if (span is TextLineBackgroundSpan) {
        // Newlines have no glyph; their selection boxes include trailing and
        // empty-line space that must not inherit an unfinished weight's fill.
        for (final run in _sourceRuns.allMatches(span.toPlainText())) {
          final range = TextSelection(
            baseOffset: offset + run.start,
            extentOffset: offset + run.end,
          );
          for (final box in editable.getBoxesForSelection(range)) {
            final position = editable.getPositionForPoint(
              editable.localToGlobal(
                Offset(box.left, (box.top + box.bottom) / 2),
              ),
            );
            final line = editable.getLineAtOffset(position);
            var start = math.max(range.start, line.start);
            var end = math.min(range.end, line.end);
            while (start < end && padding(start)) {
              start++;
            }
            while (end > start && padding(end - 1)) {
              end--;
            }
            if (start == end) continue;
            final first =
                editable
                    .getLocalRectForCaret(TextPosition(offset: start))
                    .left -
                editable.cursorOffset.dx;
            final last =
                editable
                    .getLocalRectForCaret(
                      TextPosition(
                        offset: end,
                        affinity: TextAffinity.upstream,
                      ),
                    )
                    .left -
                editable.cursorOffset.dx;
            // Native selection may extend to the paragraph edge or include an
            // annotation's reserve. Clip fills to this run's source glyphs.
            final rect = Rect.fromLTRB(
              math.max(box.left, math.min(first, last)) + span.horizontalInset,
              box.top,
              math.min(box.right, math.max(first, last)) - span.horizontalInset,
              box.bottom,
            );
            if (!rect.isEmpty) {
              (backgrounds[span.backgroundColor] ??= Path()).addRect(rect);
            }
          }
        }
      }
      if (span is TextSpan) {
        offset += span.text?.length ?? 0;
        for (final child in span.children ?? const <InlineSpan>[]) {
          paintBackground(child);
        }
      } else {
        offset += span.toPlainText().length;
      }
    }

    if (editable.text case final text?) paintBackground(text);
    // One fill per color joins fractional span edges without translucent seams.
    for (final entry in backgrounds.entries) {
      canvas.drawPath(entry.value, Paint()..color = entry.key);
    }
    _paintSelection(canvas, editable);
    canvas.restore();
  }

  void _paintSelection(Canvas canvas, RenderEditable editable) {
    final selection = editable.selection;
    if (!editable.hasFocus || selection == null || selection.isCollapsed) {
      return;
    }
    final spans = editable.text;
    final ranges = spans is SourceMappedTextSpan
        ? spans.projection.sourceRanges
        : [TextRange(start: 0, end: editable.text!.toPlainText().length)];
    final boxes = [
      for (final range in ranges)
        if (range.start < selection.end && range.end > selection.start)
          ...editable.getBoxesForSelection(
            TextSelection(
              baseOffset: math.max(range.start, selection.start),
              extentOffset: math.min(range.end, selection.end),
            ),
          ),
    ];
    if (boxes.isEmpty) return;
    final top = boxes.first.top;
    final bottom = boxes.last.bottom;
    final path = Path();
    for (final box in boxes) {
      // Cover SkParagraph's subpixel rounding at inner row edges. A single
      // filled path applies the translucent color once where boxes overlap.
      path.addRect(
        Rect.fromLTRB(
          box.left,
          math.max(top, box.top - .5),
          box.right,
          math.min(bottom, box.bottom + .5),
        ),
      );
    }
    canvas.drawPath(path, Paint()..color = _color);
  }
}
