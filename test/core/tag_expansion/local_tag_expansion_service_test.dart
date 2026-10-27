import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/tag_expansion/tag_semantics_repository.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';

void main() {
  for (final language in ['zh', 'zh-TW', 'en', 'ja', 'ko']) {
    test(
      'batch local names follow reading language $language, not UI locale',
      () async {
        final semantics = _Semantics();
        final source = _Source([_tag('blue_hair'), _tag('unknown')]);
        final service = LocalTagExpansionService(
          catalog: source,
          relatedTags: source,
          substringSearch: (_, {limit = 20}) async => [_tag('blue_hair')],
          popularSearch: ({limit = 12}) async => source.results,
          semantics: semantics,
          readingLanguage: () => language,
        );
        for (final rows in [
          await service.search(
            'blue',
            locale: 'en',
            existingTags: {'blue_hair'},
          ),
          await service.related('eyes', locale: 'en'),
          await service.popular(locale: 'en'),
        ]) {
          expect(
            rows.first.translation,
            language.startsWith('zh') ? '蓝发' : null,
          );
          expect(rows.last.translation, isNull);
        }
        expect(
          semantics.batches,
          language.startsWith('zh')
              ? [
                  ['blue_hair', 'unknown'],
                  ['blue_hair', 'unknown'],
                  ['blue_hair', 'unknown'],
                ]
              : isEmpty,
        );
      },
    );
  }

  test('Chinese lookup never waits for the English runtime index', () async {
    final catalog = _PendingSource();
    final service = LocalTagExpansionService(
      catalog: catalog,
      relatedTags: catalog,
      substringSearch: (_, {limit = 20}) =>
          throw StateError('English contains'),
      popularSearch: ({limit = 12}) async => [],
      semanticNames: (input, {limit = 80}) async => [
        _tag(
          'blue_hair',
        ).copyWith(matchKind: CompletionMatchKind.chineseContains),
      ],
      semantics: _Semantics(),
    );
    final rows = await service.search('蓝发', locale: 'zh');
    expect(catalog.calls, 0);
    expect(rows.single.canonicalTag, 'blue_hair');
    expect(rows.single.translation, '蓝发');
    expect(rows.single.matchKind, CompletionMatchKind.chineseExact);
  });
  test(
    'merges local prefix and substring results without duplicates',
    () async {
      final catalog = _Source([_tag('blue_hair')]);
      final related = _Source([_tag('long_hair')]);
      final service = LocalTagExpansionService(
        catalog: catalog,
        relatedTags: related,
        substringSearch: (input, {limit = 20}) async => [
          _tag('blue_hair'),
          _tag('long_blue_hair'),
        ],
        popularSearch: ({limit = 12}) async => [
          _tag('solo'),
          _tag('blue_hair'),
        ],
      );

      final english = await service.search(
        'blue',
        locale: 'zh',
        existingTags: {'blue_hair'},
      );
      final suggestions = await service.related(
        'blue hair',
        locale: 'zh',
        existingTags: {'blue_hair'},
      );
      final popular = await service.popular(
        locale: 'zh',
        existingTags: {'solo'},
      );

      expect(english.map((row) => row.canonicalTag), [
        'blue_hair',
        'long_blue_hair',
      ]);
      expect(english.first.isExisting, isTrue);
      expect(catalog.queries, hasLength(1));
      expect(suggestions.single.canonicalTag, 'long_hair');
      expect(related.queries.single.relatedTag, 'blue_hair');
      expect(related.queries.single.token, isEmpty);
      expect(popular.single.canonicalTag, 'blue_hair');

      await service.search('b', locale: 'en', limit: 80);
      expect(catalog.queries.last.limit, 80);
    },
  );
}

CompletionCandidate _tag(String name) => CompletionCandidate(
  canonicalTag: name,
  category: TagCategory.general,
  postCount: 100,
  matchKind: CompletionMatchKind.englishPrefix,
  sources: const {CompletionSourceKind.base},
);

class _Semantics extends TagSemanticsRepository {
  _Semantics() : super(() async => throw StateError('no real database'));
  final batches = <List<String>>[];
  @override
  Future<Map<String, TagSemanticProfile>> findAll(Iterable<String> tags) async {
    batches.add(tags.toList());
    return const {
      'blue_hair': TagSemanticProfile(
        tag: 'blue_hair',
        coreZh: '蓝发',
        synonymsZh: [],
        summaryZh: '',
        sourceCategory: 0,
        sourcePostCount: 1,
      ),
    };
  }
}

class _PendingSource implements CompletionSource {
  var calls = 0;
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) {
    calls++;
    return Completer<List<CompletionCandidate>>().future;
  }
}

class _Source implements CompletionSource {
  _Source(this.results);

  final List<CompletionCandidate> results;
  final List<CompletionQuery> queries = [];

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async {
    queries.add(query);
    return results;
  }
}
