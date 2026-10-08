import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/library/library_widgets.dart';
import 'library_test_helpers.dart';

void main() {
  testWidgets('selection callbacks and narrow overflow retain every action', (
    tester,
  ) async {
    var exits = 0, all = 0, inverse = 0, actions = 0;
    Widget bar(double width) => Center(
      child: SizedBox(
        width: width,
        child: LibrarySelectionBar(
          selectedCount: 4,
          onExit: () => exits++,
          onSelectAll: () => all++,
          onInvertSelection: () => inverse++,
          actions: [
            LibraryAction(
              label: '加入生图页',
              icon: 'plus',
              primary: true,
              onPressed: () => actions++,
            ),
            LibraryAction(
              label: '导出',
              icon: 'upload',
              onPressed: () => actions++,
            ),
            LibraryAction(
              label: '删除',
              icon: 'trash',
              onPressed: () => actions++,
            ),
          ],
        ),
      ),
    );
    await pumpLibrary(tester, bar(1000));
    await tester.tap(find.byTooltip('全选'));
    await tester.tap(find.byTooltip('反选'));
    await tester.tap(find.text('加入生图页'));
    await tester.tap(find.byTooltip('关闭'));
    expect([all, inverse, actions, exits], [1, 1, 1, 1]);
    await pumpLibrary(tester, bar(220));
    await tester.tap(find.byKey(const Key('library-selection-overflow')));
    await tester.pumpAndSettle();
    expect(find.text('导出'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(actions, 2);
    expect(tester.takeException(), isNull);
  });
}
