import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/data/models/gallery/gallery_dashboard_snapshot.dart';
import 'package:nai_launcher/data/services/gallery_statistics_repository.dart';
import 'package:nai_launcher/data/services/statistics_cache_service.dart';

GalleryDashboardSnapshot testDashboard({int images = 3}) =>
    GalleryDashboardSnapshot(
      libraryTotal: 10,
      totalImages: images,
      totalSizeBytes: 2097152,
      favoriteCount: 1,
      taggedImageCount: 0,
      imagesWithMetadata: 2,
      resolutionCounts: const {'832x1216': 2, '1024x1024': 1},
      modelCounts: const {'nai-diffusion-5-full': 2},
      samplerCounts: const {'k_euler': 2},
      sizeCounts: const {'< 1 MB': 1, '1-2 MB': 2},
      sizeBytesCounts: const {'< 1 MB': 100, '1-2 MB': 2097052},
      tagCounts: const {},
      dailyCounts: const {20260901: 1, 20261005: 2},
      hourlyCounts: const {10: 3},
      weekdayCounts: const {1: 2, 7: 1},
      weekHourCounts: const {10: 2, 154: 1},
      stepCounts: const {28: 2},
      cfgCounts: {5.5: 2},
      noiseScheduleCounts: const {'karras': 2},
      dailyModelCounts: const {
        20261005: {'nai-diffusion-5-full': 2},
      },
      monthlyBytes: const {20260901: 100, 20261001: 2097052},
    );

class FakeStatisticsRepository extends Fake
    implements GalleryStatisticsRepository {
  GalleryDashboardSnapshot dashboard = testDashboard();
  GalleryArtistStatistics artists = const GalleryArtistStatistics(
    counts: {'example name': 2},
    imagesWithArtist: 2,
  );
  Map<DateTime, int> dailyAnlas = {DateTime(2026, 10, 5): 42};
  final caches = <String, StatisticsDashboardCache>{};
  final scopes = <({DateTime? start, DateTime? end, bool naiOnly})>[];
  Completer<GalleryDashboardSnapshot>? pendingLoad;
  Completer<GalleryArtistStatistics>? pendingArtists;
  Object? failure;
  var loads = 0;
  var artistLoads = 0;
  var clears = 0;
  String version = 'fake:1';
  String? range;
  bool nai = false;

  @override
  Future<String> readSignature() async => version;
  @override
  String? get savedRange => range;
  @override
  bool get savedNaiOnly => nai;
  @override
  Future<void> saveSelection(String range, bool naiOnly) async {
    this.range = range;
    nai = naiOnly;
  }

  @override
  StatisticsDashboardCache? cached(String key) => caches[key];
  @override
  Future<void> clearCache(String key) async {
    clears++;
    caches.remove(key);
  }

  @override
  Future<void> saveCache(String key, StatisticsDashboardCache value) async {
    caches[key] = value;
  }

  @override
  Future<int> countImages() async => dashboard.libraryTotal;
  @override
  Future<Map<DateTime, int>> loadAnlas() async => dailyAnlas;
  @override
  Future<GalleryDashboardSnapshot> load({
    DateTime? start,
    DateTime? end,
    required bool naiOnly,
  }) async {
    loads++;
    scopes.add((start: start, end: end, naiOnly: naiOnly));
    if (failure != null) throw failure!;
    final pending = pendingLoad;
    pendingLoad = null;
    return pending == null ? dashboard : pending.future;
  }

  @override
  Future<GalleryArtistStatistics> loadArtists({
    DateTime? start,
    DateTime? end,
    required bool naiOnly,
    required bool Function() isCancelled,
  }) async {
    artistLoads++;
    final pending = pendingArtists;
    pendingArtists = null;
    return pending == null ? artists : pending.future;
  }
}
