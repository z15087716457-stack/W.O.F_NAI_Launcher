import 'package:flutter/widgets.dart';

import '../kit/ui_block_pill.dart';

export '../kit/ui_block_pill.dart' show BlockAppearance;

// 块系统的界面契约。界面只吃这里的数据、只调这里的回调；接线方（lib/presentation/wiring/）
// 从块库 provider / 药丸文档 / 抽取引擎组装数据，把回调接到现有 service。
//
// 覆盖六处界面：
//   1. 块库管理页（[BlocksLibraryPage]）       ← [BlocksLibraryViewData] / [BlocksLibraryActions]
//   2. 生图页块库侧栏（[BlocksDock]）           ← [BlocksDockViewData] / [BlocksDockActions]
//   3. 点开药丸的实例卡 + 抽取规则（[BlockInstanceCard]） ← [BlockInstanceViewData] / [BlockInstanceActions]
//   4. 编辑块对话框（[BlockEditDialog]）        ← [BlockEditData] / [BlockEditActions]
//   5. 选中文字存为块（[BlockSelectionToolbar] + [BlockQuickSave]） ← [BlockQuickSaveData] / [BlockQuickSaveActions]
//   6. 药丸本身（kit/ui_block_pill.dart 的 UiBlockPill，提示词编辑器里直接用）
//
// 时间字段一律本地时间；颜色一律是块 / 标签自己存的颜色（`promptBlockColorFromString` 解析后）。

/// 块的 10 色调色板（与 `prompt_block_colors.dart` 的 `promptBlockColorPalette` 同值、同顺序）。
const blockPalette = <Color>[
  Color(0xFF607D8B),
  Color(0xFFE53935),
  Color(0xFFFB8C00),
  Color(0xFFFDD835),
  Color(0xFF43A047),
  Color(0xFF00ACC1),
  Color(0xFF1E88E5),
  Color(0xFF8E24AA),
  Color(0xFFD81B60),
  Color(0xFF6D4C41),
];

// ───────────────────────────── 块 ─────────────────────────────

/// 块库标签（`PromptBlockTag`）。
@immutable
class BlockTag {
  const BlockTag(this.name, this.color);
  final String name;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is BlockTag && other.name == name && other.color == color;
  @override
  int get hashCode => Object.hash(name, color);
}

/// 块的附带生图参数（`PromptBlockGenerationSettings`）。null 字段 = 不改当前值。
/// [model] / [sampler] / [noiseSchedule] 是存储值，显示名查 [BlockParamCatalog]。
@immutable
class BlockParams {
  const BlockParams({
    this.model,
    this.steps,
    this.scale,
    this.cfgRescale,
    this.sampler,
    this.noiseSchedule,
    this.width,
    this.height,
    this.incompatible,
    this.qualityPreset,
    this.qualityCustomBlockId,
    this.ucPreset,
    this.ucCustomBlockId,
  });

  final String? model;
  final int? steps;
  final double? scale;
  final double? cfgRescale;
  final String? sampler;
  final String? noiseSchedule;
  final int? width;
  final int? height;
  final String? qualityPreset;
  final String? qualityCustomBlockId;
  final int? ucPreset;
  final String? ucCustomBlockId;

  /// 和当前生图模型不兼容时的说明（沿用 `promptBlockLibrary_settingsIncompatible`）；
  /// 非 null 时“应用”按钮不可点，旁边显示这句话。
  final String? incompatible;

  bool get isEmpty =>
      model == null &&
      steps == null &&
      scale == null &&
      cfgRescale == null &&
      sampler == null &&
      noiseSchedule == null &&
      qualityPreset == null &&
      qualityCustomBlockId == null &&
      ucPreset == null &&
      ucCustomBlockId == null;

  BlockParams copyWith({
    String? model,
    int? steps,
    double? scale,
    double? cfgRescale,
    String? sampler,
    String? noiseSchedule,
    String? qualityPreset,
    String? qualityCustomBlockId,
    bool clearQualityCustom = false,
    int? ucPreset,
    String? ucCustomBlockId,
    bool clearUcCustom = false,
  }) => BlockParams(
    model: model ?? this.model,
    steps: steps ?? this.steps,
    scale: scale ?? this.scale,
    cfgRescale: cfgRescale ?? this.cfgRescale,
    sampler: sampler ?? this.sampler,
    noiseSchedule: noiseSchedule ?? this.noiseSchedule,
    qualityPreset: qualityPreset ?? this.qualityPreset,
    qualityCustomBlockId: clearQualityCustom
        ? null
        : qualityCustomBlockId ?? this.qualityCustomBlockId,
    ucPreset: ucPreset ?? this.ucPreset,
    ucCustomBlockId: clearUcCustom
        ? null
        : ucCustomBlockId ?? this.ucCustomBlockId,
    width: width,
    height: height,
  );
}

/// 参数的可选值和显示名：模型名用 `ImageModels.modelDisplayNames`，不写死。
@immutable
class BlockParamCatalog {
  const BlockParamCatalog({
    this.models = const {},
    this.samplers = const {},
    this.noiseSchedules = const {},
    this.customPresets = const {},
    this.customPresetContents = const {},
    this.currentModel,
  });

