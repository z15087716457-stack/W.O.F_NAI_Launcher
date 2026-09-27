import 'package:collection/collection.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/local_storage_service.dart';
import '../../core/storage/prompt_block_storage.dart';
import '../../core/utils/prompt_block_exchange.dart';
import '../../core/utils/prompt_block_thumbnails.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/models/prompt_block/prompt_block_collection.dart';
import '../../data/models/prompt_block/prompt_block_folder.dart';
import '../../data/repositories/prompt_block_repository.dart';
import '../../data/services/fixed_tag_migration_service.dart';
import '../../data/services/tag_library_migration_service.dart';

part 'prompt_block_library_provider.g.dart';

enum PromptBlockTransferKind { folder, favorites, collection }

class PromptBlockTransferTarget {
  const PromptBlockTransferTarget(this.kind, [this.id]);
  final PromptBlockTransferKind kind;
  final String? id;
}

enum PromptBlockTransferMode { copy, move }

/// 块库页面和后续 Prompt 工作区共用的只读状态快照。
class PromptBlockLibraryState {
  PromptBlockLibraryState({
    required List<PromptBlock> blocks,
    required List<PromptBlockFolder> folders,
    List<PromptBlockCollection>? collections,
  }) : blocks = List.unmodifiable(blocks),
       folders = List.unmodifiable(folders),
       collections = List.unmodifiable(collections ?? const []);

  final List<PromptBlock> blocks;
  final List<PromptBlockFolder> folders;

  /// 收藏集树（收藏集 + 收藏文件夹混合，parentId 挂接成树）。
  final List<PromptBlockCollection> collections;

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

  /// 获取指定父级（null=收藏区根级）的直属收藏节点。
  List<PromptBlockCollection> collectionsIn(String? parentId) =>
      collections.childrenOf(parentId);

  PromptBlockCollection? collectionById(String id) {
    for (final node in collections) {
      if (node.id == id) return node;
    }
    return null;
  }

  /// 块当前所在的收藏集 ID 集合（不含收藏文件夹）。
  Set<String> collectionIdsOfBlock(String blockId) {
    return {
      for (final node in collections)
        if (!node.isFolder && node.blockIds.contains(blockId)) node.id,
    };
  }

  /// 收藏节点的可见块：收藏集 = 成员列表序（过滤已删除块）；
  /// 收藏文件夹 = 子树内全部收藏集成员的并集（按库内文件夹序排列）。
  List<PromptBlock> blocksInCollectionTree(String nodeId) {
    final node = collectionById(nodeId);
    if (node == null) return const [];
    if (!node.isFolder) {
      final byId = {for (final block in blocks) block.id: block};
      return [
        for (final blockId in node.blockIds)
          if (byId[blockId] case final block?) block,
      ];
    }
    final memberIds = <String>{};
    final subtreeIds = <String>{
      nodeId,
      ...collections.getDescendantIds(nodeId),
    };
    for (final child in collections) {
      if (child.isFolder || !subtreeIds.contains(child.id)) continue;
      memberIds.addAll(child.blockIds);
    }
    return blocks.where((block) => memberIds.contains(block.id)).toList();
  }

  /// 收藏文件夹的子树成员数（子孙收藏集成员的并集去重），供侧栏计数。
  int collectionTreeBlockCount(String nodeId) {
    return blocksInCollectionTree(nodeId).length;
  }

  /// 收藏集树的 DFS 顺序 id 列表（同级按用户排序，逐层下钻），
  /// 供扁平化展示（窄布局下拉框等）使用。
  List<String> collectionTreeOrder() {
    final order = <String>[];

    void visit(String? parentId) {
      for (final node in collections.childrenOf(parentId)) {
        order.add(node.id);
        visit(node.id);
      }
    }

    visit(null);
    return order;
  }

  /// 文件夹的根→当前路径名（`A / B / C`），用于分段标题与扁平展示。
  String folderPath(String folderId) {
    try {
      return folders.getPath(folderId).map((folder) => folder.name).join(' / ');
    } on Object {
      return folderId;
    }
  }

