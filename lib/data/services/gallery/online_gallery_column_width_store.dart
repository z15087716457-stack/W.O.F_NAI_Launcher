import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import 'gallery_column_width_store.dart';

/// 在线画廊逻辑列宽的 SharedPreferences 持久化（范围与本地画廊一致）。
class OnlineGalleryColumnWidthStore {
  const OnlineGalleryColumnWidthStore();

  Future<double> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getDouble(StorageKeys.onlineGalleryColumnWidth);
    if (raw == null) return 200;
    return GalleryColumnWidthStore.clampColumnWidth(raw);
  }

  Future<void> save(double columnWidth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      StorageKeys.onlineGalleryColumnWidth,
      GalleryColumnWidthStore.clampColumnWidth(columnWidth),
    );
  }
}
