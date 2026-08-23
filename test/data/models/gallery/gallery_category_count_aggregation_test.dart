import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/data/models/gallery/gallery_category.dart';

/// 外部图库源计数聚合：父节点 = 自身直计数 + 所有后代直计数之和，
/// 与「选中后按路径前缀过滤的实际图数」口径一致。
void main() {
  group('withAggregatedImageCounts', () {
    GalleryCategory cat(String id, {String? parentId, required int direct}) {
      return GalleryCategory(
        id: id,
        name: id,
        folderPath: id,
        parentId: parentId,
        imageCount: direct,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    test('aggregates multi-level tree: parent = sum of descendants', () {
      // 外部图库源根节点：01_图库(0) ─┬─ NAI 3(283)
      //                             ├─ NAI 4(675)
      //                             └─ 杂物(5) ── 子(3)
      final categories = [
        cat('root', direct: 0),
        cat('n3', parentId: 'root', direct: 283),
        cat('n4', parentId: 'root', direct: 675),
        cat('zz', parentId: 'root', direct: 5),
        cat('zz-child', parentId: 'zz', direct: 3),
      ];

      final aggregated = categories.withAggregatedImageCounts();
      final byId = {for (final c in aggregated) c.id: c.imageCount};

      expect(byId['root'], 283 + 675 + 5 + 3);
      expect(byId['n3'], 283);
      expect(byId['n4'], 675);
      expect(byId['zz'], 5 + 3);
      expect(byId['zz-child'], 3);
    });

    test('leaf-only list keeps counts unchanged', () {
      final categories = [
        cat('a', direct: 3),
        cat('b', direct: 7),
      ];

      final aggregated = categories.withAggregatedImageCounts();
      expect(aggregated.map((c) => c.imageCount).toList(), [3, 7]);
    });

    test('root with direct files adds them into aggregate', () {
      final categories = [
        cat('root', direct: 2),
        cat('child', parentId: 'root', direct: 4),
      ];

      final aggregated = categories.withAggregatedImageCounts();
      expect(aggregated.first.imageCount, 6);
    });

    test('does not mutate original list entries', () {
      final categories = [cat('root', direct: 1), cat('c', parentId: 'root', direct: 2)];

      categories.withAggregatedImageCounts();

      expect(categories[0].imageCount, 1);
      expect(categories[1].imageCount, 2);
    });

    test('深树（链式 100 层）不递归爆栈且计数正确', () {
      final categories = <GalleryCategory>[
        cat('root', direct: 1),
        for (var i = 0; i < 100; i++)
          cat('level_$i', parentId: i == 0 ? 'root' : 'level_${i - 1}', direct: 1),
      ];

      final aggregated = categories.withAggregatedImageCounts();
      final byId = {for (final c in aggregated) c.id: c.imageCount};

      expect(byId['root'], 101);
      expect(byId['level_99'], 1);
      // level_50 子树 = level_50..level_99 共 50 个节点
      expect(byId['level_50'], 50);
    });

    test('环引用（异常数据）被截断，不无限递归', () {
      // 手工构造环形引用：x 的父是 z → x→y→z→x 环（正常流程有
      // wouldCreateCycle 拦着，这里只验证异常数据下不挂死）
      final withCycle = [
        cat('x', parentId: 'z', direct: 5),
        cat('y', parentId: 'x', direct: 6),
        cat('z', parentId: 'y', direct: 7),
      ];

      final aggregated = withCycle.withAggregatedImageCounts();

      // 终止且每个节点都拿到计数（环内会重复计入子树，仅保证不崩）
      expect(aggregated, hasLength(3));
      final byId = {for (final c in aggregated) c.id: c.imageCount};
      expect(byId['x']!, greaterThanOrEqualTo(5));
      expect(byId['y']!, greaterThanOrEqualTo(6));
      expect(byId['z']!, greaterThanOrEqualTo(7));
    });
  });
}
