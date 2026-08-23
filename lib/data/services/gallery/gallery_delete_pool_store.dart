import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';

/// 本地画廊删除池的 SharedPreferences 持久化。
///
/// 删除动作不再物理删文件：DB 立即软删标记（is_deleted=1）+ 路径入池，
/// 图从内存列表即时消失；实际文件在下次启动时由启动清理步骤逐条物理删除。
///
/// 池只是 DB 软删标记的「磁盘延迟」——会话内一切以 DB is_deleted 为准
/// （文件列表/扫描器都按 DB 排除），池只负责让启动清理知道删哪些文件。
///
/// 独立小类以便单元测试（测试用 `SharedPreferences.setMockInitialValues`）。
class GalleryDeletePoolStore {
  const GalleryDeletePoolStore();

  /// 读取删除池路径列表；无记录或解析失败时返回空表。
  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.galleryDeletePool);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList(growable: false);
      }
    } catch (_) {
      // 数据损坏按空池处理，避免启动清理失败
    }
    return const [];
  }

  /// 追加路径（按原样去重合并，不归一化——删除/撤销按同一串路径往返）。
  Future<void> addAll(List<String> paths) async {
    if (paths.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final seen = <String>{...current};
    final merged = List<String>.of(current);
    for (final path in paths) {
      if (seen.add(path)) merged.add(path);
    }
    await prefs.setString(StorageKeys.galleryDeletePool, jsonEncode(merged));
  }

  /// 移除路径（幂等；路径不在池中时无操作）。
  Future<void> removeAll(List<String> paths) async {
    if (paths.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    if (current.isEmpty) return;
    final removed = <String>{...paths};
    final remaining = current
        .where((path) => !removed.contains(path))
        .toList(growable: false);
    await prefs.setString(StorageKeys.galleryDeletePool, jsonEncode(remaining));
  }

  /// 清空删除池（物理文件不受影响）。
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.galleryDeletePool);
  }

  /// 启动清理：逐条物理删除池内文件。
  ///
  /// - 文件不存在 = 成功（目标已消失，无需删除）
  /// - 删除失败（如文件被占用/权限不足）= 保留在池中，下次启动再试
  /// - 成功的路径从池中移除
  ///
  /// 返回本次成功清理的文件数。
  Future<int> cleanupPendingFiles() async {
    final paths = await load();
    if (paths.isEmpty) return 0;

    var deletedCount = 0;
    final remaining = <String>[];
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
        deletedCount++;
      } catch (e) {
        remaining.add(path);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    if (remaining.isEmpty) {
      await prefs.remove(StorageKeys.galleryDeletePool);
    } else {
      await prefs.setString(
        StorageKeys.galleryDeletePool,
        jsonEncode(remaining),
      );
    }
    return deletedCount;
  }
}
