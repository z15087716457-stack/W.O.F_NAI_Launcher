import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';

import '../constants/storage_keys.dart';
import 'base_hive_storage.dart';
import '../utils/app_logger.dart';
import '../utils/hive_startup_box_opener.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/models/prompt_block/prompt_block_collection.dart';
import '../../data/models/prompt_block/prompt_block_folder.dart';

/// 全局 Prompt 块库的 Hive 存储层。
///
/// 使用字符串 JSON 保存，避免为公共块引入 Hive TypeAdapter 和 typeId
/// 占用；实体通过稳定 key 分开保存，便于后续版本迁移和损坏记录降级。
class PromptBlockStorage {
  static const String boxName = StorageKeys.promptBlockLibraryBox;
  static const String schemaKey = 'meta:schema';
  static const int schemaVersion = 1;

  static const String _blockPrefix = 'block:';
  static const String _folderPrefix = 'folder:';
  static const String _collectionPrefix = 'collection:';
  static const String _metaPrefix = 'meta:';
  static const String _paletteKey = 'palette:order';

  PromptBlockStorage({String? hivePath}) : _hivePath = hivePath;

  final String? _hivePath;
  Box<String>? _box;
  Future<void>? _initFuture;
  Future<void> _paletteMutation = Future.value();

  /// 确保块库 Box 和 schema 已就绪。
  Future<void> init() async {
    await _getBox();
  }

