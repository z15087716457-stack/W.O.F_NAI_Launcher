import 'package:collection/collection.dart' show DeepCollectionEquality;

import '../models/prompt_block/prompt_block.dart';
import '../models/prompt_block/prompt_block_collection.dart';
import '../models/prompt_block/prompt_block_folder.dart';
import '../../core/storage/prompt_block_storage.dart';

/// 读取后的块库数据快照。
///
/// 这是一次读取结果，不是 Prompt 工作区实例；修改其中的 Freezed 副本
/// 不会自动写回公共块库。
class PromptBlockLibraryData {
  PromptBlockLibraryData({
    required List<PromptBlock> blocks,
    required List<PromptBlockFolder> folders,
    List<PromptBlockCollection>? collections,
  }) : blocks = List.unmodifiable(blocks),
       folders = List.unmodifiable(folders),
       collections = List.unmodifiable(collections ?? const []);

  final List<PromptBlock> blocks;
  final List<PromptBlockFolder> folders;
  final List<PromptBlockCollection> collections;

  PromptBlock? getBlock(String id) {
    for (final block in blocks) {
      if (block.id == id) return block;
    }
    return null;
  }

  PromptBlockFolder? getFolder(String id) {
    for (final folder in folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  PromptBlockCollection? getCollection(String id) {
    for (final collection in collections) {
      if (collection.id == id) return collection;
    }
    return null;
  }
}

/// 删除文件夹时对其内容的明确处理方式。
enum PromptBlockFolderDeleteMode {
  /// 删除文件夹树，并把其中所有块移动到根目录。
  moveContentsToRoot,

  /// 删除文件夹树，并把其中所有块移动到指定目标文件夹。
  moveContentsToFolder,

  /// 连同文件夹树中的所有块一起删除。
  deleteContents,
}

/// 全局 Prompt 块库 Repository。
class PromptBlockRepository {
  PromptBlockRepository(this._storage);

  final PromptBlockStorage _storage;

  /// 读取块、文件夹和收藏集树的当前快照。
  Future<PromptBlockLibraryData> load() async {
    final results = await Future.wait([
      _storage.getBlocks(),
      _storage.getFolders(),
      _storage.getCollections(),
    ]);
    return PromptBlockLibraryData(
      blocks: results[0] as List<PromptBlock>,
      folders: results[1] as List<PromptBlockFolder>,
      collections: results[2] as List<PromptBlockCollection>,
    );
  }

  Future<PromptBlock?> getBlock(String id) => _storage.getBlock(id);

  Future<PromptBlockFolder?> getFolder(String id) => _storage.getFolder(id);

  /// Usage is a counter, not an edit of the definition read before an await.
  Future<PromptBlock?> incrementUseCount(String id) => _storage.transformBlock(
    id,
    (current) => current?.copyWith(useCount: current.useCount + 1),
  );

  /// 创建块，并自动取得目标文件夹内的下一个排序值。
  ///
  /// [thumbnail] 必须已是应用块缩略图目录内的路径（调用方负责落盘；
  /// 见 `savePromptBlockThumbnail`），本层不做文件搬移。
  Future<PromptBlock> createBlock({
    required String title,
    required String content,
    String? folderId,
    String color = '#FF607D8B',
    String appearance = 'classic',
    String? readingTranslationZh,
    List<Map<String, dynamic>>? readingTranslationMarks,
    bool readingTranslationNeedsReview = false,
    String readingTranslationLanguageCode = 'zh',
    bool readingTranslationEdited = false,
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
    bool isFavorite = false,
    void Function()? beforeWrite,
  }) async {
    await _ensureFolderExists(folderId);
    final blocks = await _storage.getBlocks();
    final block = PromptBlock.create(
      title: title,
      content: content,
      readingTranslationZh: readingTranslationZh,
      readingTranslationMarks: readingTranslationMarks,
      readingTranslationNeedsReview: readingTranslationNeedsReview,
      readingTranslationLanguageCode: readingTranslationLanguageCode,
      readingTranslationEdited: readingTranslationEdited,
      folderId: folderId,
      atoms: atoms,
      negativeContent: negativeContent,
      negativeAtoms: negativeAtoms,
      generationSettings: generationSettings,
      tags: tags,
      isFavorite: isFavorite,
      color: color,
      appearance: appearance,
      iconName: iconName,
      thumbnail: thumbnail,
      thumbnailOffsetX: thumbnailOffsetX,
      thumbnailOffsetY: thumbnailOffsetY,
      thumbnailScale: thumbnailScale,
      sortOrder: sortOrder ?? _nextSortOrder(blocks, folderId),
    );
    if (beforeWrite == null) {
      await _storage.putBlock(block);
    } else {
      await _storage.transformBlock(block.id, (current) {
        beforeWrite();
        if (current != null) throw StateError('Block identity already exists');
        return block;
      });
    }
    await _harmonizeTagColors(block.tags);
    return block;
  }

  /// 更新块。更新不会改变块 ID；正文仍按原文保存。
  Future<PromptBlock> updateBlock(
    PromptBlock block, {
    void Function(PromptBlock?)? beforeWrite,
  }) async {
    final existing = await _storage.getBlock(block.id);
    if (existing == null) {
      throw StateError('Prompt block does not exist: ${block.id}');
    }

    var updated = block.copyWith(updatedAt: DateTime.now());
    if (beforeWrite == null) {
      await _storage.putBlock(updated);
    } else {
      updated = (await _storage.transformBlock(block.id, (current) {
        beforeWrite(current);
        if (current == null) throw StateError('Prompt block disappeared');
        return updated.copyWith(useCount: current.useCount);
      }))!;
    }
    if (!const DeepCollectionEquality().equals(existing.tags, updated.tags)) {
      await _harmonizeTagColors(updated.tags);
    }
    return updated;
  }

  /// 同名标签以最近一次明确保存的颜色为准，避免筛选视图出现同名异色。
  Future<void> _harmonizeTagColors(List<PromptBlockTag> tags) async {
    if (tags.isEmpty) return;
    final colors = {for (final tag in tags) tag.name.toLowerCase(): tag.color};
    for (final candidate in await _storage.getBlocks()) {
      await _storage.transformBlock(candidate.id, (block) {
        if (block == null) return null;
        var changed = false;
        final updatedTags = <PromptBlockTag>[];
        for (final tag in block.tags) {
          final color = colors[tag.name.toLowerCase()];
          if (color != null && color != tag.color) {
            updatedTags.add(tag.copyWith(color: color));
            changed = true;
          } else {
            updatedTags.add(tag);
          }
        }
        return changed
            ? block.copyWith(tags: updatedTags, updatedAt: DateTime.now())
            : block;
      });
    }
  }

  /// 切换块的收藏状态。
  Future<PromptBlock> toggleFavorite(String blockId) async {
    final block = await _storage.getBlock(blockId);
    if (block == null) {
      throw StateError('Prompt block does not exist: $blockId');
    }
    return updateBlock(block.copyWith(isFavorite: !block.isFavorite));
  }

  /// 移动块到另一个文件夹。
  Future<PromptBlock> moveBlock(String blockId, String? folderId) async {
    final block = await _storage.getBlock(blockId);
    if (block == null) {
      throw StateError('Prompt block does not exist: $blockId');
    }
    await _ensureFolderExists(folderId);
    final blocks = await _storage.getBlocks();
    return updateBlock(
      block.copyWith(
        folderId: folderId,
        sortOrder: _nextSortOrder(blocks, folderId),
      ),
    );
  }

  /// 删除块；不存在时保持幂等。顺带从所有收藏集成员列表中修剪该 ID。
  Future<void> deleteBlock(
    String blockId, {
    void Function(PromptBlock?)? beforeWrite,
  }) async {
    if (beforeWrite == null) {
      await _storage.deleteBlock(blockId);
    } else {
      await _storage.transformBlock(blockId, (current) {
        beforeWrite(current);
        return null;
      });
    }
    await _pruneBlocksFromCollections({blockId});
  }

  /// 替换移动时隐藏来源，但保留 ID 和内容供既有提示词实例继续展开。
  Future<PromptBlock> archiveBlockForReferences(String blockId) async {
    final block = await _storage.getBlock(blockId);
    if (block == null) {
      throw StateError('Prompt block does not exist: $blockId');
    }
    final archived = await updateBlock(
      block.copyWith(
        isArchived: true,
        folderId: null,
        isFavorite: false,
        sourcePath: null,
        sourceHash: null,
        importedAt: null,
      ),
    );
    await _pruneBlocksFromCollections({blockId});
    return archived;
  }

  /// 批量写入导入的块，保留给定实体的 ID、时间戳和来源字段。
  ///
  /// 仅供外部来源导入（TXT / 策展目录 / 库备份）使用；调用方负责
  /// 去重与覆盖决策——同 ID 实体在这里会被直接覆盖。
  Future<void> importBlocks(Iterable<PromptBlock> blocks) =>
      _storage.putBlocks(blocks);

  /// 批量写入导入的文件夹，语义与 [importBlocks] 一致。
  Future<void> importFolders(Iterable<PromptBlockFolder> folders) =>
      _storage.putFolders(folders);

  PromptBlockLibraryData get currentLibrary {
    final data = _storage.currentLibrary;
    return PromptBlockLibraryData(
      blocks: data.blocks,
      folders: data.folders,
      collections: data.collections,
    );
  }

  /// Deletes one empty folder; moving blocks remains an explicit separate edit.
  Future<void> deleteEmptyFolder(String id, {void Function()? beforeWrite}) =>
      _storage.deleteFolder(
        id,
        beforeWrite: () {
          beforeWrite?.call();
          final data = currentLibrary;
          if (data.blocks.any((b) => b.folderId == id) ||
              data.folders.any((f) => f.parentId == id)) {
            throw StateError('Move folder contents before deleting the folder');
          }
        },
      );

  Future<void> setCollectionMembership(
    String collectionId,
    String blockId,
    bool member, {
    void Function()? beforeWrite,
  }) => _storage.setCollectionMembership(
    collectionId,
    blockId,
    member,
    beforeWrite: beforeWrite,
  );

  /// 创建文件夹，并自动取得同级下一个排序值。
  Future<PromptBlockFolder> createFolder({
    required String name,
    String? parentId,
    int? sortOrder,
    void Function()? beforeWrite,
  }) async {
    await _ensureFolderExists(parentId);
    final folders = await _storage.getFolders();
    final folder = PromptBlockFolder.create(
      name: name,
      parentId: parentId,
      sortOrder: sortOrder ?? _nextFolderSortOrder(folders, parentId),
    );
    await _storage.putFolder(folder, beforeWrite: beforeWrite);
    return folder;
  }

  /// 更新文件夹；父级变更会检查循环引用。
  Future<PromptBlockFolder> updateFolder(
    PromptBlockFolder folder, {
    void Function()? beforeWrite,
  }) async {
    final existing = await _storage.getFolder(folder.id);
    if (existing == null) {
      throw StateError('Prompt block folder does not exist: ${folder.id}');
    }
    await _validateFolderParent(folder.id, folder.parentId);

    final updated = folder.copyWith(
      name: folder.name.trim(),
      updatedAt: DateTime.now(),
    );
    await _storage.putFolder(updated, beforeWrite: beforeWrite);
    return updated;
  }

  /// 移动文件夹；禁止移动到自身或后代。
  Future<PromptBlockFolder> moveFolder(
    String folderId,
    String? newParentId,
  ) async {
    final folder = await _storage.getFolder(folderId);
    if (folder == null) {
      throw StateError('Prompt block folder does not exist: $folderId');
    }
    return updateFolder(folder.copyWith(parentId: newParentId));
  }

  /// 同级重排块。传入的 ID 必须完整覆盖该层级的直属块。
  Future<void> reorderBlocks(
    String? folderId,
    List<String> orderedBlockIds, {
    void Function()? beforeWrite,
  }) async {
    final blocks = await _storage.getBlocks();
    final siblings = blocks.childrenOf(folderId);
    _validateCompleteOrder(
      expectedIds: siblings.map((block) => block.id),
      actualIds: orderedBlockIds,
      kind: 'Prompt block',
    );

    final byId = <String, PromptBlock>{
      for (final block in siblings) block.id: block,
    };
    final now = DateTime.now();
    await _storage.putBlocks(
      orderedBlockIds.asMap().entries.map(
        (entry) =>
            byId[entry.value]!.copyWith(sortOrder: entry.key, updatedAt: now),
      ),
      beforeWrite: beforeWrite,
    );
  }

  /// 同级重排文件夹。传入的 ID 必须完整覆盖该层级的直属文件夹。
  Future<void> reorderFolders(
    String? parentId,
    List<String> orderedFolderIds, {
    void Function()? beforeWrite,
  }) async {
    final folders = await _storage.getFolders();
    final siblings = folders.childrenOf(parentId);
    _validateCompleteOrder(
      expectedIds: siblings.map((folder) => folder.id),
      actualIds: orderedFolderIds,
      kind: 'Prompt block folder',
    );

    final byId = <String, PromptBlockFolder>{
      for (final folder in siblings) folder.id: folder,
    };
    final now = DateTime.now();
    await _storage.putFolders(
      orderedFolderIds.asMap().entries.map(
        (entry) =>
            byId[entry.value]!.copyWith(sortOrder: entry.key, updatedAt: now),
      ),
      beforeWrite: beforeWrite,
    );
  }

  /// 删除文件夹树，并按明确模式处理其中内容。
  Future<void> deleteFolder(
    String folderId, {
    required PromptBlockFolderDeleteMode mode,
    String? destinationFolderId,
  }) async {
    final folders = await _storage.getFolders();
    final target = folders.where((folder) => folder.id == folderId).firstOrNull;
    if (target == null) {
      return;
    }

    final folderIds = <String>{folderId, ...folders.getDescendantIds(folderId)};
    final destinationId = switch (mode) {
      PromptBlockFolderDeleteMode.moveContentsToRoot => null,
      PromptBlockFolderDeleteMode.moveContentsToFolder => destinationFolderId,
      PromptBlockFolderDeleteMode.deleteContents => null,
    };

    if (mode == PromptBlockFolderDeleteMode.moveContentsToFolder) {
      if (destinationId == null) {
        throw ArgumentError('Moving folder contents requires a destination');
      }
      if (folderIds.contains(destinationId)) {
        throw ArgumentError('Cannot move folder contents into its own subtree');
      }
      await _ensureFolderExists(destinationId);
    }

    final blocks = await _storage.getBlocks();
    final affectedBlocks = blocks
        .where(
          (block) =>
              block.folderId != null && folderIds.contains(block.folderId),
        )
        .toList();

    switch (mode) {
      case PromptBlockFolderDeleteMode.deleteContents:
        await _storage.deleteBlocks(affectedBlocks.map((block) => block.id));
        await _pruneBlocksFromCollections(
          affectedBlocks.map((block) => block.id).toSet(),
        );
      case PromptBlockFolderDeleteMode.moveContentsToRoot:
      case PromptBlockFolderDeleteMode.moveContentsToFolder:
        final destinationSiblings = blocks
            .where(
              (block) =>
                  block.folderId == destinationId &&
                  !affectedBlocks.any((affected) => affected.id == block.id),
            )
            .toList();
        var nextSortOrder = _nextSortOrder(destinationSiblings, destinationId);
        affectedBlocks.sort(_compareBlocksByOrder);
        final now = DateTime.now();
        await _storage.putBlocks(
          affectedBlocks.map(
            (block) => block.copyWith(
              folderId: destinationId,
              sortOrder: nextSortOrder++,
              updatedAt: now,
            ),
          ),
        );
    }

    await _storage.deleteFolders(folderIds);
  }

  // ==================== 收藏集 / 收藏文件夹 ====================

  /// 创建收藏集（[isFolder]=false）或收藏文件夹（=true），自动取同级
  /// 下一个排序值。[parentId] 非空时必须指向一个收藏文件夹。
  Future<PromptBlockCollection> createCollection({
    required String name,
    String? parentId,
    bool isFolder = false,
    int? sortOrder,
    void Function()? beforeWrite,
  }) async {
    await _ensureCollectionParentExists(parentId);
    final collections = await _storage.getCollections();
    final collection = PromptBlockCollection.create(
      name: name,
      parentId: parentId,
      isFolder: isFolder,
      sortOrder: sortOrder ?? _nextCollectionSortOrder(collections, parentId),
    );
    await _storage.putCollection(collection, beforeWrite: beforeWrite);
    return collection;
  }

  /// 更新收藏集 / 收藏文件夹；父级变更会检查存在性与循环引用。
  Future<PromptBlockCollection> updateCollection(
    PromptBlockCollection collection, {
    void Function()? beforeWrite,
  }) async {
    final existing = await _storage.getCollection(collection.id);
    if (existing == null) {
      throw StateError(
        'Prompt block collection does not exist: ${collection.id}',
      );
    }
    if (collection.parentId != existing.parentId) {
      await _ensureCollectionParentExists(collection.parentId);
      final collections = await _storage.getCollections();
      if (collections.wouldCreateCycle(collection.id, collection.parentId)) {
        throw ArgumentError(
          'Moving a Prompt block collection would create a cycle',
        );
      }
    }

    final updated = collection.copyWith(
      name: collection.name.trim(),
      updatedAt: DateTime.now(),
    );
    await _storage.putCollection(updated, beforeWrite: beforeWrite);
    return updated;
  }

  /// 移动收藏集 / 收藏文件夹到新父级（null=收藏区根级）；
  /// 禁止移动到自身或后代。
  Future<PromptBlockCollection> moveCollection(
    String collectionId,
    String? newParentId,
  ) async {
    final collection = await _storage.getCollection(collectionId);
    if (collection == null) {
      throw StateError('Prompt block collection does not exist: $collectionId');
    }
    return updateCollection(collection.copyWith(parentId: newParentId));
  }

  /// 同级重排收藏集 / 收藏文件夹（混合排序）。传入的 ID 必须完整覆盖
  /// 该层级的直属节点。
  Future<void> reorderCollections(
    String? parentId,
    List<String> orderedIds, {
    void Function()? beforeWrite,
  }) async {
    final collections = await _storage.getCollections();
    final siblings = collections.childrenOf(parentId);
    _validateCompleteOrder(
      expectedIds: siblings.map((node) => node.id),
      actualIds: orderedIds,
      kind: 'Prompt block collection',
    );

    final byId = <String, PromptBlockCollection>{
      for (final node in siblings) node.id: node,
    };
    final now = DateTime.now();
    await _storage.putCollections(
      orderedIds.asMap().entries.map(
        (entry) =>
            byId[entry.value]!.copyWith(sortOrder: entry.key, updatedAt: now),
      ),
      beforeWrite: beforeWrite,
    );
  }

  /// 删除收藏集或收藏文件夹。删除文件夹会连带删除整棵子树
  /// （子文件夹 + 其中收藏集）；成员块本体不受影响，仅解除成员关系。
  Future<void> deleteCollection(
    String collectionId, {
    void Function()? beforeWrite,
  }) async {
    final collections = await _storage.getCollections();
    final target = collections
        .where((node) => node.id == collectionId)
        .firstOrNull;
    if (target == null) return;

    final ids = <String>{
      collectionId,
      ...collections.getDescendantIds(collectionId),
    };
    await _storage.deleteCollections(ids, beforeWrite: beforeWrite);
  }

  /// 切换块在收藏集中的成员关系，返回切换后的成员状态。
  /// 加入收藏集时顺带把块标记为已收藏（入集即收藏）；
  /// 移出收藏集不动收藏旗标。
  Future<bool> toggleBlockInCollection(
    String collectionId,
    String blockId,
  ) async {
    final collection = await _storage.getCollection(collectionId);
    if (collection == null || collection.isFolder) {
      throw StateError('Prompt block collection does not exist: $collectionId');
    }
    final block = await _storage.getBlock(blockId);
    if (block == null) {
      throw StateError('Prompt block does not exist: $blockId');
    }

    final members = [...collection.blockIds];
    final nowMember = !members.remove(blockId);
    if (nowMember) members.add(blockId);
    await _storage.putCollection(
      collection.copyWith(blockIds: members, updatedAt: DateTime.now()),
    );
    if (nowMember && !block.isFavorite) {
      await updateBlock(block.copyWith(isFavorite: true));
    }
    return nowMember;
  }

  /// 块当前所在的收藏集 ID 集合（不含收藏文件夹）。
  Set<String> collectionIdsOfBlock(
    String blockId,
    List<PromptBlockCollection> collections,
  ) {
    return {
      for (final node in collections)
        if (!node.isFolder && node.blockIds.contains(blockId)) node.id,
    };
  }

  /// 从所有收藏集成员列表中修剪给定块 ID。
  Future<void> _pruneBlocksFromCollections(Set<String> blockIds) async {
    if (blockIds.isEmpty) return;
    final collections = await _storage.getCollections();
    final now = DateTime.now();
    for (final node in collections) {
      if (node.isFolder || node.blockIds.isEmpty) continue;
      final remaining = node.blockIds
          .where((id) => !blockIds.contains(id))
          .toList();
      if (remaining.length != node.blockIds.length) {
        await _storage.transformCollection(
          node.id,
          (current) => current?.copyWith(
            blockIds: current.blockIds
                .where((id) => !blockIds.contains(id))
                .toList(),
            updatedAt: now,
          ),
        );
      }
    }
  }

  Future<void> _ensureCollectionParentExists(String? parentId) async {
    if (parentId == null) return;
    final parent = await _storage.getCollection(parentId);
    if (parent == null || !parent.isFolder) {
      throw ArgumentError(
        'Prompt block collection folder does not exist: $parentId',
      );
    }
  }

  int _nextCollectionSortOrder(
    List<PromptBlockCollection> collections,
    String? parentId,
  ) {
    var maximum = -1;
    for (final node in collections.where((node) => node.parentId == parentId)) {
      if (node.sortOrder > maximum) maximum = node.sortOrder;
    }
    return maximum + 1;
  }

  Future<void> _ensureFolderExists(String? folderId) async {
    if (folderId == null) return;
    final folder = await _storage.getFolder(folderId);
    if (folder == null) {
      throw ArgumentError('Prompt block folder does not exist: $folderId');
    }
  }

  Future<void> _validateFolderParent(String folderId, String? parentId) async {
    await _ensureFolderExists(parentId);
    final folders = await _storage.getFolders();
    if (folders.wouldCreateCycle(folderId, parentId)) {
      throw ArgumentError('Moving a Prompt block folder would create a cycle');
    }
  }

  int _nextSortOrder(List<PromptBlock> blocks, String? folderId) {
    var maximum = -1;
    for (final block in blocks.where((block) => block.folderId == folderId)) {
      if (block.sortOrder > maximum) maximum = block.sortOrder;
    }
    return maximum + 1;
  }

  int _nextFolderSortOrder(List<PromptBlockFolder> folders, String? parentId) {
    var maximum = -1;
    for (final folder in folders.where(
      (folder) => folder.parentId == parentId,
    )) {
      if (folder.sortOrder > maximum) maximum = folder.sortOrder;
    }
    return maximum + 1;
  }

  void _validateCompleteOrder({
    required Iterable<String> expectedIds,
    required List<String> actualIds,
    required String kind,
  }) {
    final expected = expectedIds.toSet();
    final actual = actualIds.toSet();
    if (expected.length != actualIds.length ||
        actual.length != expected.length ||
        !actual.containsAll(expected)) {
      throw ArgumentError(
        '$kind reorder must include each sibling exactly once',
      );
    }
  }
}

int _compareBlocksByOrder(PromptBlock a, PromptBlock b) {
  final orderComparison = a.sortOrder.compareTo(b.sortOrder);
  if (orderComparison != 0) return orderComparison;
  return a.id.compareTo(b.id);
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
