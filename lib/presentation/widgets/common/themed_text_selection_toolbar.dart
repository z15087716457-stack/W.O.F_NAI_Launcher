/// 跟随主题字体的文本选择工具栏（选中文字后的右键菜单）。
///
/// Flutter 自带的工具栏按钮会绕开主题字体：桌面的
/// [DesktopTextSelectionToolbarButton.text] 与 macOS 的
/// [CupertinoDesktopTextSelectionToolbarButton.text] 都使用带 `inherit: false` 的
/// 常量样式，连 [DefaultTextStyle] 都不继承，于是右键菜单永远落到系统默认
/// 字体，用户在设置里选的字体对它无效。
/// [AdaptiveTextSelectionToolbar.buttonItems] 内部正是走这些命名构造，
/// 所以这里改为自己构造按钮，把字体显式补回去。
library;

import 'package:flutter/cupertino.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

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
  // macOS 上容器是 Mac 样式（AdaptiveTextSelectionToolbar 按 Theme.platform 选），按钮跟着用 Mac 的
  if (Theme.of(context).platform == TargetPlatform.macOS) {
    return _MacToolbarButton(label: label, onPressed: item.onPressed);
  }
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

/// Mac 右键菜单的按钮：悬停时强调色底、反白字，字体跟主题。
///
/// [CupertinoDesktopTextSelectionToolbarButton] 自己传 child 时不会跟着悬停换字色，
/// 这里在外面记一次悬停。
class _MacToolbarButton extends StatefulWidget {
  const _MacToolbarButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  State<_MacToolbarButton> createState() => _MacToolbarButtonState();
}

class _MacToolbarButtonState extends State<_MacToolbarButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: CupertinoDesktopTextSelectionToolbarButton(
        onPressed: widget.onPressed,
        child: Text(
          widget.label,
          overflow: TextOverflow.ellipsis,
          style: _hovered
              ? style?.copyWith(
                  color: CupertinoTheme.of(context).primaryContrastingColor,
                )
              : style,
        ),
      ),
    );
  }
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
