part of 'gallery_data_source.dart';

/// 高级搜索结果，包含命中的图片 ID 列表与对应的文件路径列表
class AdvancedSearchResult {
  final List<int> ids;
  final List<String> filePaths;

  const AdvancedSearchResult({required this.ids, required this.filePaths});

  static const empty = AdvancedSearchResult(
    ids: <int>[],
    filePaths: <String>[],
  );
}

extension GalleryDataSourceAdvancedSearch on GalleryDataSource {
  /// 高级搜索 - 支持多条件组合查询（带文件路径结果，避免调用方二次回查）
  Future<AdvancedSearchResult> advancedSearchResult({
    String? textQuery,
    DateTime? dateStart,
    DateTime? dateEnd,
    bool favoritesOnly = false,
    int? minWidth,
    int? minHeight,
    int? maxWidth,
    int? maxHeight,
    int? minFileSize,
    int? maxFileSize,
    List<String>? metadataStatuses,
    List<String>? models,
    List<String>? samplers,
    List<String>? resolutions,
    String? orientation,
    int? minSteps,
    int? maxSteps,
    double? minCfg,
    double? maxCfg,
    String? nsfwMode,

    /// 仅真 NAI 图（[GalleryDataSource._naiOnlyCondition]，排除别家工具的参数图）
    bool naiOnly = false,

    /// 排序字段（仅接受 [GallerySort.sqlColumn] 白名单值，内部再校验）
    String? orderByColumn,

    /// 是否升序（默认降序）
    bool orderAscending = false,

    /// 候选路径（当前视图内文件路径列表）
    ///
    /// 传入后查询只在候选路径内进行：DB 残留行（源外/未软删的陈旧记录）
    /// 不再占用 LIMIT 名额挤掉真实文件，且文本候选会先与视图求交。
    List<String>? candidatePaths,
    int limit = 100,
  }) async {
    final candidatePathList = candidatePaths
        ?.where((path) => path.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (candidatePaths != null && candidatePathList!.isEmpty) {
      return AdvancedSearchResult.empty;
    }

    // 缓存键（候选路径按 长度+逐元素 hash 组合做指纹，避免 Object.hashAll
    // 的单一 32 位碰撞风险；数据变更时 _markDataChanged 会整体清缓存）
    final cacheKey = _QueryCacheKey('advancedSearch', {
      'textQuery': textQuery,
      'dateStart': dateStart?.millisecondsSinceEpoch,
      'dateEnd': dateEnd?.millisecondsSinceEpoch,
      'favoritesOnly': favoritesOnly,
      'minWidth': minWidth,
      'minHeight': minHeight,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'minFileSize': minFileSize,
      'maxFileSize': maxFileSize,
      'metadataStatuses': metadataStatuses?.join(','),
      'models': models?.join(','),
      'samplers': samplers?.join(','),
      'resolutions': resolutions?.join(','),
      'orientation': orientation,
      'minSteps': minSteps,
      'maxSteps': maxSteps,
      'minCfg': minCfg,
      'maxCfg': maxCfg,
      'nsfwMode': nsfwMode,
      'naiOnly': naiOnly,
      'orderByColumn': orderByColumn,
      'orderAscending': orderAscending,
      'limit': limit,
      if (candidatePathList != null)
        'candidateFingerprint':
            '${candidatePathList.length}:${candidatePathList.fold<int>(0, (h, p) => h * 31 + p.hashCode)}',
    });

    // 检查缓存
    final cached = _queryCache.get(cacheKey);
    if (cached != null && cached.length == 2) {
      return AdvancedSearchResult(
        ids: (cached[0] as List).cast<int>(),
        filePaths: (cached[1] as List).cast<String>(),
      );
    }

    return _trackQuery(
      'advancedSearch',
      () async {
        // 1. 预取搜索候选，兼容 prompt 与文件名两条搜索链路
        List<int>? textSearchIds;
        if (textQuery != null && textQuery.trim().isNotEmpty) {
          final fullTextIds = await searchFullText(textQuery, limit: limit * 2);
          final fileNameIds = await searchByFileName(
            textQuery,
            limit: limit * 2,
          );
          final metadataTextIds = await searchByMetadataText(
            textQuery,
            limit: limit * 2,
          );
          textSearchIds = {
            ...fullTextIds,
            ...fileNameIds,
            ...metadataTextIds,
          }.toList();
          if (textSearchIds.isEmpty) {
            return AdvancedSearchResult.empty;
          }
        }

        // 1.5 候选路径限定：Mode A（有文本）优化
        // 文本候选命中小集合后，直接按这批 id 查 file_path，在 Dart 内存与 candidatePaths Set 求交。
        // 不再把 candidatePathList 全量丢进 getImageIdsByPaths。
        if (candidatePathList != null && textSearchIds != null) {
          final candidateSet = candidatePathList.toSet();
          final records = await getImagesByIds(textSearchIds);
          final inViewIds = <int>{};
          for (final record in records) {
            final id = record.id;
            if (id != null && candidateSet.contains(record.filePath)) {
              inViewIds.add(id);
            }
          }
          textSearchIds = textSearchIds.where(inViewIds.contains).toList();
          if (textSearchIds.isEmpty) {
            return AdvancedSearchResult.empty;
          }
        }

        return await execute('advancedSearch', (db) async {
          // 2. 构建查询条件
          final conditions = <String>['i.is_deleted = 0'];
          final args = <dynamic>[];

          if (favoritesOnly) {
            conditions.add('f.image_id IS NOT NULL');
          }

          if (dateStart != null) {
            conditions.add('i.modified_at >= ?');
            args.add(dateStart.millisecondsSinceEpoch);
          }
          if (dateEnd != null) {
            conditions.add('i.modified_at <= ?');
            args.add(dateEnd.millisecondsSinceEpoch);
          }

          if (minWidth != null) {
            conditions.add('i.width >= ?');
            args.add(minWidth);
          }
          if (minHeight != null) {
            conditions.add('i.height >= ?');
            args.add(minHeight);
          }
          if (maxWidth != null) {
            conditions.add('i.width <= ?');
            args.add(maxWidth);
          }
          if (maxHeight != null) {
            conditions.add('i.height <= ?');
            args.add(maxHeight);
          }

          if (minFileSize != null) {
            conditions.add('i.file_size >= ?');
            args.add(minFileSize);
          }
          if (maxFileSize != null) {
            conditions.add('i.file_size <= ?');
            args.add(maxFileSize);
          }

          if (metadataStatuses != null && metadataStatuses.isNotEmpty) {
            final statusIndices = metadataStatuses
                .map(
                  (s) => MetadataStatus.values.indexWhere((v) => v.name == s),
                )
                .where((i) => i >= 0)
                .toList();
            if (statusIndices.isNotEmpty) {
              final placeholders = List.filled(
                statusIndices.length,
                '?',
              ).join(',');
              conditions.add('i.metadata_status IN ($placeholders)');
              args.addAll(statusIndices);
            }
          }

          // ---- 元数据过滤（model/sampler/resolution/方向/steps/cfg/NSFW/NAI-only）----
          final needsMetadataJoin =
              models != null ||
              samplers != null ||
              minSteps != null ||
              maxSteps != null ||
              minCfg != null ||
              maxCfg != null ||
              nsfwMode != null ||
              naiOnly;

          if (naiOnly) {
            // 只保留真 NAI 图（排除 A1111/ComfyUI 等读出参数的非 NAI 图；
            // 无 metadata 行的 LEFT JOIN 结果各字段为 NULL，自然不命中）
            conditions.add(GalleryDataSource._naiOnlyCondition);
          }

          if (models != null && models.isNotEmpty) {
            final placeholders = List.filled(models.length, '?').join(',');
            conditions.add('m.model IN ($placeholders)');
            args.addAll(models);
          }
          if (samplers != null && samplers.isNotEmpty) {
            final placeholders = List.filled(samplers.length, '?').join(',');
            conditions.add('m.sampler IN ($placeholders)');
            args.addAll(samplers);
          }
          if (resolutions != null && resolutions.isNotEmpty) {
            final placeholders = List.filled(resolutions.length, '?').join(',');
            conditions.add('i.resolution_key IN ($placeholders)');
            args.addAll(resolutions);
          }
          if (orientation != null) {
            switch (orientation) {
              case 'landscape':
                conditions.add('i.width > i.height');
              case 'portrait':
                conditions.add('i.width < i.height');
              case 'square':
                conditions.add('i.width = i.height');
            }
          }
          if (minSteps != null) {
            conditions.add('m.steps >= ?');
            args.add(minSteps);
          }
          if (maxSteps != null) {
            conditions.add('m.steps <= ?');
            args.add(maxSteps);
          }
          if (minCfg != null) {
            conditions.add('m.cfg_scale >= ?');
            args.add(minCfg);
          }
          if (maxCfg != null) {
            conditions.add('m.cfg_scale <= ?');
            args.add(maxCfg);
          }
          if (nsfwMode != null) {
            if (nsfwMode == 'nsfw') {
              conditions.add('COALESCE(m.is_nsfw, 0) = 1');
            } else if (nsfwMode == 'sfw') {
              conditions.add('COALESCE(m.is_nsfw, 0) = 0');
            }
          }

          final whereClause = conditions.join(' AND ');

          // 排序白名单映射（双保险：调用方已传 sqlColumn 白名单值，此处再校验）
          // `image_area` 是面积 token，展开为表达式；其余为列名，全部硬编码。
          final sortColumn = switch (orderByColumn) {
            'file_name' => 'i.file_name',
            'file_size' => 'i.file_size',
            'modified_at' => 'i.modified_at',
            'created_at' => 'i.created_at',
            'image_area' => 'i.width * i.height',
            _ => 'i.modified_at',
          };
          final orderDirection = orderAscending ? 'ASC' : 'DESC';

          final selectPrefix =
              '''
              SELECT i.id, i.file_path FROM ${GalleryDataSource._imagesTable} i
              ${favoritesOnly ? 'INNER JOIN ${GalleryDataSource._favoritesTable} f ON i.id = f.image_id' : 'LEFT JOIN ${GalleryDataSource._favoritesTable} f ON i.id = f.image_id'}
              ${needsMetadataJoin ? 'LEFT JOIN ${GalleryDataSource._metadataTable} m ON m.image_id = i.id' : ''}
              ''';

          // 3. 执行查询
          const textIdChunkSize = 900;
          final ids = <int>[];
          final paths = <String>[];
          final seenIds = <int>{};

          if (candidatePathList != null) {
            if (textSearchIds != null && textSearchIds.isNotEmpty) {
              // Mode A：有文本 + 候选路径限定
              // textSearchIds 已在内存与 candidatePaths 求交，此处按 900 分块执行 SQL 属性过滤与排序
              for (var i = 0; i < textSearchIds.length; i += textIdChunkSize) {
                final end = min(i + textIdChunkSize, textSearchIds.length);
                final idChunk = textSearchIds.sublist(i, end);
                final placeholders = List.filled(idChunk.length, '?').join(',');
                final results = await db.rawQuery(
                  '''
                  $selectPrefix
                  WHERE $whereClause AND i.id IN ($placeholders)
                  ORDER BY $sortColumn $orderDirection
                  LIMIT ?
                  ''',
                  [...args, ...idChunk, limit],
                );
                for (final row in results) {
                  final id = (row['id'] as num).toInt();
                  if (seenIds.add(id)) {
                    ids.add(id);
                    paths.add(row['file_path'] as String);
                  }
                }
              }
            } else {
              // Mode B：无文本 + 候选路径限定
              // 单次 SQL 查出所有符合条件的记录，在 Dart 内存与候选路径 Set 求交。
              // 不带 ORDER BY（结果交给调用方排序），消除 800/块的分块循环与无效排序。
              final results = await db.rawQuery('''
                $selectPrefix
                WHERE $whereClause
                ''', args);
              final candidateSet = candidatePathList.toSet();
              for (final row in results) {
                final path = row['file_path'] as String?;
                if (path != null && candidateSet.contains(path)) {
                  final id = (row['id'] as num).toInt();
                  if (seenIds.add(id)) {
                    ids.add(id);
                    paths.add(path);
                  }
                }
              }
            }
          } else {
            // 无候选路径（兼容旧调用）
            if (textSearchIds != null && textSearchIds.isNotEmpty) {
              // 恢复旧语义：无候选路径且 textSearchIds 非空时，按 900 分块 AND i.id IN (...) 约束结果
              for (var i = 0; i < textSearchIds.length; i += textIdChunkSize) {
                final end = min(i + textIdChunkSize, textSearchIds.length);
                final idChunk = textSearchIds.sublist(i, end);
                final placeholders = List.filled(idChunk.length, '?').join(',');
                final results = await db.rawQuery(
                  '''
                  $selectPrefix
                  WHERE $whereClause AND i.id IN ($placeholders)
                  ORDER BY $sortColumn $orderDirection
                  LIMIT ?
                  ''',
                  [...args, ...idChunk, limit],
                );
                for (final row in results) {
                  final id = (row['id'] as num).toInt();
                  if (seenIds.add(id)) {
                    ids.add(id);
                    paths.add(row['file_path'] as String);
                  }
                }
              }
            } else {
              // 无文本搜索且无候选路径：单查询带 ORDER BY 与 LIMIT
              final results = await db.rawQuery(
                '''
                $selectPrefix
                WHERE $whereClause
                ORDER BY $sortColumn $orderDirection
                LIMIT ?
                ''',
                [...args, limit],
              );
              for (final row in results) {
                final id = (row['id'] as num).toInt();
                if (seenIds.add(id)) {
                  ids.add(id);
                  paths.add(row['file_path'] as String);
                }
              }
            }
          }

          final resultIds = ids.take(limit).toList(growable: false);
          final resultPaths = paths.take(limit).toList(growable: false);
          final searchResult = AdvancedSearchResult(
            ids: resultIds,
            filePaths: resultPaths,
          );

          // 更新缓存
          _queryCache.put(cacheKey, [resultIds, resultPaths]);

          return searchResult;
        });
      },
      details: 'text=${textQuery != null}, favorites=$favoritesOnly',
    );
  }

  /// 高级搜索 - 支持多条件组合查询（便捷包装，返回 ID 列表）
  Future<List<int>> advancedSearch({
    String? textQuery,
    DateTime? dateStart,
    DateTime? dateEnd,
    bool favoritesOnly = false,
    int? minWidth,
    int? minHeight,
    int? maxWidth,
    int? maxHeight,
    int? minFileSize,
    int? maxFileSize,
    List<String>? metadataStatuses,
    List<String>? models,
    List<String>? samplers,
    List<String>? resolutions,
    String? orientation,
    int? minSteps,
    int? maxSteps,
    double? minCfg,
    double? maxCfg,
    String? nsfwMode,
    bool naiOnly = false,
    String? orderByColumn,
    bool orderAscending = false,
    List<String>? candidatePaths,
    int limit = 100,
  }) async {
    final result = await advancedSearchResult(
      textQuery: textQuery,
      dateStart: dateStart,
      dateEnd: dateEnd,
      favoritesOnly: favoritesOnly,
      minWidth: minWidth,
      minHeight: minHeight,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      minFileSize: minFileSize,
      maxFileSize: maxFileSize,
      metadataStatuses: metadataStatuses,
      models: models,
      samplers: samplers,
      resolutions: resolutions,
      orientation: orientation,
      minSteps: minSteps,
      maxSteps: maxSteps,
      minCfg: minCfg,
      maxCfg: maxCfg,
      nsfwMode: nsfwMode,
      naiOnly: naiOnly,
      orderByColumn: orderByColumn,
      orderAscending: orderAscending,
      candidatePaths: candidatePaths,
      limit: limit,
    );
    return result.ids;
  }
}
