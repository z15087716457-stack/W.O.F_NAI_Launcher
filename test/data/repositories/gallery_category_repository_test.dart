import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import 'package:nai_launcher/data/repositories/gallery_category_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory hiveTempDir;
  late Directory galleryRoot;
  late GalleryCategoryRepository repository;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    hiveTempDir = await Directory.systemTemp.createTemp(
      'nai_launcher_gallery_category_hive_',
    );
    galleryRoot = await Directory.systemTemp.createTemp(
      'nai_launcher_gallery_category_root_',
    );
    Hive.init(hiveTempDir.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.box(
      StorageKeys.settingsBox,
    ).put(StorageKeys.imageSavePath, galleryRoot.path);
    repository = GalleryCategoryRepository.instance;
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveTempDir.exists()) {
      await hiveTempDir.delete(recursive: true);
    }
    if (await galleryRoot.exists()) {
      await galleryRoot.delete(recursive: true);
    }
  });

  test(
    'sync does not recreate a category deleted while keeping its folder',
    () async {
      final folder = Directory(
        '${galleryRoot.path}${Platform.pathSeparator}keep',
      );
      await folder.create();

      final category = GalleryCategory.create(name: 'keep', folderPath: 'keep');

      final deleted = await repository.deleteCategory(category, [
        category,
      ], deleteFolder: false);
      expect(deleted, isTrue);

      final syncedCategories = await repository.syncWithFileSystem(const []);

      expect(syncedCategories, isEmpty);
      expect(await folder.exists(), isTrue);
    },
  );

  test('moveImageToCategory 成功移动图片到分类目录', () async {
    final srcFile = File(
      '${galleryRoot.path}${Platform.pathSeparator}test_move.png',
    );
    await srcFile.writeAsString('image data');

    final category = GalleryCategory.create(
      name: 'subcat',
      folderPath: 'subcat',
    );
    final result = await repository.moveImageToCategory(srcFile.path, category);

    expect(result, isNotNull);
    expect(await srcFile.exists(), isFalse);
    expect(await File(result!).exists(), isTrue);
  });

  test('外部源图片移入分类不再被拒绝', () async {
    final extraRoot = await Directory.systemTemp.createTemp('nai_extra_root_');
    addTearDown(() async {
      if (await extraRoot.exists()) await extraRoot.delete(recursive: true);
    });

    // 登记为 extra root
    await Hive.box(
      StorageKeys.settingsBox,
    ).put(StorageKeys.galleryExtraRoots, [extraRoot.path]);

    final extImg = File(
      '${extraRoot.path}${Platform.pathSeparator}external_img.png',
    );
    await extImg.writeAsString('external content');

    final category = GalleryCategory.create(
      name: 'target',
      folderPath: 'target',
    );
    final result = await repository.moveImageToCategory(extImg.path, category);

    expect(result, isNotNull);
    expect(await extImg.exists(), isFalse);
    expect(await File(result!).exists(), isTrue);
  });

  test('copyImageToCategory 复制图片到分类，源文件依然保留', () async {
    final srcFile = File(
      '${galleryRoot.path}${Platform.pathSeparator}test_copy.png',
    );
    await srcFile.writeAsString('image to copy');

    final category = GalleryCategory.create(
      name: 'copy_target',
      folderPath: 'copy_target',
    );
    final result = await repository.copyImageToCategory(srcFile.path, category);

    expect(result, isNotNull);
    expect(await srcFile.exists(), isTrue);
    expect(await File(result!).exists(), isTrue);
  });

  test('目标分类为外部图库源时允许 move 与 copy', () async {
    final extDir = await Directory.systemTemp.createTemp('nai_ext_target_');
    addTearDown(() async {
      if (await extDir.exists()) await extDir.delete(recursive: true);
    });

    // 绝对路径 folderPath 视为 external
    final externalCat = GalleryCategory.create(
      name: 'ExternalCat',
      folderPath: extDir.path,
    );
    expect(externalCat.isExternal, isTrue);

    // 1. move 到外部分类
    final srcFileMove = File(
      '${galleryRoot.path}${Platform.pathSeparator}src_for_ext_move.png',
    );
    await srcFileMove.writeAsString('data move');

    final moveRes = await repository.moveImageToCategory(
      srcFileMove.path,
      externalCat,
    );
    expect(moveRes, isNotNull);
    expect(await srcFileMove.exists(), isFalse);
    expect(await File(moveRes!).exists(), isTrue);
    expect(p.isWithin(extDir.path, moveRes), isTrue);

    // 2. copy 到外部分类
    final srcFileCopy = File(
      '${galleryRoot.path}${Platform.pathSeparator}src_for_ext_copy.png',
    );
    await srcFileCopy.writeAsString('data copy');

    final copyRes = await repository.copyImageToCategory(
      srcFileCopy.path,
      externalCat,
    );
    expect(copyRes, isNotNull);
    expect(await srcFileCopy.exists(), isTrue);
    expect(await File(copyRes!).exists(), isTrue);
    expect(p.isWithin(extDir.path, copyRes), isTrue);
  });
}
