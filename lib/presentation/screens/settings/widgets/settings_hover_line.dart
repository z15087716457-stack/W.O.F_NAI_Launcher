import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

/// Feedback drawn over an existing separator, without changing layout or input.
class SettingsHoverLine extends StatefulWidget {
  const SettingsHoverLine({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<SettingsHoverLine> createState() => _SettingsHoverLineState();
}

class _SettingsHoverLineState extends State<SettingsHoverLine> {
  bool _hovered = false;

  void _hover(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && _hovered;
    final color = Theme.of(context).colorScheme.primary;
    final direction = Directionality.of(context);
    Widget paint(double progress, Widget child) => CustomPaint(
      foregroundPainter: _HoverLinePainter(progress, color, direction),
      child: child,
    );

    return MouseRegion(
      onEnter: (_) => _hover(true),
      onExit: (_) => _hover(false),
      child: MediaQuery.disableAnimationsOf(context)
          ? paint(active ? 1 : 0, widget.child)
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: active ? 1 : 0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: widget.child,
              builder: (_, progress, child) => paint(progress, child!),
            ),
    );
  }
}

class _HoverLinePainter extends CustomPainter {
  const _HoverLinePainter(this.progress, this.color, this.direction);

  final double progress;
  final Color color;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || size.isEmpty) return;
    final length = math.min(144.0, size.width * .2) * progress;
    final start = direction == TextDirection.rtl ? size.width - length : 0.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(start, size.height - 1.5, length, 1.5),
        const Radius.circular(.75),
      ),
      Paint()..color = color.withValues(alpha: .6 * progress),
    );
  }

  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_HoverLinePainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      direction != oldDelegate.direction;
}
