import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/utils/gallery_storage_layout.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import 'package:nai_launcher/data/repositories/gallery_category_repository.dart';
import 'package:nai_launcher/data/repositories/gallery_folder_repository.dart';
import 'package:nai_launcher/data/services/gallery/gallery_file_changes.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/utils/gallery_category_label.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory workspace, sandbox, library, output;
  late Box box;
  final folders = GalleryFolderRepository.instance;
  final categories = GalleryCategoryRepository.forTesting();

  setUp(() async {
    workspace = await Directory(
      p.normalize(p.absolute('.dart_tool/gallery-sources-20261114/tests')),
    ).create(recursive: true);
    sandbox = await workspace.createTemp('case-');
    library = await Directory(p.join(sandbox.path, 'library')).create();
    output = await Directory(p.join(library.path, 'output')).create();
    final hive = await Directory(p.join(sandbox.path, 'hive')).create();
    Hive.init(hive.path);
    box = await Hive.openBox(StorageKeys.settingsBox);
    await box.put(StorageKeys.imageSavePath, output.path);
  });
  tearDown(() async {
    await Hive.close();
    expect(
      p.isWithin(
        await workspace.resolveSymbolicLinks(),
        await sandbox.resolveSymbolicLinks(),
      ),
      true,
    );
    await sandbox.delete(recursive: true);
  });

  test(
    'legacy parent/child sources collapse without moving or writing on read',
    () async {
      await box.put(StorageKeys.galleryExtraRoots, [library.path, output.path]);
      expect(await folders.getSourcePaths(), [library.path]);
      expect(box.get(StorageKeys.gallerySourcePaths), isNull);
      expect(await folders.getCategoryBasePath(), output.path);
      expect(await folders.isExternalPath(p.join(output.path, 'a.png')), false);
      expect(await folders.isExternalPath(p.join(library.path, 'a.png')), true);
      expect((await folders.getAllRootDirs()).map((d) => d.path), [
        library.path,
      ]);
    },
  );

  test(
    'every source, including output, can be removed; empty stays empty',
    () async {
      final file = await File(
        p.join(output.path, 'keep.png'),
      ).writeAsString('original');
      expect(await folders.removeSourcePath(output.path), true);
      expect(await folders.getSourcePaths(), isEmpty);
      expect(await folders.getAllRootDirs(), isEmpty);
      expect(box.get(StorageKeys.imageSavePath), output.path);
      expect(await file.readAsString(), 'original');
      expect(await folders.addSourcePath(output.path), true);
      expect(await folders.addSourcePath(p.join(output.path, 'nested')), false);
      expect(await folders.addSourcePath(library.path), true);
      expect(await folders.getSourcePaths(), [library.path]);
    },
  );

  test(
    'changing output retains browse coverage, category file and IDs',
    () async {
      final album = await Directory(p.join(output.path, 'album')).create();
      final item = GalleryCategory.create(name: 'album', folderPath: 'album');
      await categories.saveCategories([item]);
      final originalConfig = File(
        p.join(output.path, '.gallery_categories.json'),
      );
      final bytes = await originalConfig.readAsBytes();
      final next = await Directory(p.join(sandbox.path, 'new-output')).create();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(imageSaveSettingsNotifierProvider.notifier)
          .setCustomPath(next.path);
      expect(await folders.getRootPath(), next.path);
      expect(await folders.getSourcePaths(), [output.path]);
      expect(await categories.getRootPath(), output.path);
      expect((await categories.loadCategories()).single.id, item.id);
      expect(await categories.getCategoryAbsolutePath(item), album.path);
      expect(await originalConfig.readAsBytes(), bytes);
      expect(
        await File(p.join(next.path, '.gallery_categories.json')).exists(),
        false,
      );
    },
  );

  test(
    'overlapping legacy nodes retain every ID and the dedicated entry after events',
    () async {
      await box.put(StorageKeys.galleryExtraRoots, [library.path]);
      final dir = await Directory(
        galleryUncategorizedPath(output.path),
      ).create();
      final file = await File(
        p.join(dir.path, 'fixture.png'),
      ).writeAsString('unchanged');
      final first = await categories.syncWithFileSystem([]);
      final id = first.singleWhere((c) => c.isUncategorizedFolder).id;
      final ids = first.map((c) => c.id).toSet();
      await categories.saveCategories(first);
      final event = GalleryFileChanges()..files.add(file.path);
      final changed = await categories.syncChangedPaths(first, event);
      expect(changed.map((c) => c.id).toSet(), ids);
      expect(changed.singleWhere((c) => c.isUncategorizedFolder).id, id);
      await categories.saveCategories(changed);
      final reloaded = await categories.loadCategories();
      final rescanned = await categories.syncWithFileSystem(reloaded);
      expect(reloaded.map((c) => c.id).toSet(), ids);
      expect(rescanned.map((c) => c.id).toSet(), ids);
      expect(rescanned.singleWhere((c) => c.isUncategorizedFolder).id, id);
      expect(await file.readAsString(), 'unchanged');
    },
  );

  test(
    'a previously overwritten uncategorized record is repaired with its existing ID',
    () async {
      await box.put(StorageKeys.galleryExtraRoots, [library.path]);
      final dir = await Directory(
        galleryUncategorizedPath(output.path),
      ).create();
      final broken = GalleryCategory.create(
        name: 'Uncategorized',
        folderPath: dir.path,
        parentId: 'legacy-parent',
      );
      await categories.saveCategories([broken]);
      final loaded = await categories.loadCategories();
      expect(loaded.single.id, broken.id);
      expect(loaded.single.isUncategorizedFolder, true);
      final changed = await categories.syncChangedPaths(
        loaded,
        GalleryFileChanges(),
      );
      expect(changed.single.id, broken.id);
      expect(changed.single.isUncategorizedFolder, true);
    },
  );

  test(
    'remove/re-add hides and restores existing classification without deleting files or IDs',
    () async {
      await box.put(StorageKeys.galleryExtraRoots, [library.path]);
      final dir = await Directory(p.join(library.path, 'artist')).create();
      final picture = await File(
        p.join(dir.path, 'original.png'),
      ).writeAsString('original');
      final first = await categories.syncWithFileSystem([]);
      final ids = first.map((c) => c.id).toSet();
      await categories.saveCategories(first);
      expect(await folders.removeSourcePath(library.path), true);
      expect(await categories.loadCategories(), isEmpty);
      await categories.saveCategories(await categories.syncWithFileSystem([]));
      expect(await folders.addSourcePath(library.path), true);
      // The active UI may still have an empty snapshot when the source is re-added.
      final restored = await categories.syncWithFileSystem([]);
      expect(restored.map((c) => c.id).toSet(), ids);
      expect(await picture.readAsString(), 'original');
    },
  );
}
