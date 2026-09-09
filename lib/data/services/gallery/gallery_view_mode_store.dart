import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import 'gallery_view_mode.dart';

/// 本地画廊视图模式的 SharedPreferences 持久化。
///
/// 独立小类以便单元测试（测试用 `SharedPreferences.setMockInitialValues`）。
/// V2 起持久化枚举字符串；旧布尔键只读迁移、保留不删（降级兼容）。
class GalleryViewModeStore {
  const GalleryViewModeStore();

  /// 读取持久化的视图模式；无记录时返回默认值（V3 起新装默认火车流）。
  ///
  /// 优先级：新字符串键（未知值落默认；遗留 'mosaic' 同样落默认
  /// justified，静默兼容）→ 旧布尔键迁移（true=masonry / false=grid，
  /// 并回写新键）→ 默认 justified。
  Future<GalleryViewMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    String? raw;
    try {
      raw = prefs.getString(StorageKeys.localGalleryViewModeV2);
    } catch (_) {
      raw = null;
    }
    if (raw != null) {
      return GalleryViewMode.tryParse(raw) ?? GalleryViewMode.justified;
    }
    final legacy = prefs.getBool(StorageKeys.localGalleryViewMode);
    if (legacy != null) {
      final mode = legacy ? GalleryViewMode.masonry : GalleryViewMode.grid;
      await save(mode);
      return mode;
    }
    return GalleryViewMode.justified;
  }

  /// 保存视图模式（只写新键；旧布尔键不动）。
  Future<void> save(GalleryViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.localGalleryViewModeV2, mode.name);
  }
}