  /// 存储值 → 显示名，按下拉里的顺序。
  final Map<String, String> models;
  final Map<String, String> samplers;
  final Map<String, String> noiseSchedules;

  /// 可作自定义质量词 / 负面预设的块：id → 显示名。
  final Map<String, String> customPresets;

  /// 同上：id → 正文（预览用）。
  final Map<String, String> customPresetContents;
  final String? currentModel;

  String model(String id) => models[id] ?? id;
  String sampler(String id) => samplers[id] ?? id;
  String noise(String id) => noiseSchedules[id] ?? id;
}

/// 预览图（`thumbnail` + 偏移 / 缩放，坐标系同旧 `ThumbnailDisplay`）。
@immutable
class BlockThumb {
  const BlockThumb(
    this.image, {
    this.offsetX = 0,
    this.offsetY = 0,
    this.scale = 1,
  });
  final ImageProvider image;

  /// −1…1。
  final double offsetX;
  final double offsetY;

  /// 1…3。
  final double scale;

  BlockThumb copyWith({double? offsetX, double? offsetY, double? scale}) =>
      BlockThumb(
        image,
        offsetX: offsetX ?? this.offsetX,
        offsetY: offsetY ?? this.offsetY,
        scale: scale ?? this.scale,
      );
}

/// 导入来源文件的状态（`sourcePath` / `sourceHash` 与磁盘比对）。
enum BlockSourceState { none, synced, changed, missing }

/// 一个块：管理页卡片、侧栏药丸、悬停预览卡、详情栏、实例卡共用。
@immutable
class BlockData {
  const BlockData({
    required this.id,
    required this.title,
    required this.color,
    this.icon,
    this.look = BlockAppearance.classic,
    this.atoms = const [],
    this.negativeAtoms = const [],
    this.params,
    this.tags = const [],
    this.folderId,
    this.folderName,
    this.thumb,
    this.useCount = 0,
    this.favorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.sourcePath,
    this.importedAt,
    this.sourceState = BlockSourceState.none,
    this.reading,
    this.readingNeedsReview = false,
  });

  final String id;

  /// 显示标题（`displayTitle`）。
  final String title;
  final Color color;

  /// 图标键（`iconName`），见 `UiBlockIcon.keys`；null = 默认。
  final String? icon;
  final BlockAppearance look;

  /// 正面原子（`atomsOrSplit`），按顺序。
  final List<String> atoms;

  /// 负面原子；空 = 没有负面。
  final List<String> negativeAtoms;
  final BlockParams? params;
  final List<BlockTag> tags;

  /// 所在文件夹；null = 未分类（根目录）。
  final String? folderId;

  /// 文件夹名（只放最后一级，例如“画风”）。
  final String? folderName;
  final BlockThumb? thumb;
  final int useCount;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 导入来源文件（显示用相对路径即可，例如 `artists/1999.txt`）。
  final String? sourcePath;
  final DateTime? importedAt;
  final BlockSourceState sourceState;

  /// 翻译阅读（`readingTranslationZh`），只在详情里显示。
  final String? reading;

  /// 原文改过、翻译待复核。
  final bool readingNeedsReview;

  /// 项数：正面原子数；只有负面的块（负面词块）算负面原子数。
  int get itemCount => atoms.isEmpty ? negativeAtoms.length : atoms.length;
  bool get hasNegative => negativeAtoms.isNotEmpty;
  bool get hasParams => params != null && !params!.isEmpty;

  /// 插入后发送的正文（`content`）。
  String get content => atoms.join(', ');
}

/// 新建 / 编辑后要写回的内容。
/// [atoms] 为 null 表示“纯文本”模式：原样保存 [text]，不拆原子（`PromptBlock.atoms = null`）。
@immutable
class BlockDraft {
  const BlockDraft({
    this.title = '',
    this.atoms = const [],
    this.text,
    this.negativeAtoms = const [],
    this.color = const Color(0xFF607D8B),
    this.icon,
    this.look = BlockAppearance.classic,
    this.folderId,
    this.tags = const [],
    this.params,
    this.thumb,
    this.thumbToken,
    this.clearThumb = false,
  });

  final String title;
  final List<String>? atoms;
  final String? text;
  final List<String> negativeAtoms;
  final Color color;
  final String? icon;
  final BlockAppearance look;
  final String? folderId;
  final List<BlockTag> tags;
  final BlockParams? params;

  /// 当前预览图（含偏移 / 缩放）。
  final BlockThumb? thumb;

  /// 换过图时，[BlockEditActions.onPickThumbnail] 返回的新图标识（文件路径）；null = 没换图。
  final String? thumbToken;

  /// 用户清除了预览图。
  final bool clearThumb;

  factory BlockDraft.of(BlockData b) => BlockDraft(
    title: b.title,
    atoms: b.atoms,
    negativeAtoms: b.negativeAtoms,
    color: b.color,
    icon: b.icon,
    look: b.look,
    folderId: b.folderId,
    tags: b.tags,
    params: b.params,
    thumb: b.thumb,
  );

