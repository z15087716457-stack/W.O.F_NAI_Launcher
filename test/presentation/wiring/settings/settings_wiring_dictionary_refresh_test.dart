import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/cache/cache_footprint.dart';
import 'package:nai_launcher/core/cache/gallery_cache_manager.dart';
import 'package:nai_launcher/core/constants/app_version.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/app_visibility.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/proxy_settings_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_caches.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_inventory.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_wiring.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../screens/settings/model_management_section_test.dart'
    show MemorySettings, MemorySecrets;

/// The settings screen itself (SettingsWiring) on the Dictionaries page, with
/// only the three counted values, storage and the system proxy stood in.
/// settings_dictionary_refresh_test.dart covers the refresh rules in detail;
/// this checks that the real page is wired to them.
class _Settings {
  _Settings({bool autoRefresh = true}) {
    if (!autoRefresh) {
      storage.values['settings_cache_stats_auto_refresh'] = false;
    }
  }

  final storage = MemorySettings();
  int dictionaries = 0, footprint = 0, stats = 0;
  List<int> get all => [dictionaries, footprint, stats];

  late final List<Override> _overrides = [
    localStorageServiceProvider.overrideWithValue(storage),
    secureStorageServiceProvider.overrideWithValue(MemorySecrets()),
    detectedSystemProxyProvider.overrideWith((ref) => null),
    settingsDictionaryDataProvider.overrideWith((ref) async {
      dictionaries++;
      return const SettingsDictionaryData(
        tagCount: 140000,
        dataVersion: 'fixture',
        wikiCount: 12000,
        cooccurrence: 3220000,
      );
    }),
    settingsCacheFootprintProvider.overrideWith((ref) async {
      footprint++;
      return const {
        SettingsCacheKind.danbooru: CacheFootprint(3, 300),
        SettingsCacheKind.translation: CacheFootprint(2, 200),
      };
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
        lastUpdated: DateTime(2026, 10, 30),
      );
    }),
  ];

  /// Shows [page]; switching pages of the same screen keeps its state, as
  /// clicking through the settings navigation does.
  Future<void> open(WidgetTester tester, SettingsPageId? page) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: _overrides,
          child: MaterialApp(
            locale: const Locale('zh'),
            theme: GeistTheme.light,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: page == null
                  ? const SizedBox()
                  : SettingsWiring(initialPage: page),
            ),
          ),
        ),
      );

  /// Reads the footprint on every refresh even off the page, so a timer that
  /// kept running would show up in the counts.
  ProviderSubscription<Object?> observe(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      ).listen(settingsCacheFootprintProvider, (_, __) {});
}

Future<void> _stay(WidgetTester tester, Duration time) async {
  const step = Duration(seconds: 10);
  for (var spent = Duration.zero; spent < time; spent += step) {
    await tester.pump(step);
  }
}

void main() {
  const platforms = TargetPlatformVariant({
    TargetPlatform.macOS,
    TargetPlatform.windows,
  });
  late Directory hive;

  setUpAll(() async {
    PackageInfo.setMockInitialValues(
      appName: 'nai_launcher',
      packageName: 'nai_launcher',
      version: '2.2.1',
      buildNumber: '1',
      buildSignature: '',
    );
    await AppVersion.initialize();
    hive = await Directory.systemTemp.createTemp('settings_wiring_hive_');
    Hive.init(hive.path);
    for (final box in [
      StorageKeys.settingsBox,
      StorageKeys.historyBox,
      StorageKeys.cacheBox,
      StorageKeys.tagCacheBox,
      StorageKeys.galleryBox,
      StorageKeys.statisticsCacheBox,
    ]) {
      await Hive.openBox(box);
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await hive.delete(recursive: true);
  });

  tearDown(() => AppVisibility.instance.debugSet(true));

  void sizeWindow(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1500, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'the Dictionaries page checks the bundled dictionaries once per visit, '
    'recounts the caches every 10 s and stops on another page',
    (tester) async {
      sizeWindow(tester);
      final settings = _Settings();
      await settings.open(tester, SettingsPageId.dictionaries);
      expect(settings.all, [1, 1, 1]);
      await tester.pump(const Duration(seconds: 10));
      expect(settings.all, [1, 2, 2]);
      await _stay(tester, const Duration(minutes: 1));
      expect(settings.all, [1, 8, 8]);

      await settings.open(tester, SettingsPageId.storage);
      final observer = settings.observe(tester);
      await _stay(tester, const Duration(minutes: 1));
      expect(settings.all, [1, 8, 8]);
      observer.close();

      await settings.open(tester, SettingsPageId.dictionaries);
      await tester.pump();
      expect(settings.dictionaries, 2);
    },
    variant: platforms,
  );

  testWidgets('with auto refresh off the page counts once and keeps it', (
    tester,
  ) async {
    sizeWindow(tester);
    final settings = _Settings(autoRefresh: false);
    await settings.open(tester, SettingsPageId.dictionaries);
    await _stay(tester, const Duration(minutes: 1));
    expect(settings.all, [1, 1, 1]);

    await settings.open(tester, SettingsPageId.storage);
    await settings.open(tester, SettingsPageId.dictionaries);
    await tester.pump();
    expect(settings.dictionaries, 1);
  }, variant: platforms);

  testWidgets('a hidden window pauses the page refresh', (tester) async {
    sizeWindow(tester);
    final settings = _Settings();
    await settings.open(tester, SettingsPageId.dictionaries);
    AppVisibility.instance.debugSet(false);
    await _stay(tester, const Duration(minutes: 10));
    expect(settings.all, [1, 1, 1]);

    AppVisibility.instance.debugSet(true);
    await tester.pump(Duration.zero);
    expect(settings.all, [1, 2, 2]);
  }, variant: platforms);

  testWidgets('closing settings stops the refresh', (tester) async {
    sizeWindow(tester);
    final settings = _Settings();
    await settings.open(tester, SettingsPageId.dictionaries);
    final observer = settings.observe(tester);
    await settings.open(tester, null);
    final closed = settings.footprint;
    await _stay(tester, const Duration(minutes: 1));
    expect(settings.footprint, closed);
    observer.close();
  }, variant: platforms);
}
