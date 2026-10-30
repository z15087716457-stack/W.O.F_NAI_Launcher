import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 大图查看器（本地画廊大图 · 生图页打开的生成结果）：界面只认这份契约。
///
/// 口径约定：
/// - 胶片条 [ViewerViewData.items] 是当前张前后的一段窗口（按当前范围的排序），不是整个图库；
///   位置 [ViewerViewData.position] / [ViewerViewData.total] 按整个范围算。左右键走 [ViewerActions.onStep]，
///   到窗口边缘由接线方续读，界面只要求 [ViewerViewData.currentKey] 始终在 [ViewerViewData.items] 里。
/// - 缩放、平移、小地图、快捷键表、窄窗口抽屉、确认框都是界面自己的状态，不回调。
/// - 元数据由接线方读好放进 [ViewerViewData.detail]（只给当前张）；读的过程中 `status = loading`。
/// - 时间一律给本地时间的 [DateTime]，界面按 [ViewerViewData.now] 写“2 分钟前 / 8月28日”。
/// - 模型、采样器给友好名（`ImageModels.modelDisplayNames` / `Samplers.samplerDisplayNames`），界面不再映射。

enum ViewerMode {
  /// 本地画廊：收藏 / 在文件夹中显示 / 删除 / 更多，主按钮“复用参数”。
  gallery,

  /// 生图页（历史栏 / 画布 / 保存后预览）：没有收藏和删除，主按钮“保存到图库”。
  generation,
}

/// 当前范围的排序（`GallerySortField`）。按时间排时胶片条按天分隔。
enum ViewerSort { modified, created, fileName, fileSize, dimensions }

/// 顶栏位置后面的范围文字：“全部图片 · 按修改时间”“氛围图 · 按修改时间”。
@immutable
class ViewerScope {
  const ViewerScope({this.name, this.sort});

  /// 筛选名（文件夹、收藏集、搜索词……）；null = 全部图片。
  final String? name;

  /// null = 不写排序。
  final ViewerSort? sort;
}

@immutable
class ViewerItem {
  const ViewerItem({
    required this.key,
    required this.width,
    required this.height,
    this.thumb,
    this.image,
    this.date,
    this.favorite = false,
    this.missing = false,
    this.protected = false,
    this.saved = false,
    this.path,
    this.sizeBytes,
  });

  /// 本地画廊用文件路径，生成结果用任务 id。
  final String key;

  /// 原图像素尺寸：决定胶片条比例、“适应”比例和 1:1。
  final int width;
  final int height;

  /// 胶片条缩略图；读原图时模糊垫底。
  final ImageProvider? thumb;

  /// 原图（大图限制解码尺寸由接线方用 `ResizeImage` 做）。null = 还在读，界面显示模糊缩略图 + “读取原图”。
  final ImageProvider? image;

  /// 修改时间（本地画廊）/ 生成时间（生成结果）：胶片条按天分隔、生成结果写“2 分钟前”。
  final DateTime? date;
  final bool favorite;

  /// 文件已经被移动、改名或删除。
  final bool missing;

  /// 受保护的图：删除前先确认（其他图直接移到回收站，带撤销）。
  final bool protected;

  /// 生成结果已经保存到图库（主按钮变成“已保存”）。
  final bool saved;

  /// 完整路径（找不到时显示）。
  final String? path;

  /// 文件大小（读原图时显示“读取原图 · 1.95 MB”）。
  final int? sizeBytes;

  double get aspect => width > 0 && height > 0 ? width / height : 1;
}

enum ViewerMetaStatus {
  /// 正在读元数据：参数和提示词显示骨架。
  loading,

  /// 没有 NovelAI 生成信息：复用参数灰掉，其他操作照常。
  none,
  ready,
}

/// 角色（`characterInfos`）：位置给 0–1 的中心点，界面换算成 5 × 5 格（A1–E5）。
@immutable
class ViewerCharacter {
  const ViewerCharacter({
    required this.prompt,
    this.negative = '',
    this.x,
    this.y,
  });
  final String prompt;
  final String negative;
  final double? x;
  final double? y;
}

/// 图里带的 Vibe（`vibeReferences`）：可以存进 Vibe 库。
@immutable
class ViewerVibe {
  const ViewerVibe({
    required this.name,
    this.thumb,
    this.strength,
    this.infoExtracted,
  });
  final String name;
  final ImageProvider? thumb;
  final double? strength;
  final double? infoExtracted;
}

