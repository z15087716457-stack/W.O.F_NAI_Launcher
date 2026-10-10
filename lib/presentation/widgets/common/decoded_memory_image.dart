import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

/// 根据布局尺寸限制内存图解码尺寸，避免列表里反复全尺寸解码大图。
class DecodedMemoryImage extends StatelessWidget {
  const DecodedMemoryImage({
    super.key,
    required this.bytes,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    this.gaplessPlayback = true,
    this.maxLogicalWidth,
    this.maxLogicalHeight,
    this.decodeScale = 1.0,
    this.decodeForCover = false,
    this.errorBuilder,
    this.frameBuilder,
  });

  final Uint8List bytes;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final double? maxLogicalWidth;
  final double? maxLogicalHeight;
  final double decodeScale;

  /// Decode enough pixels for a cropped banner, rather than fitting the full
  /// source inside the banner and magnifying the smaller decoded result.
  final bool decodeForCover;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageFrameBuilder? frameBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelRatio =
            MediaQuery.maybeDevicePixelRatioOf(context) ??
            View.of(context).devicePixelRatio;
        final cacheWidth = resolveCacheDimension(
          logicalSize: maxLogicalWidth,
          constrainedSize: constraints.hasBoundedWidth
              ? constraints.maxWidth
              : null,
          pixelRatio: pixelRatio,
          decodeScale: decodeScale,
        );
        final cacheHeight = resolveCacheDimension(
          logicalSize: maxLogicalHeight,
          constrainedSize: constraints.hasBoundedHeight
              ? constraints.maxHeight
              : null,
          pixelRatio: pixelRatio,
          decodeScale: decodeScale,
        );

        final memoryImage = MemoryImage(bytes);
        final ImageProvider<Object> imageProvider;
        if (cacheWidth == null && cacheHeight == null) {
          imageProvider = memoryImage;
        } else if (decodeForCover && fit == BoxFit.cover) {
          imageProvider = _CoverMemoryImage(bytes, cacheWidth, cacheHeight);
        } else {
          imageProvider = ResizeImage(
            memoryImage,
            width: cacheWidth,
            height: cacheHeight,
            policy: ResizeImagePolicy.fit,
          );
        }

        return Image(
          image: imageProvider,
          fit: fit,
          alignment: alignment,
          filterQuality: filterQuality,
          gaplessPlayback: gaplessPlayback,
          errorBuilder: errorBuilder,
          frameBuilder: frameBuilder,
        );
      },
    );
  }

  static int? resolveCacheDimension({
    required double? logicalSize,
    required double? constrainedSize,
    required double pixelRatio,
    double decodeScale = 1.0,
  }) {
    final effectiveLogicalSize = logicalSize ?? constrainedSize;
    if (effectiveLogicalSize == null || !effectiveLogicalSize.isFinite) {
      return null;
    }

    final physicalSize = (effectiveLogicalSize * pixelRatio * decodeScale)
        .round()
        .clamp(1, 4096);
    return physicalSize;
  }
}

/// Source dimensions are supplied by the codec, so portrait and panorama
/// banners keep their aspect ratio without a second decode or full-size cache.
class _CoverMemoryImage extends MemoryImage {
  const _CoverMemoryImage(super.bytes, this.targetWidth, this.targetHeight);

  final int? targetWidth;
  final int? targetHeight;

  @override
  ImageStreamCompleter loadImage(MemoryImage key, ImageDecoderCallback decode) {
    return super.loadImage(
      key,
      (buffer, {getTargetSize}) => decode(
        buffer,
        getTargetSize: (width, height) {
          final coverScale = math.max(
            (targetWidth ?? 0) / width,
            (targetHeight ?? 0) / height,
          );
          // Never upscale a small original or decode an unbounded panorama.
          final scale = math.min(
            math.min(1.0, coverScale),
            4096 / math.max(width, height),
          );
          return ui.TargetImageSize(
            width: math.max(1, (width * scale).ceil()),
            height: math.max(1, (height * scale).ceil()),
          );
        },
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _CoverMemoryImage &&
      super == other &&
      targetWidth == other.targetWidth &&
      targetHeight == other.targetHeight;

  @override
  int get hashCode => Object.hash(super.hashCode, targetWidth, targetHeight);
}
