import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/history_manager.dart';

/// Same stamp geometry for the live stroke and committed pixels. Mouse input
/// stays at full size; stylus pressure changes the diameter of each sample.
void drawPressureStroke(Canvas canvas, StrokeData stroke) {
  final points = stroke.points;
  if (points.isEmpty) return;
  double factor(int index) => stroke.pressures.isEmpty
      ? 1
      : stroke.pressures[index.clamp(0, stroke.pressures.length - 1)];
  final paint = Paint()
    ..color = stroke.isEraser
        ? Colors.white
        : stroke.color.withValues(alpha: stroke.opacity)
    ..blendMode = stroke.isEraser ? BlendMode.dstOut : BlendMode.srcOver;
  void stamp(Offset point, double diameter) {
    final radius = diameter / 2;
    paint.shader = null;
    if (stroke.hardness < 1) {
      paint.shader = RadialGradient(
        colors: [paint.color, paint.color.withValues(alpha: 0)],
        stops: const [0, 1],
      ).createShader(Rect.fromCircle(center: point, radius: radius));
    }
    if (stroke.square) {
      canvas.drawRect(
        Rect.fromCenter(center: point, width: diameter, height: diameter),
        paint,
      );
    } else {
      canvas.drawCircle(point, radius, paint);
    }
  }

  stamp(points.first, stroke.size * factor(0));
  for (var index = 1; index < points.length; index++) {
    final start = points[index - 1], end = points[index];
    final steps = math.max(
      1,
      ((end - start).distance / math.max(.5, stroke.size * .12)).ceil(),
    );
    for (var step = 1; step <= steps; step++) {
      final t = step / steps;
      stamp(
        Offset.lerp(start, end, t)!,
        stroke.size * (factor(index - 1) * (1 - t) + factor(index) * t),
      );
    }
  }
}
