import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_derive.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_fixture.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_format.dart';

DateTime d(int y, int m, int day) => DateTime(y, m, day);

void main() {
  final today = d(2026, 10, 11);

  group('时间范围', () {
    test('近 N 天含今天，上一段紧挨着且一样长', () {
      final p = rangePeriod(StatsRange.days7, today)!;
      expect(p.start, d(2026, 10, 5));
      expect(p.end, d(2026, 10, 12));
      final prev = previousPeriod(StatsRange.days7, today)!;
      expect(prev.start, d(2026, 9, 28));
      expect(prev.end, d(2026, 10, 5));
    });

    test('今年对比去年同期，全部没有范围', () {
      expect(rangePeriod(StatsRange.thisYear, today)!.start, d(2026, 1, 1));
      final prev = previousPeriod(StatsRange.thisYear, today)!;
      expect(prev.start, d(2025, 1, 1));
      expect(prev.end, d(2025, 10, 12));
      expect(rangePeriod(StatsRange.all, today), isNull);
      expect(previousPeriod(StatsRange.all, today), isNull);
    });
  });

  group('连续天数', () {
    test('今天还没画时从昨天算起；最长一段带起止日期', () {
      final daily = {
        d(2026, 10, 10): 3,
        d(2026, 10, 9): 1,
        d(2026, 10, 7): 2,
        d(2026, 9, 1): 1,
        d(2026, 9, 2): 1,
        d(2026, 9, 3): 1,
      };
      final s = streaksOf(daily, today);
      expect(s.current, 2);
      expect(s.best, 3);
      expect(s.bestStart, d(2026, 9, 1));
      expect(s.bestEnd, d(2026, 9, 3));
    });

    test('今天画了就从今天算', () {
      expect(streaksOf({today: 1, d(2026, 10, 10): 1}, today).current, 2);
      expect(streaksOf({}, today).current, 0);
    });
  });

  test('日历颜色按非零值的分位数分 5 档', () {
    final th = heatThresholds([0, 1, 2, 3, 4, 5, 6, 7, 8]);
    expect(th, [2, 4, 6]);
    expect(heatLevel(0, th), 0);
    expect(heatLevel(2, th), 1);
    expect(heatLevel(3, th), 2);
    expect(heatLevel(6, th), 3);
    expect(heatLevel(8, th), 4);
  });

  test('日历窗口：最近 53 周从周一开始、到今天为止', () {
    final w = recentWindow(today, 53);
    expect(w.start.weekday, DateTime.monday);
    expect(w.last, today);
    expect(w.dayAt(52, today.weekday - 1), today);
  });

  group('产量柱', () {
    final s = StatsFixture.snapshot();

    test('近 30 天按天：30 根，合计等于这 30 天的图片数', () {
      final b = productionBuckets(
        snapshot: s,
        range: StatsRange.days30,
        today: StatsFixture.today,
        granularity: StatsGranularity.day,
      );
      expect(b, hasLength(30));
      expect(
        b.fold(0, (a, x) => a + x.total),
        sumIn(
          s.dailyImages,
          rangePeriod(StatsRange.days30, StatsFixture.today)!,
        ),
      );
    });

    test('全部按月：从有图的第一个月到本月，无元数据 = 当月总数 − 各模型合计', () {
      final b = productionBuckets(
        snapshot: s,
        range: StatsRange.all,
        today: StatsFixture.today,
        granularity: StatsGranularity.month,
      );
      expect(b.first.period.start, d(2025, 3, 1));
      expect(b.last.period.start, d(2026, 10, 1));
      expect(b.fold(0, (a, x) => a + x.total), s.libraryTotal);
      for (final x in b) {
        expect(x.counts[StatsFamily.noMetadata], greaterThanOrEqualTo(0));
      }
    });

    test('按周的柱子从周一开始', () {
      final b = productionBuckets(
        snapshot: s,
        range: StatsRange.days90,
        today: StatsFixture.today,
        granularity: StatsGranularity.week,
      );
      expect(b.every((x) => x.period.start.weekday == DateTime.monday), isTrue);
      expect(b.length, inInclusiveRange(13, 14));
    });

    test('纵轴顶值取 1 / 2 × 10ⁿ 的整数倍', () {
      expect(niceCeiling(0), 1);
      expect(niceCeiling(27164), 30000);
      expect(niceCeiling(46), 50);
      expect(niceCeiling(120), 200);
    });
  });

  test('模型系列和友好名', () {
    expect(familyOf('nai-diffusion-4-5-full'), StatsFamily.nai45);
    expect(familyOf('nai-diffusion-5-curated'), StatsFamily.nai5);
    expect(familyOf('nai-diffusion-4-curated-preview'), StatsFamily.nai4);
    expect(familyOf('nai-diffusion-furry-3'), StatsFamily.nai3);
    expect(familyOf('custom'), StatsFamily.other);
    expect(namedModel('nai-diffusion-4-5-full'), 'NAI 4.5 Full');
    expect(namedModel('custom'), isNull);
  });

  test('时间分布：峰值、最忙一天、深夜占比', () {
    final wh = List<int>.filled(168, 0);
    wh[(4 - 1) * 24 + 12] = 10;
    wh[(5 - 1) * 24 + 23] = 5;
    wh[(5 - 1) * 24 + 2] = 5;
    final p = punchSummary(wh);
    expect(p.peakWeekday, 4);
    expect(p.peakHour, 12);
    expect(p.busiestWeekday, 4);
    expect(p.nightShare, closeTo(.5, 1e-9));
  });

  test('方向按真实宽高', () {
    final o = orientationTotals(const [
      StatsResolution(832, 1216, 3),
      StatsResolution(1216, 832, 2),
      StatsResolution(1024, 1024, 1),
    ]);
    expect(o[StatsOrientation.portrait], 3);
    expect(o[StatsOrientation.landscape], 2);
    expect(o[StatsOrientation.square], 1);
  });

  group('格式', () {
    test('数字、百分比、大小', () {
      expect(StatsFormat.count(48824), '48,824');
      expect(StatsFormat.percent(1, 3, 1), '33.3%');
      expect(StatsFormat.percent(1, 0), '0%');
      expect(StatsFormat.bytes(70223183462), ('65.4', 'GB'));
      expect(StatsFormat.bytes(3 * 1048576), ('3.0', 'MB'));
      expect(StatsFormat.trim(5.0), '5');
      expect(StatsFormat.trim(5.5), '5.5');
      expect(StatsFormat.axis(22500), '22.5k');
      expect(StatsFormat.sampler('k_euler_ancestral'), 'Euler Ancestral');
      expect(StatsFormat.sampler('unknown'), 'unknown');
    });

    test('richParts 把占位拆出来加粗', () {
      expect(richParts((v) => '共 $v 张', '12'), ['共 ', '12', ' 张']);
      expect(richParts((v) => '$v images', '3'), ['', '3', ' images']);
    });
  });
}