  BlockDraft copyWith({
    String? title,
    List<String>? atoms,
    bool plain = false,
    String? text,
    List<String>? negativeAtoms,
    Color? color,
    String? icon,
    bool clearIcon = false,
    BlockAppearance? look,
    String? folderId,
    bool root = false,
    List<BlockTag>? tags,
    BlockParams? params,
    bool clearParams = false,
    BlockThumb? thumb,
    String? thumbToken,
    bool? clearThumb,
  }) => BlockDraft(
    title: title ?? this.title,
    atoms: plain ? null : (atoms ?? this.atoms),
    text: text ?? this.text,
    negativeAtoms: negativeAtoms ?? this.negativeAtoms,
    color: color ?? this.color,
    icon: clearIcon ? null : (icon ?? this.icon),
    look: look ?? this.look,
    folderId: root ? null : (folderId ?? this.folderId),
    tags: tags ?? this.tags,
    params: clearParams ? null : (params ?? this.params),
    thumb: (clearThumb ?? false) ? null : (thumb ?? this.thumb),
    thumbToken: (clearThumb ?? false) ? null : (thumbToken ?? this.thumbToken),
    clearThumb: clearThumb ?? this.clearThumb,
  );
}

/// 详情栏里就地改的一项（只带改了的字段）。
@immutable
class BlockPatch {
  const BlockPatch({
    this.title,
    this.color,
    this.icon,
    this.clearIcon = false,
    this.look,
    this.folderId,
    this.toRoot = false,
    this.tags,
  });
  final String? title;
  final Color? color;
  final String? icon;
  final bool clearIcon;
  final BlockAppearance? look;
  final String? folderId;

  /// 移到根目录（未分类）。
  final bool toRoot;
  final List<BlockTag>? tags;
}

/// 换图回调的结果：新图 + 写回时用的标识。
@immutable
class BlockThumbPick {
  const BlockThumbPick(this.image, this.token);
  final ImageProvider image;
  final String token;
}

// ───────────────────────────── 管理页 ─────────────────────────────

enum BlocksScopeKind {
  all,
  recent,
  favorites,
  collection,
  uncategorized,
  folder,
  tag,
}

/// 左栏选中的范围。
@immutable
class BlocksScope {
  const BlocksScope._(this.kind, [this.id]);
  const BlocksScope.all() : this._(BlocksScopeKind.all);
  const BlocksScope.recent() : this._(BlocksScopeKind.recent);
  const BlocksScope.favorites() : this._(BlocksScopeKind.favorites);
  const BlocksScope.uncategorized() : this._(BlocksScopeKind.uncategorized);
  const BlocksScope.collection(String id)
    : this._(BlocksScopeKind.collection, id);
  const BlocksScope.folder(String id) : this._(BlocksScopeKind.folder, id);
  const BlocksScope.tag(String name) : this._(BlocksScopeKind.tag, name);

  final BlocksScopeKind kind;

  /// 收藏集 / 文件夹 id，或标签名。
  final String? id;

  @override
  bool operator ==(Object other) =>
      other is BlocksScope && other.kind == kind && other.id == id;
  @override
  int get hashCode => Object.hash(kind, id);
}

/// 排序（`PromptBlockSortField`）：自定义顺序 / 最近修改 / 名称 / 颜色 / 图标。
enum BlocksSort { custom, updated, title, color, icon }

/// 卡片墙视图：瀑布流（默认，封面按内容 / 原图比例）、等高网格、列表。
enum BlocksView { masonry, grid, list }

/// 按文件夹分组时的一组：[blocks] 里从 [start] 起的 [count] 个块属于同一个文件夹。
/// [folderId] 为 null 是根目录（未分类）；[path] 是 `A / B / C`。
@immutable
class BlocksGroup {
  const BlocksGroup({
    required this.folderId,
    required this.path,
    required this.start,
    required this.count,
  });
  final String? folderId;
  final String path;
  final int start;
  final int count;
  int get end => start + count;
}

/// 快速筛选（纯前端过滤，可多选）：有预览图 / 含负面 / 附带参数。
enum BlocksQuick { image, negative, params }

/// 文件夹（`PromptBlockFolder`），按树序拍平：子文件夹紧跟在父文件夹后面。
@immutable
class BlocksFolder {
  const BlocksFolder({
    required this.id,
    required this.name,
    required this.count,
    this.parentId,
    this.depth = 0,
    this.hasChildren = false,
    this.expanded = false,
  });
  final String id;
  final String name;

  /// 含子文件夹里的块。
  final int count;
  final String? parentId;
  final int depth;
  final bool hasChildren;
  final bool expanded;
}

/// 收藏集（`PromptBlockCollection`），按树序拍平；[isFolder] 是“收藏文件夹”（只装收藏集）。
@immutable
class BlocksCollection {
  const BlocksCollection({
    required this.id,
    required this.name,
    required this.count,
    this.parentId,
    this.depth = 0,
    this.isFolder = false,
  });
  final String id;
  final String name;
  final int count;
  final String? parentId;
  final int depth;
  final bool isFolder;
}

@immutable
class BlocksTagInfo {
  const BlocksTagInfo(this.tag, this.count);
  final BlockTag tag;
  final int count;
}

@immutable
class BlocksCounts {
  const BlocksCounts({
    this.all = 0,
    this.recent = 0,
    this.favorites = 0,
    this.uncategorized = 0,
  });
  final int all;
  final int recent;
  final int favorites;
  final int uncategorized;
}