  /// 读取当前 schema 版本。
  Future<int> getSchemaVersion() async {
    final box = await _getBox();
    final raw = box.get(schemaKey);
    if (raw is! String || raw.isEmpty) return schemaVersion;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['schemaVersion'] is int) {
        return decoded['schemaVersion'] as int;
      }
    } catch (_) {
      // _ensureSchema 已经会在初始化时修复损坏的 schema。
    }
    return schemaVersion;
  }

  Future<Box<String>> _getBox() async {
    if (_box?.isOpen == true) return _box!;

    final future = _initFuture ??= _initialize();
    try {
      await future;
    } catch (_) {
      if (identical(_initFuture, future)) {
        _initFuture = null;
      }
      rethrow;
    }

    // close() 可能发生在上一次初始化完成之后；此时重新打开。
    if (_box?.isOpen != true) {
      if (identical(_initFuture, future)) {
        _initFuture = null;
      }
      return _getBox();
    }
    return _box!;
  }

  Future<void> _initialize() async {
    await HiveStartupBoxOpener.openBox<String>(boxName, hivePath: _hivePath);
    _box = Hive.box<String>(boxName);
    await _ensureSchema(_box!);
  }

  Future<void> _ensureSchema(Box<String> box) async {
    final raw = box.get(schemaKey);
    if (raw == null) {
      await _writeSchema(box);
      return;
    }

    int? storedVersion;
    try {
      if (raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['schemaVersion'] is int) {
          storedVersion = decoded['schemaVersion'] as int;
        }
      }
    } catch (_) {
      storedVersion = null;
    }

    if (storedVersion == null) {
      AppLogger.w(
        'Invalid Prompt block library schema; rebuilding schema metadata',
        'PromptBlockStorage',
      );
      await _writeSchema(box);
      return;
    }

    if (storedVersion > schemaVersion) {
      throw HiveStorageException(
        'Prompt block library schema $storedVersion is newer than supported $schemaVersion',
      );
    }

    if (storedVersion < schemaVersion) {
      // 当前只有 v1；保留实体内容，仅升级 schema 元数据。
      await _writeSchema(box);
    }
  }

  Future<void> _writeSchema(Box<String> box) async {
    await box.put(
      schemaKey,
      jsonEncode({
        'schemaVersion': schemaVersion,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// 读取全部块；单条损坏记录会被跳过，不影响其他块。
  Future<List<PromptBlock>> getBlocks() async {
    final box = await _getBox();
    final blocks = <PromptBlock>[];
    for (final key in _keysWithPrefix(box, _blockPrefix)) {
      final block = _readEntity(box, key, PromptBlock.fromJson);
      if (block != null) blocks.add(block);
    }
    blocks.sort(_comparePromptBlocks);
    return blocks;
  }

  /// 读取单个块。
  Future<PromptBlock?> getBlock(String id) async {
    final box = await _getBox();
    return _readEntity(box, blockKey(id), PromptBlock.fromJson);
  }

  /// 保存或覆盖单个块。
  Future<void> putBlock(PromptBlock block) async {
    final box = await _getBox();
    await box.put(blockKey(block.id), jsonEncode(block.toJson()));
  }

  /// The callback sees the latest Hive value after opening has completed.
  /// Comparison and the synchronous Hive index update have no await between
  /// them; callers can protect an externally prepared edit without a stale put.
  Future<PromptBlock?> transformBlock(
    String id,
    PromptBlock? Function(PromptBlock?) transform,
  ) async {
    final box = await _getBox();
    final current = _readEntity(box, blockKey(id), PromptBlock.fromJson);
    final next = transform(current);
    if (identical(next, current)) return current;
    if (next == null) {
      await box.delete(blockKey(id));
    } else {
      if (next.id != id) throw StateError('Block identity cannot change');
      if (next.folderId != null &&
          _readEntity(
                box,
                folderKey(next.folderId!),
                PromptBlockFolder.fromJson,
              ) ==
              null) {
        throw StateError(
          'Prompt block folder does not exist: ${next.folderId}',
        );
      }
      await box.put(blockKey(id), jsonEncode(next.toJson()));
    }
    return next;
  }

  Future<PromptBlockCollection?> transformCollection(
    String id,
    PromptBlockCollection? Function(PromptBlockCollection?) transform,
  ) async {
    final box = await _getBox();
    final current = _readEntity(
      box,
      collectionKey(id),
      PromptBlockCollection.fromJson,
    );
    final next = transform(current);
    if (identical(next, current)) return current;
    if (next == null) {
      await box.delete(collectionKey(id));
    } else {
      if (next.id != id) throw StateError('Collection identity cannot change');
      await box.put(collectionKey(id), jsonEncode(next.toJson()));
    }
    return next;
  }

  /// Synchronous latest snapshot for a guarded write after initialization.
  ({
    List<PromptBlock> blocks,
    List<PromptBlockFolder> folders,
    List<PromptBlockCollection> collections,
  })
  get currentLibrary {
    final box = _box;
    if (box == null || !box.isOpen) throw StateError('Block storage is closed');
    return (
      blocks: [
        for (final key in _keysWithPrefix(box, _blockPrefix))
          if (_readEntity(box, key, PromptBlock.fromJson) case final value?)
            value,
      ],
      folders: [
        for (final key in _keysWithPrefix(box, _folderPrefix))
          if (_readEntity(box, key, PromptBlockFolder.fromJson)
              case final value?)
            value,
      ],
      collections: [
        for (final key in _keysWithPrefix(box, _collectionPrefix))
          if (_readEntity(box, key, PromptBlockCollection.fromJson)
              case final value?)
            value,
      ],
    );
  }

  /// Membership and the native favorite flag are committed together.
  Future<void> setCollectionMembership(
    String collectionId,
    String blockId,
    bool member, {
    void Function()? beforeWrite,
  }) async {
    final box = await _getBox();
    beforeWrite?.call();
    final collection = _readEntity(
      box,
      collectionKey(collectionId),
      PromptBlockCollection.fromJson,
    );
    final block = _readEntity(box, blockKey(blockId), PromptBlock.fromJson);
    if (collection == null || collection.isFolder || block == null) {
      throw StateError('Collection or block does not exist');
    }
    final ids = [...collection.blockIds]..removeWhere((id) => id == blockId);
    if (member) ids.add(blockId);
    final now = DateTime.now();
    await box.putAll({
      collectionKey(collectionId): jsonEncode(
        collection.copyWith(blockIds: ids, updatedAt: now).toJson(),
      ),
      if (member && !block.isFavorite)
        blockKey(blockId): jsonEncode(
          block.copyWith(isFavorite: true, updatedAt: now).toJson(),
        ),
    });
  }

  /// 批量保存块。
  Future<void> putBlocks(
    Iterable<PromptBlock> blocks, {
    void Function()? beforeWrite,
  }) async {
    final box = await _getBox();
    beforeWrite?.call();
    final values = <String, String>{
      for (final block in blocks)
        blockKey(block.id): jsonEncode(block.toJson()),
    };
    if (values.isNotEmpty) await box.putAll(values);
  }

  /// 删除单个块；不存在时保持幂等。
  Future<void> deleteBlock(String id) async {
    final box = await _getBox();
    await box.delete(blockKey(id));
  }

  /// 批量删除块。
  Future<void> deleteBlocks(Iterable<String> ids) async {
    final box = await _getBox();
    final keys = ids.map(blockKey).toList();
    if (keys.isNotEmpty) await box.deleteAll(keys);
  }

  /// 读取全部文件夹；单条损坏记录会被跳过。
  Future<List<PromptBlockFolder>> getFolders() async {
    final box = await _getBox();
    final folders = <PromptBlockFolder>[];
    for (final key in _keysWithPrefix(box, _folderPrefix)) {
      final folder = _readEntity(box, key, PromptBlockFolder.fromJson);
      if (folder != null) folders.add(folder);
    }
    folders.sort(_comparePromptBlockFolders);
    return folders;
  }

  /// 读取单个文件夹。
  Future<PromptBlockFolder?> getFolder(String id) async {
    final box = await _getBox();
    return _readEntity(box, folderKey(id), PromptBlockFolder.fromJson);
  }

  /// 保存或覆盖单个文件夹。
  Future<void> putFolder(
    PromptBlockFolder folder, {
    void Function()? beforeWrite,
  }) async {
    final box = await _getBox();
    beforeWrite?.call();
    await box.put(folderKey(folder.id), jsonEncode(folder.toJson()));
  }

  /// 批量保存文件夹。
  Future<void> putFolders(
    Iterable<PromptBlockFolder> folders, {
    void Function()? beforeWrite,
  }) async {
    final box = await _getBox();
    beforeWrite?.call();
    final values = <String, String>{
      for (final folder in folders)
        folderKey(folder.id): jsonEncode(folder.toJson()),
    };
    if (values.isNotEmpty) await box.putAll(values);
  }

  /// 删除单个文件夹；不存在时保持幂等。
  Future<void> deleteFolder(String id, {void Function()? beforeWrite}) async {
    final box = await _getBox();
    beforeWrite?.call();
    await box.delete(folderKey(id));
  }

  /// 批量删除文件夹。
  Future<void> deleteFolders(Iterable<String> ids) async {
    final box = await _getBox();
    final keys = ids.map(folderKey).toList();
    if (keys.isNotEmpty) await box.deleteAll(keys);
  }

  /// 读取全部收藏集 / 收藏文件夹；单条损坏记录会被跳过。
  Future<List<PromptBlockCollection>> getCollections() async {
    final box = await _getBox();
    final collections = <PromptBlockCollection>[];
    for (final key in _keysWithPrefix(box, _collectionPrefix)) {
      final collection = _readEntity(box, key, PromptBlockCollection.fromJson);
      if (collection != null) collections.add(collection);
    }
    collections.sort(_comparePromptBlockCollections);
    return collections;
  }

  /// 读取单个收藏集 / 收藏文件夹。
  Future<PromptBlockCollection?> getCollection(String id) async {
    final box = await _getBox();
    return _readEntity(box, collectionKey(id), PromptBlockCollection.fromJson);
  }

  /// 保存或覆盖单个收藏集 / 收藏文件夹。
  Future<void> putCollection(
    PromptBlockCollection collection, {
    void Function()? beforeWrite,
  }) async {
    final box = await _getBox();
    beforeWrite?.call();
    await box.put(
      collectionKey(collection.id),
      jsonEncode(collection.toJson()),
    );
  }

  /// 批量保存收藏集 / 收藏文件夹。
  Future<void> putCollections(
    Iterable<PromptBlockCollection> collections, {
    void Function()? beforeWrite,
  }) async {
    final box = await _getBox();
    beforeWrite?.call();
    final values = <String, String>{
      for (final collection in collections)
        collectionKey(collection.id): jsonEncode(collection.toJson()),
    };
    if (values.isNotEmpty) await box.putAll(values);
  }

  /// 删除单个收藏集 / 收藏文件夹；不存在时保持幂等。
  Future<void> deleteCollection(String id) async {
    final box = await _getBox();
    await box.delete(collectionKey(id));
  }

  /// 批量删除收藏集 / 收藏文件夹。
  Future<void> deleteCollections(
    Iterable<String> ids, {
    void Function()? beforeWrite,
  }) async {
    final box = await _getBox();
    beforeWrite?.call();
    final keys = ids.map(collectionKey).toList();
    if (keys.isNotEmpty) await box.deleteAll(keys);
  }

  /// 清空块库并重新写入 schema。仅供明确的库级清理或测试使用。
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
    await _writeSchema(box);
  }

  /// 读取颜料版块 ID 列表（用户排序序）。
  Future<List<String>> getPaletteBlockIds() async {
    final box = await _getBox();
    final raw = box.get(_paletteKey);
    if (raw is! String || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['blockIds'] is List) {
        return (decoded['blockIds'] as List).whereType<String>().toList();
      }
    } catch (_) {
      // 损坏记录按空板处理，下次写入自愈。
    }
    return const [];
  }

  /// 覆盖写入颜料版块 ID 列表。
  Future<void> putPaletteBlockIds(List<String> ids) async {
    final box = await _getBox();
    await box.put(
      _paletteKey,
      jsonEncode({
        'blockIds': ids,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// 颜料版的读取、变换和写入按调用顺序完成，避免并发操作覆盖彼此。
  /// [transform] 返回 null 表示无变更；写入错误由当前调用者处理。
  Future<bool> updatePaletteBlockIds(
    List<String>? Function(List<String> ids) transform,
  ) async {
    final previous = _paletteMutation;
    final finished = Completer<void>();
    _paletteMutation = finished.future;
    try {
      await previous;
      final next = transform(await getPaletteBlockIds());
      if (next == null) return false;
      await putPaletteBlockIds(next);
      return true;
    } finally {
      finished.complete();
    }
  }

  /// 读取块库级 meta 键（迁移标记等一次性旗标）。
  Future<String?> getMeta(String name) async {
    final box = await _getBox();
    final raw = box.get('$_metaPrefix$name');
    return raw is String ? raw : null;
  }

  /// 写入块库级 meta 键。
  Future<void> putMeta(String name, String value) async {
    final box = await _getBox();
    await box.put('$_metaPrefix$name', value);
  }

  /// 关闭本存储使用的 Box。
  Future<void> close() async {
    if (_box?.isOpen == true) await _box!.close();
    _box = null;
    _initFuture = null;
  }

  static String blockKey(String id) => '$_blockPrefix$id';
  static String folderKey(String id) => '$_folderPrefix$id';
  static String collectionKey(String id) => '$_collectionPrefix$id';

  Iterable<String> _keysWithPrefix(Box<String> box, String prefix) {
    return box.keys.whereType<String>().where((key) => key.startsWith(prefix));
  }

  T? _readEntity<T>(
    Box<String> box,
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final raw = box.get(key);
    if (raw == null) return null;
    try {
      if (raw.isEmpty) {
        throw const FormatException('entity is not a JSON string');
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('entity JSON is not an object');
      }
      return fromJson(Map<String, dynamic>.from(decoded));
    } catch (error) {
      AppLogger.w(
        'Skipping corrupt Prompt block library record $key: $error',
        'PromptBlockStorage',
      );
      return null;
    }
  }
}

int _comparePromptBlocks(PromptBlock a, PromptBlock b) {
  final folderComparison = _compareNullableStrings(a.folderId, b.folderId);
  if (folderComparison != 0) return folderComparison;

  final orderComparison = a.sortOrder.compareTo(b.sortOrder);
  if (orderComparison != 0) return orderComparison;
  return a.id.compareTo(b.id);
}

int _comparePromptBlockFolders(PromptBlockFolder a, PromptBlockFolder b) {
  final parentComparison = _compareNullableStrings(a.parentId, b.parentId);
  if (parentComparison != 0) return parentComparison;

  final orderComparison = a.sortOrder.compareTo(b.sortOrder);
  if (orderComparison != 0) return orderComparison;
  return a.id.compareTo(b.id);
}

int _comparePromptBlockCollections(
  PromptBlockCollection a,
  PromptBlockCollection b,
) {
  final parentComparison = _compareNullableStrings(a.parentId, b.parentId);
  if (parentComparison != 0) return parentComparison;

  final orderComparison = a.sortOrder.compareTo(b.sortOrder);
  if (orderComparison != 0) return orderComparison;
  return a.id.compareTo(b.id);
}

int _compareNullableStrings(String? a, String? b) {
  if (a == b) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  return a.compareTo(b);
}
