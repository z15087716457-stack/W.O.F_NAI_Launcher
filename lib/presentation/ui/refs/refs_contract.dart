import 'package:flutter/widgets.dart';

/// Vibe 库 / 精准参考库：界面只认这份契约。两个库是同一个页面 [RefsKind] 两种模式。
///
/// 口径约定：
/// - 列表 [RefsViewData.entries] 由接线方按 [RefsFilter] 筛好、排好序；界面不再二次筛选。
/// - 编码状态 [RefsEncoding]、费用常量 [RefsCosts]、模型能力 [RefsModel] 都由接线方按
///   `ModelSpecs.of(model)`、`VibeReference.needsEncodingForModel`、`AnlasCalculator` 算好给出，
///   界面不按模型名判断。
/// - 时间一律给 [DateTime]，界面按 [RefsViewData.now] 写成“2 小时前 / 昨天 / 8 月 20 日”。

enum RefsKind { vibe, precise }

/// 左栏顶部的四个视图。
enum RefsView { all, favorites, recent, inGeneration }

enum RefsSort { lastUsed, createdAt, usedCount, name }

enum RefsCardSize { small, medium, large }

/// Vibe 条目来源（`VibeSourceType`）。
enum RefsVibeSource { png, vibeFile, bundle, rawImage }

/// 精准参考类型（`PreciseRefType`）。
enum RefsPreciseType { character, style, both }

/// Vibe 对**当前模型**的编码状态。
enum RefsEncoding {
  /// 已为当前模型编码，直接能用。
  ready,

  /// 只有原图、还没编码：第一次用在生图时编码（[RefsCosts.encode]）。
  encodeOnUse,

  /// 编码是给别的模型的，有原图：用时重新编码（[RefsCosts.encode]）。
  reencode,

  /// 编码是给别的模型的，没有原图：当前模型用不了。
  unusable,

  /// 老条目没有记录编码模型：卡片不出标签，检查器不写结论。
  unknown,
}

/// 快速筛选行（卡片墙上方）。Vibe：全部 / 收藏 / 有原图 / 需要编码 / 组合包；精准参考：全部 / 收藏 / 没用过。
enum RefsQuick { all, favorites, hasRaw, needsEncoding, bundles, unused }

@immutable
class RefsFilter {
  const RefsFilter({
    this.view = RefsView.all,
    this.categoryId,
    this.source,
    this.type,
    this.quick = RefsQuick.all,
    this.query = '',
    this.sort = RefsSort.lastUsed,
    this.descending = true,
  });

  final RefsView view;

  /// Vibe 分类：null = 不按分类，[RefsCategory.uncategorized] = 未分类。选分类时 [view] 保持 all。
  final String? categoryId;
  final RefsVibeSource? source;

  /// 精准参考：左栏选中的类型。
  final RefsPreciseType? type;
  final RefsQuick quick;

  /// 搜索：Vibe 匹配名称 / 显示名 / 标签，精准参考匹配名称。界面输入停 300ms 后回调。
  final String query;
  final RefsSort sort;
  final bool descending;

  RefsFilter copyWith({
    RefsView? view,
    String? Function()? categoryId,
    RefsVibeSource? Function()? source,
    RefsPreciseType? Function()? type,
    RefsQuick? quick,
    String? query,
    RefsSort? sort,
    bool? descending,
  }) => RefsFilter(
    view: view ?? this.view,
    categoryId: categoryId != null ? categoryId() : this.categoryId,
    source: source != null ? source() : this.source,
    type: type != null ? type() : this.type,
    quick: quick ?? this.quick,
    query: query ?? this.query,
    sort: sort ?? this.sort,
    descending: descending ?? this.descending,
  );

  @override
  bool operator ==(Object other) =>
      other is RefsFilter &&
      other.view == view &&
      other.categoryId == categoryId &&
      other.source == source &&
      other.type == type &&
      other.quick == quick &&
      other.query == query &&
      other.sort == sort &&
      other.descending == descending;

  @override
  int get hashCode => Object.hash(
    view,
    categoryId,
    source,
    type,
    quick,
    query,
    sort,
    descending,
  );
}

