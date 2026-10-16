import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('quota breakdown and Vibe hints $locale dark=$dark', (
        t,
      ) async {
        await pumpGen(
          t,
          data: GenFixture.view(v45: true).copyWith(
            quota: GenQuota(
              anlas: 10668,
              subscriptionAnlas: dark ? 10668 : 10000,
              purchasedAnlas: dark ? 0 : 668,
            ),
          ),
          locale: locale,
          dark: dark,
        );
        final quota = find.byKey(const Key('gen-quota'));
        final l = AppLocalizations.of(t.element(quota))!;
        final message =
            '${l.gen_anlasTip('10,668')}\n'
            '${l.anlas_subscription}: ${dark ? '10,668' : '10,000'}\n'
            '${l.anlas_purchased}: ${dark ? '0' : '668'}';
        final pointer = await hoverOver(t, quota);
        await t.pump(const Duration(seconds: 1));
        expect(find.text(message), findsOneWidget);
        expect(t.takeException(), isNull);
        await captureUiuxRegion(
          t,
          find.byKey(const Key('gen-capture')),
          'quota-$locale-$dark',
          const Rect.fromLTWH(0, 0, 650, 210),
        );
        await pointer.moveTo(Offset.zero);
        await t.pumpAndSettle();
        await t.ensureVisible(find.byKey(const Key('gen-ref-vibe-row')));
        await tapKey(t, 'gen-ref-vibe-row');
        final info = find.byKey(const Key('gen-vibe-info-v1'));
        final label = find.descendant(of: info, matching: find.byType(Tooltip));
        await t.ensureVisible(label);
        await pointer.moveTo(t.getCenter(label));
        await t.pumpAndSettle();
        await t.pump(const Duration(seconds: 1));
        expect(find.text(l.gen_vibeInfoReencode), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      });
      for (final width in [352.0, 420.0, 560.0]) {
        testWidgets('generation $locale dark=$dark left=$width', (t) async {
          final data = GenFixture.view(layout: GenLayout(leftWidth: width));
          final recorder = GenRecorder();
          await pumpGen(
            t,
            data: data,
            actions: recorder.actions,
            locale: locale,
            dark: dark,
            window: 1600,
          );
          expect(t.takeException(), isNull);
          final module = t.getRect(find.byKey(const Key('gen-image')));
          for (final name in [
            'gen-size-group',
            'gen-orientation',
            'gen-width',
            'gen-height',
          ]) {
            final rect = t.getRect(find.byKey(Key(name)));
            expect(rect.left, greaterThanOrEqualTo(module.left));
            expect(rect.right, lessThanOrEqualTo(module.right));
          }
          await captureUiuxRegion(
            t,
            find.byKey(const Key('gen-capture')),
            'gen-$locale-$dark-$width',
            module,
          );
          await tapKey(t, 'gen-orientation-landscape');
          expect(recorder.called('onSizeChanged'), isTrue);
          await tapKey(t, 'gen-swap-size');
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