@immutable
class BlocksRagStatus {
  const BlocksRagStatus({
    this.enabled = false,
    this.available = false,
    this.searching = false,
    this.tooltip = '',
  });
  final bool enabled, available, searching;
  final String tooltip;
}

@immutable
class BlocksLibraryViewData {
  const BlocksLibraryViewData({
    required this.now,
    this.loading = false,
    this.blocks = const [],
    this.counts = const BlocksCounts(),
    this.folders = const [],
    this.collections = const [],
    this.tags = const [],
    this.scope = const BlocksScope.all(),
    this.query = '',
    this.sort = BlocksSort.updated,
    this.descending = true,
    this.view = BlocksView.masonry,
    this.groupByFolder = false,
    this.groups,
    this.quick = const {},
    this.cardSize = .5,
    this.selectedId,
    this.sidebarOpen = true,
    this.inspectorOpen = true,
    this.catalog = const BlockParamCatalog(),
    this.paletteIds = const {},
    this.rag = const BlocksRagStatus(),
  });

  final DateTime now;

  /// 首次读库中：卡片墙画骨架。
  final bool loading;

  /// 当前范围 + 搜索 + 快速筛选 + 排序之后要显示的块（接线方过滤好）。
  final List<BlockData> blocks;
  final BlocksCounts counts;

  /// 全部文件夹（整棵树拍平，包括收起的子文件夹；左栏自己按 [BlocksFolder.expanded] 隐藏）。
  final List<BlocksFolder> folders;
  final List<BlocksCollection> collections;
  final List<BlocksTagInfo> tags;
  final BlocksScope scope;
  final String query;
  final BlocksSort sort;
  final bool descending;
  final BlocksView view;

  /// 按文件夹分组（顶部开关）：开着时 [groups] 给出分组，排序在各自文件夹内进行。
  final bool groupByFolder;

  /// 分组结果；null = 不分组。[blocks] 已按组排好。
  final List<BlocksGroup>? groups;
  final Set<BlocksQuick> quick;

  /// 卡片大小 0…1（0 = 最小，约 180 宽一列；1 = 最大，约 300）。
  final double cardSize;
  final String? selectedId;
  final bool sidebarOpen;
  final bool inspectorOpen;
  final BlockParamCatalog catalog;

  /// 已经放进积木的块（多选浮条“放进积木”的提示用）。
  final Set<String> paletteIds;
  final BlocksRagStatus rag;

  bool get libraryEmpty => counts.all == 0 && !loading;
  BlockData? get selected =>
      blocks.where((b) => b.id == selectedId).firstOrNull;
}

/// 拖卡片到左栏文件夹 / 收藏集后，用户在弹出的小菜单里选的做法。
enum BlocksDropMode { move, copy }

@immutable
class BlocksLibraryActions {
  const BlocksLibraryActions({
    required this.onScopeChanged,
    required this.onQueryChanged,
    required this.onSortChanged,
    required this.onViewChanged,
    this.onGroupByFolderChanged,
    required this.onQuickChanged,
    required this.onCardSizeChanged,
    required this.onSidebarChanged,
    required this.onInspectorChanged,
    required this.onSelect,
    required this.onInsert,
    required this.onSetFavorite,
    required this.onDuplicate,
    required this.onCopyText,
    required this.onCreate,
    required this.onSave,
    required this.onUpdate,
    required this.onBatchStyle,
    required this.onDelete,
    required this.onDropToFolder,
    required this.onDropToCollection,
    required this.onRemoveFromCollection,
    required this.onReorder,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onAddToPalette,
    required this.onExport,
    required this.onApplyParams,
    required this.onPickThumbnail,
    required this.onCaptureParams,
    required this.onCreateFolder,
    required this.onRenameFolder,
    required this.onDeleteFolder,
    required this.onToggleFolder,
    required this.onMoveFolder,
    required this.onReorderFolder,
    required this.onCreateCollection,
    required this.onRenameCollection,
    required this.onDeleteCollection,
    required this.onRenameTag,
    required this.onSetTagColor,
    required this.onDeleteTag,
    required this.onImportTxt,
    required this.onImportFolder,
    required this.onImportCuration,
    required this.onExportBackup,
    required this.onImportBackup,
  });

  /// 切左栏范围。选中的文件夹 / 收藏集被删时由接线方切回“全部”/“收藏”。
  /// 搜索中切范围：接线方先清空搜索再切（旧侧栏的隐藏行为）。
  final ValueChanged<BlocksScope> onScopeChanged;
  final ValueChanged<String> onQueryChanged;
  final void Function(BlocksSort sort, {required bool descending})
  onSortChanged;
  final ValueChanged<BlocksView> onViewChanged;

  /// 顶部“按文件夹分组”开关。
  final ValueChanged<bool>? onGroupByFolderChanged;
  final ValueChanged<Set<BlocksQuick>> onQuickChanged;

  /// 拖动结束才回调（拖动中界面自己跟手）。
  final ValueChanged<double> onCardSizeChanged;
  final ValueChanged<bool> onSidebarChanged;
  final ValueChanged<bool> onInspectorChanged;
  final ValueChanged<String?> onSelect;

  /// 依次插入到生图页当前提示词（`insertPromptBlockBundle` + `incrementUseCount`）。
  final ValueChanged<List<String>> onInsert;
  final void Function(List<String> ids, bool favorite) onSetFavorite;

