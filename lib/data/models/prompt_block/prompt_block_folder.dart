import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'prompt_block_folder.freezed.dart';
part 'prompt_block_folder.g.dart';

/// 全局 Prompt 块库文件夹。
@freezed
class PromptBlockFolder with _$PromptBlockFolder {
  const PromptBlockFolder._();

  const factory PromptBlockFolder({
    /// 稳定唯一标识。
    required String id,

    /// 文件夹名称。
    required String name,

    /// 父文件夹；null 表示根目录。
    String? parentId,

    /// 同一父文件夹内的用户排序值。
    @Default(0) int sortOrder,

    /// 创建时间。
    required DateTime createdAt,

    /// 更新时间。
    required DateTime updatedAt,
  }) = _PromptBlockFolder;

  factory PromptBlockFolder.fromJson(Map<String, dynamic> json) =>
      _$PromptBlockFolderFromJson(json);

  /// 创建新文件夹。
  factory PromptBlockFolder.create({
    required String name,
    String? parentId,
    int sortOrder = 0,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final created = createdAt ?? DateTime.now();
    return PromptBlockFolder(
      id: id ?? const Uuid().v4(),
      name: name.trim(),
      parentId: parentId,
      sortOrder: sortOrder,
      createdAt: created,
      updatedAt: updatedAt ?? created,
    );
  }

  /// 是否为根目录直属文件夹。
  bool get isRoot => parentId == null;

  /// 用于空名称文件夹的界面兜底名称。
  String get displayName => name.isNotEmpty ? name : '未命名文件夹';
}

/// Prompt 块文件夹列表操作。
extension PromptBlockFolderListExtension on List<PromptBlockFolder> {
  /// 获取指定父文件夹的直属子文件夹，并按用户顺序排列。
  List<PromptBlockFolder> childrenOf(String? parentId) {
    final result = where((folder) => folder.parentId == parentId).toList();
    result.sort(_comparePromptBlockFolders);
    return result;
  }

  /// 获取根目录直属文件夹。
  List<PromptBlockFolder> get rootFolders => childrenOf(null);

  /// 获取所有后代文件夹 ID。
  Set<String> getDescendantIds(String folderId) {
    final descendants = <String>{};
    final queue = childrenOf(folderId).map((folder) => folder.id).toList();

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      if (!descendants.add(currentId)) continue;
      queue.addAll(childrenOf(currentId).map((folder) => folder.id));
    }

    return descendants;
  }

  /// 判断把 [folderId] 移到 [newParentId] 是否会形成循环。
  bool wouldCreateCycle(String folderId, String? newParentId) {
    if (newParentId == null) return false;
    if (folderId == newParentId) return true;

    final byId = <String, PromptBlockFolder>{
      for (final folder in this) folder.id: folder,
    };
    final visited = <String>{};
    String? currentId = newParentId;

    while (currentId != null && visited.add(currentId)) {
      if (currentId == folderId) return true;
      currentId = byId[currentId]?.parentId;
    }

    return false;
  }

  /// 获取从根目录到指定文件夹的路径。
  List<PromptBlockFolder> getPath(String folderId) {
    final byId = <String, PromptBlockFolder>{
      for (final folder in this) folder.id: folder,
    };
    final result = <PromptBlockFolder>[];
    final visited = <String>{};
    String? currentId = folderId;

    while (currentId != null) {
      if (!visited.add(currentId)) {
        throw StateError('文件夹层级包含循环引用: $currentId');
      }
      final folder = byId[currentId];
      if (folder == null) {
        throw ArgumentError('文件夹不存在: $currentId');
      }
      result.insert(0, folder);
      currentId = folder.parentId;
    }

    return result;
  }
}

int _comparePromptBlockFolders(PromptBlockFolder a, PromptBlockFolder b) {
  final orderComparison = a.sortOrder.compareTo(b.sortOrder);
  if (orderComparison != 0) return orderComparison;
  return a.id.compareTo(b.id);
}
