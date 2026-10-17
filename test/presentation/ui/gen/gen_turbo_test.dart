import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_header.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_parts.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  GenViewData data({required bool? turbo, bool furry = false}) =>
      GenFixture.view().copyWith(
        model: turbo == true
            ? ImageModels.animeDiffusionV5FullMedium
            : ImageModels.animeDiffusionV5Full,
        displayModel: ImageModels.animeDiffusionV5Full,
        models: const [
          GenModel(id: ImageModels.animeDiffusionV5Full, name: 'V5 Full'),
          GenModel(id: ImageModels.animeDiffusionV5Curated, name: 'V5 Curated'),
        ],
        turbo: turbo,
        clearTurbo: turbo == null,
        furry: furry,
        prompt: GenPromptData(negativeSupported: turbo != true),
        params: GenParamsData(
          steps: turbo == true ? 14 : 37,
          fixedSampling: turbo == true,
          cfgRescaleSupported: turbo != true,
          sampler: Samplers.kEulerAncestral,
        ),
      );
  for (final locale in AppLocalizations.supportedLocales) {
    for (final dark in [false, true]) {
      for (final width in [1100.0, 1600.0]) {
        testWidgets('Turbo capsule $locale dark=$dark width=$width', (t) async {
          final r = GenRecorder();
          for (final furry in [false, true]) {
            for (final active in <bool?>[false, true, null]) {
              await pumpGen(
                t,
                data: data(turbo: active, furry: furry),
                actions: r.actions,
                locale: locale.toString(),
                dark: dark,
                window: width,
                height: 760,
              );
              final capsule = find.byKey(const Key('gen-model-capsule'));
              // Measured from the original capsule with the same bundled font.
              expect(
                t.getSize(capsule).width,
                closeTo(furry ? 212.024 : 217.172, .02),
              );
              expect(t.getSize(find.byKey(const Key('gen-header'))).height, 37);
              expect(
                find.descendant(
                  of: capsule,
                  matching: find.text(furry ? 'F' : 'A'),
                ),
                findsOneWidget,
              );
              expect(
                find.descendant(of: capsule, matching: find.text('V5 Full')),
                findsOneWidget,
              );
              final count = r.calls
                  .where((s) => s.startsWith('onTurboChanged'))
                  .length;
              await t.tap(find.byKey(const Key('gen-turbo')));
              await t.pumpAndSettle();
              expect(
                r.calls.where((s) => s.startsWith('onTurboChanged')).length,
                count + (active == null ? 0 : 1),
              );
              if (active != null) {
                expect(r.last('onTurboChanged'), 'onTurboChanged(${!active})');
              }
              final negative = t.widget<GenTab>(
                find.byKey(const Key('gen-tab-negative')),
              );
              expect(negative.onTap == null, active == true);
              expect(t.takeException(), isNull);
              if (locale.languageCode == 'zh' &&
                  locale.countryCode == null &&
                  !furry &&
                  width == 1100) {
                await captureUiuxRegion(
                  t,
                  find.byKey(const Key('gen-capture')),
                  'turbo-${active ?? 'unavailable'}-${dark ? 'dark' : 'light'}',
                  t.getRect(find.byKey(const Key('gen-header'))),
                );
              }
            }
          }
        });
      }
    }
  }
  testWidgets('character negative selection survives Full Turbo Full', (
    t,
  ) async {
    const key = Key('gen-character-tab-neg-0');
    GenTab negative() => t.widget<GenTab>(find.byKey(key));
    await pumpGen(t, data: data(turbo: false));
    await tapKey(t, 'gen-character-tab-neg-0');
    expect(negative().selected, isTrue);
    await pumpGen(t, data: data(turbo: true));
    expect(negative().selected, isFalse);
    expect(negative().onTap, isNull);
    await pumpGen(t, data: data(turbo: false));
    expect(negative().selected, isTrue);
    expect(negative().onTap, isNotNull);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'Turbo drawer hides fixed controls and preserves adjustable guidance',
    (t) async {
      await pumpGen(t, data: data(turbo: true));
      await tapKey(t, 'gen-params-toggle');
      expect(find.byKey(const Key('gen-drawer-steps')), findsNothing);
      expect(find.byKey(const Key('gen-drawer-sampler')), findsNothing);
      expect(find.byKey(const Key('gen-drawer-rescale')), findsNothing);
      expect(find.byKey(const Key('gen-drawer-scale')), findsOneWidget);
      expect(find.byType(GenHeader), findsOneWidget);
    },
  );
}
