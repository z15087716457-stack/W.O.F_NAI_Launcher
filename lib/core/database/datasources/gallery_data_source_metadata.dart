part of 'gallery_data_source.dart';

extension GalleryDataSourceMetadataQueries on GalleryDataSource {
  /// 查询带 NAI 元数据（has_metadata = 1）的全部图片 ID。
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
            WHERE m.has_metadata = 1 AND i.is_deleted = 0
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
}
