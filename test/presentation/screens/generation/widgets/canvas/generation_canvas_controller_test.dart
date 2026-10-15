import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_controller.dart';

/// 复刻视图层接线：State + SingleTickerProviderStateMixin 供 ticker，
/// dispose 时归还。测试用 tester.pump 的 fake time 驱动动画帧。
class _TickerHost extends StatefulWidget {
  const _TickerHost({required this.camera});

  final GenerationCanvasCameraNotifier camera;

  @override
  State<_TickerHost> createState() => _TickerHostState();
}

class _TickerHostState extends State<_TickerHost>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    widget.camera.attachTicker(this);
  }

  @override
  void dispose() {
    widget.camera.disposeTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

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

    test('zoom from a very large fit stays continuous around the anchor', () {
      const fitted = CanvasCamera(offset: Offset(100, 50), scale: .02);
      const anchor = Offset(300, 200);
      final world = fitted.screenToWorld(anchor);
      final out = fitted.zoomAt(anchor, .8);
      expect(out.scale, closeTo(.016, 1e-9));
      expect(out.worldToScreen(world), closeToOffset(anchor));
      final inward = fitted.zoomAt(anchor, 1.2);
      expect(inward.scale, closeTo(.024, 1e-9));
      expect(inward.worldToScreen(world), closeToOffset(anchor));
    });
  });

  group('GenerationCanvasCameraNotifier', () {
    ProviderContainer buildContainer({bool reducedMotion = false}) {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith(
            (ref) => _FakeCanvasStorage(reducedMotion: reducedMotion),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('panBy 累加 offset', () {
      final container = buildContainer();
      final n = container.read(generationCanvasCameraProvider.notifier);
      final before = container.read(generationCanvasCameraProvider).offset;
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

    test('adjustTargetForTeleport 远目标返回原目标并把起点瞬移到近旁', () {
      final container = buildContainer();
      final n = container.read(generationCanvasCameraProvider.notifier);
      n.jump(CanvasCamera.init);
      const viewport = Size(800, 600); // 对角线 1000，limit = 3000
      const center = Offset(400, 300);
      const target = CanvasCamera(offset: Offset(0, 10000), scale: 1);

      final adjusted = n.adjustTargetForTeleport(target, viewport);

      // 官网快照语义：返回值始终是原始目标，落点不被改写
      expect(adjusted.offset, target.offset);
      expect(adjusted.scale, target.scale);
      // 当前相机被瞬移到目标近旁：目标视口中心的世界点在新相机下
      // 距屏幕中心恰好 3×对角线
      final moved = container.read(generationCanvasCameraProvider);
      final targetCenterWorld = target.screenToWorld(center);
      expect(
        (moved.worldToScreen(targetCenterWorld) - center).distance,
        closeTo(3000, 0.001),
      );
      expect(moved.scale, 1);
    });

    test('adjustTargetForTeleport 双侧 scale 不同时坐标换算一致', () {
      final container = buildContainer();
      final n = container.read(generationCanvasCameraProvider.notifier);
      n.jump(CanvasCamera.init); // scale 1
      const viewport = Size(800, 600);
      const center = Offset(400, 300);
      const target = CanvasCamera(offset: Offset(0, 50000), scale: 4);

      final adjusted = n.adjustTargetForTeleport(target, viewport);

      expect(adjusted.offset, target.offset);
      expect(adjusted.scale, target.scale);
      final moved = container.read(generationCanvasCameraProvider);
      // 瞬移只改 offset：起点保持自身 scale，缩放差交给 flyTo 趋近
      expect(moved.scale, 1);
      final targetCenterWorld = target.screenToWorld(center);
      expect(
        (moved.worldToScreen(targetCenterWorld) - center).distance,
        closeTo(3000, 0.001),
      );
    });

    test('无 ticker 时 flyTo 立即落到目标并回调', () {
      final container = buildContainer();
      final n = container.read(generationCanvasCameraProvider.notifier);
      var done = 0;
      const target = CanvasCamera(offset: Offset(300, -80), scale: 2);
      n.flyTo(target, onDone: () => done++);
      final cam = container.read(generationCanvasCameraProvider);
      expect(cam.offset, target.offset);
      expect(cam.scale, target.scale);
      expect(done, 1);
    });

    test('无 ticker 时离散 zoomBy 仍累计到未完成目标', () {
      final container = buildContainer();
      final n = container.read(generationCanvasCameraProvider.notifier);
      n.setViewport(const Size(800, 600));
      n.jump(CanvasCamera.init);
      n.zoomBy(1.2);
      n.zoomBy(1.2);
      expect(
        container.read(generationCanvasCameraProvider).scale,
        closeTo(1.44, 1e-6),
      );
    });

    test('zoomBy 平滑档立即生效且锚点下的世界点不动', () {
      final container = buildContainer();
      final n = container.read(generationCanvasCameraProvider.notifier);
      n.setViewport(const Size(800, 600));
      n.jump(CanvasCamera.init);
      const anchor = Offset(200, 150);
      final worldUnder = CanvasCamera.init.screenToWorld(anchor);
      n.zoomBy(1.1, anchor: anchor, smooth: true);
      final cam = container.read(generationCanvasCameraProvider);
      expect(cam.scale, closeTo(1.1, 1e-9));
      expect(cam.worldToScreen(worldUnder), closeToOffset(anchor));
    });

    test('discrete and smooth zoom preserve very large fitted scales', () {
      for (final smooth in [false, true]) {
        final container = buildContainer();
        final n = container.read(generationCanvasCameraProvider.notifier);
        n.setViewport(const Size(800, 600));
        n.flyTo(
          const CanvasCamera(offset: Offset(100, 50), scale: .02),
          fitInsideViewport: true,
        );
        n.zoomBy(.8, anchor: const Offset(300, 200), smooth: smooth);
        expect(
          container.read(generationCanvasCameraProvider).scale,
          closeTo(.016, 1e-9),
        );
      }
    });

    test('zoomBy 钳制 scale 上限 8', () {
      final container = buildContainer();
      final n = container.read(generationCanvasCameraProvider.notifier);
      n.setViewport(const Size(800, 600));
      n.jump(CanvasCamera.init);
      n.zoomBy(100);
      expect(container.read(generationCanvasCameraProvider).scale, 8.0);
    });

    test('panBy / jump / shiftWorldY 在无 ticker 下不崩溃', () {
      final container = buildContainer();
      final n = container.read(generationCanvasCameraProvider.notifier);
      n.panBy(const Offset(10, 0));
      n.jump(CanvasCamera.init);
      n.shiftWorldY(5);
      expect(container.read(generationCanvasCameraProvider).scale, 1);
    });
  });

  group('相机动画（ticker + fake time）', () {
    ProviderContainer buildContainer({bool reducedMotion = false}) {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith(
            (ref) => _FakeCanvasStorage(reducedMotion: reducedMotion),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<GenerationCanvasCameraNotifier> mountCamera(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      final n = container.read(generationCanvasCameraProvider.notifier);
      await tester.pumpWidget(_TickerHost(camera: n));
      return n;
    }

    CanvasCamera state(ProviderContainer c) =>
        c.read(generationCanvasCameraProvider);

    testWidgets('flyTo 按帧趋近并精确落在目标，onDone 只触发一次', (tester) async {
      final container = buildContainer();
      final n = await mountCamera(tester, container);
      var done = 0;
      const target = CanvasCamera(offset: Offset(120, -60), scale: 2);
      n.flyTo(target, onDone: () => done++);

      expect(state(container).scale, 1); // 起步未瞬移

      await tester.pump(); // Establish ticker's first frame timestamp.
      await tester.pump(const Duration(milliseconds: 16));
      final mid = state(container);
      expect(mid.scale, greaterThan(1));
      expect(mid.scale, lessThan(2));
      expect(mid.offset.dx, greaterThan(80));

      await tester.pump(const Duration(seconds: 2));
      final end = state(container);
      expect(end.offset.dx, closeTo(120, 1e-6));
      expect(end.offset.dy, closeTo(-60, 1e-6));
      expect(end.scale, closeTo(2, 1e-9));
      expect(done, 1);

      await tester.pump(const Duration(seconds: 1));
      expect(done, 1); // 兜底超时到达后不再重复回调
    });

    testWidgets('飞行中 panBy 取消飞行且不调用旧 onDone', (tester) async {
      final container = buildContainer();
      final n = await mountCamera(tester, container);
      var done = 0;
      n.flyTo(
        const CanvasCamera(offset: Offset(400, 0), scale: 2),
        onDone: () => done++,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      expect(state(container).offset.dx, greaterThan(80));

      n.panBy(const Offset(10, 4));
      final parked = state(container);
      await tester.pump(const Duration(seconds: 2));
      final after = state(container);
      expect(after.offset, parked.offset); // 不再朝旧目标移动
      expect(after.scale, parked.scale);
      expect(done, 0);
    });

    testWidgets('jump 取消飞行且后续帧不复活旧目标', (tester) async {
      final container = buildContainer();
      final n = await mountCamera(tester, container);
      var done = 0;
      n.flyTo(
        const CanvasCamera(offset: Offset(-500, 0), scale: 3),
        onDone: () => done++,
      );
      await tester.pump(const Duration(milliseconds: 32));
      n.jump(const CanvasCamera(offset: Offset(7, 9), scale: 1.5));
      await tester.pump(const Duration(seconds: 2));
      final after = state(container);
      expect(after.offset, const Offset(7, 9));
      expect(after.scale, 1.5);
      expect(done, 0);
    });

    testWidgets('兜底超时吸附到精确目标并收尾一次', (tester) async {
      final container = buildContainer();
      final n = await mountCamera(tester, container);
      var done = 0;
      const target = CanvasCamera(offset: Offset(300, 300), scale: 3);
      n.flyTo(
        target,
        speed: 0.001,
        duration: const Duration(milliseconds: 100),
        onDone: () => done++,
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(state(container).scale, lessThan(1.01)); // 极慢速仍在飞

      await tester.pump(const Duration(milliseconds: 600)); // 越过 100+400 兜底
      final end = state(container);
      expect(end.offset, target.offset);
      expect(end.scale, target.scale);
      expect(done, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(done, 1);
    });

    testWidgets('连续离散 zoomBy 累计到未完成目标再收敛', (tester) async {
      final container = buildContainer();
      final n = await mountCamera(tester, container);
      n.setViewport(const Size(800, 600));
      n.jump(CanvasCamera.init);
      await tester.pump(const Duration(milliseconds: 16));
      n.zoomBy(1.2);
      await tester.pump(const Duration(milliseconds: 16)); // 首飞尚未收敛
      n.zoomBy(1.2); // 应基于 1.2 目标继续累计 → 1.44
      await tester.pump(const Duration(seconds: 2));
      expect(state(container).scale, closeTo(1.44, 1e-6));
    });

    testWidgets('减动效下 flyTo 同步瞬移并回调', (tester) async {
      final container = buildContainer(reducedMotion: true);
      final n = await mountCamera(tester, container);
      var done = 0;
      const target = CanvasCamera(offset: Offset(-40, 90), scale: 2.5);
      n.flyTo(target, onDone: () => done++);
      final cam = state(container);
      expect(cam.offset, target.offset);
      expect(cam.scale, target.scale);
      expect(done, 1);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('导航跳转取消先前 idle，且不重新调度自动选图', (tester) async {
      final container = buildContainer();
      final n = await mountCamera(tester, container);
      var idle = 0;
      n.onIdle = () => idle++;
      n.panBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 60));
      n.jump(
        const CanvasCamera(offset: Offset(3, -10000), scale: .8),
        notifyIdle: false,
      );
      await tester.pump(const Duration(seconds: 3));
      expect(idle, 0);
      expect(state(container).offset, const Offset(3, -10000));
      n.panBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 121));
      expect(idle, 1);
    });

    testWidgets('停稳 120ms 触发 onIdle；运动恢复会取消待触发计时', (tester) async {
      final container = buildContainer();
      final n = await mountCamera(tester, container);
      var idle = 0;
      n.onIdle = () => idle++;

      n.panBy(const Offset(5, 0));
      await tester.pump(const Duration(milliseconds: 119));
      expect(idle, 0);
      await tester.pump(const Duration(milliseconds: 2));
      expect(idle, 1);

      // panBy 后 100ms 内重启飞行 → 旧 idle 计时被取消
      n.panBy(const Offset(5, 0));
      await tester.pump(const Duration(milliseconds: 100));
      n.flyTo(const CanvasCamera(offset: Offset(600, 0), scale: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(idle, 1); // 原 120ms 点已过但未触发

      await tester.pump(const Duration(seconds: 2));
      expect(idle, 2); // 飞行落点重新计时后触发
    });

    testWidgets('dispose 后不再触发回调也不抛异常', (tester) async {
      final container = buildContainer();
      final n = await mountCamera(tester, container);
      var done = 0;
      var idle = 0;
      n.onIdle = () => idle++;
      n.flyTo(
        const CanvasCamera(offset: Offset(200, 200), scale: 2),
        onDone: () => done++,
      );
      await tester.pump(const Duration(milliseconds: 30));
      container.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      expect(done, 0);
      expect(idle, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('远目标 teleport + flyTo 落点精确', (tester) async {
      final container = buildContainer();
      final n = await mountCamera(tester, container);
      n.jump(CanvasCamera.init);
      const target = CanvasCamera(offset: Offset(0, 20000), scale: 2);
      // 视图层同款调用：adjusted = adjustTargetForTeleport → flyTo(adjusted)
      final adjusted = n.adjustTargetForTeleport(target, const Size(800, 600));
      n.flyTo(adjusted);
      await tester.pump(const Duration(seconds: 2));
      final end = state(container);
      expect(end.offset.dx, closeTo(0, 1e-6));
      expect(end.offset.dy, closeTo(20000, 1e-6));
      expect(end.scale, closeTo(2, 1e-9));
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
  _FakeCanvasStorage({this.reducedMotion = false});

  final bool reducedMotion;

  @override
  bool getCanvasLockCamera() => false;

  @override
  bool getCanvasReducedMotion() => reducedMotion;
}
