import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/prompt_block_storage.dart';
import '../../core/utils/prompt_block_exchange.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/models/prompt_block/prompt_block_folder.dart';
import '../../data/repositories/prompt_block_repository.dart';

part 'prompt_block_library_provider.g.dart';

/// 块库页面和后续 Prompt 工作区共用的只读状态快照。
class PromptBlockLibraryState {
  PromptBlockLibraryState({
    required List<PromptBlock> blocks,
    required List<PromptBlockFolder> folders,
  }) : blocks = List.unmodifiable(blocks),
       folders = List.unmodifiable(folders);

  final List<PromptBlock> blocks;
  final List<PromptBlockFolder> folders;

  /// 获取指定文件夹内的直属块。
  List<PromptBlock> blocksInFolder(String? folderId) =>
      blocks.childrenOf(folderId);

  /// 获取指定文件夹子树内的全部块（直属 + 各级后代文件夹）。
  ///
  /// 按文件夹树顺序排列：每个文件夹先列直属块，再按用户排序逐个下钻
  /// 子文件夹，让点选父文件夹时能完整浏览整棵子树的内容。
  List<PromptBlock> blocksInFolderTree(String? folderId) {
    final result = <PromptBlock>[];

    void visit(String? id) {
      result.addAll(blocks.childrenOf(id));
      for (final folder in folders.childrenOf(id)) {
        visit(folder.id);
      }
    }

    visit(folderId);
    return result;
  }

  /// 全库文件夹树序映射（根目录为 0，之后按 DFS：先同级文件夹用户排序，
  /// 再逐层下钻），供排序回退使用；不在映射里的文件夹 ID 视为排在最后。
  Map<String?, int> folderTreeOrder() {
    final order = <String?, int>{};
    var next = 0;

    void visit(String? id) {
      order[id] = next++;
      for (final folder in folders.childrenOf(id)) {
        visit(folder.id);
      }
    }

    visit(null);
    return order;
  }

  /// 获取已收藏的块。
  List<PromptBlock> get favoriteBlocks =>
      blocks.where((block) => block.isFavorite).toList();

  /// 获取指定父文件夹的直属子文件夹。
  List<PromptBlockFolder> foldersIn(String? parentId) =>
      folders.childrenOf(parentId);

  PromptBlock? blockById(String id) {
    for (final block in blocks) {
      if (block.id == id) return block;
    }
    return null;
  }

  PromptBlockFolder? folderById(String id) {
    for (final folder in folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }
}

final promptBlockStorageProvider = Provider<PromptBlockStorage>(
  (ref) => PromptBlockStorage(),
);

final promptBlockRepositoryProvider = Provider<PromptBlockRepository>(
  (ref) => PromptBlockRepository(ref.watch(promptBlockStorageProvider)),
);

/// 全局 Prompt 块库状态管理。
@Riverpod(keepAlive: true)
class PromptBlockLibraryNotifier extends _$PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async {
    final data = await ref.watch(promptBlockRepositoryProvider).load();
    return PromptBlockLibraryState(blocks: data.blocks, folders: data.folders);
  }

