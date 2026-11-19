import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/generation_draft_backup.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'two settings edits share media and both versions expand to standalone JSON',
    () {
      final dir = Directory.systemTemp.createTempSync('generation-backup-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final image = Uint8List.fromList(
        List<int>.generate(8192, (i) => i % 251),
      );
      Map<String, dynamic> draft(int steps, Object source, Object empty) => {
        'fields': {'prompt': 'sourceImage'},
        'generation': {'steps': steps},
        'sourceImage': source,
        'maskImage': null,
        'precise': [
          {'image': source},
        ],
        'vibes': [
          {
            'rawImageData': source,
            'thumbnail': empty,
            'vibeEncoding': 'encoding fixture',
          },
        ],
        'workflow': {'temporaryEnhanceSource': source},
      };
      final a = GenerationDraftBackup.write(
        dir,
        draft(28, image, Uint8List(0)),
      );
      final b = GenerationDraftBackup.write(
        dir,
        draft(29, image, Uint8List(0)),
      );
      final original = draft(28, base64Encode(image), '');
      final legacy = File(p.join(dir.path, 'legacy.json'))
        ..writeAsStringSync(jsonEncode(original));
      expect(Directory(p.join(dir.path, 'media')).listSync().length, 3);
      expect(b.lengthSync(), lessThan(image.length));
      expect(GenerationDraftBackup.read(legacy), original);
      expect(GenerationDraftBackup.read(a), original);
      expect(GenerationDraftBackup.read(b), draft(29, base64Encode(image), ''));
      final blob = Directory(p.join(dir.path, 'media'))
          .listSync()
          .whereType<File>()
          .singleWhere((file) => file.lengthSync() == image.length);
      blob.writeAsBytesSync([0]);
      expect(() => GenerationDraftBackup.read(a), throwsFormatException);
    },
  );
}
