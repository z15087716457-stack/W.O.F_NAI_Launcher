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
    bool indexedDate = false,
    bool dateEndExclusive = false,
    bool? hasMetadata,
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
    /// 不再占用 LIMIT 名额挤掉真实文件；范围、文本和属性筛选共同完成后再排序取数。
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
      'indexedDate': indexedDate,
      'dateEndExclusive': dateEndExclusive,
      'hasMetadata': hasMetadata,
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

    return _trackQuery('advancedSearch', () async {
      final searchTerms = _extractSearchTerms(textQuery ?? '');

      return await execute('advancedSearch', (db) async {
        // Materialize exact-tag ID sets before the outer query. An IN subquery
        // over json_each can be correlated by SQLite and reparsed per row.
        Set<int>? exactIds;
        if (searchTerms.isNotEmpty) {
          final knownTags = await _knownSearchTags(db);
          for (final term in searchTerms.where(knownTags.contains)) {
            final ids = (await _exactTagImageIds(
              db,
              term,
              candidatePathList,
            )).toSet();
            exactIds = exactIds == null ? ids : exactIds.intersection(ids);
          }
          if (exactIds != null && exactIds.isEmpty) {
            return AdvancedSearchResult.empty;
          }
        }
        // 2. 构建查询条件
        final conditions = <String>['i.is_deleted = 0'];
        final args = <dynamic>[];

        // Exact IDs have already been intersected with candidate paths.
        if (candidatePathList != null && exactIds == null) {
          conditions.add('i.file_path IN (SELECT value FROM json_each(?))');
          args.add(jsonEncode(candidatePathList));
        }

        if (searchTerms.isNotEmpty) {
          final knownTags = await _knownSearchTags(db);
          for (final term in searchTerms) {
            if (knownTags.contains(term)) {
              continue;
            }
            final textConditions = <String>[];
            for (final variant in {term, term.replaceAll(' ', '_')}) {
              textConditions.add(
                r"(LOWER(i.file_name) LIKE ? ESCAPE '\' OR "
                r"LOWER(m.positive_prompt_text) LIKE ? ESCAPE '\')",
              );
              final pattern = '%${_escapeLikePattern(variant)}%';
              args.addAll([pattern, pattern]);
              // Delimited search historically includes folder paths as well.
              if ((textQuery ?? '').contains(RegExp(r'[,，]'))) {
                textConditions.add(r"LOWER(i.file_path) LIKE ? ESCAPE '\'");
                args.add(pattern);
              }
            }
            textConditions.add(
              'i.id IN (SELECT image_id FROM ${GalleryDataSource._ftsIndexTable} '
              'WHERE ${GalleryDataSource._ftsIndexTable} MATCH ?)',
            );
            args.add('"${term.replaceAll('"', '""')}"');
            conditions.add('(${textConditions.join(' OR ')})');
          }
        }

        if (favoritesOnly) {
          conditions.add('f.image_id IS NOT NULL');
        }

        final dateColumn = indexedDate
            ? '($_galleryStatisticsDate)'
            : 'i.modified_at';
        if (dateStart != null) {
          conditions.add('$dateColumn >= ?');
          args.add(
            indexedDate
                ? _statisticsDateValue(dateStart)
                : dateStart.millisecondsSinceEpoch,
          );
        }
        if (dateEnd != null) {
          conditions.add('$dateColumn ${dateEndExclusive ? '<' : '<='} ?');
          args.add(
            indexedDate
                ? _statisticsDateValue(dateEnd)
                : dateEnd.millisecondsSinceEpoch,
          );
        }
        if (hasMetadata != null) {
          conditions.add('COALESCE(m.has_metadata, 0) = ?');
          args.add(hasMetadata ? 1 : 0);
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

        if (hasMetadata == null &&
            metadataStatuses != null &&
            metadataStatuses.isNotEmpty) {
          final statusIndices = metadataStatuses
              .map((s) => MetadataStatus.values.indexWhere((v) => v.name == s))
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
            searchTerms.isNotEmpty ||
            models != null ||
            samplers != null ||
            minSteps != null ||
            maxSteps != null ||
            minCfg != null ||
            maxCfg != null ||
            nsfwMode != null ||
            hasMetadata != null ||
            indexedDate ||
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
        final width = indexedDate
            ? 'COALESCE(NULLIF(m.width, 0), NULLIF(i.width, 0))'
            : 'i.width';
        final height = indexedDate
            ? 'COALESCE(NULLIF(m.height, 0), NULLIF(i.height, 0))'
            : 'i.height';
        if (resolutions != null && resolutions.isNotEmpty) {
          final placeholders = List.filled(resolutions.length, '?').join(',');
          final resolution = indexedDate
              ? "CAST($width AS TEXT) || 'x' || CAST($height AS TEXT)"
              : 'i.resolution_key';
          conditions.add('($resolution) IN ($placeholders)');
          args.addAll(resolutions);
        }
        if (orientation != null) {
          switch (orientation) {
            case 'landscape':
              conditions.add('$width > $height');
            case 'portrait':
              conditions.add('$width < $height');
            case 'square':
              conditions.add('$width = $height');
          }
        }
        if (indexedDate &&
            (samplers != null ||
                minSteps != null ||
                maxSteps != null ||
                minCfg != null ||
                maxCfg != null)) {
          conditions.add('m.has_metadata = 1');
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

        // 范围、文本和属性筛选在同一查询中完成，最后排序和限制数量。
        Future<List<Map<String, Object?>>> query({List<int>? ids}) =>
            db.rawQuery(
              '''
            $selectPrefix
            WHERE $whereClause
            ${ids == null ? '' : 'AND i.id IN (${List.filled(ids.length, '?').join(',')})'}
            ORDER BY $sortColumn $orderDirection, i.id
            LIMIT ?
          ''',
              [...args, if (ids != null) ...ids, limit],
            );
        final results = <Map<String, Object?>>[];
        if (exactIds == null) {
          results.addAll(await query());
        } else {
          for (final ids in chunk(exactIds.toList(), 800)) {
            results.addAll(await query(ids: ids));
          }
          // Chunks each retain their own SQL ordering; merge using the same
          // sort keys before applying the global limit.
          if (results.length > 1) {
            final ordered = await db.rawQuery(
              '''
              SELECT i.id FROM ${GalleryDataSource._imagesTable} i
              WHERE i.id IN (SELECT value FROM json_each(?))
              ORDER BY $sortColumn $orderDirection, i.id
              LIMIT ?
            ''',
              [jsonEncode(results.map((r) => r['id']).toList()), limit],
            );
            final byId = {for (final row in results) row['id']: row};
            results
              ..clear()
              ..addAll(ordered.map((row) => byId[row['id']]!));
          }
        }
        final resultIds = results
            .map((row) => (row['id'] as num).toInt())
            .toList(growable: false);
        final resultPaths = results
            .map((row) => row['file_path'] as String)
            .toList(growable: false);
        final searchResult = AdvancedSearchResult(
          ids: resultIds,
          filePaths: resultPaths,
        );

        // 更新缓存
        _queryCache.put(cacheKey, [resultIds, resultPaths]);

        return searchResult;
      });
    }, details: 'text=${textQuery != null}, favorites=$favoritesOnly');
  }

  /// 高级搜索 - 支持多条件组合查询（便捷包装，返回 ID 列表）
  Future<List<int>> advancedSearch({
    String? textQuery,
    DateTime? dateStart,
    DateTime? dateEnd,
    bool indexedDate = false,
    bool dateEndExclusive = false,
    bool? hasMetadata,
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
      indexedDate: indexedDate,
      dateEndExclusive: dateEndExclusive,
      hasMetadata: hasMetadata,
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
