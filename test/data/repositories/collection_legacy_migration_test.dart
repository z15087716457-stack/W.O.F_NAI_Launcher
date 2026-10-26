import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/data/models/gallery/image_collection.dart';
import 'package:nai_launcher/data/repositories/collection_repository.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/app_logger_test_isolation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const marker = 'collection_legacy_hive_migrated_v1';
  setUpAll(() {
    AppLoggerTestIsolation.setUp();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory directory;
  late GalleryDataSource source;
  late Box<dynamic> box;
  late SharedPreferences prefs;
  final repo = CollectionRepository.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    directory = await Directory.systemTemp.createTemp('collection_migration_');
    Hive.init(p.join(directory.path, 'hive'));
    box = await Hive.openBox(StorageKeys.collectionsBox);
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
    await Hive.close();
    await directory.delete(recursive: true);
  });
  Future<String> file(String name) async {
    final path = p.join(directory.path, name);
    await File(path).writeAsBytes([1, 2, 3]);
    return path;
  }

  Future<int> index(String path) => source.upsertImage(
    filePath: path,
    fileName: p.basename(path),
    fileSize: 3,
    createdAt: DateTime(2020),
    modifiedAt: DateTime(2026),
  );
  Future<void> legacy(
    String id,
    List<String> paths, {
    String name = 'legacy',
  }) => box.put(
    id,
    ImageCollection(
      id: id,
      name: name,
      imagePaths: paths,
      createdAt: DateTime(2020),
    ).toJson(),
  );
  Future<void> expectComplete(String id, List<int> members) async {
    expect(
      (await source.listCollectionsWithCounts()).map((c) => c.id),
      contains(id),
    );
    expect(await source.getCollectionImageIds(id), unorderedEquals(members));
    expect(box.isEmpty, isTrue);
    expect(prefs.getBool(marker), isTrue);
  }

  test(
    'unindexed existing files remain recoverable until the next initialization',
    () async {
      final path = await file('pending.png');
      await legacy('old', [path]);
      await repo.initialize();
      expect(box.length, 1);
      expect(prefs.getBool(marker), isNot(true));
      final id = await index(path);
      await repo.initialize();
      await expectComplete('old', [id]);
      expect(await source.listCollectionsWithCounts(), hasLength(1));
      await repo.initialize();
      await expectComplete('old', [id]);
    },
  );
  test(
    'partially indexed collections stay intact and migrate when all paths resolve',
    () async {
      final a = await file('a.png'), b = await file('b.png');
      final first = await index(a);
      await legacy('old', [a, b]);
      await repo.initialize();
      expect(box.length, 1);
      expect(await source.listCollectionsWithCounts(), isEmpty);
      final second = await index(b);
      await repo.initialize();
      await expectComplete('old', [first, second]);
    },
  );
  test(
    'existing current collections do not suppress legacy migration',
    () async {
      final current = await source.createCollection('current');
      final path = await file('old.png');
      final id = await index(path);
      await legacy('old', [path]);
      await repo.initialize();
      await expectComplete('old', [id]);
      expect(
        (await source.listCollectionsWithCounts()).map((c) => c.id),
        unorderedEquals([current, 'old']),
      );
    },
  );
  test(
    'a membership failure rolls back all targets and permits a clean retry',
    () async {
      final a = await file('a.png'), b = await file('b.png');
      final first = await index(a), second = await index(b);
      await legacy('old', [a, b]);
      await source.executeWrite(
        'fixture',
        (db) => db.execute(
          "CREATE TRIGGER fail_migration BEFORE INSERT ON gallery_collection_items WHEN NEW.image_id = $second BEGIN SELECT RAISE(ABORT, 'fixture failure'); END",
        ),
      );
      await repo.initialize();
      expect(box.length, 1);
      expect(prefs.getBool(marker), isNot(true));
      expect(await source.listCollectionsWithCounts(), isEmpty);
      await source.executeWrite(
        'fixture',
        (db) => db.execute('DROP TRIGGER fail_migration'),
      );
      await repo.initialize();
      await expectComplete('old', [first, second]);
      expect(await source.listCollectionsWithCounts(), hasLength(1));
    },
  );
  test(
    'pending Hive data is retried even if an older version set the marker',
    () async {
      final path = await file('old.png');
      final id = await index(path);
      await legacy('old', [path]);
      await prefs.setBool(marker, true);
      await repo.initialize();
      await expectComplete('old', [id]);
    },
  );
  test('an unopened source box is not marked complete', () async {
    final path = await file('old.png');
    final id = await index(path);
    await legacy('old', [path]);
    await box.close();
    await repo.initialize();
    expect(prefs.getBool(marker), isNot(true));
    box = await Hive.openBox(StorageKeys.collectionsBox);
    await repo.initialize();
    await expectComplete('old', [id]);
  });
  test(
    'retry after an earlier commit reuses the original id and preserves a newer name',
    () async {
      final path = await file('old.png');
      final id = await index(path);
      await legacy('old', [path]);
      await source.executeWrite(
        'fixture',
        (db) => db.insert('gallery_collections', {
          'id': 'old',
          'name': 'renamed target',
          'created_at': 1,
        }),
      );
      await source.addImageToCollection('old', id);
      await repo.initialize();
      await expectComplete('old', [id]);
      final collections = await source.listCollectionsWithCounts();
      expect(collections.single.name, 'renamed target');
    },
  );
  test('empty legacy collections are preserved', () async {
    await legacy('old', []);
    await repo.initialize();
    await expectComplete('old', []);
    expect((await source.listCollectionsWithCounts()).single.name, 'legacy');
  });
}
