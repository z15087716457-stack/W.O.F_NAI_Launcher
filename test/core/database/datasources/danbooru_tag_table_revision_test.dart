import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/connection_pool_lifecycle_manager.dart';
import 'package:nai_launcher/core/database/datasources/danbooru_tag_data_source.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/database/providers/database_state_providers.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/app_logger_test_isolation.dart';

/// Every write the app makes to danbooru_tags moves
/// [DanbooruTagDataSource.tableRevision]; a closed RAG worker wakes for the
/// tag index on that alone, not on danbooru.db, which every saved image
/// writes. The autocomplete migration is covered in
/// asset_database_manager_test.dart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    AppLoggerTestIsolation.setUp();
    sqfliteFfiInit();
  });
  tearDownAll(AppLoggerTestIsolation.tearDown);

  late Directory directory;
  late String path;
  late GalleryDataSource gallery;
  late DanbooruTagDataSource tags;

  const rain = DanbooruTagRecord(
    tag: 'rain',
    category: 0,
    postCount: 1200,
    lastUpdated: 0,
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('danbooru_tag_revision_');
    path = p.join(directory.path, 'danbooru.db');
    await ConnectionPoolHolder.initialize(dbPath: path, maxConnections: 2);
    gallery = GalleryDataSource();
    await gallery.initialize();
    tags = DanbooruTagDataSource();
    await tags.initialize();
  });
  tearDown(() async {
    await tags.dispose();
    await gallery.dispose();
    await ConnectionPoolHolder.dispose();
    await directory.delete(recursive: true);
  });

  test('each written tag sync batch moves it', () async {
    final before = DanbooruTagDataSource.tableRevision;
    await tags.upsertBatch(const []);
    expect(DanbooruTagDataSource.tableRevision, before, reason: 'no rows');
    await tags.upsertBatch([rain]);
    expect(DanbooruTagDataSource.tableRevision, before + 1);
    expect((await tags.getByName('rain'))?.postCount, 1200);
    await tags.upsertBatch([
      const DanbooruTagRecord(
        tag: 'rain',
        category: 0,
        postCount: 1300,
        lastUpdated: 0,
      ),
    ]);
    expect(DanbooruTagDataSource.tableRevision, before + 2);
  });

  test('a saved image or a tag lookup leaves it', () async {
    await tags.upsertBatch([rain]);
    final before = DanbooruTagDataSource.tableRevision;
    await gallery.upsertImage(
      filePath: p.join(directory.path, 'new.png'),
      fileName: 'new.png',
      fileSize: 1,
      createdAt: DateTime(2026),
      modifiedAt: DateTime(2026),
    );
    expect(await tags.search('ra'), hasLength(1));
    expect(await tags.getCount(), 1);
    expect(DanbooruTagDataSource.tableRevision, before);
  });

  test('clearing the tag cache moves it once the rows are gone', () async {
    await tags.upsertBatch([rain]);
    final before = DanbooruTagDataSource.tableRevision;
    final lifecycle = ConnectionPoolLifecycleManager();
    await lifecycle.initialize(dbPath: path, maxConnections: 2);
    final container = ProviderContainer(
      overrides: [connectionPoolLifecycleProvider.overrideWithValue(lifecycle)],
    );
    addTearDown(container.dispose);
    final result = await container
        .read(databaseStatusNotifierProvider.notifier)
        .clearCache(serviceClearCallback: null);
    expect(result.success, isTrue, reason: result.error);
    expect(result.tableStats, {'danbooru_tags': 1});
    expect(await tags.getCount(), 0);
    expect(DanbooruTagDataSource.tableRevision, before + 1);
  });
}
