import 'dart:convert';

import 'package:hive/hive.dart';

import '../constants/storage_keys.dart';
import 'base_hive_storage.dart';
import '../utils/app_logger.dart';
import '../utils/hive_startup_box_opener.dart';
import '../../data/models/prompt_block/prompt_block.dart';
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

  PromptBlockStorage({String? hivePath}) : _hivePath = hivePath;

  final String? _hivePath;
  Box<String>? _box;
  Future<void>? _initFuture;

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
      final block = await _readEntity(box, key, PromptBlock.fromJson);
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

  /// 批量保存块。
  Future<void> putBlocks(Iterable<PromptBlock> blocks) async {
    final box = await _getBox();
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
      final folder = await _readEntity(box, key, PromptBlockFolder.fromJson);
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
  Future<void> putFolder(PromptBlockFolder folder) async {
    final box = await _getBox();
    await box.put(folderKey(folder.id), jsonEncode(folder.toJson()));
  }

  /// 批量保存文件夹。
  Future<void> putFolders(Iterable<PromptBlockFolder> folders) async {
    final box = await _getBox();
    final values = <String, String>{
      for (final folder in folders)
        folderKey(folder.id): jsonEncode(folder.toJson()),
    };
    if (values.isNotEmpty) await box.putAll(values);
  }

  /// 删除单个文件夹；不存在时保持幂等。
  Future<void> deleteFolder(String id) async {
    final box = await _getBox();
    await box.delete(folderKey(id));
  }

  /// 批量删除文件夹。
  Future<void> deleteFolders(Iterable<String> ids) async {
    final box = await _getBox();
    final keys = ids.map(folderKey).toList();
    if (keys.isNotEmpty) await box.deleteAll(keys);
  }

  /// 清空块库并重新写入 schema。仅供明确的库级清理或测试使用。
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
    await _writeSchema(box);
  }

  /// 关闭本存储使用的 Box。
  Future<void> close() async {
    if (_box?.isOpen == true) await _box!.close();
    _box = null;
    _initFuture = null;
  }

  static String blockKey(String id) => '$_blockPrefix$id';
  static String folderKey(String id) => '$_folderPrefix$id';

  Iterable<String> _keysWithPrefix(Box<String> box, String prefix) {
    return box.keys.whereType<String>().where((key) => key.startsWith(prefix));
  }

  Future<T?> _readEntity<T>(
    Box<String> box,
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final raw = box.get(key);
    try {
      if (raw is! String || raw.isEmpty) {
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

int _compareNullableStrings(String? a, String? b) {
  if (a == b) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  return a.compareTo(b);
}
