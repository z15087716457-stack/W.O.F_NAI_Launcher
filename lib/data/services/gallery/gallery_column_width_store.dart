import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';

/// 本地画廊逻辑列宽的 SharedPreferences 持久化。
///
/// 独立小类以便单元测试（测试用 `SharedPreferences.setMockInitialValues`）。
/// 范围与 UI 滑块一致：140~480，步进 20，默认 260。
class GalleryColumnWidthStore {
  const GalleryColumnWidthStore();

  /// 列宽最小值
  static const double minColumnWidth = 140;

  /// 列宽最大值
  static const double maxColumnWidth = 480;

  /// 列宽步进
  static const double columnWidthStep = 20;

  /// 默认列宽
  static const double defaultColumnWidth = 260;

  /// 把任意值钳制到合法区间并取整到步进（供 UI 与持久化共用）
  static double clampColumnWidth(double value) {
    final stepped = (value / columnWidthStep).round() * columnWidthStep;
    return stepped.clamp(minColumnWidth, maxColumnWidth);
  }

  /// 读取持久化的列宽；无记录或越界时返回默认值（260）。
  Future<double> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getDouble(StorageKeys.localGalleryColumnWidth);
    if (raw == null) return defaultColumnWidth;
    return clampColumnWidth(raw);
  }

  /// 保存列宽（写入前钳制到合法区间）。
  Future<void> save(double columnWidth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      StorageKeys.localGalleryColumnWidth,
      clampColumnWidth(columnWidth),
    );
  }
}
