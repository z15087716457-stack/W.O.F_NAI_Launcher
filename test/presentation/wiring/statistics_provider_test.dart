import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/core/database/database_providers.dart';
import 'package:nai_launcher/data/models/gallery/gallery_dashboard_snapshot.dart';
import 'package:nai_launcher/data/services/statistics_cache_service.dart';
import 'package:nai_launcher/presentation/providers/statistics/statistics_provider.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'statistics_fakes.dart';

class _CachedDashboardService extends Fake implements StatisticsCacheService {
  _CachedDashboardService(this.cached);
  final StatisticsDashboardCache cached;
  @override
  StatisticsDashboardCache? getDashboardCache(String key) => cached;
}

Future<void> settleStatistics(bool Function() ready) async {
  for (var i = 0; i < 100 && !ready(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(ready(), isTrue);
}

void main() {
  late FakeStatisticsRepository repository;
  late ProviderContainer container;
  final today = DateTime(2026, 10, 11);

  setUpAll(() async {
    await AppLogger.initialize(isTestEnvironment: true);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = FakeStatisticsRepository();
    container = ProviderContainer(
      overrides: [
        statisticsRepositoryProvider.overrideWith((ref) async => repository),
        statisticsClockProvider.overrideWithValue(() => today),
      ],
    );
    container.listen(statisticsProvider, (_, _) {});
  });
  tearDown(() => container.dispose());

  test(
    'cached snapshot is visible before database startup and survives its failure',
    () async {
      final startup = Completer<Never>();
      var databaseRequested = false;
      final cached = StatisticsDashboardCache(
        snapshot: repository.dashboard,
        artists: repository.artists,
        signature: 'pending',
        calculatedAt: today,
      );
      final scoped = ProviderContainer(
        overrides: [
          databaseManagerProvider.overrideWith((ref) {
            databaseRequested = true;
            return startup.future;
          }),
          statisticsCacheServiceProvider.overrideWithValue(
            _CachedDashboardService(cached),
          ),
          statisticsClockProvider.overrideWithValue(() => today),
        ],
      );
      addTearDown(scoped.dispose);
      scoped.listen(statisticsProvider, (_, _) {});
      await settleStatistics(
        () => scoped.read(statisticsProvider).dashboard != null,
      );
      expect(startup.isCompleted, isFalse);
      expect(scoped.read(statisticsProvider).sync, StatsSyncState.updating);
      await settleStatistics(() => databaseRequested);
      startup.completeError(StateError('database startup failed'));
      await settleStatistics(
        () => scoped.read(statisticsProvider).sync == StatsSyncState.failed,
      );
      expect(
        scoped.read(statisticsProvider).dashboard,
        same(repository.dashboard),
      );
      expect(
        scoped.read(statisticsProvider).error,
        contains('database startup failed'),
      );
    },
  );

  test(
    'first load exposes count and publishes aggregates before artists',
    () async {
      final load = Completer<GalleryDashboardSnapshot>();
      final artists = Completer<GalleryArtistStatistics>();
      repository.pendingLoad = load;
      repository.pendingArtists = artists;
      await settleStatistics(() => repository.loads == 1);
      expect(container.read(statisticsProvider).dashboard, isNull);
      expect(container.read(statisticsProvider).countingImages, 10);
      load.complete(repository.dashboard);
      await settleStatistics(() => repository.artistLoads == 1);
      expect(
        container.read(statisticsProvider).dashboard,
        same(repository.dashboard),
      );
      expect(container.read(statisticsProvider).artists, isNull);
      artists.complete(repository.artists);
      await settleStatistics(
        () => container.read(statisticsProvider).sync == StatsSyncState.idle,
      );
      expect(
        container.read(statisticsProvider).dailyAnlas[today.subtract(
          const Duration(days: 6),
        )],
        42,
      );
    },
  );

  test(
    'shows cached result while checking and skips unchanged aggregates',
    () async {
      final cached = testDashboard(images: 8);
      repository.caches['all:false'] = StatisticsDashboardCache(
        snapshot: cached,
        artists: repository.artists,
        signature: '${repository.version}:2026-10-11',
        calculatedAt: today,
      );
      final states = <StatisticsState>[];
      container.listen(statisticsProvider, (_, next) => states.add(next));
      await settleStatistics(
        () => container.read(statisticsProvider).sync == StatsSyncState.idle,
      );
      expect(
        states.any(
          (s) =>
              identical(s.dashboard, cached) &&
              s.sync == StatsSyncState.updating,
        ),
        isTrue,
      );
      expect(container.read(statisticsProvider).dashboard, same(cached));
      expect(repository.loads, 0);
      expect(repository.artistLoads, 0);
    },
  );

  test('stale cache survives failed update', () async {
    repository.caches['all:false'] = StatisticsDashboardCache(
      snapshot: repository.dashboard,
      signature: 'old session',
      calculatedAt: today,
    );
    repository.failure = StateError('query failed');
    await settleStatistics(
      () => container.read(statisticsProvider).sync == StatsSyncState.failed,
    );
    expect(
      container.read(statisticsProvider).dashboard,
      same(repository.dashboard),
    );
    expect(container.read(statisticsProvider).error, contains('query failed'));
  });

  test(
    'initial failure has no snapshot and retry forces a new query',
    () async {
      repository.failure = StateError('query failed');
      await settleStatistics(
        () => container.read(statisticsProvider).sync == StatsSyncState.failed,
      );
      expect(container.read(statisticsProvider).dashboard, isNull);
      repository.failure = null;
      await container.read(statisticsProvider.notifier).refresh();
      expect(container.read(statisticsProvider).sync, StatsSyncState.idle);
      expect(container.read(statisticsProvider).error, isNull);
      expect(repository.clears, 1);
    },
  );

  test(
    'restores independent selection and forwards range and NAI scope',
    () async {
      repository.range = 'days7';
      repository.nai = true;
      await settleStatistics(
        () => container.read(statisticsProvider).sync == StatsSyncState.idle,
      );
      expect(repository.scopes.single, (
        start: DateTime(2026, 10, 5),
        end: DateTime(2026, 10, 12),
        naiOnly: true,
      ));
      await container
          .read(statisticsProvider.notifier)
          .selectRange(StatsRange.thisYear);
      expect(repository.range, 'thisYear');
      expect(repository.scopes.last.start, DateTime(2026));
      await container.read(statisticsProvider.notifier).selectNaiOnly(false);
      expect(repository.nai, isFalse);
      expect(repository.scopes.last.naiOnly, isFalse);
    },
  );

  test(
    'immediate default-valued choice wins over saved preference and preserves untouched selection',
    () async {
      repository.range = 'days7';
      repository.nai = true;
      await container.read(statisticsProvider.notifier).selectNaiOnly(false);
      await settleStatistics(
        () => container.read(statisticsProvider).sync == StatsSyncState.idle,
      );
      expect(container.read(statisticsProvider).range, StatsRange.days7);
      expect(container.read(statisticsProvider).naiOnly, isFalse);
      expect(repository.range, 'days7');
      expect(repository.nai, isFalse);
    },
  );

  test(
    'immediate all-time choice is persisted without discarding saved NAI preference',
    () async {
      repository.range = 'days7';
      repository.nai = true;
      await container
          .read(statisticsProvider.notifier)
          .selectRange(StatsRange.all);
      await settleStatistics(
        () => container.read(statisticsProvider).sync == StatsSyncState.idle,
      );
      expect(container.read(statisticsProvider).range, StatsRange.all);
      expect(container.read(statisticsProvider).naiOnly, isTrue);
      expect(repository.range, 'all');
      expect(repository.nai, isTrue);
    },
  );

  test('late result from old range cannot replace newer selection', () async {
    final stale = Completer<GalleryDashboardSnapshot>();
    repository.pendingLoad = stale;
    await settleStatistics(() => repository.loads == 1);
    await container
        .read(statisticsProvider.notifier)
        .selectRange(StatsRange.days30);
    expect(container.read(statisticsProvider).range, StatsRange.days30);
    stale.complete(testDashboard(images: 999));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(container.read(statisticsProvider).dashboard!.totalImages, 3);
    expect(container.read(statisticsProvider).sync, StatsSyncState.idle);
  });

  test('disposed page ignores pending query completion', () async {
    final pending = Completer<GalleryDashboardSnapshot>();
    repository.pendingLoad = pending;
    await settleStatistics(() => repository.loads == 1);
    container.dispose();
    pending.complete(repository.dashboard);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(repository.artistLoads, 0);
    container = ProviderContainer();
  });

  test(
    'calendar range boundaries include today without duration DST arithmetic',
    () {
      for (final range in [
        StatsRange.days7,
        StatsRange.days30,
        StatsRange.days90,
      ]) {
        final dates = statisticsDates(range, DateTime(2026, 3, 9));
        expect(dates.end, DateTime(2026, 3, 10));
        expect(dates.start, DateTime(2026, 3, 9 - range.days! + 1));
      }
      expect(statisticsDates(StatsRange.all, today), (start: null, end: null));
    },
  );
}
