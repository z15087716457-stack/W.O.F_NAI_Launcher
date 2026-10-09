/// 跟随主题字体的文本选择工具栏（选中文字后的右键菜单）。
///
/// Flutter 自带的工具栏按钮会绕开主题字体：桌面的
/// [DesktopTextSelectionToolbarButton.text] 使用带 `inherit: false` 的
/// 常量样式，连 [DefaultTextStyle] 都不继承，于是右键菜单永远落到系统默认
/// 字体，用户在设置里选的字体对它无效。
/// [AdaptiveTextSelectionToolbar.buttonItems] 内部正是走这些命名构造，
/// 所以这里改为自己构造按钮，把字体显式补回去。
library;

import 'package:flutter/material.dart';

/// 用主题字体构建文本选择工具栏。
///
/// 容器仍交给 [AdaptiveTextSelectionToolbar] 按平台自适应，只接管按钮。
Widget buildThemedTextSelectionToolbar(
  BuildContext context, {
  required TextSelectionToolbarAnchors anchors,
  required List<ContextMenuButtonItem> buttonItems,
}) {
  return AdaptiveTextSelectionToolbar(
    anchors: anchors,
    children: [
      for (var i = 0; i < buttonItems.length; i++)
        _themedToolbarButton(context, buttonItems[i]),
    ],
  );
}

Widget _themedToolbarButton(BuildContext context, ContextMenuButtonItem item) {
  final label = AdaptiveTextSelectionToolbar.getButtonLabel(context, item);
  // Desktop toolbar defaults bypass the application's typography.
  return DesktopTextSelectionToolbarButton(
    onPressed: item.onPressed,
    child: Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}

/// 供 [EditableText.contextMenuBuilder] 直接使用的默认实现。
Widget themedContextMenuBuilder(
  BuildContext context,
  EditableTextState editableTextState,
) {
  return buildThemedTextSelectionToolbar(
    context,
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: editableTextState.contextMenuButtonItems,
  );
}
