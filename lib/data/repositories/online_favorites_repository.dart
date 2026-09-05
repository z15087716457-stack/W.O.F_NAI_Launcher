import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/cache/danbooru_image_cache_manager.dart';
import '../models/online_gallery/gallery_item.dart';
import '../models/online_gallery/gallery_source.dart';

/// 在线收藏条目：snapshot 还原的 GalleryItem + 归属信息
class OnlineFavoriteEntry {
  const OnlineFavoriteEntry({
    required this.item,
    required this.collectionId,
    required this.savedAt,
  });

  final GalleryItem item;
  final String? collectionId;
  final DateTime savedAt;
}

/// 在线收藏子集
class OnlineCollectionInfo {
  const OnlineCollectionInfo({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int itemCount;
  final DateTime createdAt;
}

/// 收藏的作者
class OnlineFavoriteAuthor {
  const OnlineFavoriteAuthor({
    required this.source,
    required this.authorId,
    required this.authorName,
    required this.savedAt,
  });

  final GallerySourceId source;
  final int authorId;
  final String authorName;
  final DateTime savedAt;
}

/// 在线画廊本地收藏仓库（独立 DB，不依赖站点账号）
///
/// 支持：作品收藏（可归入子集）、子集 CRUD、作者收藏。
/// 作品保存完整快照 JSON，收藏列表离线可看。
class OnlineFavoritesRepository {
  OnlineFavoritesRepository._() : _debugDbPath = null;

  /// 测试注入：使用指定 DB 路径的独立实例（不影响生产单例）
  @visibleForTesting
  OnlineFavoritesRepository.forTesting(String dbPath) : _debugDbPath = dbPath;

  static final OnlineFavoritesRepository instance =
      OnlineFavoritesRepository._();

  final String? _debugDbPath;
  Database? _database;
  Future<void>? _initialization;

  Future<void> initialize() {
    final db = _database;
    if (db != null && db.isOpen) return Future.value();
    return _initialization ??= _open().whenComplete(
      () => _initialization = null,
    );
  }

  Future<void> _open() async {
    final debugPath = _debugDbPath;
    final String dbFile;
    if (debugPath != null) {
      await Directory(p.dirname(debugPath)).create(recursive: true);
      dbFile = debugPath;
    } else {
      final support = await getApplicationSupportDirectory();
      final directory = Directory(p.join(support.path, 'online_favorites'));
      await directory.create(recursive: true);
      dbFile = p.join(directory.path, 'online_favorites.db');
    }
    _database = await databaseFactoryFfi.openDatabase(
      dbFile,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE online_collections(
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              sort_order INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE online_favorites(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              source TEXT NOT NULL,
              work_id INTEGER NOT NULL,
              collection_id TEXT,
              title TEXT,
              author_id INTEGER NOT NULL DEFAULT 0,
              author_name TEXT NOT NULL DEFAULT '',
              cover_url TEXT NOT NULL DEFAULT '',
              cover_width INTEGER NOT NULL DEFAULT 0,
              cover_height INTEGER NOT NULL DEFAULT 0,
              saved_at INTEGER NOT NULL,
              snapshot TEXT NOT NULL,
              UNIQUE(source, work_id)
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_online_fav_collection ON online_favorites(source, collection_id)',
          );
          await db.execute(
            'CREATE INDEX idx_online_fav_author ON online_favorites(source, author_id)',
          );
          await db.execute('''
            CREATE TABLE online_favorite_authors(
              source TEXT NOT NULL,
              author_id INTEGER NOT NULL,
              author_name TEXT NOT NULL,
              saved_at INTEGER NOT NULL,
              PRIMARY KEY(source, author_id)
            )
          ''');
        },
      ),
    );
  }

  Future<Database> _db() async {
    await initialize();
    return _database!;
  }

  // ============ 子集 ============

  Future<String> createCollection(String name) async {
    final id =
        'oc_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode.toUnsigned(20)}';
    await (await _db()).insert('online_collections', {
      'id': id,
      'name': name.trim(),
      'sort_order': DateTime.now().millisecondsSinceEpoch,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return id;
  }

  Future<bool> renameCollection(String id, String newName) async {
    final count = await (await _db()).update(
      'online_collections',
      {'name': newName.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  /// 删除子集：成员回落到根收藏（collection_id 置空）
  Future<bool> deleteCollection(String id) async {
    final db = await _db();
    final removed = await db.delete(
      'online_collections',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (removed > 0) {
      await db.update(
        'online_favorites',
        {'collection_id': null},
        where: 'collection_id = ?',
        whereArgs: [id],
      );
    }
    return removed > 0;
  }

  Future<List<OnlineCollectionInfo>> listCollectionsWithCounts(
    GallerySourceId source,
  ) async {
    final rows = await (await _db()).rawQuery(
      '''
      SELECT c.id, c.name, c.created_at,
        (SELECT COUNT(*) FROM online_favorites f
          WHERE f.collection_id = c.id AND f.source = ?) AS item_count
      FROM online_collections c
      ORDER BY c.sort_order ASC, c.created_at ASC
    ''',
      [source.key],
    );
    return [
      for (final row in rows)
        OnlineCollectionInfo(
          id: row['id']!.toString(),
          name: row['name']!.toString(),
          itemCount: (row['item_count'] as num).toInt(),
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            (row['created_at'] as num).toInt(),
          ),
        ),
    ];
  }

  // ============ 作品收藏 ============

  /// 收藏作品（幂等）。[collectionId] 为 null 表示根收藏；
  /// 已收藏时更新其归属子集（移动语义）。
  Future<void> addFavorite(GalleryItem item, {String? collectionId}) async {
    final cover = item.cover;
    await (await _db()).insert('online_favorites', {
      'source': item.sourceId.key,
      'work_id': item.id,
      'collection_id': collectionId,
      'title': item.title,
      'author_id': item.uploaderId,
      'author_name': item.author ?? '',
      'cover_url': cover.previewUrl.isNotEmpty
          ? cover.previewUrl
          : cover.displayUrl,
      'cover_width': cover.width,
      'cover_height': cover.height,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
      'snapshot': jsonEncode(item.toSnapshotJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFavorite(GallerySourceId source, int workId) async {
    await (await _db()).delete(
      'online_favorites',
      where: 'source = ? AND work_id = ?',
      whereArgs: [source.key, workId],
    );
  }

  Future<bool> isFavorite(GallerySourceId source, int workId) async {
    final rows = await (await _db()).query(
      'online_favorites',
      columns: ['id'],
      where: 'source = ? AND work_id = ?',
      whereArgs: [source.key, workId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<Set<int>> favoritedWorkIds(GallerySourceId source) async {
    final rows = await (await _db()).query(
      'online_favorites',
      columns: ['work_id'],
      where: 'source = ?',
      whereArgs: [source.key],
    );
    return rows.map((row) => (row['work_id'] as num).toInt()).toSet();
  }

  /// 列出收藏。[collectionId]=null 且 [includeAll]=false → 仅根收藏；
  /// [authorId] 非空时叠加作者过滤；[includeAll]=true → 根+全部子集。
  Future<List<OnlineFavoriteEntry>> listFavorites(
    GallerySourceId source, {
    String? collectionId,
    bool includeAll = false,
    int? authorId,
  }) async {
    final where = StringBuffer('source = ?');
    final args = <Object>[source.key];
    if (!includeAll) {
      if (collectionId == null) {
        where.write(' AND collection_id IS NULL');
      } else {
        where.write(' AND collection_id = ?');
        args.add(collectionId);
      }
    }
    if (authorId != null) {
      where.write(' AND author_id = ?');
      args.add(authorId);
    }
    final rows = await (await _db()).query(
      'online_favorites',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'saved_at DESC',
    );
    return [
      for (final row in rows)
        OnlineFavoriteEntry(
          item: _restoreFavoriteItem(row),
          collectionId: row['collection_id']?.toString(),
          savedAt: DateTime.fromMillisecondsSinceEpoch(
            (row['saved_at'] as num).toInt(),
          ),
        ),
    ];
  }

  GalleryItem _restoreFavoriteItem(Map<String, Object?> row) {
    final item = GalleryItem.fromSnapshotJson(
      Map<String, dynamic>.from(jsonDecode(row['snapshot']! as String) as Map),
    );
    if (row['source'] == GallerySourceId.aiTag.key &&
        item.sourceId == GallerySourceId.aiTag) {
      final cover = item.cover;
      for (final url in {
        cover.previewUrl,
        cover.displayUrl,
        cover.downloadUrl,
      }) {
        registerAiTagImageHost(url);
      }
    }
    return item;
  }

  /// 按作者聚合当前源收藏：作者 → 作品数（用于作者区展示）
  Future<Map<int, (String name, int count)>> authorCounts(
    GallerySourceId source,
  ) async {
    final rows = await (await _db()).rawQuery(
      'SELECT author_id, author_name, COUNT(*) AS n FROM online_favorites '
      'WHERE source = ? AND author_id > 0 GROUP BY author_id, author_name '
      'ORDER BY n DESC',
      [source.key],
    );
    return {
      for (final row in rows)
        (row['author_id'] as num).toInt(): (
          row['author_name']?.toString() ?? '',
          (row['n'] as num).toInt(),
        ),
    };
  }

  // ============ 作者收藏 ============

  /// 显式取消作者收藏，返回是否实际删除
  Future<bool> removeAuthor(GallerySourceId source, int authorId) async {
    final removed = await (await _db()).delete(
      'online_favorite_authors',
      where: 'source = ? AND author_id = ?',
      whereArgs: [source.key, authorId],
    );
    return removed > 0;
  }

  /// 切换作者收藏态，返回切换后是否已收藏
  Future<bool> toggleAuthor(
    GallerySourceId source,
    int authorId,
    String authorName,
  ) async {
    final db = await _db();
    final removed = await db.delete(
      'online_favorite_authors',
      where: 'source = ? AND author_id = ?',
      whereArgs: [source.key, authorId],
    );
    if (removed > 0) return false;
    await db.insert('online_favorite_authors', {
      'source': source.key,
      'author_id': authorId,
      'author_name': authorName,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    });
    return true;
  }

  Future<bool> isAuthorFavorite(GallerySourceId source, int authorId) async {
    final rows = await (await _db()).query(
      'online_favorite_authors',
      columns: ['author_id'],
      where: 'source = ? AND author_id = ?',
      whereArgs: [source.key, authorId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<OnlineFavoriteAuthor>> listAuthors(GallerySourceId source) async {
    final rows = await (await _db()).query(
      'online_favorite_authors',
      where: 'source = ?',
      whereArgs: [source.key],
      orderBy: 'saved_at DESC',
    );
    return [
      for (final row in rows)
        OnlineFavoriteAuthor(
          source: source,
          authorId: (row['author_id'] as num).toInt(),
          authorName: row['author_name']?.toString() ?? '',
          savedAt: DateTime.fromMillisecondsSinceEpoch(
            (row['saved_at'] as num).toInt(),
          ),
        ),
    ];
  }

  Future<void> clearAll() async {
    final db = await _db();
    await db.delete('online_favorites');
    await db.delete('online_collections');
    await db.delete('online_favorite_authors');
  }

  /// 关闭连接（测试清理用；生产进程随生命周期保活）
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
