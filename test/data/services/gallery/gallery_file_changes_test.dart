import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/gallery/gallery_file_changes.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_stream_scanner.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/data/services/image_metadata_service.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';

void main() {
  late Directory temp, root;
  late GalleryDataSource db;
  late LocalGalleryServiceImpl service;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppLogger.initialize(isTestEnvironment: true);
  });
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('gallery_file_changes_');
    root = await Directory(p.join(temp.path, 'images')).create();
    Hive.init(p.join(temp.path, 'hive'));
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.box(
      StorageKeys.settingsBox,
    ).put(StorageKeys.imageSavePath, root.path);
    await ConnectionPoolHolder.initialize(
      dbPath: p.join(temp.path, 'gallery.db'),
      maxConnections: 2,
    );
    db = GalleryDataSource();
    await db.initialize();
    await ImageMetadataService().initialize();
    GalleryStreamScanner.resetInstance();
    service = LocalGalleryServiceImpl(
      dataSource: db,
      filterService: GalleryFilterService(db),
    );
  });
  tearDown(() async {
    await service.dispose();
    GalleryStreamScanner.resetInstance();
    await db.dispose();
    await ConnectionPoolHolder.dispose();
    await Hive.close();
    await temp.delete(recursive: true);
  });
  Future<File> write(String name, String prompt) async {
    final file = File(p.join(root.path, name));
    await file.parent.create(recursive: true);
    var bytes = img.encodePng(img.Image(width: 4, height: 4));
    for (final entry in {
      'Title': 'NovelAI generated image',
      'Description': prompt,
      'Software': 'NovelAI',
      'Source': 'NovelAI Diffusion V4.5 4BDE2A90',
      'Comment': jsonEncode({
        'Description': prompt,
        'Software': 'NovelAI',
        'Comment': jsonEncode({
          'prompt': prompt,
          'width': 4,
          'height': 4,
          'steps': 28,
          'sampler': 'k_euler',
          'scale': 6.5,
        }),
      }),
    }.entries) {
      bytes = UnifiedMetadataParser.embedTextChunkOnly(
        bytes,
        entry.key,
        entry.value,
      );
    }
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<int> seed(File file, {bool favorite = false}) async {
    final stat = await file.stat();
    return db.upsertImage(
      filePath: file.path,
      fileName: p.basename(file.path),
      fileSize: stat.size,
      createdAt: stat.modified,
      modifiedAt: stat.modified,
      lastScannedAt: DateTime.now(),
      width: 100,
      height: 200,
      metadataStatus: MetadataStatus.success,
      isFavorite: favorite,
    );
  }

  test(
    'only event files change; unchanged dimensions and current filter survive',
    () async {
      final stable = await write('stable.png', 'stable');
      final edited = await write('edited.png', 'before');
      final stableId = await seed(stable);
      final editedId = await seed(edited, favorite: true);
      await service.initialize();
      await service.getTimelineEntries();
      // A DB-only dimension change must not invalidate the unrelated path cache.
      await db.execute(
        'testDimensions',
        (connection) => connection.update(
          'gallery_images',
          {'width': 900},
          where: 'id = ?',
          whereArgs: [stableId],
        ),
      );
      await write('edited.png', 'changed prompt with more bytes');
      await service.applyFilter(const FilterCriteria(searchQuery: 'edited'));
      final changes = GalleryFileChanges()..files.add(edited.path);
      expect(await service.applyFileChanges(changes), {edited.path});
      expect(service.currentFilter.searchQuery, 'edited');
      expect((await service.getTimelineEntries()).map((e) => e.path), [
        edited.path,
      ]);
      final after = await db.getImageById(editedId);
      expect(after!.isFavorite, isTrue);
      final metadata = await service.getMetadata(edited.path);
      expect(metadata!.prompt, 'changed prompt with more bytes');
      await service.clearFilters();
      final timeline = await service.getTimelineEntries();
      expect(timeline.firstWhere((e) => e.path == stable.path).width, 100);
      expect(await service.applyFileChanges(changes), isEmpty);
    },
  );

  test(
    'rename preserves identity/favorite, deletion and additions update only event paths',
    () async {
      final old = await write('old.png', 'old');
      final keep = await write('keep.png', 'keep');
      final id = await seed(old, favorite: true);
      await seed(keep);
      await service.initialize();
      final renamed = await old.rename(p.join(root.path, 'renamed.png'));
      final added = await write('added.png', 'added');
      await keep.delete();
      final changes = GalleryFileChanges()
        ..files.addAll([old.path, renamed.path, added.path, keep.path]);
      await service.applyFileChanges(changes);
      expect(await db.getImageIdByPath(renamed.path), id);
      expect((await db.getImageById(id))!.isFavorite, isTrue);
      expect((await service.getTimelineEntries()).map((e) => e.path).toSet(), {
        renamed.path,
        added.path,
      });
      expect((await db.getDeletedImagePaths()), contains(keep.path));
    },
  );

  test(
    'directory move retains soft deletion and all active image IDs',
    () async {
      final active = await write('old/a.png', 'active');
      final deleted = await write('old/deleted.png', 'deleted');
      final id = await seed(active, favorite: true);
      await seed(deleted);
      await service.initialize();
      await db.markAsDeleted(deleted.path);
      service.removeImagesFromMemory([deleted.path]);
      final oldDir = p.dirname(active.path), newDir = p.join(root.path, 'new');
      await Directory(oldDir).rename(newDir);
      final changes = GalleryFileChanges()
        ..directories.addAll([oldDir, newDir])
        ..directoryMoves[oldDir] = newDir;
      await service.applyFileChanges(changes);
      final newPath = p.join(newDir, 'a.png');
      expect(await db.getImageIdByPath(newPath), id);
      expect((await service.getTimelineEntries()).map((e) => e.path), [
        newPath,
      ]);
      expect(
        await db.getDeletedImagePaths(),
        contains(p.join(newDir, 'deleted.png')),
      );
    },
  );
}