/// 当前张的详情。文件字段在生成结果里可以为空。
@immutable
class ViewerDetail {
  const ViewerDetail({
    required this.key,
    required this.status,
    this.fileName,
    this.folder,
    this.model,
    this.seed,
    this.sampler,
    this.steps,
    this.scale,
    this.noiseSchedule,
    this.cfgRescale,
    this.smea,
    this.qualityTags,
    this.preciseCount = 0,
    this.prompt = '',
    this.characters = const [],
    this.negative = '',
    this.vibes = const [],
  });

  final String key;
  final ViewerMetaStatus status;
  final String? fileName;

  /// 所在文件夹（相对图库根目录，或完整路径）。
  final String? folder;

  /// 模型友好名“NAI Diffusion V4.5”；拿不到为 null（不显示这一行）。
  final String? model;
  final int? seed;
  final String? sampler;
  final int? steps;
  final double? scale;
  final String? noiseSchedule;
  final double? cfgRescale;

  /// V3 的 SMEA：null 不显示，“ON” / “DYN”。
  final String? smea;
  final bool? qualityTags;

  /// 精准参考张数（0 不显示）。
  final int preciseCount;
  final String prompt;
  final List<ViewerCharacter> characters;
  final String negative;
  final List<ViewerVibe> vibes;
}

/// 信息栏里的一段：主提示词 / 第 i 个角色 / 负面 / 种子。复制、翻译按段走。
@immutable
class ViewerPart {
  const ViewerPart._(this.kind, [this.index = 0]);
  static const prompt = ViewerPart._(ViewerPartKind.prompt);
  static const negative = ViewerPart._(ViewerPartKind.negative);
  static const seed = ViewerPart._(ViewerPartKind.seed);
  const ViewerPart.character(int index)
    : this._(ViewerPartKind.character, index);

  final ViewerPartKind kind;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is ViewerPart && other.kind == kind && other.index == index;
  @override
  int get hashCode => Object.hash(kind, index);
  @override
  String toString() =>
      kind == ViewerPartKind.character ? 'character($index)' : kind.name;
}

enum ViewerPartKind { prompt, character, negative, seed }

/// 某段提示词的翻译：有 [text] 时界面用译文替换原文显示（图标点亮），再点一次 [ViewerActions.onToggleTranslation] 收回。
@immutable
class ViewerTranslation {
  const ViewerTranslation({this.busy = false, this.text, this.error});
  final bool busy;
  final String? text;
  final String? error;
}

/// 收藏集（`ImageCollection`），按树序拍平；[member] 为当前张是否在里面。
@immutable
class ViewerCollection {
  const ViewerCollection({
    required this.id,
    required this.name,
    this.member = false,
    this.depth = 0,
  });
  final String id;
  final String name;
  final bool member;
  final int depth;
}

/// 刚移到回收站的那张：底部提示带撤销，界面 6 秒后调 [ViewerActions.onDismissUndo]。
@immutable
class ViewerUndo {
  const ViewerUndo({required this.id, required this.fileName});

  /// 每次删除换一个 id（连删两张时计时重来）。
  final String id;
  final String fileName;
}

/// 操作：信息栏底部、更多菜单。界面只显示 [ViewerViewData.actions] 里有的。
enum ViewerAction {
  /// 复用参数（全量导入到生图页，`Ctrl R`）。
  reuse,
  img2img,
  styleTransfer,
  preciseRef,

  /// 存入精准参考库。
  saveToRefLibrary,
  krita,
  upscale,
  copyImage,

  /// 复制文件路径。
  copyPath,

  /// 复制全部提示词（主提示词 + 角色，`fullPrompt`）。
  copyAllPrompts,
  saveAsBlock,
  moveTo,
  copyTo,
  showInFolder,

  /// 生成结果保存到图库。
  save,
}

/// 快捷键命令。接线方把设置里的快捷键（`ShortcutIds` 的大图项）换成 [SingleActivator] 给 [ViewerViewData.keys]，
/// 没给的用 [ViewerKeys.defaults]；快捷键表按这里显示。
enum ViewerCommand {
  previous,
  next,
  first,
  last,
  toggleInfo,
  fullscreen,
  close,
  zoomIn,
  zoomOut,
  zoomFit,
  zoomActual,
  reuse,
  copyPrompt,
  favorite,
  delete,
  undo,
  save,
  help,
}

