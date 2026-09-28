import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/asset_database_manager.dart';
import '../utils/tag_normalizer.dart';

class TagWikiEntry {
  const TagWikiEntry({
    required this.tag,
    required this.body,
    required this.sourceUrl,
  });

  final String tag;
  final String body;
  final String sourceUrl;
}

/// Shared local source for the expansion preview and the full tag encyclopedia.
abstract class TagWikiRepository {
  Future<TagWikiEntry?> find(String tag);
}

class AssetTagWikiRepository implements TagWikiRepository {
  AssetTagWikiRepository(this._databasePath);

  final Future<String> Function() _databasePath;

  @override
  Future<TagWikiEntry?> find(String tag) async {
    final normalized = TagNormalizer.normalize(tag);
    if (normalized.isEmpty) return null;
    final path = await _databasePath();
    final database = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    try {
      final rows = await database.query(
        'wiki_pages',
        columns: ['tag', 'body', 'source_url'],
        where: 'tag = ?',
        whereArgs: [normalized],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final row = rows.single;
      return TagWikiEntry(
        tag: row['tag'] as String,
        body: row['body'] as String,
        sourceUrl: row['source_url'] as String,
      );
    } finally {
      await database.close();
    }
  }
}

final tagWikiRepositoryProvider = Provider<TagWikiRepository>(
  (ref) =>
      AssetTagWikiRepository(AssetDatabaseManager.instance.ensureTagWikiDb),
);
