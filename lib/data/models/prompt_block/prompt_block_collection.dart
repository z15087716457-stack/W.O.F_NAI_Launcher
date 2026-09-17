import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'prompt_block_collection.freezed.dart';
part 'prompt_block_collection.g.dart';

/// Prompt 块收藏集 / 收藏文件夹。
///
/// 与画廊 `ImageCollection` 同构：[isFolder] 为 true 时是纯组织节点
/// （可无限嵌套、不装成员）；为 false 时是收藏集，[blockIds] 保存成员
/// 块 ID 列表（有序，追加在尾部）。收藏集树整体挂在块库侧栏的收藏区，
/// 与 [PromptBlockFolder] 的普通文件夹树互不干扰。
@freezed
class PromptBlockCollection with _$PromptBlockCollection {
  const PromptBlockCollection._();

  const factory PromptBlockCollection({
    /// 稳定唯一标识。
    required String id,

    /// 显示名称。
    required String name,

    /// 父收藏文件夹；null 表示收藏区根级。
    String? parentId,

    /// true = 收藏文件夹（纯组织容器），false = 收藏集。
    @Default(false) bool isFolder,

    /// 同一父级内的用户排序值。
    @Default(0) int sortOrder,

    /// 成员块 ID 列表（仅收藏集使用；有序，新成员追加在尾部）。
    @Default([]) List<String> blockIds,

    /// 创建时间。
    required DateTime createdAt,

    /// 更新时间。
    required DateTime updatedAt,
  }) = _PromptBlockCollection;

  factory PromptBlockCollection.fromJson(Map<String, dynamic> json) =>
      _$PromptBlockCollectionFromJson(json);

  /// 创建新收藏集 / 收藏文件夹。
  factory PromptBlockCollection.create({
    required String name,
    String? parentId,
    bool isFolder = false,
    int sortOrder = 0,
    List<String>? blockIds,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final created = createdAt ?? DateTime.now();
    return PromptBlockCollection(
      id: id ?? const Uuid().v4(),
      name: name.trim(),
      parentId: parentId,
      isFolder: isFolder,
      sortOrder: sortOrder,
      blockIds: blockIds ?? const [],
      createdAt: created,
      updatedAt: updatedAt ?? created,
    );
  }

  /// 是否为收藏区根级直属节点。
  bool get isRoot => parentId == null;

  /// 用于空名称的界面兜底名称。
  String get displayName => name.isNotEmpty ? name : '未命名收藏集';

  /// 收藏集成员数；收藏文件夹恒为 0（成员数由界面侧按子树并集计算）。
  int get blockCount => isFolder ? 0 : blockIds.length;
}

/// Prompt 块收藏集列表操作。
extension PromptBlockCollectionListExtension on List<PromptBlockCollection> {
  /// 获取指定父级的直属子节点（收藏集与收藏文件夹混合），按用户顺序排列。
  List<PromptBlockCollection> childrenOf(String? parentId) {
    final result = where((node) => node.parentId == parentId).toList();
    result.sort(_comparePromptBlockCollections);
    return result;
  }

  /// 获取收藏区根级直属节点。
  List<PromptBlockCollection> get rootNodes => childrenOf(null);

  /// 获取所有后代节点 ID（收藏文件夹的子树；收藏集无后代，返回空集）。
  Set<String> getDescendantIds(String nodeId) {
    final descendants = <String>{};
    final queue = childrenOf(nodeId).map((node) => node.id).toList();

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      if (!descendants.add(currentId)) continue;
      queue.addAll(childrenOf(currentId).map((node) => node.id));
    }

    return descendants;
  }

  /// 判断把 [nodeId] 移到 [newParentId] 下是否会形成循环。
  bool wouldCreateCycle(String nodeId, String? newParentId) {
    if (newParentId == null) return false;
    if (nodeId == newParentId) return true;

    final byId = <String, PromptBlockCollection>{
      for (final node in this) node.id: node,
    };
    final visited = <String>{};
    String? currentId = newParentId;

    while (currentId != null && visited.add(currentId)) {
      if (currentId == nodeId) return true;
      currentId = byId[currentId]?.parentId;
    }

    return false;
  }

  /// 获取从收藏区根级到指定节点的路径。
  List<PromptBlockCollection> getPath(String nodeId) {
    final byId = <String, PromptBlockCollection>{
      for (final node in this) node.id: node,
    };
    final result = <PromptBlockCollection>[];
    final visited = <String>{};
    String? currentId = nodeId;

    while (currentId != null) {
      if (!visited.add(currentId)) {
        throw StateError('收藏集层级包含循环引用: $currentId');
      }
      final node = byId[currentId];
      if (node == null) {
        throw ArgumentError('收藏集不存在: $currentId');
      }
      result.insert(0, node);
      currentId = node.parentId;
    }

    return result;
  }
}

int _comparePromptBlockCollections(
  PromptBlockCollection a,
  PromptBlockCollection b,
) {
  final orderComparison = a.sortOrder.compareTo(b.sortOrder);
  if (orderComparison != 0) return orderComparison;
  return a.id.compareTo(b.id);
}
