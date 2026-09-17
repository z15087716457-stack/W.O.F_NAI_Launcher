import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/data/models/prompt_block/prompt_block_collection.dart';

void main() {
  PromptBlockCollection makeNode(
    String id, {
    String? parentId,
    bool isFolder = false,
    int sortOrder = 0,
    List<String> blockIds = const [],
  }) {
    return PromptBlockCollection.create(
      id: id,
      name: id,
      parentId: parentId,
      isFolder: isFolder,
      sortOrder: sortOrder,
      blockIds: blockIds,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  group('PromptBlockCollection', () {
    test('create trims name and fills defaults', () {
      final node = PromptBlockCollection.create(name: '  收藏集  ');
      expect(node.name, '收藏集');
      expect(node.isFolder, isFalse);
      expect(node.blockIds, isEmpty);
      expect(node.isRoot, isTrue);
    });

    test('fromJson round-trips all fields', () {
      final node = makeNode(
        'c1',
        parentId: 'f1',
        isFolder: false,
        sortOrder: 3,
        blockIds: const ['b1', 'b2'],
      );
      final restored = PromptBlockCollection.fromJson(node.toJson());
      expect(restored, node);
      expect(restored.blockIds, ['b1', 'b2']);
    });

    test('displayName falls back for empty names', () {
      expect(makeNode('x', parentId: null).copyWith(name: '').displayName,
          isNotEmpty);
    });
  });

  group('PromptBlockCollectionListExtension', () {
    // 树形：根级 [folder1(sort 0), col-a(sort 1)]；
    // folder1 下 [col-b, folder2]；folder2 下 [col-c]。
    List<PromptBlockCollection> buildTree() => [
          makeNode('folder1', isFolder: true, sortOrder: 0),
          makeNode('col-a', sortOrder: 1),
          makeNode('col-b', parentId: 'folder1', sortOrder: 0),
          makeNode('folder2', parentId: 'folder1', isFolder: true, sortOrder: 1),
          makeNode('col-c', parentId: 'folder2'),
        ];

    test('childrenOf returns direct children in user order', () {
      final tree = buildTree();
      expect(tree.childrenOf(null).map((n) => n.id), ['folder1', 'col-a']);
      expect(tree.childrenOf('folder1').map((n) => n.id), [
        'col-b',
        'folder2',
      ]);
      expect(tree.childrenOf('col-a'), isEmpty);
      expect(tree.rootNodes.map((n) => n.id), ['folder1', 'col-a']);
    });

    test('getDescendantIds returns whole subtree', () {
      final tree = buildTree();
      expect(tree.getDescendantIds('folder1'), {
        'col-b',
        'folder2',
        'col-c',
      });
      expect(tree.getDescendantIds('col-a'), isEmpty);
    });

    test('wouldCreateCycle guards folder moves', () {
      final tree = buildTree();
      expect(tree.wouldCreateCycle('folder1', 'folder2'), isTrue);
      expect(tree.wouldCreateCycle('folder1', 'folder1'), isTrue);
      expect(tree.wouldCreateCycle('col-a', 'folder1'), isFalse);
      expect(tree.wouldCreateCycle('folder2', null), isFalse);
    });

    test('getPath resolves root-to-node chain', () {
      final tree = buildTree();
      expect(tree.getPath('col-c').map((n) => n.id), [
        'folder1',
        'folder2',
        'col-c',
      ]);
      expect(tree.getPath('col-a').map((n) => n.id), ['col-a']);
      expect(() => tree.getPath('missing'), throwsArgumentError);
    });
  });
}
