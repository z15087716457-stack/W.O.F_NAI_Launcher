import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/utils/list_reorder.dart';

/// 拖拽重排下标计算（removeAt(oldIndex) 后 insert(newIndex) 语义，
/// 与 ReorderableListView / 侧栏排序持久化共用）。
void main() {
  group('computeReorderInsertIndex', () {
    test('insert before target shifts down when moving down', () {
      // [A,B,C,D] 把 B(1) 插到 D(3) 之前 → 最终 [A,C,B,D]
      expect(
        computeReorderInsertIndex(oldIndex: 1, targetIndex: 3, insertAfter: false),
        2,
      );
    });

    test('insert after target shifts down when moving down', () {
      // [A,B,C,D] 把 A(0) 插到 C(2) 之后 → 最终 [B,C,A,D]
      expect(
        computeReorderInsertIndex(oldIndex: 0, targetIndex: 2, insertAfter: true),
        2,
      );
    });

    test('moving up keeps raw index', () {
      // [A,B,C,D] 把 C(2) 插到 A(0) 之前 → 最终 [C,A,B,D]
      expect(
        computeReorderInsertIndex(oldIndex: 2, targetIndex: 0, insertAfter: false),
        0,
      );
      // [A,B,C,D] 把 D(3) 插到 B(1) 之后 → 最终 [A,B,D,C]
      expect(
        computeReorderInsertIndex(oldIndex: 3, targetIndex: 1, insertAfter: true),
        2,
      );
    });

    test('moving to first/last position', () {
      // 拖到列表最前
      expect(
        computeReorderInsertIndex(oldIndex: 3, targetIndex: 0, insertAfter: false),
        0,
      );
      // 拖到最后（target=末尾项 insertAfter）
      expect(
        computeReorderInsertIndex(oldIndex: 0, targetIndex: 3, insertAfter: true),
        3,
      );
    });

    test('drop on own position yields unchanged index', () {
      // 拖到自己前面/后面都回到原下标
      expect(
        computeReorderInsertIndex(oldIndex: 1, targetIndex: 1, insertAfter: false),
        1,
      );
      expect(
        computeReorderInsertIndex(oldIndex: 1, targetIndex: 1, insertAfter: true),
        1,
      );
    });
  });

  group('removeAt+insert round-trip', () {
    test('applying computed index reproduces expected order', () {
      const list = ['A', 'B', 'C', 'D'];
      final reordered = [...list];
      final item = reordered.removeAt(0);
      reordered.insert(
        computeReorderInsertIndex(oldIndex: 0, targetIndex: 2, insertAfter: true),
        item,
      );
      expect(reordered, ['B', 'C', 'A', 'D']);
    });
  });
}
