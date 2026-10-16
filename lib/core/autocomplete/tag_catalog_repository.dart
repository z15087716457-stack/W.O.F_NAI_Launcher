import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/asset_database_manager.dart';
import 'completion_models.dart';

class TagCatalogRecord {
  const TagCatalogRecord({
    required this.canonicalTag,
    required this.category,
    required this.postCount,
  });

  final String canonicalTag;
  final TagCategory category;
  final int postCount;
}

class TagCatalogRepository implements CompletionSource {
  TagCatalogRepository({Database? database, Future<String> Function()? path})
    : _fixture = database == null
          ? null
          : _TagCatalogQueries(database: database),
      _path = path;
  final _TagCatalogQueries? _fixture;
  final Future<String> Function()? _path;
  final _versions = <String, Future<_TagCatalogQueries>>{};
  bool _disposed = false;

  Future<_TagCatalogQueries> _current() async {
    if (_disposed) throw StateError('Catalog disposed');
    if (_fixture case final fixture?) return fixture;
    final path = _path != null
        ? await _path()
        : await (() async {
            await AssetDatabaseManager.initialize();
            return AssetDatabaseManager.instance.tagCatalogDbPath;
          })();
    if (_disposed) throw StateError('Catalog disposed');
    // A query keeps its revision through every await. Previous connections are
    // retained until disposal so in-flight alias lookups cannot mix tag IDs.
    final opening = _versions.putIfAbsent(
      path,
      () async => _TagCatalogQueries(
        database: await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
        ),
      ),
    );
    try {
      final result = await opening;
      if (_disposed) throw StateError('Catalog disposed');
      return result;
    } catch (_) {
      if (identical(_versions[path], opening)) _versions.remove(path);
      rethrow;
    }
  }

  Future<void> initialize() async {
    await _current();
  }

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async =>
      (await _current()).search(query);
  Future<List<CompletionCandidate>> searchContains(
    String input, {
    int limit = 20,
  }) async => (await _current()).searchContains(input, limit: limit);
  Future<List<CompletionCandidate>> popular({int limit = 12}) async =>
      (await _current()).popular(limit: limit);
  Future<int?> postCount(String tag) async => (await _current()).postCount(tag);
  Future<Map<String, CompletionCandidate>> exactAliases(
    Iterable<String> terms,
  ) async => (await _current()).exactAliases(terms);
  Future<Map<String, TagCatalogRecord>> recordsByCanonicalTag(
    Iterable<String> tags,
  ) async => (await _current()).recordsByCanonicalTag(tags);
  Future<Map<String, String>> metadata() async => (await _current()).metadata();
  Future<Map<TagCategory, int>> categoryCounts() async =>
      (await _current()).categoryCounts();
  Future<void> dispose() async {
    _disposed = true;
    await _fixture?.dispose();
    for (final opening in _versions.values) {
      await (await opening).dispose();
    }
    _versions.clear();
  }
}

class _TagCatalogQueries implements CompletionSource {
  _TagCatalogQueries({Database? database}) : _database = database;

  Database? _database;
  Future<Database>? _opening;

  Future<void> initialize() async {
    if (_database != null) return;
    final opening = _opening ??= AssetDatabaseManager.instance
        .openTagCatalogDatabase();
    try {
      _database = await opening;
    } finally {
      if (identical(_opening, opening)) _opening = null;
    }
  }

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async {
    final normalized = query.token.trim().toLowerCase();
    if (normalized.isEmpty || query.isChinese) return const [];
    await initialize();

    final expression = _ftsExpression(normalized);
    if (expression.isEmpty) return const [];
    final requestedLimit =
        normalized.length == 1 && CompletionResultLimits.isAll(query.limit)
        ? CompletionResultLimits.oneCharacter
        : query.limit;
    final rows = await _database!.rawQuery(
      '''
      SELECT f.term, f.kind, t.id, t.name, t.category, t.post_count
      FROM tag_search f
      JOIN tags t ON t.id = f.tag_id
      WHERE tag_search MATCH ?
      ORDER BY bm25(tag_search), t.post_count DESC, t.name ASC
      LIMIT ?
      ''',
      [expression, (requestedLimit * 5).clamp(20, 500000)],
    );

    final byId = <int, Map<String, Object?>>{};
    for (final row in rows) {
      final id = row['id'] as int;
      final current = byId[id];
      if (current == null ||
          _rowMatchPriority(row, normalized) <
              _rowMatchPriority(current, normalized)) {
        byId[id] = row;
      }
    }
    if (byId.isEmpty) return const [];

    final aliasesById = await _loadAliases(byId.keys.toList());
    final candidates = byId.values
        .map((row) {
          final category = TagCategory.fromCatalog(row['category'] as int);
          if (category == null) return null;
          final term = row['term'] as String;
          final kind = row['kind'] as int;
          final matchKind = _matchKind(term, kind, normalized);
          return CompletionCandidate(
            canonicalTag: row['name'] as String,
            category: category,
            postCount: row['post_count'] as int,
            aliases: aliasesById[row['id'] as int] ?? const [],
            matchedAlias: kind == 1 ? term : null,
            matchKind: matchKind,
            sources: const {CompletionSourceKind.base},
          );
        })
        .whereType<CompletionCandidate>()
        .toList();
    candidates.sort((a, b) {
      final match = a.matchKind.index.compareTo(b.matchKind.index);
      if (match != 0) return match;
      final count = b.postCount.compareTo(a.postCount);
      if (count != 0) return count;
      return a.canonicalTag.compareTo(b.canonicalTag);
    });
    return candidates.take(requestedLimit).toList(growable: false);
  }