/// 当前模型（`GenerationParams.model`）以及它能不能用这两种参考。
@immutable
class RefsModel {
  const RefsModel({
    required this.name,
    required this.shortName,
    required this.vibeUsable,
    required this.preciseUsable,
    this.switchTarget,
  });

  /// 显示名：`V4.5 Full`（`ImageModels.modelDisplayNames`）。
  final String name;

  /// 编码标签里用的短名：`V4.5`。
  final String shortName;

  /// `modelSpec.vibetransfer`。
  final bool vibeUsable;

  /// `modelSpec.characterReferences`。
  final bool preciseUsable;

  /// 横幅“切到 …”按钮的目标模型显示名；null 时不出按钮。
  final String? switchTarget;
}

/// 费用常量，取自 `AnlasCalculator`。
@immutable
class RefsCosts {
  const RefsCosts({
    this.maxVibes = 16,
    this.freeVibes = 4,
    this.extraPerVibe = 2,
    this.encode = 2,
    this.precise = 5,
  });
  final int maxVibes;

  /// 超过这个数，每多一个 Vibe 每张图多收 [extraPerVibe]。
  final int freeVibes;
  final int extraPerVibe;

  /// 未编码 / 模型不匹配时每个编码一次的费用。
  final int encode;

  /// 每张精准参考每张图的附加费。
  final int precise;
}

/// 库里的一条（卡片 + 检查器用）。Vibe 字段和精准参考字段按 [RefsViewData.kind] 取用。
@immutable
class RefsEntry {
  const RefsEntry({
    required this.key,
    required this.name,
    this.thumb,
    this.favorite = false,
    this.inGeneration = false,
    this.strength = .6,
    this.infoExtracted = .7,
    this.source = RefsVibeSource.png,
    this.encoding = RefsEncoding.ready,
    this.encodedFor,
    this.hasRaw,
    this.bundleCount = 0,
    this.bundleThumbs = const [],
    this.type = RefsPreciseType.both,
    this.fidelity = 1,
    this.categoryId,
    this.tags = const [],
    this.usedCount = 0,
    this.lastUsed,
    this.createdAt,
    this.fileName,
    this.imageSize,
    this.imageFormat,
  });

  /// Vibe：`VibeLibraryEntry.id`；精准参考：`PreciseRefLibraryEntry.id`。
  final String key;
  final String name;

  /// 卡片缩略图（`getDisplayThumbnail`，按需加载）。
  final ImageProvider? thumb;
  final bool favorite;

  /// 这一条现在就在生图页（会话内指纹表：从库里发送过、且仍在生图页）。
  final bool inGeneration;

  /// Vibe：默认强度 / 信息提取；精准参考：[strength] 是参考强度。
  final double strength;
  final double infoExtracted;
  final RefsVibeSource source;
  final RefsEncoding encoding;

  /// 编码对应的模型短名（`V4`），[RefsEncoding.reencode] / [RefsEncoding.unusable] 的文案用。
  final String? encodedFor;

  /// 有没有原图（信息提取能不能改、能不能重编码）。卡片只有显示条目时可以先给 null，
  /// 检查器加载完整条目（`getEntry`）后再给准确值。
  final bool? hasRaw;

  /// 组合包里的 Vibe 数；0 = 不是组合包。
  final int bundleCount;

  /// 组合包卡片背后叠纸用的第 2、3 张预览（可空）。
  final List<ImageProvider> bundleThumbs;

  final RefsPreciseType type;

  /// 精准参考保真度。
  final double fidelity;

  /// Vibe 分类 id；null = 未分类。
  final String? categoryId;
  final List<String> tags;
  final int usedCount;
  final DateTime? lastUsed;
  final DateTime? createdAt;

  /// 检查器“文件”一行：`星海夜光.png`。
  final String? fileName;

  /// 精准参考原图尺寸和格式（`1024 × 1536 · PNG`）。
  final Size? imageSize;
  final String? imageFormat;

  bool get isBundle => bundleCount > 0;

