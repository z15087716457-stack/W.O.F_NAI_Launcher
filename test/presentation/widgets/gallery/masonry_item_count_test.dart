import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// 最小复现：MasonryGridView.count 的 itemCount 减少时，旧条目是否残留。
/// 不依赖任何项目代码——纯包行为验证。
void main() {
  testWidgets('itemCount 减少时旧卡片应消失', (tester) async {
    Widget build(int count) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: MasonryGridView.count(
              crossAxisCount: 2,
              itemCount: count,
              itemBuilder: (_, i) => SizedBox(
                key: ValueKey('item_$i'),
                height: 120,
                child: Text('item $i'),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('item_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('item_2')), findsOneWidget);

    // 模拟删除：itemCount 3→2，同 key 的 grid（PageStorageKey 场景）
    await tester.pumpWidget(build(2));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey('item_2')),
      findsNothing,
      reason: 'itemCount 减少后，被移除的卡片不应残留在渲染树',
    );
    expect(find.byKey(const ValueKey('item_1')), findsOneWidget);
  });
}
