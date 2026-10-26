import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../data/models/vibe/vibe_reference.dart';
import '../../data/services/metadata/unified_metadata_parser.dart';
import 'app_logger.dart';
import 'novelai_vibe_codec.dart';
import 'vibe_image_embedder.dart';
import 'localization_extension.dart';

/// Vibe 文件解析器
///
/// 支持以下格式:
/// - PNG 文件 (带 NovelAI_Vibe_Encoding_Base64 iTXt 元数据)
/// - .naiv4vibe JSON 文件
/// - .naiv4vibebundle JSON 包
/// - 其他图片格式 (作为原始图片处理)
class VibeFileParser {
  /// PNG iTXt 块中的 Vibe 编码关键字（官方格式）
  static const String _iTXtKeyword = 'NovelAI_Vibe_Encoding_Base64';

  /// NAI 官方 iTXt 关键字（嵌入图片使用）
  static const String _naiDataKeyword = 'naidata';

  /// 最大处理的文件大小（20MB）
  static const int _maxFileSize = 20 * 1024 * 1024;

  /// 解析超时时间
  static const Duration _parseTimeout = Duration(seconds: 5);

  /// 支持的图片扩展名
  static const List<String> _imageExtensions = [
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
    'bmp',
  ];

  /// 从文件字节和文件名解析 Vibe 参考
  ///
  /// 根据文件扩展名自动选择解析方式
  /// 支持智能检测：
  /// - 文件名包含 .naiv4vibebundle 但扩展名为 .png 时，优先尝试 bundle 解析
  /// - PNG 文件如果 iTXt 解析失败，尝试检测是否包含 JSON bundle 数据
  static Future<List<VibeReference>> parseFile(
    String fileName,
    Uint8List bytes, {
    double defaultStrength = 0.6,
  }) async {
    final extension = fileName.split('.').last.toLowerCase();
    final lowerFileName = fileName.toLowerCase();

    // 智能检测：文件名包含 .naiv4vibebundle 但扩展名为 .png
    // 这种情况通常是用户将 bundle 文件重命名为 .png
    if (lowerFileName.contains('.naiv4vibebundle') && extension == 'png') {
      AppLogger.i(
        'Detected bundle in filename, trying bundle parsing first: $fileName',
        'VibeParser',
      );
      try {
        // 尝试作为 bundle 解析
        final result = await fromBundle(
          fileName,
          bytes,
          defaultStrength: defaultStrength,
        );
        AppLogger.i(
          'Successfully parsed as bundle: ${result.length} vibes found',
          'VibeParser',
        );
        return result;
      } catch (e) {
        AppLogger.i(
          'Bundle parsing failed, falling back to PNG parsing: $e',
          'VibeParser',
        );
        // 失败则继续尝试 PNG 解析
      }
    }

    switch (extension) {
      case 'png':
        return _fromPngReferences(fileName, bytes, defaultStrength);

      case 'naiv4vibe':
        return [
          await fromNaiV4Vibe(
            fileName,
            bytes,
            defaultStrength: defaultStrength,
          ),
        ];

      case 'naiv4vibebundle':
        return fromBundle(fileName, bytes, defaultStrength: defaultStrength);

      default:
        // 其他图片格式作为原始图片处理
        if (_imageExtensions.contains(extension)) {
          return [
            VibeReference(
              displayName: fileName,
              vibeEncoding: '',
              thumbnail: bytes,
              rawImageData: bytes,
              strength: defaultStrength,
              sourceType: VibeSourceType.rawImage,
            ),
          ];
        }
        throw FormatException('Unsupported file type: $extension');
    }
  }

  /// 单条读取接口；文件导入使用列表接口保留 Bundle 全部内容。
  static Future<VibeReference> fromPng(
    String fileName,
    Uint8List bytes, {
    double defaultStrength = 0.6,
  }) async =>
      (await _fromPngReferences(fileName, bytes, defaultStrength)).first;

  static Future<List<VibeReference>> _fromPngReferences(
    String fileName,
    Uint8List bytes,
    double defaultStrength,
  ) async {
    final references = await extractBundleFromPng(
      bytes,
      fileName: fileName,
      defaultStrength: defaultStrength,
    );
    if (references.isNotEmpty) return references;
    return [
      VibeReference(
        displayName: fileName,
        vibeEncoding: '',
        thumbnail: bytes,
        rawImageData: bytes,
        strength: defaultStrength,
        sourceType: VibeSourceType.rawImage,
      ),
    ];
  }

