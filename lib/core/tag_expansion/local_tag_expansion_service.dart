import '../autocomplete/completion_models.dart';
import '../utils/tag_normalizer.dart';

typedef SubstringTagSearch =
    Future<List<CompletionCandidate>> Function(String input, {int limit});
typedef PopularTagSearch =
    Future<List<CompletionCandidate>> Function({int limit});

/// The explicit tag picker only reads the bundled English tag databases.
/// It deliberately does not depend on the autocomplete orchestrator, whose
/// optional Danbooru and AI branches can make network requests. Readings come
/// from the visible-tag translation queue, not from this service.
class LocalTagExpansionService {
  const LocalTagExpansionService({
    required this.catalog,
    required this.relatedTags,
    required this.substringSearch,
    required this.popularSearch,
    this.semanticNames,
  });

  final CompletionSource catalog;
  final CompletionSource relatedTags;
  final SubstringTagSearch substringSearch;
  final PopularTagSearch popularSearch;
  final SubstringTagSearch? semanticNames;

  Future<List<CompletionCandidate>> popular({
    required String locale,
    Set<String> existingTags = const {},
    int limit = 12,
  }) async {
    final candidates = await popularSearch(
      limit: (limit + existingTags.length).clamp(1, 100),
    );
    return _decorate(
      candidates
          .where((candidate) => !existingTags.contains(candidate.canonicalTag))
          .take(limit)
          .toList(growable: false),
      existingTags,
    );
  }

  Future<List<CompletionCandidate>> search(
    String input, {
    required String locale,
    Set<String> existingTags = const {},
    int limit = 40,
  }) async {
    final token = TagNormalizer.normalize(input);
    if (token.isEmpty) return const [];
    final query = _query(
      token: token,
      locale: locale,
      existingTags: existingTags,
      limit: limit,
    );
    final prefix = await catalog.search(
      query.copyWith(limit: limit.clamp(1, 100)),
    );
    final contains = token.runes.length < 2
        ? const <CompletionCandidate>[]
        : await substringSearch(token, limit: limit);
    final chinese =
        await semanticNames?.call(input, limit: limit) ??
        const <CompletionCandidate>[];
    final candidates = [...prefix, ...chinese, ...contains]
      ..sort((a, b) => a.matchKind.index.compareTo(b.matchKind.index));
    return _decorate(_unique(candidates, limit), existingTags);
  }

  Future<List<CompletionCandidate>> related(
    String sourceTag, {
    required String locale,
    Set<String> existingTags = const {},
    int limit = 24,
  }) async {
    final source = TagNormalizer.normalize(sourceTag);
    if (source.isEmpty) return const [];
    final query = _query(
      token: '',
      locale: locale,
      existingTags: existingTags,
      limit: limit,
    ).copyWith(relatedTag: source);
    final candidates = await relatedTags.search(query);
    return _decorate(candidates, existingTags);
  }

  static List<CompletionCandidate> _decorate(
    List<CompletionCandidate> candidates,
    Set<String> existingTags,
  ) => candidates
      .map(
        (candidate) => candidate.copyWith(
          isExisting: existingTags.contains(candidate.canonicalTag),
        ),
      )
      .toList(growable: false);

  static List<CompletionCandidate> _unique(
    List<CompletionCandidate> candidates,
    int limit,
  ) {
    final byTag = <String, CompletionCandidate>{};
    for (final candidate in candidates) {
      byTag.putIfAbsent(candidate.stableId, () => candidate);
      if (byTag.length >= limit) break;
    }
    return byTag.values.toList(growable: false);
  }

  static CompletionQuery _query({
    required String token,
    required String locale,
    required Set<String> existingTags,
    required int limit,
  }) => CompletionQuery(
    fullText: token,
    cursorPosition: token.length,
    token: token,
    replacementRange: TextReplacementRange(start: 0, end: token.length),
    existingTags: existingTags,
    limit: limit.clamp(1, 100),
    locale: locale,
  );
}
