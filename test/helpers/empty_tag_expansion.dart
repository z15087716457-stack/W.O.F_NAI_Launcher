import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';

/// Editor wiring tests exercise editing and imports without opening tag databases.
/// Tag retrieval has dedicated provider and picker integration suites.
final emptyTagExpansionOverride = localTagExpansionServiceProvider
    .overrideWithValue(
      LocalTagExpansionService(
        catalog: const _EmptySource(),
        relatedTags: const _EmptySource(),
        substringSearch: (_, {limit = 20}) async => const [],
        popularSearch: ({limit = 12}) async => const [],
      ),
    );

class _EmptySource implements CompletionSource {
  const _EmptySource();

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async =>
      const [];
}
