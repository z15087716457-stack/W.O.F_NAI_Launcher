import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_retranslate_button.dart';
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

class _Activity extends ChangeNotifier implements AutoTagTranslationController {
  TagTranslationActivity? activity;
  int retries = 0;
  @override
  TagTranslationActivity? activityFor(String tag, {bool wiki = false}) =>
      activity;
  @override
  void retranslateName({required String surface, required String tag}) {
    retries++;
    activity = const TagTranslationActivity(TagTranslationPhase.queued);
    notifyListeners();
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

void main() {
  for (final locale in const [
    Locale('zh'),
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'inline translation state is localized and stable in $locale $brightness',
        (tester) async {
          await tester.runAsync(loadStudioCaptureFonts);
          final activity = _Activity();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                autoTagTranslationProvider.overrideWith((_) => activity),
              ],
              child: MaterialApp(
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: AppTheme.getTheme(AppStyle.geist, brightness),
                home: const Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: 160,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'long original tag name',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TagTranslationIndicator(
                            tag: 'long_original_tag',
                            surface: 'test',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          final slot = find.byType(TagTranslationIndicator);
          final rect = tester.getRect(slot);
          expect(find.byType(TranslationIcon), findsNothing);
          activity.activity = const TagTranslationActivity(
            TagTranslationPhase.queued,
          );
          activity.notifyListeners();
          await tester.pumpAndSettle();
          final context = tester.element(slot);
          final l10n = AppLocalizations.of(context)!;
          expect(find.byTooltip(l10n.wiki_translationQueued), findsOneWidget);
          expect(painter(tester).motion.value, 0);
          expect(tester.getRect(slot), rect);
          activity.activity = const TagTranslationActivity(
            TagTranslationPhase.translating,
          );
          activity.notifyListeners();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 450));
          expect(painter(tester).motion.value, greaterThan(0));
          expect(find.byTooltip(l10n.wiki_translating), findsOneWidget);
          activity.activity = const TagTranslationActivity(
            TagTranslationPhase.failed,
            error: 'request failed',
          );
          activity.notifyListeners();
          await tester.pumpAndSettle();
          expect(painter(tester).motion.value, 0);
          expect(painter(tester).color, Theme.of(context).colorScheme.error);
          final retry = find.byTooltip(
            '${l10n.wiki_translationFailedRetry}\nrequest failed',
          );
          await tester.tap(retry);
          await tester.pumpAndSettle();
          expect(activity.retries, 1);
          expect(find.byTooltip(l10n.wiki_translationQueued), findsOneWidget);
          expect(tester.getRect(slot), rect);
          activity.activity = null;
          activity.notifyListeners();
          await tester.pumpAndSettle();
          expect(find.byType(TranslationIcon), findsNothing);
          expect(tester.getRect(slot), rect);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

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
