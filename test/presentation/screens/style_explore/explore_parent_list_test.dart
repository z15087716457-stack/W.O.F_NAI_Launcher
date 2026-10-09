import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_parent_list.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    List<ExploreParent> parents, {
    double height = double.infinity,
    Set<String> backcross = const {},
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 272,
              child: ExploreParentList(
                parents: parents,
                maxHeight: height,
                backcrossStrings: backcross,
                thumbBuilder: (_) => const ColoredBox(color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('降序显示、偏好条按最大值归一，原数据不变', (tester) async {
    const list = [
      ExploreParent(id: 'a', artistString: 'artist:low', preference: 2),
      ExploreParent(id: 'b', artistString: 'artist:high', preference: 4),
    ];
    await pump(tester, list);
    expect(
      tester.getTopLeft(find.byKey(const Key('explore-parent-b'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('explore-parent-a'))).dy),
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('explore-preference-a')),
          )
          .value,
      .5,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('explore-preference-b')),
          )
          .value,
      1,
    );
    expect(list.first.id, 'a');
    expect(find.text('1.0'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('回交标记、等偏好稳定排序、零偏好不除零', (tester) async {
    const list = [
      ExploreParent(id: 'a', artistString: 'artist:first', preference: 0),
      ExploreParent(id: 'b', artistString: 'artist:second', preference: 0),
    ];
    await pump(tester, list, backcross: {'artist:first'});
    expect(find.text('回交'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('explore-preference-a')),
          )
          .value,
      0,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('explore-parent-a'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('explore-parent-b'))).dy),
    );
  });
  testWidgets('有限高度可滚，无父本为空', (tester) async {
    await pump(tester, [
      for (var i = 0; i < 12; i++)
        ExploreParent(id: 'p$i', artistString: 'artist:$i'),
    ], height: 120);
    expect(tester.getSize(find.byType(ExploreParentList)).height, 120);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .maxScrollExtent,
      greaterThan(0),
    );
    await pump(tester, []);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
