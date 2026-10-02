import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_cache_database.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_providers.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/autocomplete/zh_dictionary_service.dart';
import 'package:nai_launcher/core/cache/gallery_cache_manager.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/database_providers.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/font_provider.dart';
import 'package:nai_launcher/presentation/providers/canvas_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/share_image_settings_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/generation_preferences_section.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/storage_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/cache_statistics_tile.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_tile.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_number_dialog.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_typography_scope.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_ui_theme.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

class _Catalog extends TagCatalogRepository {
  @override
  Future<Map<String, String>> metadata() async => {
    'tag_count': '221787',
    'data_version': '42f35be9d394',
  };
}

class _Dictionary extends ZhDictionaryService {
  @override
  ZhDictionaryState get state => const ZhDictionaryState(
    isInstalled: true,
    tagCount: 322933,
    version: '4831090f',
  );
}

class _Caches extends AutocompleteCacheDatabase {
  int danbooruClears = 0, aiClears = 0;
  @override
  Future<int> clearDanbooruCache() async {
    danbooruClears++;
    return 7;
  }

  @override
  Future<int> clearAiTranslationCache() async {
    aiClears++;
    return 3;
  }
}

void main() {
  late Directory hiveDir;
  final capture = GlobalKey();
  final capturing = Platform.environment['CAPTURE_SETTINGS_CONTENT'] == '1';
  final appearance = Platform.environment['STUDIO_APPEARANCE'] ?? 'light';
  var modelOpens = 0;
  var statisticsLoads = 0;
  setUpAll(() async {
    hiveDir = Directory.systemTemp.createTempSync('settings_content_test_');
    Hive.init(hiveDir.path);
    await Hive.openBox(StorageKeys.settingsBox);
    if (capturing) {
      await loadStudioCaptureFonts();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  setUp(() {
    modelOpens = 0;
    statisticsLoads = 0;
    SharedPreferences.setMockInitialValues({});
  });
  tearDownAll(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  Future<void> advance(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
  }

  Future<_Caches> pump(
    WidgetTester tester, {
    required bool data,
    required Size size,
    double scale = 1,
    bool systemReducedMotion = false,
    bool tickerEnabled = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final caches = _Caches();
    final storage = harness.MemorySettings()
      ..values[StorageKeys.settingsFontScale] = scale
      ..values[StorageKeys.promptWeightScrollModifier] = 'shift';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          tagCatalogRepositoryProvider.overrideWithValue(_Catalog()),
          zhDictionaryServiceProvider.overrideWith((ref) => _Dictionary()),
          autocompleteCacheDatabaseProvider.overrideWithValue(caches),
          databaseManagerProvider.overrideWith(
            (ref) async => throw StateError('offline test'),
          ),
          cacheStatisticsProvider.overrideWith((ref) async {
            statisticsLoads++;
            return CacheStatistics(
              l1MemorySize: 0,
              l1HitRate: 0,
              l1MemoryBytes: 0,
              l2HiveSize: 49836,
              l2HitRate: 0,
              l2HiveBytes: 0,
              l3DatabaseImageCount: 48813,
              l3DatabaseMetadataCount: 54474,
              totalHitRate: 0,
              lastUpdated: DateTime(2026),
            );
          }),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: settingsUiTheme(
            AppTheme.getTheme(
              AppStyle.geist,
              appearance == 'dark' ? Brightness.dark : Brightness.light,
              fontConfig: FontConfig.defaultFont,
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: systemReducedMotion),
            child: SettingsTypographyScope(
              child: TickerMode(
                enabled: tickerEnabled,
                child: RepaintBoundary(key: capture, child: child!),
              ),
            ),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          data ? '词库与缓存' : '生成与提示词',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(data ? '管理标签词库、索引与缓存维护。' : '管理提示词输入、生成提醒与请求节奏。'),
                        const SizedBox(height: 32),
                        if (data)
                          const StorageMaintenanceSection()
                        else
                          GenerationPreferencesSection(
                            onManageModels: () => modelOpens++,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (data) {
      await advance(tester);
    } else {
      await tester.pumpAndSettle();
    }
    return caches;
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    if (!capturing) return;
    await tester.runAsync(() async {
      final pixels =
          await (capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1.5);
      final bytes = await pixels.toByteData(format: ui.ImageByteFormat.png);
      final file = File(
        '.dart_tool/settings-cache-polish-captures/$name-$appearance.png',
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      pixels.dispose();
    });
  }

  for (final spec in [
    (const Size(1280, 960), 1.0, 'wide'),
    (const Size(400, 800), 1.3, 'narrow'),
  ]) {
    final label = spec.$3;
    testWidgets('generation B layout and dependent controls: $label', (
      tester,
    ) async {
      await pump(tester, data: false, size: spec.$1, scale: spec.$2);
      final input = tester.getRect(find.text('提示词输入'));
      final costs = tester.getRect(find.text('消耗提醒'));
      if (label == 'wide') {
        expect(costs.left, greaterThan(input.right));
        expect(costs.top, closeTo(input.top, .01));
      } else {
        expect(costs.top, greaterThan(input.bottom));
      }
      expect(find.text('标签扩展'), findsOneWidget);
      final interval = find.widgetWithText(SettingsTile, '生图间隔');
      expect(tester.widget<SettingsTile>(interval).enabled, isFalse);
      await screenshot(tester, 'generation-B-$label');
      final toggle = find.widgetWithText(SettingsSwitchTile, '限制生图频率');
      await tester.ensureVisible(toggle);
      await tester.tap(
        find.descendant(of: toggle, matching: find.byType(SettingsToggle)),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<SettingsTile>(interval).enabled, isTrue);
      await tester.ensureVisible(interval);
      await tester.tap(interval);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsNumberDialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(interval);
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('settings-positive-number'));
      final save = find.byKey(const Key('settings-save-number'));
      for (final invalid in ['0', '3601']) {
        await tester.enterText(field, invalid);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.byType(SettingsNumberDialog), findsOneWidget);
      }
      await tester.enterText(field, '12');
      await tester.tap(save);
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(tester.element(interval));
      expect(
        container.read(shareImageSettingsProvider).generationIntervalSeconds,
        12,
      );
      final jitter = find.widgetWithText(SettingsTile, '间隔随机抖动');
      await tester.ensureVisible(jitter);
      await tester.tap(jitter);
      await tester.pumpAndSettle();
      await tester.enterText(field, '51');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsNumberDialog), findsOneWidget);
      await tester.enterText(field, '0');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        container
            .read(shareImageSettingsProvider)
            .generationIntervalJitterPercent,
        0,
      );
      final models = find.byKey(
        const Key('settings-manage-translation-models'),
      );
      await tester.ensureVisible(models);
      await tester.tap(models);
      expect(modelOpens, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('dictionary A overview and independent cleanup: $label', (
      tester,
    ) async {
      final caches = await pump(
        tester,
        data: true,
        size: spec.$1,
        scale: spec.$2,
      );
      final l1 = tester.getRect(find.byKey(const Key('settings-cache-l1')));
      final l2 = tester.getRect(find.byKey(const Key('settings-cache-l2')));
      expect(label == 'wide' ? l2.left > l1.right : l2.top > l1.bottom, isTrue);
      expect(find.text('49,836'), findsOneWidget);
      expect(find.text('48,813'), findsOneWidget);
      expect(find.text('元数据 54,474'), findsOneWidget);
      expect(find.text('重置统计'), findsOneWidget);
      expect(
        find.byKey(const Key('settings-refresh-cache-statistics')),
        findsNothing,
      );
      final overview = find.widgetWithText(SettingsTile, '缓存概览');
      expect(tester.widget<SettingsTile>(overview).onTap, isNull);
      final leftRow = tester.getRect(
        find.byKey(const Key('settings-rescan-row')),
      );
      final rightRow = tester.getRect(
        find.byKey(const Key('settings-thumbnails-row')),
      );
      if (label == 'wide') {
        expect(leftRow.top, closeTo(rightRow.top, .01));
        expect(leftRow.bottom, closeTo(rightRow.bottom, .01));
        final leftButton = tester.getRect(
          find.byKey(const Key('settings-rescan-action')),
        );
        final rightButton = tester.getRect(
          find.byKey(const Key('settings-thumbnails-action')),
        );
        expect(leftButton.center.dy, closeTo(rightButton.center.dy, .01));
        expect(
          tester.getRect(find.text('重新扫描')).top,
          closeTo(tester.getRect(find.text('清理缩略图缓存')).top, .01),
        );
      } else {
        expect(rightRow.top, greaterThan(leftRow.bottom));
      }
      await screenshot(tester, 'dictionary-A-$label');
      for (final title in ['重新扫描', '清理缩略图缓存']) {
        final maintenance = find.widgetWithText(SettingsTile, title);
        final button = find.descendant(
          of: maintenance,
          matching: find.byType(OutlinedButton),
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await advance(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, '取消'));
        await advance(tester);
      }
      for (final key in [
        'settings-clear-danbooru-cache',
        'settings-clear-ai-cache',
      ]) {
        final action = find.byKey(Key(key));
        await tester.ensureVisible(action);
        await tester.tap(action);
        await advance(tester);
      }
      expect(caches.danbooruClears, 1);
      expect(caches.aiClears, 1);
      expect(find.text('49,836'), findsOneWidget);
      if (label == 'narrow') {
        await screenshot(tester, 'dictionary-A-narrow-bottom');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'auto-refresh ring animates, follows motion preference and keeps refreshing',
    (tester) async {
      await pump(tester, data: true, size: const Size(1280, 960));
      final ring = find.byKey(const Key('settings-auto-refresh-indicator'));
      final progress = find.descendant(
        of: ring,
        matching: find.byType(CircularProgressIndicator),
      );
      final container = ProviderScope.containerOf(tester.element(ring));
      final before = tester.widget<CircularProgressIndicator>(progress).value!;
      final primary = Theme.of(tester.element(ring)).colorScheme.primary;
      expect(
        tester.widget<CircularProgressIndicator>(progress).color,
        primary.withValues(alpha: .6),
      );
      await screenshot(tester, 'ring-before');
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        tester.widget<CircularProgressIndicator>(progress).value,
        greaterThan(before),
      );
      await screenshot(tester, 'ring-after');
      await container
          .read(canvasReducedMotionNotifierProvider.notifier)
          .setReduced(true);
      await advance(tester);
      final paused = tester.widget<CircularProgressIndicator>(progress).value;
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.widget<CircularProgressIndicator>(progress).value, paused);
      await screenshot(tester, 'ring-reduced');
      await tester.pump(const Duration(seconds: 3));
      await advance(tester);
      expect(statisticsLoads, greaterThan(1));
      await container
          .read(canvasReducedMotionNotifierProvider.notifier)
          .setReduced(false);
      await advance(tester);
      final resumed = tester.widget<CircularProgressIndicator>(progress).value!;
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.widget<CircularProgressIndicator>(progress).value,
        greaterThan(resumed),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('system reduced motion and hidden page keep a static blue ring', (
    tester,
  ) async {
    for (final systemReducedMotion in [true, false]) {
      await pump(
        tester,
        data: true,
        size: const Size(1280, 960),
        systemReducedMotion: systemReducedMotion,
        tickerEnabled: systemReducedMotion,
      );
      final progress = find.descendant(
        of: find.byKey(const Key('settings-auto-refresh-indicator')),
        matching: find.byType(CircularProgressIndicator),
      );
      final value = tester.widget<CircularProgressIndicator>(progress).value;
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.widget<CircularProgressIndicator>(progress).value, value);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
