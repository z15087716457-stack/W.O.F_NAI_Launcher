import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/autocomplete/unified_tag_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/sqlite3.dart' as native;

void main() {
  late Directory temporary;
  late UnifiedTagRepository repository;

  setUp(() async {
    sqfliteFfiInit();
    temporary = await Directory.systemTemp.createTemp('wiki_union_test_');
    final catalog = p.join(temporary.path, 'catalog.db');
    final runtime = p.join(temporary.path, 'runtime.db');
    final wiki = p.join(temporary.path, 'wiki.db');

    final bundled = native.sqlite3.open(catalog);
    bundled.execute('''
      CREATE TABLE tags(name TEXT PRIMARY KEY, category INTEGER, post_count INTEGER);
      INSERT INTO tags VALUES ('blue_eyes', 0, 100);
      INSERT INTO tags VALUES ('old_character', 4, 20);
      INSERT INTO tags VALUES ('only_bundled', 0, 10);
    ''');
    bundled.dispose();

    final synced = native.sqlite3.open(runtime);
    synced.execute('''
      CREATE TABLE danbooru_tags(tag TEXT PRIMARY KEY, category INTEGER, post_count INTEGER);
      INSERT INTO danbooru_tags VALUES ('blue_eyes', 0, 900);
      INSERT INTO danbooru_tags VALUES ('new_character', 4, 300);
    ''');
    synced.dispose();

    final articles = native.sqlite3.open(wiki);
    articles.execute('''
      CREATE TABLE wiki_pages(tag TEXT PRIMARY KEY, body TEXT, source_url TEXT);
      INSERT INTO wiki_pages VALUES ('blue_eyes', 'Eyes', 'https://example.test');
      INSERT INTO wiki_pages VALUES ('new_character', 'Character', 'https://example.test');
    ''');
    articles.dispose();

    repository = UnifiedTagRepository(
      catalog: TagCatalogRepository(),
      runtime: () async => throw StateError('Not used in browse tests'),
      unionDatabase: ({required includeWiki}) async {
        final database = await databaseFactoryFfi.openDatabase(
          catalog,
          options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
        );
        await database.execute('ATTACH DATABASE ? AS runtime', [runtime]);
        if (includeWiki) {
          await database.execute('ATTACH DATABASE ? AS wiki', [wiki]);
        }
        return database;
      },
    );
  });

  tearDown(() async => temporary.delete(recursive: true));

  test('synced count overrides bundled tag and contributes new tags', () async {
    final rows = await repository.browse();
    expect(rows.map((row) => row.canonicalTag), [
      'blue_eyes',
      'new_character',
      'old_character',
      'only_bundled',
    ]);
    expect(rows.first.postCount, 900);
    expect(await repository.count(), 4);
    final character = await repository.browse(category: TagCategory.character);
    expect(character.map((row) => row.canonicalTag), [
      'new_character',
      'old_character',
    ]);
  });

  test('article coverage filters the same unified tag view', () async {
    expect(await repository.count(hasWiki: true), 2);
    expect(await repository.count(hasWiki: false), 2);
    final missing = await repository.browse(hasWiki: false);
    expect(missing.map((row) => row.canonicalTag), [
      'old_character',
      'only_bundled',
    ]);
    final selected = await repository.byNames([
      'new_character',
      'blue_eyes',
      'not_a_tag',
      'new_character',
    ]);
    expect(selected.map((row) => row.canonicalTag), [
      'new_character',
      'blue_eyes',
    ]);
  });
}
