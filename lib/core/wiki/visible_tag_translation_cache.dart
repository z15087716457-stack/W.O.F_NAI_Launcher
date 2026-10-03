import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class CachedVisibleTagTranslation {
  const CachedVisibleTagTranslation({
    required this.nameZh,
    this.wikiZh,
    this.wikiOriginal,
    this.definition,
    this.wikiHash,
    this.nameLanguage,
    this.definitionLanguage,
  });

  final String nameZh;
  final String? wikiZh;
  final String? wikiOriginal;
  final String? definition;
  final String? wikiHash;
  final String? nameLanguage;
  final String? definitionLanguage;
}

final visibleTagTranslationCacheProvider = Provider<VisibleTagTranslationCache>(
  (ref) {
    final cache = VisibleTagTranslationCache();
    ref.onDispose(() => unawaited(cache.close()));
    return cache;
  },
);

/// User-owned sidecar cache. The bundled catalog and wiki remain read-only.
class VisibleTagTranslationCache {
  VisibleTagTranslationCache({Future<String> Function()? databasePath})
    : _databasePath = databasePath ?? _defaultPath;

  final Future<String> Function() _databasePath;
  Database? _database;
  Future<Database>? _opening;

  static Future<String> _defaultPath() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'autocomplete'));
    await directory.create(recursive: true);
    return p.join(directory.path, 'visible_tag_translations.db');
  }

  Future<Database> _open() {
    if (_database case final database?) return Future.value(database);
    return _opening ??= () async {
      final path = await _databasePath();
      final database = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onUpgrade: (db, oldVersion, _) async {
            if (oldVersion < 2) {
              await db.execute(
                'ALTER TABLE tag_translations ADD COLUMN wiki_original TEXT',
              );
            }
          },
          // Additive columns preserve compatibility with the previous Studio
          // cache reader when the application package is rolled back.
          onOpen: (db) async {
            final columns = (await db.rawQuery(
              'PRAGMA table_info(tag_translations)',
            )).map((row) => row['name']).toSet();
            await db.transaction((txn) async {
              for (final name in [
                'definition',
                'name_language',
                'definition_language',
              ]) {
                if (!columns.contains(name)) {
                  await txn.execute(
                    'ALTER TABLE tag_translations ADD COLUMN $name TEXT',
                  );
                }
              }
            });
          },
          onCreate: (db, _) => db.execute('''
            CREATE TABLE tag_translations(
              tag TEXT NOT NULL,
              route TEXT NOT NULL,
              prompt_version INTEGER NOT NULL,
              wiki_hash TEXT NOT NULL,
              name_zh TEXT NOT NULL,
              wiki_zh TEXT,
              wiki_original TEXT,
              definition TEXT,
              name_language TEXT,
              definition_language TEXT,
              updated_at INTEGER NOT NULL,
              PRIMARY KEY(tag, route, prompt_version)
            )
          '''),
        ),
      );
      _database = database;
      return database;
    }().whenComplete(() => _opening = null);
  }

  Future<CachedVisibleTagTranslation?> get({
    required String tag,
    required String route,
    required int promptVersion,
    required String wikiHash,
    bool allowEarlierVersion = false,
  }) async {
    final db = await _open();
    final rows = await db.query(
      'tag_translations',
      columns: [
        'name_zh',
        'wiki_zh',
        'wiki_original',
        'wiki_hash',
        'definition',
        'name_language',
        'definition_language',
      ],
      where:
          'tag = ? AND route = ? AND prompt_version ${allowEarlierVersion ? '<=' : '='} ?',
      whereArgs: [tag, route, promptVersion],
      orderBy: 'prompt_version DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return CachedVisibleTagTranslation(
      nameZh: row['name_zh'] as String,
      wikiZh: row['wiki_hash'] == wikiHash ? row['wiki_zh'] as String? : null,
      wikiOriginal: row['wiki_hash'] == wikiHash
          ? row['wiki_original'] as String?
          : null,
      definition: row['wiki_hash'] == wikiHash
          ? row['definition'] as String?
          : null,
      wikiHash: row['wiki_hash'] as String,
      nameLanguage: row['name_language'] as String?,
      definitionLanguage: row['definition_language'] as String?,
    );
  }

  Future<void> put({
    required String tag,
    required String route,
    required int promptVersion,
    required String wikiHash,
    required String nameZh,
    String? wikiZh,
    String? wikiOriginal,
    String? definition,
    String nameLanguage = 'zh',
    String definitionLanguage = 'zh',
  }) async {
    final db = await _open();
    await db.insert('tag_translations', {
      'tag': tag,
      'route': route,
      'prompt_version': promptVersion,
      'wiki_hash': wikiHash,
      'name_zh': nameZh,
      'wiki_zh': wikiZh,
      'wiki_original': wikiOriginal,
      'definition': definition,
      'name_language': nameLanguage,
      'definition_language': definitionLanguage,
      'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Chinese terminology is reference data across interfaces and providers.
  /// Legacy records with unknown language must not be mislabeled as Chinese.
  Future<Map<String, CachedVisibleTagTranslation>> chineseTerms(
    Iterable<String> tags,
  ) async {
    final names = tags.toSet().toList();
    if (names.isEmpty) return const {};
    final db = await _open();
    final result = <String, CachedVisibleTagTranslation>{};
    for (var start = 0; start < names.length; start += 400) {
      final chunk = names.skip(start).take(400).toList();
      final rows = await db.rawQuery(
        'SELECT tag, name_zh, wiki_hash, definition, name_language, definition_language '
        'FROM tag_translations WHERE tag IN (${List.filled(chunk.length, '?').join(',')}) '
        "AND name_language IN ('zh', 'zh-TW') ORDER BY updated_at DESC, prompt_version DESC",
        chunk,
      );
      for (final row in rows) {
        final tag = row['tag'] as String;
        result.putIfAbsent(
          tag,
          () => CachedVisibleTagTranslation(
            nameZh: row['name_zh'] as String,
            definition: row['definition'] as String?,
            wikiHash: row['wiki_hash'] as String,
            nameLanguage: row['name_language'] as String?,
            definitionLanguage: row['definition_language'] as String?,
          ),
        );
      }
    }
    return result;
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening != null) await opening;
    await _database?.close();
    _database = null;
  }
}
