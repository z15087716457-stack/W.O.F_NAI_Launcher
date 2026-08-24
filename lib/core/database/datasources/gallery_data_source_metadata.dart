part of 'gallery_data_source.dart';

extension GalleryDataSourceMetadataQueries on GalleryDataSource {
  /// 查询真 NAI 图（[GalleryDataSource._naiOnlyCondition]）的全部图片 ID。
  ///
  /// 供 NAI-only 本地回退过滤路径使用（参照收藏过滤的 image_ids 口径）。
  Future<List<int>> getImageIdsWithMetadata() async {
    try {
      return await execute(
        'getImageIdsWithMetadata',
        (db) async {
          final rows = await db.rawQuery('''
            SELECT m.image_id FROM ${GalleryDataSource._metadataTable} m
            INNER JOIN ${GalleryDataSource._imagesTable} i
              ON i.id = m.image_id
            WHERE ${GalleryDataSource._naiOnlyCondition} AND i.is_deleted = 0
            ''');
          return rows
              .map((row) => (row['image_id'] as num).toInt())
              .toList(growable: false);
        },
        timeout: const Duration(seconds: 15),
        maxRetries: 2,
      );
    } catch (e, stack) {
      AppLogger.e(
        'Failed to get image IDs with metadata',
        e,
        stack,
        'GalleryDS',
      );
      return [];
    }
  }

  /// 直跑 model 列回填（迁移一次性闸门之外的入口，供测试与手动触发）。
  ///
  /// 逻辑与启动迁移 [_migrateBackfillModelColumn] 完全一致，返回更新行数。
  Future<int> backfillModelColumn() {
    return execute('backfillModelColumn', _backfillModelColumnImpl);
  }
}
