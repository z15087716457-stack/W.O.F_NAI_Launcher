import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_canvas.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_parts.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'gen_test_harness.dart';

class _Stripes extends CustomPainter {
  const _Stripes({this.color = Colors.black});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (var x = 0.0; x < size.width; x += 4) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 4, size.height),
        Paint()..color = (x ~/ 4).isEven ? color : Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_Stripes old) => old.color != color;
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets('三条独立深色玻璃实时取样，页面主题不变', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final key = GlobalKey();
    final base = GenFixture.view();
    for (final dark in [false, true]) {
      final samples = <List<int>>[];
      for (final color in [Colors.blue, Colors.red]) {
        await tester.pumpWidget(
          genApp(
            RepaintBoundary(
              key: key,
              child: GenHost(
                data: base,
                actions: GenActions.logging((_) {}),
                slots: GenSlots(
                  editor: (_, _) => const SizedBox.shrink(),
                  canvas: (_, _) =>
                      CustomPaint(painter: _Stripes(color: color)),
                ),
                child: const GenCanvas(),
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(GenCanvas))).brightness,
          dark ? Brightness.dark : Brightness.light,
        );
        expect(find.byType(BackdropFilter), findsNWidgets(3));
        final values = <int>[];
        for (final name in ['gen-bar-top', 'gen-bar-info', 'gen-bar-actions']) {
          final bar = find.byKey(Key(name));
          expect(Theme.of(tester.element(bar)).brightness, Brightness.dark);
          final rect = tester.getRect(bar);
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final bitmap = await boundary.toImage();
            final data = (await bitmap.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            final at =
                ((rect.bottom.toInt() - 3) * bitmap.width +
                    rect.center.dx.toInt()) *
                4;
            values.addAll([data.getUint8(at), data.getUint8(at + 2)]);
            bitmap.dispose();
          });
        }
        samples.add(values);
        if (color == Colors.blue) {
          await captureUiuxRegion(
            tester,
            find.byKey(key),
            'float-charcoal-${dark ? 'dark' : 'light'}',
            tester.getRect(find.byKey(const Key('gen-bar-top'))).inflate(20),
          );
        }
        expect(tester.takeException(), isNull);
      }
      for (var i = 0; i < 6; i += 2) {
        expect(samples[0][i + 1], greaterThan(samples[0][i] + 20));
        expect(samples[1][i], greaterThan(samples[1][i + 1] + 20));
        expect(samples[0][i + 1], lessThan(160));
      }
    }
  });
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
            child: const Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _Stripes())),
                Positioned(
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
    expect(
      find.descendant(
        of: find.byKey(const Key('gen-variations-cost')),
        matching: find.text('—'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
      testWidgets('变体报价切换保持工具条位置 $locale dark=$dark', (tester) async {
        final base = GenFixture.view();
        final info = base.canvas.info!;
        final recorder = GenRecorder();
        Rect? bar, slot;
        var index = 0;
        for (final (price, loading) in <(int?, bool)>[
          (48, false),
          (null, true),
          (9, false),
          (null, false),
          (0, false),
          (9999, false),
          (123456, false),
          (48, false),
        ]) {
          await pumpGen(
            tester,
            dark: dark,
            locale: locale,
            window: 1100,
            actions: recorder.actions,
            data: base.copyWith(
              canvas: GenCanvasData(
                focus: base.canvas.focus,
                info: GenFocusInfo(
                  tileId: 'scroll-${index++}',
                  width: info.width,
                  height: info.height,
                  variationsCost: price,
                  variationsCostLoading: loading,
                ),
                upscale: const GenUpscale(selected: 'local:test'),
              ),
            ),
          );
          final currentBar = tester.getRect(
            find.byKey(const Key('gen-bar-top')),
          );
          final currentSlot = tester.getRect(
            find.byKey(const Key('gen-variations-cost')),
          );
          bar ??= currentBar;
          slot ??= currentSlot;
          expect(currentBar, bar);
          expect(currentSlot, slot);
          expect(
            find.descendant(
              of: find.byKey(const Key('gen-variations-cost')),
              matching: find.text(price?.toString() ?? (loading ? '…' : '—')),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          if (locale == 'zh' && index <= 4) {
            await captureUiuxRegion(
              tester,
              find.byKey(const Key('gen-capture')),
              'variation-${dark ? 'dark' : 'light'}-${loading ? 'loading' : price ?? 'unavailable'}',
              currentBar.inflate(22),
            );
          }
        }
        await tapKey(tester, 'gen-variations');
        expect(recorder.called('onVariations'), isTrue);
      });
    }
  }

  for (final width in [280.0, 440.0]) {
    testWidgets('放大字体与窄画布保持价签占位 width=$width', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final base = GenFixture.view();
      final info = base.canvas.info!;
      Rect? previous;
      for (final price in <int?>[48, null, 9999, 0]) {
        final data = base.copyWith(
          canvas: GenCanvasData(
            focus: base.canvas.focus,
            info: GenFocusInfo(
              tileId: info.tileId,
              width: info.width,
              height: info.height,
              variationsCost: price,
              variationsCostLoading: price == null,
            ),
            upscale: const GenUpscale(selected: 'local:test'),
          ),
        );
        await tester.pumpWidget(
          genApp(
            GenHost(
              data: data,
              actions: GenActions.logging((_) {}),
              slots: GenSlots(
                editor: (_, _) => const SizedBox.shrink(),
                canvas: (_, _) => const SizedBox.expand(),
              ),
              child: const GenCanvas(),
            ),
            locale: 'en',
          ),
        );
        await tester.pumpAndSettle();
        final slot = tester.getRect(
          find.byKey(const Key('gen-variations-cost')),
        );
        previous ??= slot;
        expect(slot, previous);
        expect(tester.takeException(), isNull);
      }
    });
  }
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
