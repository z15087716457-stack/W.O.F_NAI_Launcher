import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

import '../constants/model_spec.dart';
import '../network/error_mappers/api_error_mapper.dart';
import 'app_logger.dart';
import 'isolate_pool.dart';

const v5PreciseReferenceBuckets = <(int, int)>[
  (256, 4096),
  (256, 4032),
  (256, 3968),
  (256, 3904),
  (256, 3840),
  (256, 3776),
  (256, 3712),
  (256, 3648),
  (256, 3584),
  (256, 3520),
  (256, 3456),
  (256, 3392),
  (256, 3328),
  (320, 3264),
  (320, 3200),
  (320, 3136),
  (320, 3072),
  (320, 3008),
  (320, 2944),
  (320, 2880),
  (320, 2816),
  (320, 2752),
  (384, 2688),
  (384, 2624),
  (384, 2560),
  (384, 2496),
  (384, 2432),
  (384, 2368),
  (448, 2304),
  (448, 2240),
  (448, 2176),
  (448, 2112),
  (512, 2048),
  (512, 1984),
  (512, 1920),
  (512, 1856),
  (576, 1792),
  (576, 1728),
  (576, 1664),
  (640, 1600),
  (640, 1536),
  (704, 1472),
  (704, 1408),
  (768, 1344),
  (768, 1280),
  (832, 1216),
  (896, 1152),
  (960, 1088),
  (1024, 1024),
  (1088, 960),
  (1152, 896),
  (1216, 832),
  (1280, 768),
  (1344, 768),
  (1408, 704),
  (1472, 704),
  (1536, 640),
  (1600, 640),
  (1664, 576),
  (1728, 576),
  (1792, 576),
  (1856, 512),
  (1920, 512),
  (1984, 512),
  (2048, 512),
  (2112, 448),
  (2176, 448),
  (2240, 448),
  (2304, 448),
  (2368, 384),
  (2432, 384),
  (2496, 384),
  (2560, 384),
  (2624, 384),
  (2688, 384),
  (2752, 320),
  (2816, 320),
  (2880, 320),
  (2944, 320),
  (3008, 320),
  (3072, 320),
  (3136, 320),
  (3200, 320),
  (3264, 320),
  (3328, 256),
  (3392, 256),
  (3456, 256),
  (3520, 256),
  (3584, 256),
  (3648, 256),
  (3712, 256),
  (3776, 256),
  (3840, 256),
  (3904, 256),
  (3968, 256),
  (4032, 256),
  (4096, 256),
];

(int, int) computeV5PreciseReferenceBucket(int width, int height) {
  final aspectLog = math.log(math.max(width, 1) / math.max(height, 1));
  var best = v5PreciseReferenceBuckets.first;
  var bestDistance = double.infinity;
  for (final (w, h) in v5PreciseReferenceBuckets) {
    final distance = (aspectLog - math.log(w / h)).abs();
    if (distance < bestDistance) {
      best = (w, h);
      bestDistance = distance;
    }
  }
  return best;
}

/// NAI API 工具类
/// 提供 NovelAI API 相关的共享静态方法
class NAIApiUtils {
  static final Expando<bool> _normalizedPreciseReferencePngCache =
      Expando<bool>('normalizedPreciseReferencePng');

  /// 标记该字节对象已经是 Director Reference 可直接提交的 PNG。
  static Uint8List markNormalizedPreciseReferencePng(Uint8List imageBytes) {
    _normalizedPreciseReferencePngCache[imageBytes] = true;
    return imageBytes;
  }

  /// 当前会话中是否已确认该字节对象是规范化后的 Director Reference PNG。
  static bool isKnownNormalizedPreciseReferencePng(Uint8List imageBytes) {
    return _normalizedPreciseReferencePngCache[imageBytes] == true;
  }

  static final _preciseNormalizations = Expando<Future<Uint8List>>();
  static final _bucketPreciseNormalizations = Expando<Future<Uint8List>>();
  static final _preciseIdentities = Expando<Object>();

  static Object preciseReferenceIdentity(Uint8List bytes) =>
      _preciseIdentities[bytes] ??= Object();

  static void retainPreciseReferenceIdentity(
    Uint8List before,
    Uint8List after,
  ) {
    _preciseIdentities[after] = preciseReferenceIdentity(before);
  }

  /// Share background/import/request work by byte-object identity, never by index.
  static Future<Uint8List> normalizePreciseReference(
    Uint8List image, {
    Future<Uint8List> Function(Uint8List)? normalize,
  }) {
    if (isKnownNormalizedPreciseReferencePng(image)) return Future.value(image);
    return _preciseNormalizations[image] ??=
        Future.sync(() => (normalize ?? ensurePngFormatAsync)(image))
            .then(markNormalizedPreciseReferencePng)
            .onError((Object error, StackTrace stackTrace) {
              _preciseNormalizations[image] = null;
              Error.throwWithStackTrace(error, stackTrace);
            });
  }

