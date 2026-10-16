import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A small cover preview. The caller retains [image] for viewing, dragging and
/// saving the original. Decode at the physical display size with 50% headroom
/// for filtering; 32px buckets avoid a new cache entry on every resize pixel.
class UiPreviewImage extends StatefulWidget {
  const UiPreviewImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.gaplessPlayback = false,
  });

  final ImageProvider image;
  final double? width;
  final double? height;
  final bool gaplessPlayback;

  @override
  State<UiPreviewImage> createState() => _UiPreviewImageState();
}

class _UiPreviewImageState extends State<UiPreviewImage> {
  ImageProvider? _previousSource;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final image = widget.image;
      final width = widget.width;
      final height = widget.height;
      // A pane / DPR resize keeps the old sharp frame until its new bucket is
      // ready. Replacing the source retains the caller's original gapless policy.
      final keepFrame = widget.gaplessPlayback || _previousSource == image;
      _previousSource = image;
      final w = width?.isFinite == true ? width! : constraints.maxWidth;
      final h = height?.isFinite == true ? height! : constraints.maxHeight;
      final dpr = MediaQuery.devicePixelRatioOf(context);
      int bucket(double value) =>
          math.max(32, (value * dpr * 1.5 / 32).ceil() * 32);
      final bounded = w.isFinite && h.isFinite && w > 0 && h > 0;
      return Image(
        image: bounded
            ? PreviewImageProvider(image, bucket(w), bucket(h))
            : image,
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: keepFrame,
      );
    },
  );
}

/// Unlike a fit-inside decode, cover must retain enough pixels on BOTH axes.
/// The intrinsic aspect ratio is obtained by the decoder without decoding the
/// full image first. Tiny sources are never enlarged during decode.
class PreviewImageProvider extends ImageProvider<PreviewImageKey> {
  const PreviewImageProvider(this.source, this.width, this.height);
  final ImageProvider source;
  final int width;
  final int height;

  @override
  Future<PreviewImageKey> obtainKey(ImageConfiguration configuration) => source
      .obtainKey(configuration)
      .then((key) => PreviewImageKey(key, width, height));

  @override
  ImageStreamCompleter loadImage(
    PreviewImageKey key,
    ImageDecoderCallback decode,
  ) {
    final completer = source.loadImage(
      key.source,
      (
        ui.ImmutableBuffer buffer, {
        ui.TargetImageSizeCallback? getTargetSize,
      }) => decode(
        buffer,
        getTargetSize: (intrinsicWidth, intrinsicHeight) {
          // Respect a source which already limits decoding (e.g. ResizeImage).
          final upstream = getTargetSize?.call(intrinsicWidth, intrinsicHeight);
          final w = upstream?.width ?? intrinsicWidth;
          final h = upstream?.height ?? intrinsicHeight;
          final scale = math.min(1.0, math.max(width / w, height / h));
          return ui.TargetImageSize(
            width: math.min(w, (w * scale).ceil()),
            height: math.min(h, (h * scale).ceil()),
          );
        },
      ),
    );
    completer.addEphemeralErrorListener((Object error, StackTrace? stack) {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
    });
    return completer;
  }

  @override
  bool operator ==(Object other) =>
      other is PreviewImageProvider &&
      source == other.source &&
      width == other.width &&
      height == other.height;
  @override
  int get hashCode => Object.hash(source, width, height);
}

@immutable
class PreviewImageKey {
  const PreviewImageKey(this.source, this.width, this.height);
  final Object source;
  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      other is PreviewImageKey &&
      source == other.source &&
      width == other.width &&
      height == other.height;
  @override
  int get hashCode => Object.hash(source, width, height);
}
