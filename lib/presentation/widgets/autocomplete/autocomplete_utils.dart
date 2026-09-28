import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Shared caret positioning for autocomplete fields.
class AutocompleteUtils {
  AutocompleteUtils._();

  /// 判断实际文本输入组件是否支持多行。
  static bool isMultilineTextInput({
    required BuildContext context,
    int? maxLines,
    bool expands = false,
  }) {
    final renderEditable = _findRenderEditable(context);
    if (renderEditable != null) {
      return renderEditable.maxLines != 1;
    }
    return expands || (maxLines ?? 1) > 1;
  }

  static double getPreferredLineHeight({
    required BuildContext context,
    TextStyle? textStyle,
  }) {
    final renderEditable = _findRenderEditable(context);
    if (renderEditable != null) return renderEditable.preferredLineHeight;
    final effectiveStyle = textStyle ?? DefaultTextStyle.of(context).style;
    return (effectiveStyle.fontSize ?? 14) * (effectiveStyle.height ?? 1.2);
  }

  /// 计算光标在文本框内的位置
  /// 用于多行文本框的浮层定位
  static Offset getCursorOffset({
    required BuildContext context,
    required TextEditingController controller,
    required TextStyle? textStyle,
    required EdgeInsetsGeometry? contentPadding,
    int? maxLines,
    bool expands = false,
  }) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;

    final cursorPosition = controller.selection.baseOffset;
    if (cursorPosition < 0) {
      return Offset.zero;
    }

    // 尝试找到 RenderEditable 以获取精确的光标位置
    final renderEditable = _findRenderEditable(context);

    if (renderEditable != null) {
      // 使用 RenderEditable 获取精确的光标位置
      final caretRect = renderEditable.getLocalRectForCaret(
        TextPosition(offset: cursorPosition),
      );

      // 获取 RenderEditable 相对于 renderBox 的位置
      final editableBox = renderEditable;
      final editableOffset = editableBox.localToGlobal(
        Offset.zero,
        ancestor: renderBox,
      );

      final lineHeight = renderEditable.preferredLineHeight;

      // 返回光标位置（在光标下方显示补全框）
      return Offset(
        editableOffset.dx + caretRect.left,
        editableOffset.dy + caretRect.top + lineHeight,
      );
    }

    // Fallback: 使用 TextPainter 估算位置
    final text = controller.text;
    if (text.isEmpty) {
      return Offset.zero;
    }

    final effectiveStyle = textStyle ?? DefaultTextStyle.of(context).style;
    final horizontalPadding = contentPadding is EdgeInsets
        ? contentPadding.left + contentPadding.right
        : 24.0;
    final leftPadding = contentPadding is EdgeInsets
        ? contentPadding.left
        : 12.0;
    final topPadding = contentPadding is EdgeInsets ? contentPadding.top : 12.0;
    final bottomPadding = contentPadding is EdgeInsets
        ? contentPadding.bottom
        : 12.0;

    final availableWidth = renderBox.size.width - horizontalPadding;

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: effectiveStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: availableWidth);

    final cursorOffset = textPainter.getOffsetForCaret(
      TextPosition(offset: cursorPosition.clamp(0, text.length)),
      Rect.zero,
    );

    final lineHeight = textPainter.preferredLineHeight;
    final visibleHeight = renderBox.size.height - topPadding - bottomPadding;

    // 估算滚动偏移
    double scrollOffset = 0;
    if (cursorOffset.dy > visibleHeight - lineHeight) {
      scrollOffset = cursorOffset.dy - visibleHeight + lineHeight;
    }

    final visibleCursorY = (cursorOffset.dy - scrollOffset).clamp(
      0.0,
      visibleHeight - lineHeight,
    );

    return Offset(
      leftPadding + cursorOffset.dx,
      topPadding + visibleCursorY + lineHeight,
    );
  }

  static RenderEditable? _findRenderEditable(BuildContext context) {
    RenderEditable? result;

    void visit(Element element) {
      if (result != null) return;
      final renderObject = element.renderObject;
      if (renderObject is RenderEditable) {
        result = renderObject;
        return;
      }
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
    return result;
  }
}
