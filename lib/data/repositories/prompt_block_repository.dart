import '../models/prompt_block/prompt_block.dart';
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
  }) : blocks = List.unmodifiable(blocks),
       folders = List.unmodifiable(folders);

  final List<PromptBlock> blocks;
  final List<PromptBlockFolder> folders;

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

  /// 读取块和文件夹的当前快照。
  Future<PromptBlockLibraryData> load() async {
    final results = await Future.wait([
      _storage.getBlocks(),
      _storage.getFolders(),
    ]);
    return PromptBlockLibraryData(
      blocks: results[0] as List<PromptBlock>,
      folders: results[1] as List<PromptBlockFolder>,
    );
  }

  Future<PromptBlock?> getBlock(String id) => _storage.getBlock(id);

  Future<PromptBlockFolder?> getFolder(String id) => _storage.getFolder(id);

  /// 创建块，并自动取得目标文件夹内的下一个排序值。
  Future<PromptBlock> createBlock({
    required String title,
    required String content,
    String? folderId,
    String color = '#FF607D8B',
    String? iconName,
    int? sortOrder,
  }) async {
    await _ensureFolderExists(folderId);
    final blocks = await _storage.getBlocks();
    final block = PromptBlock.create(
      title: title,
      content: content,
      folderId: folderId,
      color: color,
      iconName: iconName,
      sortOrder: sortOrder ?? _nextSortOrder(blocks, folderId),
    );
    await _storage.putBlock(block);
    return block;
  }

  /// 更新块。更新不会改变块 ID；正文仍按原文保存。
  Future<PromptBlock> updateBlock(PromptBlock block) async {
    final existing = await _storage.getBlock(block.id);
    if (existing == null) {
      throw StateError('Prompt block does not exist: ${block.id}');
    }

    final updated = block.copyWith(updatedAt: DateTime.now());
    await _storage.putBlock(updated);
    return updated;
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

  /// 删除块；不存在时保持幂等。
  Future<void> deleteBlock(String blockId) => _storage.deleteBlock(blockId);

  /// 批量写入导入的块，保留给定实体的 ID、时间戳和来源字段。
  ///
  /// 仅供外部来源导入（TXT / 策展目录 / 库备份）使用；调用方负责
  /// 去重与覆盖决策——同 ID 实体在这里会被直接覆盖。
  Future<void> importBlocks(Iterable<PromptBlock> blocks) =>
      _storage.putBlocks(blocks);

  /// 批量写入导入的文件夹，语义与 [importBlocks] 一致。
  Future<void> importFolders(Iterable<PromptBlockFolder> folders) =>
      _storage.putFolders(folders);

  /// 创建文件夹，并自动取得同级下一个排序值。
  Future<PromptBlockFolder> createFolder({
    required String name,
    String? parentId,
    int? sortOrder,
  }) async {
    await _ensureFolderExists(parentId);
    final folders = await _storage.getFolders();
    final folder = PromptBlockFolder.create(
      name: name,
      parentId: parentId,
      sortOrder: sortOrder ?? _nextFolderSortOrder(folders, parentId),
    );
    await _storage.putFolder(folder);
    return folder;
  }

  /// 更新文件夹；父级变更会检查循环引用。
  Future<PromptBlockFolder> updateFolder(PromptBlockFolder folder) async {
    final existing = await _storage.getFolder(folder.id);
    if (existing == null) {
      throw StateError('Prompt block folder does not exist: ${folder.id}');
    }
    await _validateFolderParent(folder.id, folder.parentId);

    final updated = folder.copyWith(
      name: folder.name.trim(),
      updatedAt: DateTime.now(),
    );
    await _storage.putFolder(updated);
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
    List<String> orderedBlockIds,
  ) async {
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
    );
  }

  /// 同级重排文件夹。传入的 ID 必须完整覆盖该层级的直属文件夹。
  Future<void> reorderFolders(
    String? parentId,
    List<String> orderedFolderIds,
  ) async {
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
