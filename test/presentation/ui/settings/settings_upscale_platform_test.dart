import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/settings_gpu_probe.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_upscale.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  SettingsViewData view(
    LocalUpscalePlatform platform, {
    SettingsGpuInfo? gpu,
  }) => SettingsFixture.view(page: SettingsPageId.upscale).copyWith(
    upscale: settingsUpscaleData(
      [
        for (final model in [...localUpscaleCatalog, ...advancedUpscaleCatalog])
          model.withInstalled(model.bundled),
      ],
      const SettingsUpscaleOperation(),
      const AdvancedUpscaleInstallState(),
      const UpscaleWorkflowSettings(),
      gpu: gpu,
      platform: platform,
    ),
  );

  test('only Windows offers SeedVR2 and RTX Video installs', () {
    for (final platform in [
      LocalUpscalePlatform.windows,
      LocalUpscalePlatform.macOS,
    ]) {
      final data = view(platform).upscale;
      final windows = platform == LocalUpscalePlatform.windows;
      expect(data.seedAvailable, windows);
      expect(data.rtxAvailable, windows);
      expect(data.esrgan.map((m) => m.id), [
        'animeQuality',
        'animeFast',
        'general',
      ]);
    }
  });

  for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
    testWidgets(
      'macOS keeps Real-ESRGAN downloads and disables Windows-only installs $locale',
      (t) async {
        final rec = await pumpSettings(
          t,
          data: view(LocalUpscalePlatform.macOS),
          window: 1600,
          height: 2400,
          locale: locale,
        );
        final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
        SettingsBtn button(Finder finder) => t.widget<SettingsBtn>(finder);
        for (final id in ['animeFast', 'general']) {
          expect(
            button(find.byKey(Key('upscale-install-$id'))).onTap,
            isNotNull,
          );
        }
        final windowsOnly = find.byWidgetPredicate(
          (widget) =>
              widget is SettingsBtn &&
              widget.label == l.set_install &&
              widget.onTap == null,
        );
        // Six SeedVR2 cards plus RTX Video.
        expect(windowsOnly, findsNWidgets(advancedUpscaleCatalog.length));
        for (final widget in t.widgetList<SettingsBtn>(windowsOnly)) {
          expect(widget.tooltip, l.localUpscale_unsupportedPlatform);
        }
        expect(find.text(l.localUpscale_unsupportedPlatform), findsNWidgets(2));
        expect(find.text(l.set_upSeedSub), findsNothing);
        expect(find.text(l.set_upRtxSub), findsNothing);
        await t.tap(find.byKey(const Key('upscale-install-seed3b')));
        await t.pumpAndSettle();
        expect(rec.calls.where((call) => call.startsWith('install:')), isEmpty);
        await t.tap(find.byKey(const Key('upscale-install-general')));
        await t.pumpAndSettle();
        expect(rec.calls, contains('install:general'));
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'the GPU card names the Apple chip and keeps the Windows and fallback text',
    (t) async {
      for (final (platform, gpu) in [
        (
          LocalUpscalePlatform.macOS,
          SettingsGpuProbe.parseMacChip('Apple M2 Max\n'),
        ),
        (LocalUpscalePlatform.macOS, null),
        (
          LocalUpscalePlatform.windows,
          SettingsGpuProbe.parse(
            'NVIDIA GeForce RTX 4070, 12282, 8.9',
            'CUDA Version: 12.6',
          ),
        ),
      ]) {
        await t.pumpWidget(const SizedBox.shrink());
        await pumpSettings(t, data: view(platform, gpu: gpu), height: 2400);
        final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
        final card = find.byKey(const Key('upscale-gpu'));
        String? title(String text) =>
            find
                .descendant(of: card, matching: find.text(text))
                .evaluate()
                .isEmpty
            ? null
            : text;
        expect(
          [
            title('Apple M2 Max'),
            title(l.set_upGpu('NVIDIA GeForce RTX 4070', '12')),
            title(l.set_upNoGpu),
          ].nonNulls,
          [
            gpu == null
                ? l.set_upNoGpu
                : platform == LocalUpscalePlatform.macOS
                ? 'Apple M2 Max'
                : l.set_upGpu('NVIDIA GeForce RTX 4070', '12'),
          ],
        );
        expect(
          find.descendant(of: card, matching: find.textContaining('0 GB')),
          findsNothing,
        );
        expect(t.takeException(), isNull);
      }
    },
  );

  testWidgets('Windows keeps every install action and description', (t) async {
    final rec = await pumpSettings(
      t,
      data: view(LocalUpscalePlatform.windows),
      window: 1600,
      height: 2400,
    );
    final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
    expect(find.text(l.localUpscale_unsupportedPlatform), findsNothing);
    expect(find.text(l.set_upSeedSub), findsOneWidget);
    expect(find.text(l.set_upRtxSub), findsOneWidget);
    await t.tap(find.byKey(const Key('upscale-install-seed3b')));
    await t.pumpAndSettle();
    expect(rec.calls, contains('install:seed3b'));
    expect(t.takeException(), isNull);
  });
}
