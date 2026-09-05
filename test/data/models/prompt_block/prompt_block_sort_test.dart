import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_sort.dart';

PromptBlock _block(
  String id,
  String title, {
  DateTime? updatedAt,
  String color = '#FF607D8B',
  String? iconName,
  String? folderId,
}) {
  final at = updatedAt ?? DateTime(2026, 1, 1);
  return PromptBlock(
    id: id,
    title: title,
    content: 'content-$id',
    color: color,
    iconName: iconName,
    folderId: folderId,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  group('comparePromptBlocksBy', () {
    test('custom 恒为零（保持外部传入顺序）', () {
      final a = _block('a', 'B');
      final b = _block('b', 'a');
      expect(comparePromptBlocksBy(PromptBlockSortField.custom, a, b), 0);
    });

    test('updated 按更新时间，同键回退标题再回退 ID', () {
      final older = _block('x', 'same', updatedAt: DateTime(2026, 1, 1));
      final newer = _block('y', 'same', updatedAt: DateTime(2026, 1, 2));
      expect(
        comparePromptBlocksBy(PromptBlockSortField.updated, older, newer),
        lessThan(0),
      );
      final a = _block('a', 'same', updatedAt: DateTime(2026, 1, 1));
      final b = _block('b', 'same', updatedAt: DateTime(2026, 1, 1));
      expect(
        comparePromptBlocksBy(PromptBlockSortField.updated, a, b),
        lessThan(0),
      );
    });

    test('title 不区分大小写', () {
      final a = _block('a', 'banana');
      final b = _block('b', 'Apple');
      expect(
        comparePromptBlocksBy(PromptBlockSortField.title, a, b),
        greaterThan(0),
      );
    });

    test('color 同色聚在一起，组内按标题', () {
      final redZ = _block('a', 'zeta', color: '#FFE53935');
      final redA = _block('b', 'alpha', color: '#FFE53935');
      final blue = _block('c', 'mid', color: '#FF1E88E5');
      const field = PromptBlockSortField.color;
      expect(comparePromptBlocksBy(field, redA, redZ), lessThan(0));
      expect(comparePromptBlocksBy(field, redZ, blue), greaterThan(0));
    });

    test('icon 无图标排最前，同图标按标题', () {
      final noIcon = _block('a', 'zebra', iconName: null);
      final tagB = _block('b', 'bravo', iconName: 'tag');
      final tagA = _block('c', 'alpha', iconName: 'tag');
      const field = PromptBlockSortField.icon;
      expect(comparePromptBlocksBy(field, noIcon, tagB), lessThan(0));
      expect(comparePromptBlocksBy(field, tagA, tagB), lessThan(0));
    });
  });

  group('sortPromptBlocks', () {
    final blocks = [
      _block('a', 'Charlie', updatedAt: DateTime(2026, 3, 1), color: '#FF1E88E5', iconName: 'star'),
      _block('b', 'alpha', updatedAt: DateTime(2026, 1, 1), color: '#FFE53935', iconName: 'tag'),
      _block('c', 'Bravo', updatedAt: DateTime(2026, 2, 1), color: '#FFE53935'),
    ];

    test('custom 原样返回（不重排）', () {
      final result = sortPromptBlocks(blocks, PromptBlockSortField.custom);
      expect(result.map((b) => b.id), ['a', 'b', 'c']);
    });

    test('title 升序与降序', () {
      final asc = sortPromptBlocks(blocks, PromptBlockSortField.title);
      expect(asc.map((b) => b.id), ['b', 'c', 'a']);
      final desc = sortPromptBlocks(
        blocks,
        PromptBlockSortField.title,
        descending: true,
      );
      expect(desc.map((b) => b.id), ['a', 'c', 'b']);
    });

    test('updated 升序按时间，倒序反转', () {
      final asc = sortPromptBlocks(blocks, PromptBlockSortField.updated);
      expect(asc.map((b) => b.id), ['b', 'c', 'a']);
      final desc = sortPromptBlocks(
        blocks,
        PromptBlockSortField.updated,
        descending: true,
      );
      expect(desc.map((b) => b.id), ['a', 'c', 'b']);
    });

    test('color 同色相邻，组内按标题', () {
      final result = sortPromptBlocks(blocks, PromptBlockSortField.color);
      // 蓝(#FF1E88E5) 字典序在红(#FFE53935) 前；红组内 alpha 在 Bravo 前。
      expect(result.map((b) => b.id), ['a', 'b', 'c']);
    });

    test('icon 无图标最前，其余按图标名', () {
      final result = sortPromptBlocks(blocks, PromptBlockSortField.icon);
      expect(result.map((b) => b.id), ['c', 'a', 'b']);
    });

    test('不修改传入列表', () {
      final original = [...blocks];
      sortPromptBlocks(blocks, PromptBlockSortField.title, descending: true);
      expect(blocks.map((b) => b.id), original.map((b) => b.id));
    });

    test('同主键时按文件夹树序回退，同文件夹内按标题', () {
      // folderA 树序 1、folderB 树序 2（0 是根目录）。
      const folderOrder = {null: 0, 'folderA': 1, 'folderB': 2};
      final mixed = [
        _block('a', 'zulu', color: '#FFE53935', folderId: 'folderB'),
        _block('b', 'yankee', color: '#FFE53935', folderId: 'folderA'),
        _block('c', 'alpha', color: '#FFE53935', folderId: 'folderA'),
        _block('d', 'bravo', color: '#FFE53935'),
      ];
      final result = sortPromptBlocks(
        mixed,
        PromptBlockSortField.color,
        folderOrder: folderOrder,
      );
      // 同色簇内：根目录块（树序 0）→ folderA（alpha 在 yankee 前）→ folderB。
      expect(result.map((b) => b.id), ['d', 'c', 'b', 'a']);
    });

    test('icon 排序同样按文件夹树序回退', () {
      const folderOrder = {null: 0, 'folderA': 1, 'folderB': 2};
      final mixed = [
        _block('a', 'alpha', iconName: 'tag', folderId: 'folderB'),
        _block('b', 'alpha', iconName: 'tag', folderId: 'folderA'),
      ];
      final result = sortPromptBlocks(
        mixed,
        PromptBlockSortField.icon,
        folderOrder: folderOrder,
      );
      expect(result.map((b) => b.id), ['b', 'a']);
    });

    test('不在映射里的文件夹排在已知文件夹之后', () {
      const folderOrder = {null: 0, 'folderA': 1};
      final mixed = [
        _block('a', 'alpha', color: '#FFE53935', folderId: 'orphan'),
        _block('b', 'alpha', color: '#FFE53935', folderId: 'folderA'),
      ];
      final result = sortPromptBlocks(
        mixed,
        PromptBlockSortField.color,
        folderOrder: folderOrder,
      );
      expect(result.map((b) => b.id), ['b', 'a']);
    });

    test('updated 同时间按文件夹树序回退', () {
      const folderOrder = {null: 0, 'folderA': 1, 'folderB': 2};
      final at = DateTime(2026, 5, 1);
      final mixed = [
        _block('a', 'alpha', updatedAt: at, folderId: 'folderB'),
        _block('b', 'alpha', updatedAt: at, folderId: 'folderA'),
      ];
      final result = sortPromptBlocks(
        mixed,
        PromptBlockSortField.updated,
        folderOrder: folderOrder,
      );
      expect(result.map((b) => b.id), ['b', 'a']);
    });

    test('descending 连同文件夹回退一起反转', () {
      const folderOrder = {null: 0, 'folderA': 1, 'folderB': 2};
      final mixed = [
        _block('a', 'alpha', color: '#FFE53935', folderId: 'folderB'),
        _block('b', 'bravo', color: '#FFE53935', folderId: 'folderA'),
      ];
      final result = sortPromptBlocks(
        mixed,
        PromptBlockSortField.color,
        descending: true,
        folderOrder: folderOrder,
      );
      expect(result.map((b) => b.id), ['a', 'b']);
    });
  });

  group('PromptBlockSortField.fromStorage', () {
    test('解析已知值并拒绝未知值', () {
      expect(
        PromptBlockSortField.fromStorage('updated'),
        PromptBlockSortField.updated,
      );
      expect(PromptBlockSortField.fromStorage(null), isNull);
      expect(PromptBlockSortField.fromStorage('bogus'), isNull);
    });

    test('storageValue 往返', () {
      for (final field in PromptBlockSortField.values) {
        expect(
          PromptBlockSortField.fromStorage(field.storageValue),
          field,
        );
      }
    });
  });
}
