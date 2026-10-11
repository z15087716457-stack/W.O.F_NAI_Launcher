/// Small, pre-aggregated payload used by the statistics dashboard.
///
/// Keeping this model count-only prevents dashboard queries from materializing
/// image prompts and other large metadata fields.
class GalleryDashboardSnapshot {
  final int libraryTotal;
  final int totalImages;
  final int totalSizeBytes;
  final int favoriteCount;
  final int taggedImageCount;
  final int imagesWithMetadata;
  final Map<String, int> resolutionCounts;
  final Map<String, int> modelCounts;
  final Map<String, int> samplerCounts;
  final Map<String, int> sizeCounts;
  final Map<String, int> sizeBytesCounts;
  final Map<String, int> tagCounts;
  final Map<int, int> dailyCounts;
  final Map<int, int> hourlyCounts;
  final Map<int, int> weekdayCounts;
  final Map<int, int> weekHourCounts;
  final Map<int, int> stepCounts;
  final Map<double, int> cfgCounts;
  final Map<String, int> noiseScheduleCounts;
  final Map<int, Map<String, int>> dailyModelCounts;
  final Map<int, int> monthlyBytes;

  GalleryDashboardSnapshot({
    int? libraryTotal,
    required this.totalImages,
    required this.totalSizeBytes,
    required this.favoriteCount,
    required this.taggedImageCount,
    required this.imagesWithMetadata,
    required Map<String, int> resolutionCounts,
    required Map<String, int> modelCounts,
    required Map<String, int> samplerCounts,
    required Map<String, int> sizeCounts,
    required Map<String, int> tagCounts,
    required Map<int, int> dailyCounts,
    required Map<int, int> hourlyCounts,
    required Map<int, int> weekdayCounts,
    Map<String, int> sizeBytesCounts = const {},
    Map<int, int> weekHourCounts = const {},
    Map<int, int> stepCounts = const {},
    Map<double, int> cfgCounts = const {},
    Map<String, int> noiseScheduleCounts = const {},
    Map<int, Map<String, int>> dailyModelCounts = const {},
    Map<int, int> monthlyBytes = const {},
  }) : libraryTotal = libraryTotal ?? totalImages,
       resolutionCounts = Map.unmodifiable(resolutionCounts),
       modelCounts = Map.unmodifiable(modelCounts),
       samplerCounts = Map.unmodifiable(samplerCounts),
       sizeCounts = Map.unmodifiable(sizeCounts),
       sizeBytesCounts = Map.unmodifiable(sizeBytesCounts),
       tagCounts = Map.unmodifiable(tagCounts),
       dailyCounts = Map.unmodifiable(dailyCounts),
       hourlyCounts = Map.unmodifiable(hourlyCounts),
       weekdayCounts = Map.unmodifiable(weekdayCounts),
       weekHourCounts = Map.unmodifiable(weekHourCounts),
       stepCounts = Map.unmodifiable(stepCounts),
       cfgCounts = Map.unmodifiable(cfgCounts),
       noiseScheduleCounts = Map.unmodifiable(noiseScheduleCounts),
       dailyModelCounts = Map.unmodifiable({
         for (final entry in dailyModelCounts.entries)
           entry.key: Map<String, int>.unmodifiable(entry.value),
       }),
       monthlyBytes = Map.unmodifiable(monthlyBytes);

  Map<String, Object?> toJson() => {
    'libraryTotal': libraryTotal,
    'totalImages': totalImages,
    'totalSizeBytes': totalSizeBytes,
    'favoriteCount': favoriteCount,
    'taggedImageCount': taggedImageCount,
    'imagesWithMetadata': imagesWithMetadata,
    'resolutionCounts': resolutionCounts,
    'modelCounts': modelCounts,
    'samplerCounts': samplerCounts,
    'sizeCounts': sizeCounts,
    'sizeBytesCounts': sizeBytesCounts,
    'tagCounts': tagCounts,
    'dailyCounts': _stringKeys(dailyCounts),
    'hourlyCounts': _stringKeys(hourlyCounts),
    'weekdayCounts': _stringKeys(weekdayCounts),
    'weekHourCounts': _stringKeys(weekHourCounts),
    'stepCounts': _stringKeys(stepCounts),
    'cfgCounts': _stringKeys(cfgCounts),
    'noiseScheduleCounts': noiseScheduleCounts,
    'dailyModelCounts': _stringKeys(dailyModelCounts),
    'monthlyBytes': _stringKeys(monthlyBytes),
  };

  factory GalleryDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    Map<String, int> strings(String key) =>
        Map<String, int>.from(json[key] as Map);
    Map<int, int> integers(String key) => {
      for (final entry in (json[key] as Map).entries)
        int.parse(entry.key as String): (entry.value as num).toInt(),
    };
    return GalleryDashboardSnapshot(
      libraryTotal: json['libraryTotal'] as int,
      totalImages: json['totalImages'] as int,
      totalSizeBytes: json['totalSizeBytes'] as int,
      favoriteCount: json['favoriteCount'] as int,
      taggedImageCount: json['taggedImageCount'] as int,
      imagesWithMetadata: json['imagesWithMetadata'] as int,
      resolutionCounts: strings('resolutionCounts'),
      modelCounts: strings('modelCounts'),
      samplerCounts: strings('samplerCounts'),
      sizeCounts: strings('sizeCounts'),
      sizeBytesCounts: strings('sizeBytesCounts'),
      tagCounts: strings('tagCounts'),
      dailyCounts: integers('dailyCounts'),
      hourlyCounts: integers('hourlyCounts'),
      weekdayCounts: integers('weekdayCounts'),
      weekHourCounts: integers('weekHourCounts'),
      stepCounts: integers('stepCounts'),
      cfgCounts: {
        for (final entry in (json['cfgCounts'] as Map).entries)
          double.parse(entry.key as String): (entry.value as num).toInt(),
      },
      noiseScheduleCounts: strings('noiseScheduleCounts'),
      dailyModelCounts: {
        for (final entry in (json['dailyModelCounts'] as Map).entries)
          int.parse(entry.key as String): Map<String, int>.from(
            entry.value as Map,
          ),
      },
      monthlyBytes: integers('monthlyBytes'),
    );
  }

  static Map<String, V> _stringKeys<K, V>(Map<K, V> values) => {
    for (final entry in values.entries) entry.key.toString(): entry.value,
  };
}

class GalleryArtistStatistics {
  const GalleryArtistStatistics({
    required this.counts,
    required this.imagesWithArtist,
  });

  final Map<String, int> counts;
  final int imagesWithArtist;

  Map<String, Object?> toJson() => {
    'counts': counts,
    'imagesWithArtist': imagesWithArtist,
  };

  factory GalleryArtistStatistics.fromJson(Map<String, dynamic> json) =>
      GalleryArtistStatistics(
        counts: Map<String, int>.unmodifiable(
          Map<String, int>.from(json['counts'] as Map),
        ),
        imagesWithArtist: json['imagesWithArtist'] as int,
      );
}
