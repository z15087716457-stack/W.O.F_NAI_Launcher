import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';

void main() {
  group('Gallery Search Behavior', () {
    late GalleryDataSource dataSource;
    late String testDbPath;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);

      final tempDir = Directory.systemTemp.createTempSync('gallery_search_');
      testDbPath = '${tempDir.path}/search_behavior.db';
    });

    tearDownAll(() async {
      await ConnectionPoolHolder.dispose();

      try {
        final dbFile = File(testDbPath);
        if (await dbFile.exists()) {
          await dbFile.delete();
        }

        final tempDir = Directory(testDbPath).parent;
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    setUp(() async {
      if (ConnectionPoolHolder.isInitialized) {
        await ConnectionPoolHolder.dispose();
      }

      final dbFile = File(testDbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      await ConnectionPoolHolder.initialize(
        dbPath: testDbPath,
        maxConnections: 2,
      );

      dataSource = GalleryDataSource();
      await dataSource.initialize();
    });

    tearDown(() async {
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();

      final dbFile = File(testDbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
    });

    test(
      'should find images by file name even when metadata is absent',
      () async {
        final now = DateTime.now();
        final imageId = await dataSource.upsertImage(
          filePath: '/test/special_character_pose.png',
          fileName: 'special_character_pose.png',
          fileSize: 2048,
          createdAt: now,
          modifiedAt: now,
        );

        final result = await dataSource.advancedSearch(
          textQuery: 'special_character',
          limit: 10,
        );

        expect(result, contains(imageId));
      },
    );

    test('should support prompt queries that use comma separators', () async {
      final now = DateTime.now();
      final imageId = await dataSource.upsertImage(
        filePath: '/test/comma_query.png',
        fileName: 'comma_query.png',
        fileSize: 1024,
        createdAt: now,
        modifiedAt: now,
      );

      await dataSource.upsertMetadata(
        imageId,
        const NaiImageMetadata(
          prompt: '1girl solo blue_eyes',
          negativePrompt: '',
          seed: 1,
        ),
      );

      final result = await dataSource.searchFullText('1girl,solo', limit: 10);

      expect(result, contains(imageId));
    });

    test('negative prompt text should not be searchable', () async {
      final now = DateTime.now();
      final imageId = await dataSource.upsertImage(
        filePath: '/test/uc_only.png',
        fileName: 'uc_only.png',
        fileSize: 1024,
        createdAt: now,
        modifiedAt: now,
      );

      await dataSource.upsertMetadata(
        imageId,
        const NaiImageMetadata(
          prompt: '1girl solo',
          negativePrompt: 'worst quality, watermark, cat_ears',
          seed: 1,
        ),
      );

      // 正向词照常命中（FTS + LIKE 两条路径都走 positive_prompt_text）
      expect(
        await dataSource.searchFullText('1girl', limit: 10),
        contains(imageId),
      );
      expect(
        await dataSource.searchByMetadataText('1girl', limit: 10),
        contains(imageId),
      );

      // 只出现在负面提示词里的词不命中
      expect(await dataSource.searchFullText('cat_ears', limit: 10), isEmpty);
      expect(
        await dataSource.searchByMetadataText('cat_ears', limit: 10),
        isEmpty,
      );
      expect(
        await dataSource.searchByMetadataText('watermark', limit: 10),
        isEmpty,
      );
    });

    test(
      'character prompts searchable but character negatives are not',
      () async {
        final now = DateTime.now();
        final imageId = await dataSource.upsertImage(
          filePath: '/test/v4_char.png',
          fileName: 'v4_char.png',
          fileSize: 1024,
          createdAt: now,
          modifiedAt: now,
        );

        // V4 Comment 信封：角色框正/负提示词只存在于 raw_json
        const rawJson = '''
        {
          "prompt": "masterpiece, 1girl",
          "v4_prompt": {
            "caption": {
              "base_caption": "masterpiece, 1girl",
              "char_captions": [
                {
                  "char_caption": "green_twintails, holding sword",
                  "centers": [{"x": 0.5, "y": 0.5}]
                }
              ]
            }
          },
          "v4_negative_prompt": {
            "caption": {
              "base_caption": "lowres, blurry",
              "char_captions": [
                {"char_caption": "missing_limbs, extra_fingers"}
              ]
            }
          },
          "model_name": "nai-diffusion-4-full"
        }
      ''';

        final parsed = NovelAiParser().parse({'Comment': rawJson});
        expect(parsed, isNotNull);
        expect(parsed!.characterPrompts, isNotEmpty);

        await dataSource.upsertMetadata(imageId, parsed);

        // 角色正向可搜（FTS 走 positive_prompt_text，含角色正向）
        expect(
          await dataSource.searchFullText('green_twintails', limit: 10),
          contains(imageId),
        );

        // 角色负面不命中（FTS 与 LIKE 双路）
        expect(
          await dataSource.searchFullText('missing_limbs', limit: 10),
          isEmpty,
        );
        expect(
          await dataSource.searchByMetadataText('extra_fingers', limit: 10),
          isEmpty,
        );
      },
    );

    test('delimited (comma) search ignores negative prompt', () async {
      final now = DateTime.now();
      final imageId = await dataSource.upsertImage(
        filePath: '/test/delim_neg.png',
        fileName: 'delim_neg.png',
        fileSize: 1024,
        createdAt: now,
        modifiedAt: now,
      );

      await dataSource.upsertMetadata(
        imageId,
        const NaiImageMetadata(
          prompt: '1girl, blue_eyes',
          negativePrompt: 'nsfw, monochrome',
          seed: 1,
        ),
      );

      // 正向片段命中
      expect(
        await dataSource.searchByDelimitedTextSegments([
          '1girl',
          'blue_eyes',
        ], limit: 10),
        contains(imageId),
      );
      // 负面片段不命中（旧口径在 negative_prompt 列上会误中）
      expect(
        await dataSource.searchByDelimitedTextSegments([
          'monochrome',
        ], limit: 10),
        isEmpty,
      );
    });

    test(
      'positive_prompt_text migration rebuilds FTS with positive-only text',
      () async {
        final now = DateTime.now();
        final imageId = await dataSource.upsertImage(
          filePath: '/test/migration.png',
          fileName: 'migration.png',
          fileSize: 1024,
          createdAt: now,
          modifiedAt: now,
        );

        await dataSource.upsertMetadata(
          imageId,
          const NaiImageMetadata(
            prompt: '1girl solo',
            negativePrompt: 'ugly_duplicate',
            seed: 1,
          ),
        );

        // 模拟迁移前状态：清标记 + 把 FTS 塞回旧的全量文本（含负面）
        await dataSource.execute('testStale', (db) async {
          await db.delete(
            'gallery_meta',
            where: 'key = ?',
            whereArgs: ['positive_search_text_v1'],
          );
          await db.delete('gallery_fts_index');
          await db.insert('gallery_fts_index', {
            'image_id': imageId,
            'prompt_text': '1girl solo ugly_duplicate',
          });
          await db.update(
            'gallery_metadata',
            {'positive_prompt_text': ''},
            where: 'image_id = ?',
            whereArgs: [imageId],
          );
        });

        // 迁移路径由 initialize → doInitialize 串起：ready 态下 initialize
        // 直接返回，先 dispose 再初始化以重跑迁移
        await dataSource.dispose();
        await dataSource.initialize();

        // FTS 已重建为正向口径：负面词不再命中
        expect(
          await dataSource.searchFullText('ugly_duplicate', limit: 10),
          isEmpty,
        );
        // 正向词照常命中
        expect(
          await dataSource.searchFullText('1girl', limit: 10),
          contains(imageId),
        );
      },
    );

    test(
      'should refresh cached search results after metadata indexing updates the same tag query',
      () async {
        final now = DateTime.now();
        final file = File('/test/cache_refresh.png');
        final imageId = await dataSource.upsertImage(
          filePath: file.path,
          fileName: 'cache_refresh.png',
          fileSize: 1024,
          createdAt: now,
          modifiedAt: now,
        );

        final filterService = GalleryFilterService(dataSource);

        final initialBareSearch = await filterService.applyFilters([
          file,
        ], const FilterCriteria(searchQuery: 'shycocoa'));

        expect(initialBareSearch.files, isEmpty);

        await dataSource.upsertMetadata(
          imageId,
          const NaiImageMetadata(
            prompt: 'artist:shycocoa, 1girl, solo',
            negativePrompt: '',
            seed: 1,
          ),
        );

        final prefixedSearch = await filterService.applyFilters([
          file,
        ], const FilterCriteria(searchQuery: 'artist:shycocoa'));
        final bareSearch = await filterService.applyFilters([
          file,
        ], const FilterCriteria(searchQuery: 'shycocoa'));

        expect(
          prefixedSearch.files.map((item) => item.path),
          contains(file.path),
        );
        expect(bareSearch.files.map((item) => item.path), contains(file.path));
        expect(bareSearch.files.length, equals(prefixedSearch.files.length));
      },
    );

    test(
      'literal SQL/FTS characters are bound and cache identity preserves comma AND',
      () async {
        final now = DateTime.now();
        final id = await dataSource.upsertImage(
          filePath: '/test/literal.png',
          fileName: 'literal.png',
          fileSize: 1,
          createdAt: now,
          modifiedAt: now,
        );
        await dataSource.upsertMetadata(
          id,
          const NaiImageMetadata(
            prompt: 'aokumo gap rin, 100% blue\\\\eyes, said "hi"',
          ),
        );
        expect(
          await dataSource.advancedSearch(textQuery: 'aokumo rin'),
          isEmpty,
        );
        expect(await dataSource.advancedSearch(textQuery: 'aokumo, rin'), [id]);
        expect(await dataSource.searchByMetadataText('aokumo rin'), isEmpty);
        expect(await dataSource.searchByMetadataText('aokumo,rin'), [id]);
        expect(
          await dataSource.advancedSearch(textQuery: '100% blue\\\\eyes'),
          [id],
        );
        expect(await dataSource.advancedSearch(textQuery: 'said "hi"'), [id]);
        expect(
          await dataSource.advancedSearch(textQuery: "' OR 1=1 --"),
          isEmpty,
        );
      },
    );

    test(
      'empty delimited segments stay empty rather than becoming an unfiltered database query',
      () async {
        expect(await dataSource.searchByDelimitedTextSegments([]), isEmpty);
        expect(
          await dataSource.searchByDelimitedTextSegments([' ', '']),
          isEmpty,
        );
      },
    );

    test('whole phrases do not OR words or prefix tokens', () async {
      final now = DateTime.now();
      final ids = <int>[];
      for (final prompt in [
        'aokumo rin',
        'aokumo_rin',
        'spring',
        'ring',
        'aokumo',
        'aokumo wearing',
      ]) {
        final id = await dataSource.upsertImage(
          filePath: '/test/phrase_${ids.length}.png',
          fileName: 'phrase_${ids.length}.png',
          fileSize: 1,
          createdAt: now,
          modifiedAt: now,
        );
        await dataSource.upsertMetadata(id, NaiImageMetadata(prompt: prompt));
        ids.add(id);
      }
      for (final query in ['aokumo rin', 'aokumo_rin', ' AOKUMO RIN ']) {
        expect(
          await dataSource.advancedSearch(textQuery: query),
          unorderedEquals(ids.take(2)),
        );
        expect(
          await dataSource.searchFullText(query),
          unorderedEquals(ids.take(2)),
        );
        expect(
          await dataSource.searchByMetadataText(query),
          unorderedEquals(ids.take(2)),
        );
      }
    });

    test(
      'known tags use full tag boundaries, retain parentheses and refresh mode cache',
      () async {
        final now = DateTime.now();
        final files = <File>[];
        final ids = <int>[];
        for (final prompt in [
          'blue eyes, solo',
          'blue eyes shadow, solo',
          'blue_eyes, landscape',
          'hero (game), solo',
          'hero game, solo',
        ]) {
          final file = File('/test/tag_${ids.length}.png');
          final id = await dataSource.upsertImage(
            filePath: file.path,
            fileName: 'tag_${ids.length}.png',
            fileSize: 1,
            createdAt: now,
            modifiedAt: now,
          );
          await dataSource.upsertMetadata(id, NaiImageMetadata(prompt: prompt));
          files.add(file);
          ids.add(id);
        }
        expect(
          await dataSource.advancedSearch(textQuery: 'blue eyes'),
          unorderedEquals(ids.take(3)),
        );
        await dataSource.addTag(ids.last, 'blue_eyes');
        await dataSource.addTag(ids.last, 'hero (game)');
        expect(
          await dataSource.advancedSearch(textQuery: 'blue eyes'),
          unorderedEquals([ids[0], ids[2], ids[4]]),
        );
        expect(
          await dataSource.advancedSearch(textQuery: '1.2::BLUE_EYES::, solo'),
          unorderedEquals([ids[0], ids[4]]),
        );
        expect(
          await dataSource.advancedSearch(textQuery: 'hero (game)'),
          unorderedEquals([ids[3], ids[4]]),
        );
        final result = await GalleryFilterService(dataSource).applyFilters(
          files,
          const FilterCriteria(selectedTags: ['blue eyes']),
        );
        expect(
          result.files.map((f) => f.path),
          unorderedEquals([files[0].path, files[2].path, files[4].path]),
        );
      },
    );

    test(
      'database search failures propagate instead of returning the whole gallery',
      () async {
        await dataSource.execute(
          'breakSearchFixture',
          (db) => db.execute('DROP TABLE gallery_metadata'),
        );
        final service = GalleryFilterService(dataSource);
        for (final criteria in [
          const FilterCriteria(searchQuery: 'needle'),
          const FilterCriteria(searchQuery: 'needle, solo'),
          const FilterCriteria(selectedTags: ['needle']),
        ]) {
          await expectLater(
            service.applyFilters([File('/test/a.png')], criteria),
            throwsA(anything),
          );
        }
      },
    );

    test(
      'should not truncate local gallery search results at 10000 items',
      () async {
        const totalImages = 10005;
        final now = DateTime.now();
        final imageRecords = List.generate(
          totalImages,
          (index) => GalleryImageRecord(
            filePath: '/test/search_limit_$index.png',
            fileName: 'search_limit_$index.png',
            fileSize: 1024 + index,
            createdAt: now,
            modifiedAt: now,
            indexedAt: now,
            dateYmd: 20260421,
          ),
        );

        final imageIds = await dataSource.batchUpsertImages(imageRecords);
        expect(imageIds.length, equals(totalImages));

        await dataSource.batchUpsertMetadata([
          for (var i = 0; i < imageIds.length; i++)
            MapEntry(
              imageIds[i],
              NaiImageMetadata(
                prompt: 'common search prompt $i',
                negativePrompt: '',
                seed: i,
              ),
            ),
        ]);

        final filterService = GalleryFilterService(dataSource);
        final result = await filterService.applyFilters([
          for (final record in imageRecords) File(record.filePath),
        ], const FilterCriteria(searchQuery: 'common'));

        expect(result.files.length, equals(totalImages));
        await dataSource.addTag(imageIds.first, 'common search prompt');
        await dataSource.batchUpsertMetadata([
          for (final id in imageIds)
            MapEntry(
              id,
              const NaiImageMetadata(prompt: 'common search prompt, solo'),
            ),
        ]);
        final exact = await filterService.applyFilters([
          for (final record in imageRecords) File(record.filePath),
        ], const FilterCriteria(searchQuery: 'common search prompt'));
        expect(exact.files.length, totalImages);
        expect(
          await dataSource.advancedSearch(
            textQuery: 'common search prompt',
            candidatePaths: imageRecords.map((r) => r.filePath).toList(),
            orderByColumn: 'file_size',
            orderAscending: true,
            limit: 2,
          ),
          imageIds.take(2),
        );
        expect(
          await dataSource.advancedSearch(
            textQuery: 'common search prompt',
            candidatePaths: [imageRecords.last.filePath],
            limit: 2,
          ),
          [imageIds.last],
        );
        final chips = await filterService.applyFilters([
          for (final record in imageRecords) File(record.filePath),
        ], const FilterCriteria(selectedTags: ['common_search_prompt']));
        expect(chips.files.length, totalImages);
      },
    );
  });
}
