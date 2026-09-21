import 'image_params.dart';

/// The operation that produced an image. Captured with the request, never
/// inferred from the current editor when an old result is displayed.
enum ImageOperation {
  imageToImage,
  inpaint,
  enhance,
  variations,
  upscale,
  vibeTransfer,
  removeBackground,
  lineArt,
  sketch,
  colorize,
  emotion,
  declutter,
  pixelSnap;

  static ImageOperation? fromParams(ImageParams params) {
    if (params.enhanceWorkflow) return enhance;
    if (params.action == ImageGenerationAction.infill) return inpaint;
    if (params.action == ImageGenerationAction.img2img) return imageToImage;
    if (params.vibeReferencesV4.isNotEmpty) return vibeTransfer;
    return null;
  }
}
