import 'package:flutter/material.dart';

import '../../widgets/common/image_action_menu.dart';
import 'ui_colors.dart';
import 'ui_text.dart';

/// 保留旧图片菜单的双快捷按钮和子菜单，使用当前 UIUX 的颜色、字形与行距。
abstract final class UiImageMenu {
  static Future<T?> show<T>(
    BuildContext context, {
    required Offset position,
    required List<ImageMenuAction<T>> actions,
    required List<ImageMenuAction<T>> quickActions,
  }) {
    final c = context.ui;
    final item = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 34)),
      fixedSize: const WidgetStatePropertyAll(Size(double.infinity, 34)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10),
      ),
      textStyle: WidgetStatePropertyAll(UiText.sans(13)),
      iconColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? c.faint : c.muted,
      ),
      overlayColor: WidgetStatePropertyAll(c.control),
    );
    return ImageActionMenu.show<T>(
      context,
      position: position,
      actions: actions,
      quickActions: quickActions,
      appearance: ImageActionMenuStyle(
        menu: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.raised),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: c.line),
            ),
          ),
        ),
        item: item,
        quickAction: item.copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
          fixedSize: const WidgetStatePropertyAll(Size(double.infinity, 36)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 6),
          ),
          textStyle: WidgetStatePropertyAll(UiText.sans(12)),
          backgroundColor: WidgetStatePropertyAll(c.control),
        ),
        iconSize: 15,
        disabledColor: c.faint,
      ),
    );
  }
}
