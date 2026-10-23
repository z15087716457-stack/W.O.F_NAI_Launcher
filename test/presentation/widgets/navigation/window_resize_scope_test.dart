import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_resize_scope.dart';
import 'package:window_manager/window_manager.dart';

void _event({required bool end}) {
  for (final listener in windowManager.listeners) {
    end ? listener.onWindowResized() : listener.onWindowResize();
  }
}

class _Counts {
  int builds = 0, layouts = 0;
  Size? media, constraints;
}

class _Probe extends StatelessWidget {
  const _Probe(this.counts, {required this.child});
  final _Counts counts;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    counts.builds++;
    counts.media = MediaQuery.sizeOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        counts.layouts++;
        counts.constraints = box.biggest;
        return child;
      },
    );
  }
}

Future<void> _size(WidgetTester t, Size size) async {
  t.view.physicalSize = size;
  await t.pump();
}

class _AnimatedProbe extends StatefulWidget {
  const _AnimatedProbe();

  @override
  State<_AnimatedProbe> createState() => _AnimatedProbeState();
}

class _AnimatedProbeState extends State<_AnimatedProbe>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: animation,
    child: const ColoredBox(color: Colors.blue),
  );
}

void main() {
  for (final target in [
    const Size(1200, 600),
    const Size(600, 600),
    const Size(800, 900),
    const Size(800, 400),
    const Size(1100, 850),
  ]) {
    testWidgets('native drag lays out every live size at $target', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(800, 600);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      final counts = _Counts();
      final editor = TextEditingController(text: 'keep draft');
      addTearDown(editor.dispose);
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) => WindowResizeScope(child: child!),
          home: _Probe(
            counts,
            child: Scaffold(body: TextField(controller: editor)),
          ),
        ),
      );
      await t.enterText(find.byType(TextField), 'latest draft');
      final state = t.state(find.byType(TextField));
      _event(end: false);
      await t.pump();
      final before = (counts.builds, counts.layouts);
      final fieldHeight = t.getSize(find.byType(TextField)).height;
      for (var step = 1; step <= 12; step++) {
        _event(end: false);
        await _size(t, Size.lerp(const Size(800, 600), target, step / 12)!);
        final live = Size.lerp(const Size(800, 600), target, step / 12)!;
        expect(counts.media, live);
        expect(counts.constraints, live);
        expect(counts.layouts, before.$2 + step);
        expect(t.getSize(find.byType(TextField)).height, fieldHeight);
      }
      _event(end: true);
      await t.pump();
      expect(counts.media, target);
      expect(counts.constraints, target);
      expect(counts.layouts, before.$2 + 12);
      expect(t.state(find.byType(TextField)), same(state));
      expect(editor.text, 'latest draft');
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('programmatic size changes remain live outside a drag', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(800, 600);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    final counts = _Counts();
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) => WindowResizeScope(child: child!),
        home: _Probe(counts, child: const SizedBox.expand()),
      ),
    );
    await _size(t, const Size(1000, 700));
    expect(counts.media, const Size(1000, 700));
    expect(counts.constraints, const Size(1000, 700));
    await _size(t, const Size(700, 500));
    expect(counts.media, const Size(700, 500));
  });

  testWidgets('cancelled drag and next drag reuse the current committed size', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(800, 600);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    final counts = _Counts();
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) => WindowResizeScope(child: child!),
        home: _Probe(counts, child: const SizedBox.expand()),
      ),
    );
    _event(end: false);
    await _size(t, const Size(1000, 700));
    await _size(t, const Size(800, 600));
    _event(end: true);
    await t.pump();
    expect(counts.media, const Size(800, 600));
    _event(end: false);
    await _size(t, const Size(900, 800));
    expect(counts.media, const Size(900, 800));
    _event(end: true);
    await t.pump();
    expect(counts.media, const Size(900, 800));
    _event(end: false);
    await _size(t, const Size(1100, 500));
    expect(counts.media, const Size(1100, 500));
    _event(end: true);
    await t.pump();
    expect(counts.media, const Size(1100, 500));
  });

  for (final color in [Colors.white, const Color(0xff15191c)]) {
    testWidgets('live content fills the viewport without blank edges $color', (
      t,
    ) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(800, 600);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      final key = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) => RepaintBoundary(
            key: key,
            child: WindowResizeScope(child: child!),
          ),
          home: ColoredBox(color: color),
        ),
      );
      _event(end: false);
      await _size(t, const Size(1100, 400));
      await t.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = (await image.toByteData())!;
        for (final (x, y) in [(0, 0), (1099, 0), (0, 399), (1099, 399)]) {
          final offset = (y * image.width + x) * 4;
          expect(bytes.getUint8(offset), color.r * 255);
          expect(bytes.getUint8(offset + 1), color.g * 255);
          expect(bytes.getUint8(offset + 2), color.b * 255);
          expect(bytes.getUint8(offset + 3), 255);
        }
        image.dispose();
      });
      _event(end: true);
      await t.pump();
    });
  }

  testWidgets('listener is removed when the scope is disposed', (t) async {
    final before = windowManager.listeners.length;
    await t.pumpWidget(
      const MaterialApp(home: WindowResizeScope(child: SizedBox.expand())),
    );
    expect(windowManager.listeners.length, before + 1);
    await t.pumpWidget(const SizedBox.shrink());
    expect(windowManager.listeners.length, before);
  });

  testWidgets('content animations stay live during resize', (t) async {
    await t.pumpWidget(
      const MaterialApp(home: WindowResizeScope(child: _AnimatedProbe())),
    );
    final state = t.state<_AnimatedProbeState>(find.byType(_AnimatedProbe));
    await t.pump(const Duration(milliseconds: 100));
    _event(end: false);
    await t.pump();
    final value = state.animation.value;
    await t.pump(const Duration(milliseconds: 600));
    expect(state.animation.value, isNot(value));
    _event(end: true);
    await t.pump();
    await t.pump(const Duration(milliseconds: 70));
    expect(state.animation.value, isNot(value));
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resize uses current logical size after a DPI change', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(800, 600);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    final counts = _Counts();
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) => WindowResizeScope(child: child!),
        home: _Probe(counts, child: const SizedBox.expand()),
      ),
    );
    _event(end: false);
    t.view.devicePixelRatio = 2;
    await _size(t, const Size(2000, 1400));
    expect(counts.media, const Size(1000, 700));
    _event(end: true);
    await t.pump();
    expect(counts.media, const Size(1000, 700));
    expect(counts.constraints, const Size(1000, 700));
  });
}
