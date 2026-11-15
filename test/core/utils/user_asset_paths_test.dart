import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/utils/gallery_storage_layout.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/core/utils/precise_ref_library_path_helper.dart';
import 'package:nai_launcher/core/utils/vibe_library_path_helper.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/repositories/gallery_folder_repository.dart';
import 'package:nai_launcher/data/services/precise_ref_library_storage_service.dart';
import 'package:nai_launcher/data/services/vibe_file_storage_service.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.root);
  final String root;
  @override
  Future<String?> getApplicationSupportPath() async =>
      p.join(root, 'user-data');
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      p.join(root, 'documents');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory temp;
  late Box settings;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('studio-asset-paths-');
    final original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(temp.path);
    addTearDown(() => PathProviderPlatform.instance = original);
    Hive.init(p.join(temp.path, 'hive'));
    settings = await Hive.openBox(StorageKeys.settingsBox);
    SharedPreferences.setMockInitialValues({});
    VibeLibraryPathHelper.instance.clearCache();
  });
  tearDown(() async {
    VibeLibraryPathHelper.instance.clearCache();
    await Hive.close();
    await temp.delete(recursive: true);
  });

  test(
    'new defaults share user-data and generated output includes Uncategorized',
    () async {
      final images = (await GalleryFolderRepository.instance.getRootPath())!;
      expect(images, p.join(temp.path, 'user-data', 'images'));
      expect(
        await VibeLibraryPathHelper.instance.getPath(),
        p.join(temp.path, 'user-data', 'vibes'),
      );
      expect(
        await PreciseRefLibraryPathHelper.instance.getPath(),
        p.join(temp.path, 'user-data', 'precise_refs'),
      );
      expect(await Directory(images).exists(), isFalse);
      final saved = await ImageSaveUtils.saveBytesToGalleryPath(
        rootPath: images,
        bytes: Uint8List.fromList([1, 2, 3]),
        seed: 42,
      );
      expect(p.dirname(saved), galleryUncategorizedPath(images));
      expect(await File(saved).readAsBytes(), [1, 2, 3]);
      expect(await Directory(p.join(temp.path, 'documents')).exists(), isFalse);
      expect(settings.get(StorageKeys.imageSavePath), isNull);
    },
  );

  test(
    'legacy gallery sources and category base remain while new output uses user-data',
    () async {
      final legacy = await Directory(
        p.join(temp.path, 'documents', 'NAI_Launcher', 'images'),
      ).create(recursive: true);
      final original = await File(
        p.join(legacy.path, '.gallery_categories.json'),
      ).writeAsString('original category ids');
      final repo = GalleryFolderRepository.instance;
      expect(
        await repo.getRootPath(),
        p.join(temp.path, 'user-data', 'images'),
      );
      expect(await repo.getCategoryBasePath(), legacy.path);
      expect(
        await repo.getSourcePaths(),
        containsAll([legacy.path, p.join(temp.path, 'user-data', 'images')]),
      );
      await repo.ensureSourcesMigrated();
      expect(settings.get(StorageKeys.galleryCategoryBasePath), legacy.path);
      expect(await original.readAsString(), 'original category ids');
      expect(
        await File(
          p.join(temp.path, 'user-data', 'images', '.gallery_categories.json'),
        ).exists(),
        isFalse,
      );
    },
  );

  test(
    'default Vibe discovery retains legacy metadata without copying or duplicating files',
    () async {
      final legacy = await Directory(
        p.join(temp.path, 'documents', 'NAI_Launcher', 'vibes'),
      ).create(recursive: true);
      final helper = VibeLibraryPathHelper.instance;
      await helper.setPath(legacy.path);
      const vibe = VibeReference(
        displayName: 'legacy',
        vibeEncoding: 'Zml4dHVyZQ==',
        sourceType: VibeSourceType.naiv4vibe,
      );
      final file = await VibeFileStorageService().saveVibeToFile(vibe);
      final older = await Directory(
        p.join(temp.path, 'documents', 'vibes'),
      ).create(recursive: true);
      await File(file).copy(p.join(older.path, p.basename(file)));
      final storage = VibeLibraryStorageService();
      addTearDown(storage.close);
      final entry = VibeLibraryEntry.fromVibeReference(
        name: 'legacy',
        vibeData: vibe,
        filePath: file,
        isFavorite: true,
      ).copyWith(tags: ['personal']);
      await storage.saveEntry(entry);
      await helper.resetToDefault();
      final result = await storage.syncWithFileSystem();
      expect(result.failedCount, 0);
      final kept = (await storage.getAllEntries()).single;
      expect(kept.id, entry.id);
      expect(kept.isFavorite, isTrue);
      expect(kept.tags, ['personal']);
      expect(kept.filePath, file);
      expect(await File(file).exists(), isTrue);
      expect(await Directory(await helper.getPath()).exists(), isFalse);
    },
  );

  test(
    'PR defaults and custom folders affect new imports while old originals remain readable',
    () async {
      final oldDirectory = p.join(
        temp.path,
        'documents',
        'NAI_Launcher',
        'precise_refs',
      );
      await settings.put(StorageKeys.preciseRefLibrarySavePath, oldDirectory);
      final storage = PreciseRefLibraryStorageService();
      addTearDown(storage.close);
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 8, height: 8)),
      );
      final old = await storage.importFromBytes(bytes, name: 'old');
      await settings.delete(StorageKeys.preciseRefLibrarySavePath);
      final current = await storage.importFromBytes(bytes, name: 'new');
      expect(p.dirname(old.imagePath), oldDirectory);
      expect(
        p.dirname(current.imagePath),
        p.join(temp.path, 'user-data', 'precise_refs'),
      );
      expect(await storage.readImageBytes(old.id), bytes);
      await storage.close();
      await storage.init();
      expect(await storage.readImageBytes(old.id), bytes);
      expect(await storage.readImageBytes(current.id), bytes);
      expect(await File(old.imagePath).exists(), isTrue);
      final custom = p.join(temp.path, 'chosen-pr');
      await settings.put(StorageKeys.preciseRefLibrarySavePath, custom);
      final next = await storage.importFromBytes(bytes, name: 'chosen');
      expect(p.dirname(next.imagePath), custom);
      expect(
        (await storage.getAllEntries()).map((e) => e.id),
        containsAll([old.id, current.id, next.id]),
      );
    },
  );

  test(
    'an unavailable default Vibe directory keeps its existing entries',
    () async {
      final helper = VibeLibraryPathHelper.instance;
      const vibe = VibeReference(
        displayName: 'kept',
        vibeEncoding: 'Zml4dHVyZQ==',
        sourceType: VibeSourceType.naiv4vibe,
      );
      final file = await VibeFileStorageService().saveVibeToFile(vibe);
      final storage = VibeLibraryStorageService();
      addTearDown(storage.close);
      final entry = VibeLibraryEntry.fromVibeReference(
        name: 'kept',
        vibeData: vibe,
        filePath: file,
      );
      await storage.saveEntry(entry);
      await Directory(
        await helper.getPath(),
      ).rename(p.join(temp.path, 'temporarily-offline'));
      final result = await storage.syncWithFileSystem();
      expect(result.failedCount, 1);
      expect((await storage.getAllEntries()).single.id, entry.id);
      expect(await Directory(await helper.getPath()).exists(), isFalse);
    },
  );
}
