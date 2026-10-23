import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/resize_decoration_cache.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_resize_scope.dart';
import 'package:window_manager/window_manager.dart';

void _event(bool active) {
  for (final listener in windowManager.listeners) {
    active ? listener.onWindowResize() : listener.onWindowResized();
  }
}

class _Paints extends CustomPainter {
  int count = 0;
  @override
  void paint(Canvas canvas, Size size) {
    count++;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(_Paints oldDelegate) => false;
}

void main() {
  testWidgets('only decoration is retained; controls and images lay out live', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(800, 600);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    final paints = _Paints();
    var revision = 0;
    late StateSetter update;
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) => WindowResizeScope(child: child!),
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Stack(
              children: [
                Positioned.fill(
                  child: ResizeDecorationCache(
                    child: CustomPaint(
                      painter: paints,
                      child: Text('decoration $revision'),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    key: const Key('image'),
                    width: 120,
                    height: 80,
                    child: Text('content $revision'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    final initialPaints = paints.count;
    _event(true);
    await t.pump();
    final cachedPaints = paints.count;
    expect(cachedPaints, greaterThanOrEqualTo(initialPaints));
    update(() => revision = 1);
    await t.pump();
    for (final size in [
      const Size(1100, 500),
      const Size(600, 850),
      const Size(1000, 700),
    ]) {
      t.view.physicalSize = size;
      await t.pump();
      expect(paints.count, cachedPaints);
      expect(
        t.getRect(find.byKey(const Key('image'))),
        Rect.fromLTWH(size.width - 120, size.height - 80, 120, 80),
      );
      expect(find.text('content 1'), findsOneWidget);
      expect(find.text('decoration 0'), findsOneWidget);
    }
    _event(false);
    await t.pump();
    expect(paints.count, greaterThan(cachedPaints));
    expect(find.text('decoration 1'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  for (final end in [true, false]) {
    testWidgets(
      'visible cache covers resized edges, dispose during drag=$end',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(800, 600);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.view.resetPhysicalSize);
        final key = GlobalKey();
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) => WindowResizeScope(child: child!),
            home: RepaintBoundary(
              key: key,
              child: const ResizeDecorationCache(
                child: ColoredBox(color: Colors.red),
              ),
            ),
          ),
        );
        _event(true);
        t.view.physicalSize = const Size(1100, 400);
        await t.pump();
        await t.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = (await image.toByteData())!;
          for (final (x, y) in [(0, 0), (1099, 0), (0, 399), (1099, 399)]) {
            final offset = (y * image.width + x) * 4;
            expect(bytes.getUint8(offset), 244);
            expect(bytes.getUint8(offset + 3), 255);
          }
          image.dispose();
        });
        if (end) {
          _event(false);
          await t.pump();
        }
        await t.pumpWidget(const SizedBox.shrink());
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'hidden decoration captures only when first painted during drag',
    (t) async {
      final paints = _Paints();
      late StateSetter update;
      var hidden = true;
      await t.pumpWidget(
        MaterialApp(
          home: WindowResizeScope(
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Offstage(
                  offstage: hidden,
                  child: ResizeDecorationCache(
                    child: CustomPaint(painter: paints),
                  ),
                );
              },
            ),
          ),
        ),
      );
      _event(true);
      await t.pump();
      expect(paints.count, 0);
      update(() => hidden = false);
      await t.pump();
      expect(paints.count, 1);
      _event(false);
      await t.pump();
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('only decoration ticker mode pauses and resumes', (t) async {
    var decorationEnabled = true;
    var contentEnabled = false;
    await t.pumpWidget(
      MaterialApp(
        home: WindowResizeScope(
          child: Stack(
            children: [
              Positioned.fill(
                child: ResizeDecorationCache(
                  child: Builder(
                    builder: (context) {
                      decorationEnabled = TickerMode.valuesOf(context).enabled;
                      return const ColoredBox(color: Colors.blue);
                    },
                  ),
                ),
              ),
              Builder(
                builder: (context) {
                  contentEnabled = TickerMode.valuesOf(context).enabled;
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
    expect(decorationEnabled, isTrue);
    _event(true);
    await t.pump();
    expect(decorationEnabled, isFalse);
    expect(contentEnabled, isTrue);
    _event(false);
    await t.pump();
    expect(decorationEnabled, isTrue);
  });

  testWidgets('decoration works outside the resize scope', (t) async {
    final paints = _Paints();
    await t.pumpWidget(
      MaterialApp(
        home: ResizeDecorationCache(child: CustomPaint(painter: paints)),
      ),
    );
    expect(paints.count, 1);
    expect(t.takeException(), isNull);
  });
}