  /// 复制一份（同文件夹，标题加“副本”）。
  final ValueChanged<String> onDuplicate;

  /// 把块正文复制到剪贴板（接线方提示“已复制”）。
  final ValueChanged<String> onCopyText;
  final Future<void> Function(BlockDraft draft) onCreate;
  final Future<void> Function(String id, BlockDraft draft) onSave;

  /// 详情栏就地改（标题 / 颜色 / 图标 / 外观 / 文件夹 / 标签）。
  final void Function(String id, BlockPatch patch) onUpdate;

  /// 多选“统一改颜色 / 外观”。
  final void Function(List<String> ids, {Color? color, BlockAppearance? look})
  onBatchStyle;

  /// 界面已经确认过；删后只清选中，右栏保持展开（`009ea934` 防跳动）。
  final ValueChanged<List<String>> onDelete;

  /// 拖到文件夹 / “移到…”菜单。[folderId] 为 null = 根目录（未分类）。
  /// 目标里有同源块时，替换确认沿用现有整理器逻辑，由接线方弹。
  final void Function(List<String> ids, String? folderId, BlocksDropMode mode)
  onDropToFolder;

  /// 拖到收藏集：copy = 加入（收藏集只存引用），move = 从当前收藏集挪过去。
  final void Function(
    List<String> ids,
    String collectionId,
    BlocksDropMode mode,
  )
  onDropToCollection;
  final void Function(List<String> ids, String collectionId)
  onRemoveFromCollection;

  /// 自定义顺序下把 [id] 拖到 [beforeId] 前面（null = 放到最后）。
  final void Function(String id, String? beforeId) onReorder;
  final void Function(List<String> ids, BlockTag tag) onAddTag;
  final void Function(List<String> ids, String tag) onRemoveTag;

  /// 放进积木（`PromptBlockPaletteNotifier`）。
  final ValueChanged<List<String>> onAddToPalette;

  /// 导出选中的块为 TXT（每块一个文件）。
  final ValueChanged<List<String>> onExport;

  /// 把块的附带参数应用到当前生图（`applyPromptBlockGenerationSettings`）。
  final ValueChanged<String> onApplyParams;

  /// 选图（文件选择器）；取消返回 null。
  final Future<BlockThumbPick?> Function() onPickThumbnail;

  /// 读当前生图页参数，填进块的附带参数。
  final Future<BlockParams?> Function() onCaptureParams;

  /// 返回新文件夹 id（取消 / 失败返回 null）。
  final Future<String?> Function(String name, {String? parentId})
  onCreateFolder;
  final void Function(String id, String name) onRenameFolder;

  /// 删文件夹：接线方弹现有 `prompt_block_folder_delete_dialog`（内容移到根目录 / 其他文件夹 / 一起删）。
  final ValueChanged<String> onDeleteFolder;
  final void Function(String id, bool expanded) onToggleFolder;

  /// 把文件夹挪进另一个文件夹（null = 顶层）。
  final void Function(String id, String? parentId) onMoveFolder;

  /// 同级上移（−1）/ 下移（+1）。
  final void Function(String id, int delta) onReorderFolder;
  final Future<String?> Function(String name, {String? parentId, bool isFolder})
  onCreateCollection;
  final void Function(String id, String name) onRenameCollection;
  final ValueChanged<String> onDeleteCollection;
  final void Function(String name, String newName) onRenameTag;
  final void Function(String name, Color color) onSetTagColor;
  final ValueChanged<String> onDeleteTag;

  /// 导入：TXT 文件（每个文件一个块）/ 文件夹（子目录变文件夹）/ 整理导入（`curation_import_preview_dialog`）/
  /// 整库备份导出 / 整库备份导入。都由接线方弹文件选择器和现有对话框。
  final VoidCallback onImportTxt;
  final VoidCallback onImportFolder;
  final VoidCallback onImportCuration;
  final VoidCallback onExportBackup;
  final VoidCallback onImportBackup;

  static final BlocksLibraryActions none = BlocksLibraryActions(
    onScopeChanged: (_) {},
    onQueryChanged: (_) {},
    onSortChanged: (_, {required descending}) {},
    onViewChanged: (_) {},
    onQuickChanged: (_) {},
    onCardSizeChanged: (_) {},
    onSidebarChanged: (_) {},
    onInspectorChanged: (_) {},
    onSelect: (_) {},
    onInsert: (_) {},
    onSetFavorite: (_, _) {},
    onDuplicate: (_) {},
    onCopyText: (_) {},
    onCreate: (_) async {},
    onSave: (_, _) async {},
    onUpdate: (_, _) {},
    onBatchStyle: (_, {color, look}) {},
    onDelete: (_) {},
    onDropToFolder: (_, _, _) {},
    onDropToCollection: (_, _, _) {},
    onRemoveFromCollection: (_, _) {},
    onReorder: (_, _) {},
    onAddTag: (_, _) {},
    onRemoveTag: (_, _) {},
    onAddToPalette: (_) {},
    onExport: (_) {},
    onApplyParams: (_) {},
    onPickThumbnail: () async => null,
    onCaptureParams: () async => null,
    onCreateFolder: (_, {parentId}) async => null,
    onRenameFolder: (_, _) {},
    onDeleteFolder: (_) {},
    onToggleFolder: (_, _) {},
    onMoveFolder: (_, _) {},
    onReorderFolder: (_, _) {},
    onCreateCollection: (_, {parentId, isFolder = false}) async => null,
    onRenameCollection: (_, _) {},
    onDeleteCollection: (_) {},
    onRenameTag: (_, _) {},
    onSetTagColor: (_, _) {},
    onDeleteTag: (_) {},
    onImportTxt: () {},
    onImportFolder: () {},
    onImportCuration: () {},
    onExportBackup: () {},
    onImportBackup: () {},
  );
}