  /// Bounded substring fallback for the explicit tag search. The bundled FTS
  /// index supports token prefixes, but has no trigram index for mid-word hits.
  Future<List<CompletionCandidate>> searchContains(
    String input, {
    int limit = 20,
  }) async {
    final normalized = input.trim().toLowerCase().replaceAll(' ', '_');
    if (normalized.runes.length < 2) return const [];
    await initialize();

    final pattern =
        '%${normalized.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
    final rows = await _database!.rawQuery(
      '''
      SELECT f.term, f.kind, t.id, t.name, t.category, t.post_count
      FROM tag_search f
      JOIN tags t ON t.id = f.tag_id
      WHERE f.term LIKE ? ESCAPE '\\'
      ORDER BY t.post_count DESC, t.name ASC
      LIMIT ?
      ''',
      [pattern, (limit.clamp(1, 100) * 3)],
    );
    if (rows.isEmpty) return const [];

    final byId = <int, Map<String, Object?>>{};
    for (final row in rows) {
      final id = row['id'] as int;
      final existing = byId[id];
      if (existing == null ||
          (existing['kind'] as int) > (row['kind'] as int)) {
        byId[id] = row;
      }
    }
    final aliasesById = await _loadAliases(byId.keys.toList());
    return byId.values
        .map((row) {
          final category = TagCategory.fromCatalog(row['category'] as int);
          if (category == null) return null;
          final kind = row['kind'] as int;
          return CompletionCandidate(
            canonicalTag: row['name'] as String,
            category: category,
            postCount: row['post_count'] as int,
            aliases: aliasesById[row['id'] as int] ?? const [],
            matchedAlias: kind == 1 ? row['term'] as String : null,
            matchKind: CompletionMatchKind.fullText,
            sources: const {CompletionSourceKind.base},
          );
        })
        .whereType<CompletionCandidate>()
        .take(limit)
        .toList(growable: false);
  }

  /// A small, indexed fallback for an empty explicit search box.
  Future<List<CompletionCandidate>> popular({int limit = 12}) async {
    await initialize();
    final rows = await _database!.rawQuery(
      'SELECT name, category, post_count FROM tags '
      'WHERE category = 0 ORDER BY post_count DESC, name ASC LIMIT ?',
      [limit.clamp(1, 100)],
    );
    return rows
        .map(
          (row) => CompletionCandidate(
            canonicalTag: row['name'] as String,
            category: TagCategory.general,
            postCount: (row['post_count'] as num).toInt(),
            matchKind: CompletionMatchKind.fullText,
            sources: const {CompletionSourceKind.base},
          ),
        )
        .toList(growable: false);
  }

  Future<Map<int, List<String>>> _loadAliases(List<int> ids) async {
    if (ids.isEmpty) return const {};
    final result = <int, List<String>>{};
    // SQLite builds use different host-parameter limits. Fixed-size batches
    // keep exhaustive searches portable while avoiding one query per row.
    for (var offset = 0; offset < ids.length; offset += 400) {
      final chunk = ids.skip(offset).take(400).toList(growable: false);
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await _database!.rawQuery(
        'SELECT tag_id, alias FROM aliases WHERE tag_id IN ($placeholders) ORDER BY alias',
        chunk,
      );
      for (final row in rows) {
        result
            .putIfAbsent(row['tag_id'] as int, () => <String>[])
            .add(row['alias'] as String);
      }
    }
    return result;
  }

