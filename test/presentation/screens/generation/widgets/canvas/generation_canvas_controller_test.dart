import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
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

  group('GenerationCanvasCameraNotifier', () {
    ProviderContainer buildContainer() {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith(
            (ref) => _FakeCanvasStorage(),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('panBy 累加 offset', () {
      final container = buildContainer();
      final n = container.read(generationCanvasCameraProvider.notifier);
      final before =
          container.read(generationCanvasCameraProvider).offset;
      n.panBy(const Offset(10, 20));
      n.panBy(const Offset(5, -5));
      expect(
        container.read(generationCanvasCameraProvider).offset,
        before + const Offset(15, 15),
      );
    });

    test('fling 无 ticker 时不抛异常', () {
      final container = buildContainer();
      final n = container.read(generationCanvasCameraProvider.notifier);
      n.fling(const Offset(0.5, 0.5), const Size(800, 600));
      // 未 attachTicker 时 _anim 为 null：不应崩溃，状态不变
      expect(container.read(generationCanvasCameraProvider).scale, 1);
    });

    test('adjustTargetForTeleport 近距离不瞬移', () {
      final container = buildContainer();
      final n = container.read(generationCanvasCameraProvider.notifier);
      const viewport = Size(800, 600);
      const target = CanvasCamera(offset: Offset(200, 200), scale: 2);
      final adjusted = n.adjustTargetForTeleport(target, viewport);
      // 目标中心距视口中心未超 3×视口 → 原样返回
      expect(adjusted.offset, target.offset);
      expect(adjusted.scale, target.scale);
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

class _FakeCanvasStorage extends LocalStorageService {
  @override
  bool getCanvasLockCamera() => false;

  @override
  bool getCanvasReducedMotion() => false;
}
