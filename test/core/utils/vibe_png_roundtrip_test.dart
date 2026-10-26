import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/utils/novelai_vibe_codec.dart';
import 'package:nai_launcher/core/utils/vibe_export_utils.dart';
import 'package:nai_launcher/core/utils/vibe_file_parser.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';
import 'package:nai_launcher/presentation/wiring/generation_reference_imports.dart';

import '../../helpers/app_logger_test_isolation.dart';

Uint8List withNaiData(
  Uint8List png,
  List<int> text, {
  int compression = 0,
  String keyword = 'naidata',
}) {
  final data = <int>[
    ...ascii.encode(keyword),
    0,
    compression,
    0,
    0,
    0,
    ...text,
  ];
  final body = <int>[...ascii.encode('iTXt'), ...data];
  final length = ByteData(4)..setUint32(0, data.length);
  final crc = ByteData(4)..setUint32(0, getCrc32(body));
  return Uint8List.fromList([
    ...png.take(33),
    ...length.buffer.asUint8List(),
    ...body,
    ...crc.buffer.asUint8List(),
    ...png.skip(33),
  ]);
}

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  final png = Uint8List.fromList(
    img.encodePng(img.Image(width: 16, height: 16)),
  );
  const vibes = [
    VibeReference(
      displayName: 'A',
      vibeEncoding: 'Zml4dHVyZS1B',
      strength: -0.3,
      infoExtracted: 0.25,
      encodingModel: 'nai-diffusion-4-5-full',
    ),
    VibeReference(
      displayName: 'B',
      vibeEncoding: 'Zml4dHVyZS1C',
      strength: 0.8,
      infoExtracted: 0.75,
      encodingModel: 'nai-diffusion-4-full',
    ),
  ];
  Future<List<VibeReference>> decode(Uint8List bytes) =>
      const GenerationReferenceDecoder().vibes(
        GenerationReferenceFile('fixture.png', bytes),
      );
  void expectVibes(List<VibeReference> actual) {
    expect(actual, hasLength(vibes.length));
    for (var i = 0; i < actual.length; i++) {
      expect(actual[i].displayName, vibes[i].displayName);
      expect(actual[i].vibeEncoding, vibes[i].vibeEncoding);
      expect(actual[i].strength, vibes[i].strength);
      expect(actual[i].infoExtracted, vibes[i].infoExtracted);
      expect(actual[i].encodingModel, vibes[i].encodingModel);
      expect(actual[i].sourceType, VibeSourceType.png);
    }
  }

  test('own iTXt PNG export imports every encoded reference', () async {
    final embedded = await VibeExportUtils.buildEmbeddedPngBytes(
      vibes: vibes,
      carrierImageBytes: png,
    );
    expectVibes(await decode(embedded));
    expectVibes(await VibeFileParser.extractBundleFromPng(embedded));
  });
  test('tEXt naidata imports every encoded reference', () async {
    final embedded = UnifiedMetadataParser.embedTextChunkOnly(
      png,
      'naidata',
      base64Encode(
        utf8.encode(jsonEncode(NovelAiVibeCodec.buildBundleMap(vibes))),
      ),
    );
    expectVibes(await decode(embedded));
    expectVibes(await VibeFileParser.extractBundleFromPng(embedded));
  });
  test('single data keeps caller defaults when importInfo is absent', () async {
    final single = NovelAiVibeCodec.buildSingleMap(vibes.first)
      ..remove('importInfo');
    final embedded = UnifiedMetadataParser.embedTextChunkOnly(
      png,
      'naidata',
      base64Encode(utf8.encode(jsonEncode(single))),
    );
    final actual = await VibeFileParser.parseFile(
      'single.png',
      embedded,
      defaultStrength: 0.2,
    );
    expect(actual.single.vibeEncoding, vibes.first.vibeEncoding);
    expect(actual.single.strength, 0.2);
  });
  test('legacy encoding keyword remains supported', () async {
    final embedded = UnifiedMetadataParser.embedTextChunkOnly(
      png,
      'NovelAI_Vibe_Encoding_Base64',
      vibes.first.vibeEncoding,
    );
    expect(
      (await decode(embedded)).single.vibeEncoding,
      vibes.first.vibeEncoding,
    );
  });
  for (final compressed in [false, true]) {
    test('legacy iTXt encoding imports with compression=$compressed', () async {
      final text = utf8.encode(vibes.first.vibeEncoding);
      final embedded = withNaiData(
        png,
        compressed ? zlib.encode(text) : text,
        compression: compressed ? 1 : 0,
        keyword: 'NovelAI_Vibe_Encoding_Base64',
      );
      expect(
        (await decode(embedded)).single.vibeEncoding,
        vibes.first.vibeEncoding,
      );
    });
  }
  test('plain PNG stays one raw image and has no embedded bundle', () async {
    final actual = await decode(png);
    expect(actual.single.rawImageData, png);
    expect(actual.single.vibeEncoding, isEmpty);
    expect(actual.single.sourceType, VibeSourceType.rawImage);
    expect(await VibeFileParser.extractBundleFromPng(png), isEmpty);
  });
  test('malformed recognized reference data reports an error', () async {
    final broken = UnifiedMetadataParser.embedTextChunkOnly(
      png,
      'naidata',
      'not-base64',
    );
    await expectLater(decode(broken), throwsFormatException);
  });
  test('compressed iTXt bundle restores every reference', () async {
    final text = ascii.encode(
      base64Encode(
        utf8.encode(jsonEncode(NovelAiVibeCodec.buildBundleMap(vibes))),
      ),
    );
    expectVibes(
      await decode(withNaiData(png, zlib.encode(text), compression: 1)),
    );
  });
  test('malformed recognized iTXt does not become a raw reference', () async {
    await expectLater(
      decode(withNaiData(png, ascii.encode('not-base64'))),
      throwsA(isA<Exception>()),
    );
  });
}
