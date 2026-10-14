import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../data/services/metadata/unified_metadata_parser.dart';
import '../utils/nai_resolution_adapter.dart';

const agentAttachmentMaxBytes = 64 * 1024 * 1024;
const agentAttachmentMaxPixels = 64000000;

class AgentImageInputException implements Exception {
  const AgentImageInputException(this.code);
  final String code;
  @override
  String toString() => 'AgentImageInputException($code)';
}

String? agentImageMime(Uint8List bytes) {
  if (bytes.length < 12) return null;
  if (bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71) {
    return 'image/png';
  }
  if (bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255) {
    return 'image/jpeg';
  }
  final header = String.fromCharCodes(bytes.take(12));
  if (header.startsWith('GIF87a') || header.startsWith('GIF89a')) {
    return 'image/gif';
  }
  if (header.startsWith('RIFF') && header.endsWith('WEBP')) return 'image/webp';
  if (bytes[0] == 66 && bytes[1] == 77) return 'image/bmp';
  return null;
}

class AgentAttachmentImageInfo {
  const AgentAttachmentImageInfo({
    required this.mimeType,
    required this.width,
    required this.height,
    this.metadata,
  });
  final String mimeType;
  final int width, height;
  final Map<String, dynamic>? metadata;
}

Map<String, dynamic>? readNaiAttachmentMetadata(
  Uint8List bytes, {
  img.Image? decoded,
}) {
  if (!{
    'image/png',
    'image/jpeg',
    'image/webp',
  }.contains(agentImageMime(bytes))) {
    return null;
  }
  final texts = decoded?.textData ?? const <String, String>{};
  final textFingerprint = [
    'Software',
    'Source',
  ].any((key) => (texts[key] ?? '').toLowerCase().contains('novelai'));
  const marker = 'NovelAI';
  var encodedFingerprint = false;
  for (
    var i = bytes.indexOf(78);
    i >= 0 && i + marker.length <= bytes.length;
    i = bytes.indexOf(78, i + 1)
  ) {
    if (String.fromCharCodes(bytes.sublist(i, i + marker.length)) == marker) {
      encodedFingerprint = true;
      break;
    }
  }
  final image =
      decoded ??
      (textFingerprint || encodedFingerprint
          ? null
          : img.decodeImage(bytes, frame: 0));
  const stealth = 'stealth_pngcomp';
  var stealthFingerprint =
      image?.hasAlpha == true &&
      image!.width * image.height >= stealth.length * 8;
  if (stealthFingerprint) {
    for (var i = 0; i < stealth.length; i++) {
      var value = 0;
      for (var bit = 0; bit < 8; bit++) {
        final offset = i * 8 + bit;
        value =
            (value << 1) |
            (image
                    .getPixel(offset ~/ image.height, offset % image.height)
                    .a
                    .toInt() &
                1);
      }
      if (value != stealth.codeUnitAt(i)) {
        stealthFingerprint = false;
        break;
      }
    }
  }
  if (!textFingerprint && !encodedFingerprint && !stealthFingerprint) {
    return null;
  }
  final result = UnifiedMetadataParser.parseFromImageBytes(bytes);
  final metadata = result.metadata;
  if (metadata == null) return null;
  final confirmed =
      '${metadata.software ?? ''} ${metadata.source ?? ''}'
          .toLowerCase()
          .contains('novelai') ||
      (metadata.model ?? '').startsWith('nai-diffusion-') ||
      (stealthFingerprint &&
          (result.sourceFormat ?? '').contains('stealth_pngcomp'));
  if (!confirmed) return null;
  dynamic compact(dynamic value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          if (entry.key != 'rawJson' &&
              entry.value != null &&
              entry.value != '' &&
              !(entry.value is Iterable && (entry.value as Iterable).isEmpty) &&
              !(entry.value is Map && (entry.value as Map).isEmpty))
            entry.key: compact(entry.value),
      };
    }
    if (value is List) return value.map(compact).toList();
    return value;
  }

  return Map<String, dynamic>.from(compact(metadata.toJson()) as Map);
}

/// Validates off the UI thread. Original bytes are never re-encoded here.
Future<AgentAttachmentImageInfo> inspectAgentAttachment(Uint8List bytes) async {
  if (bytes.length > agentAttachmentMaxBytes) {
    throw const AgentImageInputException('oversized');
  }
  return Isolate.run(() {
    final mime = agentImageMime(bytes);
    final size = NaiResolutionAdapter.readImageSize(bytes);
    if (mime == null || size == null) {
      throw const AgentImageInputException('invalid');
    }
    if (size.$1 * size.$2 > agentAttachmentMaxPixels) {
      throw const AgentImageInputException('oversized');
    }
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes, frame: 0);
      if (decoded == null) {
        throw const AgentImageInputException('invalid');
      }
    } catch (_) {
      throw const AgentImageInputException('invalid');
    }
    final metadata = readNaiAttachmentMetadata(bytes, decoded: decoded);
    return AgentAttachmentImageInfo(
      mimeType: mime,
      width: size.$1,
      height: size.$2,
      metadata: metadata,
    );
  });
}

/// BMP is retained as BMP. Only the display/upload copy becomes PNG.
Future<Uint8List> agentAttachmentVisualBytes(
  Uint8List bytes,
  String mime,
) async {
  if (mime != 'image/bmp') return bytes;
  return Isolate.run(() {
    final size = NaiResolutionAdapter.readImageSize(bytes);
    if (bytes.length > agentAttachmentMaxBytes ||
        size == null ||
        size.$1 * size.$2 > agentAttachmentMaxPixels) {
      throw const AgentImageInputException('oversized');
    }
    final image = img.decodeBmp(bytes);
    if (image == null) throw const AgentImageInputException('invalid');
    return img.encodePng(image);
  });
}
