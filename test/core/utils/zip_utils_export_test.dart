import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/zip_utils.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory directory;
  late String output;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('zip_images_');
    output = p.join(directory.path, 'export.zip');
  });
  tearDown(() => directory.delete(recursive: true));

  Future<String> file(String name, List<int> bytes) async {
    final file = File(p.join(directory.path, name));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  for (final toFile in [true, false]) {
    Future<Archive> export(List<String> paths) async {
      final List<int> bytes;
      if (toFile) {
        expect(await ZipUtils.createZipFromImages(paths, output), isTrue);
        bytes = await File(output).readAsBytes();
      } else {
        bytes = (await ZipUtils.createZipBytesFromImages(paths))!;
      }
      return ZipDecoder().decodeBytes(bytes);
    }

    test('export preserves colliding names and bytes; file=$toFile', () async {
      final paths = [
        await file('a/same.png', [1, 2]),
        await file('b/same.png', [3, 4]),
        await file('c/same (2).png', [5, 6]),
        await file('d/SAME.PNG', [7, 8]),
      ];
      final archive = await export(paths);
      expect(archive.files, hasLength(paths.length));
      expect(archive.files.map((entry) => entry.content), [
        [1, 2],
        [3, 4],
        [5, 6],
        [7, 8],
      ]);
      final names = archive.files.map((entry) => entry.name).toList();
      expect(names.map((name) => name.toLowerCase()).toSet(), hasLength(4));
      expect(names, containsAll(['same.png', 'same (2).png']));
      expect(names.every((name) => p.basename(name) == name), isTrue);
    });

    test('export preserves names without collisions; file=$toFile', () async {
      final archive = await export([
        await file('a/image.png', [1]),
        await file('b/image.jpg', [2]),
      ]);
      expect(archive.files.map((entry) => entry.name), [
        'image.png',
        'image.jpg',
      ]);
    });

    test(
      'a missing selected file fails the whole export; file=$toFile',
      () async {
        final paths = [
          await file('image.png', [1]),
          p.join(directory.path, 'missing.png'),
        ];
        await File(output).writeAsBytes([9, 8, 7]);
        if (toFile) {
          expect(await ZipUtils.createZipFromImages(paths, output), isFalse);
        } else {
          expect(await ZipUtils.createZipBytesFromImages(paths), isNull);
        }
        expect(await File(output).readAsBytes(), [9, 8, 7]);
      },
    );

    test('an empty selection produces no export; file=$toFile', () async {
      if (toFile) {
        expect(await ZipUtils.createZipFromImages([], output), isFalse);
      } else {
        expect(await ZipUtils.createZipBytesFromImages([]), isNull);
      }
      expect(await File(output).exists(), isFalse);
    });
  }

  test('progress counts every successfully archived selection', () async {
    final paths = [
      await file('a/x.png', [1]),
      await file('b/x.png', [2]),
    ];
    final progress = <(int, int)>[];
    expect(
      await ZipUtils.createZipFromImages(
        paths,
        output,
        onProgress: (current, total) => progress.add((current, total)),
      ),
      isTrue,
    );
    expect(progress, [(1, 2), (2, 2)]);
    expect(
      ZipDecoder().decodeBytes(await File(output).readAsBytes()).length,
      2,
    );
  });
}