  /// 收藏节点的根→节点路径名（`A / B / C`），用于扁平展示。
  String collectionPath(String nodeId) {
    try {
      return collections.getPath(nodeId).map((node) => node.name).join(' / ');
    } on Object {
      return nodeId;
    }
  }

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
    // 旧固定词 → 块库/颜料版的一次性迁移（幂等，meta 旗标短路）。
    await FixedTagMigrationService(
      blockStorage: ref.watch(promptBlockStorageProvider),
      localStorage: ref.watch(localStorageServiceProvider),
    ).run();
    // 旧本地词库 → 块库的一次性迁移（复制不搬移；退役确认后旧键才清理）。
    await TagLibraryMigrationService(
      blockStorage: ref.watch(promptBlockStorageProvider),
      localStorage: ref.watch(localStorageServiceProvider),
    ).run();
    final data = await ref.watch(promptBlockRepositoryProvider).load();
    return PromptBlockLibraryState(
      blocks: data.blocks,
      folders: data.folders,
      collections: data.collections,
    );
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
    String? thumbnail,
    double thumbnailOffsetX = 0.0,
    double thumbnailOffsetY = 0.0,
    double thumbnailScale = 1.0,
    int? sortOrder,
    List<String>? atoms,
    String negativeContent = '',
    List<String>? negativeAtoms,
    PromptBlockGenerationSettings? generationSettings,
    List<PromptBlockTag> tags = const [],
  }) {
    return _mutate(
      (repository) => repository.createBlock(
        title: title,
        content: content,
        folderId: folderId,
        atoms: atoms,
        negativeContent: negativeContent,
        negativeAtoms: negativeAtoms,
        generationSettings: generationSettings,
        tags: tags,
        color: color,
        iconName: iconName,
        thumbnail: thumbnail,
        thumbnailOffsetX: thumbnailOffsetX,
        thumbnailOffsetY: thumbnailOffsetY,
        thumbnailScale: thumbnailScale,
        sortOrder: sortOrder,
      ),
    );
  }

  Future<PromptBlock> updateBlock(PromptBlock block) =>
      _mutate((repository) => repository.updateBlock(block));

  /// 使用次数 +1：块被插入提示词（点击/拖拽同一汇点）时调用。
  ///
  /// 轻量路径——只回写单条块记录、原位替换 state 中该条，不走整库
  /// reload，避免每次插入都触发块库面板重建；失败静默，不阻断插入。
  Future<void> incrementUseCount(String blockId) async {
    // 块库 Box 未初始化（纯内存测试等）时直接短路：不触发 lazy 初始化，
    // 也就不会产生存储层异常。
    if (!Hive.isBoxOpen(PromptBlockStorage.boxName)) return;
    try {
      final repository = ref.read(promptBlockRepositoryProvider);
      final existing = await repository.getBlock(blockId);
      if (existing == null) return;
      final updated = await repository.updateBlock(
        existing.copyWith(useCount: existing.useCount + 1),
      );
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData(
        PromptBlockLibraryState(
          blocks: [
            for (final block in current.blocks)
              block.id == blockId ? updated : block,
          ],
          folders: current.folders,
          collections: current.collections,
        ),
      );
    } catch (_) {
      // 统计失败不阻断主流程
    }
  }

  Future<PromptBlock> toggleFavorite(String blockId) =>
      _mutate((repository) => repository.toggleFavorite(blockId));

  Future<PromptBlock> moveBlock(String blockId, String? folderId) =>
      _mutate((repository) => repository.moveBlock(blockId, folderId));

  Future<void> deleteBlock(String blockId) async {
    final thumbnail = state.valueOrNull?.blockById(blockId)?.thumbnail;
    await _mutate((repository) => repository.deleteBlock(blockId));
    await deletePromptBlockThumbnail(thumbnail);
  }

  /// 批量删除块：循环单块删除，末尾单次整库 reload（不走 N 次 [_mutate]）。
  /// 任一块失败即中断并进入 AsyncError，reload 后状态以落盘为准。
  /// 成功删除的块其缩略图文件一并回收。
  Future<void> deleteBlocks(List<String> blockIds) async {
    if (blockIds.isEmpty) return;
    final repository = ref.read(promptBlockRepositoryProvider);
    final thumbnails = {
      for (final id in blockIds)
        if (state.valueOrNull?.blockById(id)?.thumbnail case final path?) path,
    };
    try {
      for (final blockId in blockIds) {
        await repository.deleteBlock(blockId);
      }
      state = AsyncData(_toState(await repository.load()));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
    for (final path in thumbnails.nonNulls) {
      await deletePromptBlockThumbnail(path);
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

  /// 目标中同源实体的数量。替换前由界面明确征求确认。
  int transferConflictCount(
    List<String> ids,
    PromptBlockTransferTarget target,
  ) {
    final current = state.valueOrNull;
    if (current == null) return 0;
    final destination = _blocksInTransferTarget(current, target);
    return ids.where((id) {
      final source = current.blockById(id);
      return source != null &&
          destination.any(
            (item) =>
                item.id != source.id && item.lineageKey == source.lineageKey,
          );
    }).length;
  }

  List<PromptBlock> _blocksInTransferTarget(
    PromptBlockLibraryState current,
    PromptBlockTransferTarget target,
  ) => switch (target.kind) {
    PromptBlockTransferKind.folder =>
      current.blocks.where((block) => block.folderId == target.id).toList(),
    PromptBlockTransferKind.favorites => current.favoriteBlocks,
    PromptBlockTransferKind.collection =>
      current.blocks
          .where(
            (block) =>
                current
                    .collectionById(target.id ?? '')
                    ?.blockIds
                    .contains(block.id) ??
                false,
          )
          .toList(),
  };

  /// 复制创建独立实体；移动保留原 ID。替换保留目标 ID，使目标已有引用稳定。
  Future<void> transferBlocks(
    List<String> ids,
    PromptBlockTransferTarget target,
    PromptBlockTransferMode mode, {
    String? sourceCollectionId,
    bool sourceFavorites = false,
    bool replaceConflicts = false,
  }) async {
    if (ids.isEmpty) return;
    final repository = ref.read(promptBlockRepositoryProvider);
    final current = _toState(await repository.load());
    final destination = _blocksInTransferTarget(current, target);
    final sources = [
      for (final id in ids)
        if (current.blockById(id) case final block?) block,
    ];
    if (sources.length != ids.toSet().length) {
      throw StateError('块库已变化，请重新选择后再试');
    }
    if (sources.map((block) => block.lineageKey).toSet().length !=
        sources.length) {
      throw StateError('所选块包含同源副本，请分开整理');
    }
    final conflicts = <String, PromptBlock>{};
    for (final source in sources) {
      for (final item in destination) {
        if (item.id != source.id && item.lineageKey == source.lineageKey) {
          conflicts[source.id] = item;
          break;
        }
      }
    }
    if (conflicts.isNotEmpty && !replaceConflicts) {
      throw StateError('同源块已存在，请确认替换');
    }
    final createdThumbnails = <String>[];
    final oldThumbnails = <String>[];
    try {
      for (final source in sources) {
        final existing = conflicts[source.id];
        // 原地复制不新增同源重影；原地移动仍需清理来源的其他分类关系。
        if (mode == PromptBlockTransferMode.copy &&
            destination.any((item) => item.id == source.id)) {
          continue;
        }
        PromptBlock placed;
        if (existing != null || mode == PromptBlockTransferMode.copy) {
          String? imagePath;
          if (source.thumbnail case final path?) {
            final file = File(path);
            if (await file.exists()) {
              imagePath = await savePromptBlockThumbnail(
                await file.readAsBytes(),
              );
              createdThumbnails.add(imagePath);
            }
          }
          if (existing != null) {
            if (existing.thumbnail case final path?) oldThumbnails.add(path);
            placed = await repository.updateBlock(
              source.copyWith(
                id: existing.id,
                lineageId: source.lineageKey,
                folderId: existing.folderId,
                sortOrder: existing.sortOrder,
                isFavorite: existing.isFavorite,
                thumbnail: imagePath,
                createdAt: existing.createdAt,
                useCount: existing.useCount,
                sourcePath: null,
                sourceHash: null,
                importedAt: null,
              ),
            );
          } else {
            placed = source.copyWith(
              id: const Uuid().v4(),
              lineageId: source.lineageKey,
              folderId: null,
              isFavorite: false,
              thumbnail: imagePath,
              useCount: 0,
              sourcePath: null,
              sourceHash: null,
              importedAt: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await repository.importBlocks([placed]);
            placed = await repository.moveBlock(placed.id, null);
          }
        } else {
          placed = source;
        }
        if (target.kind == PromptBlockTransferKind.folder) {
          if (placed.folderId != target.id) {
            placed = await repository.moveBlock(placed.id, target.id);
          }
        } else {
          if (!placed.isFavorite) {
            placed = await repository.toggleFavorite(placed.id);
          }
          if (target.kind == PromptBlockTransferKind.collection) {
            final collection = (await repository.load()).getCollection(
              target.id!,
            );
            if (collection == null || collection.isFolder) {
              throw StateError('收藏集不存在');
            }
            if (!collection.blockIds.contains(placed.id)) {
              await repository.toggleBlockInCollection(target.id!, placed.id);
            }
          }
          if (mode == PromptBlockTransferMode.move && placed.folderId != null) {
            await repository.moveBlock(placed.id, null);
          }
        }
        if (mode == PromptBlockTransferMode.move) {
          if (sourceCollectionId != null && sourceCollectionId != target.id) {
            final sourceNode = current.collectionById(sourceCollectionId);
            final sourceIds = sourceNode?.isFolder == true
                ? current.collections.getDescendantIds(sourceCollectionId)
                : {sourceCollectionId};
            for (final collectionId in sourceIds) {
              if (collectionId == target.id) continue;
              final collection = (await repository.load()).getCollection(
                collectionId,
              );
              if (collection?.isFolder == false &&
                  (collection?.blockIds.contains(source.id) ?? false)) {
                await repository.toggleBlockInCollection(
                  collectionId,
                  source.id,
                );
              }
            }
          }
          if (sourceFavorites &&
              target.kind == PromptBlockTransferKind.folder &&
              placed.isFavorite) {
            await repository.toggleFavorite(placed.id);
          }
          if (existing != null) {
            if (source.thumbnail case final path?) oldThumbnails.add(path);
            await repository.deleteBlock(source.id);
          }
        }
      }
      state = AsyncData(_toState(await repository.load()));
      for (final path in oldThumbnails) {
        if (!state.valueOrNull!.blocks.any(
          (block) => block.thumbnail == path,
        )) {
          await deletePromptBlockThumbnail(path);
        }
      }
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      for (final path in createdThumbnails) {
        if (!(await repository.load()).blocks.any(
          (block) => block.thumbnail == path,
        )) {
          await deletePromptBlockThumbnail(path);
        }
      }
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

  // ==================== 收藏集 ====================

  /// 创建收藏集（[isFolder]=false）或收藏文件夹（=true）。
  /// [parentId] 非空时必须指向一个收藏文件夹。
  Future<PromptBlockCollection> createCollection({
    required String name,
    String? parentId,
    bool isFolder = false,
  }) {
    return _mutate(
      (repository) => repository.createCollection(
        name: name,
        parentId: parentId,
        isFolder: isFolder,
      ),
    );
  }

  /// 重命名收藏集 / 收藏文件夹。
  Future<PromptBlockCollection> renameCollection(
    String collectionId,
    String name,
  ) async {
    final existing = state.valueOrNull?.collectionById(collectionId);
    if (existing == null) {
      throw StateError('Prompt block collection does not exist: $collectionId');
    }
    return _mutate(
      (repository) =>
          repository.updateCollection(existing.copyWith(name: name)),
    );
  }

  /// 移动收藏集 / 收藏文件夹到新父级（null=收藏区根级）。
  Future<PromptBlockCollection> moveCollection(
    String collectionId,
    String? newParentId,
  ) => _mutate(
    (repository) => repository.moveCollection(collectionId, newParentId),
  );

  /// 同级重排收藏集 / 收藏文件夹。
  Future<void> reorderCollections(String? parentId, List<String> orderedIds) =>
      _mutate(
        (repository) => repository.reorderCollections(parentId, orderedIds),
      );

  /// 删除收藏集 / 收藏文件夹（连带子树）；块本体不受影响。
  Future<void> deleteCollection(String collectionId) =>
      _mutate((repository) => repository.deleteCollection(collectionId));

  /// 切换块在收藏集中的成员关系，返回切换后的成员状态。
  /// 加入收藏集时顺带把块标记为已收藏（入集即收藏）。
  Future<bool> toggleBlockInCollection(String collectionId, String blockId) =>
      _mutate(
        (repository) =>
            repository.toggleBlockInCollection(collectionId, blockId),
      );

  Future<void> deleteFolder(
    String folderId, {
    required PromptBlockFolderDeleteMode mode,
    String? destinationFolderId,
  }) async {
    // 连删模式：先记下整棵子树内块的缩略图，删除成功后回收文件。
    final thumbnails = mode == PromptBlockFolderDeleteMode.deleteContents
        ? {
            for (final block
                in state.valueOrNull?.blocksInFolderTree(folderId) ??
                    const <PromptBlock>[])
              if (block.thumbnail case final path?) path,
          }
        : const <String>{};
    await _mutate(
      (repository) => repository.deleteFolder(
        folderId,
        mode: mode,
        destinationFolderId: destinationFolderId,
      ),
    );
    for (final path in thumbnails) {
      await deletePromptBlockThumbnail(path);
    }
  }

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
    return PromptBlockLibraryState(
      blocks: data.blocks,
      folders: data.folders,
      collections: data.collections,
    );
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
