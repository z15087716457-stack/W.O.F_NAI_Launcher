import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';

/// 本地画廊按时间分组的方式（仅在按修改/创建时间排序时生效）。
enum GalleryGroupMode {
  day,
  month,
  none;

  static GalleryGroupMode? tryParse(String? value) {
    for (final mode in values) {
      if (mode.name == value) return mode;
    }
    return null;
  }
}

/// 分组方式的 SharedPreferences 持久化（默认按天）。
class GalleryGroupModeStore {
  const GalleryGroupModeStore();

  Future<GalleryGroupMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    return GalleryGroupMode.tryParse(
          prefs.getString(StorageKeys.localGalleryGroupMode),
        ) ??
        GalleryGroupMode.day;
  }

  Future<void> save(GalleryGroupMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.localGalleryGroupMode, mode.name);
  }
}

/// 右侧详情面板展开状态的持久化（默认展开）。
class GalleryInspectorVisibilityStore {
  const GalleryInspectorVisibilityStore();

  Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.localGalleryInspectorVisible) ?? true;
  }

  Future<void> save(bool visible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.localGalleryInspectorVisible, visible);
  }
}