abstract final class ViewerKeys {
  static const defaults = <ViewerCommand, List<SingleActivator>>{
    ViewerCommand.previous: [SingleActivator(LogicalKeyboardKey.arrowLeft)],
    ViewerCommand.next: [SingleActivator(LogicalKeyboardKey.arrowRight)],
    ViewerCommand.first: [SingleActivator(LogicalKeyboardKey.home)],
    ViewerCommand.last: [SingleActivator(LogicalKeyboardKey.end)],
    ViewerCommand.toggleInfo: [SingleActivator(LogicalKeyboardKey.keyI)],
    ViewerCommand.fullscreen: [SingleActivator(LogicalKeyboardKey.f11)],
    ViewerCommand.close: [SingleActivator(LogicalKeyboardKey.escape)],
    ViewerCommand.zoomIn: [
      SingleActivator(LogicalKeyboardKey.equal),
      SingleActivator(LogicalKeyboardKey.numpadAdd),
    ],
    ViewerCommand.zoomOut: [
      SingleActivator(LogicalKeyboardKey.minus),
      SingleActivator(LogicalKeyboardKey.numpadSubtract),
    ],
    ViewerCommand.zoomFit: [SingleActivator(LogicalKeyboardKey.digit0)],
    ViewerCommand.zoomActual: [SingleActivator(LogicalKeyboardKey.digit1)],
    ViewerCommand.reuse: [
      SingleActivator(LogicalKeyboardKey.keyR, control: true),
    ],
    ViewerCommand.copyPrompt: [
      SingleActivator(LogicalKeyboardKey.keyC, control: true),
    ],
    ViewerCommand.favorite: [SingleActivator(LogicalKeyboardKey.keyF)],
    ViewerCommand.delete: [SingleActivator(LogicalKeyboardKey.delete)],
    ViewerCommand.undo: [
      SingleActivator(LogicalKeyboardKey.keyZ, control: true),
    ],
    ViewerCommand.save: [
      SingleActivator(LogicalKeyboardKey.keyS, control: true),
    ],
    ViewerCommand.help: [
      SingleActivator(LogicalKeyboardKey.slash, shift: true),
    ],
  };
}

@immutable
class ViewerViewData {
  const ViewerViewData({
    required this.mode,
    required this.items,
    required this.currentKey,
    required this.now,
    this.libraryReadOnly = false,
    this.position = 0,
    this.total = 0,
    this.scope,
    this.detail,
    this.actions = const {},
    this.infoOpen = true,
    this.fullscreen = false,
    this.kritaConnected = false,
    this.highlight = true,
    this.collections,
    this.translations = const {},
    this.undo,
    this.keys = ViewerKeys.defaults,
    this.zoomHintSeen = false,
    this.backLabel,
  });

  final ViewerMode mode;
  final bool libraryReadOnly;

  /// 胶片条窗口（按范围的排序）。
  final List<ViewerItem> items;
  final String currentKey;
  final DateTime now;

  /// 当前张在整个范围里的位置（从 0 起）和范围总数。生成结果不用（写“本批 N 张”）。
  final int position;
  final int total;
  final ViewerScope? scope;

  /// 当前张的详情；null 等同 loading。
  final ViewerDetail? detail;

  /// 这次打开提供哪些操作（生成结果没有删除、收藏集这类）。
  final Set<ViewerAction> actions;

  /// 信息栏开关（宽窗口；按 `I` 切换，接线方记住）。窄窗口时信息栏是抽屉，默认收起，不回调。
  final bool infoOpen;

  /// 真全屏：接线方藏起主导航和窗口按钮（`windowManager.setFullScreen`），界面藏起顶栏和信息栏。
  final bool fullscreen;

  /// Krita 没连接时“发送到 Krita”灰掉。
  final bool kritaConnected;

  /// 提示词强调高亮（设置里的开关）。
  final bool highlight;

  /// 当前张的收藏集；null = 还在读（菜单里只有“收藏”一项）。
  final List<ViewerCollection>? collections;

  /// 当前张各段的翻译。
  final Map<ViewerPart, ViewerTranslation> translations;
  final ViewerUndo? undo;
  final Map<ViewerCommand, List<SingleActivator>> keys;

