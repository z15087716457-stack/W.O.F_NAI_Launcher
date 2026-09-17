import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/storage/local_storage_service.dart';
import '../../core/storage/prompt_block_storage.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/prompt_block_thumbnails.dart';
import '../models/prompt_block/prompt_block.dart';
import '../models/prompt_block/prompt_block_folder.dart';
import '../repositories/prompt_block_repository.dart';

/// 旧「本地词库」→ 块库的一次性迁移（EVAL-1 退役路径）。
///
/// 语义：每条词库条目迁为一个块、每个分类迁为一个文件夹，**保留原 id**
/// （UC/画质预设等存量引用按 id 解析条目，保 id 后重定向即可不断链）。
/// 分类树 1:1 平移为文件夹树，同名分类不合并；条目字段 name/content/
/// thumbnail 三参数/useCount/isFavorite/sortOrder/createdAt/updatedAt 全量
/// 随迁，`tags` 与 `lastUsedAt` 在块模型中无对应字段，按蓝图口径丢弃。
///
/// 缩略图字节级复制进 `prompt_block_thumbnails/<blockId><源扩展名>`
/// （幂等覆盖、重试无孤儿文件）；复制失败退回原路径保证可见。
///
/// **复制而非搬移**：试用确认前旧存储键一律不动；确认退役后由后续
/// 批次统一清理键与代码。旗标仅成功才落盘——失败留待下次启动重试，
/// 同 id 覆盖使重试收敛。
///
/// 旧存储解码自包含：不依赖已退役的词库模型/IO 服务，按字面键名与
/// JSON 字段名直接解析（字段名对齐旧 freezed 序列化格式）。
class TagLibraryMigrationService {
  TagLibraryMigrationService({
    required PromptBlockStorage blockStorage,
    required LocalStorageService localStorage,
    Future<String?> Function(String sourcePath, String blockId)?
    thumbnailImporter,
  }) : _blockStorage = blockStorage,
       _localStorage = localStorage,
       _thumbnailImporter = thumbnailImporter ?? _importThumbnailFile;

  final PromptBlockStorage _blockStorage;
  final LocalStorageService _localStorage;

  /// 缩略图导入器：源路径 + 目标块 id → 块应持有的路径；null 表示无图。
  final Future<String?> Function(String sourcePath, String blockId)
  _thumbnailImporter;

  static const String _doneFlag = 'tagLibraryMigrationDone';

  /// 旧词库存储键（字面量；旧 StorageKeys 常量随退役批次删除）。
  static const String _legacyEntriesKey = 'tag_library_entries_data';
  static const String _legacyCategoriesKey = 'tag_library_categories_data';

  /// 执行迁移（幂等）：成功才落旗标；失败不阻塞启动、下次重试。
  Future<void> run() async {
    if (await _blockStorage.getMeta(_doneFlag) == '1') return;
    try {
      final summary = await _migrate();
      await _blockStorage.putMeta(_doneFlag, '1');
      AppLogger.i(
        'Tag-library migration finished: $summary',
        'TagLibraryMigrationService',
      );
    } catch (error, stackTrace) {
      AppLogger.e(
        'Tag-library migration failed',
        error,
        stackTrace,
        'TagLibraryMigrationService',
      );
    }
  }

