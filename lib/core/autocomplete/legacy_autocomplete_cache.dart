import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../utils/app_support_directory.dart';

/// Maintenance of existing retired caches. Opening settings creates no cache.
class LegacyAutocompleteCache {
  LegacyAutocompleteCache({Future<String> Function()? databasePath})
    : _databasePath = databasePath;
  final Future<String> Function()? _databasePath;

  Future<T?> _read<T>(Future<T> Function(Database) read) async {
    final path =
        await _databasePath?.call() ??
        p.join(
          (await getApplicationSupportDirectory()).path,
          'autocomplete',
          'autocomplete_cache.db',
        );
    if (!await File(path).exists()) return null;
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    try {
      return await read(db);
    } finally {
      await db.close();
    }
  }

  Future<Map<String, int>> statistics() async => {
    'danbooruCache': await _count('remote_queries'),
    'aiTranslations': await _count('ai_translations'),
  };

  Future<int> _count(String table) async =>
      await _read(
        (db) async =>
            (await db.rawQuery('SELECT COUNT(*) AS n FROM $table')).single['n']
                as int,
      ) ??
      0;

  Future<Map<String, int>> contentBytes() async => {
    'danbooruCache': await _bytes('remote_queries', 'payload'),
    'aiTranslations': await _bytes('ai_translations', 'translation'),
  };

  Future<int> _bytes(String table, String column) async =>
      await _read(
        (db) async =>
            (await db.rawQuery(
                  'SELECT COALESCE(SUM(length(CAST($column AS BLOB))),0) AS n FROM $table',
                )).single['n']
                as int,
      ) ??
      0;

  Future<int> clearDanbooruCache() => _clear('remote_queries');
  Future<int> clearAiTranslationCache() => _clear('ai_translations');

  Future<int> _clear(String table) async {
    final path =
        await _databasePath?.call() ??
        p.join(
          (await getApplicationSupportDirectory()).path,
          'autocomplete',
          'autocomplete_cache.db',
        );
    if (!await File(path).exists()) return 0;
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      return await db.delete(table);
    } finally {
      await db.close();
    }
  }
}
