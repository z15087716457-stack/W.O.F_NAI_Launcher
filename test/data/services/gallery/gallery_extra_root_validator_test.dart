import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/gallery/gallery_extra_root_validator.dart';
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
      await validateGalleryExtraRoot(
        selectedPath: otherRoot.path,
        mainRoot: mainRoot.path,
        existingRoots: [extraRoot.path],
      ),
      isNull,
    );
  });

  test('rejects missing, main and duplicate folders', () async {
    Future<GalleryExtraRootValidationError?> validate(String path) =>
        validateGalleryExtraRoot(
          selectedPath: path,
          mainRoot: mainRoot.path,
          existingRoots: [extraRoot.path],
        );

    expect(
      await validate(p.join(sandbox.path, 'missing')),
      GalleryExtraRootValidationError.notFound,
    );
    expect(
      await validate(mainRoot.path),
      GalleryExtraRootValidationError.sameAsMain,
    );
    expect(
      await validate(p.join(extraRoot.path, '.')),
      GalleryExtraRootValidationError.duplicate,
    );
  });

  test('rejects overlap with the main or another extra source', () async {
    final mainChild = await Directory(p.join(mainRoot.path, 'child')).create();
    final extraChild = await Directory(
      p.join(extraRoot.path, 'child'),
    ).create();

    Future<GalleryExtraRootValidationError?> validate(String path) =>
        validateGalleryExtraRoot(
          selectedPath: path,
          mainRoot: mainRoot.path,
          existingRoots: [extraRoot.path],
        );

    expect(
      await validate(mainChild.path),
      GalleryExtraRootValidationError.nested,
    );
    expect(
      await validate(extraChild.path),
      GalleryExtraRootValidationError.nested,
    );
    expect(
      await validate(sandbox.path),
      GalleryExtraRootValidationError.nested,
    );
  });
}
