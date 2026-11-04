import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/app_logger_test_isolation.dart';

/// Every write the app makes to the picture rows of danbooru.db
/// (gallery_images, gallery_metadata) moves [GalleryDataSource.imageRevision];
/// a closed RAG worker wakes for the gallery index on that alone, not on
/// danbooru.db, which favourites, collections and tags write as well.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    AppLoggerTestIsolation.setUp();
    sqfliteFfiInit();
  });
  tearDownAll(AppLoggerTestIsolation.tearDown);

  late Directory directory;
  late GalleryDataSource gallery;
  late int image;

  String file(String name) => p.join(directory.path, name);
  Future<int> save(String name) => gallery.upsertImage(
    filePath: file(name),
    fileName: name,
    fileSize: 1,
    createdAt: DateTime(2026),
    modifiedAt: DateTime(2026),
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'gallery_image_revision_',
    );
    await ConnectionPoolHolder.initialize(
      dbPath: file('danbooru.db'),
      maxConnections: 2,
    );
    gallery = GalleryDataSource();
    await gallery.initialize();
    image = await save('first.png');
  });
  tearDown(() async {
    await gallery.dispose();
    await ConnectionPoolHolder.dispose();
    await directory.delete(recursive: true);
  });

  test('each write to the picture rows moves it once it is done', () async {
    final writes = <(String, Future<void> Function())>[
      ('a saved image', () => save('second.png')),
      (
        'its parameters',
        () => gallery.upsertMetadata(
          image,
          const NaiImageMetadata(
            prompt: '1girl',
            source: 'NovelAI Diffusion V5 0ADF9AB7',
            software: 'NovelAI',
          ),
        ),
      ),
      (
        'models filled in from the fingerprint',
        () async => expect(await gallery.backfillModelColumn(), 1),
      ),
      (
        'parameters of a scan batch',
        () => gallery.batchUpsertMetadata([
          MapEntry(image, const NaiImageMetadata(prompt: 'rain')),
        ]),
      ),
      (
        'a scan batch',
        () => gallery.batchUpsertImages([
          GalleryImageRecord(
            filePath: file('third.png'),
            fileName: 'third.png',
            fileSize: 1,
            modifiedAt: DateTime(2026),
            createdAt: DateTime(2026),
            indexedAt: DateTime(2026),
            dateYmd: 20260101,
          ),
        ]),
      ),
      ('moved', () => gallery.updateFilePath(image, file('moved.png'))),
      ('deleted', () => gallery.markAsDeleted(file('moved.png'))),
      ('restored', () => gallery.batchRestoreDeleted([file('moved.png')])),
      (
        'deleted in a batch',
        () => gallery.batchMarkAsDeleted([file('moved.png')]),
      ),
      (
        'its folder renamed',
        () async => expect(
          await gallery.relocateDirectoryRecords(
            directory.path,
            p.join(directory.path, 'renamed'),
          ),
          greaterThan(0),
        ),
      ),
      (
        'an index import',
        () => gallery.importTagIndexEntries([
          TagIndexImportEntry(
            filePath: file('import.png'),
            fileName: 'import.png',
            fileSize: 1,
            modifiedAt: DateTime(2026),
          ),
        ]),
      ),
      ('all parameters cleared', gallery.deleteAllMetadata),
      ('all pictures cleared', gallery.deleteAllImages),
    ];
    for (final (write, apply) in writes) {
      final before = GalleryDataSource.imageRevision;
      await apply();
      expect(GalleryDataSource.imageRevision, before + 1, reason: write);
    }
  });

  test('favourites, collections and tags leave it', () async {
    final collection = await gallery.createCollection('Picks');
    final folder = await gallery.createCollection('Weather', isFolder: true);
    final writes = <(String, Future<void> Function())>[
      ('favourite', () => gallery.toggleFavorite(image)),
      ('unfavourite', () => gallery.toggleFavorite(image)),
      ('favourite once', () => gallery.addFavorite(image)),
      ('favourites removed', () => gallery.removeFavorites([image])),
      ('a new collection', () => gallery.createCollection('More')),
      ('renamed', () => gallery.renameCollection(collection, 'Best')),
      (
        'added to a collection',
        () => gallery.addImageToCollection(collection, image),
      ),
      (
        'removed from it',
        () => gallery.removeImageFromCollection(collection, image),
      ),
      ('added again', () => gallery.addImageToCollection(collection, image)),
      (
        'removed from all collections',
        () => gallery.removeImagesFromAllCollections([image]),
      ),
      ('moved into a folder', () => gallery.moveCollection(collection, folder)),
      (
        'reordered',
        () => gallery.reorderCollections([collection], parentId: folder),
      ),
      ('deleted', () => gallery.deleteCollection(collection)),
      ('tagged', () => gallery.addTag(image, 'rain')),
      ('its tags set', () => gallery.setImageTags(image, ['snow', 'night'])),
      ('untagged', () => gallery.removeTag(image, 'snow')),
    ];
    for (final (write, apply) in writes) {
      final before = GalleryDataSource.imageRevision;
      final shown = gallery.dataRevision;
      await apply();
      expect(gallery.dataRevision, greaterThan(shown), reason: '$write wrote');
      expect(GalleryDataSource.imageRevision, before, reason: write);
    }
  });
}
