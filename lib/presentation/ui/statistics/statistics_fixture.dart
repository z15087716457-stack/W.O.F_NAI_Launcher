import 'dart:math' as math;

import 'statistics_contract.dart';

/// 统计页的假数据：固定种子生成，每次一样。给预览入口和基准截图用，不含真实图库数据。
///
/// 形状接近真实图库：约 19 个月的历史、产量逐月上升、中途换模型、偶尔断更、
/// 少量无元数据和未知模型，Anlas 只有最近 90 天。
abstract final class StatsFixture {
  static final today = DateTime(2026, 10, 11);

  static StatsViewData view({
    StatsRange range = StatsRange.all,
    bool naiOnly = false,
    StatsSyncState sync = StatsSyncState.idle,
    bool loading = false,
    bool empty = false,
    String? error,
    bool artistsPending = false,
  }) => StatsViewData(
    range: range,
    naiOnly: naiOnly,
    today: today,
    sync: sync,
    updatedAt: DateTime(2026, 10, 11, 10, 0),
    countingImages: loading ? 48824 : null,
    errorMessage: error,
    snapshot: loading || error != null
        ? null
        : empty
        ? emptySnapshot
        : snapshot(range: range, artistsPending: artistsPending),
  );

  static StatsSnapshot snapshot({
    StatsRange range = StatsRange.all,
    bool artistsPending = false,
  }) {
    final rnd = math.Random(7);
    final first = DateTime(2025, 3, 10);
    final daily = <DateTime, int>{};
    final modelDay = <StatsModelDay>[];
    for (
      var d = first;
      !d.isAfter(today);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      final months = (d.year - 2025) * 12 + d.month - 3;
      if (rnd.nextDouble() < .12) continue;
      final weekend = d.weekday >= 6 ? 1.6 : 1.0;
      final burst = d.year == 2026 && d.month == 8 ? 6.0 : 1.0;
      final v =
          ((4 + months * months * .9) *
                  weekend *
                  burst *
                  (.4 + rnd.nextDouble()))
              .round();
      if (v <= 0) continue;
      daily[d] = v;
      final meta = (v * .93).round();
      final v5 = d.isAfter(DateTime(2026, 7, 1)) ? (meta * .62).round() : 0;
      final rest = meta - v5;
      final split = <String, int>{
        'nai-diffusion-5-full': v5,
        'nai-diffusion-4-5-full': (rest * .92).round(),
        'nai-diffusion-4-full': (rest * .05).round(),
        'nai-diffusion-3': (rest * .02).round(),
        'custom-model-${d.day % 4}':
            rest -
            (rest * .92).round() -
            (rest * .05).round() -
            (rest * .02).round(),
      };
      split.forEach((m, c) {
        if (c > 0) modelDay.add(StatsModelDay(d, m, c));
      });
    }

    final start = switch (range) {
      StatsRange.all => first,
      StatsRange.thisYear => DateTime(today.year),
      _ => DateTime(today.year, today.month, today.day + 1 - range.days!),
    };
    bool inRange(DateTime d) => !d.isBefore(start);
    final images = daily.entries
        .where((e) => inRange(e.key))
        .fold(0, (a, e) => a + e.value);
    final models = <String, int>{};
    for (final m in modelDay.where((m) => inRange(m.day))) {
      models[m.model] = (models[m.model] ?? 0) + m.count;
    }
    final withMeta = models.values.fold(0, (a, b) => a + b);
    int share(double f) => (images * f).round();

    final weekHour = List<int>.filled(168, 0);
    for (var w = 1; w <= 7; w++) {
      for (var h = 0; h < 24; h++) {
        final evening = math.exp(-math.pow((h - 21.5) / 2.6, 2));
        final noon = .55 * math.exp(-math.pow((h - 13) / 1.8, 2));
        final late = h < 3 ? .5 : 0;
        weekHour[(w - 1) * 24 + h] =
            (images /
                    60 *
                    (evening + noon + late) *
                    (w == 4 || w == 6 ? 1.5 : 1))
                .round();
      }
    }

    final monthly = <DateTime, int>{};
    daily.forEach((d, v) {
      final m = DateTime(d.year, d.month);
      monthly[m] = (monthly[m] ?? 0) + v * 1400000;
    });

    final anlas = <DateTime, int>{};
    for (var i = 0; i < 90; i++) {
      final d = DateTime(today.year, today.month, today.day - i);
      if (i == 0 || rnd.nextDouble() < .55) continue;
      anlas[d] = (rnd.nextDouble() * rnd.nextDouble() * 900 + 20).round();
    }

    List<StatsCount<T>> sorted<T>(Map<T, int> m) =>
        (m.entries.map((e) => StatsCount(e.key, e.value)).toList()
          ..sort((a, b) => b.count - a.count));

    return StatsSnapshot(
      libraryTotal: daily.values.fold(0, (a, b) => a + b),
      images: images,
      favorites: share(.0034),
      bytes: images * 1430000,
      withMetadata: withMeta,
      weekHour: weekHour,
      models: sorted(models),
      resolutions: [
        StatsResolution(832, 1216, share(.52)),
        StatsResolution(1216, 832, share(.2)),
        StatsResolution(1024, 1024, share(.12)),
        StatsResolution(1024, 1536, share(.06)),
        StatsResolution(1536, 1024, share(.04)),
        StatsResolution(640, 640, share(.03)),
        StatsResolution(1088, 1920, share(.03)),
      ],
      samplers: sorted({
        'k_euler_ancestral': share(.78),
        'k_dpmpp_2m_sde': share(.12),
        'k_euler': share(.05),
        'k_dpmpp_2s_ancestral': share(.03),
      }),
      steps: sorted({
        28: share(.8),
        23: share(.11),
        20: share(.05),
        30: share(.02),
        40: share(.01),
        12: share(.01),
      }),
      cfg: sorted({
        5.0: share(.34),
        6.0: share(.27),
        7.0: share(.18),
        5.5: share(.12),
        4.0: share(.06),
        4.5: share(.03),
      }),
      noiseSchedules: sorted({
        'karras': share(.95),
        'exponential': share(.03),
        'native': share(.02),
      }),
      sizeBuckets: [
        StatsSizeBucket(share(.08), share(.08) * 700000),
        StatsSizeBucket(share(.6), share(.6) * 1500000),
        StatsSizeBucket(share(.28), share(.28) * 2600000),
        StatsSizeBucket(share(.035), share(.035) * 6000000),
        StatsSizeBucket(share(.005), share(.005) * 13000000),
      ],
      dailyImages: daily,
      dailyModels: modelDay,
      monthlyBytes: monthly,
      dailyAnlas: anlas,
      artists: artistsPending
          ? null
          : StatsArtists(
              imagesWithArtist: share(.71),
              top: [
                for (final (i, n) in const [
                  'aoi mizuki',
                  'kuro neko (studio)',
                  'hanabira',
                  'tsukishiro',
                  'mori no oto',
                  'yuzu',
                  'shirokane (artist)',
                  'kagerou',
                  'umi',
                  'sakuya hoshino',
                ].indexed)
                  StatsCount(n, (images * .11 * math.pow(.9, i)).round()),
              ],
            ),
    );
  }

  static final emptySnapshot = StatsSnapshot(
    libraryTotal: 0,
    images: 0,
    favorites: 0,
    bytes: 0,
    withMetadata: 0,
    weekHour: List.filled(168, 0),
    models: const [],
    resolutions: const [],
    samplers: const [],
    steps: const [],
    cfg: const [],
    noiseSchedules: const [],
    sizeBuckets: List.filled(5, const StatsSizeBucket(0, 0)),
    dailyImages: const {},
    dailyModels: const [],
    monthlyBytes: const {},
    dailyAnlas: const {},
    artists: const StatsArtists(top: [], imagesWithArtist: 0),
  );
}
