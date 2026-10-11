import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/database/datasources/gallery_data_source.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/gallery/gallery_dashboard_snapshot.dart';
import '../../../data/services/anlas_statistics_service.dart';
import '../../../data/services/gallery_statistics_repository.dart';
import '../../../data/services/statistics_cache_service.dart';
import '../../ui/statistics/statistics_contract.dart'
    show StatsRange, StatsSyncState;

final statisticsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final statisticsRepositoryProvider =
    FutureProvider<GalleryStatisticsRepository>((ref) async {
      return GalleryStatisticsRepository(
        readDataSource: () async {
          final manager = await ref.read(databaseManagerProvider.future);
          final source = manager.getDataSource<GalleryDataSource>('gallery');
          if (source == null) throw StateError('GalleryDataSource not found');
          return source;
        },
        cache: ref.read(statisticsCacheServiceProvider),
        preferences: await SharedPreferences.getInstance(),
        readAnlas: () async => (await ref.read(
          anlasStatisticsServiceProvider.future,
        )).getDailyStats(days: 90),
      );
    });

class StatisticsState {
  const StatisticsState({
    this.range = StatsRange.all,
    this.naiOnly = false,
    required this.today,
    this.sync = StatsSyncState.updating,
    this.updatedAt,
    this.countingImages,
    this.dashboard,
    this.artists,
    this.dailyAnlas = const {},
    this.error,
  });

  final StatsRange range;
  final bool naiOnly;
  final DateTime today;
  final StatsSyncState sync;
  final DateTime? updatedAt;
  final int? countingImages;
  final GalleryDashboardSnapshot? dashboard;
  final GalleryArtistStatistics? artists;
  final Map<DateTime, int> dailyAnlas;
  final String? error;

  StatisticsState copyWith({
    StatsRange? range,
    bool? naiOnly,
    DateTime? today,
    StatsSyncState? sync,
    DateTime? updatedAt,
    int? countingImages,
    GalleryDashboardSnapshot? dashboard,
    GalleryArtistStatistics? artists,
    Map<DateTime, int>? dailyAnlas,
    String? error,
    bool clearArtists = false,
  }) => StatisticsState(
    range: range ?? this.range,
    naiOnly: naiOnly ?? this.naiOnly,
    today: today ?? this.today,
    sync: sync ?? this.sync,
    updatedAt: updatedAt ?? this.updatedAt,
    countingImages: countingImages ?? this.countingImages,
    dashboard: dashboard ?? this.dashboard,
    artists: clearArtists ? null : artists ?? this.artists,
    dailyAnlas: dailyAnlas ?? this.dailyAnlas,
    error: error,
  );
}

({DateTime? start, DateTime? end}) statisticsDates(
  StatsRange range,
  DateTime today,
) {
  final day = DateTime(today.year, today.month, today.day);
  final days = range.days;
  return (
    start: days != null
        ? DateTime(day.year, day.month, day.day - days + 1)
        : range == StatsRange.thisYear
        ? DateTime(day.year)
        : null,
    end: range == StatsRange.all
        ? null
        : DateTime(day.year, day.month, day.day + 1),
  );
}

final statisticsProvider =
    NotifierProvider.autoDispose<StatisticsController, StatisticsState>(
      StatisticsController.new,
    );

class StatisticsController extends AutoDisposeNotifier<StatisticsState> {
  var _serial = 0;
  var _disposed = false;
  var _selectionRestored = false;
  var _rangeTouched = false;
  var _naiTouched = false;
  Timer? _midnight;

  @override
  StatisticsState build() {
    final now = ref.read(statisticsClockProvider)();
    ref.onDispose(() {
      _disposed = true;
      _serial++;
      _midnight?.cancel();
    });
    ref.listen(anlasStatisticsServiceProvider, (previous, next) {
      if (next.hasValue && state.dashboard != null) unawaited(_refreshAnlas());
    });
    _scheduleMidnight(now);
    unawaited(
      Future<void>.microtask(() async {
        if (_serial == 0) await _load();
      }),
    );
    return StatisticsState(today: DateTime(now.year, now.month, now.day));
  }

  bool _current(int serial) => !_disposed && serial == _serial;

