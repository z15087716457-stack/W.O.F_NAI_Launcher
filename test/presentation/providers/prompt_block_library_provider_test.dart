import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/core/utils/prompt_block_exchange.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
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

  test('blocksInFolderTree aggregates descendant blocks in tree order', () async {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );

    final blockRootA = await notifier.createBlock(title: 'root-a', content: 'a');
    final blockRootB = await notifier.createBlock(title: 'root-b', content: 'b');
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
    expect(
      state.blocksInFolderTree(folderA.id).map((item) => item.id),
      [blockA1.id, blockA2.id, blockB1.id, blockC1.id],
    );
    // 根目录聚合根直属块与全部根级文件夹子树。
    expect(
      state.blocksInFolderTree(null).map((item) => item.id),
      [
        blockRootA.id,
        blockRootB.id,
        blockA1.id,
        blockA2.id,
        blockB1.id,
        blockC1.id,
        blockD1.id,
      ],
    );
    // 叶子文件夹仍只含直属块。
    expect(
      state.blocksInFolderTree(folderB.id).map((item) => item.id),
      [blockB1.id],
    );
    expect(state.blocksInFolderTree('missing-folder'), isEmpty);
    // 树序映射：根 0 → A 1 → B 2 → C 3 → D 4（同级按创建顺序）。
    expect(state.folderTreeOrder(), {
      null: 0,
      folderA.id: 1,
      folderB.id: 2,
      folderC.id: 3,
      folderD.id: 4,
    });
  });

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
}
