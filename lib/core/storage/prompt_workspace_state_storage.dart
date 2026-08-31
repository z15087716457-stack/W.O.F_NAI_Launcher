import 'dart:convert';

import 'package:hive/hive.dart';

import '../../data/models/prompt_block/prompt_block_document.dart';
import '../constants/storage_keys.dart';
import '../utils/app_logger.dart';

/// 一份已持久化的工作区文档对。
class PromptWorkspaceSnapshot {
  const PromptWorkspaceSnapshot({
    required this.positiveDocument,
    required this.negativeDocument,
  });

  final PromptBlockDocument positiveDocument;
  final PromptBlockDocument negativeDocument;
}

/// Prompt 块工作区的 Hive 持久化层。
///
/// 每个工作区实例（生成页、画风探索页）按 scope key 保存正负两份文档的
/// JSON 快照。Box 未打开时读写都安全跳过，因此测试环境无需准备 Hive。
class PromptWorkspaceStateStorage {
  static const String boxName = StorageKeys.promptWorkspaceStateBox;
  static const String schemaKey = 'meta:schema';
  static const int schemaVersion = 1;

  static const String _workspacePrefix = 'workspace:';

  final String? _hivePath;
  Box<String>? _box;
  Future<void>? _initFuture;

  PromptWorkspaceStateStorage({String? hivePath}) : _hivePath = hivePath;

  /// 确保 Box 和 schema 已就绪（由启动预开流程调用）。
  Future<void> init() async {
    await _getBox();
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

    if (_box?.isOpen != true) {
      if (identical(_initFuture, future)) {
        _initFuture = null;
      }
      return _getBox();
    }
    return _box!;
  }

  Future<void> _initialize() async {
    await _tryOpenBox();
    if (_box?.isOpen == true) {
      await _ensureSchema(_box!);
    }
  }

  /// Box 由启动流程预开；这里仅在尚未打开时兜底打开一次。
  Future<void> _tryOpenBox() async {
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box<String>(boxName);
      return;
    }
    try {
      _box = await Hive.openBox<String>(boxName, path: _hivePath);
    } catch (error, stackTrace) {
      AppLogger.e(
        'Failed to open prompt workspace state box; persistence disabled',
        error,
        stackTrace,
        'PromptWorkspaceStateStorage',
      );
      _box = null;
    }
  }

  Future<void> _ensureSchema(Box<String> box) async {
    final raw = box.get(schemaKey);
    if (raw == null) {
      await _writeSchema(box);
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['schemaVersion'] is int) return;
    } catch (_) {
      // 解析失败时重写 schema 元数据，实体记录不受影响。
    }
    await _writeSchema(box);
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

  /// 同步读取指定 scope 的持久化快照。
  ///
  /// Box 尚未打开（测试环境或启动极早期）或记录损坏时返回 null，
  /// 调用方回退到空文档。
  PromptWorkspaceSnapshot? tryLoadSync(String scope) {
    if (!Hive.isBoxOpen(boxName)) return null;
    final box = Hive.box<String>(boxName);
    final raw = box.get(_workspaceKey(scope));
    if (raw is! String || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final positive = _decodeDocument(decoded['positive']);
      final negative = _decodeDocument(decoded['negative']);
      if (positive == null || negative == null) return null;
      return PromptWorkspaceSnapshot(
        positiveDocument: positive,
        negativeDocument: negative,
      );
    } catch (error) {
      AppLogger.w(
        'Skipping corrupt prompt workspace record "$scope": $error',
        'PromptWorkspaceStateStorage',
      );
      return null;
    }
  }

  /// 持久化指定 scope 的工作区快照；Box 未打开时静默跳过。
  Future<void> persist(String scope, PromptWorkspaceSnapshot snapshot) async {
    if (!Hive.isBoxOpen(boxName)) return;
    final box = Hive.box<String>(boxName);
    await box.put(
      _workspaceKey(scope),
      jsonEncode({
        'schemaVersion': schemaVersion,
        'positive': snapshot.positiveDocument.toJson(),
        'negative': snapshot.negativeDocument.toJson(),
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// 清空全部工作区记录并重写 schema。仅供测试使用。
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

  static String _workspaceKey(String scope) => '$_workspacePrefix$scope';

  PromptBlockDocument? _decodeDocument(Object? json) {
    if (json is! Map) return null;
    return PromptBlockDocument.fromJson(Map<String, dynamic>.from(json));
  }
}
