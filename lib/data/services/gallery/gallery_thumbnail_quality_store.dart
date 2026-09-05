import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/cache/thumbnail_cache_service.dart';
import '../../../core/constants/storage_keys.dart';

/// 本地画廊缩略图质量的 SharedPreferences 持久化。
class GalleryThumbnailQualityStore {
  const GalleryThumbnailQualityStore();

  /// 读取持久化质量；无记录或枚举名非法时返回高清。
  Future<GalleryThumbnailQuality> load() async {
    final prefs = await SharedPreferences.getInstance();
    String? value;
    try {
      value = prefs.getString(StorageKeys.localGalleryThumbnailQuality);
    } catch (_) {
      return GalleryThumbnailQuality.hd;
    }
    return GalleryThumbnailQuality.values.firstWhere(
      (quality) => quality.name == value,
      orElse: () => GalleryThumbnailQuality.hd,
    );
  }

  /// 保存质量。
  Future<void> save(GalleryThumbnailQuality quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.localGalleryThumbnailQuality,
      quality.name,
    );
  }
}
