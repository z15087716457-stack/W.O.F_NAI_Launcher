import '../autocomplete/completion_models.dart';
import '../utils/tag_normalizer.dart';
import '../utils/prompt_translation_language.dart';
import 'tag_semantics_repository.dart';

typedef SubstringTagSearch =
    Future<List<CompletionCandidate>> Function(String input, {int limit});
typedef PopularTagSearch =
    Future<List<CompletionCandidate>> Function({int limit});

/// The explicit tag picker reads only local tag and semantic databases.
/// It deliberately does not depend on the autocomplete orchestrator, whose
/// optional Danbooru and AI branches can make network requests. Chinese names
/// come from local semantics; missing readings remain the visible-tag queue's job.
class LocalTagExpansionService {
  const LocalTagExpansionService({
    required this.catalog,
    required this.relatedTags,
    required this.substringSearch,
    required this.popularSearch,
    this.semanticNames,
    this.semantics,
    this.readingLanguage,
  });

  final CompletionSource catalog;
  final CompletionSource relatedTags;
  final SubstringTagSearch substringSearch;
  final PopularTagSearch popularSearch;
  final SubstringTagSearch? semanticNames;
  final TagSemanticsRepository? semantics;
  final String Function()? readingLanguage;

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
      locale,
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
    // Chinese names do not exist in the English indexes. In particular, do
    // not wait for the runtime English index before searching semantic names.
    final prefix = query.isChinese
        ? const <CompletionCandidate>[]
        : await catalog.search(query.copyWith(limit: limit.clamp(1, 100)));
    final contains = query.isChinese || token.runes.length < 2
        ? const <CompletionCandidate>[]
        : await substringSearch(token, limit: limit);
    final chinese =
        await semanticNames?.call(input, limit: limit) ??
        const <CompletionCandidate>[];
    final candidates = [...prefix, ...chinese, ...contains];
    // searchNames already orders exact Chinese names before synonyms. Sorting
    // equal undecorated rows here could discard that order before the limit.
    if (!query.isChinese) {
      candidates.sort((a, b) => a.matchKind.index.compareTo(b.matchKind.index));
    }
    return _decorate(
      _unique(candidates, limit),
      existingTags,
      locale,
      chineseInput: query.isChinese ? input.trim() : null,
    );
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
    return _decorate(candidates, existingTags, locale);
  }

  Future<List<CompletionCandidate>> _decorate(
    List<CompletionCandidate> candidates,
    Set<String> existingTags,
    String locale, {
    String? chineseInput,
  }) async {
    final chinese = PromptTranslationLanguage.fromCode(
      readingLanguage?.call() ?? locale,
    ).isChinese;
    final profiles = chinese && semantics != null && candidates.isNotEmpty
        ? await semantics!.findAll(candidates.map((c) => c.canonicalTag))
        : const <String, TagSemanticProfile>{};
    return [
      for (final candidate in candidates)
        candidate.copyWith(
          translation: profiles[candidate.canonicalTag]?.coreZh,
          clearTranslation: !chinese,
          matchKind:
              chineseInput != null &&
                  profiles[candidate.canonicalTag]?.coreZh == chineseInput
              ? CompletionMatchKind.chineseExact
              : candidate.matchKind,
          isExisting: existingTags.contains(candidate.canonicalTag),
        ),
    ];
  }

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
