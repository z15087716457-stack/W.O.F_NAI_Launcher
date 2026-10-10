// 和 HTML 原型同数据、同尺寸、同状态的实绘，供 tool/ui_shell/compare.py 并排 / 叠加对照。
// 运行：flutter test tool/ui_shell/stats_prototype_capture_test.dart
// 数据来自 .devin/mockups/stats/data.js（用户图库聚合数），只在本机读取，输出不进仓库。
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

import '../../test/helpers/studio_capture_fonts.dart';
import 'stats_prototype_data.dart';

const _rail = 48.0;

void main() {
  final out = Directory(
    Platform.environment['STATS_CAPTURE_DIR'] ??
        '.dart_tool/ui-shell/stats/flutter',
  )..createSync(recursive: true);
  final proto = StatsPrototypeData.load(
    Platform.environment['STATS_PROTO_DATA'] ?? '../../mockups/stats/data.js',
  );
  setUpAll(loadStudioCaptureFonts);

  Future<void> shot(
    WidgetTester tester,
    String name, {
    required StatsViewData data,
    required bool dark,
    double window = 1600,
    double height = 1800,
    String locale = 'zh',
    Future<void> Function()? interact,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(window - _rail, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final theme = dark ? GeistTheme.dark : GeistTheme.light;
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            body: WindowChromeScope(
              child: StatisticsPage(data: data, actions: StatsActions.none),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (interact != null) {
      await interact();
      await tester.pumpAndSettle();
    }
    final error = tester.takeException();
    if (error != null) {
      fail(error is FlutterError ? error.toStringDeep() : '$error');
    }
    final bytes = await tester.runAsync(() async {
      final ro = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('capture')),
      );
      final img = await ro.toImage();
      return (await img.toByteData(format: ui.ImageByteFormat.png))!;
    });
    File('${out.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  StatsViewData data({
    StatsRange range = StatsRange.all,
    StatsSnapshot? snapshot,
    bool loading = false,
    bool empty = false,
  }) => StatsViewData(
    range: range,
    naiOnly: false,
    today: proto.today,
    sync: StatsSyncState.idle,
    updatedAt: proto.updatedAt,
    countingImages: loading ? 48824 : null,
    snapshot: loading
        ? null
        : empty
        ? _empty(proto.today)
        : snapshot ?? proto.snapshot(last30: range == StatsRange.days30),
  );

  Future<void> hoverAt(WidgetTester tester, Offset p) async {
    final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: Offset.zero);
    addTearDown(g.removePointer);
    await g.moveTo(p);
  }

  for (final dark in [false, true]) {
    final t = dark ? '-dark' : '';
    testWidgets(
      'main$t',
      (tester) => shot(tester, 'main$t', data: data(), dark: dark),
    );
    testWidgets(
      'r30$t',
      (tester) => shot(
        tester,
        'r30$t',
        data: data(range: StatsRange.days30),
        dark: dark,
      ),
    );
    testWidgets(
      'narrow$t',
      (tester) => shot(
        tester,
        'narrow$t',
        data: data(),
        dark: dark,
        window: 1000,
        height: 2600,
      ),
    );
    testWidgets(
      'loading$t',
      (tester) => shot(
        tester,
        'loading$t',
        data: data(loading: true),
        dark: dark,
        height: 1000,
      ),
    );
    testWidgets(
      'empty$t',
      (tester) => shot(
        tester,
        'empty$t',
        data: data(empty: true),
        dark: dark,
        height: 1000,
      ),
    );
    testWidgets(
      'hover$t',
      (tester) => shot(
        tester,
        'hover$t',
        data: data(),
        dark: dark,
        interact: () async {
          // 日历 2026-08-21：原型 hot=20260821。
          final grid = tester.getRect(
            find.byKey(const Key('stats-calendar-grid')),
          );
          final weeksBack =
              DateTime(2026, 10, 5).difference(DateTime(2026, 8, 17)).inDays ~/
              7;
          final col = 52 - weeksBack;
          await hoverAt(
            tester,
            grid.topLeft + Offset(30 + col * 17 + 7, 18 + 4 * 17 + 7),
          );
        },
      ),
    );
    testWidgets(
      'hover-bar$t',
      (tester) => shot(
        tester,
        'hover-bar$t',
        data: data(),
        dark: dark,
        interact: () async {
          final chart = tester.getRect(
            find.byKey(const Key('stats-production-chart')),
          );
          final bw = (chart.width - 40) / 20;
          await hoverAt(
            tester,
            chart.topLeft + Offset(40 + 17 * bw + bw / 2, 200),
          );
        },
      ),
    );
    testWidgets(
      'hover-artist$t',
      (tester) => shot(
        tester,
        'hover-artist$t',
        data: data(),
        dark: dark,
        interact: () async {
          await hoverAt(
            tester,
            tester.getCenter(find.byKey(const Key('stats-artist-0'))),
          );
        },
      ),
    );
  }

  for (final locale in ['en', 'ja', 'ko']) {
    testWidgets(
      'main-$locale',
      (tester) => shot(
        tester,
        'main-$locale',
        data: data(),
        dark: false,
        locale: locale,
      ),
    );
    testWidgets(
      'narrow-$locale',
      (tester) => shot(
        tester,
        'narrow-$locale',
        data: data(),
        dark: false,
        locale: locale,
        window: 1000,
        height: 2600,
      ),
    );
  }
  for (final w in [1280.0, 1920.0]) {
    testWidgets(
      'main-${w.toInt()}',
      (tester) => shot(
        tester,
        'main-${w.toInt()}',
        data: data(),
        dark: false,
        window: w,
      ),
    );
  }
}

StatsSnapshot _empty(DateTime today) => StatsSnapshot(
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