  RefsEntry copyWith({
    String? name,
    ImageProvider? thumb,
    bool? favorite,
    bool? inGeneration,
    double? strength,
    double? infoExtracted,
    RefsEncoding? encoding,
    String? encodedFor,
    RefsPreciseType? type,
    double? fidelity,
    String? Function()? categoryId,
    List<String>? tags,
    int? usedCount,
    DateTime? lastUsed,
  }) => RefsEntry(
    key: key,
    name: name ?? this.name,
    thumb: thumb ?? this.thumb,
    favorite: favorite ?? this.favorite,
    inGeneration: inGeneration ?? this.inGeneration,
    strength: strength ?? this.strength,
    infoExtracted: infoExtracted ?? this.infoExtracted,
    source: source,
    encoding: encoding ?? this.encoding,
    encodedFor: encodedFor ?? this.encodedFor,
    hasRaw: hasRaw,
    bundleCount: bundleCount,
    bundleThumbs: bundleThumbs,
    type: type ?? this.type,
    fidelity: fidelity ?? this.fidelity,
    categoryId: categoryId != null ? categoryId() : this.categoryId,
    tags: tags ?? this.tags,
    usedCount: usedCount ?? this.usedCount,
    lastUsed: lastUsed ?? this.lastUsed,
    createdAt: createdAt,
    fileName: fileName,
    imageSize: imageSize,
    imageFormat: imageFormat,
  );
}

/// Vibe 分类（`VibeLibraryCategory`），可嵌套。列表按树的先序给出（父在前，子紧跟）。
@immutable
class RefsCategory {
  const RefsCategory({
    required this.id,
    required this.name,
    required this.count,
    this.parentId,
  });
  final String id;
  final String name;
  final int count;
  final String? parentId;

  /// [RefsFilter.categoryId] 里表示“未分类”的 id。
  static const uncategorized = '';
}

/// 左栏和筛选行的计数。
@immutable
class RefsCounts {
  const RefsCounts({
    this.all = 0,
    this.favorites = 0,
    this.inGeneration = 0,
    this.uncategorized = 0,
    this.needsEncoding = 0,
    this.sources = const {},
    this.types = const {},
  });
  final int all;
  final int favorites;
  final int inGeneration;
  final int uncategorized;
  final int needsEncoding;
  final Map<RefsVibeSource, int> sources;
  final Map<RefsPreciseType, int> types;
}

/// 生图页现在用着的一个参考（托盘里的一格）。
@immutable
class RefsTrayItem {
  const RefsTrayItem({
    required this.id,
    this.entryKey,
    this.thumb,
    this.value = 1,
    this.enabled = true,
  });

  /// 生图页那一侧的 id（移除时回传）。
  final String id;

  /// 来自库里哪一条；不是从库里发送的为 null。
  final String? entryKey;
  final ImageProvider? thumb;

  /// 格子底部写的数字：Vibe 是强度，精准参考是参考强度。
  final double value;

  /// 被停用（暂停 Vibe）时变灰。
  final bool enabled;
}

/// 底部托盘：生图页现在的 Vibe / 精准参考。
@immutable
class RefsTray {
  const RefsTray({
    this.items = const [],
    this.otherVibes = 0,
    this.vibesPaused = false,
  });
  final List<RefsTrayItem> items;

  /// 精准参考库：生图页上还有几个**启用的** Vibe（有精准参考时它们不会发送）。
  final int otherVibes;

  /// 精准参考库：生图页的 Vibe 是不是被托盘“暂停 Vibe”停用了。
  final bool vibesPaused;
}

/// 组合包里的一个 Vibe（`bundledVibe*` 数组的一项）。
@immutable
class RefsBundleChild {
  const RefsBundleChild({
    required this.name,
    this.thumb,
    this.strength = .6,
    this.infoExtracted = .7,
  });
  final String name;
  final ImageProvider? thumb;
  final double strength;
  final double infoExtracted;
}

/// 选中条目的完整数据（`getEntry` 之后）：大图、组合包内容。
@immutable
class RefsDetail {
  const RefsDetail({
    required this.key,
    this.image,
    this.loading = false,
    this.bundle = const [],
    this.coverIndex = 0,
    this.bundleEncodedFor,
  });
  final String key;

