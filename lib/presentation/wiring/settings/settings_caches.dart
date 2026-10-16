import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/autocomplete/autocomplete_providers.dart';
import '../../../core/cache/cache_footprint.dart';
import '../../../core/wiki/auto_tag_translation_controller.dart';
import '../../../core/wiki/visible_tag_translation_cache.dart';
import '../../../core/wiki/wiki_example_repository.dart';
import '../../providers/online_gallery_provider.dart';
import '../../ui/settings/settings_contract.dart';

final settingsCachesProvider = Provider((ref) => SettingsCaches(ref));

/// One definition of the payloads counted and cleared by the two cache rows.
/// Image files, user records, the bundled catalog and vector indices are not
/// request-result caches and are deliberately outside this operation.
class SettingsCaches {
  SettingsCaches(this.ref);
  final Ref ref;

  Future<Map<SettingsCacheKind, CacheFootprint>> footprint() async {
    final db = ref.read(autocompleteCacheDatabaseProvider);
    final counts = await db.statistics();
    final bytes = await db.contentBytes();
    var danbooru = CacheFootprint(
      counts['danbooruCache']!,
      bytes['danbooruCache']!,
    );
    if (ref.exists(danbooruCompletionSourceProvider)) {
      danbooru += ref.read(danbooruCompletionSourceProvider).footprint;
    }
    if (ref.exists(onlineGalleryNotifierProvider)) {
      danbooru += ref
          .read(onlineGalleryNotifierProvider.notifier)
          .danbooruCacheFootprint;
    }
    if (ref.exists(wikiExampleRepositoryProvider)) {
      danbooru += ref.read(wikiExampleRepositoryProvider).footprint;
    }
    final visible = await ref
        .read(visibleTagTranslationCacheProvider)
        .footprint();
    return {
      SettingsCacheKind.danbooru: danbooru,
      SettingsCacheKind.translation:
          CacheFootprint(counts['aiTranslations']!, bytes['aiTranslations']!) +
          visible,
    };
  }

  Future<void> clear(SettingsCacheKind kind) async {
    final db = ref.read(autocompleteCacheDatabaseProvider);
    switch (kind) {
      case SettingsCacheKind.danbooru:
        if (ref.exists(danbooruCompletionSourceProvider)) {
          ref.read(danbooruCompletionSourceProvider).clearMemoryCache();
        }
        if (ref.exists(onlineGalleryNotifierProvider)) {
          ref.read(onlineGalleryNotifierProvider.notifier).clearDanbooruCache();
        }
        if (ref.exists(wikiExampleRepositoryProvider)) {
          ref.read(wikiExampleRepositoryProvider).clearCache();
        }
        await db.clearDanbooruCache();
      case SettingsCacheKind.translation:
        final legacy = db.clearAiTranslationCache();
        final visible = ref.exists(autoTagTranslationProvider)
            ? ref.read(autoTagTranslationProvider).clearCache()
            : ref.read(visibleTagTranslationCacheProvider).clear();
        await Future.wait([legacy, visible]);
    }
  }
}

final settingsCacheFootprintProvider = FutureProvider(
  (ref) => ref.read(settingsCachesProvider).footprint(),
);
