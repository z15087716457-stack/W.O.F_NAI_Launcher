import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';

void main() {
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
