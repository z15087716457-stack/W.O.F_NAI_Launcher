import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'stats_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  group('各语言 × 各宽度不溢出', () {
    for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
      for (final window in [1920.0, 1600.0, 1280.0, 1000.0, 900.0, 800.0]) {
        testWidgets('$locale @ ${window.toInt()}', (tester) async {
          await pumpStats(
            tester,
            data: StatsFixture.view(),
            locale: locale,
            window: window,
            height: 3600,
          );
          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('stats-kpis')), findsOneWidget);
        });
      }
    }
  });

  group('各状态', () {
    final states = <String, StatsViewData>{
      'loading': StatsFixture.view(loading: true),
      'empty': StatsFixture.view(empty: true),
      'error': StatsFixture.view(error: 'database is locked'),
      'updating': StatsFixture.view(sync: StatsSyncState.updating),
      'failed': StatsFixture.view(sync: StatsSyncState.failed),
      'artists pending': StatsFixture.view(artistsPending: true),
      for (final r in StatsRange.values)
        'range ${r.name}': StatsFixture.view(range: r),
    };
    for (final MapEntry(:key, :value) in states.entries) {
      for (final locale in ['zh', 'en', 'ja', 'ko']) {
        testWidgets('$key · $locale', (tester) async {
          await pumpStats(
            tester,
            data: value,
            locale: locale,
            window: 1000,
            height: 3000,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('首次统计显示张数，出错显示原因', (tester) async {
      await pumpStats(tester, data: StatsFixture.view(loading: true));
      expect(find.text('正在统计 48,824 张…'), findsOneWidget);
      await pumpStats(
        tester,
        data: StatsFixture.view(error: 'database is locked'),
      );
      expect(find.text('database is locked'), findsOneWidget);
      expect(find.text('统计没有算出来'), findsOneWidget);
    });

    testWidgets('画师还在算时显示占位', (tester) async {
      await pumpStats(tester, data: StatsFixture.view(artistsPending: true));
      expect(find.text('正在统计画师…'), findsOneWidget);
      expect(find.byKey(const Key('stats-artist-0')), findsNothing);
    });
  });

  group('操作都走契约回调', () {
    testWidgets('时间范围、仅 NAI、刷新', (tester) async {
      final rec = RecordingStatsActions();
      await pumpStats(tester, data: StatsFixture.view(), actions: rec.actions);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('stats-range')),
          matching: find.text('30 天'),
        ),
      );
      await tester.tap(find.byKey(const Key('stats-nai-only')));
      await tester.tap(find.byKey(const Key('stats-refresh')));
      expect(rec.ranges, [StatsRange.days30]);
      expect(rec.naiOnly, [true]);
      expect(rec.refreshes, 1);
    });

    testWidgets('点日历格打开那一天', (tester) async {
      final rec = RecordingStatsActions();
      await pumpStats(tester, data: StatsFixture.view(), actions: rec.actions);
      final grid = tester.getRect(find.byKey(const Key('stats-calendar-grid')));
      final today = StatsFixture.today;
      // 1600 宽放得下整年 53 周，格子 14、间距 3；今天在最后一列。
      await tester.tapAt(
        grid.topLeft +
            Offset(30 + 52 * 17 + 7, 18 + (today.weekday - 1) * 17 + 7),
      );
      expect(rec.filters, [
        StatsDateFilter(
          today,
          DateTime(today.year, today.month, today.day + 1),
        ),
      ]);
    });

    testWidgets('点产量柱打开那个月；切到按天后副标题跟着变', (tester) async {
      final rec = RecordingStatsActions();
      await pumpStats(tester, data: StatsFixture.view(), actions: rec.actions);
      final chart = tester.getRect(
        find.byKey(const Key('stats-production-chart')),
      );
      await tester.tapAt(Offset(chart.right - 6, chart.top + 200));
      expect(
        rec.filters.single,
        StatsDateFilter(DateTime(2026, 10), DateTime(2026, 11)),
      );
      expect(find.text('按月，颜色是模型'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('stats-granularity')),
          matching: find.text('日'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('按天，颜色是模型'), findsOneWidget);
    });

    testWidgets('模型、尺寸、方向、参数、画师、存储都带对筛选', (tester) async {
      final rec = RecordingStatsActions();
      await pumpStats(tester, data: StatsFixture.view(), actions: rec.actions);
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await tap(find.byKey(const Key('stats-model-nai-diffusion-4-5-full')));
      await tap(find.byKey(const Key('stats-resolution-832x1216')));
      await tap(find.byKey(const Key('stats-orientation-landscape')));
      await tap(find.text('Euler Ancestral').last);
      await tap(find.text('28 步').last);
      await tap(find.byKey(const Key('stats-artist-0')));
      await tap(find.byKey(const Key('stats-storage-no-metadata')));
      await tap(find.byKey(const Key('stats-storage-large')));
      expect(rec.filters, [
        const StatsModelFilter('nai-diffusion-4-5-full'),
        const StatsResolutionFilter(832, 1216),
        const StatsOrientationFilter(StatsOrientation.landscape),
        const StatsSamplerFilter('k_euler_ancestral'),
        const StatsStepsFilter(28),
        const StatsArtistFilter('aoi mizuki'),
        const StatsNoMetadataFilter(),
        const StatsMinFileSizeFilter(10 * 1024 * 1024),
      ]);
    });

    testWidgets('“其他 N 个模型”不可点', (tester) async {
      final rec = RecordingStatsActions();
      await pumpStats(tester, data: StatsFixture.view(), actions: rec.actions);
      await tester.tap(find.text('其他 4 个模型'), warnIfMissed: false);
      expect(rec.filters, isEmpty);
    });

    testWidgets('空图库的两个按钮、出错页的重试', (tester) async {
      final rec = RecordingStatsActions();
      await pumpStats(
        tester,
        data: StatsFixture.view(empty: true),
        actions: rec.actions,
      );
      await tester.tap(find.byKey(const Key('stats-empty-generate')));
      await tester.tap(find.byKey(const Key('stats-empty-add-folder')));
      expect(rec.generates, 1);
      expect(rec.addFolders, 1);
      await pumpStats(
        tester,
        data: StatsFixture.view(error: 'x'),
        actions: rec.actions,
      );
      await tester.tap(find.byKey(const Key('stats-error-retry')));
      expect(rec.refreshes, 1);
    });
  });

  testWidgets('宽度规则：三列 / 两列 / 一列', (tester) async {
    double cardTop(String key) => tester.getRect(find.byKey(Key(key))).top;
    await pumpStats(
      tester,
      data: StatsFixture.view(),
      window: 1600,
      height: 3000,
    );
    expect(cardTop('stats-anlas'), cardTop('stats-punch'));
    expect(cardTop('stats-aspect'), cardTop('stats-punch'));
    await pumpStats(
      tester,
      data: StatsFixture.view(),
      window: 1000,
      height: 3600,
    );
    expect(cardTop('stats-anlas'), cardTop('stats-punch'));
    expect(cardTop('stats-aspect'), greaterThan(cardTop('stats-punch')));
    await pumpStats(
      tester,
      data: StatsFixture.view(),
      window: 720,
      height: 5000,
    );
    expect(cardTop('stats-anlas'), greaterThan(cardTop('stats-punch')));
  });
}
