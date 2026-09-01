import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/data/services/explore_run_image_store.dart';

void main() {
  late Directory rootDirectory;

  setUpAll(() async {
    rootDirectory = await Directory.systemTemp.createTemp(
      'explore_image_store_test_',
    );
  });

  tearDownAll(() async {
    if (await rootDirectory.exists()) {
      await rootDirectory.delete(recursive: true);
    }
  });

  ExploreRunImageStore store() =>
      ExploreRunImageStore(rootPathResolver: () async => rootDirectory.path);

  test('deleteCandidateImage removes the copy and is idempotent', () async {
    final imageStore = store();
    final file = File('${rootDirectory.path}/cand-1.png');
    await file.writeAsBytes(const [1, 2, 3]);
    expect(await file.exists(), isTrue);

    expect(await imageStore.deleteCandidateImage(file.path), isTrue);
    expect(await file.exists(), isFalse);

    // 文件本就不存在视为成功（幂等）。
    expect(await imageStore.deleteCandidateImage(file.path), isTrue);
  });

  test(
    'storeCandidateImage copies into run dir; deleteRunDir clears it',
    () async {
      final imageStore = store();
      final source = File('${rootDirectory.path}/source.png');
      await source.writeAsBytes(const [9, 8, 7]);

      final storedPath = await imageStore.storeCandidateImage(
        runId: 'run-x',
        candidateId: 'cand-x',
        bytes: Uint8List.fromList(const [0]),
        sourceFilePath: source.path,
      );
      expect(storedPath, isNotNull);
      expect(await File(storedPath!).exists(), isTrue);
      // 源文件不动（铁律 3）。
      expect(await source.exists(), isTrue);

      await imageStore.deleteRunDir('run-x');
      expect(await File(storedPath).exists(), isFalse);
      // 目录不存在时幂等。
      await imageStore.deleteRunDir('run-x');
    },
  );
}
