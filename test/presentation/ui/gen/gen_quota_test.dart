import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_glyph.dart';
import 'package:nai_launcher/presentation/utils/opus_usage_presentation.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in AppLocalizations.supportedLocales) {
    for (final dark in [false, true]) {
      for (final width in [1100.0, 1600.0]) {
        testWidgets('quota states / $locale / dark=$dark / width=$width', (
          t,
        ) async {
          final l = lookupAppLocalizations(locale);
          final c = UiColors.fromTheme(
            dark ? GeistTheme.dark : GeistTheme.light,
          );
          final recorder = GenRecorder();
          final states = [
            (
              'normal',
              const OpusUsage(percent: 50, purchasedPercent: 200),
              c.accent,
            ),
            (
              'reserve-same-number',
              const OpusUsage(purchasedPercent: 50),
              c.quotaReserve,
            ),
            (
              'blue-boundary',
              const OpusUsage(percent: 20, purchasedPercent: 200),
              c.accent,
            ),
            (
              'yellow',
              const OpusUsage(percent: 19.9, purchasedPercent: 200),
              c.warn,
            ),
            ('yellow-boundary', const OpusUsage(percent: 5), c.warn),
            (
              'red',
              const OpusUsage(percent: 4.9, purchasedPercent: 200),
              c.error,
            ),
            (
              'reserve',
              const OpusUsage(
                purchasedPercent: 200.5,
                timeUntilNextPercent: 90,
              ),
              c.quotaReserve,
            ),
            ('empty', const OpusUsage(isNegative: true), c.error),
          ];
          for (final (name, usage, color) in states) {
            await pumpGen(
              t,
              window: width,
              height: 700,
              dark: dark,
              locale: locale.toString(),
              actions: recorder.actions,
              data: GenFixture.view().copyWith(
                quota: GenQuota(
                  opusPercent: usage.activePercent,
                  opusUsingReserve: usage.isUsingReserve,
                  opusTip: opusUsageTooltip(l, usage),
                  anlas: 9736,
                  subscriptionAnlas: 7518,
                  purchasedAnlas: 2218,
                ),
              ),
            );
            final quota = find.byKey(const Key('gen-quota'));
            final bolt = find.descendant(
              of: quota,
              matching: find.byType(UiGlyph),
            );
            expect(t.widget<UiGlyph>(bolt).color, color, reason: name);
            final number =
                usage.activePercent == usage.activePercent.roundToDouble()
                ? '${usage.activePercent.round()}%'
                : '${usage.activePercent.toStringAsFixed(1)}%';
            expect(
              find.descendant(of: quota, matching: find.text(number)),
              findsOneWidget,
            );
            expect(
              find.descendant(of: quota, matching: find.text('9,736')),
              findsOneWidget,
            );
            final tooltip = t.widget<Tooltip>(
              find.ancestor(of: quota, matching: find.byType(Tooltip)),
            );
            expect(
              tooltip.message,
              contains(
                l.opusUsage_regularRemaining(
                  usage.regularPercent.toStringAsFixed(1),
                ),
              ),
            );
            expect(
              tooltip.message,
              contains(
                l.opusUsage_reserveRemaining(
                  usage.reservePercent.toStringAsFixed(1),
                ),
              ),
            );
            expect(tooltip.message, contains('7,518'));
            expect(tooltip.message, contains('2,218'));
            expect(t.getSize(find.byKey(const Key('gen-header'))).height, 37);
            expect(t.takeException(), isNull, reason: name);
            if (locale.languageCode == 'zh' &&
                locale.countryCode == null &&
                width == 1100) {
              await captureUiuxRegion(
                t,
                find.byKey(const Key('gen-capture')),
                'quota-$name-${dark ? 'dark' : 'light'}',
                t.getRect(find.byKey(const Key('gen-header'))),
              );
            }
            if (name == 'reserve') {
              final mouse = await t.createGesture(
                kind: PointerDeviceKind.mouse,
              );
              await mouse.addPointer(location: Offset.zero);
              await mouse.moveTo(t.getCenter(quota));
              await t.pump(const Duration(seconds: 1));
              await t.pump(const Duration(milliseconds: 200));
              expect(find.text(tooltip.message!), findsOneWidget);
              expect(t.takeException(), isNull);
              if (width == 1100) {
                await captureUiuxRegion(
                  t,
                  find.byKey(const Key('gen-capture')),
                  'quota-hover-${locale.toString()}-${dark ? 'dark' : 'light'}',
                  const Rect.fromLTWH(0, 0, 1052, 270),
                );
              }
              await mouse.removePointer();
              await t.pumpAndSettle();
              await t.tap(quota);
              await t.pump();
              expect(recorder.called('onOpenQuota'), isTrue);
            }
          }
        });
      }
    }
  }
}
