import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_collection.freezed.dart';
part 'image_collection.g.dart';

/// 图片集合模型
@freezed
class ImageCollection with _$ImageCollection {
  const factory ImageCollection({
    required String id, // 集合ID
    required String name, // 集合名称
    String? description, // 集合描述
    @Default([]) List<String> imagePaths, // 图片路径列表（旧 Hive 数据迁移用；DB 模式恒空）
    @Default(0) int imageCount, // 图片数量（DB 链接式计数；文件夹为子孙并集去重计数）
    required DateTime createdAt, // 创建时间
    String? parentId, // 父文件夹ID（null=收藏根级平铺）
    @Default(false) bool isFolder, // 是否为收藏文件夹（纯组织节点，不装图）
  }) = _ImageCollection;

  const ImageCollection._();

  factory ImageCollection.fromJson(Map<String, dynamic> json) =>
      _$ImageCollectionFromJson(json);

  /// 集合是否为空
  bool get isEmpty => imageCount == 0;

  /// 集合是否非空
  bool get isNotEmpty => imageCount > 0;
}
