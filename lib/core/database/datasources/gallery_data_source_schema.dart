part of 'gallery_data_source.dart';

mixin GalleryDataSourceSchema on EnhancedBaseDataSource {
  @override
  Future<void> doInitialize() async {
    return await execute('doInitialize', (db) async {
      await _createImagesTable(db);
      await _createMetadataTable(db);
      await _createFavoritesTable(db);
      await _createTagsTable(db);
      await _createImageTagsTable(db);
      await _createScanLogsTable(db);
      await _createFtsIndexTable(db);
      await _createCollectionsTables(db);

      // 迁移：添加 last_scanned_at 列（如果缺失）
      await _migrateAddLastScannedAt(db);

      // 迁移：添加 is_nsfw 列（如果缺失）
      await _migrateAddIsNsfw(db);

      // 迁移：回填历史行的 model 列（一次性，gallery_meta 记完成标记）
      await _migrateBackfillModelColumn(db);

      // 迁移：收藏集成员补写进收藏表（一次性，gallery_meta 记完成标记）
      await _migrateCollectionMembersToFavorites(db);

      AppLogger.i('Gallery tables initialized', 'GalleryDS');
    });
  }

  /// 迁移：回填历史元数据行的 model 列（按版本一次性）。
  ///
  /// 旧扫描行 model 为空，但 source/software/raw_json 里带模型指纹
  ///（V5 Source「NovelAI Diffusion V5 …」、params 新信封 model_name、
  /// V3「Stable Diffusion XL <哈希>」、转存件指纹落 software 列、
  /// 整 tEXt 表序列化进单个 Comment 字段的信封件指纹在 raw_json
  /// 内层 Source 键等）；版本过滤直接读 model 列，必须落库。
  /// 派生走与扫描一致的入口：source → raw_json（[NovelAiParser] 全信封
  /// 规则）→ software 兜底。无法推导的行（如 stealth V4.5）保持 NULL，
  /// 与新扫描结果一致。
  Future<void> _migrateBackfillModelColumn(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${GalleryDataSource._galleryMetaTable} (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
      final done = await db.rawQuery(
        "SELECT value FROM ${GalleryDataSource._galleryMetaTable} "
        "WHERE key = 'model_backfill_v3'",
      );
      if (done.isNotEmpty) return;

      final updated = await _backfillModelColumnImpl(db);
      await db.insert(GalleryDataSource._galleryMetaTable, {
        'key': 'model_backfill_v3',
        'value': '$updated',
      });
      AppLogger.i(
        '[Migration] model column backfill v3 done: $updated rows updated',
        'GalleryDS',
      );
    } catch (e, stack) {
      // 迁移失败不阻止应用启动
      AppLogger.e(
        '[Migration] Failed to backfill model column',
        e,
        stack,
        'GalleryDS',
      );
    }
  }

  /// 按 source/software/raw_json 指纹回填 model 列，返回更新行数。
  Future<int> _backfillModelColumnImpl(Database db) async {
    final rows = await db.rawQuery('''
      SELECT image_id, source, software, raw_json
      FROM ${GalleryDataSource._metadataTable}
      WHERE has_metadata = 1 AND (model IS NULL OR model = '')
        AND (source LIKE '%Diffusion%' OR software LIKE '%Diffusion%'
             OR raw_json LIKE '%model_name%' OR raw_json LIKE '%Diffusion%')
    ''');
    if (rows.isEmpty) return 0;

    var updated = 0;
    final batch = db.batch();
    for (final row in rows) {
      final source = row['source'] as String?;
      final software = row['software'] as String?;
      final rawJson = row['raw_json'] as String?;

      String? derived;
      if (source != null && source.isNotEmpty) {
        derived = NaiImageMetadata.modelIdFromFingerprint(source);
      }
      if (derived == null && rawJson != null && rawJson.isNotEmpty) {
        derived = NovelAiParser().parse({'Comment': rawJson})?.model;
      }
      if (derived == null && software != null && software.isNotEmpty) {
        derived = NaiImageMetadata.modelIdFromFingerprint(software);
      }
      if (derived == null) continue;

      batch.update(
        GalleryDataSource._metadataTable,
        {'model': derived},
        where: 'image_id = ?',
        whereArgs: [(row['image_id'] as num).toInt()],
      );
      updated++;
    }
    if (updated > 0) {
      await batch.commit(noResult: true);
    }
    return updated;
  }

  /// 迁移：收藏集成员补写进收藏表（按版本一次性）。
  ///
  /// 旧版本收藏集与心形收藏是两套独立系统：只进集合、未心形的图在
  /// 「收藏」根节点看不到、也无法批量移除。此迁移把
  /// `gallery_collection_items` 的 image_id 去重补写进 `gallery_favorites`
  ///（幂等 INSERT OR IGNORE，已有心形记录保留原 favorited_at），此后
  /// favorites 表即「收藏」根的全集（根=总收藏，子集=根的细分）。
  Future<void> _migrateCollectionMembersToFavorites(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${GalleryDataSource._galleryMetaTable} (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
      final done = await db.rawQuery(
        "SELECT value FROM ${GalleryDataSource._galleryMetaTable} "
        "WHERE key = 'favorites_collection_members_v1'",
      );
      if (done.isNotEmpty) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final migrated = await db.rawUpdate(
        'INSERT OR IGNORE INTO ${GalleryDataSource._favoritesTable} '
        '(image_id, favorited_at) '
        'SELECT DISTINCT image_id, ? '
        'FROM ${GalleryDataSource._collectionItemsTable}',
        [now],
      );
      await db.insert(GalleryDataSource._galleryMetaTable, {
        'key': 'favorites_collection_members_v1',
        'value': '$migrated',
      });
      // 收藏缓存可能已被旧数据预热，迁移后强制重载
      (this as GalleryDataSource)._favoritesLoaded = false;
      AppLogger.i(
        '[Migration] favorites collection-members backfill done: +$migrated',
        'GalleryDS',
      );
    } catch (e, stack) {
      // 迁移失败不阻止应用启动（不落标记：下次启动重试）
      AppLogger.e(
        '[Migration] Failed to backfill favorites from collection members',
        e,
        stack,
        'GalleryDS',
      );
    }
  }

  Future<void> _createImagesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${GalleryDataSource._imagesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL UNIQUE,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL DEFAULT 0,
        width INTEGER,
        height INTEGER,
        aspect_ratio REAL,
        modified_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        indexed_at INTEGER NOT NULL,
        last_scanned_at INTEGER,
        date_ymd INTEGER NOT NULL DEFAULT 0,
        resolution_key TEXT,
        metadata_status INTEGER NOT NULL DEFAULT 2,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 核心索引：按修改时间排序（主查询）
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_images_modified_at
      ON ${GalleryDataSource._imagesTable}(modified_at DESC)
    ''');

    // 核心索引：按创建时间排序
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_images_created_at
      ON ${GalleryDataSource._imagesTable}(created_at DESC)
    ''');

    // 核心索引：按 ID 主键查询
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_images_id_deleted
      ON ${GalleryDataSource._imagesTable}(id) WHERE is_deleted = 0
    ''');

    // 核心索引：按日期分组
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_images_date_ymd
      ON ${GalleryDataSource._imagesTable}(date_ymd DESC) WHERE is_deleted = 0
    ''');

    // 核心索引：收藏过滤
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_images_favorite
      ON ${GalleryDataSource._imagesTable}(is_favorite, modified_at DESC) WHERE is_deleted = 0
    ''');

    // 核心索引：元数据状态过滤
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_images_metadata_status
      ON ${GalleryDataSource._imagesTable}(metadata_status) WHERE is_deleted = 0
    ''');

    // 核心索引：is_deleted 过滤（软删除）
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_images_is_deleted
      ON ${GalleryDataSource._imagesTable}(is_deleted, modified_at DESC)
    ''');

    // 核心索引：画廊扫描性能优化 - 文件路径
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_images_file_path
      ON ${GalleryDataSource._imagesTable}(file_path) WHERE is_deleted = 0
    ''');

    // 复合索引：多条件查询优化
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_images_composite
      ON ${GalleryDataSource._imagesTable}(is_deleted, is_favorite, modified_at DESC)
    ''');
  }

  /// 迁移：添加 last_scanned_at 列（如果缺失）
  Future<void> _migrateAddLastScannedAt(Database db) async {
    try {
      // 检查列是否存在
      final tableInfo = await db.rawQuery(
        'PRAGMA table_info(${GalleryDataSource._imagesTable})',
      );
      final hasColumn = tableInfo.any(
        (col) => col['name'] == 'last_scanned_at',
      );

      if (!hasColumn) {
        AppLogger.i(
          '[Migration] Adding last_scanned_at column to ${GalleryDataSource._imagesTable}',
          'GalleryDS',
        );
        await db.execute(
          'ALTER TABLE ${GalleryDataSource._imagesTable} ADD COLUMN last_scanned_at INTEGER',
        );
        AppLogger.i(
          '[Migration] last_scanned_at column added successfully',
          'GalleryDS',
        );
      } else {
        AppLogger.d(
          '[Migration] last_scanned_at column already exists',
          'GalleryDS',
        );
      }
    } catch (e, stack) {
      AppLogger.e(
        '[Migration] Failed to add last_scanned_at column',
        e,
        stack,
        'GalleryDS',
      );
      // 迁移失败不应该阻止应用启动
    }
  }

  /// 迁移：添加 is_nsfw 列（如果缺失）
  Future<void> _migrateAddIsNsfw(Database db) async {
    try {
      final tableInfo = await db.rawQuery(
        'PRAGMA table_info(${GalleryDataSource._metadataTable})',
      );
      final hasColumn = tableInfo.any((col) => col['name'] == 'is_nsfw');

      if (!hasColumn) {
        AppLogger.i(
          '[Migration] Adding is_nsfw column to ${GalleryDataSource._metadataTable}',
          'GalleryDS',
        );
        await db.execute(
          'ALTER TABLE ${GalleryDataSource._metadataTable} '
          'ADD COLUMN is_nsfw INTEGER NOT NULL DEFAULT 0',
        );
        AppLogger.i(
          '[Migration] is_nsfw column added successfully',
          'GalleryDS',
        );
      }
    } catch (e, stack) {
      AppLogger.e(
        '[Migration] Failed to add is_nsfw column',
        e,
        stack,
        'GalleryDS',
      );
      // 迁移失败不应该阻止应用启动
    }
  }

  Future<void> _createMetadataTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${GalleryDataSource._metadataTable} (
        image_id INTEGER PRIMARY KEY,
        prompt TEXT NOT NULL DEFAULT '',
        negative_prompt TEXT NOT NULL DEFAULT '',
        seed INTEGER,
        sampler TEXT,
        steps INTEGER,
        cfg_scale REAL,
        width INTEGER,
        height INTEGER,
        model TEXT,
        smea INTEGER NOT NULL DEFAULT 0,
        smea_dyn INTEGER NOT NULL DEFAULT 0,
        noise_schedule TEXT,
        cfg_rescale REAL,
        uc_preset INTEGER,
        quality_toggle INTEGER NOT NULL DEFAULT 0,
        is_img2img INTEGER NOT NULL DEFAULT 0,
        strength REAL,
        noise REAL,
        software TEXT,
        source TEXT,
        version TEXT,
        raw_json TEXT,
        has_metadata INTEGER NOT NULL DEFAULT 0,
        is_nsfw INTEGER NOT NULL DEFAULT 0,
        full_prompt_text TEXT NOT NULL DEFAULT '',
        vibe_encoding TEXT,
        vibe_strength REAL,
        vibe_info_extracted REAL,
        vibe_source_type TEXT,
        has_vibe INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (image_id) REFERENCES ${GalleryDataSource._imagesTable}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_metadata_model
      ON ${GalleryDataSource._metadataTable}(model) WHERE model IS NOT NULL AND model != ''
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_metadata_sampler
      ON ${GalleryDataSource._metadataTable}(sampler) WHERE sampler IS NOT NULL AND sampler != ''
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_metadata_seed
      ON ${GalleryDataSource._metadataTable}(seed)
    ''');

    // 新增索引：全文搜索优化
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_metadata_prompt
      ON ${GalleryDataSource._metadataTable}(prompt) WHERE prompt IS NOT NULL AND prompt != ''
    ''');
  }

  Future<void> _createFavoritesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${GalleryDataSource._favoritesTable} (
        image_id INTEGER PRIMARY KEY,
        favorited_at INTEGER NOT NULL,
        FOREIGN KEY (image_id) REFERENCES ${GalleryDataSource._imagesTable}(id) ON DELETE CASCADE
      )
    ''');

    // 新增索引：收藏时间排序
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_favorites_time
      ON ${GalleryDataSource._favoritesTable}(favorited_at DESC)
    ''');
  }

  Future<void> _createTagsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${GalleryDataSource._tagsTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        category TEXT,
        usage_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_tags_name
      ON ${GalleryDataSource._tagsTable}(name)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_tags_category
      ON ${GalleryDataSource._tagsTable}(category)
    ''');

    // 新增索引：使用频次排序
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_tags_usage
      ON ${GalleryDataSource._tagsTable}(usage_count DESC)
    ''');
  }

  Future<void> _createImageTagsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${GalleryDataSource._imageTagsTable} (
        image_id INTEGER NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (image_id, tag_id),
        FOREIGN KEY (image_id) REFERENCES ${GalleryDataSource._imagesTable}(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES ${GalleryDataSource._tagsTable}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_image_tags_tag_id
      ON ${GalleryDataSource._imageTagsTable}(tag_id)
    ''');
  }

  Future<void> _createScanLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${GalleryDataSource._scanLogsTable} (
        id TEXT PRIMARY KEY,
        started_at INTEGER NOT NULL,
        completed_at INTEGER,
        total_files INTEGER NOT NULL DEFAULT 0,
        processed_files INTEGER NOT NULL DEFAULT 0,
        new_files INTEGER NOT NULL DEFAULT 0,
        updated_files INTEGER NOT NULL DEFAULT 0,
        failed_files INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        scan_path TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_scan_logs_started_at
      ON ${GalleryDataSource._scanLogsTable}(started_at DESC)
    ''');
  }

  Future<void> _createFtsIndexTable(Database db) async {
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS ${GalleryDataSource._ftsIndexTable} USING fts5(
        image_id UNINDEXED,
        prompt_text,
        tokenize = 'porter'
      )
    ''');
  }

  /// 收藏集表（链接式：只存 image_id 成员关系，不复制文件）
  Future<void> _createCollectionsTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${GalleryDataSource._collectionsTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${GalleryDataSource._collectionItemsTable} (
        collection_id TEXT NOT NULL,
        image_id INTEGER NOT NULL,
        added_at INTEGER NOT NULL,
        PRIMARY KEY (collection_id, image_id),
        FOREIGN KEY (collection_id)
          REFERENCES ${GalleryDataSource._collectionsTable}(id) ON DELETE CASCADE,
        FOREIGN KEY (image_id)
          REFERENCES ${GalleryDataSource._imagesTable}(id) ON DELETE CASCADE
      )
    ''');

    // 按图反查成员关系的索引（卡片菜单/过滤）
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_gallery_collection_items_image_id
      ON ${GalleryDataSource._collectionItemsTable}(image_id)
    ''');
  }

  @override
  Future<DataSourceHealth> doCheckHealth() async {
    return await execute('doCheckHealth', (db) async {
      final source = this as GalleryDataSource;
      final tables = [
        GalleryDataSource._imagesTable,
        GalleryDataSource._metadataTable,
        GalleryDataSource._favoritesTable,
        GalleryDataSource._tagsTable,
        GalleryDataSource._imageTagsTable,
        GalleryDataSource._scanLogsTable,
        GalleryDataSource._ftsIndexTable,
        GalleryDataSource._collectionsTable,
        GalleryDataSource._collectionItemsTable,
      ];

      final missingTables = <String>[];

      for (final table in tables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [table],
        );
        if (result.isEmpty) {
          missingTables.add(table);
        }
      }

      if (missingTables.isNotEmpty) {
        return DataSourceHealth(
          status: HealthStatus.corrupted,
          message: 'Missing tables: ${missingTables.join(', ')}',
          details: {'missingTables': missingTables},
          timestamp: DateTime.now(),
        );
      }

      for (final table in tables) {
        await db.rawQuery('SELECT 1 FROM $table LIMIT 1');
      }

      final imageCount = await _getTableCount(
        db,
        GalleryDataSource._imagesTable,
      );
      final metadataCount = await _getTableCount(
        db,
        GalleryDataSource._metadataTable,
      );
      final tagCount = await _getTableCount(db, GalleryDataSource._tagsTable);

      return DataSourceHealth(
        status: HealthStatus.healthy,
        message: 'Gallery data source is healthy',
        details: {
          'imageCount': imageCount,
          'metadataCount': metadataCount,
          'tagCount': tagCount,
          'imageCacheSize': source._imageCache.size,
          'queryCacheSize': source._queryCache.size,
          'cacheHitRate': {
            'image': source._imageCache.hitRate,
            'query': source._queryCache.hitRate,
          },
          'slowQueryCount': source._slowQueryLogs.length,
        },
        timestamp: DateTime.now(),
      );
    });
  }

  Future<int> _getTableCount(dynamic db, String tableName) async {
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName',
      );
      return (result.first['count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> doClear() async {
    (this as GalleryDataSource).clearCache();
    AppLogger.i('Gallery data source cleared', 'GalleryDS');
  }

  @override
  Future<void> doRestore() async {
    (this as GalleryDataSource).clearCache();
    AppLogger.i('Gallery data source ready for restore', 'GalleryDS');
  }
}
