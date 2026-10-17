import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../autocomplete/autocomplete_providers.dart';
import '../autocomplete/completion_models.dart';
import '../autocomplete/unified_tag_repository.dart';
import '../database/services/service_providers.dart';
import 'local_tag_expansion_service.dart';
import 'tag_semantics_repository.dart';

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
  return LocalTagExpansionService(
    catalog: catalog,
    relatedTags: ref.watch(cooccurrenceCompletionSourceProvider),
    substringSearch: catalog.searchContains,
    popularSearch: catalog.popular,
    semanticNames: (input, {limit = 80}) async {
      final repository = ref.read(tagSemanticsRepositoryProvider);
      final candidates = await catalog.byNames(
        await repository.searchNames(input, limit: limit),
      );
      final profiles = await repository.findAll(
        candidates.map((c) => c.canonicalTag),
      );
      return [
        for (final candidate in candidates)
          candidate.copyWith(
            translation: profiles[candidate.canonicalTag]?.coreZh,
            retrievalOrigins: const ['chinese-name'],
            matchKind: profiles[candidate.canonicalTag]?.coreZh == input.trim()
                ? CompletionMatchKind.chineseExact
                : CompletionMatchKind.chineseContains,
          ),
      ];
    },
  );
});