  /// 原图（检查器预览、大图详情）；null 时用卡片缩略图。
  final ImageProvider? image;
  final bool loading;
  final List<RefsBundleChild> bundle;
  final int coverIndex;

  /// 组合包里全部已为哪个模型编码（`V4.5`）；混合时给 null。
  final String? bundleEncodedFor;
}

/// 拖文件进窗口时的识别结果（`VibeDropImportPreprocessor`），非 null 时显示拖入提示。
@immutable
class RefsDropSummary {
  const RefsDropSummary({
    this.vibePngs = 0,
    this.vibeFiles = 0,
    this.bundles = 0,
    this.images = 0,
  });
  final int vibePngs;
  final int vibeFiles;
  final int bundles;
  final int images;
  int get total => vibePngs + vibeFiles + bundles + images;
}

enum RefsImportKind { vibePng, vibeFile, bundle, image }

/// 导入窗口里的一个文件。
@immutable
class RefsImportRow {
  const RefsImportRow({
    required this.id,
    required this.name,
    required this.ext,
    required this.kind,
    this.thumb,
    this.encodedFor,
    this.encodedForCurrent = true,
    this.bundle = const [],
    this.duplicate = false,
  });
  final String id;

  /// 去掉扩展名的文件名（默认条目名）。
  final String name;

  /// `.png`、`.naiv4vibe`……
  final String ext;
  final RefsImportKind kind;
  final ImageProvider? thumb;

  /// 文件里自带的编码对应模型短名。
  final String? encodedFor;

  /// 自带编码是不是给当前模型的。
  final bool encodedForCurrent;

  /// 组合包里的 Vibe（名称 + 预览），“挑几个”用。
  final List<RefsBundleChild> bundle;

  /// 库里已有同名条目（`_reservedImportNames`）。
  final bool duplicate;
}

/// 接线方选完文件 / 拖入 / 粘贴后给出的导入草稿，非 null 时显示导入窗口。
@immutable
class RefsImportDraft {
  const RefsImportDraft({required this.rows, this.categoryId});
  final List<RefsImportRow> rows;

  /// 默认放进的分类（左栏当前选中的分类）。
  final String? categoryId;
}

enum RefsBundleImport { whole, split, pick }

enum RefsDuplicate { keepBoth, overwrite, skip }

@immutable
class RefsImportRowPlan {
  const RefsImportRowPlan({
    required this.id,
    required this.name,
    this.bundle = RefsBundleImport.whole,
    this.picked = const [],
    this.duplicate = RefsDuplicate.keepBoth,
  });
  final String id;
  final String name;
  final RefsBundleImport bundle;

  /// [RefsBundleImport.pick] 时勾选的子项下标。
  final List<int> picked;
  final RefsDuplicate duplicate;
}

/// 导入窗口点“导入”的结果。
@immutable
class RefsImportPlan {
  const RefsImportPlan({
    required this.rows,
    this.categoryId,
    this.tags = const [],
    this.encodeNow = false,
  });
  final List<RefsImportRowPlan> rows;
  final String? categoryId;
  final List<String> tags;

  /// 普通图片现在就编码（每张 [RefsCosts.encode]）；false = 用到时再编码（先存原图）。
  final bool encodeNow;
}

enum RefsExportFormat { vibeFile, bundle, png, encoded }

/// 导出窗口点“导出”的结果（导出实现走 `vibe_export_utils`，不改）。
@immutable
class RefsExportPlan {
  const RefsExportPlan({
    required this.keys,
    required this.format,
    required this.folder,
    this.thumbnails = true,
    this.zip = false,
  });
  final List<String> keys;
  final RefsExportFormat format;
  final String folder;
  final bool thumbnails;
  final bool zip;
}

/// 导入按钮旁的箭头：从哪里导入。
enum RefsImportSource { files, images, clipboard }

