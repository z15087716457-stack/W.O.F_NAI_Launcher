import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/autocomplete/unified_tag_repository.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/visible_tag_translation_cache.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_knowledge_tools.dart';

class _Wiki implements TagWikiRepository {
  @override
  Future<TagWikiEntry?> find(String tag) async => tag.startsWith('large_page')
      ? TagWikiEntry(
          tag: tag,
          body: 'long body ' * 4000,
          sourceUrl: 'https://danbooru.donmai.us/wiki_pages/$tag',
        )
      : tag == 'long_hair'
      ? const TagWikiEntry(
          tag: 'long_hair',
          body:
              'Long hair is hair longer than shoulder-length.\n\nExamples\npost #123',
          sourceUrl: 'https://danbooru.donmai.us/wiki_pages/long_hair',
        )
      : null;
}

class _Cache extends VisibleTagTranslationCache {
  @override
  Future<Map<String, CachedVisibleTagTranslation>> chineseTerms(
    Iterable<String> tags,
  ) async => {
    if (tags.contains('long_hair'))
      'long_hair': const CachedVisibleTagTranslation(nameZh: '长发'),
  };
}

class _Tags extends UnifiedTagRepository {
  _Tags()
    : super(
        catalog: TagCatalogRepository(),
        runtime: () async =>
            throw StateError('No network or runtime DB in this fixture'),
      );
  String? requested;
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async {
    requested = query.token;
    return [
      const CompletionCandidate(
        canonicalTag: 'long_hair',
        category: TagCategory.general,
        postCount: 6300000,
        aliases: ['longhair'],
        matchedAlias: 'longhair',
        matchKind: CompletionMatchKind.aliasExact,
        sources: {CompletionSourceKind.base},
      ),
    ];
  }
}

void main() {
  late ProviderContainer container;
  late _Tags tags;
  setUp(() {
    tags = _Tags();
    container = ProviderContainer(
      overrides: [
        tagWikiRepositoryProvider.overrideWithValue(_Wiki()),
        visibleTagTranslationCacheProvider.overrideWithValue(_Cache()),
        unifiedTagRepositoryProvider.overrideWithValue(tags),
      ],
    );
  });
  tearDown(() => container.dispose());
  Future<Map<String, dynamic>> run(
    String name,
    Map<String, dynamic> params, {
    NaiAgentCancellation? cancellation,
  }) async => container.read(
    Provider((ref) => naiAgentKnowledgeTools(ref)),
  )[name]!(name, params, cancellation ?? NaiAgentCancellation());

  test(
    'wiki normalizes tags, pages source text and reports missing entries truthfully',
    () async {
      final first = await run('wiki_query', {
        'tags': ['Long Hair', 'missing'],
        'limit': 10,
      });
      final pages = first['details']['pages'] as List;
      expect(pages[0]['tag'], 'long_hair');
      expect(pages[0]['body'], 'Long hair ');
      expect(pages[0]['next_offset'], 10);
      expect(pages[0]['body_language'], 'source');
      expect(pages[1]['found'], isFalse);
      final next = await run('wiki_query', {
        'tags': ['long_hair'],
        'offset': 10,
        'limit': 10,
      });
      expect(next['details']['pages'][0]['body'], 'is hair lo');
    },
  );
  test(
    'tag lookup retains aliases and cached Chinese name without inventing translation',
    () async {
      final result = await run('tag_query', {'query': 'longhair'});
      final tag = result['details']['tags'][0];
      expect(tags.requested, 'longhair');
      expect(tag['tag'], 'long_hair');
      expect(tag['aliases'], ['longhair']);
      expect(tag['zh'], '长发');
      expect(tag['definition_language'], 'source');
      expect(result['details']['network_requests'], 0);
    },
  );
  test(
    'batch wiki text stays within one page budget and offers individual continuations',
    () async {
      final result = await run('wiki_query', {
        'tags': [for (var i = 0; i < 20; i++) 'large_page_$i'],
        'limit': 24000,
      });
      final pages = result['details']['pages'] as List;
      final total = pages.fold<int>(
        0,
        (sum, page) => sum + (page['body'] as String).length,
      );
      expect(total, lessThanOrEqualTo(24000));
      expect(pages.every((page) => page['next_offset'] != null), isTrue);
      expect(result['details']['body_limit_per_page'], 1200);
    },
  );
  test(
    'oversized queries and already cancelled lookup refuse rather than broad querying',
    () async {
      await expectLater(
        run('wiki_query', {'tags': List.filled(21, 'long_hair')}),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'invalid_tags',
          ),
        ),
      );
      await expectLater(
        run('tag_query', {'query': 'long_hair', 'limit': 100000}),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'invalid_query',
          ),
        ),
      );
      final cancellation = NaiAgentCancellation()..cancel();
      await expectLater(
        run('tag_query', {'query': 'longhair'}, cancellation: cancellation),
        throwsA(
          isA<NaiAgentToolError>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
    },
  );
}
