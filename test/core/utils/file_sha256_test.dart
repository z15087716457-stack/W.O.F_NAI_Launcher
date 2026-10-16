import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/file_sha256.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'file hashing matches SHA-256 for empty, small and streamed native input',
    () async {
      final root = await Directory.systemTemp.createTemp('file-sha256-test-');
      try {
        for (final length in [0, 3, 1024 * 1024, 5 * 1024 * 1024 + 19]) {
          final bytes = Uint8List.fromList(
            List.generate(length, (index) => (index * 31 + 17) & 255),
          );
          final file = File(p.join(root.path, 'input.bin'));
          await file.writeAsBytes(bytes);
          expect(await fileSha256(file), sha256.convert(bytes).toString());
        }
      } finally {
        await root.delete(recursive: true);
      }
    },
  );

  test('concurrent native hashes do not share mutable buffers', () async {
    final root = await Directory.systemTemp.createTemp(
      'file-sha256-concurrent-',
    );
    try {
      final futures = <Future<void>>[];
      for (var index = 0; index < 3; index++) {
        final bytes = Uint8List(2 * 1024 * 1024)
          ..fillRange(0, 2 * 1024 * 1024, index);
        final file = File(p.join(root.path, '$index.bin'));
        await file.writeAsBytes(bytes);
        futures.add(() async {
          expect(await fileSha256(file), sha256.convert(bytes).toString());
        }());
      }
      await Future.wait(futures);
    } finally {
      await root.delete(recursive: true);
    }
  });
}
