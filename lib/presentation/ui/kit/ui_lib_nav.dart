import 'package:flutter/material.dart';

import 'ui_colors.dart';
import 'ui_controls.dart';
import 'ui_glyph.dart';
import 'ui_text.dart';

/// 库页左栏的导航行：32 高、外边距 8、圆角 7、图标 15、间距 9；选中控件底 + 加粗；
/// [drop] = 拖卡片悬停在上面（强调色 10% 底 + 1.5 描边）。[indent] 是子分类的缩进。
/// （在线画廊有一份同样外观的私有实现，后续页面统一用这个。）
class UiNavItem extends StatelessWidget {
  const UiNavItem({
    super.key,
    required this.label,
    this.glyph,
    this.glyphSize = 15,
    this.glyphColor,
    this.leading,
    this.trailing,
    this.selected = false,
    this.drop = false,
    this.indent = 0,
    this.onTap,
    this.onSecondaryTap,
  });

  final String label;
  final String? glyph;
  final double glyphSize;
  final Color? glyphColor;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final bool drop;
  final double indent;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onSecondaryTapUp: onSecondaryTap == null
            ? null
            : (d) => onSecondaryTap!(d.globalPosition),
        child: UiPressable(
          onTap: onTap,
          builder: (context, hover) => Container(
            height: 32,
            padding: EdgeInsets.only(left: 10 + indent, right: 10),
            decoration: BoxDecoration(
              color: drop
                  ? c.accent.withValues(alpha: .10)
                  : selected
                  ? c.control
                  : (hover ? c.hover : null),
              borderRadius: BorderRadius.circular(7),
              border: drop ? Border.all(color: c.accent, width: 1.5) : null,
            ),
            child: Row(
              spacing: 9,
              children: [
                if (leading != null)
                  leading!
                else if (glyph != null)
                  UiGlyph(
                    glyph!,
                    size: glyphSize,
                    color: drop ? c.accent : (glyphColor ?? c.muted),
                  ),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(
                      13,
                      weight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: drop ? c.accent : c.ink,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 导航行尾的计数：Geist Mono 11.5 弱色。
class UiNavCount extends StatelessWidget {
  const UiNavCount(this.count, {super.key});
  final int? count;

  @override
  Widget build(BuildContext context) => Text(
    count == null ? '' : '$count',
    style: UiText.mono(11.5, color: context.ui.faint),
  );
}

/// 左栏小节标题：30 高、上外边距 8、11.5 / w600 弱色。
class UiSectionTitle extends StatelessWidget {
  const UiSectionTitle({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.only(left: 18, right: 12),
    child: DefaultTextStyle.merge(
      style: UiText.sans(
        11.5,
        weight: FontWeight.w600,
        color: context.ui.faint,
      ),
      child: Row(spacing: 6, children: children),
    ),
  );
}

/// 虚线圆角框（空库拖放区、托盘加号格）。
class UiDashedBox extends StatelessWidget {
  const UiDashedBox({
    super.key,
    required this.child,
    this.radius = 16,
    this.padding = EdgeInsets.zero,
    this.color,
    this.strokeWidth = 1.5,
    this.dash = 5,
    this.gap = 4,
  });
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color? color;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedPainter(
      color ?? context.ui.strong,
      radius,
      strokeWidth,
      dash,
      gap,
    ),
    child: Padding(padding: padding, child: child),
  );
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color, this.radius, this.width, this.dash, this.gap);
  final Color color;
  final double radius;
  final double width;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(width / 2),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += dash + gap) {
        canvas.drawPath(m.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color || old.radius != radius || old.width != width;
}