  /// 重新从 Hive 读取块库。
  Future<void> refresh() async {
    final repository = ref.read(promptBlockRepositoryProvider);
    state = const AsyncLoading();
    try {
      state = AsyncData(_toState(await repository.load()));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<PromptBlock> createBlock({
    required String title,
    required String content,
    String? folderId,
    String color = '#FF607D8B',
    String? iconName,
    int? sortOrder,
  }) {
    return _mutate(
      (repository) => repository.createBlock(
        title: title,
        content: content,
        folderId: folderId,
        color: color,
        iconName: iconName,
        sortOrder: sortOrder,
      ),
    );
  }

  Future<PromptBlock> updateBlock(PromptBlock block) =>
      _mutate((repository) => repository.updateBlock(block));

  Future<PromptBlock> toggleFavorite(String blockId) =>
      _mutate((repository) => repository.toggleFavorite(blockId));

  Future<PromptBlock> moveBlock(String blockId, String? folderId) =>
      _mutate((repository) => repository.moveBlock(blockId, folderId));

  Future<void> deleteBlock(String blockId) =>
      _mutate((repository) => repository.deleteBlock(blockId));

  /// 批量删除块：循环单块删除，末尾单次整库 reload（不走 N 次 [_mutate]）。
  /// 任一块失败即中断并进入 AsyncError，reload 后状态以落盘为准。
  Future<void> deleteBlocks(List<String> blockIds) async {
    if (blockIds.isEmpty) return;
    final repository = ref.read(promptBlockRepositoryProvider);
    try {
      for (final blockId in blockIds) {
        await repository.deleteBlock(blockId);
      }
      state = AsyncData(_toState(await repository.load()));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// 批量移动块到目标文件夹（null = 根目录），末尾单次整库 reload。
  Future<void> moveBlocks(List<String> blockIds, String? folderId) async {
    if (blockIds.isEmpty) return;
    final repository = ref.read(promptBlockRepositoryProvider);
    try {
      for (final blockId in blockIds) {
        await repository.moveBlock(blockId, folderId);
      }
      state = AsyncData(_toState(await repository.load()));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// 批量设置收藏状态：只对当前态与目标不一致的块调用 toggle，末尾单次 reload。
  Future<void> setFavorite(List<String> blockIds, bool favorite) async {
    if (blockIds.isEmpty) return;
    final current = state.valueOrNull;
    final toToggle = <String>[];
    for (final blockId in blockIds) {
      final block = current?.blockById(blockId);
      if (block != null && block.isFavorite != favorite) toToggle.add(blockId);
    }
    if (toToggle.isEmpty) return;
    final repository = ref.read(promptBlockRepositoryProvider);
    try {
      for (final blockId in toToggle) {
        await repository.toggleFavorite(blockId);
      }
      state = AsyncData(_toState(await repository.load()));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<PromptBlockFolder> createFolder({
    required String name,
    String? parentId,
    int? sortOrder,
  }) {
    return _mutate(
      (repository) => repository.createFolder(
        name: name,
        parentId: parentId,
        sortOrder: sortOrder,
      ),
    );
  }

  Future<PromptBlockFolder> updateFolder(PromptBlockFolder folder) =>
      _mutate((repository) => repository.updateFolder(folder));

  Future<PromptBlockFolder> moveFolder(String folderId, String? newParentId) =>
      _mutate((repository) => repository.moveFolder(folderId, newParentId));

  Future<void> reorderBlocks(String? folderId, List<String> orderedIds) =>
      _mutate((repository) => repository.reorderBlocks(folderId, orderedIds));

  Future<void> reorderFolders(String? parentId, List<String> orderedIds) =>
      _mutate((repository) => repository.reorderFolders(parentId, orderedIds));

  Future<void> deleteFolder(
    String folderId, {
    required PromptBlockFolderDeleteMode mode,
    String? destinationFolderId,
  }) => _mutate(
    (repository) => repository.deleteFolder(
      folderId,
      mode: mode,
      destinationFolderId: destinationFolderId,
    ),
  );

  /// TXT 单文件导入：只新增，同来源已存在的文件跳过，不覆盖任何块。
  Future<PromptBlockExchangeResult> importTxtFiles({
    required List<String> paths,
    String? folderId,
  }) async {
    final files = await PromptBlockExchange.readTxtFiles(paths);
    final repository = ref.read(promptBlockRepositoryProvider);
    final plan = PromptBlockExchange.buildPlan(
      files: files,
      library: await repository.load(),
      folderChainOf: (_) => const [],
    );

    var created = 0;
    final toWrite = <PromptBlock>[];
    for (final item in plan.items) {
      if (item.action != PromptBlockExchangeAction.create) continue;
      toWrite.add(
        PromptBlock.create(
          title: item.file.title,
          content: item.file.content,
          folderId: folderId,
          sourcePath: item.file.path,
          sourceHash: item.file.hash,
          importedAt: DateTime.now(),
        ),
      );
      created++;
    }
    if (toWrite.isNotEmpty) {
      await _mutate((repository) => repository.importBlocks(toWrite));
    }
    return PromptBlockExchangeResult(
      created: created,
      updated: 0,
      skipped: plan.skipCount + plan.updateCount,
    );
  }

  /// 执行交换计划：新建条目写入，update 条目仅在 [updateChanged] 为真时
  /// 用来源内容刷新（用户显式确认过才覆盖）。
  Future<PromptBlockExchangeResult> applyExchangePlan(
    PromptBlockExchangePlan plan, {
    bool updateChanged = false,
  }) async {
    final repository = ref.read(promptBlockRepositoryProvider);
    final data = await repository.load();
    final now = DateTime.now();

    final folders = data.folders.toList();
    final chainIds = <List<String>, String?>{};
    final nextOrder = <String?, int>{
      for (final folder in data.folders)
        folder.id: _maxOrder(data.blocks.where((b) => b.folderId == folder.id)),
      null: _maxOrder(data.blocks.where((b) => b.folderId == null)),
    };

    var created = 0;
    var updated = 0;
    final toWrite = <PromptBlock>[];
    for (final item in plan.items) {
      switch (item.action) {
        case PromptBlockExchangeAction.create:
          final folderId = await _resolveFolderChain(
            repository,
            folders,
            chainIds,
            item.folderChain,
          );
          toWrite.add(
            PromptBlock.create(
              title: item.file.title,
              content: item.file.content,
              folderId: folderId,
              sortOrder: nextOrder[folderId] ?? 0,
              sourcePath: item.file.path,
              sourceHash: item.file.hash,
              importedAt: now,
            ),
          );
          nextOrder[folderId] = (nextOrder[folderId] ?? -1) + 1;
          created++;
        case PromptBlockExchangeAction.skipUnchanged:
          break;
        case PromptBlockExchangeAction.update:
          if (!updateChanged || item.existingBlock == null) break;
          toWrite.add(
            item.existingBlock!.copyWith(
              content: item.file.content,
              sourceHash: item.file.hash,
              importedAt: now,
              updatedAt: now,
            ),
          );
          updated++;
      }
    }
    if (toWrite.isNotEmpty) {
      await _mutate((repository) => repository.importBlocks(toWrite));
    }
    return PromptBlockExchangeResult(
      created: created,
      updated: updated,
      skipped: plan.items.length - created - updated,
    );
  }

  /// 导出整库备份 JSON 结构（不落盘，由界面选择保存位置）。
  Future<Map<String, dynamic>> exportLibrary() async {
    final data = await ref.read(promptBlockRepositoryProvider).load();
    return PromptBlockExchange.exportLibraryJson(
      blocks: data.blocks,
      folders: data.folders,
    );
  }

  /// 导入库备份：同 ID 实体跳过，不覆盖既有内容。
  Future<PromptBlockLibraryImportSummary> importLibrary(
    Map<String, dynamic> json,
  ) async {
    final repository = ref.read(promptBlockRepositoryProvider);
    final plan = PromptBlockExchange.planLibraryImport(
      json: json,
      library: await repository.load(),
    );
    if (plan.folders.isNotEmpty) {
      await repository.importFolders(plan.folders);
    }
    if (plan.blocks.isNotEmpty) {
      await repository.importBlocks(plan.blocks);
    }
    await refresh();
    return PromptBlockLibraryImportSummary(
      importedFolders: plan.folders.length,
      importedBlocks: plan.blocks.length,
      skippedFolders: plan.skippedFolders,
      skippedBlocks: plan.skippedBlocks,
    );
  }

  /// 逐级确保文件夹链存在，返回末端文件夹 ID（空链为 null 即根目录）。
  ///
  /// [folders] 是内存中的文件夹快照副本，新建的文件夹会追加进去，
  /// 避免同一链条重复建夹。
  Future<String?> _resolveFolderChain(
    PromptBlockRepository repository,
    List<PromptBlockFolder> folders,
    Map<List<String>, String?> chainIds,
    List<String> chain,
  ) async {
    if (chain.isEmpty) return null;
    final cached = chainIds[chain];
    if (cached != null) return cached;

    String? parentId;
    for (final name in chain) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      var existing = folders
          .where((f) => f.parentId == parentId && f.name == trimmed)
          .firstOrNull;
      if (existing == null) {
        existing = await repository.createFolder(
          name: trimmed,
          parentId: parentId,
        );
        folders.add(existing);
      }
      parentId = existing.id;
    }
    chainIds[chain] = parentId;
    return parentId;
  }

  int _maxOrder(Iterable<PromptBlock> blocks) {
    var maximum = -1;
    for (final block in blocks) {
      if (block.sortOrder > maximum) maximum = block.sortOrder;
    }
    return maximum + 1;
  }

  Future<T> _mutate<T>(
    Future<T> Function(PromptBlockRepository repository) action,
  ) async {
    final repository = ref.read(promptBlockRepositoryProvider);
    try {
      final result = await action(repository);
      state = AsyncData(_toState(await repository.load()));
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  PromptBlockLibraryState _toState(PromptBlockLibraryData data) {
    return PromptBlockLibraryState(blocks: data.blocks, folders: data.folders);
  }
}

/// 一次外部来源交换的执行结果。
class PromptBlockExchangeResult {
  PromptBlockExchangeResult({
    required this.created,
    required this.updated,
    required this.skipped,
  });

  final int created;
  final int updated;
  final int skipped;
}

/// 库备份导入结果。
class PromptBlockLibraryImportSummary {
  PromptBlockLibraryImportSummary({
    required this.importedFolders,
    required this.importedBlocks,
    required this.skippedFolders,
    required this.skippedBlocks,
  });

  final int importedFolders;
  final int importedBlocks;
  final int skippedFolders;
  final int skippedBlocks;
}
