import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';

import '../../helpers/app_logger_test_isolation.dart';

Object? withoutDimensions(Object? value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        if (entry.key != 'width' && entry.key != 'height')
          entry.key: withoutDimensions(entry.value),
    };
  }
  if (value is List) return value.map(withoutDimensions).toList();
  if (value is String && value.startsWith('{')) {
    return withoutDimensions(jsonDecode(value));
  }
  return value;
}

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  final plain = Uint8List.fromList(
    img.encodePng(img.Image(width: 16, height: 24)),
  );

  Future<void> expectInheritance(Uint8List source) async {
    final before = UnifiedMetadataParser.parseFromImageBytes(source);
    expect(before.success, isTrue);
    final originalBytes = Uint8List.fromList(source);
    final output = await ImageSaveUtils.inheritSourceMetadata(
      imageBytes: plain,
      sourceBytes: source,
      width: 16,
      height: 24,
    );
    final after = UnifiedMetadataParser.parseFromImageBytes(output);
    expect(after.success, isTrue, reason: after.errorMessage);
    expect(after.metadata!.prompt, before.metadata!.prompt);
    expect(after.metadata!.seed, before.metadata!.seed);
    expect(after.metadata!.model, before.metadata!.model);
    expect(after.metadata!.software, before.metadata!.software);
    expect(after.metadata!.source, before.metadata!.source);
    expect(after.metadata!.width, 16);
    expect(after.metadata!.height, 24);
    expect(
      withoutDimensions(jsonDecode(after.metadata!.rawJson!)),
      withoutDimensions(jsonDecode(before.metadata!.rawJson!)),
    );
    expect(source, originalBytes);
    expect(img.decodePng(output)!.getBytes(), img.decodePng(plain)!.getBytes());

    // Alignment edits PNG results. WebP/JPEG here are source-metadata fixtures,
    // so place their complete envelope in a PNG before checking alignment.
    final pngSource = UnifiedMetadataParser.isPngHeader(source)
        ? source
        : UnifiedMetadataParser.embedTextChunkOnly(
            plain,
            'Comment',
            before.metadata!.rawJson!,
          );
    final aligned = await ImageSaveUtils.alignEmbeddedResolution(
      imageBytes: pngSource,
      width: 16,
      height: 24,
    );
    expect(aligned, isNotNull);
    final alignedMetadata = UnifiedMetadataParser.parseFromImageBytes(
      aligned!,
    ).metadata!;
    expect(alignedMetadata.width, 16);
    expect(alignedMetadata.height, 24);
    expect(alignedMetadata.prompt, before.metadata!.prompt);
    expect(alignedMetadata.characterPrompts, before.metadata!.characterPrompts);
    expect(
      alignedMetadata.characterNegativePrompts,
      before.metadata!.characterNegativePrompts,
    );
    expect(
      withoutDimensions(jsonDecode(alignedMetadata.rawJson!)),
      withoutDimensions(jsonDecode(before.metadata!.rawJson!)),
    );
    expect(source, originalBytes);
    expect(
      await ImageSaveUtils.alignEmbeddedResolution(
        imageBytes: aligned,
        width: 16,
        height: 24,
      ),
      same(aligned),
    );
  }

  for (final name in [
    'v5_stealth_classic_envelope.png',
    'v4_webp_exif_stealth.webp',
    'v45_launcher_text_chunk.png',
  ]) {
    test('inherits full metadata from $name', () async {
      await expectInheritance(
        await File('test/fixtures/metadata/$name').readAsBytes(),
      );
    });
  }

  const params = {
    'prompt': 'source prompt',
    'uc': 'source negative',
    'seed': 123,
    'width': 2,
    'height': 3,
    'model': 'nai-diffusion-4-full',
    'v4_prompt': {
      'caption': {
        'base_caption': 'source prompt',
        'char_captions': [
          {
            'char_caption': 'speaker',
            'centers': [
              {'x': 0.2, 'y': 0.8},
            ],
          },
        ],
      },
    },
    'opaque_parameter': {
      'keep': [1, 2, 3],
    },
  };
  test(
    'alignment preserves independent PNG headers and wrapped fields',
    () async {
      final envelope = {
        'Description': 'inner description',
        'Software': 'NovelAI inner',
        'Source': 'NovelAI inner model',
        'Comment': jsonEncode(params),
        'opaque_envelope': {'width': 777, 'keep': true},
      };
      final headers = {
        'Comment': jsonEncode(envelope),
        'Description': 'outer description differs',
        'Software': 'NovelAI outer',
        'Source': 'NovelAI outer model',
        'Title': 'independent title',
      };
      var source = plain;
      for (final entry in headers.entries) {
        source = UnifiedMetadataParser.embedTextChunkOnly(
          source,
          entry.key,
          entry.value,
        );
      }
      final aligned = await ImageSaveUtils.alignEmbeddedResolution(
        imageBytes: source,
        width: 16,
        height: 24,
      );
      final after = UnifiedMetadataParser.extractPngTextData(aligned!);
      expect({...after}..remove('Comment'), {...headers}..remove('Comment'));
      final expected = {
        ...envelope,
        'Comment': jsonEncode({...params, 'width': 16, 'height': 24}),
      };
      expect(jsonDecode(after['Comment']!), expected);
      expect(
        img.decodePng(aligned)!.getBytes(),
        img.decodePng(source)!.getBytes(),
      );
    },
  );
  test('JPEG EXIF source preserves its full params envelope', () async {
    final image = img.Image(width: 2, height: 3);
    image.exif.exifIfd[0x9286] = img.IfdValueUndefined.list(
      Uint8List.fromList([
        ...ascii.encode('ASCII'),
        0,
        0,
        0,
        ...utf8.encode(
          jsonEncode({
            'software': 'NovelAI',
            'source': 'NovelAI Diffusion V4',
            'params': params,
            'opaque_envelope': 'keep',
          }),
        ),
      ]),
    );
    await expectInheritance(Uint8List.fromList(img.encodeJpg(image)));
  });
  for (final key in ['Comment', 'params']) {
    for (final asString in [false, true]) {
      test(
        'preserves $key envelope and nested parameters (string=$asString)',
        () async {
          final envelope = {
            'Description': 'source description',
            'Software': 'NovelAI',
            'Source': 'NovelAI Diffusion V4',
            'description': 'source description',
            'software': 'NovelAI',
            'source': 'NovelAI Diffusion V4',
            'opaque_envelope': {'keep': 'exact'},
            key: asString ? jsonEncode(params) : params,
          };
          final source = UnifiedMetadataParser.embedTextChunkOnly(
            plain,
            'Comment',
            jsonEncode(envelope),
          );
          await expectInheritance(source);
        },
      );
    }
  }

  test('keeps a derived image with its own stealth metadata intact', () async {
    final own = await File(
      'test/fixtures/metadata/v5_stealth_classic_envelope.png',
    ).readAsBytes();
    expect(
      await ImageSaveUtils.inheritSourceMetadata(
        imageBytes: own,
        sourceBytes: plain,
        width: 16,
        height: 24,
      ),
      same(own),
    );
  });
  test('a source without metadata leaves the derived image intact', () async {
    expect(
      await ImageSaveUtils.alignEmbeddedResolution(
        imageBytes: plain,
        width: 16,
        height: 24,
      ),
      isNull,
    );
    expect(
      await ImageSaveUtils.inheritSourceMetadata(
        imageBytes: plain,
        sourceBytes: plain,
        width: 16,
        height: 24,
      ),
      same(plain),
    );
  });
}
