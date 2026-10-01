import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One vector glyph for every translation surface. The two upright characters
/// exchange positions while busy; neither glyph changes editable text offsets.
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
    final phase = math.sin(motion.value * math.pi * 2);
    final progress = (1 - math.cos(motion.value * math.pi * 2)) / 2;
    const latinHome = Offset(6.7, 8.5);
    const chineseHome = Offset(16, 13.7);
    final arc = Offset(-1.8 * phase, 3.2 * phase);
    final latin = Offset.lerp(latinHome, chineseHome, progress)! + arc;
    final chinese = Offset.lerp(chineseHome, latinHome, progress)! - arc;
    final alpha = 1 - .65 * 4 * progress * (1 - progress);
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final a = Path()
      ..moveTo(-3.2, 4.5)
      ..lineTo(0, -4.5)
      ..lineTo(3.2, 4.5)
      ..moveTo(-2.1, 1.5)
      ..lineTo(2, 1.5);
    final wen = Path()
      ..moveTo(-1.2, -6.3)
      ..lineTo(-1.2, -4.3)
      ..moveTo(-5.2, -4.3)
      ..lineTo(5.2, -4.3)
      ..moveTo(-3.3, -2.3)
      ..cubicTo(-2.2, 1.7, .4, 4.5, 4.6, 6.3)
      ..moveTo(2.8, -2.3)
      ..cubicTo(1.8, 1.5, -.9, 4.4, -5.3, 6.3);
    canvas.drawPath(a.shift(latin), paint);
    canvas.drawPath(wen.shift(chinese), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(TranslationIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.motion != motion;
}
