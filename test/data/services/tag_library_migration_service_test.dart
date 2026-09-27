import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/tag_library_migration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late PromptBlockStorage storage;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'tag_library_migration_test_',
    );
    Hive.init(hiveDirectory.path);
    storage = PromptBlockStorage();
    await storage.init();
  });

  setUp(() async {
    await storage.clear();
    if (Hive.isBoxOpen(StorageKeys.settingsBox)) {
      await Hive.box(StorageKeys.settingsBox).clear();
    } else {
      await Hive.openBox(StorageKeys.settingsBox);
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  Future<void> writeLibrary({
    List<Map<String, dynamic>> entries = const [],
    List<Map<String, dynamic>> categories = const [],
  }) async {
    final box = Hive.box(StorageKeys.settingsBox);
    await box.put('tag_library_entries_data', jsonEncode(entries));
    await box.put('tag_library_categories_data', jsonEncode(categories));
  }

  Map<String, dynamic> entryJson(
    String id, {
    String name = 'entry',
    String content = 'content',
    String? categoryId,
    String? thumbnail,
    double thumbnailOffsetX = 0,
    double thumbnailOffsetY = 0,
    double thumbnailScale = 1,
    int useCount = 0,
    bool isFavorite = false,
    int sortOrder = 0,
    List<String> tags = const [],
    String createdAt = '2024-01-01T00:00:00.000',
    String updatedAt = '2024-02-01T00:00:00.000',
  }) {
    return {
      'id': id,
      'name': name,
      'content': content,
      'thumbnail': thumbnail,
      'thumbnailOffsetX': thumbnailOffsetX,
      'thumbnailOffsetY': thumbnailOffsetY,
      'thumbnailScale': thumbnailScale,
      'tags': tags,
      'categoryId': categoryId,
      'sortOrder': sortOrder,
      'useCount': useCount,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> categoryJson(
    String id,
    String name, {
    String? parentId,
    int sortOrder = 0,
  }) {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'sortOrder': sortOrder,
      'createdAt': '2024-01-01T00:00:00.000',
    };
  }

  TagLibraryMigrationService makeService({
    Future<String?> Function(String, String)? thumbnailImporter,
  }) {
    return TagLibraryMigrationService(
      blockStorage: storage,
      localStorage: LocalStorageService(),
      thumbnailImporter:
          thumbnailImporter ??
          (sourcePath, blockId) async => 'imported/$blockId.png',
    );
  }

  group('TagLibraryMigrationService', () {
    test(
      'migrates categories to folder tree and entries to blocks keeping ids',
      () async {
        await writeLibrary(
          categories: [
            categoryJson('cat-root', '画风'),
            categoryJson('cat-child', '画师集', parentId: 'cat-root'),
            // 同名分类不合并：两个「其他」各自成文件夹。
            categoryJson('cat-other-a', '其他', parentId: 'cat-root'),
            categoryJson('cat-other-b', '其他', parentId: 'cat-child'),
          ],
          entries: [
            entryJson(
              'e-1',
              name: 'W.O.F 干净可爱',
              content: 'artist:shion, best quality',
              categoryId: 'cat-child',
              thumbnail: 'C:/lib_thumbs/e-1.png',
              thumbnailOffsetX: 0.25,
              thumbnailOffsetY: -0.5,
              thumbnailScale: 1.6,
              useCount: 7,
              isFavorite: true,
              sortOrder: 3,
              tags: ['通用'],
            ),
            entryJson(
              'e-2',
              name: '无分类条目',
              content: 'orphan content',
              categoryId: 'ghost-cat',
            ),
          ],
        );

        await makeService().run();

        final data = await PromptBlockRepository(storage).load();
        expect(data.folders, hasLength(4));
        expect(data.blocks, hasLength(2));

        final child = data.getFolder('cat-child')!;
        expect(child.name, '画师集');
        expect(child.parentId, 'cat-root');
        // 同名文件夹各自保留。
        final others = data.folders.where((f) => f.name == '其他').toList();
        expect(others, hasLength(2));

        final block = data.getBlock('e-1')!;
        expect(block.title, 'W.O.F 干净可爱');
        expect(block.content, 'artist:shion, best quality');
        expect(block.folderId, 'cat-child');
        expect(block.thumbnail, 'imported/e-1.png');
        expect(block.thumbnailOffsetX, 0.25);
        expect(block.thumbnailOffsetY, -0.5);
        expect(block.thumbnailScale, 1.6);
        expect(block.useCount, 7);
        expect(block.isFavorite, isTrue);
        expect(block.tags.map((tag) => tag.name), ['通用']);
        expect(block.sortOrder, 3);
        expect(block.createdAt, DateTime.parse('2024-01-01T00:00:00.000'));
        expect(block.updatedAt, DateTime.parse('2024-02-01T00:00:00.000'));

        // 失效 categoryId 回退根目录。
        final orphan = data.getBlock('e-2')!;
        expect(orphan.folderId, isNull);

        // 旗标落盘，旧键保留（复制而非搬移）。
        expect(await storage.getMeta('tagLibraryMigrationDone'), '1');
        expect(
          Hive.box(StorageKeys.settingsBox).get('tag_library_entries_data'),
          isNotNull,
        );
      },
    );

    test('missing thumbnail source yields null thumbnail', () async {
      await writeLibrary(
        entries: [entryJson('e-1', thumbnail: 'C:/missing/x.png')],
      );
      await makeService(
        thumbnailImporter: (sourcePath, blockId) async => null,
      ).run();

      final data = await PromptBlockRepository(storage).load();
      expect(data.blocks.single.thumbnail, isNull);
    });

    test('root folders and blocks append after existing root order', () async {
      final repository = PromptBlockRepository(storage);
      await repository.createFolder(name: '既有文件夹');
      await repository.createBlock(title: '既有块', content: 'x');

      await writeLibrary(
        categories: [categoryJson('cat-a', '迁入')],
        entries: [entryJson('e-1', name: '迁入块')],
      );
      await makeService().run();

      final data = await PromptBlockRepository(storage).load();
      final migratedFolder = data.getFolder('cat-a')!;
      final existingFolder = data.folders.firstWhere((f) => f.name == '既有文件夹');
      expect(migratedFolder.sortOrder, greaterThan(existingFolder.sortOrder));

      final migratedBlock = data.getBlock('e-1')!;
      final existingBlock = data.blocks.firstWhere((b) => b.title == '既有块');
      expect(migratedBlock.sortOrder, greaterThan(existingBlock.sortOrder));
    });

    test(
      'flag short-circuits second run; rerun without flag converges',
      () async {
        await writeLibrary(entries: [entryJson('e-1', name: 'A')]);
        await makeService().run();
        var data = await PromptBlockRepository(storage).load();
        expect(data.blocks, hasLength(1));

        // 旗标短路：塞新数据也不再迁。
        await writeLibrary(entries: [entryJson('e-2', name: 'B')]);
        await makeService().run();
        data = await PromptBlockRepository(storage).load();
        expect(data.blocks, hasLength(1));

        // 模拟失败后重试：清旗标重跑，同 id 覆盖不产生重复。
        await storage.putMeta('tagLibraryMigrationDone', '');
        await writeLibrary(entries: [entryJson('e-1', name: 'A2')]);
        await makeService().run();
        data = await PromptBlockRepository(storage).load();
        expect(data.blocks, hasLength(1));
        expect(data.blocks.single.title, 'A2');
      },
    );

    test('failure leaves flag unset so next run retries', () async {
      await writeLibrary(entries: [entryJson('e-1', thumbnail: 'x.png')]);
      await makeService(
        thumbnailImporter: (sourcePath, blockId) =>
            throw StateError('disk gone'),
      ).run();

      expect(await storage.getMeta('tagLibraryMigrationDone'), isNot('1'));

      await makeService().run();
      expect(await storage.getMeta('tagLibraryMigrationDone'), '1');
      final data = await PromptBlockRepository(storage).load();
      expect(data.blocks.single.thumbnail, 'imported/e-1.png');
    });

    test('empty library still sets the flag', () async {
      await makeService().run();
      expect(await storage.getMeta('tagLibraryMigrationDone'), '1');
      final data = await PromptBlockRepository(storage).load();
      expect(data.blocks, isEmpty);
      expect(data.folders, isEmpty);
    });

    test('malformed json degrades to empty migration', () async {
      await Hive.box(
        StorageKeys.settingsBox,
      ).put('tag_library_entries_data', '{not a list');
      await makeService().run();
      expect(await storage.getMeta('tagLibraryMigrationDone'), '1');
      final data = await PromptBlockRepository(storage).load();
      expect(data.blocks, isEmpty);
    });
  });
}
