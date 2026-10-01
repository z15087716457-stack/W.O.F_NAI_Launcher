import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/translation_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/translation_modified_badge.dart';

import '../../../helpers/studio_capture_fonts.dart';

TranslationIconPainter painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(TranslationIcon),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as TranslationIconPainter;

Widget sample({bool busy = false, bool reduced = false, bool ticking = true}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: TickerMode(
          enabled: ticking,
          child: Center(
            child: IconTheme(
              data: const IconThemeData(
                size: 16,
                color: Colors.blue,
                opacity: .5,
              ),
              child: TranslationIcon(busy: busy),
            ),
          ),
        ),
      ),
    );

void main() {
  test(
    'rotating arrows leave the central letter upright and stationary',
    () async {
      Future<List<int>> render(double phase) async {
        final recorder = ui.PictureRecorder();
        TranslationIconPainter(
          Colors.blue,
          AlwaysStoppedAnimation(phase),
        ).paint(Canvas(recorder), const Size(96, 96));
        final picture = recorder.endRecording();
        final image = await picture.toImage(96, 96);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final pixels = data!.buffer.asUint8List().toList();
        image.dispose();
        picture.dispose();
        return pixels;
      }

      List<int> center(List<int> pixels) => [
        for (var y = 32; y < 64; y++)
          for (var x = 34; x < 64; x++)
            ...pixels.sublist((y * 96 + x) * 4, (y * 96 + x) * 4 + 4),
      ];

      final idle = await render(0);
      final idleCenter = center(idle);
      expect(idleCenter.any((byte) => byte != 0), isTrue);
      for (final phase in [.125, .25, .375]) {
        final moving = await render(phase);
        expect(moving, isNot(idle));
        expect(center(moving), idleCenter);
      }
    },
  );

  testWidgets('busy cycles the arrow ring and completion resets', (
    tester,
  ) async {
    await tester.pumpWidget(sample());
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(TranslationIcon)), const Size(16, 16));
    expect(painter(tester).color.a, closeTo(.5, .01));
    expect(painter(tester).motion.value, 0);
    await tester.pumpWidget(sample(busy: true));
    await tester.pump(const Duration(milliseconds: 450));
    expect(painter(tester).motion.value, closeTo(.25, .01));
    await tester.pump(const Duration(milliseconds: 450));
    expect(painter(tester).motion.value, closeTo(.5, .01));
    await tester.pump(const Duration(milliseconds: 900));
    expect(painter(tester).motion.value, closeTo(0, .01));
    await tester.pumpWidget(sample());
    await tester.pumpAndSettle();
    expect(painter(tester).motion.value, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await _captureMotion(tester);
  });

  testWidgets(
    'reduced motion and hidden tickers stop the loop while preserving busy state',
    (tester) async {
      await tester.pumpWidget(sample(busy: true, reduced: true));
      await tester.pumpAndSettle();
      expect(painter(tester).motion.value, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(sample(busy: true));
      await tester.pump(const Duration(milliseconds: 450));
      expect(painter(tester).motion.value, greaterThan(0));
      await tester.pumpWidget(sample(busy: true, ticking: false));
      await tester.pumpAndSettle();
      expect(painter(tester).motion.value, 0);
      expect(
        tester.widget<TranslationIcon>(find.byType(TranslationIcon)).busy,
        isTrue,
      );
      await tester.pumpWidget(sample(busy: true));
      await tester.pump(const Duration(milliseconds: 450));
      expect(painter(tester).motion.value, greaterThan(0));
      await tester.pumpWidget(sample(busy: true, reduced: true));
      await tester.pumpAndSettle();
      expect(painter(tester).motion.value, 0);
    },
  );
}

Future<void> _captureMotion(WidgetTester tester) async {
  if (Platform.environment['CAPTURE_TRANSLATION_ICON'] != '1') return;
  await loadStudioCaptureFonts();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  final boundaryKey = GlobalKey();
  Widget preview(bool busy) => MaterialApp(
    theme: AppTheme.getTheme(AppStyle.geist, Brightness.light),
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: ColoredBox(
            color: Colors.white,
            child: SizedBox(
              width: 480,
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TranslationIcon(size: 18, color: Colors.grey, busy: busy),
                  TranslationIcon(size: 64, color: Colors.blue, busy: busy),
                  const TranslationModifiedBadge(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpWidget(preview(false));
  await tester.pumpAndSettle();
  await tester.pumpWidget(preview(true));
  for (var i = 0; i < 36; i++) {
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(
        '.dart_tool/translation-cycle-icon-captures/frame-${i.toString().padLeft(2, '0')}.png',
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpWidget(preview(false));
  await tester.pumpAndSettle();
}
