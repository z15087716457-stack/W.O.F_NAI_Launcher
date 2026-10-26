import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/services/gallery/gallery_filter_service.dart';
import '../../data/services/gallery/unified_gallery_service.dart';
import '../../data/services/precise_ref_library_storage_service.dart';
import '../../data/services/vibe_library_storage_service.dart';
import '../providers/floating_resource_windows_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/precise_ref_library_provider.dart';
import '../providers/prompt_block_library_provider.dart';
import '../providers/vibe_library_provider.dart';
import '../ui/refs/refs_contract.dart';
import 'blocks_mapping.dart';
import 'gallery_search_history.dart';
import 'refs_library_wiring.dart';
import 'refs_mapping.dart';

/// Moving, focusing or resizing a window must not re-run its library search.
final floatingResourceQueryProvider = Provider.autoDispose
    .family<
      ({String query, FloatingResourceScope scope, FloatingResourceKind kind})?,
      String
    >((ref, id) {
      return ref.watch(
        floatingResourceWindowsProvider.select((windows) {
          for (final window in windows) {
            if (window.id == id) {
              return (
                query: window.query,
                scope: window.scope,
                kind: window.kind,
              );
            }
          }
          return null;
        }),
      );
    });

/// Zero-based pages, 60 records each. queryRecords owns separate filter/cache/
/// cancellation state; never write to localGalleryNotifierProvider here.
final floatingGalleryPageProvider = FutureProvider.autoDispose
    .family<GalleryQueryPage, ({String id, int page})>((ref, request) async {
      if (request.page < 0) throw ArgumentError.value(request.page, 'page');
      final window = ref.watch(floatingResourceQueryProvider(request.id));
      if (window == null || window.kind != FloatingResourceKind.gallery) {
        return const GalleryQueryPage(records: [], totalCount: 0);
      }
      final service = ref.watch(galleryServiceProvider);
      return service.queryRecords(
        FilterCriteria(
          searchQuery: window.query,
          categoryFolderPath: window.scope.folderPath,
          categoryId: window.scope.categoryId,
          collectionId: window.scope.collectionId,
          showFavoritesOnly: window.scope.favoritesOnly,
        ),
        offset: request.page * 60,
        limit: 60,
      );
    });

final floatingBlocksProvider = FutureProvider.autoDispose
    .family<List<PromptBlock>, String>((ref, id) async {
      final window = ref.watch(floatingResourceQueryProvider(id));
      if (window == null || window.kind != FloatingResourceKind.blocks) {
        return const [];
      }
      final library = await ref.watch(
        promptBlockLibraryNotifierProvider.future,
      );
      final scope = window.scope;
      final blocks = scope.folderId == null
          ? library.blocks
          : library.blocksInFolderTree(scope.folderId);
      final collectionIds = scope.collectionId == null
          ? null
          : library
                .blocksInCollectionTree(scope.collectionId!)
                .map((b) => b.id)
                .toSet();
      return List.unmodifiable(
        blocks.where(
          (block) =>
              (!scope.favoritesOnly || block.isFavorite) &&
              (collectionIds == null || collectionIds.contains(block.id)) &&
              blockMatches(block, window.query),
        ),
      );
    });

/// Shared idempotent initialization, not a copy of either page controller.
final floatingRefsReadyProvider = FutureProvider.autoDispose
    .family<void, FloatingResourceKind>((ref, kind) async {
      switch (kind) {
        case FloatingResourceKind.vibe:
          await ref.read(vibeLibraryNotifierProvider.notifier).initialize();
        case FloatingResourceKind.precise:
          await ref
              .read(preciseRefLibraryNotifierProvider.notifier)
              .initialize();
        case FloatingResourceKind.gallery:
        case FloatingResourceKind.blocks:
          break;
      }
    });

final floatingRefsProvider = FutureProvider.autoDispose
    .family<List<RefsEntry>, String>((ref, id) async {
      final window = ref.watch(floatingResourceQueryProvider(id));
      if (window == null ||
          (window.kind != FloatingResourceKind.vibe &&
              window.kind != FloatingResourceKind.precise)) {
        return const [];
      }
      await ref.watch(floatingRefsReadyProvider(window.kind).future);
      final entries = <RefsEntry>[];
      if (window.kind == FloatingResourceKind.vibe) {
        final library = ref.watch(vibeLibraryNotifierProvider);
        if (library.error != null) throw StateError(library.error!);
        final storage = ref.watch(vibeLibraryStorageServiceProvider);
        final model = ref.watch(
          generationParamsNotifierProvider.select((p) => p.model),
        );
        final statuses =
            ref.watch(refsVibeStatusesProvider).valueOrNull ??
            const <String, RefsVibeStatus>{};
        entries.addAll([
          for (final entry in library.entries)
            mapVibeEntry(
              entry,
              model: model,
              status: statuses[entry.id],
              thumb: RefsLazyImage(
                storage,
                entry.id,
                storage.getDisplayThumbnailRevision(entry.id),
                () => storage.getDisplayThumbnail(entry.id),
              ),
            ),
        ]);
      } else {
        final library = ref.watch(preciseRefLibraryNotifierProvider);
        if (library.error != null) throw StateError(library.error!);
        final storage = ref.watch(preciseRefLibraryStorageServiceProvider);
        entries.addAll([
          for (final entry in library.entries)
            mapPreciseEntry(
              entry,
              thumb: RefsLazyImage(
                storage,
                entry.id,
                entry.hashCode,
                () => storage.getDisplayThumbnail(entry.id),
              ),
            ),
        ]);
      }
      return List.unmodifiable(
        filterRefsEntries(
          entries,
          RefsFilter(
            query: window.query,
            categoryId: window.scope.categoryId,
            view: window.scope.favoritesOnly
                ? RefsView.favorites
                : RefsView.all,
          ),
        ),
      );
    });

final floatingGalleryQueryActionsProvider = Provider(
  FloatingGalleryQueryActions.new,
);

/// Only the UI's explicit Enter/confirm action records history, not typing.
class FloatingGalleryQueryActions {
  FloatingGalleryQueryActions(this.ref);
  final Ref ref;

  Future<void> confirm(String id, String query) async {
    ref.read(floatingResourceWindowsProvider.notifier).setQuery(id, query);
    await ref.read(gallerySearchHistoryProvider.notifier).add(query);
  }
}
