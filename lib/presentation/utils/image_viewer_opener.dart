import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/image_generation_provider.dart';
import '../providers/local_gallery_focus_provider.dart';
import '../providers/local_gallery_provider.dart';
import '../ui/viewer/viewer_contract.dart';
import '../widgets/common/image_detail/file_image_detail_data.dart';
import '../widgets/common/image_detail/image_detail_data.dart';
import 'image_viewer_callbacks.dart';
import '../wiring/image_viewer_backend.dart';
import '../wiring/image_viewer_gallery.dart';
import '../wiring/image_viewer_mapping.dart';
import '../wiring/image_viewer_session.dart';

class ImageViewerOpener {
  static Future<void> showGallery(
    BuildContext context, {
    required int initialIndex,
    String? scopeName,
  }) async {
    if (!context.mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    final existing = container.read(imageViewerSessionProvider);
    if (existing != null) return existing.done.future;
    final gallery = container.read(localGalleryNotifierProvider);
    final entries = gallery.timeline.entries;
    if (initialIndex < 0 || initialIndex >= entries.length) return;
    final target = entries[initialIndex].path;
    final notifier = container.read(localGalleryNotifierProvider.notifier);
    final byPath = {for (final entry in entries) entry.path: entry};
    final backend = ImageViewerBackend(
      keys: entries.map((entry) => entry.path).toList(),
      initialKey: target,
      load: (paths) async {
        await notifier.loadRecords(paths);
        return [
          for (final path in paths)
            LocalImageDetailData(
              notifier.cachedRecord(path) ?? notifier.recordFor(byPath[path]!),
              getFavoriteStatus: (path) =>
                  notifier.cachedRecord(path)?.isFavorite ?? false,
              aspectRatio: byPath[path]!.aspectRatio,
            ),
        ];
      },
      readMetadata: (image) =>
          (image as LocalImageDetailData).getMetadataAsync(),
      deleteImage: (path) =>
          container.read(imageViewerGalleryProvider).delete(path),
      restoreImage: (path) =>
          container.read(imageViewerGalleryProvider).restore(path),
    );
    container.read(localGalleryFocusNotifierProvider.notifier).focus(target);
    final session = ImageViewerSession(
      backend: backend,
      mode: ViewerMode.gallery,
      scope: ViewerScope(
        name: scopeName,
        sort: viewerSortOf(gallery.sortField),
      ),
      dimensions: {
        for (final entry in entries)
          if (entry.hasDimensions)
            entry.path: (width: entry.width!, height: entry.height!),
      },
      dates: {
        for (final entry in entries) entry.path: entry.modifiedAt.toLocal(),
      },
    );
    container.read(imageViewerSessionProvider.notifier).state = session;
    return session.done.future;
  }

  static Future<void> showSingle(
    BuildContext context, {
    required ImageDetailData image,
    bool showMetadataPanel = true,
    String? backLabel,
    ImageViewerCallbacks? callbacks,
  }) => showMultiple(context, images: [image], callbacks: callbacks);

  static Future<void> showMultiple(
    BuildContext context, {
    required List<ImageDetailData> images,
    int initialIndex = 0,
    bool showMetadataPanel = true,
    String? backLabel,
    bool showThumbnails = true,
    ImageViewerCallbacks? callbacks,
  }) async {
    if (!context.mounted || images.isEmpty) return;
    final container = ProviderScope.containerOf(context, listen: false);
    final existing = container.read(imageViewerSessionProvider);
    if (existing != null) return existing.done.future;
    final byKey = {for (final image in images) image.identifier: image};
    final backend = ImageViewerBackend(
      keys: byKey.keys.toList(),
      initialKey: images[initialIndex.clamp(0, images.length - 1)].identifier,
      load: (keys) async => [for (final key in keys) byKey[key]!],
      readMetadata: (image) async => switch (image) {
        final FileImageDetailData image => image.getMetadataAsync(),
        final GeneratedImageDetailData image => image.getMetadataAsync(),
        final LocalImageDetailData image => image.getMetadataAsync(),
        _ => image.metadata,
      },
      pageSize: images.length,
    );
    final generated = container
        .read(imageGenerationNotifierProvider)
        .mergedPanelImages;
    final session = ImageViewerSession(
      backend: backend,
      mode: ViewerMode.generation,
      save: callbacks?.onSave,
      dimensions: {
        for (final image in generated)
          image.id: (width: image.width, height: image.height),
      },
      dates: {
        for (final image in generated) image.id: image.createdAt.toLocal(),
      },
    );
    container.read(imageViewerSessionProvider.notifier).state = session;
    return session.done.future;
  }

  static void showSingleImmediate(
    BuildContext context, {
    required ImageDetailData image,
    bool showMetadataPanel = true,
    String? backLabel,
    ImageViewerCallbacks? callbacks,
    String? heroTag,
  }) {
    unawaited(showSingle(context, image: image, callbacks: callbacks));
  }

  static void showMultipleImmediate(
    BuildContext context, {
    required List<ImageDetailData> images,
    int initialIndex = 0,
    bool showMetadataPanel = true,
    String? backLabel,
    bool showThumbnails = true,
    ImageViewerCallbacks? callbacks,
  }) {
    unawaited(
      showMultiple(
        context,
        images: images,
        initialIndex: initialIndex,
        callbacks: callbacks,
      ),
    );
  }
}
