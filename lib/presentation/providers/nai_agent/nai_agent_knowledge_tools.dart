import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/autocomplete/completion_models.dart';
import '../../../core/autocomplete/autocomplete_providers.dart';
import '../../../core/autocomplete/cooccurrence_completion_source.dart';
import '../../../core/tag_expansion/tag_expansion_providers.dart';
import '../../../core/wiki/tag_wiki_repository.dart';
import '../../../core/wiki/tag_translation_glossary.dart';
import '../../../core/utils/tag_normalizer.dart';
import 'nai_agent_wiki_images.dart';

Map<String, NaiAgentToolExecutor> naiAgentKnowledgeTools(
  Ref ref, {
  NaiAgentWikiImages? images,
}) => {
  'wiki_query': (name, params, cancellation) async {
    cancellation.check();
    final tags = params['tags'];
    if (tags is! List ||
        tags.isEmpty ||
        tags.length > 20 ||
        tags.any((tag) => tag is! String || tag.trim().isEmpty)) {
      throw const NaiAgentToolError(
        'invalid_tags',
        'Provide 1 to 20 canonical tags',
      );
    }
    final offset = params['offset'] ?? 0, limit = params['limit'] ?? 12000;
    if (offset is! int ||
        offset < 0 ||
        limit is! int ||
        limit < 1 ||
        limit > 24000) {
      throw const NaiAgentToolError(
        'invalid_page',
        'Expected offset >= 0 and limit 1 to 24000 characters',
      );
    }
    final names = tags.cast<String>().map(TagNormalizer.normalize).toSet();
    if (params['include_examples'] != null &&
            params['include_examples'] is! bool ||
        params['include_examples'] == true &&
            (names.length != 1 || images == null)) {
      throw const NaiAgentToolError(
        'invalid_examples',
        'Request examples for one tag',
      );
    }
    Map<String, dynamic> examples = {};
    if (params['include_examples'] == true) {
      try {
        examples = await images!.list(names.single, params, cancellation);
      } on NaiAgentToolError {
        rethrow;
      } catch (_) {
        cancellation.check();
        examples = {'examples': [], 'examples_error': 'unavailable'};
      }
    }
    final pages = await ref.read(tagWikiRepositoryProvider).findAll(names);
    cancellation.check();
    // A batch must not multiply a 24k-character page into twenty full pages.
    final bodyLimit = (limit ~/ pages.length.clamp(1, 20)).clamp(1, limit);
    return naiAgentTextResult({
      'pages': [
        for (final tag in names)
          if (pages[tag] case final page?)
            {
              'tag': tag,
              'source_url': page.sourceUrl,
              'body': page.body.substring(
                offset.clamp(0, page.body.length),
                (offset + bodyLimit).clamp(0, page.body.length),
              ),
              'body_language': 'source',
              'total_characters': page.body.length,
              'next_offset': offset + bodyLimit < page.body.length
                  ? offset + bodyLimit
                  : null,
            }
          else
            {'tag': tag, 'found': false},
      ],
      'source': 'local_wiki',
      'body_limit_per_page': bodyLimit,
      ...examples,
    });
  },
  'tag_query': (name, params, cancellation) async {
    cancellation.check();
    final query = params['query'];
    final limit = params['limit'] ?? 20;
    if (query is! String ||
        query.trim().isEmpty ||
        query.length > 200 ||
        limit is! int ||
        limit < 1 ||
        limit > 100) {
      throw const NaiAgentToolError(
        'invalid_query',
        'Provide an English tag query and limit 1 to 100',
      );
    }
    final repository = ref.read(unifiedTagRepositoryProvider);
    final matches = params['contains'] == true
        ? await repository.searchContains(query, limit: limit)
        : await repository.search(
            CompletionQuery(
              fullText: query,
              cursorPosition: query.length,
              token: TagNormalizer.normalize(query),
              replacementRange: TextReplacementRange(
                start: 0,
                end: query.length,
              ),
              existingTags: const {},
              limit: limit,
              locale: 'en',
            ),
          );
    cancellation.check();
    final terms = await ref
        .read(tagTranslationGlossaryProvider)
        .termsFor(matches.map((candidate) => candidate.canonicalTag));
    cancellation.check();
    return naiAgentTextResult({
      'tags': [
        for (final candidate in matches)
          {
            'tag': candidate.canonicalTag,
            'category': candidate.category.name,
            'post_count': candidate.postCount,
            'aliases': candidate.aliases,
            if (candidate.matchedAlias != null)
              'matched_alias': candidate.matchedAlias,
            ...?terms[candidate.canonicalTag],
          },
      ],
      'source': 'local_catalog_and_synced_tags',
      'network_requests': 0,
    });
  },
  'tag_related': (name, params, cancellation) async {
    cancellation.check();
    const keys = {'tags', 'exclude', 'categories', 'limit'};
    List<String> names(Object? value, int min, int max) {
      if (value is! List ||
          value.length < min ||
          value.length > max ||
          value.any(
            (v) => v is! String || v.trim().isEmpty || v.length > 512,
          )) {
        throw const NaiAgentToolError(
          'invalid_query',
          'Provide bounded nonempty tag names',
        );
      }
      return value.cast<String>();
    }

    final limit = params['limit'] ?? 20;
    if (params.keys.any((key) => !keys.contains(key)) ||
        limit is! int ||
        limit < 1 ||
        limit > 50) {
      throw const NaiAgentToolError(
        'invalid_query',
        'Expected tag_related fields and limit 1 to 50',
      );
    }
    final inputs = names(params['tags'], 1, 20);
    final excluded = names(params['exclude'] ?? const [], 0, 500);
    final categoryNames = names(
      params['categories'] ?? const ['general'],
      1,
      8,
    );
    final categories = <TagCategory>{};
    for (final category in categoryNames) {
      final match = TagCategory.values
          .where((v) => v.name == category && v != TagCategory.library)
          .firstOrNull;
      if (match == null) {
        throw const NaiAgentToolError('invalid_query', 'Unknown tag category');
      }
      categories.add(match);
    }
    final normalized = {
      for (final raw in [...inputs, ...excluded])
        raw: TagNormalizer.normalize(raw),
    };
    final catalog = ref.read(tagCatalogRepositoryProvider);
    final records = await catalog.recordsByCanonicalTag(normalized.values);
    final aliases = await catalog.exactAliases(
      normalized.values.where((tag) => !records.containsKey(tag)),
    );
    cancellation.check();
    final resolved = <Map<String, String>>[];
    final unknown = <String>[];
    final seeds = <String>{};
    for (final input in inputs.toSet()) {
      final normalizedTag = normalized[input]!;
      final tag =
          records[normalizedTag]?.canonicalTag ??
          aliases[normalizedTag]?.canonicalTag;
      if (tag == null) {
        unknown.add(input);
      } else {
        resolved.add({'input': input, 'tag': tag});
        seeds.add(tag);
      }
    }
    final exclude = <String>{...seeds};
    for (final raw in excluded) {
      final tag = normalized[raw]!;
      exclude.add(
        records[tag]?.canonicalTag ?? aliases[tag]?.canonicalTag ?? tag,
      );
    }
    final List<RelatedTagMatch> matches = seeds.isEmpty
        ? const []
        : await ref
              .read(cooccurrenceCompletionSourceProvider)
              .related(
                seeds.toList(),
                exclude: exclude,
                categories: categories,
                limit: limit,
              );
    cancellation.check();
    final terms = await ref
        .read(tagTranslationGlossaryProvider)
        .termsFor(matches.map((match) => match.candidate.canonicalTag));
    cancellation.check();
    return naiAgentTextResult({
      'source': 'local_cooccurrence',
      'network_requests': 0,
      'algorithm': 'jaccard_frequency',
      'resolved': resolved,
      'unknown': unknown,
      'items': [
        for (final match in matches)
          {
            'tag': match.candidate.canonicalTag,
            'category': match.candidate.category.name,
            'post_count': match.candidate.postCount,
            'score': match.candidate.relatedScore,
            'sources': match.sources,
            'support': match.sources.length,
            if (terms[match.candidate.canonicalTag]?['zh'] case final zh?)
              'translation': zh,
          },
      ],
    });
  },
};
