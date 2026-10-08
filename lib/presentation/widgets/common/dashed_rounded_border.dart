import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Keeps the atom editor's joined edges intact; pills opt into a fully dashed outline.
class DashedRoundedBorderPainter extends CustomPainter {
  DashedRoundedBorderPainter({
    required this.color,
    required this.dashedColor,
    required this.radius,
    required this.topRounded,
    required this.bottomRounded,
    required this.solidLeft,
    required this.solidRight,
    this.dashedAll = false,
    this.strokeWidth = 1,
  });

  final Color color;
  final Color dashedColor;
  final Radius radius;
  final bool topRounded;
  final bool bottomRounded;
  final bool solidLeft;
  final bool solidRight;
  final bool dashedAll;
  final double strokeWidth;

  static const double _dash = 3;
  static const double _gap = 2;
  static const double _c = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (dashedAll) {
      final rect = (Offset.zero & size).deflate(strokeWidth / 2);
      final path = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            rect,
            Radius.circular(math.max(0, radius.x - strokeWidth / 2)),
          ),
        );
      final dashPaint = Paint()
        ..color = dashedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      for (final metric in path.computeMetrics()) {
        for (var start = 0.0; start < metric.length; start += _dash + _gap) {
          canvas.drawPath(
            metric.extractPath(start, math.min(start + _dash, metric.length)),
            dashPaint,
          );
        }
      }
      return;
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dashedPaint = Paint()
      ..color = dashedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final w = size.width;
    final h = size.height;
    final r = radius.x;
    // 四角弧条件：角有资格圆（首/末外角）且相邻两边都实。
    final tl = topRounded && solidLeft ? r : 0.0;
    final tr = topRounded && solidRight ? r : 0.0;
    final bl = bottomRounded && solidLeft ? r : 0.0;
    final br = bottomRounded && solidRight ? r : 0.0;

    canvas.drawLine(Offset(tl, _c), Offset(w - tr, _c), paint);
    canvas.drawLine(Offset(bl, h - _c), Offset(w - br, h - _c), paint);
    if (tl > 0) {
      _arc(canvas, paint, tl, tl, math.pi, math.pi / 2);
    }
    if (tr > 0) {
      _arc(canvas, paint, w - tr, tr, -math.pi / 2, math.pi / 2);
    }
    if (br > 0) {
      _arc(canvas, paint, w - br, h - br, 0, math.pi / 2);
    }
    if (bl > 0) {
      _arc(canvas, paint, bl, h - bl, math.pi / 2, math.pi / 2);
    }
    _edgeV(canvas, solidLeft ? paint : dashedPaint, _c, tl, h - bl, solidLeft);
    _edgeV(
      canvas,
      solidRight ? paint : dashedPaint,
      w - _c,
      tr,
      h - br,
      solidRight,
    );
  }

  /// 竖边：实线一条到底；虚线首段顶 y1（接上横边/弧端）、
  /// 末段顶 y2。
  void _edgeV(
    Canvas canvas,
    Paint paint,
    double x,
    double y1,
    double y2,
    bool solid,
  ) {
    if (solid) {
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
      return;
    }
    var y = y1;
    while (y < y2) {
      final end = (y + _dash).clamp(y, y2);
      canvas.drawLine(Offset(x, y), Offset(x, end.toDouble()), paint);
      y += _dash + _gap;
    }
  }

  /// 四分之一圆弧（逆时针坐标系下的角弧），线心半径 = 角
  /// 半径 - 0.5 保证外缘对齐框边。
  void _arc(
    Canvas canvas,
    Paint paint,
    double cx,
    double cy,
    double start,
    double sweep,
  ) {
    final rr = radius.x - _c;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: rr),
      start,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.dashedAll != dashedAll ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.color != color ||
      oldDelegate.dashedColor != dashedColor ||
      oldDelegate.radius != radius ||
      oldDelegate.topRounded != topRounded ||
      oldDelegate.bottomRounded != bottomRounded ||
      oldDelegate.solidLeft != solidLeft ||
      oldDelegate.solidRight != solidRight;
}
