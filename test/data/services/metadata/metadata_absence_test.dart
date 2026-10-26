import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/services/metadata/isolate_metadata_service.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';
import 'package:path/path.dart' as p;

import '../../../helpers/app_logger_test_isolation.dart';

void main() {
  final image = img.Image(width: 8, height: 8);
  final valid = {
    'png': Uint8List.fromList(img.encodePng(image)),
    'jpg': Uint8List.fromList(img.encodeJpg(image)),
    'webp': base64Decode('UklGRhoAAABXRUJQVlA4TA0AAAAvAAAAEAcQERGIiP4HAA=='),
  };
  final corrupt = {
    'png': Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
    'jpg': Uint8List.fromList([255, 216, 255, 225, 0, 20, 0, 0]),
    'webp': Uint8List.fromList([
      ...ascii.encode('RIFF'),
      10,
      0,
      0,
      0,
      ...ascii.encode('WEBP'),
    ]),
  };
  late Directory directory;
  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    directory = await Directory.systemTemp.createTemp('metadata_absence_');
  });
  tearDownAll(() async {
    IsolateMetadataService.instance.dispose();
    await directory.delete(recursive: true);
    await AppLoggerTestIsolation.tearDown();
  });
  for (final entry in valid.entries) {
    test(
      '${entry.key} valid absence survives single and two-phase worker paths',
      () async {
        final parsed = UnifiedMetadataParser.parseFromImageBytes(entry.value);
        expect(parsed.success, isFalse);
        expect(parsed.metadataAbsent, isTrue, reason: parsed.errorMessage);
        final file = File(p.join(directory.path, 'plain.${entry.key}'));
        await file.writeAsBytes(entry.value);
        for (final gradual in [false, true]) {
          final config = IsolateParseConfig(
            useGradualRead: gradual,
            useCache: false,
          );
          final single = await IsolateMetadataService.instance.parseMetadata(
            file.path,
            config: config,
          );
          final hashed = await IsolateMetadataService.instance
              .parseMetadataWithHash(
                file.path,
                config: config,
                shouldParseWithHash: (_) => true,
              );
          for (final result in [single, hashed]) {
            expect(result.success, isTrue, reason: result.error);
            expect(result.metadata, isNotNull);
            expect(result.metadata!.hasData, isFalse);
          }
          expect(hashed.fileHash, isNotNull);
        }
      },
    );
  }
  for (final entry in corrupt.entries) {
    test('${entry.key} corrupt data remains a failed read', () async {
      final parsed = UnifiedMetadataParser.parseFromImageBytes(entry.value);
      expect(parsed.success, isFalse);
      expect(parsed.metadataAbsent, isFalse);
      final file = File(p.join(directory.path, 'broken.${entry.key}'));
      await file.writeAsBytes(entry.value);
      final result = await IsolateMetadataService.instance
          .parseMetadataWithHash(file.path, shouldParseWithHash: (_) => true);
      expect(result.success, isFalse);
      expect(result.metadata, isNull);
      expect(result.error, isNotNull);
    });
  }
}
