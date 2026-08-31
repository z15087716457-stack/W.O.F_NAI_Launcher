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
}
