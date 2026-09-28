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

extension TagWikiAvailability on TagWikiRepository {
  Future<Set<String>> available(Iterable<String> tags) async {
    if (this case final AssetTagWikiRepository asset) {
      return asset.available(tags);
    }
    final found = <String>{};
    for (final tag in tags) {
      if (await find(tag) != null) found.add(TagNormalizer.normalize(tag));
    }
    return found;
  }
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

  Future<Set<String>> available(Iterable<String> tags) async {
    final normalized = tags
        .map(TagNormalizer.normalize)
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    if (normalized.isEmpty) return const {};
    final path = await _databasePath();
    final database = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    try {
      final found = <String>{};
      for (var offset = 0; offset < normalized.length; offset += 400) {
        final chunk = normalized.skip(offset).take(400).toList();
        final placeholders = List.filled(chunk.length, '?').join(',');
        final rows = await database.rawQuery(
          'SELECT tag FROM wiki_pages WHERE tag IN ($placeholders)',
          chunk,
        );
        found.addAll(rows.map((row) => row['tag'] as String));
      }
      return found;
    } finally {
      await database.close();
    }
  }
}

final tagWikiRepositoryProvider = Provider<TagWikiRepository>(
  (ref) =>
      AssetTagWikiRepository(AssetDatabaseManager.instance.ensureTagWikiDb),
);
