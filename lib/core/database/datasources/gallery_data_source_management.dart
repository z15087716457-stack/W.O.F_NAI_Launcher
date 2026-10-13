part of 'gallery_data_source.dart';

extension GalleryImageManagementQueries on GalleryDataSource {
  /// Keep image IDs, metadata, favorites, memberships and soft deletion when
  /// an actual directory is renamed. Match path boundaries, not name prefixes.
  Future<int> relocateDirectoryRecords(
    String oldRoot,
    String newRoot, {
    Map<String, String> aliases = const {},
  }) async {
    final count = await execute(
      'relocateDirectoryRecords',
      (db) => db.transaction((txn) async {
        final rows = await txn.query(
          GalleryDataSource._imagesTable,
          columns: ['id', 'file_path'],
        );
        var changed = 0;
        final mappings = {...aliases, oldRoot: newRoot};
        for (final row in rows) {
          final old = row['file_path'] as String;
          final mapping = mappings.entries
              .where((entry) => galleryPathIsWithin(entry.key, old))
              .firstOrNull;
          if (mapping == null) continue;
          final normalizedRoot = normalizeGalleryFilePath(
            mapping.key,
          ).replaceAll(RegExp(r'[\\/]+$'), '');
          final relative = normalizeGalleryFilePath(old)
              .substring(normalizedRoot.length)
              .replaceFirst(RegExp(r'^[\\/]+'), '');
          final target = '${mapping.value}${Platform.pathSeparator}$relative';
          await txn.update(
            GalleryDataSource._imagesTable,
            {
              'file_path': target,
              'indexed_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [row['id']],
          );
          changed++;
        }
        return changed;
      }),
    );
    if (count > 0) {
      _imageCache.clear();
      _markDataChanged();
    }
    return count;
  }

  Future<Map<String, dynamic>> readCollectionManagementState() => execute(
    'readCollectionManagementState',
    (db) => db.transaction((txn) async {
      final collections = await txn.query(
        GalleryDataSource._collectionsTable,
        orderBy: 'id',
      );
      final members = await txn.rawQuery('''
          SELECT m.collection_id, m.image_id, m.added_at,
                 i.file_path, i.is_deleted,
                 CASE WHEN f.image_id IS NULL THEN 0 ELSE 1 END AS favorite
          FROM ${GalleryDataSource._collectionItemsTable} m
          LEFT JOIN ${GalleryDataSource._imagesTable} i ON i.id = m.image_id
          LEFT JOIN ${GalleryDataSource._favoritesTable} f ON f.image_id = m.image_id
          ORDER BY m.collection_id, m.image_id
        ''');
      return {'collections': collections, 'members': members};
    }),
  );

  /// Uncached record for explicit management, including the native delete pool.
  Future<GalleryImageRecord?> readImageForManagement(int id) =>
      execute('readImageForManagement', (db) async {
        final rows = await db.query(
          GalleryDataSource._imagesTable,
          where: 'id = ?',
          whereArgs: [id],
        );
        return rows.isEmpty ? null : GalleryImageRecord.fromMap(rows.single);
      });

  Future<List<GalleryImageRecord>> queryDeletedImageRecords({
    required int offset,
    required int limit,
  }) => execute('queryDeletedImageRecords', (db) async {
    final rows = await db.query(
      GalleryDataSource._imagesTable,
      where: 'is_deleted = 1',
      orderBy: 'id DESC',
      offset: offset,
      limit: limit,
    );
    return rows.map(GalleryImageRecord.fromMap).toList();
  });
}
