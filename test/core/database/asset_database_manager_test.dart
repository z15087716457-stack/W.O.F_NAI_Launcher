import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/asset_database_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory appSupportDir;
  late Map<String, int> assetLoadCounts;
  late Map<String, Uint8List> assets;
  late Map<String, dynamic> manifest;

  setUp(() async {
    AssetDatabaseManager.resetForTesting();
    tempDir = await Directory.systemTemp.createTemp(
      'asset_database_manager_test_',
    );
    appSupportDir = await Directory(
      p.join(tempDir.path, 'app_support'),
    ).create(recursive: true);
    PathProviderPlatform.instance = _TestPathProviderPlatform(
      appSupportPath: appSupportDir.path,
    );

    final catalog = await _createCatalogFixture(tempDir.path);
    final cooccurrence = await _createCooccurrenceFixture(tempDir.path);
    final wiki = await _createWikiFixture(tempDir.path);
    final semantics = await _createSemanticsFixture(tempDir.path);
    final catalogBytes = await catalog.readAsBytes();
    final cooccurrenceBytes = await cooccurrence.readAsBytes();
    final wikiBytes = await wiki.readAsBytes();
    final semanticsBytes = await semantics.readAsBytes();
    manifest = {
      'databases': {
        AssetDatabaseManager.tagCatalogDb: {
          'schemaVersion': 1,
          'dataVersion': 'test-data',
          'sha256': sha256.convert(catalogBytes).toString(),
          'size': catalogBytes.length,
        },
        AssetDatabaseManager.cooccurrenceDb: {
          'schemaVersion': 1,
          'dataVersion': 'test-data',
          'sha256': sha256.convert(cooccurrenceBytes).toString(),
          'size': cooccurrenceBytes.length,
        },
        AssetDatabaseManager.tagWikiDb: {
          'schemaVersion': 1,
          'dataVersion': 'test-data',
          'sha256': sha256.convert(wikiBytes).toString(),
          'size': wikiBytes.length,
        },
        AssetDatabaseManager.tagSemanticsDb: {
          'schemaVersion': 1,
          'dataVersion': 'test-data',
          'sha256': sha256.convert(semanticsBytes).toString(),
          'size': semanticsBytes.length,
        },
      },
    };
    assets = {
      'assets/databases/manifest.json': Uint8List.fromList(
        utf8.encode(jsonEncode(manifest)),
      ),
      'assets/databases/${AssetDatabaseManager.tagCatalogDb}': catalogBytes,
      'assets/databases/${AssetDatabaseManager.cooccurrenceDb}':
          cooccurrenceBytes,
      'assets/databases/${AssetDatabaseManager.tagWikiDb}': wikiBytes,
      'assets/databases/${AssetDatabaseManager.tagSemanticsDb}': semanticsBytes,
    };
    assetLoadCounts = <String, int>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(
            message!.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );
          assetLoadCounts[key] = (assetLoadCounts[key] ?? 0) + 1;
          final value = assets[key];
          if (value == null) return null;
          return ByteData.sublistView(value);
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('reuses a validated local database matching the manifest', () async {
    final dbDir = await Directory(
      p.join(appSupportDir.path, 'asset_databases'),
    ).create(recursive: true);
    final databases = manifest['databases'] as Map<String, dynamic>;
    for (final name in [
      AssetDatabaseManager.tagCatalogDb,
      AssetDatabaseManager.cooccurrenceDb,
    ]) {
      final target = File(p.join(dbDir.path, name));
      await target.writeAsBytes(assets['assets/databases/$name']!);
      await File(
        '${target.path}.install.json',
      ).writeAsString(jsonEncode({'sha256': databases[name]['sha256']}));
    }

    await AssetDatabaseManager.initialize();

    expect(assetLoadCounts['assets/databases/manifest.json'], 1);
    expect(
      assetLoadCounts['assets/databases/${AssetDatabaseManager.tagCatalogDb}'],
      isNull,
    );
    expect(
      assetLoadCounts['assets/databases/${AssetDatabaseManager.cooccurrenceDb}'],
      isNull,
    );
  });

  test('installs missing assets atomically with manifest state', () async {
    await AssetDatabaseManager.initialize();

    final dbDir = Directory(p.join(appSupportDir.path, 'asset_databases'));
    for (final name in [
      AssetDatabaseManager.tagCatalogDb,
      AssetDatabaseManager.cooccurrenceDb,
    ]) {
      final target = File(p.join(dbDir.path, name));
      expect(await target.exists(), isTrue);
      expect(await File('${target.path}.install.json').exists(), isTrue);
      expect(assetLoadCounts['assets/databases/$name'], 1);
    }
    expect(await File(p.join(dbDir.path, 'translation.db')).exists(), isFalse);
    expect(
      await File(p.join(dbDir.path, AssetDatabaseManager.tagWikiDb)).exists(),
      isFalse,
    );
    expect(
      await File(
        p.join(dbDir.path, AssetDatabaseManager.tagSemanticsDb),
      ).exists(),
      isFalse,
    );
  });

  test('installs the wiki only on first article and reuses it', () async {
    await AssetDatabaseManager.initialize();
    final manager = AssetDatabaseManager.instance;
    final first = await manager.ensureTagWikiDb();
    final second = await manager.ensureTagWikiDb();
    expect(first, second);
    expect(await File(first).exists(), isTrue);
    expect(
      assetLoadCounts['assets/databases/${AssetDatabaseManager.tagWikiDb}'],
      1,
    );
  });

  test(
    'semantic data is installed once on demand, including concurrent readers',
    () async {
      await AssetDatabaseManager.initialize();
      const key = 'assets/databases/${AssetDatabaseManager.tagSemanticsDb}';
      expect(assetLoadCounts[key], isNull);
      final manager = AssetDatabaseManager.instance;
      final paths = await Future.wait([
        manager.ensureTagSemanticsDb(),
        manager.ensureTagSemanticsDb(),
      ]);
      expect(paths[0], paths[1]);
      expect(await File(paths.first).exists(), isTrue);
      expect(await manager.ensureTagSemanticsDb(), paths.first);
      expect(assetLoadCounts[key], 1);
    },
  );

  test(
    'failed semantic validation publishes nothing and can be retried',
    () async {
      await AssetDatabaseManager.initialize();
      const key = 'assets/databases/${AssetDatabaseManager.tagSemanticsDb}';
      final valid = assets[key]!;
      assets[key] = Uint8List.fromList([1, 2, 3]);
      final manager = AssetDatabaseManager.instance;
      await expectLater(
        manager.ensureTagSemanticsDb(),
        throwsA(isA<StateError>()),
      );
      final target = File(
        p.join(
          appSupportDir.path,
          'asset_databases',
          AssetDatabaseManager.tagSemanticsDb,
        ),
      );
      expect(await target.exists(), isFalse);
      assets[key] = valid;
      expect(await manager.ensureTagSemanticsDb(), target.path);
      expect(await target.exists(), isTrue);
    },
  );

  test('legacy autocomplete migration preserves local gallery data', () async {
    final runtimeDir = await Directory(
      p.join(appSupportDir.path, 'databases'),
    ).create(recursive: true);
    final runtimePath = p.join(runtimeDir.path, 'danbooru.db');
    final runtimeDb = sqlite3.open(runtimePath);
    runtimeDb.execute('''
      CREATE TABLE gallery_images(id INTEGER PRIMARY KEY, file_path TEXT);
      INSERT INTO gallery_images(file_path) VALUES ('C:/gallery/image.png');
      CREATE TABLE gallery_favorites(image_id INTEGER PRIMARY KEY);
      INSERT INTO gallery_favorites(image_id) VALUES (1);
      CREATE TABLE danbooru_tags(tag TEXT PRIMARY KEY);
      INSERT INTO danbooru_tags(tag) VALUES ('legacy_tag');
    ''');
    runtimeDb.dispose();

    await AssetDatabaseManager.initialize();

    final migratedDb = sqlite3.open(runtimePath);
    try {
      expect(
        migratedDb
            .select('SELECT file_path FROM gallery_images')
            .single['file_path'],
        'C:/gallery/image.png',
      );
      expect(
        migratedDb
            .select('SELECT image_id FROM gallery_favorites')
            .single['image_id'],
        1,
      );
      expect(
        migratedDb.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'danbooru_tags'",
        ),
        isEmpty,
      );
    } finally {
      migratedDb.dispose();
    }
    expect(
      await File(
        p.join(
          appSupportDir.path,
          'asset_databases',
          '.autocomplete-v1-migrated',
        ),
      ).exists(),
      isTrue,
    );
  });
}

