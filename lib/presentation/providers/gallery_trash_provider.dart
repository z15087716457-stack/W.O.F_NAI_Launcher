import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_providers.dart';
import '../../core/database/datasources/gallery_data_source.dart';
import '../../data/services/gallery/gallery_delete_pool_store.dart';
import '../../data/services/gallery/unified_gallery_service.dart';

/// Explicit deletion-pool scope. It never changes the normal library query.
final galleryTrashTimelineProvider = FutureProvider<List<GalleryTimelineEntry>>(
  (ref) async {
    final paths = await const GalleryDeletePoolStore().load();
    if (paths.isEmpty) return [];
    final manager = await ref.read(databaseManagerProvider.future);
    final source = manager.getDataSource<GalleryDataSource>('gallery');
    final dimensions = source == null
        ? <String, (int?, int?)>{}
        : await source.getImageDimensionsByPaths(paths, includeDeleted: true);
    final entries = <GalleryTimelineEntry>[];
    for (var start = 0; start < paths.length; start += 64) {
      final batch = paths.skip(start).take(64);
      final stats = await Future.wait([
        for (final path in batch) File(path).stat(),
      ]);
      for (final (i, path) in batch.indexed) {
        final stat = stats[i];
        if (stat.type != FileSystemEntityType.file) continue;
        entries.add(
          GalleryTimelineEntry(
            path: path,
            modifiedAt: stat.modified,
            width: dimensions[path]?.$1,
            height: dimensions[path]?.$2,
            size: stat.size,
          ),
        );
      }
    }
    return entries;
  },
);