  /// 读取 PNG 内的全部参考；仅未包含参考数据时返回空列表。
  static Future<List<VibeReference>> extractBundleFromPng(
    Uint8List bytes, {
    String fileName = 'bundle.png',
    double defaultStrength = 0.6,
  }) async {
    if (bytes.length > _maxFileSize) {
      throw const FormatException('Vibe PNG exceeds the 20MB size limit');
    }
    return compute(
      _parsePngIsolate,
      _PngParseParams(
        fileName: fileName,
        bytes: bytes,
        defaultStrength: defaultStrength,
      ),
    ).timeout(_parseTimeout);
  }

  static Future<List<VibeReference>> _parsePngIsolate(
    _PngParseParams params,
  ) async {
    final info = img.PngDecoder().startDecode(params.bytes);
    if (info is! img.PngInfo) throw const FormatException('Invalid PNG image');

    Future<List<VibeReference>> parsePayload(
      Map<String, dynamic> payload,
    ) async {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
      final references = payload.containsKey('vibes')
          ? await fromBundle(
              params.fileName,
              bytes,
              defaultStrength: params.defaultStrength,
            )
          : [
              await fromNaiV4Vibe(
                params.fileName,
                bytes,
                defaultStrength: params.defaultStrength,
              ),
            ];
      return [
        for (final reference in references)
          reference.copyWith(
            sourceType: VibeSourceType.png,
            thumbnail: reference.thumbnail ?? params.bytes,
          ),
      ];
    }

    final naiData = VibeImageEmbedder.extractNaiDataFromPng(params.bytes);
    if (naiData != null) return parsePayload(naiData);
    final textData = UnifiedMetadataParser.extractPngTextData(params.bytes);
    final encodedBundle = textData[_naiDataKeyword];
    if (encodedBundle != null) {
      return parsePayload(
        jsonDecode(utf8.decode(base64Decode(encodedBundle)))
            as Map<String, dynamic>,
      );
    }
    final encoding = textData[_iTXtKeyword];
    if (encoding != null) {
      if (encoding.isEmpty) throw const FormatException('Empty Vibe encoding');
      return [
        VibeReference(
          displayName: params.fileName,
          vibeEncoding: encoding,
          thumbnail: params.bytes,
          rawImageData: params.bytes,
          strength: params.defaultStrength,
          sourceType: VibeSourceType.png,
        ),
      ];
    }
    final embeddedJson = _extractEmbeddedJsonFromTextData(textData);
    if (embeddedJson == null) return [];
    return parsePayload(jsonDecode(embeddedJson) as Map<String, dynamic>);
  }

  /// 从 textData 中提取嵌入的 JSON 数据
  ///
  /// 检查 textData 中是否包含 JSON 数据
  static String? _extractEmbeddedJsonFromTextData(
    Map<String, String> textData,
  ) {
    for (final entry in textData.entries) {
      final text = entry.value;
      try {
        // 检查是否包含 JSON 特征
        if (text.contains('"identifier"') ||
            text.contains('"novelai-vibe-transfer"') ||
            text.contains('"encodings"')) {
          // 尝试找到 JSON 开始位置
          final jsonStart = text.indexOf('{');
          if (jsonStart != -1) {
            final jsonText = text.substring(jsonStart);
            // 验证是否为有效 JSON
            jsonDecode(jsonText);
            return jsonText;
          }
        }
      } catch (e) {
        // 不是有效的 JSON，继续检查下一个 entry
        continue;
      }
    }
    return null;
  }

  /// 从导入信息中提取强度值
  static double _extractStrength(
    Map<String, dynamic>? importInfo,
    double defaultValue,
  ) {
    final strengthValue = importInfo?['strength'];
    return switch (strengthValue) {
      final double v => v,
      final int v => v.toDouble(),
      final String v => double.tryParse(v) ?? defaultValue,
      _ => defaultValue,
    };
  }

  /// 从导入信息中提取信息提取值
  static double _extractInformationExtracted(
    Map<String, dynamic>? importInfo,
    double defaultValue,
  ) {
    final infoValue = importInfo?['information_extracted'];
    return switch (infoValue) {
      final double v => VibeReference.sanitizeInfoExtracted(v),
      final int v => VibeReference.sanitizeInfoExtracted(v.toDouble()),
      final String v => VibeReference.sanitizeInfoExtracted(
        double.tryParse(v) ?? defaultValue,
      ),
      _ => defaultValue,
    };
  }