  Future<int?> postCount(String canonicalTag) async {
    final records = await recordsByCanonicalTag([canonicalTag]);
    return records[canonicalTag.trim().toLowerCase()]?.postCount;
  }

  /// Exact alias lookup only; never use a prefix search to create wiki links.
  Future<Map<String, CompletionCandidate>> exactAliases(
    Iterable<String> terms,
  ) async {
    final names = terms.toSet().toList();
    if (names.isEmpty) return const {};
    await initialize();
    final matches = <String, Map<String, CompletionCandidate>>{};
    for (var offset = 0; offset < names.length; offset += 400) {
      final chunk = names.skip(offset).take(400).toList();
      final rows = await _database!.rawQuery(
        'SELECT a.alias, t.name, t.category, t.post_count FROM aliases a '
        'JOIN tags t ON t.id = a.tag_id WHERE a.alias IN (${List.filled(chunk.length, '?').join(',')})',
        chunk,
      );
      for (final row in rows) {
        final category = TagCategory.fromCatalog(
          (row['category'] as num).toInt(),
        );
        if (category == null) continue;
        final name = row['name'] as String;
        (matches[row['alias'] as String] ??= {})[name] = CompletionCandidate(
          canonicalTag: name,
          category: category,
          postCount: (row['post_count'] as num).toInt(),
          matchKind: CompletionMatchKind.aliasExact,
          sources: const {CompletionSourceKind.base},
        );
      }
    }
    return {
      for (final entry in matches.entries)
        if (entry.value.length == 1) entry.key: entry.value.values.single,
    };
  }

  Future<Map<String, TagCatalogRecord>> recordsByCanonicalTag(
    Iterable<String> canonicalTags,
  ) async {
    final names = canonicalTags
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (names.isEmpty) return const {};
    await initialize();

    final result = <String, TagCatalogRecord>{};
    for (var offset = 0; offset < names.length; offset += 400) {
      final chunk = names.skip(offset).take(400).toList(growable: false);
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await _database!.rawQuery(
        'SELECT name, category, post_count FROM tags '
        'WHERE name IN ($placeholders)',
        chunk,
      );
      for (final row in rows) {
        final category = TagCategory.fromCatalog(
          (row['category'] as num).toInt(),
        );
        if (category == null) continue;
        final name = row['name'] as String;
        result[name] = TagCatalogRecord(
          canonicalTag: name,
          category: category,
          postCount: (row['post_count'] as num).toInt(),
        );
      }
    }
    return result;
  }

  Future<Map<String, String>> metadata() async {
    await initialize();
    final rows = await _database!.rawQuery('SELECT key, value FROM metadata');
    return {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
  }

  Future<Map<TagCategory, int>> categoryCounts() async {
    await initialize();
    final rows = await _database!.rawQuery(
      'SELECT category, COUNT(*) AS count FROM tags GROUP BY category',
    );
    final counts = <TagCategory, int>{};
    for (final row in rows) {
      final category = TagCategory.fromCatalog(row['category'] as int);
      if (category == null) continue;
      final count = row['count'] as int;
      counts.update(
        category,
        (current) => current + count,
        ifAbsent: () => count,
      );
    }
    return counts;
  }

  Future<void> dispose() async {
    await _opening;
    await _database?.close();
    _database = null;
  }

  static String _ftsExpression(String value) {
    final normalized = value.replaceAll('_', ' ');
    final tokens = normalized
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty)
        .toList();
    return tokens.map((token) => '"${token.replaceAll('"', '""')}"*').join(' ');
  }

  static CompletionMatchKind _matchKind(String term, int kind, String query) {
    final normalizedTerm = term.toLowerCase();
    if (kind == 0) {
      return normalizedTerm == query
          ? CompletionMatchKind.englishExact
          : normalizedTerm.startsWith(query)
          ? CompletionMatchKind.englishPrefix
          : CompletionMatchKind.fullText;
    }
    return normalizedTerm == query
        ? CompletionMatchKind.aliasExact
        : normalizedTerm.startsWith(query)
        ? CompletionMatchKind.aliasPrefix
        : CompletionMatchKind.fullText;
  }

  static int _rowMatchPriority(Map<String, Object?> row, String query) {
    return _matchKind(row['term'] as String, row['kind'] as int, query).index;
  }
}
