import 'dart:convert';

import 'package:hive/hive.dart';

import '../constants/storage_keys.dart';
import 'base_hive_storage.dart';
import '../utils/app_logger.dart';
import '../utils/hive_startup_box_opener.dart';
import '../../data/models/style_explore/explore_run.dart';
import '../../data/models/style_explore/explore_candidate_deletion.dart';

/// 画风探索 Run 的 Hive 存储层。
///
/// 与 Recipe 一致：字符串 JSON、稳定 key 分条保存、损坏记录跳过降级。
class StyleExploreRunStorage {
  static const String boxName = StorageKeys.styleExploreRunsBox;
  static const String schemaKey = 'meta:schema';
  static const int schemaVersion = 1;

  static const String _runPrefix = 'run:';

  StyleExploreRunStorage({String? hivePath}) : _hivePath = hivePath;

  final String? _hivePath;
  Box<String>? _box;
  Future<void>? _initFuture;

  /// 确保 Run Box 和 schema 已就绪。
  Future<void> init() async {
    await _getBox();
  }

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
      // _ensureSchema 在初始化时修复损坏的 schema。
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
        'Invalid style explore run schema; rebuilding schema metadata',
        'StyleExploreRunStorage',
      );
      await _writeSchema(box);
      return;
    }

    if (storedVersion > schemaVersion) {
      throw HiveStorageException(
        'Style explore run schema $storedVersion is newer than supported $schemaVersion',
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

  /// 读取全部 Run，按更新时间新→旧排列；单条损坏记录跳过。
  Future<List<ExploreRun>> getRuns() async {
    final box = await _getBox();
    final runs = <ExploreRun>[];
    for (final key in _keysWithPrefix(box, _runPrefix)) {
      final run = _readEntity(box, key, ExploreRun.fromJson);
      if (run != null) runs.add(_normalizeLegacyStatus(run));
    }
    runs.sort((a, b) {
      final comparison = b.updatedAt.compareTo(a.updatedAt);
      if (comparison != 0) return comparison;
      return a.id.compareTo(b.id);
    });
    return runs;
  }

  /// 读取单个 Run。
  Future<ExploreRun?> getRun(String id) async {
    final box = await _getBox();
    final run = _readEntity(box, runKey(id), ExploreRun.fromJson);
    return run == null ? null : _normalizeLegacyStatus(run);
  }

  /// 存量 `reviewing` 归一化为 `generated`（评审体系已整层拆除，
  /// 枚举值仅为反序列化兼容保留；读到即转，下次落盘自愈）。
  static ExploreRun _normalizeLegacyStatus(ExploreRun run) =>
      run.status == ExploreRunStatus.reviewing
      ? run.copyWith(status: ExploreRunStatus.generated)
      : run;

  ExploreRun? currentRun(String id) {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('Explore storage is closed');
    }
    final run = _readEntity(box, runKey(id), ExploreRun.fromJson);
    return run == null ? null : _normalizeLegacyStatus(run);
  }

  /// 保存或覆盖单个 Run。
  Future<void> putRun(ExploreRun run, {void Function()? beforeWrite}) async {
    final box = await _getBox();
    beforeWrite?.call();
    await box.put(runKey(run.id), jsonEncode(run.toJson()));
  }

  /// Latest comparison and Hive index update have no asynchronous gap.
  Future<ExploreRun> transformRun(
    String id,
    ExploreRun Function(ExploreRun) update,
  ) async {
    final box = await _getBox();
    final current = _readEntity(box, runKey(id), ExploreRun.fromJson);
    if (current == null) throw StateError('Explore run does not exist');
    final next = update(_normalizeLegacyStatus(current));
    if (next.id != id) throw StateError('Explore identity cannot change');
    await box.put(runKey(id), jsonEncode(next.toJson()));
    return next;
  }

  /// 删除单个 Run；不存在时保持幂等。
  Future<void> deleteRun(String id) async {
    final box = await _getBox();
    await box.delete(runKey(id));
  }

  /// 清空全部 Run 并重写 schema。仅供测试使用。
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

  Future<List<ExploreCandidateDeletion>> getCandidateDeletions() async {
    final box = await _getBox();
    final result = <ExploreCandidateDeletion>[];
    for (final key in _keysWithPrefix(box, 'undo:')) {
      final deletion = _readEntity(box, key, ExploreCandidateDeletion.fromJson);
      if (deletion != null) result.add(deletion);
    }
    return result..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> putCandidateDeletion(ExploreCandidateDeletion deletion) async {
    await (await _getBox()).put(
      'undo:${deletion.id}',
      jsonEncode(deletion.toJson()),
    );
  }

  Future<void> deleteCandidateDeletion(String id) async {
    await (await _getBox()).delete('undo:$id');
  }

  static String runKey(String id) => '$_runPrefix$id';

  Iterable<String> _keysWithPrefix(Box<String> box, String prefix) {
    return box.keys.whereType<String>().where((key) => key.startsWith(prefix));
  }

  T? _readEntity<T>(
    Box<String> box,
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
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
        'Skipping corrupt style explore run record $key: $error',
        'StyleExploreRunStorage',
      );
      return null;
    }
  }
}
