import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/src/test_vsync.dart' as test_vsync;
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CanvasCamera', () {
    test('screenToWorld / worldToScreen 互逆', () {
      const cam = CanvasCamera(offset: Offset(10, -20), scale: 2.0);
      const p = Offset(123, 456);
      expect(cam.worldToScreen(cam.screenToWorld(p)), closeToOffset(p));
    });

    test('zoomAt 保持屏幕锚点不动', () {
      const cam = CanvasCamera(offset: Offset(30, 40), scale: 1.0);
      const anchor = Offset(200, 150);
      final zoomed = cam.zoomAt(anchor, 2.0);
      expect(
        zoomed.worldToScreen(cam.screenToWorld(anchor)),
        closeToOffset(anchor),
      );
      expect(zoomed.scale, 2.0);
    });

    test('zoomAt 钳制 [0.1, 8]', () {
      const cam = CanvasCamera(offset: Offset.zero, scale: 1.0);
      expect(cam.zoomAt(Offset.zero, 100).scale, 8.0);
      expect(cam.zoomAt(Offset.zero, 0.001).scale, 0.1);
    });

    test('visibleWorldRect 随相机移动', () {
      const cam = CanvasCamera(offset: Offset(100, 50), scale: 2.0);
      final rect = cam.visibleWorldRect(const Size(400, 300));
      expect(rect.left, -50); // -offset.dx / scale
      expect(rect.top, -25);
      expect(rect.width, 200);
      expect(rect.height, 150);
    });
  });

  group('GenerationCanvasController', () {
    test('panBy 累加 offset 并打断动画', () {
      final c = GenerationCanvasController(
        vsync: const test_vsync.TestVSync(),
      );
      c.panBy(const Offset(10, 20));
      c.panBy(const Offset(5, -5));
      expect(c.camera.offset, const Offset(15, 15));
      c.dispose();
    });

    test('fling 慢速不动', () {
      final c = GenerationCanvasController(
        vsync: const test_vsync.TestVSync(),
      );
      // 0.01 px/ms = 10px/s < 20px/s 停止阈值 → 不起惯性
      c.fling(const Offset(0.01, 0));
      expect(c.camera.offset, Offset.zero);
      c.dispose();
    });

    test('setPanDirection 零向量停止 ticker', () {
      final c = GenerationCanvasController(
        vsync: const test_vsync.TestVSync(),
      );
      c.setPanDirection(const Offset(1, 0));
      c.setPanDirection(Offset.zero);
      c.dispose();
    });

    test('flyToRect 近距离走动画路径不抛异常', () {
      final c = GenerationCanvasController(
        vsync: const test_vsync.TestVSync(),
      );
      const viewport = Size(800, 600);
      const rect = Rect.fromLTWH(-416, -608, 832, 1216);
      c.flyToRect(rect, viewport);
      c.dispose();
    });
  });
}

Matcher closeToOffset(Offset expected) => _OffsetMatcher(expected);

class _OffsetMatcher extends Matcher {
  _OffsetMatcher(this.expected);
  final Offset expected;
  static const double epsilon = 1e-6;
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Offset) return false;
    return (item - expected).distance <= epsilon;
  }

  @override
  Description describe(Description description) =>
      description.add('offset ≈ $expected');
}
