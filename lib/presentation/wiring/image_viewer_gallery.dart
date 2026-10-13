import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/datasources/gallery_data_source.dart';
import '../../core/utils/app_logger.dart';
import '../../data/services/gallery/gallery_delete_pool_store.dart';
import '../providers/bulk_operation_provider.dart';
import '../providers/collection_provider.dart';
import '../../core/database/database_providers.dart';
import '../providers/gallery_category_provider.dart';
import '../providers/local_gallery_provider.dart';
import '../ui/viewer/viewer_contract.dart';
import 'image_viewer_mapping.dart';

final imageViewerGalleryProvider = Provider<ImageViewerGallery>(
  (ref) => ImageViewerGallery(ref),
);

class ImageViewerGallery {
  ImageViewerGallery(this.ref);
  final Ref ref;
  Future<void> _queue = Future.value();

  Future<void> serialize(Future<void> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then((_) {}, onError: (Object error, StackTrace stack) {});
    return result;
  }

  Future<void> refresh() async {
    await ref.read(localGalleryNotifierProvider.notifier).reloadTimeline();
    await ref.read(collectionNotifierProvider.notifier).refresh();
    await ref.read(galleryCategoryNotifierProvider.notifier).refresh();
  }

  Future<bool> delete(String path) async {
    final result = await ref
        .read(bulkOperationNotifierProvider.notifier)
        .bulkDelete([path]);
    if (result.success == 0) return false;
    try {
      await refresh();
    } catch (error) {
      AppLogger.w(
        'Viewer deleted image; refresh failed: $error',
        'ImageViewer',
      );
    }
    return true;
  }

  Future<void> restore(String path) async {
    final manager = await ref.read(databaseManagerProvider.future);
    final dataSource = manager.getDataSource<GalleryDataSource>('gallery');
    if (dataSource == null) throw StateError('GalleryDataSource not found');
    const pool = GalleryDeletePoolStore();
    final pending = (await pool.load()).contains(path);
    await pool.removeAll([path]);
    try {
      await dataSource.batchRestoreDeleted([path]);
    } catch (_) {
      if (pending) await pool.addAll([path]);
      rethrow;
    }
    await ref.read(localGalleryNotifierProvider.notifier).clearRecentlyDeleted([
      path,
    ]);
    await refresh();
  }

  Future<void> setFavorite(String path, bool value) => serialize(() async {
    final gallery = ref.read(localGalleryNotifierProvider.notifier);
    final service = await gallery.getService();
    if (await service.isFavorite(path) != value) {
      await gallery.toggleFavorite(path);
    }
    if (await gallery.syncFavoriteStatus(path) != value) {
      throw StateError('Favorite update failed');
    }
  });

  Future<List<ViewerCollection>> collections(String path) async {
    await ref.read(collectionNotifierProvider.notifier).initialize();
    final state = ref.read(collectionNotifierProvider);
    if (state.error != null) throw StateError(state.error!);
    final members = await ref
        .read(collectionRepositoryProvider)
        .getCollectionIdsForImage(path);
    return viewerCollectionsOf(state.collections, members);
  }

  Future<void> setCollection(String path, String id, bool member) =>
      serialize(() async {
        final repository = ref.read(collectionRepositoryProvider);
        if (await repository.isImageInCollection(id, path) == member) return;
        final notifier = ref.read(collectionNotifierProvider.notifier);
        if (member) {
          await notifier.addImagesToCollection(id, [path]);
        } else {
          await notifier.removeImagesFromCollection(id, [path]);
        }
        if (ref.read(collectionNotifierProvider).error != null ||
            await repository.isImageInCollection(id, path) != member) {
          throw StateError('Collection update failed');
        }
        await ref
            .read(localGalleryNotifierProvider.notifier)
            .syncFavoriteStatus(path);
      });
}
