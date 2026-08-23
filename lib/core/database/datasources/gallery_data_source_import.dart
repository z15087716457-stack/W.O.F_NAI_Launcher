part of 'gallery_data_source.dart';

String _buildImportedFullPromptText(TagIndexImportEntry entry) {
  final buffer = StringBuffer();

  void append(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return;
    if (buffer.isNotEmpty) {
      buffer.write(' ');
    }
    buffer.write(text);
  }

  append(entry.prompt);
  append(entry.negativePrompt);
  append(entry.model);
  append(entry.sampler);
  append(entry.software);
  append(entry.source);

  return buffer.toString();
}

/// 批量导入标签索引条目（JSONL 索引导入专用，幂等可重导）
///
/// 每批在一个事务内完成：
/// - [gallery_images]：按规范化 file_path 查，不存在则创建
///   （metadata_status=imported，last_scanned_at 置为当前，避免扫描器重复解析），
///   已存在则更新 size/mtime/宽高等（防过期），保留收藏状态
/// - [gallery_metadata]：写 prompt/negative_prompt/full_prompt_text/
///   source/software/seed/raw_json（整行原始 JSON 备查）
/// - [gallery_tags] + [gallery_image_tags]：先清该图旧关联再插入（幂等）
/// - [gallery_fts_index]：与元数据写入同路维护（先删后插）
///
/// 返回 (新建数, 更新数)
Future<(int, int)> _importTagIndexEntries(
  GalleryDataSource dataSource,
  List<TagIndexImportEntry> entries, {
  int batchSize = 500,
}) async {
  if (entries.isEmpty) return (0, 0);

  var importedCount = 0;
  var updatedCount = 0;

  for (var i = 0; i < entries.length; i += batchSize) {
    final end = (i + batchSize < entries.length)
        ? i + batchSize
        : entries.length;
    final batch = entries.sublist(i, end);
    final batchIndex = i ~/ batchSize;

    final (created, touched) = await dataSource.executeTransaction(
      'importTagIndexEntries#batch$batchIndex',
      (txn) async {
        var created = 0;
        var touched = 0;

        // 1. 批量查询现有记录（一次查询），并保留收藏状态
        final filePaths = batch.map((e) => e.filePath).toList();
        final placeholders = List.filled(filePaths.length, '?').join(',');
        final existingResults = await txn.rawQuery(
          '''
          SELECT id, file_path, is_favorite FROM ${GalleryDataSource._imagesTable}
          WHERE file_path IN ($placeholders)
          ''',
          filePaths,
        );

        final pathToIdMap = <String, int>{};
        final pathToFavorite = <String, bool>{};
        for (final row in existingResults) {
          final path = row['file_path'] as String?;
          final id = (row['id'] as num?)?.toInt();
          if (path != null && id != null) {
            pathToIdMap[path] = id;
            pathToFavorite[path] = (row['is_favorite'] as num?)?.toInt() == 1;
          }
        }

        // 1.5 批量取旧 is_nsfw 分级（metadata 表；REPLACE 会整行覆盖，
        // JSONL 无 nsfw 字段时保留已有分级，显式 true/false 才覆盖）
        final existingImageIds =
            pathToIdMap.values.where((id) => id > 0).toList();
        final pathToNsfw = <String, int>{};
        if (existingImageIds.isNotEmpty) {
          final idPlaceholders = List.filled(
            existingImageIds.length,
            '?',
          ).join(',');
          final nsfwRows = await txn.rawQuery(
            '''
            SELECT image_id, is_nsfw FROM ${GalleryDataSource._metadataTable}
            WHERE image_id IN ($idPlaceholders)
            ''',
            existingImageIds,
          );
          final idToNsfw = <int, int>{
            for (final row in nsfwRows)
              if (row['image_id'] != null)
                (row['image_id'] as num).toInt():
                    (row['is_nsfw'] as num?)?.toInt() ?? 0,
          };
          for (final entry in pathToIdMap.entries) {
            pathToNsfw[entry.key] = idToNsfw[entry.value] ?? 0;
          }
        }

        final now = DateTime.now();
        final ftsUpdates = <int, String>{};

        for (final entry in batch) {
          final existingId = pathToIdMap[entry.filePath];
          final imageMap = {
            'file_path': entry.filePath,
            'file_name': entry.fileName,
            'file_size': entry.fileSize,
            'width': entry.width,
            'height': entry.height,
            'aspect_ratio': entry.width != null &&
                    entry.height != null &&
                    entry.height! > 0
                ? entry.width! / entry.height!
                : null,
            'modified_at': entry.modifiedAt.millisecondsSinceEpoch,
            'created_at': entry.modifiedAt.millisecondsSinceEpoch,
            'indexed_at': now.millisecondsSinceEpoch,
            'last_scanned_at': now.millisecondsSinceEpoch,
            'date_ymd': dataSource._formatDateYmd(entry.modifiedAt),
            'resolution_key': entry.width != null && entry.height != null
                ? '${entry.width}x${entry.height}'
                : null,
            'metadata_status': MetadataStatus.imported.index,
            'is_favorite': (pathToFavorite[entry.filePath] ?? false) ? 1 : 0,
            'is_deleted': 0,
          };

          final int imageId;
          if (existingId != null) {
            dataSource._imageCache.remove(existingId);
            await txn.update(
              GalleryDataSource._imagesTable,
              imageMap,
              where: 'id = ?',
              whereArgs: [existingId],
            );
            imageId = existingId;
            touched++;
          } else {
            imageId = await txn.insert(
              GalleryDataSource._imagesTable,
              imageMap,
              conflictAlgorithm: ConflictAlgorithm.abort,
            );
            pathToIdMap[entry.filePath] = imageId;
            created++;
          }

          // 2. 元数据（整行覆盖，幂等）
          final fullPromptText = _buildImportedFullPromptText(entry);
          await txn.insert(
            GalleryDataSource._metadataTable,
            {
              'image_id': imageId,
              'prompt': entry.prompt ?? '',
              'negative_prompt': entry.negativePrompt ?? '',
              'seed': entry.seed,
              'width': entry.width,
              'height': entry.height,
              'model': entry.model,
              'sampler': entry.sampler,
              'steps': entry.steps,
              'cfg_scale': entry.cfgScale,
              'noise_schedule': entry.noiseSchedule,
              'software': entry.software,
              'source': entry.source,
              'raw_json': entry.rawJson,
              'has_metadata':
                  (entry.prompt?.isNotEmpty == true ||
                          entry.negativePrompt?.isNotEmpty == true ||
                          entry.source != null ||
                          entry.software != null ||
                          entry.seed != null ||
                          entry.model != null ||
                          entry.sampler != null ||
                          entry.steps != null ||
                          entry.cfgScale != null)
                      ? 1
                      : 0,
              // JSONL 无 nsfw 字段（null）时保留已有分级，显式 true/false 才覆盖
              'is_nsfw': (entry.nsfw ?? (pathToNsfw[entry.filePath] ?? 0) == 1)
                  ? 1
                  : 0,
              'full_prompt_text': fullPromptText,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          ftsUpdates[imageId] = fullPromptText;

          // 3. 标签：先清旧关联再插入（幂等可重导）
          final oldTagRows = await txn.rawQuery(
            'SELECT tag_id FROM ${GalleryDataSource._imageTagsTable} WHERE image_id = ?',
            [imageId],
          );
          await txn.delete(
            GalleryDataSource._imageTagsTable,
            where: 'image_id = ?',
            whereArgs: [imageId],
          );

          final normalizedTags = entry.tags
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toSet()
              .toList();
          final affectedTagIds = oldTagRows
              .map((row) => row['tag_id'] as String)
              .toSet();

          for (final tagName in normalizedTags) {
            final tagId = dataSource._generateTagId(tagName);
            affectedTagIds.add(tagId);

            await txn.insert(
              GalleryDataSource._tagsTable,
              {'id': tagId, 'name': tagName, 'usage_count': 0},
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            await txn.insert(
              GalleryDataSource._imageTagsTable,
              {'image_id': imageId, 'tag_id': tagId},
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }

          // 重新统计受影响标签的使用次数
          for (final tagId in affectedTagIds) {
            await txn.rawUpdate(
              '''
              UPDATE ${GalleryDataSource._tagsTable}
              SET usage_count = (
                SELECT COUNT(*) FROM ${GalleryDataSource._imageTagsTable} WHERE tag_id = ?
              )
              WHERE id = ?
              ''',
              [tagId, tagId],
            );
          }
        }

        // 4. FTS 索引：与元数据写入同路维护（先删后插）
        await dataSource._batchUpdateFtsIndex(txn, ftsUpdates);

        return (created, touched);
      },
      timeout: const Duration(seconds: 60),
    );

    importedCount += created;
    updatedCount += touched;

    if (end < entries.length) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  dataSource._markDataChanged();

  AppLogger.i(
    'Imported ${entries.length} tag index entries: '
    '$importedCount new, $updatedCount updated',
    'GalleryDS',
  );

  return (importedCount, updatedCount);
}
