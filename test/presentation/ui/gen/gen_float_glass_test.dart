import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_parts.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

class _Stripes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (var x = 0.0; x < size.width; x += 4) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 4, size.height),
        Paint()..color = (x ~/ 4).isEven ? Colors.black : Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_Stripes old) => false;
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final dark in [false, true]) {
    testWidgets('玻璃只模糊背后的图像 dark=$dark', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(300, 100);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? GeistTheme.dark : GeistTheme.light,
          home: RepaintBoundary(
            key: key,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _Stripes())),
                const Positioned(
                  left: 40,
                  top: 30,
                  child: GenFloat(children: [SizedBox(width: 120, height: 30)]),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(tester.getSize(find.byType(GenFloat)), const Size(130, 38));
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        int range(int y) {
          final values = [
            for (var x = 100; x < 116; x++) data.getUint8((y * 300 + x) * 4),
          ];
          values.sort();
          return values.last - values.first;
        }

        expect(range(10), 255);
        expect(range(48), lessThan(30));
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    });
    testWidgets('高对比度保留工具条控件并使用清晰底色 dark=$dark', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? GeistTheme.dark : GeistTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(highContrast: true),
            child: child!,
          ),
          home: const Scaffold(
            body: Center(child: GenFloat(children: [Text('7')])),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('7'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final price in [0, 12]) {
    testWidgets('变体显示 $price Anlas 胶囊，放大仍显示免费', (tester) async {
      final base = GenFixture.view();
      final info = base.canvas.info!;
      final recorder = GenRecorder();
      await pumpGen(
        tester,
        data: base.copyWith(
          canvas: GenCanvasData(
            focus: base.canvas.focus,
            info: GenFocusInfo(
              tileId: info.tileId,
              width: info.width,
              height: info.height,
              variationsCost: price,
            ),
            upscale: const GenUpscale(selected: 'local:test'),
          ),
        ),
        actions: recorder.actions,
        window: 1100,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('gen-variations-cost')),
          matching: find.text('$price'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('gen-upscale-cost')),
          matching: find.text('免费'),
        ),
        findsOneWidget,
      );
      expect(find.byType(BackdropFilter), findsNWidgets(3));
      await tapKey(tester, 'gen-variations');
      expect(recorder.called('onVariations'), isTrue);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('云端报价缺失时不显示免费', (tester) async {
    final base = GenFixture.view();
    await pumpGen(
      tester,
      data: base.copyWith(
        canvas: GenCanvasData(
          focus: base.canvas.focus,
          info: base.canvas.info,
          upscale: const GenUpscale(selected: 'novelai', available: false),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('gen-upscale-cost')),
        matching: find.text('—'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('gen-variations-cost')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('云端放大保留数字与 Anlas 胶囊及原执行回调', (tester) async {
    final base = GenFixture.view();
    final recorder = GenRecorder();
    await pumpGen(
      tester,
      actions: recorder.actions,
      data: base.copyWith(
        canvas: GenCanvasData(
          focus: base.canvas.focus,
          info: base.canvas.info,
          upscale: const GenUpscale(selected: 'novelai', cost: 7),
        ),
      ),
    );
    final badge = find.byKey(const Key('gen-upscale-cost'));
    expect(
      find.descendant(of: badge, matching: find.text('7')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: badge, matching: find.byType(GenAnlas)),
      findsOneWidget,
    );
    await tapKey(tester, 'gen-upscale');
    expect(recorder.called('onUpscale'), isTrue);
    expect(tester.takeException(), isNull);
  });
}
