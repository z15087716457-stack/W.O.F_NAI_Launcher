import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One vector glyph for every translation surface. While busy, the arrows
/// rotate around a fixed upright A without affecting editable text offsets.
class TranslationIcon extends StatefulWidget {
  const TranslationIcon({super.key, this.size, this.color, this.busy = false});
  final double? size;
  final Color? color;
  final bool busy;

  @override
  State<TranslationIcon> createState() => _TranslationIconState();
}

class _TranslationIconState extends State<TranslationIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  void _updateMotion() {
    final enabled =
        widget.busy &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  @override
  void didUpdateWidget(TranslationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busy != widget.busy) _updateMotion();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = widget.size ?? iconTheme.size ?? 24;
    var color =
        widget.color ??
        iconTheme.color ??
        Theme.of(context).colorScheme.onSurface;
    final opacity = iconTheme.opacity ?? 1;
    color = color.withValues(alpha: color.a * opacity);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: TranslationIconPainter(color, _motion)),
      ),
    );
  }
}

/// Text-free vector paths make the small icon independent of font fallback.
class TranslationIconPainter extends CustomPainter {
  TranslationIconPainter(this.color, this.motion) : super(repaint: motion);
  final Color color;
  final Animation<double> motion;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final ring = Path()
      ..moveTo(4.4, 8)
      ..arcToPoint(const Offset(19.2, 6.2), radius: const Radius.circular(8.2))
      ..moveTo(19.2, 3.4)
      ..lineTo(19.2, 6.2)
      ..lineTo(16.4, 6.2)
      ..moveTo(19.6, 16)
      ..arcToPoint(const Offset(4.8, 17.8), radius: const Radius.circular(8.2))
      ..moveTo(4.8, 20.6)
      ..lineTo(4.8, 17.8)
      ..lineTo(7.6, 17.8);
    canvas.save();
    canvas.translate(12, 12);
    canvas.rotate(motion.value * math.pi * 2);
    canvas.translate(-12, -12);
    canvas.drawPath(ring, paint);
    canvas.restore();
    canvas.drawPath(
      Path()
        ..moveTo(8.8, 15.4)
        ..lineTo(12, 8.1)
        ..lineTo(15.2, 15.4)
        ..moveTo(10, 12.8)
        ..lineTo(14, 12.8),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(TranslationIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.motion != motion;
}
