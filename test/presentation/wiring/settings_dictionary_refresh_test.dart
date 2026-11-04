import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/cache_footprint.dart';
import 'package:nai_launcher/core/cache/gallery_cache_manager.dart';
import 'package:nai_launcher/core/services/app_visibility.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_caches.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_dictionary_refresh.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_inventory.dart';

/// Builds the way SettingsWiring does: settingsViewData reads the three
/// dictionaries-page values only while that page is shown, then the page is
/// reported to the refresh.
class _Settings extends ConsumerStatefulWidget {
  const _Settings(this.page, {required this.autoRefresh});
  final SettingsPageId page;
  final bool autoRefresh;
  @override
  ConsumerState<_Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<_Settings> {
  late final _refresh = SettingsDictionaryRefresh.forSettings(ref);

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final open = widget.page == SettingsPageId.dictionaries;
    if (open) {
      ref.watch(settingsDictionaryDataProvider);
      ref.watch(settingsCacheFootprintProvider);
      ref.watch(settingsCacheStatsProvider);
    }
    _refresh.update(open: open, autoRefresh: widget.autoRefresh);
    return const SizedBox();
  }
}

/// Counts how often each value is computed. The real bundled-dictionaries
/// value runs the Wiki `PRAGMA quick_check` and count, the co-occurrence
/// `COUNT(*)` and the tag catalog metadata read; the other two count the
/// caches that change while the app runs.
class _Counts {
  int dictionaries = 0, footprint = 0, stats = 0;

  /// Holds the bundled-dictionaries check open until completed.
  Completer<void>? dictionariesGate;

  List<int> get all => [dictionaries, footprint, stats];

  late final List<Override> _overrides = [
    settingsDictionaryDataProvider.overrideWith((ref) async {
      dictionaries++;
      await dictionariesGate?.future;
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

  Widget page(SettingsPageId page, {bool autoRefresh = true}) => ProviderScope(
    overrides: _overrides,
    child: _Settings(page, autoRefresh: autoRefresh),
  );
}

/// Stays on whatever is shown, drawing a frame every 10 s like the app does
/// after each refresh.
Future<void> _stay(WidgetTester tester, Duration time) async {
  const step = Duration(seconds: 10);
  for (var spent = Duration.zero; spent < time; spent += step) {
    await tester.pump(step);
  }
}

/// Brings the window back and draws the next frame. Riverpod asks for that
/// frame from a microtask, so the pump has to run microtasks first.
Future<void> _show(WidgetTester tester) async {
  AppVisibility.instance.debugSet(true);
  await tester.pump(Duration.zero);
}

void main() {
  // The window signal itself is platform code (menu bar on macOS, tray on
  // Windows); the refresh only follows it, the same way on both.
  const platforms = TargetPlatformVariant({
    TargetPlatform.macOS,
    TargetPlatform.windows,
  });
  final visibility = AppVisibility.instance;
  tearDown(() => visibility.debugSet(true));

  testWidgets(
    'opening the page checks the bundled dictionaries once; staying recounts '
    'only the caches, every 10 s as the "updated" line shows',
    (tester) async {
      final counts = _Counts();
      await tester.pumpWidget(counts.page(SettingsPageId.dictionaries));
      expect(counts.all, [1, 1, 1]);

      await tester.pump(const Duration(seconds: 9));
      expect(counts.all, [1, 1, 1]);
      await tester.pump(const Duration(seconds: 1));
      expect(counts.all, [1, 2, 2]);

      await _stay(tester, const Duration(minutes: 10));
      expect(counts.all, [1, 62, 62]);
    },
    variant: platforms,
  );

  testWidgets(
    'every visit checks the bundled dictionaries once more; leaving stops '
    'the refresh',
    (tester) async {
      final counts = _Counts();
      await tester.pumpWidget(counts.page(SettingsPageId.dictionaries));
      // Nothing on the other settings pages reads the caches. Listening anyway
      // makes a refresh timer that kept running after leaving show up.
      final observer = ProviderScope.containerOf(
        tester.element(find.byType(_Settings)),
      ).listen(settingsCacheFootprintProvider, (_, __) {});
      await tester.pumpWidget(counts.page(SettingsPageId.storage));
      await _stay(tester, const Duration(minutes: 1));
      expect(counts.all, [1, 1, 1]);
      observer.close();

      await tester.pumpWidget(counts.page(SettingsPageId.dictionaries));
      await tester.pump();
      expect(counts.dictionaries, 2);
      await _stay(tester, const Duration(minutes: 1));
      expect(counts.dictionaries, 2);
    },
    variant: platforms,
  );

  testWidgets(
    'a hidden window pauses the cache refresh; showing it recounts once and '
    'resumes',
    (tester) async {
      final counts = _Counts();
      await tester.pumpWidget(counts.page(SettingsPageId.dictionaries));
      visibility.debugSet(false);
      await _stay(tester, const Duration(hours: 1));
      expect(counts.all, [1, 1, 1]);

      await _show(tester);
      expect(counts.all, [1, 2, 2]);
      await tester.pump(const Duration(seconds: 10));
      expect(counts.all, [1, 3, 3]);
    },
    variant: platforms,
  );

  testWidgets(
    'opened while hidden it checks once and recounts the caches only once '
    'the window shows',
    (tester) async {
      visibility.debugSet(false);
      final counts = _Counts();
      await tester.pumpWidget(counts.page(SettingsPageId.dictionaries));
      await _stay(tester, const Duration(minutes: 5));
      expect(counts.all, [1, 1, 1]);

      await _show(tester);
      expect(counts.all, [1, 2, 2]);
      await tester.pump(const Duration(seconds: 10));
      expect(counts.all, [1, 3, 3]);
    },
    variant: platforms,
  );

  testWidgets(
    'with auto refresh off nothing is recounted, also when the window comes '
    'back; turning it on refreshes only the caches',
    (tester) async {
      final counts = _Counts();
      await tester.pumpWidget(
        counts.page(SettingsPageId.dictionaries, autoRefresh: false),
      );
      await _stay(tester, const Duration(minutes: 1));
      visibility.debugSet(false);
      await _show(tester);
      expect(counts.all, [1, 1, 1]);

      await tester.pumpWidget(counts.page(SettingsPageId.dictionaries));
      await tester.pump(const Duration(seconds: 10));
      expect(counts.all, [1, 2, 2]);
    },
    variant: platforms,
  );

  testWidgets(
    'with auto refresh off, coming back reuses what the first visit counted',
    (tester) async {
      final counts = _Counts();
      await tester.pumpWidget(
        counts.page(SettingsPageId.dictionaries, autoRefresh: false),
      );
      for (var visit = 0; visit < 5; visit++) {
        await tester.pumpWidget(
          counts.page(SettingsPageId.storage, autoRefresh: false),
        );
        await tester.pumpWidget(
          counts.page(SettingsPageId.dictionaries, autoRefresh: false),
        );
        await tester.pump();
      }
      expect(counts.dictionaries, 1);
    },
    variant: platforms,
  );

  testWidgets(
    'coming back while the first check still runs does not start a second one',
    (tester) async {
      final counts = _Counts()..dictionariesGate = Completer<void>();
      await tester.pumpWidget(counts.page(SettingsPageId.dictionaries));
      await tester.pumpWidget(counts.page(SettingsPageId.storage));
      await tester.pumpWidget(counts.page(SettingsPageId.dictionaries));
      await tester.pump();
      expect(counts.dictionaries, 1);

      counts.dictionariesGate!.complete();
      await tester.pump();
      expect(counts.dictionaries, 1);
    },
    variant: platforms,
  );
}
