import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/utils/vibe_export_utils.dart';
import 'package:nai_launcher/core/utils/vibe_image_embedder.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/wiring/refs_exporter.dart';

import '../../helpers/app_logger_test_isolation.dart';

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  final image = img.Image(width: 9, height: 5)..setPixelRgb(0, 0, 255, 0, 0);
  final png = Uint8List.fromList(img.encodePng(image));
  const encoded = VibeReference(
    displayName: 'offline',
    vibeEncoding: 'Zml4dHVyZQ==',
    encodingModel: 'nai-diffusion-4-5-full',
  );

  Future<void> expectExport(Uint8List raw, int width, int height) async {
    final entry = VibeLibraryEntry.fromVibeReference(
      name: 'fixture',
      vibeData: encoded.copyWith(rawImageData: raw, thumbnail: png),
    );
    final files = await RefsExporter.build(
      [entry],
      RefsExportPlan(
        keys: [entry.id],
        format: RefsExportFormat.png,
        folder: 'unused',
      ),
      model: 'nai-diffusion-4-5-full',
    );
    expect(files, hasLength(1));
    final decoded = img.decodePng(files.single.bytes)!;
    expect((decoded.width, decoded.height), (width, height));
    final embedded = await VibeImageEmbedder.extractVibeFromImage(
      files.single.bytes,
    );
    expect(embedded.vibes.single.vibeEncoding, encoded.vibeEncoding);
    expect(embedded.vibes.single.rawImageData, raw);
    expect(entry.rawImageData, raw);
  }

  test(
    'JPEG carrier exports as PNG and keeps the original reference',
    () async {
      await expectExport(Uint8List.fromList(img.encodeJpg(image)), 9, 5);
    },
  );
  test('WebP carrier exports as PNG', () async {
    final webp = await File(
      'test/fixtures/metadata/v4_webp_exif_stealth.webp',
    ).readAsBytes();
    final decoded = img.decodeWebP(webp)!;
    await expectExport(webp, decoded.width, decoded.height);
  });
  test('JPEG EXIF orientation is baked before PNG export', () async {
    final rotated = img.Image.from(image);
    rotated.exif.imageIfd.orientation = 6;
    await expectExport(Uint8List.fromList(img.encodeJpg(rotated)), 5, 9);
  });
  test('PNG carrier keeps pixels and existing text metadata', () async {
    final source = UnifiedMetadataParser.embedTextChunkOnly(
      png,
      'Comment',
      '{"prompt":"source prompt","seed":12}',
    );
    final output = await VibeExportUtils.buildEmbeddedPngBytes(
      vibes: [encoded],
      carrierImageBytes: source,
    );
    expect(
      img.decodePng(output)!.getBytes(),
      img.decodePng(source)!.getBytes(),
    );
    expect(
      UnifiedMetadataParser.parseFromImageBytes(output).metadata!.seed,
      12,
    );
  });
  test('a thumbnail-only entry still exports', () async {
    final entry = VibeLibraryEntry.fromVibeReference(
      name: 'thumb',
      vibeData: encoded.copyWith(thumbnail: png),
    );
    final files = await RefsExporter.build(
      [entry],
      RefsExportPlan(
        keys: [entry.id],
        format: RefsExportFormat.png,
        folder: 'unused',
      ),
      model: 'nai-diffusion-4-5-full',
    );
    expect(img.decodePng(files.single.bytes), isNotNull);
  });
  test('batch plans accept JPEG and preserve all bundle references', () async {
    final jpeg = Uint8List.fromList(img.encodeJpg(image));
    final entries = [
      for (final name in ['A', 'B'])
        VibeLibraryEntry.fromVibeReference(
          name: name,
          vibeData: encoded.copyWith(rawImageData: jpeg),
        ),
    ];
    final plans = VibeExportUtils.buildEmbeddedPngExportPlans(entries);
    expect(plans, hasLength(2));
    for (final plan in plans) {
      final output = await VibeExportUtils.buildEmbeddedPngBytes(
        vibes: [
          ...plan.vibes,
          encoded.copyWith(displayName: 'second'),
        ],
        carrierImageBytes: plan.carrierImageBytes,
      );
      expect(img.decodePng(output), isNotNull);
      expect(
        (await VibeImageEmbedder.extractVibeFromImage(output)).vibes,
        hasLength(2),
      );
    }
  });
}
