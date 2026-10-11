import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/gallery/gallery_filter_service.dart';
import '../providers/statistics/statistics_provider.dart';
import '../router/app_router.dart';
import '../router/gallery_navigation_request.dart';
import '../ui/statistics/statistics_contract.dart';
import '../ui/statistics/statistics_page.dart';

final statisticsNavigationProvider = Provider<StatisticsNavigation>(
  (ref) => const StatisticsNavigation(),
);

class StatisticsNavigation {
  const StatisticsNavigation();

  void generate(BuildContext context) => context.go(AppRoutes.home);
  void gallery(BuildContext context, FilterCriteria criteria) => context.go(
    AppRoutes.localGallery,
    extra: GalleryNavigationRequest(criteria: criteria),
  );
  void addFolder(BuildContext context) => context.go(
    AppRoutes.localGallery,
    extra: GalleryNavigationRequest(addFolder: true),
  );
}

class StatisticsWiring extends ConsumerStatefulWidget {
  const StatisticsWiring({super.key});

  @override
  ConsumerState<StatisticsWiring> createState() => _StatisticsWiringState();
}

class _StatisticsWiringState extends ConsumerState<StatisticsWiring> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statisticsProvider);
    final controller = ref.read(statisticsProvider.notifier);
    final navigation = ref.read(statisticsNavigationProvider);
    return StatisticsPage(
      data: statisticsViewData(state),
      actions: StatsActions(
        onRangeChanged: (range) => unawaited(controller.selectRange(range)),
        onNaiOnlyChanged: (value) => unawaited(controller.selectNaiOnly(value)),
        onRefresh: () => unawaited(controller.refresh()),
        onOpenGallery: (filter) => navigation.gallery(
          context,
          statisticsGalleryFilter(
            filter,
            range: state.range,
            naiOnly: state.naiOnly,
            today: state.today,
          ),
        ),
        onGoGenerate: () => navigation.generate(context),
        onAddGalleryFolder: () => navigation.addFolder(context),
      ),
    );
  }
}

List<StatsCount<T>> _counts<T>(Map<T, int> values) {
  final sorted = values.entries.toList()
    ..sort((a, b) {
      final order = b.value.compareTo(a.value);
      return order == 0 ? a.key.toString().compareTo(b.key.toString()) : order;
    });
  return List.unmodifiable(
    sorted.map((entry) => StatsCount(entry.key, entry.value)),
  );
}

DateTime _date(int value) =>
    DateTime(value ~/ 10000, (value ~/ 100) % 100, value % 100);

StatsViewData statisticsViewData(StatisticsState state) {
  final data = state.dashboard;
  final artists = state.artists;
  return StatsViewData(
    range: state.range,
    naiOnly: state.naiOnly,
    today: state.today,
    sync: state.sync,
    updatedAt: state.updatedAt,
    countingImages: state.countingImages,
    errorMessage: state.error,
    snapshot: data == null
        ? null
        : StatsSnapshot(
            libraryTotal: data.libraryTotal,
            images: data.totalImages,
            favorites: data.favoriteCount,
            bytes: data.totalSizeBytes,
            withMetadata: data.imagesWithMetadata,
            weekHour: List.unmodifiable(
              List.generate(168, (index) => data.weekHourCounts[index] ?? 0),
            ),
            models: _counts(data.modelCounts),
            resolutions: List.unmodifiable(
              data.resolutionCounts.entries.map((entry) {
                final dimensions = entry.key.split('x');
                return StatsResolution(
                  int.parse(dimensions[0]),
                  int.parse(dimensions[1]),
                  entry.value,
                );
              }).toList()..sort((a, b) => b.count.compareTo(a.count)),
            ),
            samplers: _counts(data.samplerCounts),
            steps: _counts(data.stepCounts),
            cfg: _counts(data.cfgCounts),
            noiseSchedules: _counts(data.noiseScheduleCounts),
            sizeBuckets: List.unmodifiable([
              for (final label in [
                '< 1 MB',
                '1-2 MB',
                '2-5 MB',
                '5-10 MB',
                '> 10 MB',
              ])
                StatsSizeBucket(
                  data.sizeCounts[label] ?? 0,
                  data.sizeBytesCounts[label] ?? 0,
                ),
            ]),
            dailyImages: Map.unmodifiable(
              data.dailyCounts.map((key, value) => MapEntry(_date(key), value)),
            ),
            dailyModels: List.unmodifiable([
              for (final day in data.dailyModelCounts.entries)
                for (final model in day.value.entries)
                  StatsModelDay(_date(day.key), model.key, model.value),
            ]),
            monthlyBytes: Map.unmodifiable(
              data.monthlyBytes.map(
                (key, value) => MapEntry(_date(key), value),
              ),
            ),
            dailyAnlas: Map.unmodifiable(state.dailyAnlas),
            artists: artists == null
                ? null
                : StatsArtists(
                    top: _counts(
                      artists.counts,
                    ).take(10).toList(growable: false),
                    imagesWithArtist: artists.imagesWithArtist,
                  ),
          ),
  );
}

FilterCriteria statisticsGalleryFilter(
  StatsGalleryFilter filter, {
  required StatsRange range,
  required bool naiOnly,
  required DateTime today,
}) {
  final dates = statisticsDates(range, today);
  final base = FilterCriteria(
    naiOnly: naiOnly,
    dateStart: dates.start,
    dateEnd: dates.end,
    indexedDate: true,
    dateEndExclusive: true,
  );
  return switch (filter) {
    StatsDateFilter(:final start, :final end) => base.copyWith(
      dateStart: start,
      dateEnd: end,
    ),
    StatsModelFilter(:final model) => base.copyWith(filterModels: [model]),
    StatsResolutionFilter(:final width, :final height) => base.copyWith(
      filterResolutions: ['${width}x$height'],
    ),
    StatsOrientationFilter(:final orientation) => base.copyWith(
      filterOrientation: orientation.name,
    ),
    StatsSamplerFilter(:final sampler) => base.copyWith(
      filterSamplers: [sampler],
    ),
    StatsStepsFilter(:final steps) => base.copyWith(
      filterMinSteps: steps,
      filterMaxSteps: steps,
    ),
    StatsCfgFilter(:final cfg) => base.copyWith(
      filterMinCfg: cfg,
      filterMaxCfg: cfg,
    ),
    StatsArtistFilter(:final name) => base.copyWith(
      searchQuery: 'artist:$name',
    ),
    StatsNoMetadataFilter() => base.copyWith(
      metadataStatuses: ['none'],
      hasMetadata: false,
    ),
    StatsMinFileSizeFilter(:final bytes) => base.copyWith(minFileSize: bytes),
  };
}