// ───────────────────────────── 生图页侧栏 ─────────────────────────────

/// 侧栏分类筛选里的一项（顶层文件夹）。
@immutable
class BlocksDockChip {
  const BlocksDockChip({required this.id, required this.name, this.count});
  final String id;
  final String name;
  final int? count;
}

/// 按分类分组的一段：分类名 + 块。
@immutable
class BlocksDockGroup {
  const BlocksDockGroup({
    required this.id,
    required this.name,
    required this.count,
    required this.blocks,
    this.expanded = true,
  });
  final String id;
  final String name;
  final int count;

  /// 这个分类里的块（含子文件夹），侧栏只摆前 [BlocksDock.groupPreview] 个，其余点“全部 N”。
  final List<BlockData> blocks;
  final bool expanded;
}

/// 侧栏筛选：全部 / 收藏 / 某个分类。
@immutable
class BlocksDockFilter {
  const BlocksDockFilter._(this.favorites, this.folderId);
  const BlocksDockFilter.all() : this._(false, null);
  const BlocksDockFilter.favorites() : this._(true, null);
  const BlocksDockFilter.folder(String id) : this._(false, id);
  final bool favorites;
  final String? folderId;
  bool get isAll => !favorites && folderId == null;

  @override
  bool operator ==(Object other) =>
      other is BlocksDockFilter &&
      other.favorites == favorites &&
      other.folderId == folderId;
  @override
  int get hashCode => Object.hash(favorites, folderId);
}

@immutable
class BlocksDockViewData {
  const BlocksDockViewData({
    this.total = 0,
    this.loading = false,
    this.query = '',
    this.filter = const BlocksDockFilter.all(),
    this.chips = const [],
    this.favorites = const [],
    this.recent = const [],
    this.groups = const [],
    this.results = const [],
    this.rag = const BlocksRagStatus(),
  });

  final int total;
  final bool loading;
  final String query;
  final BlocksDockFilter filter;
  final List<BlocksDockChip> chips;

  /// “全部”时置顶的两段：收藏、最近使用（最多 20 个，新的在前；SharedPreferences 里的最近插入 ID）。
  final List<BlockData> favorites;
  final List<BlockData> recent;

  /// 筛“全部”时是所有分类；筛某个分类时只有它（子文件夹各成一段）；筛收藏时为空（用 [favorites]）。
  final List<BlocksDockGroup> groups;

  /// 搜索结果（[query] 非空时显示，平铺不分组）。
  final List<BlockData> results;
  final BlocksRagStatus rag;
}

@immutable
class BlocksDockActions {
  const BlocksDockActions({
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onInsert,
    required this.dragDataOf,
    required this.onCreate,
    required this.onOpenLibrary,
    required this.onClose,
    required this.onToggleGroup,
    required this.onEdit,
    required this.onSetFavorite,
    required this.onAddToPalette,
    required this.onShowInLibrary,
    this.onPopOut,
  });

  final ValueChanged<String> onQueryChanged;
  final ValueChanged<BlocksDockFilter> onFilterChanged;

  /// 点药丸：插到最近光标处（`pillActiveEditorTargetProvider` + `insertPromptBlockBundle`，计使用次数、记最近使用）。
  final ValueChanged<String> onInsert;

  /// 拖药丸进提示词时的拖拽数据（`PromptBlockDragData`）。
  final Object Function(String id) dragDataOf;

  /// 标题行“+”：打开编辑块对话框新建。
  final VoidCallback onCreate;

  /// 标题行“在块库中打开”。
  final VoidCallback onOpenLibrary;
  final VoidCallback onClose;
  final void Function(String groupId, bool expanded) onToggleGroup;

  /// 右键菜单。
  final ValueChanged<String> onEdit;
  final void Function(String id, bool favorite) onSetFavorite;
  final ValueChanged<String> onAddToPalette;
  final ValueChanged<String> onShowInLibrary;

  /// 弹出为浮窗（画风探索页的浮层不传）。
  final VoidCallback? onPopOut;
}

// ───────────────────────────── 实例卡 ─────────────────────────────

enum BlockMode { fixed, sequential, random }

/// 随机抽取的输出顺序：按抽中顺序 / 按池里原顺序。
enum BlockOrder { drawn, original }

/// 作用于：正面 / 负面 / 两面（`rollScopeMask` 1 / 2 / 3）。
enum BlockScopeSide { positive, negative, both }