Future<File> _createCatalogFixture(String directory) async {
  final file = File(p.join(directory, 'catalog-fixture.db'));
  final db = sqlite3.open(file.path);
  db.execute('''
    CREATE TABLE metadata(key TEXT PRIMARY KEY, value TEXT NOT NULL);
    INSERT INTO metadata VALUES ('schema_version', '1');
    INSERT INTO metadata VALUES ('data_version', 'test-data');
    CREATE TABLE tags(id INTEGER PRIMARY KEY, name TEXT, category INTEGER, post_count INTEGER);
    CREATE TABLE aliases(id INTEGER PRIMARY KEY, tag_id INTEGER, alias TEXT);
    CREATE VIRTUAL TABLE tag_search USING fts5(term, search_key, tag_id UNINDEXED, kind UNINDEXED);
  ''');
  db.dispose();
  return file;
}

Future<File> _createCooccurrenceFixture(String directory) async {
  final file = File(p.join(directory, 'cooccurrence-fixture.db'));
  final db = sqlite3.open(file.path);
  db.execute('CREATE TABLE cooccurrences(tag1 TEXT, tag2 TEXT, count INTEGER)');
  db.dispose();
  return file;
}

Future<File> _createWikiFixture(String directory) async {
  final file = File(p.join(directory, 'wiki-fixture.db'));
  final db = sqlite3.open(file.path);
  db.execute('''
    CREATE TABLE metadata(key TEXT PRIMARY KEY, value TEXT NOT NULL);
    INSERT INTO metadata VALUES ('schema_version', '1');
    INSERT INTO metadata VALUES ('data_version', 'test-data');
    CREATE TABLE wiki_pages(tag TEXT PRIMARY KEY, body TEXT NOT NULL, source_url TEXT NOT NULL);
    INSERT INTO wiki_pages VALUES ('blue_hair', 'Blue hair.', '');
  ''');
  db.dispose();
  return file;
}

Future<File> _createSemanticsFixture(String directory) async {
  final file = File(p.join(directory, 'semantics-fixture.db'));
  final db = sqlite3.open(file.path);
  db.execute('''
    CREATE TABLE metadata(key TEXT PRIMARY KEY, value TEXT NOT NULL);
    INSERT INTO metadata VALUES ('schema_version', '1');
    INSERT INTO metadata VALUES ('data_version', 'test-data');
    CREATE TABLE tag_semantics(
      tag TEXT PRIMARY KEY, synonyms_zh TEXT, core_zh TEXT, summary_zh TEXT,
      category INTEGER, source_post_count INTEGER, sensitive INTEGER,
      source_row INTEGER, source_row_sha256 TEXT
    );
  ''');
  db.dispose();
  return file;
}

class _TestPathProviderPlatform extends PathProviderPlatform {
  _TestPathProviderPlatform({required this.appSupportPath});

  final String appSupportPath;

  @override
  Future<String?> getApplicationSupportPath() async => appSupportPath;
}
