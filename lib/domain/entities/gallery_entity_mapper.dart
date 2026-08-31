import '../../core/database/datasources/gallery_data_source.dart';
import '../../data/models/gallery/local_image_record.dart';
import '../../data/models/gallery/nai_image_metadata.dart';
import 'gallery_image_entity.dart';

/// 画廊实体映射器
///
/// 负责在不同层的数据模型之间进行转换：
/// - 数据库层 (GalleryImageRecord)
/// - 缓存层 (LocalImageRecord)
/// - 领域层 (GalleryImageEntity)
class GalleryEntityMapper {
  const GalleryEntityMapper._();

  // ============================================================
  // GalleryImageRecord <-> GalleryImageEntity
  // ============================================================

  /// 从数据库记录转换为领域实体
  static GalleryImageEntity fromRecord(
    GalleryImageRecord record, {
    NaiImageMetadata? metadata,
    List<String> tags = const [],
  }) {
    return GalleryImageEntity.fromRecord(
      record,
      metadata: metadata,
      tags: tags,
    );
  }

  /// 从领域实体转换为数据库记录
  static GalleryImageRecord toRecord(GalleryImageEntity entity) {
    return entity.toRecord();
  }

  /// 批量转换数据库记录为领域实体
  static List<GalleryImageEntity> fromRecords(
    List<GalleryImageRecord> records, {
    Map<int, NaiImageMetadata>? metadataMap,
    Map<int, List<String>>? tagsMap,
  }) {
    return records.map((record) {
      final metadata = record.id != null ? (metadataMap?[record.id!]) : null;
      final tags = (record.id != null ? (tagsMap?[record.id!]) : null) ?? [];
      return fromRecord(record, metadata: metadata, tags: tags);
    }).toList();
  }

  // ============================================================
  // LocalImageRecord <-> GalleryImageEntity
  // ============================================================

  /// 从 Hive 缓存记录转换为领域实体
  static GalleryImageEntity fromLocalRecord(LocalImageRecord record) {
    return GalleryImageEntity(
      filePath: record.path,
      fileName: record.path.split('\\').last.split('/').last,
      fileSize: record.size,
      modifiedAt: record.modifiedAt,
      createdAt: record.modifiedAt,
      indexedAt: record.modifiedAt,
      metadataStatus: record.metadataStatus,
      isFavorite: record.isFavorite,
      metadata: record.metadata,
      tags: record.tags,
    );
  }

  /// 从领域实体转换为 Hive 缓存记录
  static LocalImageRecord toLocalRecord(GalleryImageEntity entity) {
    return LocalImageRecord(
      path: entity.filePath,
      size: entity.fileSize,
      modifiedAt: entity.modifiedAt,
      metadata: entity.metadata,
      metadataStatus: entity.metadataStatus,
      isFavorite: entity.isFavorite,
      tags: entity.tags,
    );
  }

  /// 批量转换 Hive 记录为领域实体
  static List<GalleryImageEntity> fromLocalRecords(
    List<LocalImageRecord> records,
  ) {
    return records.map(fromLocalRecord).toList();
  }

  // ============================================================
  // GalleryImageRecord <-> LocalImageRecord
  // ============================================================

  /// 从数据库记录转换为 Hive 缓存记录
  static LocalImageRecord recordToLocalRecord(GalleryImageRecord record) {
    return LocalImageRecord(
      path: record.filePath,
      size: record.fileSize,
      modifiedAt: record.modifiedAt,
      metadataStatus: record.metadataStatus,
      isFavorite: record.isFavorite,
    );
  }

  /// 从 Hive 缓存记录转换为数据库记录（需要补充信息）
  static GalleryImageRecord localRecordToRecord(
    LocalImageRecord local, {
    int? id,
    DateTime? createdAt,
    DateTime? indexedAt,
  }) {
    final fileName = local.path.split('\\').last.split('/').last;
    return GalleryImageRecord(
      id: id,
      filePath: local.path,
      fileName: fileName,
      fileSize: local.size,
      modifiedAt: local.modifiedAt,
      createdAt: createdAt ?? local.modifiedAt,
      indexedAt: indexedAt ?? DateTime.now(),
      dateYmd:
          local.modifiedAt.year * 10000 +
          local.modifiedAt.month * 100 +
          local.modifiedAt.day,
      metadataStatus: local.metadataStatus,
      isFavorite: local.isFavorite,
    );
  }

  // ============================================================
  // 批量转换工具
  // ============================================================

  /// 批量转换并合并元数据
  static Future<List<GalleryImageEntity>> enrichEntities(
    List<GalleryImageRecord> records,
    Future<NaiImageMetadata?> Function(String path) metadataLoader,
  ) async {
    final entities = <GalleryImageEntity>[];

    for (final record in records) {
      NaiImageMetadata? metadata;
      if (record.metadataStatus == MetadataStatus.success) {
        metadata = await metadataLoader(record.filePath);
      }

      entities.add(fromRecord(record, metadata: metadata));
    }

    return entities;
  }

  /// 提取文件路径列表
  static List<String> extractPaths(List<GalleryImageEntity> entities) {
    return entities.map((e) => e.filePath).toList();
  }

  /// 按 ID 分组
  static Map<int, GalleryImageEntity> mapById(
    List<GalleryImageEntity> entities,
  ) {
    return {
      for (final entity in entities)
        if (entity.id != null) entity.id!: entity,
    };
  }

  /// 按文件路径分组
  static Map<String, GalleryImageEntity> mapByPath(
    List<GalleryImageEntity> entities,
  ) {
    return {for (final entity in entities) entity.filePath: entity};
  }

  /// 过滤有元数据的实体
  static List<GalleryImageEntity> withMetadata(
    List<GalleryImageEntity> entities,
  ) {
    return entities.where((e) => e.hasMetadata).toList();
  }

  /// 过滤无元数据的实体
  static List<GalleryImageEntity> withoutMetadata(
    List<GalleryImageEntity> entities,
  ) {
    return entities.where((e) => !e.hasMetadata).toList();
  }

  /// 过滤收藏的实体
  static List<GalleryImageEntity> favorites(List<GalleryImageEntity> entities) {
    return entities.where((e) => e.isFavorite).toList();
  }
}
