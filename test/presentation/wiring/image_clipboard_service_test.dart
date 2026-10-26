import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/presentation/services/image_clipboard_service.dart';
import 'package:nai_launcher/presentation/utils/clipboard_image.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('copy_original_');
  });
  tearDown(() async {
    await temp.delete(recursive: true);
  });
  test(
    'original file bytes copied exactly once, with live strip setting',
    () async {
      final original = UnifiedMetadataParser.embedTextChunkOnly(
        Uint8List.fromList(img.encodePng(img.Image(width: 5, height: 7))),
        'Comment',
        '{"prompt":"private-sentinel"}',
      );
      final file = File('${temp.path}/original.png');
      await file.writeAsBytes(original);
      var strip = false;
      final writes = <Uint8List>[];
      final service = ImageClipboardService(
        stripMetadata: () => strip,
        write: (bytes) async => writes.add(bytes),
      );
      await service.copyFile(file.path);
      expect(writes.length, 1);
      expect(writes.single, original);
      strip = true;
      await service.copyFile(file.path);
      expect(writes.length, 2);
      expect(
        String.fromCharCodes(writes.last),
        isNot(contains('private-sentinel')),
      );
      expect(img.decodePng(writes.last)!.width, 5);
      expect(await file.readAsBytes(), original);
    },
  );
  test(
    'JPEG normalized to PNG at clipboard writer; failures propagate',
    () async {
      final bytes = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 3, height: 4)),
      );
      Uint8List? output;
      final service = ImageClipboardService(
        stripMetadata: () => false,
        write: (b) => writeImageBytesToClipboardAsPng(
          b,
          writePng: (png) async {
            output = png;
          },
        ),
      );
      await service.copyBytes(() async => bytes, fileName: 'original.jpg');
      expect(output!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(img.decodePng(output!)!.height, 4);
      await expectLater(
        service.copyFile('${temp.path}/missing.png'),
        throwsA(isA<FileSystemException>()),
      );
      final failing = ImageClipboardService(
        stripMetadata: () => false,
        write: (_) async => throw StateError('clipboard failed'),
      );
      await expectLater(
        failing.copyBytes(() async => bytes, fileName: 'a.jpg'),
        throwsStateError,
      );
    },
  );
}