  static Future<Uint8List> normalizePreciseReferenceForModel(
    Uint8List image,
    ModelSpec spec,
  ) {
    if (spec.resizeCharacterReferences) return normalizePreciseReference(image);
    if (!spec.bucketCharacterReferences) return Future.value(image);
    return _bucketPreciseNormalizations[image] ??= ComputeGate()
        .runCompute(_bucketPreciseReference, image)
        .then((bytes) => bytes ?? image)
        .onError((Object error, StackTrace stackTrace) {
          _bucketPreciseNormalizations[image] = null;
          Error.throwWithStackTrace(error, stackTrace);
        });
  }

  /// A null result lets the caller reuse the original PNG across isolates.
  static Uint8List? _bucketPreciseReference(Uint8List bytes) {
    final decoder = img.findDecoderForData(bytes);
    final decoded = decoder?.decode(bytes);
    if (decoded == null) {
      throw const FormatException('Invalid precise reference image');
    }
    final orientation = decoded.exif.imageIfd.orientation;
    final image = orientation != null && orientation != 1
        ? img.bakeOrientation(decoded)
        : decoded;
    final width = image.width;
    final height = image.height;
    final (bucketWidth, bucketHeight) = computeV5PreciseReferenceBucket(
      width,
      height,
    );
    if (width == bucketWidth && height == bucketHeight) {
      return decoder is img.PngDecoder && identical(image, decoded)
          ? null
          : img.encodePng(image);
    }
    final scale = math.max(bucketWidth / width, bucketHeight / height);
    final resizeWidth = math.max((width * scale + 0.5).floor(), bucketWidth);
    final resizeHeight = math.max((height * scale + 0.5).floor(), bucketHeight);
    final resized = img.copyResize(
      image,
      width: resizeWidth,
      height: resizeHeight,
      interpolation: img.Interpolation.cubic,
    );
    return img.encodePng(
      img.copyCrop(
        resized,
        x: (resizeWidth - bucketWidth) ~/ 2,
        y: (resizeHeight - bucketHeight) ~/ 2,
        width: bucketWidth,
        height: bucketHeight,
      ),
    );
  }

  /// 将 double 转换为 JSON 数值（整数或浮点数）
  /// 如果是整数值（如 5.0），返回 int；否则返回 double
  static num toJsonNumber(double value) {
    return value == value.truncateToDouble() ? value.toInt() : value;
  }

  /// 将图片转换为 NovelAI Director Reference 要求的格式
  /// 按官方 Web 客户端 Q6 路径处理：
  /// - 选择三种目标画布之一：(1024,1536), (1536,1024), (1472,1472)
  /// - 选择宽高比最接近原图的目标画布
  /// - 按比例缩放图像，黑色背景居中粘贴
  /// - 转换为 PNG 格式
  static Uint8List ensurePngFormat(Uint8List imageBytes) {
    // 解码图片
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      AppLogger.w('Failed to decode image, returning original bytes', 'Utils');
      return imageBytes;
    }

    final int width = originalImage.width;
    final int height = originalImage.height;

    AppLogger.d(
      'Processing character reference: ${width}x$height, channels: ${originalImage.numChannels}',
      'Utils',
    );

    final targets = [
      (1024, 1536), // portrait
      (1536, 1024), // landscape
      (1472, 1472), // square
    ];

    final imageAspectRatio = width / height;
    var bestTarget = targets.first;
    var bestAspectDelta = (bestTarget.$1 / bestTarget.$2 - imageAspectRatio)
        .abs();
    for (final target in targets.skip(1)) {
      final aspectDelta = (target.$1 / target.$2 - imageAspectRatio).abs();
      if (aspectDelta < bestAspectDelta) {
        bestAspectDelta = aspectDelta;
        bestTarget = target;
      }
    }
    final targetW = bestTarget.$1;
    final targetH = bestTarget.$2;

    final targetAspectRatio = targetW / targetH;
    final (newW, newH) = imageAspectRatio > targetAspectRatio
        ? (targetW, (targetW / imageAspectRatio).round())
        : ((targetH * imageAspectRatio).round(), targetH);
    final resized = img.copyResize(
      originalImage,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.cubic,
    );

    final newImg = img.Image(
      width: targetW,
      height: targetH,
      numChannels: 3,
      backgroundColor: img.ColorRgb8(0, 0, 0), // 黑色背景
    );

    final left = (targetW - newW) ~/ 2;
    final top = (targetH - newH) ~/ 2;
    img.compositeImage(newImg, resized, dstX: left, dstY: top);

    final pngBytes = Uint8List.fromList(img.encodePng(newImg));
    AppLogger.d(
      'Character reference processed: ${width}x$height -> ${targetW}x$targetH (centered on black), '
          '${imageBytes.length} bytes -> ${pngBytes.length} bytes',
      'Utils',
    );

    return markNormalizedPreciseReferencePng(pngBytes);
  }

  /// 在后台 isolate 中执行 Director Reference 图片规范化，避免阻塞 UI isolate。
  static Future<Uint8List> ensurePngFormatAsync(Uint8List imageBytes) async {
    final normalizedBytes = await ComputeGate().runCompute(
      ensurePngFormat,
      imageBytes,
    );
    return markNormalizedPreciseReferencePng(normalizedBytes);
  }

  /// 格式化 DioException 为错误代码（供 UI 层本地化显示）
  /// 返回格式: "ERROR_CODE|详细信息"
  static String formatDioError(DioException e) {
    return ApiErrorMapper.formatDioError(e);
  }
}