@immutable
class RefsViewData {
  const RefsViewData({
    required this.kind,
    required this.now,
    required this.model,
    this.costs = const RefsCosts(),
    this.entries = const [],
    this.counts = const RefsCounts(),
    this.categories = const [],
    this.filter = const RefsFilter(),
    this.selectedKey,
    this.detail,
    this.tray = const RefsTray(),
    this.cardSize = RefsCardSize.medium,
    this.sidebarOpen = true,
    this.inspectorOpen = true,
    this.folderPath,
    this.exportFolder = '',
    this.importType = RefsPreciseType.both,
    this.loading = false,
    this.drop,
    this.importDraft,
    this.reducedMotion = false,
  });

  final RefsKind kind;

  /// 相对时间的基准（测试和基准图固定它）。
  final DateTime now;
  final RefsModel model;
  final RefsCosts costs;

  /// 已按 [filter] 筛选、排序的条目。
  final List<RefsEntry> entries;
  final RefsCounts counts;

  /// Vibe 分类树（先序）。精准参考库为空。
  final List<RefsCategory> categories;
  final RefsFilter filter;
  final String? selectedKey;

  /// [selectedKey] 的完整数据；还没加载完给 `RefsDetail(loading: true)`。
  final RefsDetail? detail;
  final RefsTray tray;
  final RefsCardSize cardSize;
  final bool sidebarOpen;
  final bool inspectorOpen;

  /// Vibe 库文件夹（左栏底部）。
  final String? folderPath;

  /// 导出窗口默认保存位置。
  final String exportFolder;

  /// 精准参考库：导入时用的类型（`_importType`，跟着左栏选中的类型走）。
  final RefsPreciseType importType;

  /// 首次加载 / 重新扫描文件夹中。
  final bool loading;
  final RefsDropSummary? drop;
  final RefsImportDraft? importDraft;
  final bool reducedMotion;

  /// 整个库是空的（显示空库引导，不显示卡片墙和托盘）。
  bool get libraryEmpty => counts.all == 0 && !loading;
}

/// 改一条的默认参数（写回库条目）。只传要改的字段。
@immutable
class RefsParamsPatch {
  const RefsParamsPatch({
    this.strength,
    this.infoExtracted,
    this.fidelity,
    this.type,
  });
  final double? strength;

  /// 改信息提取要按原图重新编码（`prepareVibeForLibraryParamSave`，扣费前接线方先确认）。
  final double? infoExtracted;
  final double? fidelity;
  final RefsPreciseType? type;
}

/// 这次发送用的参数（检查器里改过但没“存为默认”的值）。
@immutable
class RefsSendOverride {
  const RefsSendOverride({required this.strength, required this.infoExtracted});
  final double strength;
  final double infoExtracted;
}

@immutable
class RefsActions {
  const RefsActions({
    required this.onFilterChanged,
    required this.onCardSizeChanged,
    required this.onSidebarChanged,
    required this.onInspectorChanged,
    required this.onSelect,
    required this.onAddToGeneration,
    required this.onAddBundle,
    required this.onSendImg2Img,
    required this.onSaveAsVibe,
    required this.onSetFavorite,
    required this.onRename,
    required this.onUpdateParams,
    required this.onSetStrengthMany,
    required this.onSetTypeMany,
    required this.onSaveBundle,
    required this.onSplitBundle,
    required this.onSetBundleCover,
    required this.onPackBundle,
    required this.onEncodeNow,
    required this.onMoveToCategory,
    required this.onAddTags,
    required this.onRemoveTag,
    required this.onCreateCategory,
    required this.onRenameCategory,
    required this.onDeleteCategory,
    required this.onMoveCategory,
    required this.onImport,
    required this.onImportConfirm,
    required this.onImportCancel,
    required this.onExport,
    required this.onPickExportFolder,
    required this.onExportAll,
    required this.onRescan,
    required this.onOpenFolder,
    required this.onReplacePreview,
    required this.onCopyImage,
    required this.onDelete,
    required this.onTrayRemove,
    required this.onTrayClear,
    required this.onPauseVibes,
    required this.onGoGeneration,
    required this.onSwitchModel,
  });

  /// 左栏视图 / 分类 / 来源 / 类型、快速筛选、搜索、排序都走这一个回调；接线方存偏好、重新筛选。
  final ValueChanged<RefsFilter> onFilterChanged;
  final ValueChanged<RefsCardSize> onCardSizeChanged;
  final ValueChanged<bool> onSidebarChanged;
  final ValueChanged<bool> onInspectorChanged;

