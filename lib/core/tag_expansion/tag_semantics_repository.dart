import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/asset_database_manager.dart';
import '../utils/tag_normalizer.dart';

/// Imported semantic hints; category/count describe this source snapshot only.
/// These are not user translations or replacements for a full Wiki article.
class TagSemanticProfile {
  const TagSemanticProfile({
    required this.tag,
    required this.synonymsZh,
    required this.coreZh,
    required this.summaryZh,
    required this.sourceCategory,
    required this.sourcePostCount,
  });

  final String tag, coreZh, summaryZh;
  final List<String> synonymsZh;
  final int sourceCategory, sourcePostCount;

  factory TagSemanticProfile.fromRow(Map<String, Object?> row) =>
      TagSemanticProfile(
        tag: row['tag'] as String,
        synonymsZh: List<String>.unmodifiable(
          (jsonDecode(row['synonyms_zh'] as String) as List).cast<String>(),
        ),
        coreZh: row['core_zh'] as String,
        summaryZh: row['summary_zh'] as String,
        sourceCategory: row['category'] as int,
        sourcePostCount: row['source_post_count'] as int,
      );
}

/// Exact-tag data access, independent of the current completion/search pipeline.
class TagSemanticsRepository {
  const TagSemanticsRepository(this._databasePath);
  final Future<String> Function() _databasePath;

  Future<TagSemanticProfile?> find(String tag) async =>
      (await findAll([tag]))[TagNormalizer.normalize(tag)];

  Future<Map<String, TagSemanticProfile>> findAll(Iterable<String> tags) async {
    final names = tags
        .map(TagNormalizer.normalize)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    if (names.isEmpty) return const {};
    final db = await databaseFactoryFfi.openDatabase(
      await _databasePath(),
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    try {
      final result = <String, TagSemanticProfile>{};
      for (var offset = 0; offset < names.length; offset += 400) {
        final batch = names.skip(offset).take(400).toList();
        final rows = await db.query(
          'tag_semantics',
          where: 'tag IN (${List.filled(batch.length, '?').join(',')})',
          whereArgs: batch,
        );
        for (final row in rows) {
          final profile = TagSemanticProfile.fromRow(row);
          result[profile.tag] = profile;
        }
      }
      return result;
    } finally {
      await db.close();
    }
  }
}

final tagSemanticsRepositoryProvider = Provider<TagSemanticsRepository>(
  (ref) => TagSemanticsRepository(
    AssetDatabaseManager.instance.ensureTagSemanticsDb,
  ),
);
