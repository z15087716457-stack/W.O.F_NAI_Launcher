import 'dart:convert';
import 'dart:io';

import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';

/// 读 HTML 原型同目录的 `data.js`（用户图库的聚合数，只在本机对照时读取，不进仓库），
/// 转成界面契约，让 Flutter 实绘和原型用完全相同的数字。
class StatsPrototypeData {
  StatsPrototypeData._(this.json);
  final Map<String, dynamic> json;

  static StatsPrototypeData load(String path) {
    final s = File(path).readAsStringSync();
    return StatsPrototypeData._(
      jsonDecode(s.substring(s.indexOf('{'), s.lastIndexOf('}') + 1))
          as Map<String, dynamic>,
    );
  }

  DateTime get today => DateTime.parse('${json['today']}');

  DateTime get updatedAt {
    final t = (json['calculatedAt'] as String).split(':');
    return DateTime(
      today.year,
      today.month,
      today.day,
      int.parse(t[0]),
      int.parse(t[1]),
    );
  }

  static DateTime _ymd(Object v) {
    final s = '$v';
    return DateTime(
      int.parse(s.substring(0, 4)),
      int.parse(s.substring(4, 6)),
      int.parse(s.substring(6, 8)),
    );
  }

  static List<StatsCount<T>> _counts<T>(
    List<dynamic> l,
    T Function(Object) key,
  ) => [
    for (final e in l) StatsCount(key(e[0] as Object), (e[1] as num).toInt()),
  ];

  StatsSnapshot snapshot({bool last30 = false, bool artistsPending = false}) {
    final b = (last30 ? json['r30'] : json) as Map<String, dynamic>;
    final weekHour = List<int>.filled(168, 0);
    for (final e in b['punch'] as List) {
      final w = e[0] as int;
      weekHour[((w == 0 ? 7 : w) - 1) * 24 + (e[1] as int)] += e[2] as int;
    }
    final sizes = List.generate(5, (_) => const StatsSizeBucket(0, 0));
    for (final e in b['sizeB'] as List) {
      sizes[e[0] as int] = StatsSizeBucket(e[1] as int, (e[2] as num).toInt());
    }
    return StatsSnapshot(
      libraryTotal: json['total'] as int,
      images: b['total'] as int,
      favorites: b['fav'] as int,
      bytes: (b['size'] as num).toInt(),
      withMetadata: b['meta'] as int,
      weekHour: weekHour,
      models: _counts(b['models'] as List, (k) => '$k'),
      resolutions: [
        for (final e in b['res'] as List)
          StatsResolution(e[0] as int, e[1] as int, e[2] as int),
      ],
      samplers: _counts(b['sampler'] as List, (k) => '$k'),
      steps: _counts(b['steps'] as List, (k) => (k as num).toInt()),
      cfg: _counts(b['cfg'] as List, (k) => (k as num).toDouble()),
      noiseSchedules: _counts(b['noise'] as List, (k) => '$k'),
      sizeBuckets: sizes,
      dailyImages: {
        for (final e in (json['daily'] as Map).entries)
          _ymd(e.key): e.value as int,
      },
      dailyModels: [
        for (final e in json['modelDay'] as List)
          StatsModelDay(_ymd(e[0] as Object), e[1] as String, e[2] as int),
      ],
      monthlyBytes: {
        for (final e in json['sizeMonth'] as List)
          DateTime(
            int.parse('${e[0]}'.substring(0, 4)),
            int.parse('${e[0]}'.substring(4)),
          ): (e[1] as num)
              .toInt(),
      },
      dailyAnlas: {
        for (final e in (json['anlas'] as Map).entries)
          DateTime.parse(e.key as String): e.value as int,
      },
      artists: artistsPending
          ? null
          : StatsArtists(
              top: _counts(b['artists'] as List, (k) => '$k'),
              imagesWithArtist: b['artistImgs'] as int,
            ),
    );
  }
}
