import 'package:flutter/material.dart';

import 'ui_colors.dart';
import 'ui_controls.dart';
import 'ui_glyph.dart';
import 'ui_popover.dart';
import 'ui_text.dart';

@immutable
class UiMenuItem {
  const UiMenuItem({
    required this.label,
    required this.onTap,
    this.glyph,
    this.danger = false,
    this.divider = false,
    this.checked = false,
    this.trailing,
    this.enabled = true,
    this.indent = 0,
    this.key,
  });
  final String label;
  final String? glyph;
  final VoidCallback onTap;
  final bool danger;

  /// 这一项上方画分隔线。
  final bool divider;

  /// 当前选中项（右侧打勾）。
  final bool checked;
  final String? trailing;
  final bool enabled;

  /// 子项缩进（分类树）。
  final double indent;
  final Key? key;
}

/// 菜单：弹层外观、内边距 4；行高 34、圆角 7、13 号字、图标 15。点一项先关菜单再执行。
/// （和在线画廊菜单同一外观，后续页面统一用这个。）
class UiMenu extends StatelessWidget {
  const UiMenu({
    super.key,
    required this.items,
    required this.onClose,
    this.width = 210,
    this.maxHeight = 420,
  });
  final List<UiMenuItem> items;
  final VoidCallback onClose;
  final double width;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPopoverSurface(
      width: width,
      padding: const EdgeInsets.all(4),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final it in items) ...[
                if (it.divider)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: c.line,
                  ),
                UiPressable(
                  key: it.key,
                  onTap: it.enabled
                      ? () {
                          onClose();
                          it.onTap();
                        }
                      : null,
                  builder: (context, hover) {
                    final fg = !it.enabled
                        ? c.faint
                        : it.danger
                        ? c.error
                        : c.ink;
                    return Container(
                      height: 34,
                      padding: EdgeInsets.only(left: 10 + it.indent, right: 10),
                      decoration: BoxDecoration(
                        color: hover ? c.control : null,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        spacing: 10,
                        children: [
                          if (it.glyph != null)
                            UiGlyph(
                              it.glyph!,
                              size: 15,
                              color: it.danger ? c.error : c.muted,
                            ),
                          Expanded(
                            child: Text(
                              it.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.sans(
                                13,
                                color: fg,
                                weight: it.checked
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (it.trailing != null)
                            Text(
                              it.trailing!,
                              style: UiText.mono(11.5, color: c.faint),
                            ),
                          if (it.checked)
                            UiGlyph(
                              UiGlyphs.check,
                              size: 14,
                              strokeWidth: 2.4,
                              color: c.accent,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
