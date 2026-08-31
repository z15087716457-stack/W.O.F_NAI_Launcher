import 'dart:convert';

import 'package:hive/hive.dart';

import '../constants/storage_keys.dart';
import 'base_hive_storage.dart';
import '../utils/app_logger.dart';
import '../utils/hive_startup_box_opener.dart';
import '../../data/models/style_explore/style_explore_recipe.dart';

/// 画风探索 Recipe 的 Hive 存储层。
///
/// 与块库一致：字符串 JSON、稳定 key 分条保存、损坏记录跳过降级。
class StyleExploreRecipeStorage {
  static const String boxName = StorageKeys.styleExploreRecipesBox;
  static const String schemaKey = 'meta:schema';
  static const int schemaVersion = 1;

  static const String _recipePrefix = 'recipe:';

  StyleExploreRecipeStorage({String? hivePath}) : _hivePath = hivePath;

  final String? _hivePath;
  Box<String>? _box;
  Future<void>? _initFuture;

  /// 确保 Recipe Box 和 schema 已就绪。
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
        'Invalid style explore recipe schema; rebuilding schema metadata',
        'StyleExploreRecipeStorage',
      );
      await _writeSchema(box);
      return;
    }

    if (storedVersion > schemaVersion) {
      throw HiveStorageException(
        'Style explore recipe schema $storedVersion is newer than supported $schemaVersion',
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

  /// 读取全部 Recipe，按更新时间新→旧排列；单条损坏记录跳过。
  Future<List<StyleExploreRecipe>> getRecipes() async {
    final box = await _getBox();
    final recipes = <StyleExploreRecipe>[];
    for (final key in _keysWithPrefix(box, _recipePrefix)) {
      final recipe = await _readEntity(box, key, StyleExploreRecipe.fromJson);
      if (recipe != null) recipes.add(recipe);
    }
    recipes.sort((a, b) {
      final comparison = b.updatedAt.compareTo(a.updatedAt);
      if (comparison != 0) return comparison;
      return a.id.compareTo(b.id);
    });
    return recipes;
  }

  /// 读取单个 Recipe。
  Future<StyleExploreRecipe?> getRecipe(String id) async {
    final box = await _getBox();
    return _readEntity(box, recipeKey(id), StyleExploreRecipe.fromJson);
  }

  /// 保存或覆盖单个 Recipe。
  Future<void> putRecipe(StyleExploreRecipe recipe) async {
    final box = await _getBox();
    await box.put(recipeKey(recipe.id), jsonEncode(recipe.toJson()));
  }

  /// 删除单个 Recipe；不存在时保持幂等。
  Future<void> deleteRecipe(String id) async {
    final box = await _getBox();
    await box.delete(recipeKey(id));
  }

  /// 清空全部 Recipe 并重写 schema。仅供测试使用。
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

  static String recipeKey(String id) => '$_recipePrefix$id';

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
        'Skipping corrupt style explore recipe record $key: $error',
        'StyleExploreRecipeStorage',
      );
      return null;
    }
  }
}