  /// 第一次放大时的操作提示看过没有（看过不再出）。
  final bool zoomHintSeen;

  /// 顶栏返回按钮的文字；null 按 [mode] 写“本地画廊 / 生图”（画风探索传“画风探索”）。
  final String? backLabel;

  ViewerItem? get current =>
      items.where((i) => i.key == currentKey).firstOrNull;
}

/// 回调。`key` 都是 [ViewerItem.key]。
@immutable
class ViewerActions {
  const ViewerActions({
    required this.onClose,
    required this.onSelect,
    required this.onStep,
    required this.onJump,
    required this.onLoadMore,
    required this.onInfoChanged,
    required this.onFullscreenChanged,
    required this.onSetFavorite,
    required this.onToggleCollection,
    required this.onCreateCollection,
    required this.onDelete,
    required this.onUndoDelete,
    required this.onDismissUndo,
    required this.onAction,
    required this.onCopy,
    required this.onToggleTranslation,
    required this.onSaveVibe,
    required this.onZoomHintSeen,
    required this.onCaptionOverStage,
  });

  /// 返回 / 关闭。[keyboard] 为 true 是 Esc 触发的：Windows 上窗口刚拿回焦点时接线方可以忽略
  /// （沿用旧查看器 `_shouldSuppressEscCloseOnWindows`）。
  final void Function({required bool keyboard}) onClose;

  /// 点胶片条里的一张。
  final ValueChanged<String> onSelect;

  /// 上一张 / 下一张（±1）。到范围头尾时不动。
  final ValueChanged<int> onStep;

  /// 第一张 / 最后一张（[last] 为 true 是最后一张）。
  final void Function({required bool last}) onJump;

  /// 胶片条滚到窗口边缘，往前（false）/ 往后（true）续读缩略图。
  final void Function({required bool forward}) onLoadMore;
  final ValueChanged<bool> onInfoChanged;
  final ValueChanged<bool> onFullscreenChanged;

  /// 收藏（`F` 直接切换；菜单里的“收藏”一项）。
  final void Function(String key, bool value) onSetFavorite;
  final void Function(String key, String collectionId, bool member)
  onToggleCollection;

  /// 新建收藏集并把当前张放进去（接线方弹输入框）。
  final ValueChanged<String> onCreateCollection;

  /// 移到回收站。受保护的图界面先确认再调。成功后接线方把当前张换成下一张（删的是最后一张换上一张，
  /// 窗口里没图了就关闭），总数减一，给 [ViewerViewData.undo]。
  final ValueChanged<String> onDelete;
  final VoidCallback onUndoDelete;
  final VoidCallback onDismissUndo;
  final void Function(String key, ViewerAction action) onAction;

  /// 复制某一段（提示词 / 角色 / 负面 / 种子），接线方负责剪贴板和提示。
  final void Function(String key, ViewerPart part) onCopy;
  final void Function(String key, ViewerPart part) onToggleTranslation;

  /// 把图里第 [index] 个 Vibe 存进 Vibe 库（接线方弹 `SaveVibeDialog`）。
  final void Function(String key, int index) onSaveVibe;
  final VoidCallback onZoomHintSeen;

  /// 窗口按钮是否压在黑底舞台上（信息栏收起、窄窗口）：true 时接线方把窗口按钮换成浅色图标，
  /// false 时（信息栏停靠在右边）跟主题。全屏时窗口按钮本来就藏起来，报 false。变化时才调。
  final ValueChanged<bool> onCaptionOverStage;

  static final none = ViewerActions(
    onClose: ({required keyboard}) {},
    onSelect: (_) {},
    onStep: (_) {},
    onJump: ({required last}) {},
    onLoadMore: ({required forward}) {},
    onInfoChanged: (_) {},
    onFullscreenChanged: (_) {},
    onSetFavorite: (_, _) {},
    onToggleCollection: (_, _, _) {},
    onCreateCollection: (_) {},
    onDelete: (_) {},
    onUndoDelete: () {},
    onDismissUndo: () {},
    onAction: (_, _) {},
    onCopy: (_, _) {},
    onToggleTranslation: (_, _) {},
    onSaveVibe: (_, _) {},
    onZoomHintSeen: () {},
    onCaptionOverStage: (_) {},
  );
}
