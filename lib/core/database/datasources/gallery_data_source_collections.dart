part of 'gallery_data_source.dart';

/// 收藏集（collections）数据访问
///
/// 链接式收藏：`gallery_collection_items` 只存 (collection_id, image_id)，
/// 不复制文件。删除收藏集级联删除成员关系，不触碰图片文件。
///
/// 层级模型：`parent_id` 指向父节点（NULL=收藏根级平铺）；`is_folder=1`
/// 为纯组织节点，不参与成员关系，只有文件夹可拥有子节点。
extension GalleryDataSourceCollections on GalleryDataSource {
  /// 创建收藏集，返回新收藏集 ID
  ///
  /// [parentId] 父文件夹 ID（须为文件夹节点；null=收藏根级平铺）。
  Future<String> createCollection(
    String name, {
    String? parentId,
    bool isFolder = false,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await execute('createCollection', (db) async {
      if (parentId != null) {
        final parent = await db.rawQuery(
          'SELECT is_folder FROM ${GalleryDataSource._collectionsTable} '
          'WHERE id = ?',
          [parentId],
        );
        if (parent.isEmpty || (parent.first['is_folder'] as num?) != 1) {
          throw ArgumentError('Parent collection is not a folder: $parentId');
        }
      }
      final sortResult = await db.rawQuery(
        'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next '
        'FROM ${GalleryDataSource._collectionsTable} '
        'WHERE parent_id IS ?',
        [parentId],
      );
      final nextSortOrder = (sortResult.first['next'] as num?)?.toInt() ?? 0;

      await db.insert(GalleryDataSource._collectionsTable, {
        'id': id,
        'name': name.trim(),
        'sort_order': nextSortOrder,
        'created_at': now,
        'parent_id': parentId,
        'is_folder': isFolder ? 1 : 0,
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
  ///
  /// 非空文件夹禁止删除：子节点存在时返回 false，由上层提示先清空。
  Future<bool> deleteCollection(String id) async {
    final deleted = await execute('deleteCollection', (db) async {
      return db.transaction((txn) async {
        final childCount =
            (await txn.rawQuery(
              'SELECT COUNT(*) AS cnt FROM ${GalleryDataSource._collectionsTable} '
              'WHERE parent_id = ?',
              [id],
            ))
                .first['cnt'] as int? ??
            0;
        if (childCount > 0) return 0;

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

  /// 移动收藏集/文件夹到新父级（null=移到收藏根级）
  ///
  /// 目标必须是文件夹节点；目标不能是自身或自身的子孙（防环）。
  /// 移入后 sort_order 追加到目标父级末尾。
  Future<bool> moveCollection(String id, String? newParentId) async {
    if (id == newParentId) return false;
    final moved = await execute('moveCollection', (db) async {
      if (newParentId != null) {
        final parent = await db.rawQuery(
          'SELECT is_folder FROM ${GalleryDataSource._collectionsTable} '
          'WHERE id = ?',
          [newParentId],
        );
        if (parent.isEmpty || (parent.first['is_folder'] as num?) != 1) {
          return 0;
        }
      }

      // 防环：目标不能在自身的子孙子树内（含自身）
      final allRows = await db.rawQuery(
        'SELECT id, parent_id FROM ${GalleryDataSource._collectionsTable}',
      );
      final parentById = <String, String?>{
        for (final row in allRows) row['id'] as String: row['parent_id'] as String?,
      };
      var ancestor = newParentId;
      while (ancestor != null) {
        if (ancestor == id) return 0;
        ancestor = parentById[ancestor];
      }

      final sortResult = await db.rawQuery(
        'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next '
        'FROM ${GalleryDataSource._collectionsTable} '
        'WHERE parent_id IS ?',
        [newParentId],
      );
      final nextSortOrder = (sortResult.first['next'] as num?)?.toInt() ?? 0;

      return db.update(
        GalleryDataSource._collectionsTable,
        {'parent_id': newParentId, 'sort_order': nextSortOrder},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    if (moved > 0) _markDataChanged();
    return moved > 0;
  }

  /// 收藏集列表（含未删除图片成员计数），按 sort_order、created_at 升序
  ///
  /// 文件夹节点的 image_count 为其全部子孙收藏集成员的去重并集计数
  ///（与「选中文件夹浏览递归并集」语义一致）；子项求和会因一图多集
  /// 重复累计，故逐文件夹做 COUNT(DISTINCT)。
  Future<List<GalleryCollectionInfo>> listCollectionsWithCounts() async {
    return _trackQuery('listCollectionsWithCounts', () async {
      return execute('listCollectionsWithCounts', (db) async {
        final rows = await db.rawQuery('''
          SELECT
            c.id,
            c.name,
            c.sort_order,
            c.created_at,
            c.parent_id,
            c.is_folder,
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
        final infos = [
          for (final row in rows) GalleryCollectionInfo.fromMap(row),
        ];
        if (!infos.any((info) => info.isFolder)) return infos;

        // 文件夹计数：子孙收藏集成员并集（去重）
        final parentById = <String, String?>{
          for (final info in infos) info.id: info.parentId,
        };
        for (final info in infos) {
          if (!info.isFolder) continue;
          final descendantIds = _descendantsOf(info.id, parentById,
              includeSelf: true);
          if (descendantIds.isEmpty) continue;
          final placeholders =
              List.filled(descendantIds.length, '?').join(',');
          final countRow = await db.rawQuery('''
            SELECT COUNT(DISTINCT ci.image_id) AS cnt
            FROM ${GalleryDataSource._collectionItemsTable} ci
            INNER JOIN ${GalleryDataSource._imagesTable} i
              ON i.id = ci.image_id
            WHERE ci.collection_id IN ($placeholders) AND i.is_deleted = 0
          ''', descendantIds);
          final cnt = (countRow.first['cnt'] as num?)?.toInt() ?? 0;
          final index = infos.indexWhere((x) => x.id == info.id);
          infos[index] = GalleryCollectionInfo(
            id: info.id,
            name: info.name,
            imageCount: cnt,
            sortOrder: info.sortOrder,
            createdAt: info.createdAt,
            parentId: info.parentId,
            isFolder: info.isFolder,
          );
        }
        return infos;
      });
    });
  }

  /// 按 parent_id 映射收集子孙节点 ID（不含起点自身，除非 [includeSelf]）
  static List<String> _descendantsOf(
    String id,
    Map<String, String?> parentById, {
    bool includeSelf = false,
  }) {
    final childrenOf = <String, List<String>>{};
    parentById.forEach((child, parent) {
      if (parent == null) return;
      childrenOf.putIfAbsent(parent, () => []).add(child);
    });
    final result = <String>[
      if (includeSelf) id,
    ];
    final queue = [...?childrenOf[id]];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      result.add(current);
      queue.addAll(childrenOf[current] ?? const []);
    }
    return result;
  }

  /// 节点是否有子节点（非空文件夹判定）
  Future<bool> hasChildCollections(String id) async {
    return _trackQuery('hasChildCollections', () async {
      return execute('hasChildCollections', (db) async {
        final rows = await db.rawQuery(
          'SELECT 1 FROM ${GalleryDataSource._collectionsTable} '
          'WHERE parent_id = ? LIMIT 1',
          [id],
        );
        return rows.isNotEmpty;
      });
    });
  }

  /// 按给定 ID 顺序重排收藏集（sort_order = 下标）
  ///
  /// [orderedIds] 必须是同一父级（[parentId]）下的全部子项；
  /// parent_id 一并写回，保证重排与归属一致。
  Future<bool> reorderCollections(
    List<String> orderedIds, {
    String? parentId,
  }) async {
    if (orderedIds.isEmpty) return false;

    final ok = await execute('reorderCollections', (db) async {
      return db.transaction((txn) async {
        for (var i = 0; i < orderedIds.length; i++) {
          await txn.update(
            GalleryDataSource._collectionsTable,
            {'sort_order': i, 'parent_id': parentId},
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

  /// 添加图片到收藏集（幂等；返回是否真正新插入，已在集合中返回 false）
  Future<bool> addImageToCollection(String collectionId, int imageId) async {
    final changed = await execute('addImageToCollection', (db) async {
      // db.insert 返回 rowid 而非受影响行数（表非空时恒 >1，不能用来判定
      // 是否插入成功）；rawUpdate 返回 sqlite3_changes()：插入成功=1、被
      // OR IGNORE 跳过=0，才是可靠的幂等结果
      return db.rawUpdate(
        'INSERT OR IGNORE INTO ${GalleryDataSource._collectionItemsTable} '
        '(collection_id, image_id, added_at) VALUES (?, ?, ?)',
        [collectionId, imageId, DateTime.now().millisecondsSinceEpoch],
      );
    });
    if (changed == 1) _markDataChanged();
    return changed == 1;
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

  /// 从所有收藏集移除图片（图片 ID 为空时无操作）
  ///
  /// 「从收藏根移除」语义：取消心形收藏时，同时清掉该图在全部集合里的
  /// 成员关系（根=总收藏，子集=根的细分）。返回删除的成员关系行数。
  Future<int> removeImagesFromAllCollections(List<int> imageIds) async {
    if (imageIds.isEmpty) return 0;

    var removed = 0;
    const batchSize = 900;
    for (final chunk in chunk(imageIds, batchSize)) {
      final placeholders = List.filled(chunk.length, '?').join(',');
      removed += await execute('removeImagesFromAllCollections', (db) async {
        return db.rawDelete(
          'DELETE FROM ${GalleryDataSource._collectionItemsTable} '
          'WHERE image_id IN ($placeholders)',
          chunk,
        );
      });
    }
    if (removed > 0) _markDataChanged();
    return removed;
  }

  /// 收藏集内图片 ID 列表（按加入时间升序）
  ///
  /// 文件夹节点返回其全部子孙收藏集成员的去重并集（同一图在多个子集
  /// 时只保留最早加入时间），与「选中文件夹浏览递归并集」共用一套语义。
  Future<List<int>> getCollectionImageIds(String collectionId) async {
    if (collectionId.isEmpty) return const [];

    return _trackQuery('getCollectionImageIds', () async {
      return execute('getCollectionImageIds', (db) async {
        final rows = await db.rawQuery(
          'SELECT id, parent_id FROM ${GalleryDataSource._collectionsTable}',
        );
        final parentById = <String, String?>{
          for (final row in rows) row['id'] as String: row['parent_id'] as String?,
        };
        final targetIds = _descendantsOf(collectionId, parentById,
            includeSelf: true);
        if (!parentById.containsKey(collectionId)) return const <int>[];

        final placeholders = List.filled(targetIds.length, '?').join(',');
        final memberRows = await db.rawQuery(
          '''
          SELECT image_id, MIN(added_at) AS first_added
          FROM ${GalleryDataSource._collectionItemsTable}
          WHERE collection_id IN ($placeholders)
          GROUP BY image_id
          ORDER BY first_added ASC
        ''',
          targetIds,
        );
        return [
          for (final row in memberRows) (row['image_id'] as num).toInt(),
        ];
      });
    });
  }

  /// 图片所在的收藏集 ID 集合（卡片收藏菜单用）
  Future<Set<String>> getCollectionIdsForImage(int imageId) async {
    return _trackQuery('getCollectionIdsForImage', () async {
      return execute('getCollectionIdsForImage', (db) async {
        final rows = await db.rawQuery(
          '''
          SELECT collection_id FROM ${GalleryDataSource._collectionItemsTable}
          WHERE image_id = ?
        ''',
          [imageId],
        );
        return {for (final row in rows) row['collection_id'] as String};
      });
    });
  }
}
