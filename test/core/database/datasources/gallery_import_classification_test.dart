import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
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
    directory = await Directory.systemTemp.createTemp('gallery_import_rating_');
    await ConnectionPoolHolder.initialize(
      dbPath: p.join(directory.path, 'gallery.db'),
    );
    source = GalleryDataSource();
    await source.initialize();
  });
  tearDown(() async {
    await source.dispose();
    await ConnectionPoolHolder.dispose();
    await directory.delete(recursive: true);
  });

  TagIndexImportEntry entry(bool? nsfw, int index) => TagIndexImportEntry(
    filePath: p.join(directory.path, 'same.png'),
    fileName: 'same.png',
    fileSize: 1,
    modifiedAt: DateTime.utc(2026, 10, 25),
    prompt: 'entry$index',
    nsfw: nsfw,
  );

  final cases = <(bool?, List<bool?>, bool)>[
    (null, [true, null], true),
    (null, [true, null, false, null], false),
    (true, [null, null], true),
    (false, [true, null], true),
    (true, [false, null], false),
  ];
  for (final (initial, values, expected) in cases) {
    for (final batchSize in [1, 500]) {
      test('initial=$initial values=$values batch=$batchSize', () async {
        if (initial != null) {
          await source.importTagIndexEntries([entry(initial, -1)]);
        }
        final result = await source.importTagIndexEntries([
          for (var i = 0; i < values.length; i++) entry(values[i], i),
        ], batchSize: batchSize);
        expect(result.$1, initial == null ? 1 : 0);
        expect(result.$2, values.length - result.$1);
        final id = (await source.getImageIdByPath(entry(null, 0).filePath))!;
        expect(
          await source.advancedSearch(nsfwMode: expected ? 'nsfw' : 'sfw'),
          [id],
        );
        expect(
          await source.advancedSearch(nsfwMode: expected ? 'sfw' : 'nsfw'),
          isEmpty,
        );
        final metadata = (await source.getMetadataByImageIds([id]))[id]!;
        expect(metadata.prompt, 'entry${values.length - 1}');
      });
    }
  }
}
