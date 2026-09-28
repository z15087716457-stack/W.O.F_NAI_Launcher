import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../autocomplete/autocomplete_providers.dart';
import 'local_tag_expansion_service.dart';

final localTagExpansionServiceProvider = Provider<LocalTagExpansionService>((
  ref,
) {
  final catalog = ref.watch(tagCatalogRepositoryProvider);
  final dictionary = ref.watch(zhDictionaryServiceProvider);
  return LocalTagExpansionService(
    catalog: catalog,
    chineseDictionary: dictionary,
    relatedTags: ref.watch(cooccurrenceCompletionSourceProvider),
    translations: dictionary,
    substringSearch: catalog.searchContains,
    popularSearch: catalog.popular,
  );
});
