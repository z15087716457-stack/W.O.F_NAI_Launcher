import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/app_logger_test_isolation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    AppLoggerTestIsolation.setUp();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory directory;
  late GalleryDataSource source;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('gallery_scoped_search_');
    await ConnectionPoolHolder.initialize(
      dbPath: p.join(directory.path, 'gallery.db'),
      maxConnections: 2,
    );
    source = GalleryDataSource();
    await source.initialize();
  });
  tearDown(() async {
    await source.dispose();
    await ConnectionPoolHolder.dispose();
    await directory.delete(recursive: true);
  });

  Future<(File, int)> add(
    String folder,
    String name,
    int year, {
    String? prompt,
    int width = 100,
  }) async {
    final file = File(p.join(directory.path, folder, name));
    await file.parent.create(recursive: true);
    await file.writeAsBytes([1]);
    final id = await source.upsertImage(
      filePath: file.path,
      fileName: name,
      fileSize: 1,
      width: width,
      height: 100,
      createdAt: DateTime.utc(year),
      modifiedAt: DateTime.utc(year),
    );
    if (prompt != null) {
      await source.upsertMetadata(
        id,
        NaiImageMetadata(prompt: prompt, negativePrompt: 'negative-only'),
      );
    }
    return (file, id);
  }

  for (final channel in ['filename', 'metadata', 'fts stem']) {
    test(
      'older in-view $channel match survives newer outside matches',
      () async {
        final query = channel == 'fts stem' ? 'running' : 'needle';
        final word = channel == 'fts stem' ? 'run' : 'needle';
        final inside = await add(
          'current',
          channel == 'filename' ? 'needle_inside.png' : 'inside.png',
          2000,
          prompt: channel == 'filename'
              ? null
              : '$word ${List.filled(100, 'padding').join(' ')}',
        );
        for (var i = 0; i < 4; i++) {
          await add(
            'outside',
            channel == 'filename' ? 'needle_$i.png' : 'outside_$i.png',
            2020 + i,
            prompt: channel == 'filename' ? null : word,
          );
        }
        if (channel == 'filename') {
          expect(
            await source.searchByFileName(query, limit: 100),
            contains(inside.$2),
          );
        } else {
          expect(
            await source.searchFullText(query, limit: 100),
            contains(inside.$2),
          );
        }
        final result = await GalleryFilterService(
          source,
        ).applyFilters([inside.$1], FilterCriteria(searchQuery: query));
        expect(result.files.map((file) => file.path), [inside.$1.path]);
      },
    );
  }

  test(
    'attribute filters apply before the text limit even without a view scope',
    () async {
      final inside = await add(
        'current',
        'needle_inside.png',
        2000,
        width: 100,
      );
      for (var i = 0; i < 4; i++) {
        await add('outside', 'needle_$i.png', 2020 + i, width: 200);
      }
      expect(
        await source.advancedSearch(
          textQuery: 'needle',
          maxWidth: 100,
          limit: 1,
        ),
        [inside.$2],
      );
    },
  );

  test(
    'large candidate sets escape quotes, preserve Unicode paths and sorted limits',
    () async {
      final old = await add(
        'current',
        '奇怪 空格_%,😀.png',
        2000,
        prompt: 'needle',
      );
      final recent = await add('current', 'newer.png', 2001, prompt: 'needle');
      final outside = await add('outside', 'needle_newest.png', 2026);
      final candidates = [
        for (var i = 0; i < 1200; i++)
          p.join(directory.path, 'unindexed_$i.png'),
        p.join(directory.path, 'unindexed_"quote".png'),
        old.$1.path,
        recent.$1.path,
      ];
      final first = await source.advancedSearchResult(
        textQuery: 'needle',
        candidatePaths: candidates,
        orderByColumn: 'modified_at',
        orderAscending: true,
        limit: 1,
      );
      final last = await source.advancedSearchResult(
        textQuery: 'needle',
        candidatePaths: candidates,
        orderByColumn: 'modified_at',
        orderAscending: false,
        limit: 1,
      );
      expect(first.ids, [old.$2]);
      expect(first.filePaths, [old.$1.path]);
      expect(last.ids, [recent.$2]);
      expect(last.filePaths, [recent.$1.path]);
      expect(last.ids, isNot(contains(outside.$2)));
    },
  );

  test(
    'empty scopes stay empty and separate scope caches cannot mix',
    () async {
      final a = await add('a', 'needle_a.png', 2000);
      final b = await add('b', 'needle_b.png', 2026);
      expect(
        await source.advancedSearch(textQuery: 'needle', candidatePaths: []),
        isEmpty,
      );
      expect(
        await source.advancedSearch(
          textQuery: 'needle',
          candidatePaths: [a.$1.path],
        ),
        [a.$2],
      );
      expect(
        await source.advancedSearch(
          textQuery: 'needle',
          candidatePaths: [b.$1.path],
        ),
        [b.$2],
      );
      expect(
        await source.advancedSearch(
          textQuery: 'needle',
          candidatePaths: [a.$1.path],
        ),
        [a.$2],
      );
    },
  );
}
