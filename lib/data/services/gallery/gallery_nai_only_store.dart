import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';

/// 本地画廊 NAI-only 过滤偏好的 SharedPreferences 持久化。
///
/// 默认 true：用户明确只要 NAI 生成的图，非 NAI 图（无元数据）默认隐藏。
/// 独立小类以便单元测试（测试用 `SharedPreferences.setMockInitialValues`）。
class GalleryNaiOnlyStore {
  const GalleryNaiOnlyStore();

  /// 读取持久化偏好；无记录时返回默认值（true = 只看 NAI 图）。
  Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.localGalleryNaiOnly) ?? true;
  }

  /// 保存偏好。
  Future<void> save(bool naiOnly) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.localGalleryNaiOnly, naiOnly);
  }
}
