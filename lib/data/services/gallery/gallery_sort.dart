import 'package:flutter/foundation.dart';

/// 画廊排序字段（白名单）
///
/// 字段→SQL 列映射只允许走 [GallerySort.sqlColumn] 的白名单 switch，
/// 严禁把用户输入直接拼进 SQL。
enum GallerySortField {
  /// 修改时间
  modifiedAt,

  /// 创建时间（SQL 侧 `i.created_at`）
  createdAt,

  /// 文件名
  fileName,

  /// 文件大小
  fileSize,

  /// 图像尺寸（按面积 width×height，SQL 侧 `i.width * i.height`）
  imageDimensions,
}

/// 排序方向
enum GallerySortDirection { ascending, descending }

/// 画廊排序规格（纯数据 + 纯比较逻辑，便于单元测试）
@immutable
class GallerySort {
  final GallerySortField field;
  final GallerySortDirection direction;

  const GallerySort({required this.field, required this.direction});

  /// 默认排序：修改时间 新→旧
  const GallerySort.modifiedAtDesc()
    : field = GallerySortField.modifiedAt,
      direction = GallerySortDirection.descending;

  /// 各字段的合理默认方向：时间/大小/尺寸默认降序（新/大在前），名称默认升序。
  /// 切字段时按此复位方向（工具条两段式排序的记忆方向）。
  static GallerySortDirection defaultDirectionFor(GallerySortField field) {
    return switch (field) {
      GallerySortField.fileName => GallerySortDirection.ascending,
      GallerySortField.modifiedAt ||
      GallerySortField.createdAt ||
      GallerySortField.fileSize ||
      GallerySortField.imageDimensions => GallerySortDirection.descending,
    };
  }

  /// 用指定字段 + 该字段默认方向构造排序。
  GallerySort.withDefaultDirection(GallerySortField field)
    : field = field,
      direction = defaultDirectionFor(field);

  /// SQL 排序列白名单映射。
  ///
  /// 只接受 [GallerySortField] 枚举值，未识别值一律回退 `modified_at`。
  /// 返回的是映射 token（如 `image_area`），具体 SQL 表达式由查询层的
  /// 二次白名单（advancedSearch 的 sortColumn switch）展开，杜绝拼接。
  String get sqlColumn => switch (field) {
    GallerySortField.modifiedAt => 'modified_at',
    GallerySortField.createdAt => 'created_at',
    GallerySortField.fileName => 'file_name',
    GallerySortField.fileSize => 'file_size',
    GallerySortField.imageDimensions => 'image_area',
  };

  /// 排序缓存键（过滤缓存需要感知排序变化）
  String get cacheKey => '${field.name}:${direction.name}';

  int _withDirection(int result) =>
      direction == GallerySortDirection.ascending ? result : -result;

  /// 纯比较器：主字段按排序方向，主字段相同以文件名（不区分大小写）升序
  /// 兜底，保证相同主字段时的顺序可复现（List.sort 不稳定）。
  ///
  /// [createdAtA]/[createdAtB]：创建时间（缺省按最小时间处理，不影响旧调用方）。
  /// [imageAreaA]/[imageAreaB]：图像面积 width×height（缺省按 0 处理）。
  int compareFiles({
    required DateTime modifiedAtA,
    required DateTime modifiedAtB,
    required int fileSizeA,
    required int fileSizeB,
    required String fileNameA,
    required String fileNameB,
    DateTime? createdAtA,
    DateTime? createdAtB,
    int? imageAreaA,
    int? imageAreaB,
  }) {
    final primary = switch (field) {
      GallerySortField.modifiedAt => modifiedAtA.compareTo(modifiedAtB),
      GallerySortField.createdAt => (createdAtA ?? DateTime(0)).compareTo(
        createdAtB ?? DateTime(0),
      ),
      GallerySortField.fileName => fileNameA.toLowerCase().compareTo(
        fileNameB.toLowerCase(),
      ),
      GallerySortField.fileSize => fileSizeA.compareTo(fileSizeB),
      GallerySortField.imageDimensions => (imageAreaA ?? 0).compareTo(
        imageAreaB ?? 0,
      ),
    };
    if (primary != 0) return _withDirection(primary);

    final tie = fileNameA.toLowerCase().compareTo(fileNameB.toLowerCase());
    return tie;
  }

  @override
  bool operator ==(Object other) =>
      other is GallerySort &&
      other.field == field &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(field, direction);

  @override
  String toString() => 'GallerySort(${field.name}, ${direction.name})';
}
