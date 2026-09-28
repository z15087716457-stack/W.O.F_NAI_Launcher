import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../autocomplete/autocomplete_providers.dart';
import '../autocomplete/unified_tag_repository.dart';
import '../database/services/service_providers.dart';
import 'local_tag_expansion_service.dart';

final unifiedTagRepositoryProvider = Provider<UnifiedTagRepository>((ref) {
  return UnifiedTagRepository(
    catalog: ref.watch(tagCatalogRepositoryProvider),
    runtime: () => ref.read(danbooruTagDataSourceProvider.future),
  );
});

final localTagExpansionServiceProvider = Provider<LocalTagExpansionService>((
  ref,
) {
  final catalog = ref.watch(unifiedTagRepositoryProvider);
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
