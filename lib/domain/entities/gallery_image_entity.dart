import '../../data/models/gallery/local_image_record.dart' show MetadataStatus;
import '../../data/models/gallery/nai_image_metadata.dart';
import '../../core/database/datasources/gallery_data_source.dart';

/// 画廊图片领域实体
///
/// 这是业务逻辑层使用的统一模型，不依赖具体的数据层实现。
/// 它整合了来自不同数据源的信息：
/// - 数据库记录 ([GalleryImageRecord])
/// - Hive 缓存 ([LocalImageRecord])
/// - 元数据 ([NaiImageMetadata])
class GalleryImageEntity {
  final int? id;
  final String filePath;
  final String fileName;
  final int fileSize;
  final int? width;
  final int? height;
  final double? aspectRatio;
  final DateTime modifiedAt;
  final DateTime createdAt;
  final DateTime indexedAt;
  final String? resolutionKey;
  final MetadataStatus metadataStatus;
  final bool isFavorite;
  final bool isDeleted;

  // 元数据
  final NaiImageMetadata? metadata;

  // 标签
  final List<String> tags;

  const GalleryImageEntity({
    this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    this.width,
    this.height,
    this.aspectRatio,
    required this.modifiedAt,
    required this.createdAt,
    required this.indexedAt,
    this.resolutionKey,
    this.metadataStatus = MetadataStatus.none,
    this.isFavorite = false,
    this.isDeleted = false,
    this.metadata,
    this.tags = const [],
  });

  /// 是否有有效元数据
  bool get hasMetadata => metadata != null && metadata!.hasData;

  /// 获取提示词
  String? get prompt => metadata?.prompt;

  /// 获取负面提示词
  String? get negativePrompt => metadata?.negativePrompt;

  /// 获取种子
  int? get seed => metadata?.seed;

  /// 获取采样器
  String? get sampler => metadata?.sampler;

  /// 获取步数
  int? get steps => metadata?.steps;

  /// 获取 CFG Scale
  double? get scale => metadata?.scale;

  /// 获取模型
  String? get model => metadata?.model;

  /// 获取分辨率字符串
  String get resolution => '${width ?? '?'}×${height ?? '?'}';

  /// 从数据库记录创建
  factory GalleryImageEntity.fromRecord(
    GalleryImageRecord record, {
    NaiImageMetadata? metadata,
    List<String> tags = const [],
  }) {
    return GalleryImageEntity(
      id: record.id,
      filePath: record.filePath,
      fileName: record.fileName,
      fileSize: record.fileSize,
      width: record.width,
      height: record.height,
      aspectRatio: record.aspectRatio,
      modifiedAt: record.modifiedAt,
      createdAt: record.createdAt,
      indexedAt: record.indexedAt,
      resolutionKey: record.resolutionKey,
      metadataStatus: record.metadataStatus,
      isFavorite: record.isFavorite,
      isDeleted: record.isDeleted,
      metadata: metadata,
      tags: tags,
    );
  }

  /// 转换为数据库记录
  GalleryImageRecord toRecord() {
    return GalleryImageRecord(
      id: id,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      width: width,
      height: height,
      aspectRatio: aspectRatio,
      modifiedAt: modifiedAt,
      createdAt: createdAt,
      indexedAt: indexedAt,
      dateYmd:
          modifiedAt.year * 10000 + modifiedAt.month * 100 + modifiedAt.day,
      resolutionKey: resolutionKey,
      metadataStatus: metadataStatus,
      isFavorite: isFavorite,
      isDeleted: isDeleted,
    );
  }

  GalleryImageEntity copyWith({
    int? id,
    String? filePath,
    String? fileName,
    int? fileSize,
    int? width,
    int? height,
    double? aspectRatio,
    DateTime? modifiedAt,
    DateTime? createdAt,
    DateTime? indexedAt,
    String? resolutionKey,
    MetadataStatus? metadataStatus,
    bool? isFavorite,
    bool? isDeleted,
    NaiImageMetadata? metadata,
    List<String>? tags,
    bool clearMetadata = false,
  }) {
    return GalleryImageEntity(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      createdAt: createdAt ?? this.createdAt,
      indexedAt: indexedAt ?? this.indexedAt,
      resolutionKey: resolutionKey ?? this.resolutionKey,
      metadataStatus: metadataStatus ?? this.metadataStatus,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GalleryImageEntity &&
        other.id == id &&
        other.filePath == filePath;
  }

  @override
  int get hashCode => Object.hash(id, filePath);

  @override
  String toString() {
    return 'GalleryImageEntity(id=$id, path=$filePath, name=$fileName)';
  }
}

/// 画廊图片列表结果
class GalleryImageListResult {
  final List<GalleryImageEntity> images;
  final int totalCount;
  final int offset;
  final int limit;
  final bool hasMore;

  const GalleryImageListResult({
    required this.images,
    required this.totalCount,
    required this.offset,
    required this.limit,
    this.hasMore = false,
  });

  GalleryImageListResult copyWith({
    List<GalleryImageEntity>? images,
    int? totalCount,
    int? offset,
    int? limit,
    bool? hasMore,
  }) {
    return GalleryImageListResult(
      images: images ?? this.images,
      totalCount: totalCount ?? this.totalCount,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// 元数据过滤条件
class MetadataFilterCriteria {
  final String? model;
  final String? sampler;
  final int? minSteps;
  final int? maxSteps;
  final double? minCfg;
  final double? maxCfg;
  final String? resolution;
  final int? seed;

  const MetadataFilterCriteria({
    this.model,
    this.sampler,
    this.minSteps,
    this.maxSteps,
    this.minCfg,
    this.maxCfg,
    this.resolution,
    this.seed,
  });

  bool get hasFilters =>
      model != null ||
      sampler != null ||
      minSteps != null ||
      maxSteps != null ||
      minCfg != null ||
      maxCfg != null ||
      resolution != null ||
      seed != null;

  bool matches(NaiImageMetadata metadata) {
    if (model != null && metadata.model != model) return false;
    if (sampler != null && metadata.sampler != sampler) return false;
    if (minSteps != null && (metadata.steps ?? 0) < minSteps!) return false;
    if (maxSteps != null && (metadata.steps ?? 0) > maxSteps!) return false;
    if (minCfg != null && (metadata.scale ?? 0) < minCfg!) return false;
    if (maxCfg != null && (metadata.scale ?? 0) > maxCfg!) return false;
    if (resolution != null) {
      final res = '${metadata.width}×${metadata.height}';
      if (res != resolution) return false;
    }
    if (seed != null && metadata.seed != seed) return false;
    return true;
  }
}
