import '../database/datasources/cooccurrence_data_source.dart';
import 'completion_models.dart';
import 'tag_catalog_repository.dart';

class RelatedTagMatch {
  const RelatedTagMatch(this.candidate, this.sources);
  final CompletionCandidate candidate;
  final List<String> sources;
}

typedef CooccurrenceDataSourceLoader =
    Future<CooccurrenceDataSource> Function();

/// Offline related-tag source backed by the bundled cooccurrence CSV database.
///
/// The asset stores intersection counts. Catalog post counts are joined at
/// query time so ranking can use the same Jaccard metric as Danbooru's related
/// tag endpoint without duplicating the complete tag catalog in another database.
class CooccurrenceCompletionSource implements CompletionSource {
  CooccurrenceCompletionSource(
    CooccurrenceDataSource dataSource, {
    required TagCatalogRepository catalog,
  }) : this.withLoader(() async => dataSource, catalog: catalog);

  CooccurrenceCompletionSource.withLoader(
    this._loadDataSource, {
    required TagCatalogRepository catalog,
  }) : _catalog = catalog;

  final CooccurrenceDataSourceLoader _loadDataSource;
  final TagCatalogRepository _catalog;

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async {
    final relatedTag = query.relatedTag?.trim().toLowerCase();
    if (relatedTag == null || relatedTag.isEmpty || query.token.isNotEmpty) {
      return const [];
    }

    final requestedLimit = CompletionResultLimits.isAll(query.limit)
        ? CompletionResultLimits.maxRelatedTags
        : query.limit.clamp(1, CompletionResultLimits.maxRelatedTags);
    final matches = await related(
      [relatedTag],
      exclude: query.existingTags,
      limit: requestedLimit,
    );
    return [for (final match in matches) match.candidate];
  }

  /// Shared offline ranking for editor completion and the Agent tool.
  /// Inputs are canonical tags; score every adjacent edge before taking top-k.
  Future<List<RelatedTagMatch>> related(
    List<String> tags, {
    Set<String> exclude = const {},
    Set<TagCategory>? categories,
    int limit = 20,
  }) async {
    final seeds = tags.toSet();
    if (seeds.isEmpty) return const [];
    final dataSource = await _loadDataSource();
    final rows = await dataSource.getRelatedTagsBatch(
      seeds.toList(),
      limit: null,
    );

    final records = await _catalog.recordsByCanonicalTag({
      ...seeds,
      for (final batch in rows.values) ...batch.map((row) => row.tag),
    });
    final scores = <String, double>{};
    final counts = <String, int>{};
    final sources = <String, List<String>>{};
    for (final seed in seeds) {
      for (final row in rows[seed] ?? const <RelatedTag>[]) {
        final record = records[row.tag];
        if (record == null ||
            seeds.contains(row.tag) ||
            exclude.contains(row.tag) ||
            (categories != null && !categories.contains(record.category))) {
          continue;
        }
        final score = _jaccard(
          intersection: row.count,
          sourcePostCount: records[seed]?.postCount,
          targetPostCount: record.postCount,
        );
        if (score == null || score <= 0) continue;
        scores.update(row.tag, (value) => value + score, ifAbsent: () => score);
        counts.update(
          row.tag,
          (value) => value + row.count,
          ifAbsent: () => row.count,
        );
        sources.putIfAbsent(row.tag, () => []).add(seed);
      }
    }
    final names = scores.keys.toList();
    names.sort((left, right) {
      final support = sources[right]!.length.compareTo(sources[left]!.length);
      if (support != 0) return support;
      final similarity = scores[right]!.compareTo(scores[left]!);
      if (similarity != 0) return similarity;
      final occurrences = counts[right]!.compareTo(counts[left]!);
      if (occurrences != 0) return occurrences;
      final popularity = records[right]!.postCount.compareTo(
        records[left]!.postCount,
      );
      if (popularity != 0) return popularity;
      return left.compareTo(right);
    });
    return [
      for (final name in names.take(limit))
        RelatedTagMatch(
          CompletionCandidate(
            canonicalTag: name,
            category: records[name]!.category,
            postCount: records[name]!.postCount,
            matchKind: CompletionMatchKind.related,
            sources: const {CompletionSourceKind.cooccurrence},
            relatedScore: scores[name]! / seeds.length,
            cooccurrenceCount: counts[name],
          ),
          List.unmodifiable(sources[name]!),
        ),
    ];
  }

  static double? _jaccard({
    required int intersection,
    required int? sourcePostCount,
    required int? targetPostCount,
  }) {
    if (intersection <= 0 ||
        sourcePostCount == null ||
        sourcePostCount <= 0 ||
        targetPostCount == null ||
        targetPostCount <= 0) {
      return null;
    }
    // Marginals and edge counts are different snapshots. Bound stale counts
    // before deriving similarity rather than presenting impossible overlaps.
    intersection = intersection.clamp(
      0,
      sourcePostCount < targetPostCount ? sourcePostCount : targetPostCount,
    );
    final union = sourcePostCount + targetPostCount - intersection;
    if (union <= 0) return null;
    return (intersection / union).clamp(0.0, 1.0);
  }
}