/// 实例的抽取规则（`PillInstanceSettings`，字段一一对应）。
@immutable
class BlockRollSettings {
  const BlockRollSettings({
    this.mode = BlockMode.fixed,
    this.countMin = 1,
    this.countMax = 1,
    this.order = BlockOrder.drawn,
    this.weightEnabled = false,
    this.weightMin = .1,
    this.weightMax = 2,
    this.weightAverage = .8,
    this.leftDispersion = .4,
    this.rightDispersion = .4,
    this.softBalance = true,
    this.softBalanceStrength = 1,
    this.probability = 1,
  });

  static const weightFloor = -3.0;
  static const weightCeiling = 3.0;

  /// 分布预设（只是快捷写左右离散，不落库）：集中 / 均衡 / 发散。
  static const focused = .15;
  static const balanced = .4;
  static const spread = .85;

  final BlockMode mode;
  final int countMin;
  final int countMax;
  final BlockOrder order;
  final bool weightEnabled;
  final double weightMin;
  final double weightMax;
  final double weightAverage;
  final double leftDispersion;
  final double rightDispersion;
  final bool softBalance;
  final double softBalanceStrength;

  /// 出现概率 0…1（`triggerProbability`）。
  final double probability;

  BlockRollSettings copyWith({
    BlockMode? mode,
    int? countMin,
    int? countMax,
    BlockOrder? order,
    bool? weightEnabled,
    double? weightMin,
    double? weightMax,
    double? weightAverage,
    double? leftDispersion,
    double? rightDispersion,
    bool? softBalance,
    double? softBalanceStrength,
    double? probability,
  }) => BlockRollSettings(
    mode: mode ?? this.mode,
    countMin: countMin ?? this.countMin,
    countMax: countMax ?? this.countMax,
    order: order ?? this.order,
    weightEnabled: weightEnabled ?? this.weightEnabled,
    weightMin: weightMin ?? this.weightMin,
    weightMax: weightMax ?? this.weightMax,
    weightAverage: weightAverage ?? this.weightAverage,
    leftDispersion: leftDispersion ?? this.leftDispersion,
    rightDispersion: rightDispersion ?? this.rightDispersion,
    softBalance: softBalance ?? this.softBalance,
    softBalanceStrength: softBalanceStrength ?? this.softBalanceStrength,
    probability: probability ?? this.probability,
  );

  @override
  bool operator ==(Object other) =>
      other is BlockRollSettings &&
      other.mode == mode &&
      other.countMin == countMin &&
      other.countMax == countMax &&
      other.order == order &&
      other.weightEnabled == weightEnabled &&
      other.weightMin == weightMin &&
      other.weightMax == weightMax &&
      other.weightAverage == weightAverage &&
      other.leftDispersion == leftDispersion &&
      other.rightDispersion == rightDispersion &&
      other.softBalance == softBalance &&
      other.softBalanceStrength == softBalanceStrength &&
      other.probability == probability;

  @override
  int get hashCode => Object.hash(
    mode,
    countMin,
    countMax,
    order,
    weightEnabled,
    weightMin,
    weightMax,
    weightAverage,
    leftDispersion,
    rightDispersion,
    softBalance,
    softBalanceStrength,
    probability,
  );
}

/// 抽到的一项：[weight] 为 null 表示没套权重；[text] 是原子原文（例如 `artist:sincos`）。
@immutable
class BlockDrawn {
  const BlockDrawn(this.text, [this.weight]);
  final String text;
  final double? weight;
}

@immutable
class BlockInstanceViewData {
  const BlockInstanceViewData({
    required this.block,
    required this.settings,
    this.locked = false,
    this.enabled = true,
    this.drawn = const [],
    this.send = '',
    this.skipped = false,
    this.temporary = false,
    this.tempContent,
    this.tempNegativeContent,
    this.originalContent,
    this.originalNegativeContent,
    this.editedAt,
    this.editedBy,
    this.folders = const [],
    this.seqIndex = 0,
    this.seqCount = 1,
    this.prevText,
    this.nextText,
    this.side,
    this.evolution,
    this.missing = false,
    this.catalog = const BlockParamCatalog(),
  });

  /// 附带参数的显示名。
  final BlockParamCatalog catalog;

  /// 实例引用的块（块被删时 [missing] 为 true，只用标题）。
  final BlockData block;
  final BlockRollSettings settings;

  /// 冻结当前抽取结果（顺序模式同时冻结游标）。
  final bool locked;
  final bool enabled;

  /// 本次抽到的项（`currentRoll` 拆开），顺序 / 随机时显示。
  final List<BlockDrawn> drawn;

  /// 实际发送的文本（`currentRoll` 原文）。
  final String send;

  /// 出现概率没通过，这次整个块没出场。
  final bool skipped;
  final bool temporary;
  final String? tempContent;
  final String? tempNegativeContent;
  final String? originalContent;
  final String? originalNegativeContent;
  final DateTime? editedAt;

  /// 谁改成临时块的：`agent` / `user`。
  final String? editedBy;

  /// 临时块“另存为新块”可选的文件夹（树序拍平）。
  final List<BlocksFolder> folders;

  /// 顺序模式：当前这批的起点（`sequenceCursor − lastRollCount`，0 起）和这批的项数；
  /// 池长是 `block.atoms.length`。
  final int seqIndex;
  final int seqCount;

  /// 顺序模式：上一项 / 下一项（原文，没有则 null）。
  final String? prevText;
  final String? nextText;