  void _scheduleMidnight(DateTime now) {
    _midnight?.cancel();
    _midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (_disposed) return;
        unawaited(refresh());
        _scheduleMidnight(ref.read(statisticsClockProvider)());
      },
    );
  }

  Future<void> selectRange(StatsRange range) {
    if (_selectionRestored && state.range == range) return Future<void>.value();
    _rangeTouched = true;
    state = state.copyWith(range: range);
    return _load(persist: true);
  }

  Future<void> selectNaiOnly(bool value) {
    if (_selectionRestored && state.naiOnly == value) {
      return Future<void>.value();
    }
    _naiTouched = true;
    state = state.copyWith(naiOnly: value);
    return _load(persist: true);
  }

  Future<void> refresh() => _load(force: true);

  Future<void> _refreshAnlas() async {
    final serial = _serial;
    try {
      final repository = await ref.read(statisticsRepositoryProvider.future);
      final daily = await repository.loadAnlas();
      if (_current(serial)) {
        state = state.copyWith(dailyAnlas: daily, error: state.error);
      }
    } catch (e, stack) {
      AppLogger.e('Failed to refresh statistics Anlas', e, stack, 'Statistics');
    }
  }

  Future<void> _load({bool force = false, bool persist = false}) async {
    if (_disposed) return;
    final serial = ++_serial;
    final clock = ref.read(statisticsClockProvider);
    final now = clock();
    state = state.copyWith(
      today: DateTime(now.year, now.month, now.day),
      sync: StatsSyncState.updating,
    );
    try {
      final repository = await ref.read(statisticsRepositoryProvider.future);
      if (!_current(serial)) return;
      if (!_selectionRestored) {
        state = state.copyWith(
          range: _rangeTouched
              ? state.range
              : StatsRange.values.firstWhere(
                  (range) => range.name == repository.savedRange,
                  orElse: () => StatsRange.all,
                ),
          naiOnly: _naiTouched ? state.naiOnly : repository.savedNaiOnly,
        );
        _selectionRestored = true;
      }
      final range = state.range;
      final naiOnly = state.naiOnly;
      final today = state.today;
      final dates = statisticsDates(range, today);
      final key = '${range.name}:$naiOnly';
      if (persist) await repository.saveSelection(range.name, naiOnly);
      if (!_current(serial)) return;
      if (force) await repository.clearCache(key);
      if (!_current(serial)) return;
      final cached = force ? null : repository.cached(key);
      if (cached != null) {
        state = state.copyWith(
          dashboard: cached.snapshot,
          artists: cached.artists,
          clearArtists: cached.artists == null,
          updatedAt: cached.calculatedAt,
        );
      }
      if (state.dashboard == null) {
        final count = await repository.countImages();
        if (!_current(serial)) return;
        state = state.copyWith(countingImages: count);
      }
      for (var attempt = 0; attempt < 3; attempt++) {
        final dailyAnlas = await repository.loadAnlas();
        if (!_current(serial)) return;
        state = state.copyWith(dailyAnlas: dailyAnlas);
        final revision = await repository.readSignature();
        if (!_current(serial)) return;
        final signature = '$revision:${today.year}-${today.month}-${today.day}';
        final useCache = cached?.signature == signature;
        final dashboard = useCache
            ? cached!.snapshot
            : await repository.load(
                start: dates.start,
                end: dates.end,
                naiOnly: naiOnly,
              );
        if (!_current(serial)) return;
        if (revision != await repository.readSignature()) continue;
        if (!_current(serial)) return;
        final calculatedAt = useCache ? cached!.calculatedAt : clock();
        state = state.copyWith(
          dashboard: dashboard,
          dailyAnlas: dailyAnlas,
          updatedAt: calculatedAt,
          clearArtists: !useCache,
        );
        final artists = useCache && cached!.artists != null
            ? cached.artists!
            : await repository.loadArtists(
                start: dates.start,
                end: dates.end,
                naiOnly: naiOnly,
                isCancelled: () => !_current(serial),
              );
        if (!_current(serial)) return;
        if (revision != await repository.readSignature()) continue;
        if (!_current(serial)) return;
        state = state.copyWith(artists: artists, sync: StatsSyncState.idle);
        if (!useCache || cached!.artists == null) {
          await Future<void>.delayed(Duration.zero);
          if (!_current(serial)) return;
          try {
            await repository.saveCache(
              key,
              StatisticsDashboardCache(
                snapshot: dashboard,
                artists: artists,
                signature: signature,
                calculatedAt: calculatedAt,
              ),
            );
          } catch (e, stack) {
            AppLogger.e(
              'Failed to save dashboard cache',
              e,
              stack,
              'Statistics',
            );
          }
        }
        return;
      }
      throw StateError('Gallery changed while collecting statistics');
    } catch (e, stack) {
      if (!_current(serial)) return;
      AppLogger.e('Failed to load statistics', e, stack, 'Statistics');
      state = state.copyWith(sync: StatsSyncState.failed, error: e.toString());
    }
  }
}
