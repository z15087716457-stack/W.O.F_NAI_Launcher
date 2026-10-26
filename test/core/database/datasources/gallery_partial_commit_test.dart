import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/base_data_source.dart';
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
  final now = DateTime.utc(2026, 10, 25);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'gallery_partial_commit_',
    );
    await ConnectionPoolHolder.initialize(
      dbPath: p.join(directory.path, 'gallery.db'),
      maxConnections: 1,
    );
    source = GalleryDataSource();
    await source.initialize();
  });
  tearDown(() async {
    await Future<void>.delayed(Duration.zero);
    await source.dispose();
    await ConnectionPoolHolder.dispose();
    await directory.delete(recursive: true);
  });

  GalleryImageRecord record(String name) => GalleryImageRecord(
    filePath: p.join(directory.path, name),
    fileName: name,
    fileSize: 1,
    width: 1,
    height: 1,
    createdAt: now,
    modifiedAt: now,
    indexedAt: now,
    dateYmd: 20261025,
  );
  TagIndexImportEntry entry(String name) => TagIndexImportEntry(
    filePath: p.join(directory.path, name),
    fileName: name,
    fileSize: 1,
    modifiedAt: now,
    prompt: 'needle',
  );
  Future<void> sql(String statement) async {
    final pool = ConnectionPoolHolder.instance;
    final db = await pool.acquire();
    try {
      await db.execute(statement);
    } finally {
      await pool.release(db);
    }
  }

  test(
    'committed images invalidate a previously empty query when the next batch fails',
    () async {
      expect(await source.queryImages(), isEmpty);
      final before = source.dataRevision;
      await sql(
        "CREATE TRIGGER reject_image BEFORE INSERT ON gallery_images WHEN NEW.file_name='reject.png' BEGIN SELECT RAISE(ABORT,'fixture failure'); END",
      );
      await expectLater(
        source.batchUpsertImages([
          record('accepted.png'),
          record('reject.png'),
        ], batchSize: 1),
        throwsA(isA<DataSourceOperationException>()),
      );
      expect(source.dataRevision, greaterThan(before));
      expect((await source.queryImages()).map((image) => image.fileName), [
        'accepted.png',
      ]);
    },
  );

  test(
    'committed metadata invalidates text queries when the next batch fails',
    () async {
      final ids = await source.batchUpsertImages([
        record('a.png'),
        record('b.png'),
      ]);
      expect(await source.searchByMetadataText('needle'), isEmpty);
      final before = source.dataRevision;
      await sql(
        "CREATE TRIGGER reject_metadata BEFORE INSERT ON gallery_metadata WHEN NEW.image_id=${ids.last} BEGIN SELECT RAISE(ABORT,'fixture failure'); END",
      );
      await expectLater(
        source.batchUpsertMetadata([
          MapEntry(ids.first, const NaiImageMetadata(prompt: 'needle')),
          MapEntry(ids.last, const NaiImageMetadata(prompt: 'needle')),
        ], batchSize: 1),
        throwsA(isA<DataSourceOperationException>()),
      );
      expect(source.dataRevision, greaterThan(before));
      expect(await source.searchByMetadataText('needle'), [ids.first]);
      expect(await source.searchFullText('needle'), [ids.first]);
    },
  );

  test(
    'committed imported records invalidate queries when the next batch fails',
    () async {
      expect(await source.queryImages(), isEmpty);
      final before = source.dataRevision;
      await sql(
        "CREATE TRIGGER reject_image BEFORE INSERT ON gallery_images WHEN NEW.file_name='reject.png' BEGIN SELECT RAISE(ABORT,'fixture failure'); END",
      );
      await expectLater(
        source.importTagIndexEntries([
          entry('accepted.png'),
          entry('reject.png'),
        ], batchSize: 1),
        throwsA(isA<DataSourceOperationException>()),
      );
      expect(source.dataRevision, greaterThan(before));
      expect((await source.queryImages()).map((image) => image.fileName), [
        'accepted.png',
      ]);
    },
  );

  test(
    'committed membership removals invalidate the filter cache when a later chunk fails',
    () async {
      final records = List.generate(901, (i) => record('$i.png'));
      final ids = await source.batchUpsertImages(records, batchSize: 1000);
      final collection = await source.createCollection('fixture');
      final pool = ConnectionPoolHolder.instance;
      final db = await pool.acquire();
      try {
        final batch = db.batch();
        for (final id in ids) {
          batch.insert('gallery_collection_items', {
            'collection_id': collection,
            'image_id': id,
            'added_at': 1,
          });
        }
        await batch.commit(noResult: true);
      } finally {
        await pool.release(db);
      }
      final service = GalleryFilterService(source);
      final files = records.map((r) => File(r.filePath)).toList();
      final criteria = FilterCriteria(collectionId: collection);
      expect(
        (await service.applyFilters(files, criteria)).files,
        hasLength(901),
      );
      final before = source.dataRevision;
      await sql(
        "CREATE TRIGGER reject_removal BEFORE DELETE ON gallery_collection_items WHEN OLD.image_id=${ids.last} BEGIN SELECT RAISE(ABORT,'fixture failure'); END",
      );
      await expectLater(
        source.removeImagesFromAllCollections(ids),
        throwsA(isA<DataSourceOperationException>()),
      );
      expect(source.dataRevision, greaterThan(before));
      expect(
        (await service.applyFilters(files, criteria)).files.map((f) => f.path),
        [records.last.filePath],
      );
    },
  );

  for (final kind in [
    'images',
    'metadata',
    'import',
    'membership',
    'delete',
    'restore',
  ]) {
    test(
      'a $kind commit arriving after caller timeout still invalidates caches',
      () async {
        late Future<void> Function() run;
        late Future<int> Function() visibleCount;
        var expected = 1;
        if (kind == 'metadata') {
          final id = (await source.batchUpsertImages([
            record('late.png'),
          ])).single;
          expect(await source.searchByMetadataText('needle'), isEmpty);
          run = () => source.batchUpsertMetadata([
            MapEntry(id, const NaiImageMetadata(prompt: 'needle')),
          ]);
          visibleCount = () async =>
              (await source.searchByMetadataText('needle')).length;
        } else if (kind == 'membership') {
          final image = record('late.png');
          final id = (await source.batchUpsertImages([image])).single;
          final collection = await source.createCollection('fixture');
          await source.addImageToCollection(collection, id);
          final service = GalleryFilterService(source);
          final files = [File(image.filePath)];
          final criteria = FilterCriteria(collectionId: collection);
          expect(
            (await service.applyFilters(files, criteria)).files,
            hasLength(1),
          );
          run = () async {
            await source.removeImagesFromAllCollections([id]);
          };
          visibleCount = () async =>
              (await service.applyFilters(files, criteria)).files.length;
          expected = 0;
        } else if (kind == 'delete' || kind == 'restore') {
          final image = record('late.png');
          await source.batchUpsertImages([image]);
          if (kind == 'restore') {
            await source.batchMarkAsDeleted([image.filePath]);
          }
          expect(
            await source.queryImages(),
            hasLength(kind == 'restore' ? 0 : 1),
          );
          run = kind == 'delete'
              ? () => source.batchMarkAsDeleted([image.filePath])
              : () => source.batchRestoreDeleted([image.filePath]);
          visibleCount = () async => (await source.queryImages()).length;
          expected = kind == 'delete' ? 0 : 1;
        } else {
          expect(await source.queryImages(), isEmpty);
          if (kind == 'images') {
            run = () async {
              await source.batchUpsertImages([record('late.png')]);
            };
          } else {
            run = () async {
              await source.importTagIndexEntries([entry('late.png')]);
            };
          }
          visibleCount = () async => (await source.queryImages()).length;
        }
        final before = source.dataRevision;
        final task = runZoned<Future<void>>(
          run,
          zoneSpecification: ZoneSpecification(
            createTimer: (self, parent, zone, duration, callback) =>
                parent.createTimer(
                  zone,
                  duration == const Duration(seconds: 60) ||
                          duration == const Duration(seconds: 30)
                      ? Duration.zero
                      : duration,
                  callback,
                ),
          ),
        );
        await expectLater(task, throwsA(isA<DataSourceOperationException>()));
        final pool = ConnectionPoolHolder.instance;
        expect(pool.inUseCount, 1);
        // 单连接池只有在真实后台操作完成并归还后，下一次获取才会成功。
        final connection = await pool.acquire(
          timeout: const Duration(seconds: 2),
        );
        await pool.release(connection);
        expect(source.dataRevision, greaterThan(before));
        expect(await visibleCount(), expected);
      },
    );
  }

  test(
    'an atomic delete rollback keeps rows and the unchanged revision',
    () async {
      final records = [record('accepted.png'), record('reject.png')];
      await source.batchUpsertImages(records);
      expect(await source.queryImages(), hasLength(2));
      final before = source.dataRevision;
      await sql(
        "CREATE TRIGGER reject_delete BEFORE UPDATE ON gallery_images WHEN NEW.file_name='reject.png' AND NEW.is_deleted=1 BEGIN SELECT RAISE(ABORT,'fixture failure'); END",
      );
      await expectLater(
        source.batchMarkAsDeleted(records.map((r) => r.filePath).toList()),
        throwsA(isA<DataSourceOperationException>()),
      );
      expect(source.dataRevision, before);
      expect(await source.queryImages(), hasLength(2));
      expect(await source.getDeletedImagePaths(), isEmpty);
    },
  );
}
