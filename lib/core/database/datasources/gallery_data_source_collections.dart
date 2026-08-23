part of 'gallery_data_source.dart';

/// 收藏集（collections）数据访问
///
/// 链接式收藏：`gallery_collection_items` 只存 (collection_id, image_id)，
/// 不复制文件。删除收藏集级联删除成员关系，不触碰图片文件。
extension GalleryDataSourceCollections on GalleryDataSource {
  /// 创建收藏集，返回新收藏集 ID
  Future<String> createCollection(String name) async {
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await execute('createCollection', (db) async {
      final sortResult = await db.rawQuery(
        'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next '
        'FROM ${GalleryDataSource._collectionsTable}',
      );
      final nextSortOrder =
          (sortResult.first['next'] as num?)?.toInt() ?? 0;

      await db.insert(GalleryDataSource._collectionsTable, {
        'id': id,
        'name': name.trim(),
        'sort_order': nextSortOrder,
        'created_at': now,
      });
    });
    _markDataChanged();
    return id;
  }

  /// 重命名收藏集
  Future<bool> renameCollection(String id, String newName) async {
    final updated = await execute('renameCollection', (db) async {
      return db.update(
        GalleryDataSource._collectionsTable,
        {'name': newName.trim()},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    if (updated > 0) _markDataChanged();
    return updated > 0;
  }

  /// 删除收藏集（级联删除成员关系，不删图片文件）
  Future<bool> deleteCollection(String id) async {
    final deleted = await execute('deleteCollection', (db) async {
      return db.transaction((txn) async {
        await txn.delete(
          GalleryDataSource._collectionItemsTable,
          where: 'collection_id = ?',
          whereArgs: [id],
        );
        return txn.delete(
          GalleryDataSource._collectionsTable,
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    });
    if (deleted > 0) _markDataChanged();
    return deleted > 0;
  }

  /// 收藏集列表（含未删除图片成员计数），按 sort_order、created_at 升序
  Future<List<GalleryCollectionInfo>> listCollectionsWithCounts() async {
    return _trackQuery('listCollectionsWithCounts', () async {
      return execute('listCollectionsWithCounts', (db) async {
        final rows = await db.rawQuery('''
          SELECT
            c.id,
            c.name,
            c.sort_order,
            c.created_at,
            (
              SELECT COUNT(*)
              FROM ${GalleryDataSource._collectionItemsTable} ci
              INNER JOIN ${GalleryDataSource._imagesTable} i
                ON i.id = ci.image_id
              WHERE ci.collection_id = c.id AND i.is_deleted = 0
            ) AS image_count
          FROM ${GalleryDataSource._collectionsTable} c
          ORDER BY c.sort_order ASC, c.created_at ASC
        ''');
        return [
          for (final row in rows) GalleryCollectionInfo.fromMap(row),
        ];
      });
    });
  }

  /// 按给定 ID 顺序重排收藏集（sort_order = 下标）
  Future<bool> reorderCollections(List<String> orderedIds) async {
    if (orderedIds.isEmpty) return false;

    final ok = await execute('reorderCollections', (db) async {
      return db.transaction((txn) async {
        for (var i = 0; i < orderedIds.length; i++) {
          await txn.update(
            GalleryDataSource._collectionsTable,
            {'sort_order': i},
            where: 'id = ?',
            whereArgs: [orderedIds[i]],
          );
        }
        return true;
      });
    });
    if (ok) _markDataChanged();
    return ok;
  }

  /// 添加图片到收藏集（幂等）
  Future<bool> addImageToCollection(
    String collectionId,
    int imageId,
  ) async {
    return execute('addImageToCollection', (db) async {
      final inserted = await db.insert(
        GalleryDataSource._collectionItemsTable,
        {
          'collection_id': collectionId,
          'image_id': imageId,
          'added_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return inserted == 1;
    });
  }

  /// 从收藏集移除图片（不存在时返回 false，视为无成员可移除）
  Future<bool> removeImageFromCollection(
    String collectionId,
    int imageId,
  ) async {
    final deleted = await execute('removeImageFromCollection', (db) async {
      return db.delete(
        GalleryDataSource._collectionItemsTable,
        where: 'collection_id = ? AND image_id = ?',
        whereArgs: [collectionId, imageId],
      );
    });
    if (deleted > 0) _markDataChanged();
    return deleted > 0;
  }

  /// 收藏集内图片 ID 列表（按加入时间升序）
  Future<List<int>> getCollectionImageIds(String collectionId) async {
    if (collectionId.isEmpty) return const [];

    return _trackQuery('getCollectionImageIds', () async {
      return execute('getCollectionImageIds', (db) async {
        final rows = await db.rawQuery('''
          SELECT image_id FROM ${GalleryDataSource._collectionItemsTable}
          WHERE collection_id = ?
          ORDER BY added_at ASC
        ''', [collectionId]);
        return [
          for (final row in rows) (row['image_id'] as num).toInt(),
        ];
      });
    });
  }

  /// 图片所在的收藏集 ID 集合（卡片收藏菜单用）
  Future<Set<String>> getCollectionIdsForImage(int imageId) async {
    return _trackQuery('getCollectionIdsForImage', () async {
      return execute('getCollectionIdsForImage', (db) async {
        final rows = await db.rawQuery('''
          SELECT collection_id FROM ${GalleryDataSource._collectionItemsTable}
          WHERE image_id = ?
        ''', [imageId]);
        return {for (final row in rows) row['collection_id'] as String};
      });
    });
  }
}
