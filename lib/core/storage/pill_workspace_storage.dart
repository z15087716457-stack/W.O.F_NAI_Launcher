import 'dart:convert';

import 'package:hive/hive.dart';

import '../../data/models/prompt_block/pill_document.dart';
import '../constants/storage_keys.dart';
import '../utils/app_logger.dart';

/// 药丸工作区的 Hive 持久化层（P0 原型）。
///
/// 与 `PromptWorkspaceStateStorage` 共用同一个 Box、按 key 前缀隔离；
/// Box 未打开时读写都安全跳过，测试环境无需准备 Hive。
class PillWorkspaceStorage {
  static const String boxName = StorageKeys.promptWorkspaceStateBox;
  static const int schemaVersion = 1;

  static const String _pillPrefix = 'pillworkspace:';

  /// 同步读取指定 scope 的药丸文档；未打开/损坏时返回 null。
  PillDocument? tryLoadSync(String scope) {
    if (!Hive.isBoxOpen(boxName)) return null;
    final box = Hive.box<String>(boxName);
    final raw = box.get(_key(scope));
    if (raw is! String || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return PillDocument.fromJson(Map<String, dynamic>.from(decoded));
    } catch (error) {
      AppLogger.w(
        'Skipping corrupt pill workspace record "$scope": $error',
        'PillWorkspaceStorage',
      );
      return null;
    }
  }

  /// 持久化指定 scope 的文档；Box 未打开时静默跳过。
  Future<void> persist(String scope, PillDocument document) async {
    if (!Hive.isBoxOpen(boxName)) return;
    final box = Hive.box<String>(boxName);
    await box.put(
      _key(scope),
      jsonEncode({
        'schemaVersion': schemaVersion,
        ...document.toJson(),
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// 删除指定 scope 的存档（如角色被删除时清理其正/负 lane）。
  Future<void> deleteScope(String scope) async {
    if (!Hive.isBoxOpen(boxName)) return;
    await Hive.box<String>(boxName).delete(_key(scope));
  }

  static String _key(String scope) => '$_pillPrefix$scope';
}
