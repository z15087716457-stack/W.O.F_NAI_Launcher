import 'dart:typed_data';
import '../../core/constants/api_constants.dart';
import '../../core/utils/max_enhance_utils.dart';
import '../../data/models/image/image_params.dart';

/// Pure projection shared by the editor and frozen Agent source requests.
class NativeImageEnhance {
  const NativeImageEnhance._();

  static List<double> factors(String model, int width, int height) {
    if ((width == 832 && height == 1216) || (width == 1216 && height == 832)) {
      return const [1.0, 1.5];
    }
    final step = ImageModels.isV5Model(model) ? 32 : 64;
    return [1.0, 1.5, 2.0]
        .where(
          (factor) =>
              width * height * factor * factor <= MaxEnhanceMath.maxArea &&
              (width * factor) % step == 0 &&
              (height * factor) % step == 0,
        )
        .toList();
  }

  static (double, double) magnitude(double value) {
    const presets = [
      (0.2, 0.0),
      (0.4, 0.0),
      (0.5, 0.0),
      (0.6, 0.0),
      (0.7, 0.1),
    ];
    return presets[(value.clamp(0.0, 1.0) * 4).round()];
  }

  static ImageParams project({
    required ImageParams current,
    required Uint8List source,
    required int width,
    required int height,
    required double factor,
    required double strength,
    required double noise,
    required bool max,
  }) {
    final model = ImageModels.resolveBaseModel(current.model);
    final maxEnabled = max && MaxEnhanceMath.isEligible(model, width, height);
    return current.copyWith(
      model: model,
      sourceImage: source,
      maskImage: null,
      action: ImageGenerationAction.img2img,
      isOutpaint: false,
      enhanceWorkflow: true,
      upscaledEnhance: maxEnabled,
      width: maxEnabled ? width : (width * factor).round(),
      height: maxEnabled ? height : (height * factor).round(),
      strength: strength,
      noise: noise,
    );
  }
}
