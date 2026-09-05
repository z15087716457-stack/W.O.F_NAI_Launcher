import 'prompt_block.dart';

/// 块库内容区的排序字段。
enum PromptBlockSortField {
  /// 默认：文件夹视图按文件夹树序（块用用户手动排序），全部视图按名称。
  custom,

  /// 按更新时间。
  updated,

  /// 按标题（不区分大小写）。
  title,

  /// 按颜色值（同色块聚在一起）。
  color,

  /// 按图标名（无图标块排最前，同图标块聚在一起）。
  icon;

  /// SharedPreferences 稳定存储值。
  String get storageValue => name;

  /// 是否用户自定义排列以外的排序（此时手动拖拽重排无意义）。
  bool get overridesManualOrder => this != PromptBlockSortField.custom;

  static PromptBlockSortField? fromStorage(String? value) {
    if (value == null) return null;
    for (final field in PromptBlockSortField.values) {
      if (field.name == value) return field;
    }
    return null;
  }
}

/// 按字段比较两个块。
///
/// 回退链：主键 → 文件夹树序（[folderOrder]，缺失的文件夹排最后）→
/// 标题（不区分大小写）→ ID，保证结果稳定；同色/同图标簇内来自同一
/// 文件夹的块连在一起，文件夹之间按用户整理的树序排列。
int comparePromptBlocksBy(
  PromptBlockSortField field,
  PromptBlock a,
  PromptBlock b, {
  Map<String?, int> folderOrder = const {},
}) {
  if (field == PromptBlockSortField.custom) return 0;
  final primary = switch (field) {
    PromptBlockSortField.custom => 0,
    PromptBlockSortField.updated => a.updatedAt.compareTo(b.updatedAt),
    PromptBlockSortField.title => a.title
        .toLowerCase()
        .compareTo(b.title.toLowerCase()),
    PromptBlockSortField.color => a.color.compareTo(b.color),
    PromptBlockSortField.icon => (a.iconName ?? '').compareTo(
      b.iconName ?? '',
    ),
  };
  if (primary != 0) return primary;

  final folderComparison = _compareFolderOrder(
    a.folderId,
    b.folderId,
    folderOrder,
  );
  if (folderComparison != 0) return folderComparison;

  final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  if (byTitle != 0) return byTitle;
  return a.id.compareTo(b.id);
}

int _compareFolderOrder(
  String? folderIdA,
  String? folderIdB,
  Map<String?, int> folderOrder,
) {
  if (folderIdA == folderIdB) return 0;
  final orderA = folderOrder[folderIdA] ?? _kUnknownFolderOrder;
  final orderB = folderOrder[folderIdB] ?? _kUnknownFolderOrder;
  return orderA.compareTo(orderB);
}

const int _kUnknownFolderOrder = 1 << 30;

/// 排序块列表副本；[descending] 为真时反转结果（回退链已保证同键顺序
/// 确定，反转后仍稳定）。custom 直接原样返回列表副本。
List<PromptBlock> sortPromptBlocks(
  List<PromptBlock> blocks,
  PromptBlockSortField field, {
  bool descending = false,
  Map<String?, int> folderOrder = const {},
}) {
  if (!field.overridesManualOrder) return blocks;
  final sorted = [...blocks]..sort(
    (a, b) => comparePromptBlocksBy(field, a, b, folderOrder: folderOrder),
  );
  return descending ? sorted.reversed.toList() : sorted;
}
