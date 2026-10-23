import 'package:flutter/material.dart';

/// 带“撤销”按钮的底部提示。
///
/// Flutter 的 SnackBar 一旦带 action，默认 `persist = true`，会一直留在底部直到被点击。
/// 所有撤销提示都走这里：固定时长、到时自动消退。
SnackBar undoSnackBar({
  required Widget content,
  required String undoLabel,
  required VoidCallback onUndo,
  Duration duration = const Duration(seconds: 4),
}) => SnackBar(
  duration: duration,
  persist: false,
  content: content,
  action: SnackBarAction(label: undoLabel, onPressed: onUndo),
);
