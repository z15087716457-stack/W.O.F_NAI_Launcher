import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';

/// 真实样本夹具：
/// - v5_stealth_classic_envelope.png：NAI 官网 V5 下载件（无 tEXt，alpha LSB 隐写，
///   经典信封，Source=DiffusionModelMetaName.NAIv5 E32849CC）
/// - v45_launcher_text_chunk.png：启动器自存 V4.5（经典 tEXt 格式，回归样本）
/// - v4_webp_exif_stealth.webp：V4 webp（EXIF + alpha 隐写双通道，rating:general）
const _v5Png = 'test/fixtures/metadata/v5_stealth_classic_envelope.png';
const _v45Png = 'test/fixtures/metadata/v45_launcher_text_chunk.png';
const _v4Webp = 'test/fixtures/metadata/v4_webp_exif_stealth.webp';

void main() {
  group('UnifiedMetadataParser 真实样本', () {
    test('V5 PNG（alpha 隐写）能读出模型/提示词/种子/采样器', () {
      final result = UnifiedMetadataParser.parseFromFile(_v5Png);

      expect(result.success, isTrue, reason: result.errorMessage);
      final metadata = result.metadata!;
      expect(metadata.model, ImageModels.animeDiffusionV5Full);
      expect(metadata.prompt, isNotEmpty);
      expect(metadata.seed, 741649701);
      expect(metadata.sampler, 'k_euler_ancestral');
      expect(metadata.steps, 28);
    });

    test('V4.5 启动器 PNG（经典 tEXt）回归不破', () {
      final result = UnifiedMetadataParser.parseFromFile(_v45Png);

      expect(result.success, isTrue, reason: result.errorMessage);
      final metadata = result.metadata!;
      expect(metadata.model, ImageModels.animeDiffusionV45Full);
      expect(metadata.prompt, isNotEmpty);
      expect(metadata.seed, 4199015664);
      expect(metadata.sampler, 'k_euler_ancestral');
    });

    test('webp（EXIF 通道）能读出提示词', () {
      final result = UnifiedMetadataParser.parseFromFile(_v4Webp);

      expect(result.success, isTrue, reason: result.errorMessage);
      expect(result.sourceFormat, contains('EXIF'));
      final metadata = result.metadata!;
      expect(metadata.prompt, contains('gawr gura'));
      expect(metadata.seed, 1428971741);
      expect(metadata.sampler, 'k_euler_ancestral');
    });

    test('webp 剥离 EXIF 后走 alpha 隐写回退', () {
      final bytes = File(_v4Webp).readAsBytesSync();
      final stripped = _stripWebpExifChunk(bytes);

      final result = UnifiedMetadataParser.parseFromImageBytes(stripped);

      expect(result.success, isTrue, reason: result.errorMessage);
      expect(result.sourceFormat, contains('stealth'));
      expect(result.metadata!.prompt, contains('gawr gura'));
    });

    test('未知格式字节返回失败而非抛异常', () {
      final result = UnifiedMetadataParser.parseFromImageBytes(
        Uint8List.fromList(utf8.encode('not an image at all')),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Not a valid'));
    });
  });

  group('UnifiedMetadataParser V5 params 新信封', () {
    const paramsMap = {
      'prompt': '1girl, synth_test',
      'uc': 'lowres',
      'steps': 28,
      'seed': 12345678,
      'sampler': 'k_euler_ancestral',
      'width': 832,
      'height': 1216,
      'model_name': 'DiffusionModelMetaName.NAIv5',
      'model_hash': 'E32849CC',
    };
    const envelope = {
      'description': '1girl, synth_test',
      'software': 'NovelAI',
      'source': 'DiffusionModelMetaName.NAIv5 E32849CC',
      'generation_time': 1.0,
      'params': paramsMap,
      'track': 'stable',
    };

    test('params 为 Map 时归一化走经典路径', () {
      final result = UnifiedMetadataParser.parseFromTextData({
        'Comment': jsonEncode(envelope),
      });

      expect(result.success, isTrue, reason: result.errorMessage);
      final metadata = result.metadata!;
      expect(metadata.model, ImageModels.animeDiffusionV5Full);
      expect(metadata.prompt, '1girl, synth_test');
      expect(metadata.negativePrompt, 'lowres');
      expect(metadata.seed, 12345678);
      expect(metadata.sampler, 'k_euler_ancestral');
    });

    test('params 为 JSON string 时同样识别', () {
      final envelopeWithStringParams = {
        ...envelope,
        'params': jsonEncode(paramsMap),
      };
      final result = UnifiedMetadataParser.parseFromTextData({
        'Comment': jsonEncode(envelopeWithStringParams),
      });

      expect(result.success, isTrue, reason: result.errorMessage);
      expect(result.metadata!.prompt, '1girl, synth_test');
      expect(result.metadata!.model, ImageModels.animeDiffusionV5Full);
    });

    test('JPEG APP1 EXIF 携带 V5 params 信封（UserComment）', () {
      final jpeg = _buildJpegWithExifUserComment(jsonEncode(envelope));

      final result = UnifiedMetadataParser.parseFromImageBytes(jpeg);

      expect(result.success, isTrue, reason: result.errorMessage);
      expect(result.sourceFormat, contains('JPEG EXIF'));
      final metadata = result.metadata!;
      expect(metadata.model, ImageModels.animeDiffusionV5Full);
      expect(metadata.prompt, '1girl, synth_test');
      expect(metadata.seed, 12345678);
      expect(metadata.sampler, 'k_euler_ancestral');
    });
  });
}

/// 从 webp 字节中移除 EXIF chunk 并修正 RIFF 长度
Uint8List _stripWebpExifChunk(Uint8List bytes) {
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final fourcc = latin1.decode(bytes.sublist(offset, offset + 4));
    final size = ByteData.sublistView(
      bytes,
      offset + 4,
      offset + 8,
    ).getUint32(0, Endian.little);
    final chunkTotal = 8 + size + (size & 1);
    if (fourcc == 'EXIF') {
      final out = BytesBuilder();
      out.add(bytes.sublist(0, offset));
      out.add(bytes.sublist(offset + chunkTotal));
      final stripped = out.toBytes();
      // 修正 RIFF 总长度（文件大小 - 8）
      ByteData.sublistView(
        stripped,
        4,
        8,
      ).setUint32(0, stripped.length - 8, Endian.little);
      return stripped;
    }
    offset += chunkTotal;
  }
  throw StateError('fixture webp has no EXIF chunk');
}

