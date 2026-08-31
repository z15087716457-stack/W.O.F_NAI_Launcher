import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/fixed_tag/fixed_tag_link.dart';

/// 固定词侧边栏联动曲线绘制器。
class SidebarLinkPainter extends CustomPainter {
  SidebarLinkPainter({
    required this.links,
    required this.isMismatched,
    required this.color,
    required this.positiveAnchors,
    required this.negativeAnchors,
    this.previewStart,
    this.previewEnd,
    this.previewIsDetaching = false,
  });

  final List<FixedTagLink> links;
  final bool Function(FixedTagLink link) isMismatched;
  final Color color;
  final Map<String, Offset> positiveAnchors;
  final Map<String, Offset> negativeAnchors;
  final Offset? previewStart;
  final Offset? previewEnd;
  final bool previewIsDetaching;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    for (final link in links) {
      final start = positiveAnchors[link.positiveEntryId];
      final end = negativeAnchors[link.negativeEntryId];
      if (start == null || end == null) continue;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx + 44, start.dy, end.dx - 44, end.dy, end.dx, end.dy);
      final paint = Paint()
        ..color = color.withValues(alpha: isMismatched(link) ? 0.45 : 0.85)
        ..strokeWidth = isMismatched(link) ? 1.6 : 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (isMismatched(link)) {
        _drawDashedPath(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }
    }

    final dragStart = previewStart;
    final dragEnd = previewEnd;
    if (dragStart != null && dragEnd != null) {
      final path = Path()
        ..moveTo(dragStart.dx, dragStart.dy)
        ..cubicTo(
          dragStart.dx + 44,
          dragStart.dy,
          dragEnd.dx - 44,
          dragEnd.dy,
          dragEnd.dx,
          dragEnd.dy,
        );
      final paint = Paint()
        ..color = color.withValues(alpha: previewIsDetaching ? 0.58 : 0.9)
        ..strokeWidth = previewIsDetaching ? 1.8 : 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      if (previewIsDetaching) {
        _drawDashedPath(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }
      canvas.drawCircle(
        dragEnd,
        previewIsDetaching ? 3.2 : 4.0,
        Paint()..color = color.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SidebarLinkPainter oldDelegate) {
    return oldDelegate.links != links ||
        oldDelegate.color != color ||
        oldDelegate.previewStart != previewStart ||
        oldDelegate.previewEnd != previewEnd ||
        oldDelegate.previewIsDetaching != previewIsDetaching ||
        oldDelegate.isMismatched != isMismatched ||
        !mapEquals(oldDelegate.positiveAnchors, positiveAnchors) ||
        !mapEquals(oldDelegate.negativeAnchors, negativeAnchors);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 6.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }
}

/// 收集锚点相对联动图层的中心坐标。
Map<String, Offset> collectAnchorCenters(
  Map<String, GlobalKey> keys,
  GlobalKey layerKey,
) {
  final layerRenderObject = layerKey.currentContext?.findRenderObject();
  if (layerRenderObject is! RenderBox || !layerRenderObject.hasSize) {
    return const {};
  }

  final centers = <String, Offset>{};
  for (final entry in keys.entries) {
    final renderObject = entry.value.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) continue;
    final globalCenter = renderObject.localToGlobal(
      renderObject.size.center(Offset.zero),
    );
    centers[entry.key] = layerRenderObject.globalToLocal(globalCenter);
  }
  return centers;
}
