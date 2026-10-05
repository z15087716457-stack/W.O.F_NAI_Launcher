import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Axis-aligned square stamps, shared by preview, layer rasterization and export.
void drawSquareStroke(
  Canvas canvas,
  List<Offset> points,
  double size,
  Paint paint,
) {
  paint.style = PaintingStyle.fill;
  void stamp(Offset point) => canvas.drawRect(
    Rect.fromCenter(center: point, width: size, height: size),
    paint,
  );
  if (points.isEmpty) return;
  stamp(points.first);
  for (var i = 1; i < points.length; i++) {
    final from = points[i - 1];
    final to = points[i];
    final steps = math
        .max((to.dx - from.dx).abs(), (to.dy - from.dy).abs())
        .ceil();
    for (var step = 1; step <= steps; step++) {
      stamp(Offset.lerp(from, to, step / steps)!);
    }
  }
}
