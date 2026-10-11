import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/datasources/gallery_data_source.dart';
import '../models/gallery/gallery_dashboard_snapshot.dart';
import 'anlas_statistics_service.dart';
import 'statistics_cache_service.dart';

class GalleryStatisticsRepository {
  GalleryStatisticsRepository({
    required this.readDataSource,
    required this.cache,
    required this.preferences,
    required this.readAnlas,
  });

  final Future<GalleryDataSource> Function() readDataSource;
  final StatisticsCacheService cache;
  final SharedPreferences preferences;
  final Future<List<DailyAnlasStat>> Function() readAnlas;
  Future<void> _selectionWrite = Future<void>.value();

  String? get savedRange => preferences.getString('statistics_range');
  bool get savedNaiOnly => preferences.getBool('statistics_nai_only') ?? false;
  Future<String> readSignature() async =>
      (await readDataSource()).getStatisticsSignature();

  Future<void> saveSelection(String range, bool naiOnly) {
    final next = _selectionWrite.then((_) async {
      final rangeSaved = await preferences.setString('statistics_range', range);
      final naiSaved = await preferences.setBool(
        'statistics_nai_only',
        naiOnly,
      );
      if (!rangeSaved || !naiSaved) {
        throw StateError('Unable to save statistics selection');
      }
    });
    _selectionWrite = next.catchError((Object _) {});
    return next;
  }

  StatisticsDashboardCache? cached(String key) => cache.getDashboardCache(key);
  Future<void> clearCache(String key) => cache.clearDashboardCache(key);
  Future<void> saveCache(String key, StatisticsDashboardCache value) =>
      cache.saveDashboardCache(key, value);
  Future<int> countImages() async => (await readDataSource()).countImages();

  Future<GalleryDashboardSnapshot> load({
    DateTime? start,
    DateTime? end,
    required bool naiOnly,
  }) async => (await readDataSource()).getDashboardStatistics(
    dateStart: start,
    dateEnd: end,
    naiOnly: naiOnly,
  );

  Future<Map<DateTime, int>> loadAnlas() async => {
    for (final stat in await readAnlas())
      DateTime(stat.date.year, stat.date.month, stat.date.day): stat.cost,
  };

  Future<GalleryArtistStatistics> loadArtists({
    DateTime? start,
    DateTime? end,
    required bool naiOnly,
    required bool Function() isCancelled,
  }) async {
    final counts = <String, int>{};
    var imagesWithArtist = 0;
    var cursor = 0;
    final source = await readDataSource();
    while (!isCancelled()) {
      final rows = await source.getStatisticsArtistPrompts(
        dateStart: start,
        dateEnd: end,
        naiOnly: naiOnly,
        afterId: cursor,
      );
      if (isCancelled() || rows.isEmpty) break;
      cursor = (rows.last['id'] as num).toInt();
      final prompts = rows.map((row) => row['prompt'] as String).toList();
      final page = await compute(countStatisticsArtists, prompts);
      imagesWithArtist += page.imagesWithArtist;
      for (final entry in page.counts.entries) {
        counts[entry.key] = (counts[entry.key] ?? 0) + entry.value;
      }
      await Future<void>.delayed(Duration.zero);
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final order = b.value.compareTo(a.value);
        return order == 0 ? a.key.compareTo(b.key) : order;
      });
    return GalleryArtistStatistics(
      counts: Map.unmodifiable(Map.fromEntries(sorted.take(10))),
      imagesWithArtist: imagesWithArtist,
    );
  }
}

GalleryArtistStatistics countStatisticsArtists(List<String> prompts) {
  final pattern = RegExp(
    r'(?:^|[,{}\[\]|:\s])artist:\s*([^,{}\[\]|:\r\n]+)',
    caseSensitive: false,
  );
  final counts = <String, int>{};
  var imagesWithArtist = 0;
  for (final prompt in prompts) {
    final artists = pattern
        .allMatches(prompt)
        .map(
          (match) => match
              .group(1)!
              .trim()
              .toLowerCase()
              .replaceAll('_', ' ')
              .replaceAll(RegExp(r'\s+'), ' '),
        )
        .where((name) => name.isNotEmpty)
        .toSet();
    if (artists.isNotEmpty) imagesWithArtist++;
    for (final name in artists) {
      counts[name] = (counts[name] ?? 0) + 1;
    }
  }
  return GalleryArtistStatistics(
    counts: counts,
    imagesWithArtist: imagesWithArtist,
  );
}
