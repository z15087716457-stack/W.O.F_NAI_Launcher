import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/autocomplete/completion_models.dart';
import '../../../core/autocomplete/prompt_token_parser.dart';
import '../../../core/utils/tag_normalizer.dart';
import '../../../data/models/tag/local_tag.dart';
import 'autocomplete_controller.dart';

/// 自动补全工具类
/// 提供标签提取、光标定位、建议应用等公共方法
class AutocompleteUtils {
  AutocompleteUtils._();

  static String getCurrentTag(
    String text,
    int cursorPosition, {
    bool splitOnSpaces = false,
  }) {
    if (cursorPosition < 0 || cursorPosition > text.length) return '';
    final query = PromptTokenParser.parse(
      text: text,
      cursorPosition: cursorPosition,
      limit: 20,
      locale: 'en',
      splitOnSpaces: splitOnSpaces,
    );
    if (query.kind == CompletionQueryKind.libraryAlias) return '';
    final range = query.replacementRange;
    return TagNormalizer.normalize(
      text.substring(range.start, cursorPosition.clamp(range.start, range.end)),
    );
  }

  static (int, int, String) findTagRange(String text, int cursorPosition) {
    if (cursorPosition < 0 || cursorPosition > text.length) return (-1, -1, '');
    final query = PromptTokenParser.parse(
      text: text,
      cursorPosition: cursorPosition,
      limit: 20,
      locale: 'en',
    );
    final range = query.replacementRange;
    final prefix = text.substring(0, range.start);
    final weight = RegExp(
      r'(-?(?:\d+\.?\d*|\.\d+)::)[\s\{\[\(]*$',
    ).firstMatch(prefix)?.group(1);
    return (range.start, range.end, weight ?? '');
  }

  static (String newText, int newCursorPosition) applySuggestion({
    required String text,
    required int cursorPosition,
    required LocalTag suggestion,
    required AutocompleteConfig config,
  }) {
    if (cursorPosition < 0 || cursorPosition > text.length) {
      return (text, cursorPosition);
    }
    final query = PromptTokenParser.parse(
      text: text,
      cursorPosition: cursorPosition,
      limit: config.maxSuggestions ?? 20,
      locale: 'en',
      splitOnSpaces: config.treatSpacesAsSeparators,
    );
    if (query.kind == CompletionQueryKind.libraryAlias) {
      return (text, cursorPosition);
    }
    final result = PromptTokenParser.apply(
      text: text,
      query: query,
      canonicalTag: suggestion.tag,
      autoInsertComma: config.autoInsertComma,
      splitOnSpaces: config.treatSpacesAsSeparators,
      closeOpenWeight: true,
    );
    return (result.text, result.cursorPosition);
  }

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
