import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/cache/gallery_cache_manager.dart';
import 'package:nai_launcher/core/constants/app_version.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/rag/rag_runtime_probe.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_rag.dart';
import 'package:nai_launcher/core/services/app_visibility.dart';
import 'package:nai_launcher/core/services/settings_gpu_probe.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_upscale.dart';
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

class _Rag extends RagController {
  final starts = <(String, RagSource, bool)>[];
  final resumes = <RagSource>[];

  @override
  RagStatus build() => const RagStatus(
    phase: 'ready',
    indexKnown: true,
    sources: {
      RagSource.wiki: RagStatus(indexKnown: true),
      RagSource.blocks: RagStatus(indexKnown: true, indexed: 12, total: 12),
      RagSource.gallery: RagStatus(indexKnown: true, phase: 'paused'),
    },
  );

  @override
  Future<Map<String, dynamic>> preview({
    RagSource source = RagSource.tags,
    bool verify = true,
  }) async => {'plan_id': source.name, 'documents': 22, 'total': 30};

  @override
  Future<void> start(
    String planId, {
    bool rebuild = false,
    RagSource source = RagSource.tags,
  }) async => starts.add((planId, source, rebuild));

  @override
  Future<void> resume({RagSource source = RagSource.tags}) async =>
      resumes.add(source);
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
    'RAG build and rebuild use the inline plan, resume runs directly',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1500, 1200);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final storage = MemorySettings();
      await storage.setSetting(
        RagSettingsController.storageKey,
        '{"version":1,"enabled":true}',
      );
      final rag = _Rag();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storage),
            secureStorageServiceProvider.overrideWithValue(MemorySecrets()),
            ragControllerProvider.overrideWith(() => rag),
            ragRuntimeInfoProvider.overrideWith(
              (ref) async =>
                  const RagRuntimeInfo(python: 'fixture', ready: true),
            ),
            settingsIndexBytesProvider.overrideWith((ref) async => 0),
            settingsRagWeightsProvider.overrideWith((ref) async => true),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            theme: GeistTheme.light,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(
              body: SettingsWiring(initialPage: SettingsPageId.rag),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      final build = find.byKey(const Key('rag-build-wiki'));
      final plan = find.byKey(const Key('rag-plan-wiki'));
      final start = find.byKey(const Key('rag-plan-start'));
      final cancel = find.byKey(const Key('rag-plan-cancel'));
      await tap(build);
      expect(plan, findsOneWidget);
      expect(ModalRoute.of(tester.element(plan))!.isCurrent, isTrue);
      expect(rag.starts, isEmpty);
      await tap(cancel);
      expect(plan, findsNothing);
      expect(rag.starts, isEmpty);
      await tap(build);
      await tap(start);
      expect(rag.starts, [('wiki', RagSource.wiki, false)]);

      await tap(find.byKey(const Key('rag-resume-gallery')));
      expect(rag.resumes, [RagSource.gallery]);
      await tap(find.byKey(const Key('rag-more-blocks')));
      final l = AppLocalizations.of(tester.element(find.byType(SettingsPage)))!;
      await tap(find.text(l.set_rebuild));
      expect(find.byKey(const Key('rag-plan-blocks')), findsOneWidget);
      expect(ModalRoute.of(tester.element(start))!.isCurrent, isTrue);
      expect(rag.starts, hasLength(1));
      await tap(start);
      expect(rag.starts.last, ('blocks', RagSource.blocks, true));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'overview and local upscale show the same detected GPU and available models',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1500, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gpu = Completer<SettingsGpuInfo?>();
      var probes = 0;
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(MemorySettings()),
          secureStorageServiceProvider.overrideWithValue(MemorySecrets()),
          settingsGpuProvider.overrideWith((ref) {
            probes++;
            return gpu.future;
          }),
          localUpscaleModelsProvider.overrideWith(
            (ref) async => [
              localUpscaleCatalog.first,
              localUpscaleCatalog[1].withInstalled(true),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);
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

      await open(SettingsPageId.overview);
      expect(probes, 1);
      final l = AppLocalizations.of(tester.element(find.byType(SettingsPage)))!;
      expect(find.text(l.set_upNoGpu), findsNothing);
      expect(find.text(l.set_testing), findsOneWidget);
      gpu.complete(
        const SettingsGpuInfo('NVIDIA GeForce RTX 4080', 16384, 8.9, '12.6'),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('RTX 4080'), findsOneWidget);
      expect(find.text(l.set_tileUpscaleModels('2')), findsOneWidget);
      await open(SettingsPageId.upscale);
      expect(find.textContaining('RTX 4080'), findsOneWidget);
      expect(probes, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

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
