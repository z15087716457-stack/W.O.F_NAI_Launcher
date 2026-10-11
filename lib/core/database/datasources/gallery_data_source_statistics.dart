part of 'gallery_data_source.dart';

extension GalleryDataSourceStatistics on GalleryDataSource {
  /// Loads only aggregate values required by the statistics dashboard.
  Future<GalleryDashboardSnapshot> getDashboardStatistics({
    DateTime? dateStart,
    DateTime? dateEnd,
    bool naiOnly = false,
  }) {
    final scoped = _statisticsWhere(
      dateStart: dateStart,
      dateEnd: dateEnd,
      naiOnly: naiOnly,
    );
    final history = _statisticsWhere(naiOnly: naiOnly);
    return _trackQuery('getDashboardStatistics', () async {
      return execute(
        'getDashboardStatistics',
        (db) => db.transaction((txn) async {
          final libraryRows = await txn.rawQuery(
            'SELECT COUNT(*) AS total FROM ${GalleryDataSource._imagesTable} WHERE is_deleted = 0',
          );
          final baseRows = await txn.rawQuery('''
            SELECT COUNT(*) AS total_images,
              COALESCE(SUM(i.file_size), 0) AS total_size,
              COALESCE(SUM(f.image_id IS NOT NULL), 0) AS favorite_count,
              COALESCE(SUM(EXISTS(SELECT 1 FROM ${GalleryDataSource._imageTagsTable} it WHERE it.image_id = i.id)), 0) AS tagged_image_count,
              COALESCE(SUM(COALESCE(m.has_metadata, 0) = 1), 0) AS images_with_metadata
            FROM ${GalleryDataSource._imagesTable} i
            LEFT JOIN ${GalleryDataSource._metadataTable} m ON m.image_id = i.id
            LEFT JOIN ${GalleryDataSource._favoritesTable} f ON f.image_id = i.id
            WHERE $scoped
          ''');

          final resolutionRows = await txn.rawQuery('''
            SELECT
              COALESCE(NULLIF(m.width, 0), NULLIF(i.width, 0)) AS width,
              COALESCE(NULLIF(m.height, 0), NULLIF(i.height, 0)) AS height,
              COUNT(*) AS item_count
            FROM ${GalleryDataSource._imagesTable} i
            LEFT JOIN ${GalleryDataSource._metadataTable} m
              ON m.image_id = i.id
            WHERE $scoped
              AND COALESCE(NULLIF(m.width, 0), NULLIF(i.width, 0)) > 0
              AND COALESCE(NULLIF(m.height, 0), NULLIF(i.height, 0)) > 0
            GROUP BY 1, 2
            ORDER BY item_count DESC
          ''');

          final modelRows = await txn.rawQuery('''
            SELECT m.model AS label, COUNT(*) AS item_count
            FROM ${GalleryDataSource._metadataTable} m
            INNER JOIN ${GalleryDataSource._imagesTable} i
              ON i.id = m.image_id
            WHERE $scoped
              AND m.model IS NOT NULL
              AND m.model != ''
            GROUP BY m.model
            ORDER BY item_count DESC
          ''');

          final samplerRows = await txn.rawQuery('''
            SELECT m.sampler AS label, COUNT(*) AS item_count
            FROM ${GalleryDataSource._metadataTable} m
            INNER JOIN ${GalleryDataSource._imagesTable} i
              ON i.id = m.image_id
            WHERE $scoped
              AND m.has_metadata = 1
              AND m.sampler IS NOT NULL
              AND m.sampler != ''
            GROUP BY m.sampler
            ORDER BY item_count DESC
          ''');

          final sizeRows = await txn.rawQuery('''
            SELECT
              CASE
                WHEN file_size < 1048576 THEN '< 1 MB'
                WHEN file_size < 2097152 THEN '1-2 MB'
                WHEN file_size < 5242880 THEN '2-5 MB'
                WHEN file_size < 10485760 THEN '5-10 MB'
                ELSE '> 10 MB'
              END AS label,
              CASE
                WHEN file_size < 1048576 THEN 0
                WHEN file_size < 2097152 THEN 1
                WHEN file_size < 5242880 THEN 2
                WHEN file_size < 10485760 THEN 3
                ELSE 4
              END AS sort_order,
              COUNT(*) AS item_count,
              COALESCE(SUM(file_size), 0) AS total_bytes
            FROM ${GalleryDataSource._imagesTable} i
            LEFT JOIN ${GalleryDataSource._metadataTable} m ON m.image_id = i.id
            WHERE $scoped
            GROUP BY label, sort_order
            ORDER BY sort_order
          ''');

          final tagRows = await txn.rawQuery('''
            SELECT t.name AS label, COUNT(DISTINCT it.image_id) AS item_count
            FROM ${GalleryDataSource._tagsTable} t
            INNER JOIN ${GalleryDataSource._imageTagsTable} it
              ON it.tag_id = t.id
            INNER JOIN ${GalleryDataSource._imagesTable} i
              ON i.id = it.image_id
            LEFT JOIN ${GalleryDataSource._metadataTable} m ON m.image_id = i.id
            WHERE $scoped
            GROUP BY t.id, t.name
            ORDER BY item_count DESC
            LIMIT 20
          ''');

          final dailyRows = await txn.rawQuery('''
            SELECT $_galleryStatisticsDate AS bucket, COUNT(*) AS item_count
            FROM ${GalleryDataSource._imagesTable} i
            LEFT JOIN ${GalleryDataSource._metadataTable} m ON m.image_id = i.id
            WHERE $history GROUP BY bucket ORDER BY bucket
          ''');
          final dailyModelRows = await txn.rawQuery('''
            SELECT $_galleryStatisticsDate AS bucket, m.model AS label, COUNT(*) AS item_count
            FROM ${GalleryDataSource._imagesTable} i
            INNER JOIN ${GalleryDataSource._metadataTable} m ON m.image_id = i.id
            WHERE $history AND m.model IS NOT NULL AND m.model != ''
            GROUP BY bucket, m.model ORDER BY bucket, item_count DESC, m.model
          ''');
          final monthlyRows = await txn.rawQuery('''
            SELECT CAST(($_galleryStatisticsDate) / 100 AS INTEGER) * 100 + 1 AS bucket,
              COALESCE(SUM(i.file_size), 0) AS item_count
            FROM ${GalleryDataSource._imagesTable} i
            LEFT JOIN ${GalleryDataSource._metadataTable} m ON m.image_id = i.id
            WHERE $history GROUP BY bucket ORDER BY bucket
          ''');
          final weekHourRows = await txn.rawQuery('''
            SELECT CAST(strftime('%w', i.modified_at / 1000.0, 'unixepoch', 'localtime') AS INTEGER) AS weekday,
              CAST(strftime('%H', i.modified_at / 1000.0, 'unixepoch', 'localtime') AS INTEGER) AS hour,
              COUNT(*) AS item_count
            FROM ${GalleryDataSource._imagesTable} i
            LEFT JOIN ${GalleryDataSource._metadataTable} m ON m.image_id = i.id
            WHERE $scoped GROUP BY weekday, hour ORDER BY weekday, hour
          ''');
          Future<List<Map<String, Object?>>> parameters(String column) =>
              txn.rawQuery('''
            SELECT m.$column AS label, COUNT(*) AS item_count
            FROM ${GalleryDataSource._imagesTable} i
            INNER JOIN ${GalleryDataSource._metadataTable} m ON m.image_id = i.id
            WHERE $scoped AND m.has_metadata = 1 AND m.$column IS NOT NULL AND m.$column != ''
            GROUP BY m.$column ORDER BY item_count DESC, m.$column
          ''');
          final stepRows = await parameters('steps');
          final cfgRows = await parameters('cfg_scale');
          final noiseRows = await parameters('noise_schedule');
          final base = baseRows.first;
          final hourlyCounts = <int, int>{};
          final weekdayCounts = <int, int>{};
          final weekHourCounts = <int, int>{};
          for (final row in weekHourRows) {
            final sqliteWeekday = _statisticsInt(row['weekday']);
            final weekday = sqliteWeekday == 0
                ? DateTime.sunday
                : sqliteWeekday;
            final hour = _statisticsInt(row['hour']);
            final count = _statisticsInt(row['item_count']);
            weekHourCounts[(weekday - 1) * 24 + hour] = count;
            weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + count;
            hourlyCounts[hour] = (hourlyCounts[hour] ?? 0) + count;
          }
          final dailyModelCounts = <int, Map<String, int>>{};
          for (final row in dailyModelRows) {
            (dailyModelCounts[_statisticsInt(row['bucket'])] ??=
                {})[row['label'] as String] = _statisticsInt(
              row['item_count'],
            );
          }

          return GalleryDashboardSnapshot(
            libraryTotal: _statisticsInt(libraryRows.first['total']),
            totalImages: _statisticsInt(base['total_images']),
            totalSizeBytes: _statisticsInt(base['total_size']),
            favoriteCount: _statisticsInt(base['favorite_count']),
            taggedImageCount: _statisticsInt(base['tagged_image_count']),
            imagesWithMetadata: _statisticsInt(base['images_with_metadata']),
            resolutionCounts: {
              for (final row in resolutionRows)
                '${_statisticsInt(row['width'])}x${_statisticsInt(row['height'])}':
                    _statisticsInt(row['item_count']),
            },
            modelCounts: _statisticsStringCounts(modelRows),
            samplerCounts: _statisticsStringCounts(samplerRows),
            sizeCounts: _statisticsStringCounts(sizeRows),
            tagCounts: _statisticsStringCounts(tagRows),
            dailyCounts: _statisticsIntCounts(dailyRows),
            hourlyCounts: hourlyCounts,
            weekdayCounts: weekdayCounts,
            weekHourCounts: weekHourCounts,
            sizeBytesCounts: {
              for (final row in sizeRows)
                row['label'] as String: _statisticsInt(row['total_bytes']),
            },
            stepCounts: {
              for (final row in stepRows)
                _statisticsInt(row['label']): _statisticsInt(row['item_count']),
            },
            cfgCounts: {
              for (final row in cfgRows)
                (row['label'] as num).toDouble(): _statisticsInt(
                  row['item_count'],
                ),
            },
            noiseScheduleCounts: _statisticsStringCounts(noiseRows),
            dailyModelCounts: dailyModelCounts,
            monthlyBytes: _statisticsIntCounts(monthlyRows),
          );
        }),
        timeout: const Duration(seconds: 30),
        maxRetries: 2,
      );
    });
  }

