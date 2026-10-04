import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The approved horizontal double-link glyph, drawn at its native 16px size.
class BridgeLinkIcon extends StatefulWidget {
  const BridgeLinkIcon({
    super.key,
    required this.color,
    this.working = false,
    this.size = 16,
  });
  final Color color;
  final bool working;
  final double size;

  @override
  State<BridgeLinkIcon> createState() => _BridgeLinkIconState();
}

class _BridgeLinkIconState extends State<BridgeLinkIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  void _updateMotion() {
    final animate =
        widget.working &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate) {
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
  void didUpdateWidget(BridgeLinkIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMotion();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: AnimatedBuilder(
      animation: _motion,
      builder: (_, _) => CustomPaint(
        painter: BridgeLinkPainter(
          color: widget.color,
          progress: _motion.value,
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }
}

class BridgeLinkPainter extends CustomPainter {
  const BridgeLinkPainter({required this.color, this.progress = 0});
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Less than half a physical pixel of movement at the 16px display size.
    final shift = math.sin(progress * math.pi * 2) * 0.65;
    final left = Path()
      ..moveTo(10 + shift, 7)
      ..lineTo(7 + shift, 7)
      ..cubicTo(4.24 + shift, 7, 2 + shift, 9.24, 2 + shift, 12)
      ..cubicTo(2 + shift, 14.76, 4.24 + shift, 17, 7 + shift, 17)
      ..lineTo(10 + shift, 17);
    final right = Path()
      ..moveTo(14 - shift, 7)
      ..lineTo(17 - shift, 7)
      ..cubicTo(19.76 - shift, 7, 22 - shift, 9.24, 22 - shift, 12)
      ..cubicTo(22 - shift, 14.76, 19.76 - shift, 17, 17 - shift, 17)
      ..lineTo(14 - shift, 17);
    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
    canvas.drawLine(const Offset(8, 12), const Offset(16, 12), paint);
  }

  @override
  bool shouldRepaint(BridgeLinkPainter oldDelegate) =>
      color != oldDelegate.color || progress != oldDelegate.progress;
}
