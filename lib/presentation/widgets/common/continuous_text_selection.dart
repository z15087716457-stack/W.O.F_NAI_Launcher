import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    final selection = editable.selection;
    if (!editable.hasFocus || selection == null || selection.isCollapsed) {
      return;
    }
    final boxes = editable.getBoxesForSelection(selection);
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
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(path, Paint()..color = _color);
    canvas.restore();
  }
}
