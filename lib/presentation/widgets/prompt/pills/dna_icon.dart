import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 轻量线性 DNA 双螺旋图标，不依赖图标字体或第三方库。
class DnaIcon extends StatelessWidget {
  const DnaIcon({
    super.key,
    this.size = 16,
    required this.color,
    this.strokeWidth = 1.4,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: DnaIconPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class DnaIconPainter extends CustomPainter {
  const DnaIconPainter({required this.color, this.strokeWidth = 1.4});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final railPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.8, strokeWidth * 0.8);

    final center = size.width / 2;
    final amplitude = size.width * 0.26;
    final top = size.height * 0.08;
    final bottom = size.height * 0.92;
    const turns = math.pi * 2.0;
    final left = Path();
    final right = Path();
    const samples = 24;
    for (var i = 0; i <= samples; i++) {
      final t = i / samples;
      final y = top + (bottom - top) * t;
      final wave = math.sin(t * turns) * amplitude;
      final leftX = center - wave;
      final rightX = center + wave;
      if (i == 0) {
        left.moveTo(leftX, y);
        right.moveTo(rightX, y);
      } else {
        left.lineTo(leftX, y);
        right.lineTo(rightX, y);
      }
    }
    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);

    const rungCount = 5;
    for (var i = 0; i < rungCount; i++) {
      final t = (i + 0.5) / rungCount;
      final y = top + (bottom - top) * t;
      final wave = math.sin(t * turns) * amplitude;
      canvas.drawLine(
        Offset(center - wave, y),
        Offset(center + wave, y),
        railPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DnaIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