  Future<List<Map<String, Object?>>> getStatisticsArtistPrompts({
    DateTime? dateStart,
    DateTime? dateEnd,
    bool naiOnly = false,
    int afterId = 0,
    int limit = 512,
  }) {
    final scope = _statisticsWhere(
      dateStart: dateStart,
      dateEnd: dateEnd,
      naiOnly: naiOnly,
    );
    return execute(
      'getStatisticsArtistPrompts',
      (db) => db.rawQuery(
        '''
      SELECT i.id, m.prompt
      FROM ${GalleryDataSource._imagesTable} i
      INNER JOIN ${GalleryDataSource._metadataTable} m ON m.image_id = i.id
      WHERE $scope AND m.has_metadata = 1 AND i.id > ?
        AND m.prompt LIKE '%artist:%'
      ORDER BY i.id LIMIT ?
    ''',
        [afterId, limit],
      ),
    );
  }
}

const _galleryStatisticsDate =
    "CASE WHEN i.date_ymd > 0 THEN i.date_ymd ELSE CAST(strftime('%Y%m%d', i.modified_at / 1000.0, 'unixepoch', 'localtime') AS INTEGER) END";

int _statisticsDateValue(DateTime date) =>
    date.year * 10000 + date.month * 100 + date.day;

String _statisticsWhere({
  DateTime? dateStart,
  DateTime? dateEnd,
  bool naiOnly = false,
}) => [
  'i.is_deleted = 0',
  if (naiOnly) '(${GalleryDataSource._naiOnlyCondition})',
  if (dateStart != null)
    '($_galleryStatisticsDate) >= ${_statisticsDateValue(dateStart)}',
  if (dateEnd != null)
    '($_galleryStatisticsDate) < ${_statisticsDateValue(dateEnd)}',
].join(' AND ');

