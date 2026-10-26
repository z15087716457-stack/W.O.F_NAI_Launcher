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
    this.subtitle,
    this.badge,
    this.enabled = true,
    this.indent = 0,
    this.leading,
    this.keepOpen = false,
    this.onExit,
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

  /// 第二行弱色说明（11 号）。
  final String? subtitle;

  /// 标题后的小蓝标签（例如“新”）。
  final String? badge;
  final bool enabled;

  /// 子项缩进（分类树）。
  final double indent;

  /// 左侧自定义图标（例如服务商标志）；有 [glyph] 时忽略。
  final Widget? leading;

  /// 点了不关菜单（例如“再点一次确认”的两步操作）。
  final bool keepOpen;

  /// 鼠标移出这一项（两步确认用来作废）。
  final VoidCallback? onExit;
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
                _ExitRegion(
                  onExit: it.onExit,
                  child: UiPressable(
                    key: it.key,
                    onTap: it.enabled
                        ? () {
                            if (!it.keepOpen) onClose();
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
                        height: it.subtitle == null ? 34 : 48,
                        padding: EdgeInsets.only(
                          left: 10 + it.indent,
                          right: 10,
                        ),
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
                              )
                            else
                              ?it.leading,
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    spacing: 6,
                                    children: [
                                      Flexible(
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
                                      if (it.badge != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: c.brand.withValues(
                                              alpha: .12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            it.badge!,
                                            style: UiText.sans(
                                              10,
                                              weight: FontWeight.w600,
                                              color: c.accent,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (it.subtitle != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: Text(
                                        it.subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: UiText.sans(11, color: c.faint),
                                      ),
                                    ),
                                ],
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExitRegion extends StatelessWidget {
  const _ExitRegion({required this.onExit, required this.child});
  final VoidCallback? onExit;
  final Widget child;

  @override
  Widget build(BuildContext context) => onExit == null
      ? child
      : MouseRegion(onExit: (_) => onExit!(), child: child);
}
