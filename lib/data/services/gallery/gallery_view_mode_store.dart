import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';

/// 本地画廊视图模式的 SharedPreferences 持久化。
///
/// 独立小类以便单元测试（测试用 `SharedPreferences.setMockInitialValues`）。
class GalleryViewModeStore {
  const GalleryViewModeStore();

  /// 读取持久化的视图模式；无记录时返回默认值（瀑布流 = true）。
  Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.localGalleryViewMode) ?? true;
  }

  /// 保存视图模式。
  Future<void> save(bool isMasonryView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.localGalleryViewMode, isMasonryView);
  }
}
