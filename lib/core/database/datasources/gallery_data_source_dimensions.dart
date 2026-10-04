part of 'gallery_data_source.dart';

/// 连续画廊排版用的宽高查询。
extension GalleryDataSourceDimensions on GalleryDataSource {
  /// 按路径批量读取已索引图片的宽高（只返回宽高均为正数的条目）。
  Future<Map<String, (int, int)>> getImageDimensionsByPaths(
    List<String> filePaths,
  ) async {
    if (filePaths.isEmpty) return {};

    return _trackQuery('getImageDimensionsByPaths', () async {
      final result = <String, (int, int)>{};
      try {
        for (final batch in chunk(filePaths, 900)) {
          await execute(
            'getImageDimensionsByPaths',
            (db) async {
              final placeholders = List.filled(batch.length, '?').join(',');
              final rows = await db.rawQuery('''
                  SELECT file_path, width, height FROM ${GalleryDataSource._imagesTable}
                  WHERE file_path IN ($placeholders) AND +is_deleted = 0
                  ''', batch);
              GalleryDataSourceDimensions._collectDimensions(rows, result);
            },
            timeout: const Duration(seconds: 30),
            maxRetries: 3,
          );
        }
      } catch (e, stack) {
        AppLogger.e(
          'Failed to get image dimensions: ${filePaths.length} paths',
          e,
          stack,
          'GalleryDS',
        );
      }
      return result;
    }, details: '${filePaths.length} paths');
  }

  /// 一次读取全部已索引图片的宽高（首次排版整库时比分批 IN 查询更快）。
  Future<Map<String, (int, int)>> getAllImageDimensions() async {
    return _trackQuery('getAllImageDimensions', () async {
      final result = <String, (int, int)>{};
      try {
        await execute(
          'getAllImageDimensions',
          (db) async {
            final rows = await db.rawQuery('''
                SELECT file_path, width, height FROM ${GalleryDataSource._imagesTable}
                WHERE is_deleted = 0 AND width > 0 AND height > 0
                ''');
            GalleryDataSourceDimensions._collectDimensions(rows, result);
          },
          timeout: const Duration(seconds: 60),
          maxRetries: 3,
        );
      } catch (e, stack) {
        AppLogger.e(
          'Failed to get all image dimensions',
          e,
          stack,
          'GalleryDS',
        );
      }
      return result;
    });
  }

  static void _collectDimensions(
    List<Map<String, Object?>> rows,
    Map<String, (int, int)> result,
  ) {
    for (final row in rows) {
      final path = row['file_path'] as String?;
      final width = (row['width'] as num?)?.toInt();
      final height = (row['height'] as num?)?.toInt();
      if (path == null || width == null || height == null) continue;
      if (width <= 0 || height <= 0) continue;
      result[path] = (width, height);
    }
  }
}
