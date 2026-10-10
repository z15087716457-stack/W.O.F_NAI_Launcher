import 'dart:math' as math;

import '../../utils/gallery_model_labels.dart';
import 'statistics_contract.dart';

/// 界面自己从契约数据推出来的展示数字（纯函数，有单测）。
/// 不涉及数据库：只做求和、分桶、找最大值这类展示计算。

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
DateTime mondayOf(DateTime d) => addDays(dayOf(d), 1 - d.weekday);
DateTime monthOf(DateTime d) => DateTime(d.year, d.month);

/// 一段日期，[start] 含、[end] 不含。
class StatsPeriod {
  const StatsPeriod(this.start, this.end);
  final DateTime start;
  final DateTime end;

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);
}

/// 当前时间范围对应的日期段；“全部”为 null。
StatsPeriod? rangePeriod(StatsRange range, DateTime today) {
  final end = addDays(today, 1);
  final days = range.days;
  if (days != null) return StatsPeriod(addDays(today, 1 - days), end);
  if (range == StatsRange.thisYear) {
    return StatsPeriod(DateTime(today.year), end);
  }
  return null;
}

/// 用来比较的上一段：固定天数取前面同样长的一段；今年取去年同期。
StatsPeriod? previousPeriod(StatsRange range, DateTime today) {
  final days = range.days;
  if (days != null) {
    final start = addDays(today, 1 - days);
    return StatsPeriod(addDays(start, -days), start);
  }
  if (range == StatsRange.thisYear) {
    return StatsPeriod(
      DateTime(today.year - 1),
      DateTime(today.year - 1, today.month, today.day + 1),
    );
  }
  return null;
}

int sumIn(Map<DateTime, int> daily, StatsPeriod p) {
  var s = 0;
  daily.forEach((d, v) {
    if (p.contains(d)) s += v;
  });
  return s;
}

int countOn(Map<DateTime, int> daily, DateTime d) => daily[dayOf(d)] ?? 0;

/// 截至 [today] 的连续天数（今天还没画时从昨天算起）和历史最长一段。
class StatsStreaks {
  const StatsStreaks(this.current, this.best, this.bestStart, this.bestEnd);
  final int current;
  final int best;
  final DateTime? bestStart;
  final DateTime? bestEnd;
}

StatsStreaks streaksOf(Map<DateTime, int> daily, DateTime today) {
  var cur = 0;
  var d = countOn(daily, today) > 0 ? today : addDays(today, -1);
  while (countOn(daily, d) > 0) {
    cur++;
    d = addDays(d, -1);
  }
  final days =
      daily.entries.where((e) => e.value > 0).map((e) => e.key).toList()
        ..sort();
  var best = 0, run = 0;
  DateTime? prev, bestEnd;
  for (final day in days) {
    run = prev != null && addDays(prev, 1) == day ? run + 1 : 1;
    if (run > best) {
      best = run;
      bestEnd = day;
    }
    prev = day;
  }
  return StatsStreaks(
    cur,
    best,
    bestEnd == null ? null : addDays(bestEnd, 1 - best),
    bestEnd,
  );
}

int activeDays(Map<DateTime, int> daily) =>
    daily.values.where((v) => v > 0).length;

DateTime? firstDay(Map<DateTime, int> daily) {
  DateTime? first;
  daily.forEach((d, v) {
    if (v > 0 && (first == null || d.isBefore(first!))) first = d;
  });
  return first;
}

/// 最近 [n] 天每天的值，旧在前。
List<int> lastDays(Map<DateTime, int> daily, DateTime today, int n) => [
  for (var i = n - 1; i >= 0; i--) countOn(daily, addDays(today, -i)),
];

/// 最近 [n] 个月每月合计，旧在前。
List<int> lastMonths(Map<DateTime, int> daily, DateTime today, int n) {
  final out = List<int>.filled(n, 0);
  final base = today.year * 12 + today.month - 1;
  daily.forEach((d, v) {
    final i = n - 1 - (base - (d.year * 12 + d.month - 1));
    if (i >= 0 && i < n) out[i] += v;
  });
  return out;
}

// ---------------------------------------------------------------- 日历

