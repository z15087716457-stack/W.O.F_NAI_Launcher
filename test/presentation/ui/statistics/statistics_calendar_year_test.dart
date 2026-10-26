import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_calendar.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_layout.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../refs/refs_test_harness.dart' show refsApp;

void main() {
  setUpAll(loadStudioCaptureFonts);
  Future<AppLocalizations> calendar(
    WidgetTester t,
    DateTime today,
    Map<DateTime, int> daily,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1800, 1000);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final total = daily.values.fold(0, (a, b) => a + b);
    final snapshot = StatsSnapshot(
      libraryTotal: total,
      images: total,
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
      dailyImages: daily,
      dailyModels: const [],
      monthlyBytes: const {},
      dailyAnlas: const {},
    );
    await t.pumpWidget(
      refsApp(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 1440,
            child: StatsCalendarCard(
              data: StatsViewData(
                range: StatsRange.all,
                naiOnly: false,
                today: today,
                sync: StatsSyncState.idle,
                snapshot: snapshot,
              ),
              snapshot: snapshot,
              actions: StatsActions.none,
              layout: const StatsLayout(1800),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    return AppLocalizations.of(t.element(find.byType(StatsCalendarCard)))!;
  }

  Future<void> year(WidgetTester t, int value) async {
    await t.tap(find.byKey(const Key('stats-calendar-year')));
    await t.pumpAndSettle();
    await t.tap(find.text('$value 年'));
    await t.pumpAndSettle();
  }

  String summary(WidgetTester t, String label) {
    final column = find
        .ancestor(of: find.text(label), matching: find.byType(Column))
        .first;
    return (t.widget<Column>(column).children.first as Text).textSpan!
        .toPlainText();
  }

  for (final value in [2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026]) {
    testWidgets(
      '$value annual metrics exclude grid padding on weekday ${DateTime(value).weekday}',
      (t) async {
        final labels = await calendar(t, DateTime(2030, 6, 30), {
          DateTime(value - 1, 12, 31): 100,
          DateTime(value, 1, 1): 2,
          DateTime(value, 12, 31): 3,
          DateTime(value + 1, 1, 1): 200,
        });
        await year(t, value);
        final days = DateTime(value + 1).difference(DateTime(value)).inDays;
        expect(summary(t, labels.stats_calendarImagesInYear('$value')), '5');
        expect(summary(t, labels.stats_calendarActiveDays), '2 / $days');
        expect(summary(t, labels.stats_calendarBestDay), '3');
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets('the current year stops at today for every annual metric', (
    t,
  ) async {
    final labels = await calendar(t, DateTime(2026, 1, 5), {
      DateTime(2025, 12, 31): 100,
      DateTime(2026, 1, 1): 2,
      DateTime(2026, 1, 5): 3,
      DateTime(2026, 1, 6): 80,
    });
    await year(t, 2026);
    expect(summary(t, labels.stats_calendarImagesInYear('2026')), '5');
    expect(summary(t, labels.stats_calendarActiveDays), '2 / 5');
    expect(summary(t, labels.stats_calendarBestDay), '3');
  });

  testWidgets('the recent-year view still includes valid previous-year days', (
    t,
  ) async {
    final labels = await calendar(t, DateTime(2026, 1, 5), {
      DateTime(2025, 12, 31): 100,
      DateTime(2026, 1, 1): 2,
      DateTime(2026, 1, 5): 3,
      DateTime(2026, 1, 6): 80,
    });
    expect(summary(t, labels.stats_calendarImagesPastYear), '105');
    expect(summary(t, labels.stats_calendarBestDay), '100');
  });
}
