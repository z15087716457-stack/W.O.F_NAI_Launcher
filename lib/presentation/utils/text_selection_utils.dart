import 'package:flutter/material.dart';

/// 文本选择工具类
///
/// 提供 TextEditingController 的选中文本相关操作
class TextSelectionUtils {
  TextSelectionUtils._();

  static const Map<String, ({String open, String close})> _wrapPairs = {
    '(': (open: '(', close: ')'),
    ')': (open: '(', close: ')'),
    '[': (open: '[', close: ']'),
    ']': (open: '[', close: ']'),
    '{': (open: '{', close: '}'),
    '}': (open: '{', close: '}'),
  };

  /// 获取当前选中的文本
  ///
  /// 如果没有选中文本，返回空字符串
  ///
  /// 参数:
  /// - [controller]: 文本编辑控制器
  ///
  /// 返回:
  /// - 选中的文本内容，如果没有选中则返回空字符串
  static String getSelectedText(TextEditingController controller) {
    final selection = controller.selection;
    if (selection.start == selection.end) {
      return '';
    }
    return controller.text.substring(selection.start, selection.end);
  }

  /// 检查是否有选中的文本
  ///
  /// 参数:
  /// - [controller]: 文本编辑控制器
  ///
  /// 返回:
  /// - 如果有选中的文本返回 true，否则返回 false
  static bool hasSelection(TextEditingController controller) {
    final selection = controller.selection;
    return selection.start != selection.end;
  }

  /// 将当前选区包裹为成对括号，并保留包裹后的选区。
  static TextEditingValue wrapSelection(
    TextEditingValue value, {
    required String open,
    required String close,
  }) {
    final selection = value.selection;
    if (!selection.isValid || selection.isCollapsed) {
      return value;
    }

    final start = selection.start;
    final end = selection.end;
    if (start < 0 || end > value.text.length || start >= end) {
      return value;
    }

    final selectedText = value.text.substring(start, end);
    final wrappedText = value.text.replaceRange(
      start,
      end,
      '$open$selectedText$close',
    );
    final wrappedEnd = start + open.length + selectedText.length + close.length;

    return value.copyWith(
      text: wrappedText,
      selection: TextSelection(baseOffset: start, extentOffset: wrappedEnd),
      composing: TextRange.empty,
    );
  }

  /// 检测“选区被单个括号字符替换”的输入，并自动转换为包裹选区。
  static TextEditingValue wrapSelectionOnBracketReplacement(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_hasActiveComposingRange(oldValue) ||
        _hasActiveComposingRange(newValue)) {
      return newValue;
    }

    final oldSelection = oldValue.selection;
    if (!oldSelection.isValid || oldSelection.isCollapsed) {
      return newValue;
    }

    final start = oldSelection.start;
    final end = oldSelection.end;
    if (start < 0 || end > oldValue.text.length || start >= end) {
      return newValue;
    }

    final selectedLength = end - start;
    final expectedLength = oldValue.text.length - selectedLength + 1;
    if (newValue.text.length != expectedLength ||
        start >= newValue.text.length) {
      return newValue;
    }

    final insertedChar = newValue.text.substring(start, start + 1);
    final wrapPair = _wrapPairs[insertedChar];
    if (wrapPair == null) {
      return newValue;
    }

    final replacedText = oldValue.text.replaceRange(start, end, insertedChar);
    if (replacedText != newValue.text) {
      return newValue;
    }

    return wrapSelection(oldValue, open: wrapPair.open, close: wrapPair.close);
  }

  static bool _hasActiveComposingRange(TextEditingValue value) {
    final composing = value.composing;
    return composing.isValid && !composing.isCollapsed;
  }
}
