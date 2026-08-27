import 'dart:math' as math;

import '../constants/model_spec.dart';

/// V5 增强 Max✨ 档的目标尺寸与资格判定。
///
/// 数值与算法取自官网 bundle（57863 模块）：资格=源图面积低于
/// 3MP 的 80%（2516582.4），目标尺寸=ROd(w,h)：2x 基准
/// （先 floor 到 /16 再 ×2）、按 3MP 上限等比收缩、吸附 /32
/// （round，超上限回退 floor）。
class MaxEnhanceMath {
  MaxEnhanceMath._();

  /// 服务端端到端放大的面积上限（3145728 像素）。
  static const int maxArea = 3145728;

  /// Max 档资格上限：3MP 的 80%。
  static const double eligibilityMaxArea = 2516582.4000000004;

  /// 当前模型与源图尺寸是否可用 Max✨ 档。
  static bool isEligible(String model, int? width, int? height) {
    if (!ModelSpecs.of(model).maxEnhance) return false;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return false;
    }
    final area = width * height;
    return area < eligibilityMaxArea;
  }

  /// Max✨ 档的计费/展示目标尺寸（请求本身仍发源图尺寸 +
  /// `upscaled_enhance`，服务端放大到此尺寸）。
  static ({int width, int height}) targetSize(int width, int height) {
    final baseWidth = (width ~/ 16) * 32;
    final baseHeight = (height ~/ 16) * 32;
    final baseArea = baseWidth * baseHeight;
    if (baseArea <= 0) {
      return (width: width, height: height);
    }
    final scale = math.min(1.0, math.sqrt(maxArea / baseArea));
    var w = 32 * ((baseWidth * scale) / 32).round();
    var h = 32 * ((baseHeight * scale) / 32).round();
    if (w * h > maxArea) {
      w = 32 * ((baseWidth * scale) / 32).floor();
      h = 32 * ((baseHeight * scale) / 32).floor();
    }
    return (width: w.clamp(32, 1 << 30), height: h.clamp(32, 1 << 30));
  }
}
