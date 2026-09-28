import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';

void main() {
  test(
    'merges local prefix and substring results without duplicates',
    () async {
      final catalog = _Source([_tag('blue_hair')]);
      final dictionary = _Source([_tag('blue_hair', translation: '蓝发')]);
      final related = _Source([_tag('long_hair')]);
      final service = LocalTagExpansionService(
        catalog: catalog,
        chineseDictionary: dictionary,
        relatedTags: related,
        translations: const _Translations(),
        substringSearch: (input, {limit = 20}) async => [
          _tag('blue_hair'),
          _tag('long_blue_hair'),
        ],
      );

      final english = await service.search(
        'blue',
        locale: 'zh',
        existingTags: {'blue_hair'},
      );
      final chinese = await service.search('蓝发', locale: 'zh');
      final suggestions = await service.related(
        'blue hair',
        locale: 'zh',
        existingTags: {'blue_hair'},
      );

      expect(english.map((row) => row.canonicalTag), [
        'blue_hair',
        'long_blue_hair',
      ]);
      expect(english.first.isExisting, isTrue);
      expect(english.first.translation, '蓝发');
      expect(chinese.single.canonicalTag, 'blue_hair');
      expect(catalog.queries, hasLength(1));
      expect(dictionary.queries, hasLength(1));
      expect(suggestions.single.canonicalTag, 'long_hair');
      expect(related.queries.single.relatedTag, 'blue_hair');
      expect(related.queries.single.token, isEmpty);
    },
  );
}

CompletionCandidate _tag(String name, {String? translation}) =>
    CompletionCandidate(
      canonicalTag: name,
      category: TagCategory.general,
      postCount: 100,
      matchKind: CompletionMatchKind.englishPrefix,
      sources: const {CompletionSourceKind.base},
      translation: translation,
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

class _Translations implements TranslationResolver {
  const _Translations();

  @override
  Future<Map<String, String>> resolve(
    List<String> canonicalTags, {
    required String locale,
  }) async => {'blue_hair': '蓝发'};
}