  /// 单击 / 方向键选中：检查器换成这条，接线方加载完整条目到 [RefsViewData.detail]。
  final ValueChanged<String> onSelect;

  /// 加入生图页（双击、Enter、悬停条、检查器、多选、拖到托盘）。[replace] = Shift / “替换”：
  /// 先清掉生图页现有的同类参考。[overrides] 是检查器里改过但没存的参数。发送后**不跳页**。
  /// 精准参考库这里就是“发送到精准参考”。超过 16 个时接线方提示并截断。
  final void Function(
    List<String> keys, {
    bool replace,
    Map<String, RefsSendOverride> overrides,
  })
  onAddToGeneration;

  /// 组合包详情：只发 [indexes] 这几个（null = 全部），[overrides] 按子项下标。
  final void Function(
    String key, {
    List<int>? indexes,
    Map<int, RefsSendOverride> overrides,
    bool replace,
  })
  onAddBundle;

  /// 精准参考：发送到图生图（**会跳到生图页**）。
  final ValueChanged<String> onSendImg2Img;

  /// 精准参考：用这张图新建一条未编码的 Vibe 条目。
  final ValueChanged<String> onSaveAsVibe;
  final void Function(List<String> keys, bool favorite) onSetFavorite;
  final void Function(String key, String name) onRename;

  /// 存为默认（Vibe）/ 就地改（精准参考的类型、强度、保真度）。
  final void Function(String key, RefsParamsPatch patch) onUpdateParams;

  /// 多选“统一设置强度”：写回各条默认强度。
  final void Function(List<String> keys, double strength) onSetStrengthMany;

  /// 精准参考多选：统一改类型。
  final void Function(List<String> keys, RefsPreciseType type) onSetTypeMany;

  /// 组合包“保存到组合包”：把子项参数写回文件（按下标）。
  final void Function(String key, Map<int, RefsSendOverride> values)
  onSaveBundle;

  /// 拆成单独的 Vibe（原组合包保留）。
  final ValueChanged<String> onSplitBundle;
  final void Function(String key, int index) onSetBundleCover;

  /// 多选“打包成组合包”（`saveBundleEntry` 新建一条，原条目不动）。
  final ValueChanged<List<String>> onPackBundle;

  /// 现在为当前模型编码（扣 [RefsCosts.encode]，接线方先确认）。
  final ValueChanged<String> onEncodeNow;

  /// 移到分类（拖到左栏、检查器下拉、多选“移到”）。null = 未分类。
  final void Function(List<String> keys, String? categoryId) onMoveToCategory;
  final void Function(List<String> keys, List<String> tags) onAddTags;
  final void Function(String key, String tag) onRemoveTag;

  /// 新建分类（[parentId] 非 null 时建子分类），返回新 id。
  final Future<String> Function(String name, {String? parentId})
  onCreateCategory;
  final void Function(String id, String name) onRenameCategory;
  final ValueChanged<String> onDeleteCategory;

  /// 拖分类改父级（null = 顶层）。界面不会把分类拖到自己或自己的子孙上。
  final void Function(String id, String? parentId) onMoveCategory;

  /// 导入按钮（Ctrl+I）/ 箭头里的“图片 / 剪贴板”/ 空库按钮。
  /// Vibe：接线方选好文件、识别后给出 [RefsViewData.importDraft]；精准参考直接按 [RefsViewData.importType] 存。
  final ValueChanged<RefsImportSource> onImport;
  final ValueChanged<RefsImportPlan> onImportConfirm;
  final VoidCallback onImportCancel;

  final ValueChanged<RefsExportPlan> onExport;

  /// 导出窗口“选择”保存位置；取消返回 null。
  final Future<String?> Function() onPickExportFolder;

  /// “更多 › 导出全部”。
  final VoidCallback onExportAll;

  /// “更多 › 重新扫描文件夹”（原“刷新”，`syncWithFileSystem`）。
  final VoidCallback onRescan;

  /// 打开所在文件夹：[key] 为 null 时打开库文件夹（`Process.start`，不等结束）。
  final ValueChanged<String?> onOpenFolder;