  /// 从 .naiv4vibe 文件解析 Vibe 参考
  static Future<VibeReference> fromNaiV4Vibe(
    String fileName,
    Uint8List bytes, {
    double defaultStrength = 0.6,
  }) async {
    final jsonString = utf8.decode(bytes);
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    final name = jsonData['name'] as String? ?? fileName;
    final strength = _extractStrength(
      jsonData['importInfo'] as Map<String, dynamic>?,
      defaultStrength,
    );
    final infoExtracted = _extractInformationExtracted(
      jsonData['importInfo'] as Map<String, dynamic>?,
      0.7,
    );
    final rawImageData = _extractRawImageFromJson(jsonData);
    final thumbnail = _extractThumbnailFromJson(jsonData);
    final type = jsonData['type'] as String?;
    final encodingDetails = _extractEncodingDetails(jsonData);

    if (type == 'image') {
      if (rawImageData == null || rawImageData.isEmpty) {
        throw ArgumentError(currentL10n.vibeFile_missingRawImage(fileName));
      }

      return VibeReference(
        displayName: name,
        vibeEncoding: encodingDetails?.encoding ?? '',
        thumbnail: thumbnail,
        rawImageData: rawImageData,
        strength: VibeReference.sanitizeStrength(strength),
        infoExtracted: infoExtracted,
        encodingModel: encodingDetails?.model,
        sourceType: encodingDetails == null
            ? VibeSourceType.rawImage
            : VibeSourceType.naiv4vibe,
      );
    }

    if (encodingDetails == null) {
      final hasEncodings = jsonData.containsKey('encodings');
      throw ArgumentError(
        '文件缺少有效的 Vibe encoding: $fileName '
        '(type=$type, hasEncodings=$hasEncodings). '
        '此文件可能已损坏或不完整，建议删除后重新保存。',
      );
    }

    return VibeReference(
      displayName: name,
      vibeEncoding: encodingDetails.encoding,
      thumbnail: thumbnail,
      rawImageData: rawImageData,
      strength: VibeReference.sanitizeStrength(strength),
      infoExtracted: infoExtracted,
      encodingModel: encodingDetails.model,
      sourceType: VibeSourceType.naiv4vibe,
    );
  }

  /// 从 JSON 数据中提取缩略图
  static Uint8List? _extractThumbnailFromJson(Map<String, dynamic> jsonData) {
    try {
      final thumbnailBase64 = jsonData['thumbnail'] as String?;
      if (thumbnailBase64 != null && thumbnailBase64.isNotEmpty) {
        final base64Data = _extractBase64FromDataUri(thumbnailBase64);
        if (base64Data != null) {
          return base64Decode(base64Data);
        }
      }

      // 如果没有 thumbnail 字段，尝试从 image 字段提取
      final imageBase64 = jsonData['image'] as String?;
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        final base64Data = _extractBase64FromDataUri(imageBase64);
        if (base64Data != null) {
          return base64Decode(base64Data);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.d('Error extracting thumbnail from JSON: $e', 'VibeParser');
      }
    }
    return null;
  }

  /// 从 JSON 数据中提取原始图片
  static Uint8List? _extractRawImageFromJson(Map<String, dynamic> jsonData) {
    try {
      final imageBase64 = jsonData['image'] as String?;
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        final base64Data = _extractBase64FromDataUri(imageBase64);
        if (base64Data != null) {
          return base64Decode(base64Data);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.d('Error extracting raw image from JSON: $e', 'VibeParser');
      }
    }
    return null;
  }

  /// 从 Data URI 中提取 base64 数据
  /// 格式: data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ...
  static String? _extractBase64FromDataUri(String dataUri) {
    if (dataUri.startsWith('data:')) {
      final commaIndex = dataUri.indexOf(',');
      if (commaIndex != -1 && commaIndex < dataUri.length - 1) {
        return dataUri.substring(commaIndex + 1);
      }
    }
    // 如果不是 Data URI 格式，假设是纯 base64
    return dataUri;
  }

