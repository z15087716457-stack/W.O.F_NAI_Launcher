/// 收藏集列表条目（含成员计数）
///
/// 收藏集只存「图 ID ↔ 收藏集」的链接关系，不复制文件。
class GalleryCollectionInfo {
  final String id;
  final String name;
  final int imageCount;
  final int sortOrder;
  final DateTime createdAt;

  const GalleryCollectionInfo({
    required this.id,
    required this.name,
    this.imageCount = 0,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory GalleryCollectionInfo.fromMap(Map<String, dynamic> row) {
    return GalleryCollectionInfo(
      id: row['id'] as String,
      name: row['name'] as String,
      imageCount: (row['image_count'] as num?)?.toInt() ?? 0,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
