import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/online/online_contract.dart';
import 'package:nai_launcher/presentation/ui/online/online_fixture.dart';
import 'package:nai_launcher/presentation/ui/online/online_wall.dart';

import 'online_test_harness.dart';

void main() {
  final works = List.generate(
    500,
    (i) => OnlineWork(key: 'w$i', id: i, width: 100, height: 100),
  );
  OnlineViewData data(String key, double offset, {int? count}) =>
      OnlineFixture.view(
        selectedKey: null,
        sidebarOpen: false,
        inspectorOpen: false,
        list: OnlineList(
          key: key,
          items: count == null ? works : works.take(count).toList(),
          initialOffset: offset,
        ),
      );

  ScrollController wall(WidgetTester tester) => tester
      .widget<SingleChildScrollView>(find.byKey(const Key('online-wall')))
      .controller!;

  testWidgets(
    'small trackpad movements reuse mounted masonry cards; long jumps fill the viewport',
    (tester) async {
      await pumpOnline(
        tester,
        data: data('ranking', 0),
        window: 900,
        height: 550,
      );
      final point = tester.getCenter(find.byKey(const Key('online-wall')));
      final initial = tester
          .widgetList<OnlineCard>(find.byType(OnlineCard))
          .map((c) => c.work.key)
          .toSet();
      var rebuilds = 0;
      final original = debugOnRebuildDirtyWidget;
      debugOnRebuildDirtyWidget = (element, builtOnce) {
        original?.call(element, builtOnce);
        if (element.widget is OnlineCard) rebuilds++;
      };
      addTearDown(() => debugOnRebuildDirtyWidget = original);
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      await gesture.panZoomStart(point);
      for (var i = 0; i < 24; i++) {
        await gesture.moveBy(const Offset(0, -4));
        await tester.pump(const Duration(milliseconds: 8));
      }
      expect(wall(tester).offset, greaterThan(60));
      expect(
        rebuilds,
        0,
        reason: 'cards already cover this part of the viewport',
      );
      await gesture.up();
      await tester.pumpAndSettle();
      wall(tester).jumpTo(20000);
      await tester.pumpAndSettle();
      final visible = find.byType(OnlineCard).hitTestable();
      expect(visible, findsWidgets);
      expect(
        tester
            .widgetList<OnlineCard>(visible)
            .every((card) => !initial.contains(card.work.key)),
        isTrue,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'shrinking a gallery while deep in the list keeps the last cards visible',
    (tester) async {
      await pumpOnline(
        tester,
        data: data('favorites', 0),
        window: 900,
        height: 550,
      );
      wall(tester).jumpTo(20000);
      await tester.pump();
      await tester.pumpWidget(onlineApp(data('favorites', 0, count: 12), null));
      await tester.pumpAndSettle();
      expect(wall(tester).offset, wall(tester).position.maxScrollExtent);
      expect(find.byType(OnlineCard).hitTestable(), findsWidgets);
    },
  );

  testWidgets(
    'switching between populated gallery lists restores each list offset',
    (tester) async {
      await pumpOnline(
        tester,
        data: data('ranking', 120),
        window: 900,
        height: 550,
      );
      expect(wall(tester).offset, 120);
      wall(tester).jumpTo(920);
      await tester.pump();
      await tester.pumpWidget(onlineApp(data('favorites', 310), null));
      await tester.pumpAndSettle();
      expect(wall(tester).offset, 310);
      await tester.pumpWidget(onlineApp(data('ranking', 920), null));
      await tester.pumpAndSettle();
      expect(wall(tester).offset, 920);
    },
  );
}
