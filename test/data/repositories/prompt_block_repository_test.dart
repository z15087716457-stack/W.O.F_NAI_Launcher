import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';

void main() {
  late Directory hiveDirectory;
  late PromptBlockStorage storage;
  late PromptBlockRepository repository;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'prompt_block_repository_test_',
    );
    Hive.init(hiveDirectory.path);
    storage = PromptBlockStorage();
    repository = PromptBlockRepository(storage);
    await storage.init();
  });

  setUp(() async {
    await storage.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('schema is initialized in the independent versioned box', () async {
    expect(await storage.getSchemaVersion(), PromptBlockStorage.schemaVersion);
    final box = Hive.box<String>(PromptBlockStorage.boxName);
    expect(box.containsKey(PromptBlockStorage.schemaKey), isTrue);
  });

  test('CRUD preserves raw content and survives reopening storage', () async {
    final folder = await repository.createFolder(name: '画风');
    const content = 'line 1, 2::weighted::\n<style>α</style>';
    final block = await repository.createBlock(
      title: '风格',
      content: content,
      folderId: folder.id,
      color: '#FFFF0000',
    );

    expect((await repository.getBlock(block.id))?.content, content);
    expect((await repository.load()).folders.single.id, folder.id);

    await storage.close();
    final reopenedStorage = PromptBlockStorage();
    final reopened = await PromptBlockRepository(reopenedStorage).load();

    expect(reopened.blocks.single.id, block.id);
    expect(reopened.blocks.single.content, content);
    expect(reopened.blocks.single.color, '#FFFF0000');
    expect(reopened.folders.single.name, '画风');
    await reopenedStorage.close();
  });

  test('same-name tags keep one color across blocks', () async {
    final first = await repository.createBlock(
      title: '一',
      content: 'one',
      tags: const [PromptBlockTag(name: '冷色', color: '#FF268BEA')],
    );
    final second = await repository.createBlock(
      title: '二',
      content: 'two',
      tags: const [PromptBlockTag(name: '冷色', color: '#FF00ACC1')],
    );
    expect(
      (await repository.getBlock(first.id))!.tags.single.color,
      '#FF00ACC1',
    );
    await repository.updateBlock(
      first.copyWith(
        tags: const [PromptBlockTag(name: '冷色', color: '#FF8E24AA')],
      ),
    );
    expect(
      (await repository.getBlock(second.id))!.tags.single.color,
      '#FF8E24AA',
    );
  });

  test(
    'toggleFavorite persists the favorite state and is backward compatible',
    () async {
      final block = await repository.createBlock(
        title: '收藏候选',
        content: 'favorite me',
      );

      final favorited = await repository.toggleFavorite(block.id);
      expect(favorited.isFavorite, isTrue);
      expect((await repository.getBlock(block.id))?.isFavorite, isTrue);

      final legacyJson = Map<String, dynamic>.from(block.toJson())
        ..remove('isFavorite');
      expect(PromptBlock.fromJson(legacyJson).isFavorite, isFalse);
    },
  );

  test('reordering renumbers only the requested sibling layer', () async {
    final folder = await repository.createFolder(name: '画风');
    final first = await repository.createBlock(
      title: '一',
      content: 'one',
      folderId: folder.id,
    );
    final second = await repository.createBlock(
      title: '二',
      content: 'two',
      folderId: folder.id,
    );
    final third = await repository.createBlock(
      title: '三',
      content: 'three',
      folderId: folder.id,
    );
    final rootBlock = await repository.createBlock(title: '根', content: 'root');

    await repository.reorderBlocks(folder.id, [third.id, first.id, second.id]);

    final data = await repository.load();
    final folderBlocks = data.blocks.childrenOf(folder.id);
    expect(folderBlocks.map((block) => block.id), [
      third.id,
      first.id,
      second.id,
    ]);
    expect(data.getBlock(rootBlock.id)?.sortOrder, 0);
  });

  test('reorderFolders persists custom order within a parent', () async {
    final first = await repository.createFolder(name: '第一');
    final second = await repository.createFolder(name: '第二');
    final third = await repository.createFolder(name: '第三');

    await repository.reorderFolders(null, [third.id, first.id, second.id]);

    expect(
      (await repository.load()).folders
          .where((folder) => folder.parentId == null)
          .map((folder) => folder.id),
      [third.id, first.id, second.id],
    );
  });

  test('moving a folder into its descendant is rejected', () async {
    final root = await repository.createFolder(name: 'root');
    final child = await repository.createFolder(
      name: 'child',
      parentId: root.id,
    );

    expect(
      repository.moveFolder(root.id, child.id),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('folder deletion can move all nested blocks to root', () async {
    final root = await repository.createFolder(name: 'root');
    final child = await repository.createFolder(
      name: 'child',
      parentId: root.id,
    );
    final block = await repository.createBlock(
      title: 'nested',
      content: 'keep me',
      folderId: child.id,
    );

    await repository.deleteFolder(
      root.id,
      mode: PromptBlockFolderDeleteMode.moveContentsToRoot,
    );

    final data = await repository.load();
    expect(data.folders, isEmpty);
    expect(data.getBlock(block.id)?.folderId, isNull);
    expect(data.getBlock(block.id)?.content, 'keep me');
  });

  test('folder deletion can delete nested blocks explicitly', () async {
    final folder = await repository.createFolder(name: 'delete me');
    final block = await repository.createBlock(
      title: 'nested',
      content: 'remove me',
      folderId: folder.id,
    );

    await repository.deleteFolder(
      folder.id,
      mode: PromptBlockFolderDeleteMode.deleteContents,
    );

    final data = await repository.load();
    expect(data.getFolder(folder.id), isNull);
    expect(data.getBlock(block.id), isNull);
  });

  test(
    'editing an immutable copy does not write through to the library',
    () async {
      final block = await repository.createBlock(
        title: 'original',
        content: 'original content',
      );
      final workspaceCopy = block.copyWith(content: 'workspace-only change');

      expect(workspaceCopy.content, 'workspace-only change');
      expect(
        (await repository.getBlock(block.id))?.content,
        'original content',
      );
    },
  );

  test(
    'corrupt entity is skipped while valid entities remain readable',
    () async {
      final valid = await repository.createBlock(
        title: 'valid',
        content: 'valid content',
      );
      final box = Hive.box<String>(PromptBlockStorage.boxName);
      await box.put('block:corrupt', '{not-json');

      final blocks = await storage.getBlocks();
      expect(blocks.map((block) => block.id), [valid.id]);
    },
  );

  group('collections', () {
    test(
      'create assigns sibling sort order and requires folder parent',
      () async {
        final first = await repository.createCollection(name: '集一');
        final second = await repository.createCollection(name: '集二');
        // 收藏文件夹与收藏集在根级混合排序
        final folder = await repository.createCollection(
          name: '收藏夹',
          isFolder: true,
        );
        final child = await repository.createCollection(
          name: '子集',
          parentId: folder.id,
        );

        expect(first.sortOrder, 0);
        expect(second.sortOrder, 1);
        expect(folder.sortOrder, 2);
        expect(child.sortOrder, 0);
        expect(child.parentId, folder.id);
        expect(
          () => repository.createCollection(name: 'x', parentId: first.id),
          throwsArgumentError,
        );
      },
    );

    test('moveCollection rejects cycles', () async {
      final outer = await repository.createCollection(
        name: '外',
        isFolder: true,
      );
      final inner = await repository.createCollection(
        name: '内',
        parentId: outer.id,
        isFolder: true,
      );

      expect(
        () => repository.moveCollection(outer.id, inner.id),
        throwsArgumentError,
      );
      final moved = await repository.moveCollection(inner.id, null);
      expect(moved.parentId, isNull);
    });

    test('reorderCollections renumbers only the requested layer', () async {
      final folder = await repository.createCollection(
        name: '夹',
        isFolder: true,
      );
      final a = await repository.createCollection(name: 'a');
      final b = await repository.createCollection(name: 'b');
      final inside = await repository.createCollection(
        name: 'inside',
        parentId: folder.id,
      );

      // 重排需完整覆盖该层全部同级（含收藏文件夹）
      await repository.reorderCollections(null, [b.id, a.id, folder.id]);

      final data = await repository.load();
      expect(data.getCollection(b.id)?.sortOrder, 0);
      expect(data.getCollection(a.id)?.sortOrder, 1);
      expect(data.getCollection(folder.id)?.sortOrder, 2);
      // 其他层级不受影响
      expect(data.getCollection(inside.id)?.sortOrder, 0);
      expect(
        () => repository.reorderCollections(null, [a.id]),
        throwsArgumentError,
      );
    });

    test(
      'toggleBlockInCollection adds membership and auto-favorites',
      () async {
        final collection = await repository.createCollection(name: '集');
        final block = await repository.createBlock(title: 'b', content: 'c');

        expect(
          await repository.toggleBlockInCollection(collection.id, block.id),
          isTrue,
        );
        var data = await repository.load();
        expect(data.getCollection(collection.id)?.blockIds, [block.id]);
        expect(data.getBlock(block.id)?.isFavorite, isTrue);

        // 移出收藏集不动收藏旗标
        expect(
          await repository.toggleBlockInCollection(collection.id, block.id),
          isFalse,
        );
        data = await repository.load();
        expect(data.getCollection(collection.id)?.blockIds, isEmpty);
        expect(data.getBlock(block.id)?.isFavorite, isTrue);

        // 收藏文件夹不能装成员
        final folder = await repository.createCollection(
          name: '夹',
          isFolder: true,
        );
        expect(
          () => repository.toggleBlockInCollection(folder.id, block.id),
          throwsStateError,
        );
      },
    );

    test('deleteCollection removes subtree but keeps member blocks', () async {
      final folder = await repository.createCollection(
        name: '夹',
        isFolder: true,
      );
      final child = await repository.createCollection(
        name: '子集',
        parentId: folder.id,
      );
      final block = await repository.createBlock(title: 'b', content: 'c');
      await repository.toggleBlockInCollection(child.id, block.id);

      await repository.deleteCollection(folder.id);

      final data = await repository.load();
      expect(data.getCollection(folder.id), isNull);
      expect(data.getCollection(child.id), isNull);
      // 块本体不动
      expect(data.getBlock(block.id), isNotNull);
      // 删不存在的节点幂等
      await repository.deleteCollection('missing');
    });

    test('deleteBlock prunes membership from every collection', () async {
      final a = await repository.createCollection(name: 'a');
      final b = await repository.createCollection(name: 'b');
      final block = await repository.createBlock(title: 'x', content: 'y');
      await repository.toggleBlockInCollection(a.id, block.id);
      await repository.toggleBlockInCollection(b.id, block.id);

      await repository.deleteBlock(block.id);

      final data = await repository.load();
      expect(data.getCollection(a.id)?.blockIds, isEmpty);
      expect(data.getCollection(b.id)?.blockIds, isEmpty);
    });
  });
}