  /// 从 .naiv4vibebundle 文件解析多个 Vibe 参考
  static Future<List<VibeReference>> fromBundle(
    String fileName,
    Uint8List bytes, {
    double defaultStrength = 0.6,
  }) async {
    final jsonString = utf8.decode(bytes);
    final bundleData = jsonDecode(jsonString) as Map<String, dynamic>;
    final vibesList = bundleData['vibes'] as List<dynamic>? ?? [];

    final results = <VibeReference>[];

    for (var i = 0; i < vibesList.length; i++) {
      try {
        final vibeItem = vibesList[i];
        // 验证元素类型，跳过非 Map 类型的元素
        if (vibeItem is! Map<String, dynamic>) {
          if (kDebugMode) {
            AppLogger.d(
              'Skipping invalid vibe entry $i in bundle: expected Map but got ${vibeItem.runtimeType}',
              'VibeParser',
            );
          }
          continue;
        }
        final vibeJson = vibeItem;
        final name = vibeJson['name'] as String? ?? '$fileName#$i';
        final strength = _extractStrength(
          vibeJson['importInfo'] as Map<String, dynamic>?,
          defaultStrength,
        );
        final infoExtracted = _extractInformationExtracted(
          vibeJson['importInfo'] as Map<String, dynamic>?,
          0.7,
        );

        final encodingDetails = _extractEncodingDetails(vibeJson);
        final rawImageData = _extractRawImageFromJson(vibeJson);
        if (encodingDetails != null ||
            (rawImageData != null && rawImageData.isNotEmpty)) {
          final thumbnail = _extractThumbnailFromJson(vibeJson);
          results.add(
            VibeReference(
              displayName: name,
              vibeEncoding: encodingDetails?.encoding ?? '',
              thumbnail: thumbnail,
              rawImageData: rawImageData,
              strength: VibeReference.sanitizeStrength(strength),
              infoExtracted: infoExtracted,
              encodingModel:
                  encodingDetails?.model ??
                  _extractEncodingModelFromJson(vibeJson),
              sourceType: encodingDetails == null
                  ? VibeSourceType.rawImage
                  : VibeSourceType.naiv4vibebundle,
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          AppLogger.d(
            'Error parsing vibe entry $i in bundle: $e',
            'VibeParser',
          );
        }
      }
    }

    if (results.isEmpty) {
      throw ArgumentError('No valid vibes found in bundle: $fileName');
    }

    return results;
  }

  static String? _extractEncodingModelFromJson(Map<String, dynamic> jsonData) {
    final encodingModel = _extractEncodingDetails(jsonData)?.model;
    if (encodingModel != null) {
      return encodingModel;
    }
    final importInfo = jsonData['importInfo'];
    final model = importInfo is Map ? importInfo['model'] : null;
    return model is String
        ? NovelAiVibeCodec.normalizeModelOrNull(model)
        : null;
  }

  static ({String encoding, String? model})? _extractEncodingDetails(
    Map<String, dynamic> jsonData,
  ) {
    final encodingsValue = jsonData['encodings'];
    if (encodingsValue is! Map) {
      return null;
    }

    final importInfo = jsonData['importInfo'];
    final importedModel = importInfo is Map && importInfo['model'] is String
        ? NovelAiVibeCodec.normalizeModelOrNull(importInfo['model'] as String)
        : null;
    final preferredModelKey = importedModel == null
        ? null
        : NovelAiVibeCodec.encodingKeyForModel(importedModel);
    final informationExtracted = importInfo is Map
        ? switch (importInfo['information_extracted']) {
            final num value => value.toDouble(),
            final String value => double.tryParse(value),
            _ => null,
          }
        : null;

    final modelEntries = encodingsValue.entries.toList(growable: false);
    if (preferredModelKey != null) {
      modelEntries.sort((left, right) {
        if (left.key == preferredModelKey) return -1;
        if (right.key == preferredModelKey) return 1;
        return 0;
      });
    }

    for (final modelEntry in modelEntries) {
      final modelEncodings = modelEntry.value;
      if (modelEncodings is! Map) {
        continue;
      }

      MapEntry<dynamic, dynamic>? fallback;
      MapEntry<dynamic, dynamic>? unknown;
      MapEntry<dynamic, dynamic>? matchingParams;
      for (final variant in modelEncodings.entries) {
        final value = variant.value;
        if (value is! Map) {
          continue;
        }
        final encoding = value['encoding'];
        if (encoding is! String || encoding.isEmpty) {
          continue;
        }
        fallback ??= variant;
        if (variant.key == 'unknown') {
          unknown ??= variant;
        }
        final params = value['params'];
        final parameterValue = params is Map
            ? params['information_extracted']
            : null;
        if (informationExtracted != null &&
            parameterValue is num &&
            parameterValue.toDouble() == informationExtracted) {
          matchingParams ??= variant;
        }
      }

      final selected = matchingParams ?? unknown ?? fallback;
      if (selected == null) {
        continue;
      }
      final selectedValue = selected.value as Map;
      final modelKey = modelEntry.key.toString();
      return (
        encoding: selectedValue['encoding'] as String,
        model: NovelAiVibeCodec.modelForEncodingKey(modelKey) ?? importedModel,
      );
    }

    return null;
  }

  /// 检查文件扩展名是否为支持的图片格式
  static bool isSupportedImageExtension(String extension) {
    final ext = extension.toLowerCase();
    return _imageExtensions.contains(ext) ||
        ext == 'naiv4vibe' ||
        ext == 'naiv4vibebundle';
  }

  /// 检查文件名是否为支持的格式
  static bool isSupportedFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return isSupportedImageExtension(extension);
  }
}

/// PNG 解析参数（用于 Isolate）
class _PngParseParams {
  final String fileName;
  final Uint8List bytes;
  final double defaultStrength;

  _PngParseParams({
    required this.fileName,
    required this.bytes,
    required this.defaultStrength,
  });
}
