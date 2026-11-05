import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/cache/gallery_cache_manager.dart';
import 'package:nai_launcher/core/constants/app_version.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/app_visibility.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_page.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_caches.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_dictionary_update.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_inventory.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_wiring.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../screens/settings/model_management_section_test.dart'
    show MemorySettings, MemorySecrets;

class _Updater extends SettingsDictionaryUpdater {
  int checks = 0;

  @override
  SettingsDictionaryUpdate build() => const SettingsDictionaryUpdate();

  @override
  Future<void> check() async => checks++;
}

void main() {
  late Directory hive;
  setUpAll(() async {
    PackageInfo.setMockInitialValues(
      appName: 'nai_launcher',
      packageName: 'nai_launcher',
      version: '2.2.6',
      buildNumber: '83',
      buildSignature: '',
    );
    await AppVersion.initialize();
    hive = await Directory.systemTemp.createTemp('settings-refresh-');
    Hive.init(hive.path);
    for (final name in [
      StorageKeys.settingsBox,
      StorageKeys.historyBox,
      StorageKeys.cacheBox,
      StorageKeys.tagCacheBox,
      StorageKeys.galleryBox,
      StorageKeys.statisticsCacheBox,
    ]) {
      await Hive.openBox(name);
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await hive.delete(recursive: true);
  });

  testWidgets(
    'dictionaries check on visits and manual refresh, cache timer follows visibility and the switch',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1500, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final visibility = AppVisibility.instance;
      addTearDown(() => visibility.onWindowEvent('show'));
      var dictionaries = 0, footprint = 0, stats = 0;
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(MemorySettings()),
          secureStorageServiceProvider.overrideWithValue(MemorySecrets()),
          settingsDictionaryUpdateProvider.overrideWith(_Updater.new),
          settingsDictionaryDataProvider.overrideWith((ref) async {
            dictionaries++;
            return const SettingsDictionaryData(tagCount: 140000);
          }),
          settingsCacheFootprintProvider.overrideWith((ref) async {
            footprint++;
            return const {};
          }),
          settingsCacheStatsProvider.overrideWith((ref) async {
            stats++;
            return CacheStatistics(
              l1MemorySize: 2,
              l1HitRate: .5,
              l1MemoryBytes: 4,
              l2HiveSize: 5,
              l2HitRate: .5,
              l2HiveBytes: 6,
              l3DatabaseImageCount: 9,
              l3DatabaseMetadataCount: 8,
              totalHitRate: .5,
              lastUpdated: DateTime(2026, 11, 5),
            );
          }),
        ],
      );
      addTearDown(container.dispose);
      final footprintWatcher = container.listen(
        settingsCacheFootprintProvider,
        (_, _) {},
      );
      addTearDown(footprintWatcher.close);

      Future<void> open(SettingsPageId page) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: const Locale('zh'),
              theme: GeistTheme.light,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: SettingsWiring(initialPage: page)),
            ),
          ),
        );
        await tester.pump();
      }

      await open(SettingsPageId.dictionaries);
      expect((dictionaries, footprint, stats), (1, 1, 1));
      await tester.pump(const Duration(seconds: 10));
      expect((dictionaries, footprint, stats), (1, 2, 2));

      visibility.onWindowEvent('hide');
      await tester.pump(const Duration(seconds: 30));
      expect((dictionaries, footprint, stats), (1, 2, 2));
      visibility.onWindowEvent('show');
      await tester.pump(const Duration(seconds: 10));
      expect((dictionaries, footprint, stats), (1, 3, 3));

      final actions = tester
          .widget<SettingsPage>(find.byType(SettingsPage))
          .actions;
      actions.onCheckDictionaryUpdates();
      await tester.pump();
      expect(dictionaries, 2);
      expect(
        (container.read(settingsDictionaryUpdateProvider.notifier) as _Updater)
            .checks,
        1,
      );

      actions.onChanged(SettingKey.cacheStatsAutoRefresh, false);
      await tester.pump();
      final before = (footprint, stats);
      await tester.pump(const Duration(seconds: 30));
      expect((footprint, stats), before);

      await open(SettingsPageId.shortcuts);
      await tester.pump(const Duration(seconds: 10));
      expect((footprint, stats), before);
      await open(SettingsPageId.dictionaries);
      expect(dictionaries, 3);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
