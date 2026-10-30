import 'dart:io';

import 'gallery_delete_pool_store.dart';

class GalleryTrashService {
  const GalleryTrashService({
    required this.restoreIndex,
    this.pool = const GalleryDeletePoolStore(),
  });
  final Future<void> Function(List<String>) restoreIndex;
  final GalleryDeletePoolStore pool;

  Future<List<String>> restore(List<String> paths) async {
    final pending = (await pool.load()).toSet();
    final targets = paths.where(pending.contains).toSet().toList();
    if (targets.isEmpty) return [];
    try {
      await pool.restore(targets, () => restoreIndex(targets));
    } catch (_) {
      await pool.addAll(targets);
      rethrow;
    }
    return targets;
  }

  /// Only explicitly confirmed pool members can be permanently removed.
  /// Failed files stay in the pool, matching startup cleanup semantics.
  Future<List<String>> purge(List<String> paths) async {
    final pending = (await pool.load()).toSet();
    final removed = <String>[];
    for (final path in paths.toSet().where(pending.contains)) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
        removed.add(path);
      } on FileSystemException {
        continue;
      }
    }
    await pool.removeAll(removed);
    return removed;
  }
}
