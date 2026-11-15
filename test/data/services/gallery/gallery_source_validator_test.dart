import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/gallery/gallery_source_validator.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory sandbox;
  late Directory mainRoot;
  late Directory extraRoot;
  late Directory otherRoot;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('gallery_extra_root_');
    mainRoot = await Directory(p.join(sandbox.path, 'main')).create();
    extraRoot = await Directory(p.join(sandbox.path, 'extra')).create();
    otherRoot = await Directory(p.join(sandbox.path, 'other')).create();
  });

  tearDown(() async {
    await sandbox.delete(recursive: true);
  });

  test('accepts an independent existing folder', () async {
    expect(
      await validateGallerySource(
        selectedPath: otherRoot.path,
        existingRoots: [extraRoot.path],
      ),
      isNull,
    );
  });

  test(
    'rejects missing and duplicate folders but accepts the output location',
    () async {
      Future<GallerySourceValidationError?> validate(String path) =>
          validateGallerySource(
            selectedPath: path,
            existingRoots: [extraRoot.path],
          );

      expect(
        await validate(p.join(sandbox.path, 'missing')),
        GallerySourceValidationError.notFound,
      );
      expect(await validate(mainRoot.path), isNull);
      expect(
        await validate(p.join(extraRoot.path, '.')),
        GallerySourceValidationError.duplicate,
      );
    },
  );

  test('rejects covered children and accepts a wider parent', () async {
    final mainChild = await Directory(p.join(mainRoot.path, 'child')).create();
    final extraChild = await Directory(
      p.join(extraRoot.path, 'child'),
    ).create();

    Future<GallerySourceValidationError?> validate(String path) =>
        validateGallerySource(
          selectedPath: path,
          existingRoots: [extraRoot.path],
        );

    expect(await validate(mainChild.path), isNull);
    expect(
      await validate(extraChild.path),
      GallerySourceValidationError.covered,
    );
    expect(await validate(sandbox.path), isNull);
  });
}