  /// 换预览图（菜单“换预览图…”，或把图片拖到大图详情上），`updateEntryThumbnail`。
  final ValueChanged<String> onReplacePreview;
  final ValueChanged<String> onCopyImage;

  /// 删除。界面已经让用户确认过。
  final ValueChanged<List<String>> onDelete;

  /// 托盘：移掉生图页的一个参考 / 清空。
  final ValueChanged<String> onTrayRemove;
  final VoidCallback onTrayClear;

  /// 精准参考托盘“暂停 Vibe / 恢复”：把生图页全部 Vibe 设为停用 / 启用。
  final ValueChanged<bool> onPauseVibes;
  final VoidCallback onGoGeneration;

  /// 横幅“切到 …”（`GenerationParamsNotifier.updateModel`）。
  final VoidCallback onSwitchModel;

  static final none = RefsActions(
    onFilterChanged: (_) {},
    onCardSizeChanged: (_) {},
    onSidebarChanged: (_) {},
    onInspectorChanged: (_) {},
    onSelect: (_) {},
    onAddToGeneration: (_, {replace = false, overrides = const {}}) {},
    onAddBundle: (_, {indexes, overrides = const {}, replace = false}) {},
    onSendImg2Img: (_) {},
    onSaveAsVibe: (_) {},
    onSetFavorite: (_, _) {},
    onRename: (_, _) {},
    onUpdateParams: (_, _) {},
    onSetStrengthMany: (_, _) {},
    onSetTypeMany: (_, _) {},
    onSaveBundle: (_, _) {},
    onSplitBundle: (_) {},
    onSetBundleCover: (_, _) {},
    onPackBundle: (_) {},
    onEncodeNow: (_) {},
    onMoveToCategory: (_, _) {},
    onAddTags: (_, _) {},
    onRemoveTag: (_, _) {},
    onCreateCategory: (_, {parentId}) async => '',
    onRenameCategory: (_, _) {},
    onDeleteCategory: (_) {},
    onMoveCategory: (_, _) {},
    onImport: (_) {},
    onImportConfirm: (_) {},
    onImportCancel: () {},
    onExport: (_) {},
    onPickExportFolder: () async => null,
    onExportAll: () {},
    onRescan: () {},
    onOpenFolder: (_) {},
    onReplacePreview: (_) {},
    onCopyImage: (_) {},
    onDelete: (_) {},
    onTrayRemove: (_) {},
    onTrayClear: () {},
    onPauseVibes: (_) {},
    onGoGeneration: () {},
    onSwitchModel: () {},
  );
}

/// 生图页“从库添加”选择器（`VibeSelectorDialog` / `PreciseRefSelectorDialog` 的新外观）。
/// 选择器自己做搜索和分类筛选（条目全量给出）。
@immutable
class RefsPickerData {
  const RefsPickerData({
    required this.kind,
    required this.now,
    required this.model,
    required this.entries,
    this.costs = const RefsCosts(),
    this.categories = const [],
    this.recent = const [],
    this.inUse = 0,
    this.single = false,
  });
  final RefsKind kind;
  final DateTime now;
  final RefsModel model;

  /// 全部条目（按最近使用排好）；[RefsEntry.inGeneration] 标“已在用”。
  final List<RefsEntry> entries;
  final RefsCosts costs;
  final List<RefsCategory> categories;

  /// 最近用过的条目 key（最多 7 个）。
  final List<String> recent;

  /// 生图页现在已有几个（Vibe 计 16 上限，精准参考算费用）。
  final int inUse;

  /// 单选（图生图从精准参考库选底图）：点一张直接确认。
  final bool single;
}

@immutable
class RefsPickerActions {
  const RefsPickerActions({
    required this.onConfirm,
    required this.onClose,
    required this.onOpenLibrary,
  });

  /// 追加（[replace] = false）或替换现有（`VibeSelectionResult.shouldReplace`）。
  final void Function(List<String> keys, {required bool replace}) onConfirm;
  final VoidCallback onClose;

  /// 关掉选择器并打开对应的库页。
  final VoidCallback onOpenLibrary;
}