/// 构造最小 JPEG：SOI + APP1(Exif) + EOI，UserComment 携带给定 JSON
Uint8List _buildJpegWithExifUserComment(String jsonText) {
  final commentPayload = Uint8List.fromList([
    ...latin1.encode('ASCII'),
    0, 0, 0, // ASCII 字符集前缀补齐 8 字节
    ...utf8.encode(jsonText),
  ]);

  // TIFF（大端）：MM 42，IFD0 在偏移 8，单条目 UserComment(0x9286)
  final tiff = BytesBuilder();
  const ifdOffset = 8;
  const entryCount = 1;
  const valueOffset = ifdOffset + 2 + entryCount * 12 + 4;
  tiff.add([0x4D, 0x4D, 0x00, 0x2A]); // MM + magic 42
  tiff.add(_be32(ifdOffset));
  tiff.add(_be16(entryCount));
  tiff.add(_be16(0x9286)); // tag: UserComment
  tiff.add(_be16(7)); // type: UNDEFINED
  tiff.add(_be32(commentPayload.length));
  tiff.add(_be32(valueOffset));
  tiff.add(_be32(0)); // next IFD = 0
  tiff.add(commentPayload);

  final exifBody = Uint8List.fromList([
    ...latin1.encode('Exif'),
    0, 0,
    ...tiff.toBytes(),
  ]);

  final jpeg = BytesBuilder();
  jpeg.add([0xFF, 0xD8]); // SOI
  jpeg.add([0xFF, 0xE1]); // APP1
  jpeg.add(_be16(exifBody.length + 2)); // 段长度含自身 2 字节
  jpeg.add(exifBody);
  jpeg.add([0xFF, 0xD9]); // EOI
  return jpeg.toBytes();
}

List<int> _be16(int value) => [(value >> 8) & 0xFF, value & 0xFF];

List<int> _be32(int value) => [
  (value >> 24) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 8) & 0xFF,
  value & 0xFF,
];
