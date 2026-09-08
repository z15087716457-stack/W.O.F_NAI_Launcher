/// 收藏集列表条目（含成员计数）
///
/// 收藏集只存「图 ID ↔ 收藏集」的链接关系，不复制文件。
/// 层级字段：[parentId] 指向父文件夹（null=收藏根级平铺）；
/// [isFolder] 为纯组织节点，不参与成员关系，image_count 为
/// 子孙收藏集成员的去重并集计数。
class GalleryCollectionInfo {
  final String id;
  final String name;
  final int imageCount;
  final int sortOrder;
  final DateTime createdAt;
  final String? parentId;
  final bool isFolder;

  const GalleryCollectionInfo({
    required this.id,
    required this.name,
    this.imageCount = 0,
    this.sortOrder = 0,
    required this.createdAt,
    this.parentId,
    this.isFolder = false,
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
      parentId: row['parent_id'] as String?,
      isFolder: (row['is_folder'] as num?)?.toInt() == 1,
    );
  }
}