/// 日历显示的若干整周：从 [start]（周一）起 [weeks] 周，到 [last] 为止。
class CalendarWindow {
  const CalendarWindow(this.start, this.weeks, this.last);
  final DateTime start;
  final int weeks;
  final DateTime last;

  DateTime dayAt(int week, int row) => addDays(start, week * 7 + row);
  bool shows(DateTime d) => !d.isBefore(start) && !d.isAfter(last);
}

/// 截至今天的最近 [weeks] 周。
CalendarWindow recentWindow(DateTime today, int weeks) =>
    CalendarWindow(addDays(mondayOf(today), -(weeks - 1) * 7), weeks, today);

/// 某一年的全年（今年截至今天）。
CalendarWindow yearWindow(int year, DateTime today) {
  final start = mondayOf(DateTime(year));
  final last = year == today.year ? today : DateTime(year, 12, 31);
  return CalendarWindow(start, last.difference(start).inDays ~/ 7 + 1, last);
}

/// 5 档颜色的分界：非零值的 25% / 50% / 80% 分位数。
List<int> heatThresholds(Iterable<int> values) {
  final nz = values.where((v) => v > 0).toList()..sort();
  int q(double p) => nz.isEmpty ? 1 : nz[((nz.length - 1) * p).floor()];
  return [q(.25), q(.5), q(.8)];
}

int heatLevel(int v, List<int> th) => v <= 0
    ? 0
    : v <= th[0]
    ? 1
    : v <= th[1]
    ? 2
    : v <= th[2]
    ? 3
    : 4;

/// 图库里有图的年份，新的在前。
List<int> yearsWithImages(Map<DateTime, int> daily) {
  final ys = {
    for (final e in daily.entries)
      if (e.value > 0) e.key.year,
  }.toList()..sort((a, b) => b - a);
  return ys;
}

// ---------------------------------------------------------------- 模型

enum StatsFamily { nai45, nai5, nai4, nai3, other, noMetadata }

StatsFamily familyOf(String model) {
  if (model.contains('4-5')) return StatsFamily.nai45;
  if (model.contains('diffusion-5')) return StatsFamily.nai5;
  if (model.contains('diffusion-4')) return StatsFamily.nai4;
  if (model.contains('diffusion-3') || model.contains('furry-3')) {
    return StatsFamily.nai3;
  }
  return StatsFamily.other;
}

/// 有友好名的模型（未知模型并进“其他 N 个模型”）。
String? namedModel(String model) {
  final name = galleryModelFriendlyName(model);
  return name == model ? null : name;
}

enum StatsGranularity { day, week, month }

StatsGranularity defaultGranularity(StatsRange r) => switch (r) {
  StatsRange.days7 || StatsRange.days30 => StatsGranularity.day,
  StatsRange.days90 => StatsGranularity.week,
  StatsRange.thisYear || StatsRange.all => StatsGranularity.month,
};

/// 产量图的一根柱子。
class ProductionBucket {
  ProductionBucket(this.period)
    : counts = {for (final f in StatsFamily.values) f: 0};
  final StatsPeriod period;
  final Map<StatsFamily, int> counts;
  int get total => counts.values.fold(0, (a, b) => a + b);
}

