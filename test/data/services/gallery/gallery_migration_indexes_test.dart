import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';

void main() {
  group('Gallery Redundant Index Migration Tests', () {
    late Directory tempDir;
    late String dbPath;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'nai_launcher_migration_test_',
      );
      dbPath = p.join(tempDir.path, 'gallery.db');
    });

    tearDown(() async {
      await ConnectionPoolHolder.dispose();
      if (await tempDir.exists()) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    });

    test('新库初始化不建毒瘤索引，并写入 meta 迁移标记', () async {
      await ConnectionPoolHolder.initialize(dbPath: dbPath, maxConnections: 2);
      final dataSource = GalleryDataSource();
      await dataSource.initialize();

      final db = await databaseFactory.openDatabase(dbPath);
      final indexRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='gallery_images'",
      );
      final indexNames = indexRows.map((r) => r['name'] as String).toSet();

      // 验证不应创建毒瘤索引
      expect(indexNames.contains('idx_gallery_images_composite'), isFalse);
      expect(indexNames.contains('idx_gallery_images_is_deleted'), isFalse);

      // 验证有效索引存在
      expect(indexNames.contains('idx_gallery_images_modified_at'), isTrue);
      expect(indexNames.contains('idx_gallery_images_favorite'), isTrue);

      // 验证写入了迁移标记
      final metaRows = await db.rawQuery(
        "SELECT value FROM gallery_meta WHERE key = 'drop_redundant_indexes_analyze_v1'",
      );
      expect(metaRows.isNotEmpty, isTrue);

      await db.close();
      await dataSource.dispose();
    });

    test('老库存在毒瘤索引时，初始化会 DROP 这两个索引并写入标记；二次初始化保持幂等', () async {
      // 1. 模拟老库：手动创建 images 表并建立两个毒瘤索引
      final rawDb = await databaseFactory.openDatabase(dbPath);
      await rawDb.execute('''
        CREATE TABLE gallery_images (
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
      await rawDb.execute('''
        CREATE INDEX idx_gallery_images_is_deleted
        ON gallery_images(is_deleted, modified_at DESC)
      ''');
      await rawDb.execute('''
        CREATE INDEX idx_gallery_images_composite
        ON gallery_images(is_deleted, is_favorite, modified_at DESC)
      ''');
      await rawDb.close();

      // 2. 正常初始化
      await ConnectionPoolHolder.initialize(dbPath: dbPath, maxConnections: 2);
      final dataSource = GalleryDataSource();
      await dataSource.initialize();

      // 验证已 DROP 毒瘤索引
      final checkDb = await databaseFactory.openDatabase(dbPath);
      final indexRows = await checkDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='gallery_images'",
      );
      final indexNames = indexRows.map((r) => r['name'] as String).toSet();
      expect(indexNames.contains('idx_gallery_images_composite'), isFalse);
      expect(indexNames.contains('idx_gallery_images_is_deleted'), isFalse);

      final metaRows = await checkDb.rawQuery(
        "SELECT value FROM gallery_meta WHERE key = 'drop_redundant_indexes_analyze_v1'",
      );
      expect(metaRows.isNotEmpty, isTrue);

      await checkDb.close();
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();

      // 3. 二次初始化：已带标记，幂等安全
      await ConnectionPoolHolder.initialize(dbPath: dbPath, maxConnections: 2);
      final dataSource2 = GalleryDataSource();
      await dataSource2.initialize();

      final checkDb2 = await databaseFactory.openDatabase(dbPath);
      final metaRows2 = await checkDb2.rawQuery(
        "SELECT value FROM gallery_meta WHERE key = 'drop_redundant_indexes_analyze_v1'",
      );
      expect(metaRows2.isNotEmpty, isTrue);
      expect(metaRows2.first['value'], metaRows.first['value']);

      await checkDb2.close();
      await dataSource2.dispose();
    });
  });
}
