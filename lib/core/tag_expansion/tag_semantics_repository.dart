import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/asset_database_manager.dart';
import '../utils/tag_normalizer.dart';
import 'tag_semantics_store.dart';
import '../wiki/tag_wiki_repository.dart';

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

  bool get complete =>
      coreZh.isNotEmpty && synonymsZh.isNotEmpty && summaryZh.isNotEmpty;

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
  const TagSemanticsRepository(
    this._databasePath, {
    this.supplements,
    this.currentWikiHash,
  });
  final Future<String> Function() _databasePath;
  final TagSemanticsStore? supplements;
  final Future<String> Function(String tag)? currentWikiHash;

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
      final overlay = await supplements?.findAll(names) ?? const {};
      for (final name in overlay.keys) {
        final prior = result[name];
        final row = overlay[name]!;
        final terms = (jsonDecode(row['synonyms_zh'] as String) as List)
            .cast<String>();
        final summaryCurrent =
            currentWikiHash == null ||
            row['summary_hash'] == await currentWikiHash!(name);
        result[name] = TagSemanticProfile(
          tag: name,
          coreZh: (row['core_zh'] as String).isNotEmpty
              ? row['core_zh'] as String
              : prior?.coreZh ?? '',
          synonymsZh: terms.isNotEmpty
              ? List.unmodifiable(terms)
              : prior?.synonymsZh ?? const [],
          summaryZh: summaryCurrent && (row['summary_zh'] as String).isNotEmpty
              ? row['summary_zh'] as String
              : prior?.summaryZh ?? '',
          sourceCategory: prior?.sourceCategory ?? 0,
          sourcePostCount: prior?.sourcePostCount ?? 0,
        );
      }
      return result;
    } finally {
      await db.close();
    }
  }

  /// Name lookup only. Natural-language scenes are handled by the local RAG.
  Future<List<String>> searchNames(String input, {int limit = 80}) async {
    final query = input.trim();
    if (query.isEmpty || !RegExp(r'[\u3400-\u9fff]').hasMatch(query)) {
      return const [];
    }
    final db = await databaseFactoryFfi.openDatabase(
      await _databasePath(),
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    try {
      var union =
          'SELECT tag,core_zh,synonyms_zh,source_post_count FROM tag_semantics';
      if (supplements != null) {
        await db.execute('ATTACH DATABASE ? AS supplements', [
          await supplements!.readyPath(),
        ]);
        union +=
            ' UNION ALL SELECT tag,core_zh,synonyms_zh,0 AS source_post_count FROM supplements.tag_semantics';
      }
      final rows = await db.rawQuery(
        '''WITH profiles AS ($union) SELECT tag FROM profiles s
        WHERE instr(core_zh, ?) > 0 OR EXISTS (
          SELECT 1 FROM json_each(s.synonyms_zh) WHERE instr(value, ?) > 0)
        GROUP BY tag ORDER BY MIN(CASE WHEN core_zh=? THEN 0 ELSE 1 END), MAX(source_post_count) DESC, tag LIMIT ?''',
        [query, query, query, limit.clamp(1, 100)],
      );
      return [for (final row in rows) row['tag'] as String];
    } finally {
      await db.close();
    }
  }
}

final tagSemanticsRepositoryProvider = Provider<TagSemanticsRepository>(
  (ref) => TagSemanticsRepository(
    AssetDatabaseManager.instance.ensureTagSemanticsDb,
    supplements: ref.watch(tagSemanticsStoreProvider),
    currentWikiHash: (tag) async => sha256
        .convert(
          utf8.encode(
            (await ref.read(tagWikiRepositoryProvider).find(tag))?.body ?? '',
          ),
        )
        .toString(),
  ),
);
