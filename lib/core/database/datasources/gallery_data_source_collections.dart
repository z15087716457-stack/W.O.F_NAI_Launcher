part of 'gallery_data_source.dart';

/// 收藏集（collections）数据访问
///
/// 链接式收藏：`gallery_collection_items` 只存 (collection_id, image_id)，
/// 不复制文件。删除收藏集级联删除成员关系，不触碰图片文件。
///
/// 层级模型：`parent_id` 指向父节点（NULL=收藏根级平铺）；`is_folder=1`
/// 为纯组织节点，不参与成员关系，只有文件夹可拥有子节点。
extension GalleryDataSourceCollections on GalleryDataSource {
  /// 旧 Hive 集合完整入库后才允许清理来源；缺索引时整批保留待下次迁移。
  Future<bool> migrateLegacyCollections(
    List<ImageCollection> collections,
  ) => executeWrite('migrateLegacyCollections', (db) async {
    final migrated = await db.transaction((txn) async {
      final paths = {for (final entry in collections) ...entry.imagePaths};
      final rows = await txn.rawQuery(
        'SELECT id, file_path FROM ${GalleryDataSource._imagesTable} '
        'WHERE file_path IN (SELECT value FROM json_each(?)) AND is_deleted = 0',
        [jsonEncode(paths.toList())],
      );
      final ids = {
        for (final row in rows) row['file_path'] as String: row['id'] as int,
      };
      if (ids.length != paths.length) return false;
      final sort = await txn.rawQuery(
        'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next '
        'FROM ${GalleryDataSource._collectionsTable} WHERE parent_id IS NULL',
      );
      var nextOrder = sort.single['next'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final entry in collections) {
        if (entry.name.trim().isEmpty) {
          throw ArgumentError('Legacy collection name is empty');
        }
        // 保留旧 ID：提交后清理来源失败时，重试不重复建集或覆盖新名称。
        await txn.insert(GalleryDataSource._collectionsTable, {
          'id': entry.id,
          'name': entry.name.trim(),
          'sort_order': nextOrder++,
          'created_at': entry.createdAt.millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        for (final path in entry.imagePaths) {
          await txn.insert(GalleryDataSource._collectionItemsTable, {
            'collection_id': entry.id,
            'image_id': ids[path]!,
            'added_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      return true;
    });
    if (migrated) _markDataChanged();
    return migrated;
  });

  static bool _canReparentCollections(
    List<Map<String, Object?>> rows,
    Set<String> movingIds,
    String? parentId,
  ) {
    final byId = {for (final row in rows) row['id'] as String: row};
    if (!movingIds.every(byId.containsKey)) return false;
    final seen = <String>{};
    var ancestor = parentId;
    while (ancestor != null) {
      if (movingIds.contains(ancestor) || !seen.add(ancestor)) return false;
      final row = byId[ancestor];
      if (row == null || row['is_folder'] != 1) return false;
      ancestor = row['parent_id'] as String?;
    }
    return true;
  }

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
    await executeWrite('createCollection', (db) async {
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
      _markDataChanged();
    });
    return id;
  }

  /// 重命名收藏集
  Future<bool> renameCollection(String id, String newName) async {
    final updated = await executeWrite('renameCollection', (db) async {
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
    final deleted = await executeWrite('deleteCollection', (db) async {
      final count = await db.transaction((txn) async {
        final childCount =
            (await txn.rawQuery(
                  'SELECT COUNT(*) AS cnt FROM ${GalleryDataSource._collectionsTable} '
                  'WHERE parent_id = ?',
                  [id],
                )).first['cnt']
                as int? ??
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
      if (count > 0) _markDataChanged();
      return count;
    });
    return deleted > 0;
  }

  /// 移动收藏集/文件夹到新父级（null=移到收藏根级）
  ///
  /// 目标必须是文件夹节点；目标不能是自身或自身的子孙（防环）。
  /// 移入后 sort_order 追加到目标父级末尾。
  Future<bool> moveCollection(String id, String? newParentId) async {
    if (id == newParentId) return false;
    final moved = await executeWrite('moveCollection', (db) async {
      final allRows = await db.rawQuery(
        'SELECT id, parent_id, is_folder '
        'FROM ${GalleryDataSource._collectionsTable}',
      );
      if (!_canReparentCollections(allRows, {id}, newParentId)) return 0;

      final sortResult = await db.rawQuery(
        'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next '
        'FROM ${GalleryDataSource._collectionsTable} '
        'WHERE parent_id IS ?',
        [newParentId],
      );
      final nextSortOrder = (sortResult.first['next'] as num?)?.toInt() ?? 0;

      final count = await db.update(
        GalleryDataSource._collectionsTable,
        {'parent_id': newParentId, 'sort_order': nextSortOrder},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count > 0) _markDataChanged();
      return count;
    });
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
          final descendantIds = _descendantsOf(
            info.id,
            parentById,
            includeSelf: true,
          );
          if (descendantIds.isEmpty) continue;
          final placeholders = List.filled(descendantIds.length, '?').join(',');
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
    final result = <String>[if (includeSelf) id];
    final visited = <String>{id};
    final queue = [...?childrenOf[id]];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!visited.add(current)) {
        throw StateError('Collection hierarchy contains a cycle at $current');
      }
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

    return executeWrite('reorderCollections', (db) async {
      final rows = await db.rawQuery(
        'SELECT id, parent_id, is_folder '
        'FROM ${GalleryDataSource._collectionsTable}',
      );
      if (!_canReparentCollections(rows, orderedIds.toSet(), parentId)) {
        return false;
      }
      await db.transaction((txn) async {
        for (var i = 0; i < orderedIds.length; i++) {
          await txn.update(
            GalleryDataSource._collectionsTable,
            {'sort_order': i, 'parent_id': parentId},
            where: 'id = ?',
            whereArgs: [orderedIds[i]],
          );
        }
      });
      _markDataChanged();
      return true;
    });
  }

  /// 添加图片到收藏集（幂等；返回是否真正新插入，已在集合中返回 false）
  Future<bool> addImageToCollection(String collectionId, int imageId) async {
    final changed = await executeWrite('addImageToCollection', (db) async {
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
    final deleted = await executeWrite('removeImageFromCollection', (db) async {
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
      removed += await executeWrite('removeImagesFromAllCollections', (
        db,
      ) async {
        final count = await db.rawDelete(
          'DELETE FROM ${GalleryDataSource._collectionItemsTable} '
          'WHERE image_id IN ($placeholders)',
          chunk,
        );
        if (count > 0) _markDataChanged();
        return count;
      });
    }
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
          for (final row in rows)
            row['id'] as String: row['parent_id'] as String?,
        };
        final targetIds = _descendantsOf(
          collectionId,
          parentById,
          includeSelf: true,
        );
        if (!parentById.containsKey(collectionId)) return const <int>[];

        final placeholders = List.filled(targetIds.length, '?').join(',');
        final memberRows = await db.rawQuery('''
          SELECT image_id, MIN(added_at) AS first_added
          FROM ${GalleryDataSource._collectionItemsTable}
          WHERE collection_id IN ($placeholders)
          GROUP BY image_id
          ORDER BY first_added ASC
        ''', targetIds);
        return [for (final row in memberRows) (row['image_id'] as num).toInt()];
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
