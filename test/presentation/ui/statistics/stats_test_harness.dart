import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

/// 主导航宽度：页面可用宽度 = 窗口宽 − 48。
const statsRail = 48.0;

/// 按“窗口宽”装一个统计页（和应用里一样扣掉主导航），关掉动画，带窗口按钮避让。
Future<void> pumpStats(
  WidgetTester tester, {
  required StatsViewData data,
  StatsActions? actions,
  double window = 1600,
  double height = 1800,
  String locale = 'zh',
  bool dark = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(window - statsRail, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('stats-capture'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? GeistTheme.dark : GeistTheme.light,
        locale: locale.contains('_')
            ? Locale(locale.split('_')[0], locale.split('_')[1])
            : Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: WindowChromeScope(
            child: StatisticsPage(
              data: data,
              actions: actions ?? StatsActions.none,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 记录所有回调，断言用。
class RecordingStatsActions {
  final ranges = <StatsRange>[];
  final naiOnly = <bool>[];
  final filters = <StatsGalleryFilter>[];
  var refreshes = 0;
  var generates = 0;
  var addFolders = 0;

  StatsActions get actions => StatsActions(
    onRangeChanged: ranges.add,
    onNaiOnlyChanged: naiOnly.add,
    onRefresh: () => refreshes++,
    onOpenGallery: filters.add,
    onGoGenerate: () => generates++,
    onAddGalleryFolder: () => addFolders++,
  );
}
