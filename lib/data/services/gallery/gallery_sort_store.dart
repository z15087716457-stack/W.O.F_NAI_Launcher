import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import 'gallery_sort.dart';

/// 本地画廊排序的 SharedPreferences 持久化（字段 + 方向两个值）。
///
/// 枚举用 `name` 字符串序列化（改名需迁移）。无记录时返回 null，
/// 调用方沿用默认排序（修改时间 新→旧）。独立小类以便单元测试
/// （测试用 `SharedPreferences.setMockInitialValues`）。
class GallerySortStore {
  const GallerySortStore();

  /// 读取持久化的排序；无记录或枚举名非法时返回 null（调用方用默认）。
  Future<GallerySort?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final fieldName = prefs.getString(StorageKeys.localGallerySortField);
    final directionName = prefs.getString(
      StorageKeys.localGallerySortDirection,
    );
    if (fieldName == null || directionName == null) return null;

    final field = GallerySortField.values
        .where((value) => value.name == fieldName)
        .firstOrNull;
    final direction = GallerySortDirection.values
        .where((value) => value.name == directionName)
        .firstOrNull;
    if (field == null || direction == null) return null;

    return GallerySort(field: field, direction: direction);
  }

  /// 保存排序（字段 + 方向）。
  Future<void> save(GallerySort sort) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.localGallerySortField, sort.field.name);
    await prefs.setString(
      StorageKeys.localGallerySortDirection,
      sort.direction.name,
    );
  }
}
