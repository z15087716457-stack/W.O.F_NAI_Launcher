import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/tag_candidate_title.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_retranslate_button.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/translation_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/translation_modified_badge.dart';

import '../../../helpers/studio_capture_fonts.dart';

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
  for (final scale in [1.0, 1.5, 2.0]) {
    for (final size in [14.0, 28.0]) {
      for (final wrapped in [false, true]) {
        testWidgets(
          'translation artwork is centered next to $size text at $scale scale; wrapped=$wrapped',
          (tester) async {
            await tester.runAsync(loadStudioCaptureFonts);
            final boundary = GlobalKey();
            final activity = _Activity()
              ..activity = const TagTranslationActivity(
                TagTranslationPhase.queued,
              );
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  autoTagTranslationProvider.overrideWith((_) => activity),
                ],
                child: MaterialApp(
                  locale: const Locale('zh'),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  theme: AppTheme.getTheme(AppStyle.geist, Brightness.light),
                  home: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: Scaffold(
                      body: Center(
                        child: RepaintBoundary(
                          key: boundary,
                          child: TagCandidateTitle(
                            title: 'blue eyes',
                            maxLines: wrapped ? null : 1,
                            category: TagCategory.general,
                            showCategory: false,
                            style: TextStyle(
                              fontSize: size,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                            trailing: const TagTranslationIndicator(
                              tag: 'blue_eyes',
                              surface: 'alignment',
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final text = tester.getRect(find.text('blue eyes'));
            final icon = tester.getRect(find.byType(TranslationIcon));
            final slot = tester.getRect(find.byType(TagTranslationIndicator));
            expect(slot.center.dy, closeTo(text.center.dy, .5));
            // 光学偏移随标题字号等比：14 号 1.5，28 号 3。
            expect(
              icon.center.dy,
              closeTo(slot.center.dy + 1.5 * size / 14 * scale, .5),
            );
            await tester.runAsync(() async {
              final render =
                  boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await render.toImage(pixelRatio: 1);
              final data = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!.buffer.asUint8List();
              var top = image.height;
              var bottom = -1;
              for (var y = 0; y < image.height; y++) {
                for (var x = 0; x < text.width.floor(); x++) {
                  final index = (y * image.width + x) * 4;
                  if (data[index + 3] > 80 &&
                      data[index] < 100 &&
                      data[index + 2] < 100) {
                    if (y < top) top = y;
                    if (y > bottom) bottom = y;
                  }
                }
              }
              expect(bottom, greaterThan(top));
              final inkCenter =
                  tester.getRect(find.byKey(boundary)).top +
                  (top + bottom + 1) / 2;
              expect(icon.center.dy, closeTo(inkCenter, 1.5 * scale));
              image.dispose();
            });
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
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
          expect(find.byType(TranslationIcon), findsOneWidget);
          expect(tester.getRect(slot), rect);
          activity.activity = const TagTranslationActivity(
            TagTranslationPhase.translating,
          );
          activity.notifyListeners();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 450));
          expect(find.byType(TranslationIcon), findsOneWidget);
          expect(find.byTooltip(l10n.wiki_translating), findsOneWidget);
          activity.activity = const TagTranslationActivity(
            TagTranslationPhase.failed,
            error: 'request failed',
          );
          activity.notifyListeners();
          await tester.pumpAndSettle();
          expect(find.byType(TranslationIcon), findsOneWidget);
          expect(
            tester.widget<TranslationIcon>(find.byType(TranslationIcon)).color,
            Theme.of(context).colorScheme.error,
          );
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

  TranslationIconPainter cycle(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byType(TranslationIcon),
                  matching: find.byWidgetPredicate(
                    (w) =>
                        w is CustomPaint && w.painter is TranslationIconPainter,
                  ),
                ),
              )
              .painter!
          as TranslationIconPainter;

  testWidgets(
    'language glyph and cycle retain slot and alpha; completion stops',
    (tester) async {
      await tester.pumpWidget(sample());
      await tester.pumpAndSettle();
      final slot = tester.getRect(find.byType(TranslationIcon));
      expect(slot.size, const Size(16, 16));
      expect(find.byIcon(Icons.translate), findsOneWidget);
      await tester.pumpWidget(sample(busy: true));
      await tester.pump();
      expect(tester.getRect(find.byType(TranslationIcon)), slot);
      expect(cycle(tester).color, Colors.blue.withValues(alpha: .5));
      await tester.pump(const Duration(milliseconds: 450));
      final first = cycle(tester).motion.value;
      expect(first, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 450));
      expect(cycle(tester).motion.value, greaterThan(first));
      expect(tester.getRect(find.byType(TranslationIcon)), slot);
      await tester.pumpWidget(sample());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.translate), findsOneWidget);
      expect(tester.getRect(find.byType(TranslationIcon)), slot);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await _captureMotion(tester);
    },
  );

  testWidgets(
    'cycle stops for reduced motion and hidden tickers, then resumes',
    (tester) async {
      for (final disabled in [true, false]) {
        await tester.pumpWidget(
          sample(busy: true, reduced: disabled, ticking: disabled),
        );
        await tester.pumpAndSettle();
        expect(cycle(tester).motion.value, 0);
        expect(tester.binding.hasScheduledFrame, isFalse);
      }
      await tester.pumpWidget(sample(busy: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(cycle(tester).motion.value, greaterThan(0));
      await tester.pumpWidget(sample(busy: true, reduced: true));
      await tester.pumpAndSettle();
      expect(cycle(tester).motion.value, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
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