int _statisticsInt(Object? value) => (value as num?)?.toInt() ?? 0;

Map<String, int> _statisticsStringCounts(List<Map<String, Object?>> rows) {
  final counts = <String, int>{};
  for (final row in rows) {
    final label = row['label'] as String?;
    if (label == null || label.isEmpty) continue;
    counts[label] = _statisticsInt(row['item_count']);
  }
  return counts;
}

Map<int, int> _statisticsIntCounts(List<Map<String, Object?>> rows) {
  final counts = <int, int>{};
  for (final row in rows) {
    final bucket = _statisticsInt(row['bucket']);
    counts[bucket] = _statisticsInt(row['item_count']);
  }
  return counts;
}

// ============================================================
// 筛选候选查询（高级筛选面板用）
// ============================================================

extension GalleryDataSourceFilterCandidates on GalleryDataSource {
  /// distinct model 候选（带计数，按计数降序）
  Future<List<GalleryDistinctValue>> getDistinctModels({int limit = 50}) {
    return _queryDistinctMetadataValues('model', limit: limit);
  }

  /// distinct sampler 候选（带计数，按计数降序）
  Future<List<GalleryDistinctValue>> getDistinctSamplers({int limit = 50}) {
    return _queryDistinctMetadataValues('sampler', limit: limit);
  }

