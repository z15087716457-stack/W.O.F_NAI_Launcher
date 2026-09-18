import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/pill_roll_engine.dart';

part 'prompt_block.freezed.dart';
part 'prompt_block.g.dart';

/// 可复用的全局 Prompt 块。
///
/// [content] 是完整纯文本，创建和更新时不得自动拆分、格式化或去重。
@freezed
class PromptBlock with _$PromptBlock {
  const PromptBlock._();

  const factory PromptBlock({
    /// 稳定唯一标识。
    required String id,

    /// 仅用于界面显示的标题。
    required String title,

    /// 供 Prompt 展开的完整纯文本正文。
    required String content,

    /// 显式原子列表（FEAT-79）：非 null 时随机池/顺序幕/注入池抽取
    /// 直接按它切，原子内逗号自由；null = 旧块或纯文本新建，
    /// 回退顶层逗号切分（见 [atomsOrSplit]）。保存时与 [content]
    /// 保持 `atoms.join(', ')` 同步，插入/搜索/预览全部只读 content。
    @JsonKey(includeIfNull: false) List<String>? atoms,

    /// 所属文件夹；null 表示根目录。
    String? folderId,

    /// 稳定保存的显示颜色，例如 #FF607D8B。
    @Default('#FF607D8B') String color,

    /// 自定义图标名（预设表键，见 prompt_block_icons.dart）；null 用默认图标。
    @JsonKey(includeIfNull: false) String? iconName,

    /// 预览图路径（应用文档目录 prompt_block_thumbnails/ 内的 PNG）；null 无图。
    @JsonKey(includeIfNull: false) String? thumbnail,

    /// 预览图水平偏移（-1.0 ~ 1.0），与词库条目同坐标系。
    @Default(0.0) double thumbnailOffsetX,

    /// 预览图垂直偏移（-1.0 ~ 1.0）。
    @Default(0.0) double thumbnailOffsetY,

    /// 预览图缩放比例（1.0 ~ 3.0）。
    @Default(1.0) double thumbnailScale,

    /// 成功插入提示词的次数（点击/拖拽同一汇点计数）。
    @Default(0) int useCount,

    /// 是否加入收藏。
    @Default(false) bool isFavorite,

    /// 同一文件夹内的用户排序值。
    @Default(0) int sortOrder,

    /// 创建时间。
    required DateTime createdAt,

    /// 更新时间。
    required DateTime updatedAt,

    /// 导入来源文件的绝对路径；手动创建的块为 null。
    @JsonKey(includeIfNull: false) String? sourcePath,

    /// 导入来源文件内容在读取时刻的 SHA-256 十六进制摘要。
    @JsonKey(includeIfNull: false) String? sourceHash,

    /// 上次从来源文件读取内容的时间。
    @JsonKey(includeIfNull: false) DateTime? importedAt,
  }) = _PromptBlock;

  factory PromptBlock.fromJson(Map<String, dynamic> json) =>
      _$PromptBlockFromJson(json);

  /// 创建新块。
  ///
  /// 注意：标题会去除首尾空白，正文 [content] 原样保留。
  factory PromptBlock.create({
    required String title,
    required String content,
    String? folderId,
    String color = '#FF607D8B',
    String? iconName,
    String? thumbnail,
    double thumbnailOffsetX = 0.0,
    double thumbnailOffsetY = 0.0,
    double thumbnailScale = 1.0,
    int useCount = 0,
    bool isFavorite = false,
    int sortOrder = 0,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sourcePath,
    String? sourceHash,
    DateTime? importedAt,
    List<String>? atoms,
  }) {
    final created = createdAt ?? DateTime.now();
    return PromptBlock(
      atoms: atoms,
      id: id ?? const Uuid().v4(),
      title: title.trim(),
      content: content,
      folderId: folderId,
      color: color,
      iconName: iconName,
      thumbnail: thumbnail,
      thumbnailOffsetX: thumbnailOffsetX,
      thumbnailOffsetY: thumbnailOffsetY,
      thumbnailScale: thumbnailScale,
      useCount: useCount,
      isFavorite: isFavorite,
      sortOrder: sortOrder,
      createdAt: created,
      updatedAt: updatedAt ?? created,
      sourcePath: sourcePath,
      sourceHash: sourceHash,
      importedAt: importedAt,
    );
  }

  /// 用于空标题块的界面兜底名称。
  String get displayTitle => title.isNotEmpty ? title : '未命名块';

  /// 内容预览（截取前 100 个字符），供补全建议与选择器列表展示。
  String get contentPreview {
    if (content.length > 100) {
      return '${content.substring(0, 100)}...';
    }
    return content;
  }

  /// 是否已挂预览图。
  bool get hasThumbnail => thumbnail != null && thumbnail!.isNotEmpty;

  /// 抽取用原子列表（FEAT-79）：显式 [atoms] 非 null 时原样返回
  /// （含空列表=无原子，不再 fallback）；null 回退顶层逗号切分——
  /// 随机池/顺序幕/注入池统一从这取原子集合。
  List<String> get atomsOrSplit =>
      atoms ?? PillRollEngine.splitTopLevelAtoms(content);

  /// 返回更新时间已刷新的副本，不改变其他字段。
  PromptBlock touched({DateTime? at}) =>
      copyWith(updatedAt: at ?? DateTime.now());
}

/// Prompt 块列表操作。
extension PromptBlockListExtension on List<PromptBlock> {
  /// 获取指定文件夹的直属块，并按用户顺序排列。
  List<PromptBlock> childrenOf(String? folderId) {
    final result = where((block) => block.folderId == folderId).toList();
    result.sort(_comparePromptBlocks);
    return result;
  }

  /// 按文件夹、排序值和稳定 ID 排列，避免依赖 Hive 枚举顺序。
  List<PromptBlock> sortedByFolderAndOrder() {
    final result = [...this];
    result.sort(_comparePromptBlocks);
    return result;
  }
}

int _comparePromptBlocks(PromptBlock a, PromptBlock b) {
  final folderComparison = _compareNullableStrings(a.folderId, b.folderId);
  if (folderComparison != 0) return folderComparison;

  final orderComparison = a.sortOrder.compareTo(b.sortOrder);
  if (orderComparison != 0) return orderComparison;
  return a.id.compareTo(b.id);
}

int _compareNullableStrings(String? a, String? b) {
  if (a == b) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  return a.compareTo(b);
}
