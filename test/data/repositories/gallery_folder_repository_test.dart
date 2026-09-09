import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/repositories/gallery_folder_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory hiveTempDir;
  late Directory galleryRoot;
  late GalleryFolderRepository repository;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    hiveTempDir = await Directory.systemTemp.createTemp(
      'nai_launcher_gallery_folder_hive_',
    );
    galleryRoot = await Directory.systemTemp.createTemp(
      'nai_launcher_gallery_folder_root_',
    );
    Hive.init(hiveTempDir.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.box(
      StorageKeys.settingsBox,
    ).put(StorageKeys.imageSavePath, galleryRoot.path);
    repository = GalleryFolderRepository.instance;
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

  test('moveImageToFolder 成功移动图片且不被外部源拦截', () async {
    final extraRoot = await Directory.systemTemp.createTemp(
      'nai_extra_folder_',
    );
    addTearDown(() async {
      if (await extraRoot.exists()) await extraRoot.delete(recursive: true);
    });

    await Hive.box(
      StorageKeys.settingsBox,
    ).put(StorageKeys.galleryExtraRoots, [extraRoot.path]);

    final extImg = File(p.join(extraRoot.path, 'ext.png'));
    await extImg.writeAsString('external image');

    final targetFolder = Directory(p.join(galleryRoot.path, 'target_folder'));
    await targetFolder.create();

    final success = await repository.moveImageToFolder(
      extImg.path,
      targetFolder.path,
    );

    expect(success, isTrue);
    expect(await extImg.exists(), isFalse);
    expect(await File(p.join(targetFolder.path, 'ext.png')).exists(), isTrue);
  });

  test('copyImageToFolder 成功复制图片并保留源文件', () async {
    final srcImg = File(p.join(galleryRoot.path, 'src.png'));
    await srcImg.writeAsString('copy me');

    final targetFolder = Directory(p.join(galleryRoot.path, 'copy_dest'));
    await targetFolder.create();

    final success = await repository.copyImageToFolder(
      srcImg.path,
      targetFolder.path,
    );

    expect(success, isTrue);
    expect(await srcImg.exists(), isTrue);
    expect(await File(p.join(targetFolder.path, 'src.png')).exists(), isTrue);
  });

  test('copyImagesToFolder 批量复制图片', () async {
    final srcImg1 = File(p.join(galleryRoot.path, 'batch1.png'));
    final srcImg2 = File(p.join(galleryRoot.path, 'batch2.png'));
    await srcImg1.writeAsString('1');
    await srcImg2.writeAsString('2');

    final targetFolder = Directory(p.join(galleryRoot.path, 'batch_dest'));
    await targetFolder.create();

    final count = await repository.copyImagesToFolder([
      srcImg1.path,
      srcImg2.path,
    ], targetFolder.path);

    expect(count, 2);
    expect(await srcImg1.exists(), isTrue);
    expect(await srcImg2.exists(), isTrue);
    expect(
      await File(p.join(targetFolder.path, 'batch1.png')).exists(),
      isTrue,
    );
    expect(
      await File(p.join(targetFolder.path, 'batch2.png')).exists(),
      isTrue,
    );
  });
}
