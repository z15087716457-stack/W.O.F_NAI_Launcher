import 'dart:typed_data';

import '../../../../core/utils/inpaint_mask_utils.dart';
import '../../../../core/utils/nai_resolution_adapter.dart';

typedef MaskOverlayBuilder = Uint8List Function(Uint8List maskImage);

typedef SourcePreviewSizeReader = (int, int)? Function(Uint8List sourceImage);

(int, int) resolveSourcePreviewDimensions({
  required Uint8List sourceBytes,
  int? sourceWidth,
  int? sourceHeight,
  int? fallbackWidth,
  int? fallbackHeight,
  SourcePreviewSizeReader? imageSizeReader,
}) {
  if (sourceWidth != null &&
      sourceHeight != null &&
      sourceWidth > 0 &&
      sourceHeight > 0) {
    return (sourceWidth, sourceHeight);
  }

  final encodedSize = (imageSizeReader ?? NaiResolutionAdapter.readImageSize)(
    sourceBytes,
  );
  if (encodedSize != null && encodedSize.$1 > 0 && encodedSize.$2 > 0) {
    return encodedSize;
  }

  if (fallbackWidth != null &&
      fallbackHeight != null &&
      fallbackWidth > 0 &&
      fallbackHeight > 0) {
    return (fallbackWidth, fallbackHeight);
  }

  return (1, 1);
}

class Img2ImgPreviewDerivedData {
  const Img2ImgPreviewDerivedData({this.maskOverlayBytes});

  final Uint8List? maskOverlayBytes;
}

/// 缓存图生图预览区的重型派生数据，避免无关重建时反复解码大图。
class Img2ImgPreviewCache {
  Img2ImgPreviewCache({MaskOverlayBuilder? maskOverlayBuilder})
    : _maskOverlayBuilder =
          maskOverlayBuilder ?? InpaintMaskUtils.maskToEditorOverlay;

  final MaskOverlayBuilder _maskOverlayBuilder;

  Uint8List? _lastMaskImageForOverlay;
  Uint8List? _cachedMaskOverlayBytes;

  Img2ImgPreviewDerivedData resolve({Uint8List? maskImage}) {
    if (!identical(maskImage, _lastMaskImageForOverlay)) {
      _lastMaskImageForOverlay = maskImage;
      _cachedMaskOverlayBytes = maskImage == null
          ? null
          : _maskOverlayBuilder(maskImage);
    }

    return Img2ImgPreviewDerivedData(maskOverlayBytes: _cachedMaskOverlayBytes);
  }
}
