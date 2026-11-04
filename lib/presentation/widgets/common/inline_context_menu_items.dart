import 'package:flutter/widgets.dart';

/// 输入框里的内联块（比如翻译块）给「右键点在它上面」的那次输入框右键菜单追加的项。
///
/// 右键照旧交给输入框，菜单内容也照旧由输入框决定；块只在右键按下时 [register] 自己的项，
/// 输入框构建菜单时用 [of] 取出来排在最后。只有从同一个按下位置打开的那次菜单取得到，
/// 之后在别处右键就没有了。
abstract final class InlineContextMenuItems {
  static final Expando<(Offset, List<ContextMenuButtonItem>)> _byField =
      Expando();

  static void register(
    EditableTextState field,
    Offset globalPosition,
    List<ContextMenuButtonItem> items,
  ) {
    _byField[field] = (globalPosition, items);
  }

  static List<ContextMenuButtonItem> of(EditableTextState field) {
    final entry = _byField[field];
    if (entry == null) return const [];
    final (position, items) = entry;
    return field.contextMenuAnchors.primaryAnchor == position
        ? items
        : const [];
  }
}
