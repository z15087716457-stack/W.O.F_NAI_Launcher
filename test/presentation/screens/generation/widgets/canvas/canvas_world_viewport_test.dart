import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_world_viewport.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_controller.dart';

void main() {
  testWidgets(
    'negative and distant coordinates share paint and hit transforms',
    (tester) async {
      final camera = ValueNotifier(CanvasCamera.init);
      addTearDown(camera.dispose);
      var taps = 0;
      var secondary = 0;
      const rect = Rect.fromLTWH(-9000, -5000, 200, 160);
      final children = [
        CanvasWorldItem(
          rect: rect,
          child: GestureDetector(
            onTap: () => taps++,
            onSecondaryTap: () => secondary++,
            child: const ColoredBox(color: Colors.blue),
          ),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<CanvasCamera>(
              valueListenable: camera,
              builder: (_, value, _) =>
                  CanvasWorldViewport(camera: value, children: children),
            ),
          ),
        ),
      );
      for (final scale in [0.25, 1.0, 2.0]) {
        camera.value = CanvasCamera(
          scale: scale,
          offset: const Offset(200, 180) - rect.topLeft * scale,
        );
        await tester.pump();
        for (final local in [
          const Offset(5, 5),
          const Offset(195, 5),
          const Offset(5, 155),
          const Offset(195, 155),
        ]) {
          final point = camera.value.worldToScreen(rect.topLeft + local);
          await tester.tapAt(point);
          await tester.pump();
        }
        final pointer = await tester.startGesture(
          camera.value.worldToScreen(rect.center),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await pointer.up();
        await tester.pump();
      }
      expect(taps, 12);
      expect(secondary, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('camera frames do not rebuild or relayout image content', (
    tester,
  ) async {
    final camera = ValueNotifier(CanvasCamera.init);
    addTearDown(camera.dispose);
    var builds = 0;
    var layouts = 0;
    final children = [
      CanvasWorldItem(
        rect: const Rect.fromLTWH(-100, -100, 400, 600),
        child: Builder(
          builder: (_) {
            builds++;
            return LayoutBuilder(
              builder: (_, constraints) {
                layouts++;
                return const ColoredBox(color: Colors.blue);
              },
            );
          },
        ),
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<CanvasCamera>(
            valueListenable: camera,
            builder: (_, value, _) =>
                CanvasWorldViewport(camera: value, children: children),
          ),
        ),
      ),
    );
    final initial = (builds, layouts);
    for (var frame = 1; frame <= 30; frame++) {
      camera.value = CanvasCamera(
        offset: Offset(frame * 2.0, frame * 3.0),
        scale: 1 + frame / 100,
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect((builds, layouts), initial);
    expect(tester.takeException(), isNull);
  });
}