  /// 作用于；null = 块没有负面部分，不显示这一行。
  final BlockScopeSide? side;

  /// 遗传开关（只在画风探索页传）；null = 不显示。
  final bool? evolution;
  final bool missing;
}

@immutable
class BlockInstanceActions {
  const BlockInstanceActions({
    required this.onReroll,
    required this.onLockChanged,
    required this.onModeChanged,
    required this.onStep,
    required this.onSideChanged,
    required this.onEnabledChanged,
    required this.onEditBlock,
    required this.onRemove,
    required this.onApplyParams,
    required this.onSaveSettings,
    required this.sample,
    required this.onShowInLibrary,
    required this.onCopySend,
    this.onEvolutionChanged,
    this.onExpand,
    this.onEditTempContent,
    this.onRevertTemp,
    this.onSaveTempAsNewBlock,
  });

  final VoidCallback onReroll;
  final ValueChanged<bool> onLockChanged;

  /// 卡片里直接切模式：接线方用当前规则只改 mode 写回（`updateInstanceSettings`），并按新模式重抽。
  final ValueChanged<BlockMode> onModeChanged;

  /// 顺序模式 ← / →（−1 / +1）。
  final ValueChanged<int> onStep;
  final ValueChanged<BlockScopeSide> onSideChanged;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEditBlock;

  /// 从提示词里移除这个实例。
  final VoidCallback onRemove;
  final VoidCallback onApplyParams;

  /// 抽取规则面板点“完成”。卡片可能已经被销毁（B1）：接线方先拿存活在 ProviderContainer 里的
  /// notifier 再异步写，配对块逐成员写入。
  final ValueChanged<BlockRollSettings> onSaveSettings;

  /// 效果预览：按给定规则抽 [times] 次（`PillRollEngine`，不写回）。
  final List<List<BlockDrawn>> Function(BlockRollSettings settings, int times)
  sample;
  final VoidCallback onShowInLibrary;

  /// 复制实际发送的文本。
  final VoidCallback onCopySend;
  final VoidCallback? onExpand;
  final Future<void> Function(String content, String? negativeContent)?
  onEditTempContent;
  final Future<void> Function()? onRevertTemp;
  final Future<void> Function(String title, String? folderId)?
  onSaveTempAsNewBlock;
  final ValueChanged<bool>? onEvolutionChanged;
}

// ───────────────────────────── 编辑块 ─────────────────────────────

@immutable
class BlockEditData {
  const BlockEditData({
    required this.draft,
    this.blockId,
    this.folders = const [],
    this.tags = const [],
    this.catalog = const BlockParamCatalog(),
    this.sourcePath,
    this.importedAt,
    this.sourceState = BlockSourceState.none,
    this.folderName,
  });

  final BlockDraft draft;

  /// null = 新建。
  final String? blockId;
  final List<BlocksFolder> folders;

  /// 库里已有的标签（加标签时的候选）。
  final List<BlockTag> tags;
  final BlockParamCatalog catalog;
  final String? sourcePath;
  final DateTime? importedAt;
  final BlockSourceState sourceState;

  /// 预览卡右上角的分类名。
  final String? folderName;
}

@immutable
class BlockEditActions {
  const BlockEditActions({
    required this.onSave,
    required this.onCancel,
    required this.onPickThumbnail,
    required this.onCaptureParams,
    this.onDelete,
  });

  /// 保存（Ctrl+Enter 同）。签名对应旧 `PromptBlockEditDialog.show` / `createWithDialog` 的返回值。
  final ValueChanged<BlockDraft> onSave;
  final VoidCallback onCancel;
  final Future<BlockThumbPick?> Function() onPickThumbnail;
  final Future<BlockParams?> Function() onCaptureParams;

  /// 删除块（新建时不传）。界面先确认。
  final VoidCallback? onDelete;
}

// ───────────────────────────── 选中文字存为块 ─────────────────────────────

@immutable
class BlockQuickSaveData {
  const BlockQuickSaveData({
    required this.atoms,
    required this.title,
    this.color = const Color(0xFF8E24AA),
    this.icon,
    this.folders = const [],
    this.folderId,
    this.replaceSelection = true,
  });

  /// 选中文字按顶层逗号拆好的项。
  final List<String> atoms;

  /// 建议的名字（接线方取前几项拼出来，例如“白裙蓝花”或 `white dress, blue…`）。
  final String title;
  final Color color;
  final String? icon;
  final List<BlocksFolder> folders;
  final String? folderId;

  /// 上次的“保存后换成块”开关（接线方记住）。
  final bool replaceSelection;
}

@immutable
class BlockQuickDraft {
  const BlockQuickDraft({
    required this.title,
    required this.atoms,
    required this.color,
    required this.icon,
    required this.folderId,
    required this.replaceSelection,
  });
  final String title;
  final List<String> atoms;
  final Color color;
  final String? icon;
  final String? folderId;

  /// 保存后把选中的文字换成这个块的实例。
  final bool replaceSelection;
}

@immutable
class BlockQuickSaveActions {
  const BlockQuickSaveActions({required this.onSave, required this.onCancel});
  final ValueChanged<BlockQuickDraft> onSave;
  final VoidCallback onCancel;
}
