import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_parent_list.dart';

void main() {
  /// 父本区在谱系卡内容区的可用宽：默认画廊宽 360 - 卡边距与内边距 32。
  const defaultCardContentWidth = 328.0;

  List<ExploreParent> parents(int count) => [
    for (var i = 0; i < count; i++)
      ExploreParent(id: 'p-$i', artistString: 'artist:string-$i'),
  ];

  Future<void> pumpList(
    WidgetTester tester, {
    required List<ExploreParent> list,
    required double width,
  }) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: ExploreParentList(
                parents: list,
                thumbBuilder: (_) => const SizedBox(width: 24, height: 24),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  double topOf(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  double leftOf(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dx;

  ScrollPosition scrollPosition(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  testWidgets('默认画廊宽下两列排布：相邻父本同行、第三行起落回左列', (tester) async {
    await pumpList(tester, list: parents(4), width: defaultCardContentWidth);

    // 前两个父本同一行、左右分列。
    expect(topOf(tester, 'artist:string-0'), topOf(tester, 'artist:string-1'));
    expect(
      leftOf(tester, 'artist:string-0'),
      lessThan(leftOf(tester, 'artist:string-1')),
    );
    // 第三、四个换行且仍两列（奇数末行不拉伸另测）。
    expect(
      topOf(tester, 'artist:string-2'),
      greaterThan(topOf(tester, 'artist:string-0')),
    );
    expect(topOf(tester, 'artist:string-2'), topOf(tester, 'artist:string-3'));
  });

  testWidgets('更窄可用宽回落单列', (tester) async {
    await pumpList(tester, list: parents(2), width: 300);

    expect(
      leftOf(tester, 'artist:string-0'),
      leftOf(tester, 'artist:string-1'),
    );
    expect(
      topOf(tester, 'artist:string-0'),
      lessThan(topOf(tester, 'artist:string-1')),
    );
  });

  testWidgets('两列阈值边界：等于阈值即两列', (tester) async {
    await pumpList(
      tester,
      list: parents(2),
      width: exploreParentListTwoColumnMinWidth,
    );

    expect(
      tester.getTopLeft(find.text('artist:string-0')).dy,
      tester.getTopLeft(find.text('artist:string-1')).dy,
    );
  });

  testWidgets('奇数父本：末行单个占左列，不拉伸满宽', (tester) async {
    await pumpList(tester, list: parents(3), width: defaultCardContentWidth);

    final itemWidth = tester
        .getSize(
          find
              .ancestor(
                of: find.text('artist:string-2'),
                matching: find.byType(Row),
              )
              .first,
        )
        .width;
    expect(itemWidth, lessThan(defaultCardContentWidth / 2 + 1));
    expect(
      leftOf(tester, 'artist:string-2'),
      leftOf(tester, 'artist:string-0'),
    );
  });

  testWidgets('父本少：限高内取自然高，不出现内部滚动', (tester) async {
    await pumpList(tester, list: parents(2), width: defaultCardContentWidth);

    expect(
      tester.getSize(find.byType(ExploreParentList)).height,
      lessThan(exploreParentListMaxHeight),
    );
    expect(scrollPosition(tester).maxScrollExtent, 0);
  });

  testWidgets('父本多：限高封顶 + 内部滚动（不接力外层）', (tester) async {
    await pumpList(tester, list: parents(12), width: defaultCardContentWidth);

    expect(
      tester.getSize(find.byType(ExploreParentList)).height,
      exploreParentListMaxHeight,
    );
    final position = scrollPosition(tester);
    expect(position.maxScrollExtent, greaterThan(0));

    final before = topOf(tester, 'artist:string-0');
    await tester.drag(find.byType(ListView), const Offset(0, -40));
    await tester.pump();
    expect(position.pixels, greaterThan(0));
    expect(topOf(tester, 'artist:string-0'), lessThan(before));
  });

  testWidgets('偏好值非 1.0 才显示', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('zh'));
    await pumpList(
      tester,
      list: const [
        ExploreParent(id: 'p-0', artistString: 'a'),
        ExploreParent(id: 'p-1', artistString: 'b', preference: 2.5),
      ],
      width: defaultCardContentWidth,
    );

    expect(
      find.text(l10n.styleExplore_preferenceValue('2.50')),
      findsOneWidget,
    );
    expect(find.text(l10n.styleExplore_preferenceValue('1.00')), findsNothing);
  });

  testWidgets('无父本时不渲染任何行', (tester) async {
    await pumpList(tester, list: parents(0), width: defaultCardContentWidth);

    expect(tester.getSize(find.byType(ExploreParentList)).height, 0);
    expect(find.byType(ListView), findsNothing);
  });
}
