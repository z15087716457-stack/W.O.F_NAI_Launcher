import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class CachedVisibleTagTranslation {
  const CachedVisibleTagTranslation({required this.nameZh, this.wikiZh});

  final String nameZh;
  final String? wikiZh;
}

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
          version: 1,
          onCreate: (db, _) => db.execute('''
            CREATE TABLE tag_translations(
              tag TEXT NOT NULL,
              route TEXT NOT NULL,
              prompt_version INTEGER NOT NULL,
              wiki_hash TEXT NOT NULL,
              name_zh TEXT NOT NULL,
              wiki_zh TEXT,
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
      columns: ['name_zh', 'wiki_zh', 'wiki_hash'],
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
    );
  }

  Future<void> put({
    required String tag,
    required String route,
    required int promptVersion,
    required String wikiHash,
    required String nameZh,
    String? wikiZh,
  }) async {
    final db = await _open();
    await db.insert('tag_translations', {
      'tag': tag,
      'route': route,
      'prompt_version': promptVersion,
      'wiki_hash': wikiHash,
      'name_zh': nameZh,
      'wiki_zh': wikiZh,
      'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening != null) await opening;
    await _database?.close();
    _database = null;
  }
}
