import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/core/utils/prompt_block_exchange.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';

void main() {
  late Directory hiveDirectory;
  late PromptBlockStorage storage;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'prompt_block_provider_test_',
    );
    Hive.init(hiveDirectory.path);
    storage = PromptBlockStorage();
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

  test('provider loads and refreshes the shared block library', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    final initial = await container.read(
      promptBlockLibraryNotifierProvider.future,
    );
    expect(initial.blocks, isEmpty);

    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );
    final block = await notifier.createBlock(
      title: '测试块',
      content: 'line 1\nline 2',
      color: '#FFFF0000',
    );

    final current = await container.read(
      promptBlockLibraryNotifierProvider.future,
    );
    expect(current.blockById(block.id)?.content, 'line 1\nline 2');
    expect(current.blockById(block.id)?.color, '#FFFF0000');
  });

  test(
    'optimistic edits preserve concurrent use counts and reject newer content',
    () async {
      final container = ProviderContainer(
        overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(
        promptBlockLibraryNotifierProvider.notifier,
      );
      final block = await notifier.createBlock(
        title: 'Original',
        content: 'artist:a',
      );
      await notifier.incrementUseCount(block.id);
      await notifier.updateBlockIfUnchanged(
        block,
        block.copyWith(title: 'New title'),
      );
      var current = (await container.read(
        promptBlockLibraryNotifierProvider.future,
      )).blockById(block.id)!;
      expect(current.useCount, 1);
      final edited = current;
      final counting = notifier.incrementUseCount(block.id);
      final updating = notifier.updateBlockIfUnchanged(
        edited,
        edited.copyWith(content: 'artist:b'),
      );
      await Future.wait([counting, updating]);
      current = (await container.read(
        promptBlockLibraryNotifierProvider.future,
      )).blockById(block.id)!;
      expect(current.content, 'artist:b');
      expect(current.useCount, 2);
      await expectLater(
        notifier.updateBlockIfUnchanged(
          edited,
          edited.copyWith(content: 'stale'),
        ),
        throwsStateError,
      );
      expect(
        (await container.read(
          promptBlockLibraryNotifierProvider.future,
        )).blockById(block.id)!.content,
        'artist:b',
      );
      await Future.wait([
        notifier.setBlockFavorite(block.id, true),
        notifier.setBlockFavorite(block.id, true),
      ]);
      expect(
        (await container.read(
          promptBlockLibraryNotifierProvider.future,
        )).blockById(block.id)!.isFavorite,
        isTrue,
      );
    },
  );

  test('provider exposes favorite blocks after toggling a block', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );
    final block = await notifier.createBlock(title: '收藏块', content: 'favorite');
    await notifier.toggleFavorite(block.id);

    final state = await container.read(
      promptBlockLibraryNotifierProvider.future,
    );
    expect(state.favoriteBlocks.map((item) => item.id), [block.id]);
  });

  test(
    'copy keeps two independent blocks with shared lineage; replacement updates only target',
    () async {
      final container = ProviderContainer(
        overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(
        promptBlockLibraryNotifierProvider.notifier,
      );
      final sourceFolder = await notifier.createFolder(name: '来源');
      final targetFolder = await notifier.createFolder(name: '目标');
      final original = await notifier.createBlock(
        title: '角色',
        content: 'old',
        folderId: sourceFolder.id,
      );
      await notifier.updateBlock(
        original.copyWith(useCount: 7, sourcePath: 'source.txt'),
      );
      final target = PromptBlockTransferTarget(
        PromptBlockTransferKind.folder,
        targetFolder.id,
      );
      await notifier.transferBlocks(
        [original.id],
        target,
        PromptBlockTransferMode.copy,
      );
      var state = await container.read(
        promptBlockLibraryNotifierProvider.future,
      );
      final duplicate = state.blocks.singleWhere(
        (block) => block.folderId == targetFolder.id,
      );
      expect(duplicate.id, isNot(original.id));
      expect(duplicate.lineageKey, original.id);
      expect(duplicate.useCount, 0);
      expect(duplicate.sourcePath, isNull);
      expect(state.blockById(original.id)?.content, 'old');

      await notifier.updateBlock(original.copyWith(content: 'new'));
      expect(notifier.transferConflictCount([original.id], target), 1);
      await notifier.transferBlocks(
        [original.id],
        target,
        PromptBlockTransferMode.copy,
        replaceConflicts: true,
      );
      state = await container.read(promptBlockLibraryNotifierProvider.future);
      expect(state.blocks.length, 2);
      expect(state.blockById(duplicate.id)?.content, 'new');
      expect(state.blockById(original.id)?.folderId, sourceFolder.id);

      await notifier.transferBlocks(
        [original.id],
        target,
        PromptBlockTransferMode.move,
        replaceConflicts: true,
      );
      state = await container.read(promptBlockLibraryNotifierProvider.future);
      expect(state.blocks.map((block) => block.id), [duplicate.id]);
      expect(state.blockById(duplicate.id)?.content, 'new');
      expect(state.blockById(original.id)?.isArchived, isTrue);
      expect(state.blockById(original.id)?.content, 'new');
      expect(state.archivedBlocks.map((block) => block.id), [original.id]);
      await notifier.incrementUseCount(original.id);
      state = await container.read(promptBlockLibraryNotifierProvider.future);
      expect(state.blockById(original.id)?.useCount, 1);
    },
  );

  test(
    'moving from a collection into a folder removes source membership',
    () async {
      final container = ProviderContainer(
        overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(
        promptBlockLibraryNotifierProvider.notifier,
      );
      final parent = await notifier.createCollection(
        name: '收藏夹',
        isFolder: true,
      );
      final collection = await notifier.createCollection(
        name: '收藏集',
        parentId: parent.id,
      );
      final folder = await notifier.createFolder(name: '目标');
      final block = await notifier.createBlock(title: '角色', content: 'prompt');
      await notifier.toggleBlockInCollection(collection.id, block.id);
      await notifier.transferBlocks(
        [block.id],
        PromptBlockTransferTarget(PromptBlockTransferKind.folder, folder.id),
        PromptBlockTransferMode.move,
        sourceCollectionId: parent.id,
      );
      final state = await container.read(
        promptBlockLibraryNotifierProvider.future,
      );
      expect(state.blockById(block.id)?.folderId, folder.id);
      expect(state.collectionById(collection.id)?.blockIds, isEmpty);
    },
  );

  test(
    'blocksInFolderTree aggregates descendant blocks in tree order',
    () async {
      final container = ProviderContainer(
        overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(
        promptBlockLibraryNotifierProvider.notifier,
      );

      final blockRootA = await notifier.createBlock(
        title: 'root-a',
        content: 'a',
      );
      final blockRootB = await notifier.createBlock(
        title: 'root-b',
        content: 'b',
      );
      final folderA = await notifier.createFolder(name: 'A');
      final blockA1 = await notifier.createBlock(
        title: 'a-1',
        content: 'a1',
        folderId: folderA.id,
      );
      final blockA2 = await notifier.createBlock(
        title: 'a-2',
        content: 'a2',
        folderId: folderA.id,
      );
      final folderB = await notifier.createFolder(
        name: 'B',
        parentId: folderA.id,
      );
      final blockB1 = await notifier.createBlock(
        title: 'b-1',
        content: 'b1',
        folderId: folderB.id,
      );
      final folderC = await notifier.createFolder(
        name: 'C',
        parentId: folderA.id,
      );
      final blockC1 = await notifier.createBlock(
        title: 'c-1',
        content: 'c1',
        folderId: folderC.id,
      );
      final folderD = await notifier.createFolder(name: 'D');
      final blockD1 = await notifier.createBlock(
        title: 'd-1',
        content: 'd1',
        folderId: folderD.id,
      );

      final state = await container.read(
        promptBlockLibraryNotifierProvider.future,
      );

      // 父文件夹聚合整棵子树：直属块在前，再按同级顺序下钻 B、C。
      expect(state.blocksInFolderTree(folderA.id).map((item) => item.id), [
        blockA1.id,
        blockA2.id,
        blockB1.id,
        blockC1.id,
      ]);
      // 根目录聚合根直属块与全部根级文件夹子树。
      expect(state.blocksInFolderTree(null).map((item) => item.id), [
        blockRootA.id,
        blockRootB.id,
        blockA1.id,
        blockA2.id,
        blockB1.id,
        blockC1.id,
        blockD1.id,
      ]);
      // 叶子文件夹仍只含直属块。
      expect(state.blocksInFolderTree(folderB.id).map((item) => item.id), [
        blockB1.id,
      ]);
      expect(state.blocksInFolderTree('missing-folder'), isEmpty);
      // 树序映射：根 0 → A 1 → B 2 → C 3 → D 4（同级按创建顺序）。
      expect(state.folderTreeOrder(), {
        null: 0,
        folderA.id: 1,
        folderB.id: 2,
        folderC.id: 3,
        folderD.id: 4,
      });
    },
  );

  test(
    'importTxtFiles creates new blocks and skips existing sources',
    () async {
      final container = ProviderContainer(
        overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(
        promptBlockLibraryNotifierProvider.notifier,
      );

      final txtA = File('${hiveDirectory.path}${Platform.pathSeparator}a.txt');
      await txtA.writeAsString('artist-a, artist-b', flush: true);
      final txtB = File('${hiveDirectory.path}${Platform.pathSeparator}b.txt');
      await txtB.writeAsString('<style>1::best::</style>', flush: true);

      final first = await notifier.importTxtFiles(
        paths: [txtA.path, txtB.path],
      );
      expect(first.created, 2);
      expect(first.skipped, 0);

      var state = await container.read(
        promptBlockLibraryNotifierProvider.future,
      );
      final blockA = state.blocks.firstWhere((b) => b.sourcePath == txtA.path);
      expect(blockA.content, 'artist-a, artist-b');
      expect(blockA.title, 'a');
      expect(
        blockA.sourceHash,
        PromptBlockExchange.contentHash(blockA.content),
      );
      expect(blockA.importedAt, isNotNull);

      // 同来源重复导入:只新增,不覆盖既有块。
      await File(txtA.path).writeAsString('changed on disk', flush: true);
      final second = await notifier.importTxtFiles(paths: [txtA.path]);
      expect(second.created, 0);
      expect(second.skipped, 1);

      state = await container.read(promptBlockLibraryNotifierProvider.future);
      expect(
        state.blocks.firstWhere((b) => b.sourcePath == txtA.path).content,
        'artist-a, artist-b',
      );
    },
  );

  test('applyExchangePlan mirrors folders, allocates order and updates only '
      'when confirmed', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );

    final existing = await notifier.createBlock(
      title: '旧画师',
      content: 'old content',
    );
    final importedOld = await notifier.updateBlock(
      existing.copyWith(
        sourcePath: '/curation/画师池.txt',
        sourceHash: PromptBlockExchange.contentHash('old content'),
      ),
    );

    final files = [
      PromptBlockExchangeFile(path: '/curation/sub/new.txt', content: '全新'),
      PromptBlockExchangeFile(
        path: '/curation/画师池.txt',
        content: 'new content',
      ),
    ];
    final currentState = await container.read(
      promptBlockLibraryNotifierProvider.future,
    );
    final plan = PromptBlockExchange.buildPlan(
      files: files,
      library: PromptBlockLibraryData(
        blocks: currentState.blocks,
        folders: currentState.folders,
      ),
      folderChainOf: (file) =>
          file.path.contains('sub') ? ['策展', 'sub'] : ['策展'],
    );
    expect(plan.createCount, 1);
    expect(plan.updateCount, 1);

    // 未确认更新:只落新建。
    final first = await notifier.applyExchangePlan(plan);
    expect(first.created, 1);
    expect(first.updated, 0);

    var state = await container.read(promptBlockLibraryNotifierProvider.future);
    final rootMirror = state.folders.firstWhere((f) => f.name == '策展');
    final subMirror = state.folders.firstWhere((f) => f.name == 'sub');
    expect(subMirror.parentId, rootMirror.id);
    final newBlock = state.blocks.firstWhere(
      (b) => b.sourcePath == '/curation/sub/new.txt',
    );
    expect(newBlock.folderId, subMirror.id);
    expect(newBlock.content, '全新');
    expect(state.blockById(importedOld.id)?.content, 'old content');

    // 确认更新:重新对照库构建计划(新建项已变为未变更),来源内容覆盖、
    // hash 与读取时间刷新。
    final stateAfterFirst = await container.read(
      promptBlockLibraryNotifierProvider.future,
    );
    final secondPlan = PromptBlockExchange.buildPlan(
      files: files,
      library: PromptBlockLibraryData(
        blocks: stateAfterFirst.blocks,
        folders: stateAfterFirst.folders,
      ),
      folderChainOf: (file) =>
          file.path.contains('sub') ? ['策展', 'sub'] : ['策展'],
    );
    expect(secondPlan.createCount, 0);
    expect(secondPlan.updateCount, 1);

    final second = await notifier.applyExchangePlan(
      secondPlan,
      updateChanged: true,
    );
    expect(second.created, 0);
    expect(second.updated, 1);

    state = await container.read(promptBlockLibraryNotifierProvider.future);
    final updated = state.blockById(importedOld.id)!;
    expect(updated.content, 'new content');
    expect(updated.sourceHash, PromptBlockExchange.contentHash('new content'));
    expect(updated.folderId, isNull);
  });

  test('library backup export/import round trip skips existing ids', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );

    final block = await notifier.createBlock(
      title: '备份块',
      content: '内容',
      folderId: null,
    );

    final exported = await notifier.exportLibrary();
    final importIntoSame = await notifier.importLibrary(
      Map<String, dynamic>.from(exported),
    );
    expect(importIntoSame.importedBlocks, 0);
    expect(importIntoSame.skippedBlocks, 1);

    // 清库后恢复:块与来源字段完整回来。
    await storage.clear();
    await notifier.refresh();
    final restored = await notifier.importLibrary(
      Map<String, dynamic>.from(exported),
    );
    expect(restored.importedBlocks, 1);

    final state = await container.read(
      promptBlockLibraryNotifierProvider.future,
    );
    expect(state.blockById(block.id)?.content, '内容');
  });

  test('importLibrary rejects invalid backup payloads', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );

    expect(
      () => notifier.importLibrary({'folders': []}),
      throwsA(isA<FormatException>()),
    );
  });

  test('deleteBlocks removes multiple blocks in one pass', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );
    final a = await notifier.createBlock(title: 'A', content: 'a');
    final b = await notifier.createBlock(title: 'B', content: 'b');
    final c = await notifier.createBlock(title: 'C', content: 'c');

    await notifier.deleteBlocks([a.id, b.id]);

    final state = await container.read(
      promptBlockLibraryNotifierProvider.future,
    );
    expect(state.blockById(a.id), isNull);
    expect(state.blockById(b.id), isNull);
    expect(state.blockById(c.id)?.title, 'C');
    expect(state.blocks.map((block) => block.id), [c.id]);
  });

  test('deleteBlocks with an empty list is a no-op', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );
    final a = await notifier.createBlock(title: 'A', content: 'a');

    await notifier.deleteBlocks([]);

    final state = await container.read(
      promptBlockLibraryNotifierProvider.future,
    );
    expect(state.blockById(a.id)?.title, 'A');
  });

  test('moveBlocks moves blocks into a folder and back to root', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );
    final folder = await notifier.createFolder(name: 'F1');
    final a = await notifier.createBlock(title: 'A', content: 'a');
    final b = await notifier.createBlock(title: 'B', content: 'b');

    await notifier.moveBlocks([a.id, b.id], folder.id);

    var state = await container.read(promptBlockLibraryNotifierProvider.future);
    expect(state.blockById(a.id)?.folderId, folder.id);
    expect(state.blockById(b.id)?.folderId, folder.id);

    await notifier.moveBlocks([a.id], null);

    state = await container.read(promptBlockLibraryNotifierProvider.future);
    expect(state.blockById(a.id)?.folderId, isNull);
    expect(state.blockById(b.id)?.folderId, folder.id);
  });

  test('moveBlocks to a missing folder throws and keeps disk state', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );
    final a = await notifier.createBlock(title: 'A', content: 'a');

    await expectLater(
      notifier.moveBlocks([a.id], 'missing-folder'),
      throwsA(isA<ArgumentError>()),
    );

    // 批量失败后 notifier 处于 AsyncError，先 refresh 恢复再断言落盘状态。
    await notifier.refresh();
    final state = await container.read(
      promptBlockLibraryNotifierProvider.future,
    );
    expect(state.blockById(a.id)?.folderId, isNull);
  });

  test('createBlock persists thumbnail fields across reload', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );

    final block = await notifier.createBlock(
      title: '带图块',
      content: 'c',
      thumbnail: 'C:/app/prompt_block_thumbnails/a.png',
      thumbnailOffsetX: 0.2,
      thumbnailOffsetY: -0.3,
      thumbnailScale: 1.4,
    );

    await notifier.refresh();
    final reloaded = container
        .read(promptBlockLibraryNotifierProvider)
        .valueOrNull
        ?.blockById(block.id);
    expect(reloaded?.thumbnail, 'C:/app/prompt_block_thumbnails/a.png');
    expect(reloaded?.thumbnailOffsetX, 0.2);
    expect(reloaded?.thumbnailOffsetY, -0.3);
    expect(reloaded?.thumbnailScale, 1.4);
    expect(reloaded?.useCount, 0);
  });

  test('incrementUseCount bumps count in state and on disk; unknown id is '
      'a no-op', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );
    final block = await notifier.createBlock(title: 'B', content: 'x');

    await notifier.incrementUseCount(block.id);
    await notifier.incrementUseCount(block.id);
    await notifier.incrementUseCount('missing-block');

    var current = container
        .read(promptBlockLibraryNotifierProvider)
        .valueOrNull;
    expect(current?.blockById(block.id)?.useCount, 2);

    // 落盘核对：整库 reload 后计数仍在。
    await notifier.refresh();
    current = container.read(promptBlockLibraryNotifierProvider).valueOrNull;
    expect(current?.blockById(block.id)?.useCount, 2);
  });

  test('pill lane insertBlockAt increments block useCount once', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );
    final block = await notifier.createBlock(title: 'B', content: 'x');
    await container.read(promptBlockLibraryNotifierProvider.future);

    container
        .read(pillWorkspaceProvider('test-scope').notifier)
        .insertBlockAt(offset: 0, blockId: block.id);

    // useCount 是 fire-and-forget 异步回写：轮询直至落账（超时则断言失败）。
    var count = 0;
    for (var attempt = 0; attempt < 100 && count == 0; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      count =
          container
              .read(promptBlockLibraryNotifierProvider)
              .valueOrNull
              ?.blockById(block.id)
              ?.useCount ??
          0;
    }
    expect(count, 1);
  });

  test('setFavorite favorites, unfavorites and skips no-ops', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );
    final a = await notifier.createBlock(title: 'A', content: 'a');
    final b = await notifier.createBlock(title: 'B', content: 'b');
    final c = await notifier.createBlock(title: 'C', content: 'c');

    await notifier.setFavorite([a.id, b.id], true);

    var state = await container.read(promptBlockLibraryNotifierProvider.future);
    expect(state.blockById(a.id)?.isFavorite, isTrue);
    expect(state.blockById(b.id)?.isFavorite, isTrue);
    expect(state.blockById(c.id)?.isFavorite, isFalse);

    await notifier.setFavorite([a.id], false);

    state = await container.read(promptBlockLibraryNotifierProvider.future);
    expect(state.blockById(a.id)?.isFavorite, isFalse);
    expect(state.blockById(b.id)?.isFavorite, isTrue);

    // 目标态与当前态一致的空操作不应抛错。
    await notifier.setFavorite([], true);

    state = await container.read(promptBlockLibraryNotifierProvider.future);
    expect(state.blockById(b.id)?.isFavorite, isTrue);
  });

  group('collections', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer(
        overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test(
      'create/rename/move/reorder/delete collection round-trips state',
      () async {
        final container = makeContainer();
        final notifier = container.read(
          promptBlockLibraryNotifierProvider.notifier,
        );
        await container.read(promptBlockLibraryNotifierProvider.future);

        final folder = await notifier.createCollection(
          name: '夹',
          isFolder: true,
        );
        final a = await notifier.createCollection(name: 'a');
        final b = await notifier.createCollection(
          name: 'b',
          parentId: folder.id,
        );

        var state = await container.read(
          promptBlockLibraryNotifierProvider.future,
        );
        expect(state.collectionById(folder.id)?.isFolder, isTrue);
        expect(state.collectionById(b.id)?.parentId, folder.id);
        expect(state.collectionTreeOrder(), [folder.id, b.id, a.id]);
        expect(state.collectionPath(b.id), '夹 / b');

        await notifier.renameCollection(a.id, 'A+');
        await notifier.moveCollection(a.id, folder.id);
        state = await container.read(promptBlockLibraryNotifierProvider.future);
        expect(state.collectionById(a.id)?.name, 'A+');
        expect(state.collectionById(a.id)?.parentId, folder.id);
        expect(state.collectionPath(a.id), '夹 / A+');

        await notifier.reorderCollections(folder.id, [a.id, b.id]);
        state = await container.read(promptBlockLibraryNotifierProvider.future);
        expect(state.collectionsIn(folder.id).map((n) => n.id), [a.id, b.id]);

        await notifier.deleteCollection(folder.id);
        state = await container.read(promptBlockLibraryNotifierProvider.future);
        expect(state.collectionById(folder.id), isNull);
        expect(state.collectionById(a.id), isNull);
        expect(state.collectionById(b.id), isNull);
      },
    );

    test(
      'toggleBlockInCollection auto-favorites and tracks membership',
      () async {
        final container = makeContainer();
        final notifier = container.read(
          promptBlockLibraryNotifierProvider.notifier,
        );
        await container.read(promptBlockLibraryNotifierProvider.future);

        final folder = await notifier.createCollection(
          name: '夹',
          isFolder: true,
        );
        final inner = await notifier.createCollection(
          name: '内集',
          parentId: folder.id,
        );
        final outer = await notifier.createCollection(name: '外集');
        final block = await notifier.createBlock(title: 'b', content: 'c');

        await notifier.toggleBlockInCollection(inner.id, block.id);
        await notifier.toggleBlockInCollection(outer.id, block.id);

        var state = await container.read(
          promptBlockLibraryNotifierProvider.future,
        );
        // 入集即收藏
        expect(state.blockById(block.id)?.isFavorite, isTrue);
        expect(state.collectionIdsOfBlock(block.id), {inner.id, outer.id});
        // 收藏文件夹视图 = 子树成员并集
        expect(state.blocksInCollectionTree(folder.id).map((x) => x.id), [
          block.id,
        ]);
        expect(state.collectionTreeBlockCount(folder.id), 1);

        // 移出后旗标保留、成员关系解除
        await notifier.toggleBlockInCollection(inner.id, block.id);
        state = await container.read(promptBlockLibraryNotifierProvider.future);
        expect(state.blockById(block.id)?.isFavorite, isTrue);
        expect(state.collectionIdsOfBlock(block.id), {outer.id});
        expect(state.blocksInCollectionTree(folder.id), isEmpty);
      },
    );

    test('deleteBlock prunes collection membership in state', () async {
      final container = makeContainer();
      final notifier = container.read(
        promptBlockLibraryNotifierProvider.notifier,
      );
      await container.read(promptBlockLibraryNotifierProvider.future);

      final collection = await notifier.createCollection(name: '集');
      final block = await notifier.createBlock(title: 'b', content: 'c');
      await notifier.toggleBlockInCollection(collection.id, block.id);

      await notifier.deleteBlock(block.id);
      final state = await container.read(
        promptBlockLibraryNotifierProvider.future,
      );
      expect(state.collectionById(collection.id)?.blockIds, isEmpty);
    });
  });
}