  /// 返回迁移摘要字符串供日志使用。
  Future<String> _migrate() async {
    final entries = _decodeEntries();
    final categories = _decodeCategories();
    if (entries.isEmpty && categories.isEmpty) {
      return 'empty library';
    }

    final categoryIds = categories.map((c) => c.id).toSet();
    final repository = PromptBlockRepository(_blockStorage);
    final existing = await repository.load();

    // 根级文件夹/块追加在既有内容之后；子级各自新父内保持原 sortOrder。
    var nextRootFolderOrder = _maxFolderOrder(existing.folders, null) + 1;
    var nextRootBlockOrder = _maxBlockOrder(existing.blocks, null) + 1;

    final sortedCategories = [...categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final folders = <PromptBlockFolder>[];
    for (final category in sortedCategories) {
      final isRoot =
          category.parentId == null || !categoryIds.contains(category.parentId);
      folders.add(
        PromptBlockFolder.create(
          id: category.id,
          name: category.name,
          parentId: isRoot ? null : category.parentId,
          sortOrder: isRoot ? nextRootFolderOrder++ : category.sortOrder,
          createdAt: category.createdAt,
        ),
      );
    }

    final sortedEntries = [...entries]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final blocks = <PromptBlock>[];
    for (final entry in sortedEntries) {
      final folderId =
          entry.categoryId != null && categoryIds.contains(entry.categoryId)
          ? entry.categoryId
          : null;
      String? thumbnail;
      if (entry.thumbnail != null && entry.thumbnail!.isNotEmpty) {
        thumbnail = await _thumbnailImporter(entry.thumbnail!, entry.id);
      }
      blocks.add(
        PromptBlock.create(
          id: entry.id,
          title: entry.name.isNotEmpty
              ? entry.name
              : _titleFromContent(entry.content),
          content: entry.content,
          folderId: folderId,
          thumbnail: thumbnail,
          thumbnailOffsetX: entry.thumbnailOffsetX,
          thumbnailOffsetY: entry.thumbnailOffsetY,
          thumbnailScale: entry.thumbnailScale,
          useCount: entry.useCount,
          isFavorite: entry.isFavorite,
          sortOrder: folderId == null ? nextRootBlockOrder++ : entry.sortOrder,
          createdAt: entry.createdAt,
          updatedAt: entry.updatedAt,
        ),
      );
    }

    await repository.importFolders(folders);
    await repository.importBlocks(blocks);

    return '${folders.length} folders, ${blocks.length} blocks, '
        '${blocks.where((b) => b.hasThumbnail).length} thumbnails';
  }

  List<_LegacyEntry> _decodeEntries() {
    final raw = _localStorage.getSetting<String>(_legacyEntriesKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map(
            (e) => _LegacyEntry.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (error, stackTrace) {
      AppLogger.e(
        'Failed to decode tag library entries',
        error,
        stackTrace,
        'TagLibraryMigrationService',
      );
      return const [];
    }
  }

  List<_LegacyCategory> _decodeCategories() {
    final raw = _localStorage.getSetting<String>(_legacyCategoriesKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map(
            (e) =>
                _LegacyCategory.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (error, stackTrace) {
      AppLogger.e(
        'Failed to decode tag library categories',
        error,
        stackTrace,
        'TagLibraryMigrationService',
      );
      return const [];
    }
  }

  /// 默认缩略图导入：字节级复制进 `prompt_block_thumbnails/`。
  ///
  /// 词库缩略图与块缩略图同管线产出，直接复制避免 472 张图在主
  /// isolate 里逐张解码重编码（首次打开块库卡顿），且像素零损失。
  /// 文件名取 `<blockId><源扩展名>`，重试幂等覆盖。源文件缺失返回
  /// null；复制失败退回原路径（退役清理不删磁盘目录故不会断图）。
  static Future<String?> _importThumbnailFile(
    String sourcePath,
    String blockId,
  ) async {
    final source = File(sourcePath);
    if (!await source.exists()) return null;
    try {
      final dir = await promptBlockThumbnailDirectory();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final ext = p.extension(sourcePath);
      final target = File(p.join(dir.path, '$blockId$ext'));
      await source.copy(target.path);
      return target.path;
    } catch (_) {
      return sourcePath;
    }
  }

  static int _maxFolderOrder(
    List<PromptBlockFolder> folders,
    String? parentId,
  ) {
    var maximum = -1;
    for (final folder in folders.where((f) => f.parentId == parentId)) {
      if (folder.sortOrder > maximum) maximum = folder.sortOrder;
    }
    return maximum;
  }

  static int _maxBlockOrder(List<PromptBlock> blocks, String? folderId) {
    var maximum = -1;
    for (final block in blocks.where((b) => b.folderId == folderId)) {
      if (block.sortOrder > maximum) maximum = block.sortOrder;
    }
    return maximum;
  }

  static String _titleFromContent(String content) {
    if (content.length > 20) return '${content.substring(0, 20)}...';
    return content.isEmpty ? '未命名' : content;
  }
}

/// 旧词库条目解码记录（仅迁移所需字段；`tags`/`lastUsedAt` 按口径丢弃）。
class _LegacyEntry {
  const _LegacyEntry({
    required this.id,
    required this.name,
    required this.content,
    required this.thumbnail,
    required this.thumbnailOffsetX,
    required this.thumbnailOffsetY,
    required this.thumbnailScale,
    required this.categoryId,
    required this.sortOrder,
    required this.useCount,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String content;
  final String? thumbnail;
  final double thumbnailOffsetX;
  final double thumbnailOffsetY;
  final double thumbnailScale;
  final String? categoryId;
  final int sortOrder;
  final int useCount;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory _LegacyEntry.fromJson(Map<String, dynamic> json) => _LegacyEntry(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    content: json['content'] as String? ?? '',
    thumbnail: json['thumbnail'] as String?,
    thumbnailOffsetX: (json['thumbnailOffsetX'] as num?)?.toDouble() ?? 0.0,
    thumbnailOffsetY: (json['thumbnailOffsetY'] as num?)?.toDouble() ?? 0.0,
    thumbnailScale: (json['thumbnailScale'] as num?)?.toDouble() ?? 1.0,
    categoryId: json['categoryId'] as String?,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    useCount: (json['useCount'] as num?)?.toInt() ?? 0,
    isFavorite: json['isFavorite'] as bool? ?? false,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

/// 旧词库分类解码记录（仅迁移所需字段）。
class _LegacyCategory {
  const _LegacyCategory({
    required this.id,
    required this.name,
    required this.parentId,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? parentId;
  final int sortOrder;
  final DateTime createdAt;

  factory _LegacyCategory.fromJson(Map<String, dynamic> json) =>
      _LegacyCategory(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        parentId: json['parentId'] as String?,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