  /// distinct resolution_key 候选（带计数，按计数降序）
  Future<List<GalleryDistinctValue>> getDistinctResolutions({int limit = 20}) {
    return _queryDistinctImagesValues('resolution_key', limit: limit);
  }

  Future<List<GalleryDistinctValue>> _queryDistinctMetadataValues(
    String column, {
    int limit = 20,
  }) async {
    return _queryDistinctValues(
      column,
      table: GalleryDataSource._metadataTable,
      limit: limit,
      operationName: 'getDistinctValues',
    );
  }

  Future<List<GalleryDistinctValue>> _queryDistinctImagesValues(
    String column, {
    int limit = 20,
  }) async {
    return _queryDistinctValues(
      column,
      table: GalleryDataSource._imagesTable,
      limit: limit,
      operationName: 'getDistinctImagesValues',
    );
  }

  Future<List<GalleryDistinctValue>> _queryDistinctValues(
    String column, {
    required String table,
    required int limit,
    required String operationName,
  }) async {
    try {
      return await execute(
        '$operationName:$column',
        (db) async {
          // metadata 表需 JOIN images 过滤软删；images 表直接过滤。
          // column 为内部硬编码白名单（model/sampler/resolution_key），安全插值。
          final fromClause = table == GalleryDataSource._metadataTable
              ? '$table m INNER JOIN ${GalleryDataSource._imagesTable} i ON i.id = m.image_id'
              : '$table i';
          final valueExpr = table == GalleryDataSource._metadataTable
              ? 'm.$column'
              : 'i.$column';

          final results = await db.rawQuery(
            '''
            SELECT $valueExpr AS value, COUNT(*) AS count
            FROM $fromClause
            WHERE $valueExpr IS NOT NULL AND $valueExpr != ''
              AND i.is_deleted = 0
            GROUP BY $valueExpr
            ORDER BY count DESC
            LIMIT ?
            ''',
            [limit],
          );
          return results.map(GalleryDistinctValue.fromMap).toList();
        },
        timeout: const Duration(seconds: 15),
        maxRetries: 2,
      );
    } catch (e, stack) {
      AppLogger.e(
        'Failed to get distinct values for $table.$column',
        e,
        stack,
        'GalleryDS',
      );
      return [];
    }
  }

  /// 标签自动补全（包含匹配，按 usage_count 降序）
  ///
  /// 兼容下划线/空格变体：`blue hair` 与 `blue_hair` 互相命中。
  Future<List<String>> autocompleteTags(String query, {int limit = 8}) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    final escaped = _escapeLikePattern(trimmed);
    final underscoreVariant = escaped.replaceAll(' ', '_');
    final spaceVariant = escaped.replaceAll('_', ' ');

    try {
      final results = await execute(
        'autocompleteTags',
        (db) async {
          final dbResults = await db.rawQuery(
            """
            SELECT name FROM ${GalleryDataSource._tagsTable}
            WHERE name LIKE ? ESCAPE '\\' OR name LIKE ? ESCAPE '\\'
            ORDER BY usage_count DESC
            LIMIT ?
            """,
            ['%$underscoreVariant%', '%$spaceVariant%', limit],
          );
          final names = <String>[];
          for (final row in dbResults) {
            final name = row['name'] as String?;
            if (name != null && name.isNotEmpty && !names.contains(name)) {
              names.add(name);
            }
          }
          return names;
        },
        timeout: const Duration(seconds: 10),
        maxRetries: 2,
      );
      return results;
    } catch (e, stack) {
      AppLogger.e('Failed to autocomplete tags: $query', e, stack, 'GalleryDS');
      return [];
    }
  }
}
