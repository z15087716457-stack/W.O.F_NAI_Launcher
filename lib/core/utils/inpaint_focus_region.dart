import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'dart:isolate';
import 'package:image/image.dart' as img;

/// Source-pixel coordinates; the website stores the same rectangle on its
/// eight-pixel mask grid. Context is excluded from repainting, not from the crop.
class InpaintFocusRegion {
  const InpaintFocusRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.context = 96,
  });
  final int x, y, width, height, context;
  Rect get rect => Rect.fromLTWH(
    x.toDouble(),
    y.toDouble(),
    width.toDouble(),
    height.toDouble(),
  );
  factory InpaintFocusRegion.fromRect(Rect rect, {required int context}) {
    final left = (rect.left / 8).round() * 8;
    final top = (rect.top / 8).round() * 8;
    return InpaintFocusRegion(
      x: left,
      y: top,
      width: math.max(8, (rect.right / 8).round() * 8 - left),
      height: math.max(8, (rect.bottom / 8).round() * 8 - top),
      context: context,
    );
  }
  InpaintFocusRegion clamped(int sourceWidth, int sourceHeight) {
    final left = x.clamp(0, math.max(0, sourceWidth - 8)).toInt();
    final top = y.clamp(0, math.max(0, sourceHeight - 8)).toInt();
    return InpaintFocusRegion(
      x: left,
      y: top,
      width: width.clamp(8, sourceWidth - left).toInt(),
      height: height.clamp(8, sourceHeight - top).toInt(),
      context: context,
    );
  }

  ({int width, int height}) get requestSize {
    const pixels = 1048576;
    if (width * height >= pixels * 0.8) return (width: width, height: height);
    final scale = math.sqrt(pixels / (width * height));
    return (
      width: math.max(64, (width * scale).floor() ~/ 64 * 64),
      height: math.max(64, (height * scale).floor() ~/ 64 * 64),
    );
  }

  /// Clips coverage to the focus interior. An empty interior mask means repaint
  /// the whole interior, exactly as the website's Save operation does.
  void applyToBinaryMask(Uint8List mask, int sourceWidth, int sourceHeight) {
    final inner = rect.deflate(context.toDouble());
    if (inner.isEmpty) {
      mask.fillRange(0, mask.length, 0);
      return;
    }
    final left = inner.left.ceil().clamp(0, sourceWidth);
    final right = inner.right.ceil().clamp(left, sourceWidth);
    final top = inner.top.ceil().clamp(0, sourceHeight);
    final bottom = inner.bottom.ceil().clamp(top, sourceHeight);
    mask.fillRange(0, top * sourceWidth, 0);
    mask.fillRange(bottom * sourceWidth, mask.length, 0);
    var hasCoverage = false;
    for (var y = top; y < bottom; y++) {
      final offset = y * sourceWidth;
      mask.fillRange(offset, offset + left, 0);
      mask.fillRange(offset + right, offset + sourceWidth, 0);
      if (!hasCoverage) {
        for (var x = left; x < right; x++) {
          if (mask[offset + x] != 0) {
            hasCoverage = true;
            break;
          }
        }
      }
    }
    if (!hasCoverage) {
      for (var y = top; y < bottom; y++) {
        mask.fillRange(y * sourceWidth + left, y * sourceWidth + right, 1);
      }
    }
  }

  Future<Uint8List> cropBytes(Uint8List bytes) {
    final left = x, top = y, w = width, h = height;
    return Isolate.run(() {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw StateError('Invalid focused inpaint image');
      return Uint8List.fromList(
        img.encodePng(
          img.copyCrop(decoded, x: left, y: top, width: w, height: h),
          level: 9,
        ),
      );
    });
  }
}
