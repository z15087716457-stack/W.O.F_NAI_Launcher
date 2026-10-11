import 'package:flutter/material.dart';

import 'ui_colors.dart';
import 'ui_text.dart';

enum UiKeycapStyle {
  /// 浮层里的键帽：18 高、1px 描边 + 2px 底边、抬起底。
  normal,

  /// 展开导航行尾：17 高、10 号字、透明底。
  compact,

  /// 深色提示气泡里：无描边，提示字色 14% 底。
  tip,
}

/// 一组键帽，例如 `['Ctrl', '1']`，间距 3。
class UiKeycaps extends StatelessWidget {
  const UiKeycaps(
    this.keys, {
    super.key,
    this.style = UiKeycapStyle.normal,
    this.gap = 3,
  });

  final List<String> keys;
  final UiKeycapStyle style;
  final double gap;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: gap,
    children: [for (final k in keys) UiKeycap(k, style: style)],
  );
}

class UiKeycap extends StatelessWidget {
  const UiKeycap(this.label, {super.key, this.style = UiKeycapStyle.normal});

  final String label;
  final UiKeycapStyle style;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final compact = style == UiKeycapStyle.compact;
    final tip = style == UiKeycapStyle.tip;
    final side = BorderSide(color: c.line);
    final h = compact ? 17.0 : 18.0;
    return Container(
      constraints: BoxConstraints(minWidth: h, minHeight: h, maxHeight: h),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: tip
            ? c.tipInk.withValues(alpha: .14)
            : compact
            ? null
            : c.raised,
        borderRadius: BorderRadius.circular(4),
        border: tip
            ? null
            : Border(
                left: side,
                top: side,
                right: side,
                bottom: side.copyWith(width: 2),
              ),
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          label,
          style: UiText.mono(
            compact ? 10 : 10.5,
            weight: FontWeight.w500,
            height: 1,
            color: tip ? c.tipInk.withValues(alpha: .8) : c.muted,
          ),
        ),
      ),
    );
  }
}
