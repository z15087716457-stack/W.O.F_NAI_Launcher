import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets(
    'unknown cache sizes stay unknown; L3 count needs no invented hit rate',
    (t) async {
      for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
        await pumpSettings(
          t,
          data: _data(
            SettingsPageId.dictionaries,
            dictionaries: const SettingsDictionaryData(
              caches: {SettingsCacheKind.danbooru: (0, 0)},
              l3: SettingsCacheStat(hitRate: null, entries: 123, images: true),
            ),
          ),
          locale: locale,
          window: 1280,
        );
        final context = t.element(find.byKey(const Key('clear-translation')));
        final l = AppLocalizations.of(context)!;
        expect(find.text(l.set_dcImagesUnit('123')), findsOneWidget);
        expect(find.text('—'), findsWidgets);
        expect(find.text(l.set_dcCacheSize('0', '0 B')), findsOneWidget);
        expect(
          t
              .widget<SettingsBtn>(find.byKey(const Key('clear-translation')))
              .onTap,
          isNull,
        );
        expect(
          t.widget<SettingsBtn>(find.byKey(const Key('clear-danbooru'))).onTap,
          isNull,
        );
        expect(t.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'gallery source remains available before usage measurement finishes',
    (t) async {
      await pumpSettings(
        t,
        data: _data(
          SettingsPageId.storage,
          storage: const SettingsStorageData(
            computing: true,
            roots: [
              SettingsGalleryRoot(
                id: 'fixture',
                path: 'C:/fixture/images',
                images: 0,
                primary: true,
              ),
            ],
            thumbnailLimit: 1024 * 1024,
            folderNames: {SettingsFolder.images: 'images'},
          ),
        ),
      );
      expect(find.text('C:/fixture/images'), findsOneWidget);
      expect(find.text('0.0'), findsNothing);
      expect(find.text('—'), findsWidgets);
      expect(t.takeException(), isNull);
    },
  );
}

SettingsViewData _data(
  SettingsPageId page, {
  SettingsStorageData? storage,
  SettingsDictionaryData? dictionaries,
}) {
  final d = SettingsFixture.view(page: page);
  return SettingsViewData(
    page: page,
    values: d.values,
    now: d.now,
    version: d.version,
    options: d.options,
    account: d.account,
    canvas: d.canvas,
    shortcuts: d.shortcuts,
    generation: d.generation,
    storage: storage ?? d.storage,
    dictionaries: dictionaries ?? d.dictionaries,
    models: d.models,
    agent: d.agent,
    rag: d.rag,
    upscale: d.upscale,
    bridges: d.bridges,
    network: d.network,
    privacy: d.privacy,
    backup: d.backup,
    about: d.about,
  );
}
