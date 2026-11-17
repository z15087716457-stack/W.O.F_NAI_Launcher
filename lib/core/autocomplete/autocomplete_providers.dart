import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/services/service_providers.dart';
import 'legacy_autocomplete_cache.dart';
import 'cooccurrence_completion_source.dart';
import 'tag_catalog_repository.dart';

final legacyAutocompleteCacheProvider = Provider(
  (ref) => LegacyAutocompleteCache(),
);

final tagCatalogRepositoryProvider = Provider<TagCatalogRepository>((ref) {
  final repository = TagCatalogRepository();
  ref.onDispose(() => unawaited(repository.dispose()));
  return repository;
});

final cooccurrenceCompletionSourceProvider =
    Provider<CooccurrenceCompletionSource>((ref) {
      final dataSource = ref.watch(cooccurrenceDataSourceProvider.future);
      return CooccurrenceCompletionSource.withLoader(
        () => dataSource,
        catalog: ref.watch(tagCatalogRepositoryProvider),
      );
    });
