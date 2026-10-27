import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/prompt_assistant/models/prompt_assistant_models.dart';
import '../../presentation/prompt_assistant/services/prompt_assistant_service.dart';

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
    semantics: ref.watch(tagSemanticsRepositoryProvider),
    readingLanguage: () => ref
        .read(promptAssistantServiceProvider)
        .targetLanguageFor(LauncherInterface.tagTranslate),
    semanticNames: (input, {limit = 80}) async {
      final repository = ref.read(tagSemanticsRepositoryProvider);
      final candidates = await catalog.byNames(
        await repository.searchNames(input, limit: limit),
      );
      return [
        for (final candidate in candidates)
          candidate.copyWith(
            retrievalOrigins: const ['chinese-name'],
            matchKind: CompletionMatchKind.chineseContains,
          ),
      ];
    },
  );
});
