import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/base_data_source.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/danbooru_tag_data_source.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/app_logger_test_isolation.dart';

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
  late DanbooruTagDataSource tags;
  late int imageId;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sqlite_writer_');
    await ConnectionPoolHolder.initialize(
      dbPath: p.join(directory.path, 'gallery.db'),
      maxConnections: 2,
    );
    source = GalleryDataSource();
    await source.initialize();
    tags = DanbooruTagDataSource();
    await tags.initialize();
    imageId = await source.upsertImage(
      filePath: p.join(directory.path, 'existing.png'),
      fileName: 'existing.png',
      fileSize: 1,
      createdAt: DateTime(2026),
      modifiedAt: DateTime(2026),
    );
    final pool = ConnectionPoolHolder.instance;
    final connections = [await pool.acquire(), await pool.acquire()];
    for (final db in connections) {
      await db.execute('PRAGMA busy_timeout = 30');
    }
    await connections.first.execute(
      'CREATE TABLE fixture_counter (value INTEGER NOT NULL)',
    );
    await connections.first.rawInsert('INSERT INTO fixture_counter VALUES (0)');
    for (final db in connections) {
      await pool.release(db);
    }
  });
  tearDown(() async {
    await tags.dispose();
    await source.dispose();
    await ConnectionPoolHolder.dispose();
    await directory.delete(recursive: true);
  });

  Future<int> upsert() => source.upsertImage(
    filePath: p.join(directory.path, 'new.png'),
    fileName: 'new.png',
    fileSize: 1,
    createdAt: DateTime(2026),
    modifiedAt: DateTime(2026),
  );
  Future<int> value() => source.execute(
    'readCounter',
    (db) async =>
        (await db.rawQuery('SELECT value FROM fixture_counter')).single['value']
            as int,
  );

  Future<void> overlap(Future<Object?> Function() second) async {
    final started = Completer<void>(), release = Completer<void>();
    final first = source.executeTransaction('heldWriter', (txn) async {
      await txn.rawUpdate('UPDATE fixture_counter SET value = value + 1');
      started.complete();
      await release.future;
    });
    await started.future;
    final timer = Timer(const Duration(milliseconds: 10), release.complete);
    try {
      await second();
      await first;
      expect(await value(), 1);
    } finally {
      if (!release.isCompleted) release.complete();
      await first;
      timer.cancel();
    }
  }

  test(
    'single image write waits for the active transaction',
    () => overlap(upsert),
  );
  test(
    'favorite write waits for the active transaction',
    () => overlap(() => source.toggleFavorite(imageId)),
  );
  test(
    'collection write waits for the active transaction',
    () => overlap(() => source.createCollection('new')),
  );
  test(
    'import transaction waits for the active transaction',
    () => overlap(
      () => source.importTagIndexEntries([
        TagIndexImportEntry(
          filePath: p.join(directory.path, 'import.png'),
          fileName: 'import.png',
          fileSize: 1,
          modifiedAt: DateTime(2026),
        ),
      ]),
    ),
  );
  test(
    'statistics transaction waits for the active transaction',
    () => overlap(source.getStatisticsSignature),
  );
  test(
    'another data source shares the database writer boundary',
    () => overlap(() async {
      await tags.upsertBatch([
        const DanbooruTagRecord(
          tag: 'fixture',
          category: 0,
          postCount: 1,
          lastUpdated: 1,
        ),
      ]);
      return null;
    }),
  );

  test(
    'timeout keeps writer ownership until the actual transaction ends',
    () async {
      final started = Completer<void>(), release = Completer<void>();
      final first = source.executeTransaction('timedWriter', (txn) async {
        await txn.rawUpdate('UPDATE fixture_counter SET value = value + 1');
        started.complete();
        await release.future;
      }, timeout: const Duration(milliseconds: 5));
      final observed = expectLater(
        first,
        throwsA(isA<DataSourceOperationException>()),
      );
      await started.future;
      await observed;
      final timer = Timer(const Duration(milliseconds: 10), release.complete);
      try {
        await upsert();
        expect(await value(), 1);
      } finally {
        if (!release.isCompleted) release.complete();
        timer.cancel();
      }
    },
  );

  test('ordinary WAL readers remain independent of the writer', () async {
    final started = Completer<void>(), release = Completer<void>();
    final first = source.executeTransaction('heldWriter', (txn) async {
      await txn.rawUpdate('UPDATE fixture_counter SET value = value + 1');
      started.complete();
      await release.future;
    });
    await started.future;
    try {
      expect(await value().timeout(const Duration(milliseconds: 500)), 0);
    } finally {
      release.complete();
      await first;
    }
    expect(await value(), 1);
  });

  test('two concurrent favorite toggles apply in order', () async {
    expect(
      await Future.wait([
        source.toggleFavorite(imageId),
        source.toggleFavorite(imageId),
      ]),
      [true, false],
    );
    expect(await source.isFavorite(imageId), isFalse);
  });
}