/// 按粒度把每天的数字分到柱子里；范围是“全部”时从有图的第一天起，柱子数有上限。
List<ProductionBucket> productionBuckets({
  required StatsSnapshot snapshot,
  required StatsRange range,
  required DateTime today,
  required StatsGranularity granularity,
}) {
  final period =
      rangePeriod(range, today) ??
      StatsPeriod(firstDay(snapshot.dailyImages) ?? today, addDays(today, 1));
  DateTime startOf(DateTime d) => switch (granularity) {
    StatsGranularity.day => dayOf(d),
    StatsGranularity.week => mondayOf(d),
    StatsGranularity.month => monthOf(d),
  };
  DateTime next(DateTime d) => switch (granularity) {
    StatsGranularity.day => addDays(d, 1),
    StatsGranularity.week => addDays(d, 7),
    StatsGranularity.month => DateTime(d.year, d.month + 1),
  };
  final (minBars, maxBars) = switch (granularity) {
    StatsGranularity.day => (range.days ?? 14, 90),
    StatsGranularity.week => (range == StatsRange.days90 ? 13 : 8, 52),
    StatsGranularity.month => (range == StatsRange.all ? 6 : 1, 24),
  };
  final starts = <DateTime>[];
  for (var s = startOf(period.start); s.isBefore(period.end); s = next(s)) {
    starts.add(s);
  }
  while (starts.length < minBars) {
    starts.insert(
      0,
      startOf(addDays(starts.isEmpty ? today : starts.first, -1)),
    );
  }
  if (starts.length > maxBars) starts.removeRange(0, starts.length - maxBars);
  final buckets = [
    for (final s in starts) ProductionBucket(StatsPeriod(s, next(s))),
  ];
  final visible = StatsPeriod(
    range == StatsRange.all ? buckets.first.period.start : period.start,
    period.end,
  );
  int? indexOf(DateTime d) {
    if (!visible.contains(d)) return null;
    final s = startOf(d);
    for (var i = buckets.length - 1; i >= 0; i--) {
      if (buckets[i].period.start == s) return i;
    }
    return null;
  }

  final totals = List<int>.filled(buckets.length, 0);
  snapshot.dailyImages.forEach((d, v) {
    final i = indexOf(d);
    if (i != null) totals[i] += v;
  });
  for (final m in snapshot.dailyModels) {
    final i = indexOf(m.day);
    if (i == null) continue;
    final f = familyOf(m.model);
    buckets[i].counts[f] = buckets[i].counts[f]! + m.count;
  }
  for (final (i, b) in buckets.indexed) {
    b.counts[StatsFamily.noMetadata] = math.max(totals[i] - b.total, 0);
  }
  return buckets;
}

/// 产量图纵轴顶值：取整到 1 / 2 × 10ⁿ。
int niceCeiling(int v) {
  if (v <= 1) return 1;
  final p = math.pow(10, (math.log(v) / math.ln10).floor()).toInt();
  final m = v / p > 5 ? 2 : 1;
  return (v / p / m).ceil() * p * m;
}

// ---------------------------------------------------------------- 时间分布

class PunchSummary {
  const PunchSummary(
    this.max,
    this.peakWeekday,
    this.peakHour,
    this.busiestWeekday,
    this.nightShare,
  );
  final int max;

  /// 1 = 周一 … 7 = 周日。
  final int peakWeekday;
  final int peakHour;
  final int busiestWeekday;

  /// 22 点到 6 点前的占比（0–1）。
  final double nightShare;
}

int punchAt(List<int> weekHour, int weekday, int hour) =>
    weekHour[(weekday - 1) * 24 + hour];

PunchSummary punchSummary(List<int> weekHour) {
  var max = 0, pw = 1, ph = 0;
  final byDay = List<int>.filled(8, 0);
  final byHour = List<int>.filled(24, 0);
  for (var w = 1; w <= 7; w++) {
    for (var h = 0; h < 24; h++) {
      final c = punchAt(weekHour, w, h);
      byDay[w] += c;
      byHour[h] += c;
      if (c > max) {
        max = c;
        pw = w;
        ph = h;
      }
    }
  }
  var bw = 1;
  for (var w = 2; w <= 7; w++) {
    if (byDay[w] > byDay[bw]) bw = w;
  }
  final all = byHour.fold(0, (a, b) => a + b);
  final night = [22, 23, 0, 1, 2, 3, 4, 5].fold(0, (a, h) => a + byHour[h]);
  return PunchSummary(max, pw, ph, bw, all == 0 ? 0 : night / all);
}

// ---------------------------------------------------------------- Anlas

int anlasLast(Map<DateTime, int> dailyAnlas, DateTime today, int n) =>
    lastDays(dailyAnlas, today, n).fold(0, (a, b) => a + b);

// ---------------------------------------------------------------- 画幅

StatsOrientation orientationOf(int w, int h) => w == h
    ? StatsOrientation.square
    : h > w
    ? StatsOrientation.portrait
    : StatsOrientation.landscape;

Map<StatsOrientation, int> orientationTotals(List<StatsResolution> res) {
  final out = {for (final o in StatsOrientation.values) o: 0};
  for (final r in res) {
    final o = orientationOf(r.width, r.height);
    out[o] = out[o]! + r.count;
  }
  return out;
}

int totalOf<T>(List<StatsCount<T>> list) => list.fold(0, (a, c) => a + c.count);
