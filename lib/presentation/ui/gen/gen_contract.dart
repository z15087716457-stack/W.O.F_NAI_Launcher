import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// 生图页（方案 A 精修）：界面只认这份契约。
///
/// 口径约定：
/// - 左栏 = 顶栏胶囊 + 提示词 / 角色 / 参考图 / 图像四个模块 + 参数条（含抽屉）+ 生成条；中间画布；右边历史栏。
///   块库侧栏（`BlocksDock`，块系统已做好）由接线方当成 [GenSlots.dock] 传进来，夹在左栏和画布之间。
/// - **提示词编辑器不在本页画**：基础提示词正 / 负面、每个角色正 / 负面的那块可编辑文字（药丸、权重高亮、
///   自动补全、翻译叠字）由接线方用现有编辑器通过 [GenSlots.editor] 填进来。界面画编辑器四周的一切：
///   页签、工具按钮、右上角清空 ×、底部预设行、token 条。编辑器本身不要带内边距和底色。
/// - **画布引擎可选**：界面自带一个“舞台”，把 [GenCanvasData.focus] 这一组图按原型摆在画布中间。
///   想保留无限画布（平移、缩放、惯性、按组排布）就传 [GenSlots.canvas]，每张图用参数里给的 `tile` 画，
///   三条浮动工具条、空 / 失败 / 定位编辑这些叠层仍由界面画在上面。
/// - 模型差异不在界面里判断：哪些控件显示，全看数据里对应字段是不是 null（例如 [GenRefsData.vibes]
///   为 null = 当前模型不支持风格迁移，整行不显示）。
/// - 界面自己管、不回调的：每个角色卡当前看正面还是负面、参考图三行展开没展开、参数抽屉开没开、
///   历史栏多选和勾选、锁定滚动、菜单和弹层。要记住的只有 [GenLayout] 里的宽度和开关。
/// - 快捷键（生成、取消、清空提示词、切正负面……）用户可以自定义，由接线方注册，界面只处理 Esc 关弹层。
/// - 时间一律给本地时间；数字（种子、宽高、Anlas）给原始值，界面负责千分位和等宽数字。

/// 左右两栏的宽度和开关（拖动松手、点折叠时回调 [GenActions.onLayoutChanged]）。
@immutable
class GenLayout {
  const GenLayout({
    this.leftOpen = true,
    this.leftWidth = 420,
    this.historyOpen = true,
    this.historyWidth = 210,
    this.dockOpen = false,
  });

  /// 左栏 352–560（`layoutState.webLeftPanelWidth`）；收起时只剩 40 宽的竖条。
  final bool leftOpen;
  final double leftWidth;

  /// 历史栏 200–400（`layoutState.rightPanelWidth`）；收起时只剩 40 宽的竖条。
  final bool historyOpen;
  final double historyWidth;

  /// 块库侧栏开着（`layoutState.blockLibraryPanelOpen`），[GenSlots.dock] 显示在左栏右边。
  final bool dockOpen;

  static const minLeft = 352.0;
  static const maxLeft = 560.0;
  static const minHistory = 200.0;
  static const maxHistory = 400.0;

  GenLayout copyWith({
    bool? leftOpen,
    double? leftWidth,
    bool? historyOpen,
    double? historyWidth,
    bool? dockOpen,
  }) => GenLayout(
    leftOpen: leftOpen ?? this.leftOpen,
    leftWidth: leftWidth ?? this.leftWidth,
    historyOpen: historyOpen ?? this.historyOpen,
    historyWidth: historyWidth ?? this.historyWidth,
    dockOpen: dockOpen ?? this.dockOpen,
  );

  @override
  bool operator ==(Object other) =>
      other is GenLayout &&
      other.leftOpen == leftOpen &&
      other.leftWidth == leftWidth &&
      other.historyOpen == historyOpen &&
      other.historyWidth == historyWidth &&
      other.dockOpen == dockOpen;

  @override
  int get hashCode =>
      Object.hash(leftOpen, leftWidth, historyOpen, historyWidth, dockOpen);

  @override
  String toString() =>
      'GenLayout(leftOpen: $leftOpen, leftWidth: $leftWidth, '
      'historyOpen: $historyOpen, historyWidth: $historyWidth, dockOpen: $dockOpen)';
}

// ───────────────────────── 顶栏 ─────────────────────────

/// 模型菜单的一项（`ImageModels.allModels`）。
@immutable
class GenModel {
  const GenModel({
    required this.id,
    required this.name,
    this.description,
    this.legacy = false,
  });

  /// `nai-diffusion-4-5-full` 这类原始 id。
  final String id;

  /// 胶囊里的短名（“V4.5 Full”，`ModelDisplay.shortNameOf`）。
  final String name;

  /// 菜单第二行（`ModelDisplay.descriptionOf`），没有就 null。
  final String? description;

  /// 归在“旧模型”分组（`ModelDisplay.groupOf == legacy`）。
  final bool legacy;
}

/// 账号额度胶囊。
@immutable
class GenQuota {
  const GenQuota({this.opusPercent, this.opusTip, this.anlas});

  /// Opus 免费额度剩余百分比（`usage.percent`，V5 才有）；null = 不显示这一格。
  final double? opusPercent;

  /// Opus 格的悬停说明（`OpusUsageChip._tooltip`）。
  final String? opusTip;

  /// Anlas 余额；null = 还没拿到（显示“—”）。
  final int? anlas;
}

/// 桥接（Krita / Agent）状态小图标，放在提示词页签后面（`AgentBridgeIndicator`）。
enum GenBridgePhase { idle, working, synced, failed }

@immutable
class GenBridge {
  const GenBridge({required this.phase, required this.label});
  final GenBridgePhase phase;

  /// 悬停说明（`bridgeAgentStatus`）。
  final String label;
}

// ───────────────────────── 提示词 ─────────────────────────

/// 编辑器槽位要填哪一块：[character] 为 null 是基础提示词，否则是第几个角色（0 起）。
@immutable
class GenEditorTarget {
  const GenEditorTarget.base({this.negative = false, this.fullscreen = false})
    : character = null;
  const GenEditorTarget.character(
    int this.character, {
    this.negative = false,
    this.fullscreen = false,
  });

  final int? character;
  final bool negative;

  /// 在“全屏编辑”弹窗里（编辑器可以撑满、字号可以大一号）。
  final bool fullscreen;

  bool get isBase => character == null;

  @override
  bool operator ==(Object other) =>
      other is GenEditorTarget &&
      other.character == character &&
      other.negative == negative &&
      other.fullscreen == fullscreen;

  @override
  int get hashCode => Object.hash(character, negative, fullscreen);

  @override
  String toString() =>
      '${character == null ? 'base' : 'char$character'}'
      '${negative ? '-neg' : ''}${fullscreen ? '-full' : ''}';
}

/// token 用量（`PromptTokenCount`）：底部 3px 长条，超过 90% 变琥珀色，超限变红。
@immutable
class GenTokens {
  const GenTokens(this.used, this.limit);
  final int used;
  final int limit;
}

/// 下拉里的一项（质量词预设、负面预设、采样器、噪声调度……）。
@immutable
class GenOption {
  const GenOption({required this.id, required this.label, this.detail});
  final String id;
  final String label;

  /// 菜单右侧的弱色说明（推荐 / 描述）。
  final String? detail;
}

/// 页签悬停时显示的“最终发送”预览的一段（`_PositivePromptTooltip` 的各节）。
@immutable
class GenPreviewSection {
  const GenPreviewSection({required this.label, required this.text});

  /// “主提示词 / 质量词 / 角色 1 …”。
  final String label;
  final String text;
}

/// 提示词卡头部“模块与开关”菜单里的状态（`layoutState.*ToolPinned` 和提示词设置）。
@immutable
class GenPromptTools {
  const GenPromptTools({
    this.palettePinned = false,
    this.dockPinned = true,
    this.translatePinned = true,
    this.agentPinned = true,
    this.autoFormat = true,
    this.highlight = true,
    this.sdConvert = false,
    this.related = true,
  });

  /// 积木板按钮钉在头部。
  final bool palettePinned;

  /// 块库侧栏按钮钉在头部。
  final bool dockPinned;

  /// 翻译按钮钉在头部。
  final bool translatePinned;

  /// NAI Agent 入口钉在头部；运行时由接线方提供。
  final bool agentPinned;

  /// 自动格式化（`autoFormatPromptSettingsProvider`）。
  final bool autoFormat;

  /// 强调高亮（`highlightEmphasisSettingsProvider`）。
  final bool highlight;

  /// SD 语法自动转换（`sdSyntaxAutoConvertSettingsProvider`）。
  final bool sdConvert;

  /// 共现推荐（`autocompleteSettings.relatedTagsEnabled`）。
  final bool related;
}

enum GenPromptTool {
  palettePinned,
  dockPinned,
  translatePinned,
  agentPinned,
  autoFormat,
  highlight,
  sdConvert,
  related,
}

/// 翻译按钮（`promptTranslationCoordinator`）。
@immutable
class GenTranslate {
  const GenTranslate({this.busy = false, this.showing = false, this.route});

  /// 正在翻译：图标转圈、按钮不可点。
  final bool busy;

  /// 当前这一面有译文正在显示（再点一下 = 全部还原）。
  final bool showing;

  /// “DeepSeek · deepseek-chat”这类线路名；null = 没配翻译模型（点了先引导去设置）。
  final String? route;
}

@immutable
class GenPromptData {
  const GenPromptData({
    this.negative = false,
    this.positiveTokens = const GenTokens(0, 512),
    this.negativeTokens = const GenTokens(0, 512),
    this.qualityPresets = const [],
    this.qualityPreset,
    this.ucPresets = const [],
    this.ucPreset,
    this.transparent,
    this.positivePreview = const [],
    this.negativePreview = const [],
    this.tools = const GenPromptTools(),
    this.translate = const GenTranslate(),
    this.bridge,
  });

  /// 当前看负面页签（快捷键“切换正 / 负面”也要能切，所以由接线方管）。
  final bool negative;
  final GenTokens positiveTokens;
  final GenTokens negativeTokens;

  /// 质量词预设（`qualityPresetNotifierProvider`），正面页签底部右侧的下拉。
  final List<GenOption> qualityPresets;
  final String? qualityPreset;

  /// 负面预设（`ucPresetNotifierProvider`），负面页签底部右侧的下拉。
  final List<GenOption> ucPresets;
  final String? ucPreset;

  /// 透明背景（`spec.transparency`，V5 才有）：null = 不显示这一格。
  final bool? transparent;

  /// 页签悬停预览：最终发出去的正面 / 负面，按节给。
  final List<GenPreviewSection> positivePreview;
  final List<GenPreviewSection> negativePreview;

  final GenPromptTools tools;
  final GenTranslate translate;

  /// 桥接开着才给（`kritaBridge.enabled`）。
  final GenBridge? bridge;

  GenTokens get tokens => negative ? negativeTokens : positiveTokens;
}

// ───────────────────────── 角色 ─────────────────────────

enum GenGender { female, male, other }

@immutable
class GenCharacter {
  const GenCharacter({
    required this.id,
    this.name,
    this.gender = GenGender.female,
    this.enabled = true,
    this.positiveTokens = const GenTokens(0, 512),
    this.negativeTokens = const GenTokens(0, 512),
    this.position,
  });

  final String id;

  /// 用户起的名字；null 显示“角色 N”。
  final String? name;
  final GenGender gender;

  /// 参与生成（卡片右上角的勾）。关掉时整张卡变淡。
  final bool enabled;
  final GenTokens positiveTokens;
  final GenTokens negativeTokens;

  /// 自定义定位时的位置，0–1（V4.5 吸附到 5 × 5 格中心 0.1 / 0.3 / 0.5 / 0.7 / 0.9）；
  /// null = 还没放（按 AI 选择处理）。
  final Offset? position;
}

@immutable
class GenCharactersData {
  const GenCharactersData({
    this.list = const [],
    this.aiPosition = true,
    this.max = 6,
    this.freeform = false,
  });

  final List<GenCharacter> list;

  /// 定位：AI 选择（`globalAiChoice`）还是自定义。
  final bool aiPosition;

  /// 上限（`spec.maxCharacters`：V5 32、V4.5 6）。
  final int max;

  /// V5 自由坐标；false = V4.5 的 5 × 5 网格（`spec.freeformCharacterPosition`）。
  final bool freeform;
}

// ───────────────────────── 参考图 ─────────────────────────

/// 图生图（`Img2ImgPanel`）。[image] 为 null = 还没放图。
@immutable
class GenImg2Img {
  const GenImg2Img({
    this.image,
    this.width = 0,
    this.height = 0,
    this.strength = .7,
    this.noise = 0,
    this.enabled = true,
    this.mask = GenMask.none,
    this.inpaintStrength = 1,
  });

  final ImageProvider? image;
  final int width;
  final int height;

  /// 强度 0–1（默认 0.7）、噪声 0–1（默认 0）。
  final double strength;
  final double noise;

  /// 开关（`img2img_enabled`）：关掉时参数保留但这次不发送。
  final bool enabled;

  /// 局部重绘蒙版：没有 / 画好了（显示“局部重绘强度”）。
  final GenMask mask;
  final double inpaintStrength;

  bool get hasImage => image != null;
}

enum GenMask { none, ready }

enum GenVibeState { encoded, pending, encoding }

/// 一个风格迁移参考（`VibeReference`）。
@immutable
class GenVibe {
  const GenVibe({
    required this.id,
    required this.thumb,
    required this.name,
    this.strength = .6,
    this.info = 1,
    this.enabled = true,
    this.state = GenVibeState.encoded,
    this.encodeCost = 2,
  });

  final String id;
  final ImageProvider thumb;
  final String name;

  /// 参考强度 / 信息提取，0–1。已编码的 Vibe 改信息提取要重新编码（界面会提示）。
  final double strength;
  final double info;
  final bool enabled;
  final GenVibeState state;

  /// 待编码时编码一次要的 Anlas。
  final int encodeCost;
}

@immutable
class GenRecentVibe {
  const GenRecentVibe({
    required this.id,
    required this.thumb,
    required this.name,
  });
  final String id;
  final ImageProvider thumb;
  final String name;
}

@immutable
class GenVibesData {
  const GenVibesData({
    this.list = const [],
    this.max = 16,
    this.freeCount = 4,
    this.extraCost = 2,
    this.normalize = true,
    this.recent = const [],
  });

  final List<GenVibe> list;
  final int max;

  /// 超过 [freeCount] 个后每个多 [extraCost] Anlas（`AnlasCalculator`）。
  final int freeCount;
  final int extraCost;

  /// 标准化强度（`normalizeVibeStrength`）。
  final bool normalize;

  /// 最近用过的 Vibe（`referencePanelNotifierProvider` 的 `recentEntries`），点一下加回来。
  final List<GenRecentVibe> recent;
}

enum GenPreciseType { character, style, both }

/// 一个精准参考（`PreciseReference`）。
@immutable
class GenPrecise {
  const GenPrecise({
    required this.id,
    required this.thumb,
    this.type = GenPreciseType.character,
    this.strength = 1,
    this.fidelity = 1,
    this.enabled = true,
  });

  final String id;
  final ImageProvider thumb;
  final GenPreciseType type;
  final double strength;
  final double fidelity;
  final bool enabled;
}

@immutable
class GenPreciseData {
  const GenPreciseData({this.list = const [], this.costEach = 5});
  final List<GenPrecise> list;

  /// 每张多少 Anlas（`AnlasCalculator`）。
  final int costEach;
}

@immutable
class GenRefsData {
  const GenRefsData({
    this.img2img = const GenImg2Img(),
    this.vibes,
    this.precise,
    this.dropHover,
  });

  final GenImg2Img img2img;

  /// null = 当前模型不支持风格迁移（`spec.vibetransfer`），整行不显示。
  final GenVibesData? vibes;

  /// null = 当前模型不支持精准参考（`spec.characterReferences`）。
  final GenPreciseData? precise;

  /// 文件正拖在哪一行上（接线方的 [GenSlots.drop] 报进出），界面画投放高亮。
  final GenDropTarget? dropHover;
}

// ───────────────────────── 图像 ─────────────────────────

enum GenSizeGroup { normal, large, wallpaper, small, custom }

enum GenOrientation { portrait, landscape, square }

/// 一个尺寸预设（`ResolutionPreset.presets`）。
@immutable
class GenSizePreset {
  const GenSizePreset(this.group, this.orientation, this.width, this.height);
  final GenSizeGroup group;
  final GenOrientation orientation;
  final int width;
  final int height;
}

@immutable
class GenImageData {
  const GenImageData({
    this.width = 832,
    this.height = 1216,
    this.presets = const [],
    this.count = 1,
    this.maxCount = 4,
    this.repeat = 1,
    this.maxRepeat = 99,
  });

  final int width;
  final int height;
  final List<GenSizePreset> presets;

  /// 每次张数（`nSamples`）1–[maxCount]。
  final int count;
  final int maxCount;

  /// 重复请求次数（`requestCount`）1–[maxRepeat]。
  final int repeat;
  final int maxRepeat;
}

// ───────────────────────── 参数 ─────────────────────────

@immutable
class GenSmea {
  const GenSmea({this.auto = true, this.smea = false, this.dyn = false});
  final bool auto;
  final bool smea;
  final bool dyn;
}

@immutable
class GenParamsData {
  const GenParamsData({
    this.steps = 28,
    this.maxSteps = 50,
    this.scale = 5,
    this.maxScale = 10,
    this.cfgRescale = 0,
    this.seed,
    this.seedPinned = false,
    this.sampler = 'k_dpmpp_2m_sde',
    this.samplers = const [],
    this.noise,
    this.noises = const [],
    this.varietyPlus,
    this.decrisp,
    this.smea,
  });

  final int steps;
  final int maxSteps;
  final double scale;
  final double maxScale;
  final double cfgRescale;

  /// 当前种子；随机且还没生成过时为 null（显示“随机”）。
  final int? seed;

  /// 种子固定（`seed != -1`）。
  final bool seedPinned;

  final String sampler;

  /// 采样器（`Samplers.samplersForModel`），[GenOption.detail] 非 null 的归在“推荐”分组。
  final List<GenOption> samplers;

  /// 噪声调度；null = 当前模型没有这一项（`spec.noiseSchedule`）。
  final String? noise;
  final List<GenOption> noises;

  /// Variety+；null = 当前模型没有。
  final bool? varietyPlus;

  /// Decrisp（V3）；null = 没有。
  final bool? decrisp;

  /// SMEA / DYN（V3 + 非 DDIM）；null = 没有。
  final GenSmea? smea;

  String get samplerLabel =>
      samplers.where((s) => s.id == sampler).firstOrNull?.label ?? sampler;
}

/// 参数抽屉里能改的项。
enum GenParam { steps, scale, cfgRescale }

// ───────────────────────── 生成 ─────────────────────────

enum GenRunState {
  /// 可以点。
  ready,

  /// 生成中：按钮变“停止”，带整批进度。
  generating,

  /// 冷却中（`generationCooldownProvider`）。
  cooldown,

  /// 不能点，原因见 [GenGenerateData.blocked]（没写提示词、正在放大……）。
  blocked,
}

@immutable
class GenGenerateData {
  const GenGenerateData({
    this.state = GenRunState.ready,
    this.label = '',
    this.cost,
    this.insufficient = false,
    this.done = 0,
    this.total = 1,
    this.progress,
    this.cooldown = 0,
    this.blocked,
  });

  final GenRunState state;

  /// 按钮文案（`GenerateButtonCopy.pick`，含彩蛋和图生图 / 增强的变体），由接线方算好。
  final String label;

  /// 这次要花的 Anlas；null = 正在算。Opus 免费时给 0。
  final int? cost;

  /// 余额不够：价格角标变红。
  final bool insufficient;

  /// 生成中：第几张已完成 / 一共几张，整批进度 0–1（null = 还没开始出图）。
  final int done;
  final int total;
  final double? progress;

  /// 冷却剩余秒数。
  final int cooldown;

  /// [GenRunState.blocked] 时的原因（悬停说明）。
  final String? blocked;
}

// ───────────────────────── 画布 ─────────────────────────

enum GenTileState {
  /// 出图了。
  done,

  /// 排队中（还没开始）：三点跳动占位。
  pending,

  /// 正在出：有流式预览就模糊垫着，带进度。
  streaming,

  /// 这一张失败了。
  failed,
}

/// 画布上的一张（一次请求里的一张图，或它的占位）。
@immutable
class GenTile {
  const GenTile({
    required this.id,
    required this.width,
    required this.height,
    this.image,
    this.originalImage,
    this.inpaintMaskBytes,
    this.preview,
    this.state = GenTileState.done,
    this.progress,
    this.error,
  });

  final String id;
  final int width;
  final int height;
  final ImageProvider? image;
  final ImageProvider? originalImage;
  final Uint8List? inpaintMaskBytes;

  /// 流式预览（`streamPreview`）。
  final ImageProvider? preview;
  final GenTileState state;
  final double? progress;
  final String? error;
}

/// 一组 = 一次生成请求（`generationRunId`）。
@immutable
class GenGroup {
  const GenGroup({required this.id, required this.tiles});
  final String id;
  final List<GenTile> tiles;
}

/// 浮动工具条要用的“当前这张”（焦点组里选中的那张）。
@immutable
class GenFocusInfo {
  const GenFocusInfo({
    required this.tileId,
    required this.width,
    required this.height,
    this.seed,
    this.pinned = false,
    this.variationsCost,
    this.variationsCostLoading = false,
    this.enhanceCost,
    this.canUseAsInput = true,
    this.canCompareOriginal = false,
  });

  final String tileId;
  final int width;
  final int height;
  final int? seed;

  /// 钉在画布上（`canvasPinnedNotifierProvider`）。
  final bool pinned;

  /// “变体”要的 Anlas；0 仍显示胶囊，null = 尚无报价。
  final int? variationsCost;

  /// 首次读取图片参数时显示加载占位；结束后无报价显示“—”。
  final bool variationsCostLoading;

  /// “增强”按当前增强设置要的 Anlas（悬停提示里写；null = 不显示价格）。
  final int? enhanceCost;

  /// 能不能拿去增强 / 变体 / 放大 / 设为图生图（`canUseAsGenerationInput`，失败快照不行）。
  final bool canUseAsInput;
  final bool canCompareOriginal;
}

/// 放大按钮（`CanvasUpscaleButton`）：主按钮按记住的方案执行，箭头改方案。
@immutable
class GenUpscale {
  const GenUpscale({
    this.cost,
    this.running = false,
    this.available = true,
    this.options = const [],
    this.selected,
    this.progress,
    this.status,
  });

  /// 云端放大的非负 Anlas；null 时本地写“免费”，云端报价不可用写“—”。
  final int? cost;

  /// 正在放大：主按钮变“停止”。
  final bool running;

  /// 放大进度 0–1（本地放大有阶段百分比时给）：主按钮换成进度圈 + 百分比，
  /// 工具条下面出一条进度（[status] + 百分比 + 取消）。null = 只转圈。
  final double? progress;

  /// 进度条上的一句状态，例如“本机放大 · 推理中”（阶段：准备 / 编码 / 推理 / 解码）。
  final String? status;

  /// 方案能用（本地模型装好了 / 云端价格算得出）。
  final bool available;

  /// 方案菜单（本地模型、NovelAI 云端……）。
  final List<GenOption> options;
  final String? selected;
}

/// 透明图的垫底（`CanvasImageBackgroundNotifier.presets`，另可给 `#RRGGBB`）：只画在图片像素下面，
/// 不进保存的图。`checker` = 跟随主题的棋盘格，`none` = 不垫。
abstract final class GenBackdrop {
  static const presets = [
    'checker',
    'checkerLight',
    'checkerDark',
    'none',
    'black',
    'white',
    'gray',
    'red',
    'green',
    'blue',
  ];

  static bool isValid(String v) =>
      presets.contains(v) || RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v);
}

/// 生成失败（`image_preview.dart` 按错误码映射好的标题和说明）。
@immutable
class GenError {
  const GenError({required this.title, this.hint, this.detail});
  final String title;
  final String? hint;

  /// 原始错误（可复制）。
  final String? detail;
}

@immutable
class GenCanvasData {
  const GenCanvasData({
    this.focus,
    this.info,
    this.upscale = const GenUpscale(),
    this.error,
    this.backdrop,
    this.zoomToFill = false,
    this.positioning = false,
    this.generateShortcut = 'Ctrl+Enter',
    this.locked = false,
    this.sheet,
  });

  /// 焦点组（历史栏点了哪一批 / 刚生成的那一批）；null = 画布上什么都没有。
  final GenGroup? focus;

  /// 焦点组里选中的那张（出图了才有，浮动工具条靠它）。
  final GenFocusInfo? info;
  final GenUpscale upscale;

  /// 最近一次生成失败，画在画布下方，点“关闭”回调 [GenActions.onDismissError]。
  final GenError? error;

  /// 透明图垫底（`canvasImageBackgroundNotifierProvider`）；null = 当前模型不出透明图
  /// （`spec.transparency`），显示设置里不出这一节，图下也不垫。
  final String? backdrop;

  /// 单张图放大填满画布（`canvasZoomToFillNotifierProvider`）。
  final bool zoomToFill;

  /// 正在编辑角色位置：画布换成定位板。
  final bool positioning;

  /// 空画布上提示的快捷键（用户可能改过）。
  final String generateShortcut;

  /// 生成中：增强 / 变体 / 放大 / 局部重绘这些会再发请求的按钮不可点。
  final bool locked;

  /// 从工具条落下的面板开着哪个（对应按钮显示选中，箭头指着它）；面板本身由
  /// [GenSlots.toolSheet] 给（画布工具的 `ToolsEnhanceSheet` / `ToolsUpscaleSheet`）。
  final GenToolSheet? sheet;
}

/// 工具条落下的面板：增强（点“增强”）/ 放大设置（点放大旁的小箭头）。
enum GenToolSheet { enhance, upscale }

// ───────────────────────── 历史 ─────────────────────────

/// 历史图的角标：这张是怎么来的。
enum GenOp { upscale, enhance, variation, inpaint, img2img }

@immutable
class GenHistoryImage {
  const GenHistoryImage({
    required this.id,
    required this.thumb,
    required this.width,
    required this.height,
    this.op,
    this.favorite = false,
  });

  final String id;
  final ImageProvider thumb;
  final int width;
  final int height;
  final GenOp? op;
  final bool favorite;
}

/// 一批 = 一次请求。
@immutable
class GenBatch {
  const GenBatch({
    required this.id,
    required this.time,
    required this.images,
    this.pending = 0,
  });

  final String id;
  final DateTime time;
  final List<GenHistoryImage> images;

  /// 这一批还在出的张数（生成中的那一批放在最上面，封面用占位）。
  final int pending;

  int get count => images.length + pending;
}

@immutable
class GenHistoryData {
  const GenHistoryData({
    this.batches = const [],
    this.selected,
    this.autoSave = true,
    this.pinned = 0,
  });

  /// 新到旧。
  final List<GenBatch> batches;

  /// 当前焦点那一批（描边）。
  final String? selected;

  /// 自动保存到图库（`imageSaveSettingsNotifierProvider` 的 `autoSave`）。
  final bool autoSave;

  /// 画布上钉住的张数（> 0 时标题旁显示“钉住 N”，点了把画布飞到钉住区）。
  final int pinned;

  int get total => batches.fold(0, (s, b) => s + b.images.length);
}

// ───────────────────────── 整页 ─────────────────────────

@immutable
class GenViewData {
  const GenViewData({
    required this.model,
    required this.models,
    this.furry,
    this.quota = const GenQuota(),
    this.layout = const GenLayout(),
    this.prompt = const GenPromptData(),
    this.characters,
    this.refs = const GenRefsData(),
    this.image = const GenImageData(),
    this.params = const GenParamsData(),
    this.generate = const GenGenerateData(),
    this.canvas = const GenCanvasData(),
    this.history = const GenHistoryData(),
    this.now,
  });

  /// 当前模型 id，以及菜单里的全部模型。
  final String model;
  final List<GenModel> models;

  /// Anime / Furry 模式（`params.furryMode`）；null = 当前模型没有这一格（`spec.v4Prompts`）。
  final bool? furry;
  final GenQuota quota;
  final GenLayout layout;
  final GenPromptData prompt;

  /// null = 当前模型没有角色提示词（V3 及更早），整个模块不显示。
  final GenCharactersData? characters;
  final GenRefsData refs;
  final GenImageData image;
  final GenParamsData params;
  final GenGenerateData generate;
  final GenCanvasData canvas;
  final GenHistoryData history;

  /// 历史栏判断“今天”用；null 取当前时间。
  final DateTime? now;

  GenModel get currentModel =>
      models.where((m) => m.id == model).firstOrNull ??
      GenModel(id: model, name: model);

  GenViewData copyWith({
    String? model,
    List<GenModel>? models,
    bool? furry,
    bool clearFurry = false,
    GenQuota? quota,
    GenLayout? layout,
    GenPromptData? prompt,
    GenCharactersData? characters,
    bool clearCharacters = false,
    GenRefsData? refs,
    GenImageData? image,
    GenParamsData? params,
    GenGenerateData? generate,
    GenCanvasData? canvas,
    GenHistoryData? history,
  }) => GenViewData(
    model: model ?? this.model,
    models: models ?? this.models,
    furry: clearFurry ? null : (furry ?? this.furry),
    quota: quota ?? this.quota,
    layout: layout ?? this.layout,
    prompt: prompt ?? this.prompt,
    characters: clearCharacters ? null : (characters ?? this.characters),
    refs: refs ?? this.refs,
    image: image ?? this.image,
    params: params ?? this.params,
    generate: generate ?? this.generate,
    canvas: canvas ?? this.canvas,
    history: history ?? this.history,
    now: now,
  );
}

// ───────────────────────── 槽位 ─────────────────────────

/// 编辑器：按 [target] 返回那一块的可编辑文字（不带内边距和底色，高度随内容）。
typedef GenEditorBuilder =
    Widget Function(BuildContext context, GenEditorTarget target);

/// 画布上的一张：接线方的画布引擎每张图都用它画（选中描边、悬停、占位、失败都在里面）。
typedef GenTileBuilder =
    Widget Function(BuildContext context, GenTile tile, {bool focused});

/// 画布引擎：用 [tile] 画每张图，平移缩放按组排布自己管。
typedef GenCanvasBuilder =
    Widget Function(BuildContext context, GenTileBuilder tile);

/// 参考图某一行外面包一层投放区（`DropRegion`）：接线方读文件、判断是图还是 `.naiv4vibe`，
/// 拖进拖出时更新 [GenRefsData.dropHover]。
typedef GenDropWrapper =
    Widget Function(BuildContext context, GenDropTarget target, Widget child);

/// 历史缩略图外面包一层（拖出到资源管理器 / 别的软件，`DraggableMemoryImage`）。
typedef GenHistoryDragWrapper =
    Widget Function(BuildContext context, String imageId, Widget child);

@immutable
class GenSlots {
  const GenSlots({
    required this.editor,
    this.canvas,
    this.dock,
    this.drop,
    this.historyDrag,
    this.toolSheet,
    this.emptyCanvas,
    this.translationGuide,
    this.agentToggle,
    this.historyCaptionInset = true,
    this.preserveHistory = false,
  });

  final GenEditorBuilder editor;

  /// 品牌欢迎页与随机小贴士由现有组件提供。
  final WidgetBuilder? emptyCanvas;

  /// 教程显示在翻译浮层内；回调返回操作菜单。
  final Widget Function(BuildContext context, VoidCallback onBack)?
  translationGuide;

  /// 仅应用启用 Agent 集成时提供。
  final Widget? agentToggle;

  /// Agent 停靠右侧时，历史栏不再占用窗口按钮所在的一行。
  final bool historyCaptionInset;

  /// A docked Agent keeps history visible; narrow layouts compact the editor
  /// and use a smaller canvas instead of covering or auto-collapsing history.
  final bool preserveHistory;

  /// null = 用界面自带的舞台（只摆焦点组）。
  final GenCanvasBuilder? canvas;

  /// [GenCanvasData.sheet] 非 null 时，摆在顶部工具条下面、水平居中的面板
  /// （画布工具的增强面板 / 放大设置）。
  final Widget? toolSheet;

  /// 块库侧栏（`BlocksDockWiring`），[GenLayout.dockOpen] 时显示。
  final Widget? dock;
  final GenDropWrapper? drop;
  final GenHistoryDragWrapper? historyDrag;
}

// ───────────────────────── 回调 ─────────────────────────

/// 菜单从哪弹：组件的全局矩形（接线方自己弹现有面板时用来定位）。
typedef GenAnchorCallback = void Function(Rect anchor);

@immutable
class GenActions {
  const GenActions({
    required this.onLayoutChanged,
    required this.onModelChanged,
    required this.onFurryChanged,
    required this.onOpenQuota,
    required this.onNegativeTab,
    required this.onClearPrompt,
    required this.onQualityPreset,
    required this.onUcPreset,
    required this.onTransparentChanged,
    required this.onPromptTool,
    required this.onOpenPalette,
    required this.onTranslate,
    required this.onToggleTranslation,
    required this.onTranslationSettings,
    required this.onOpenBridge,
    required this.onAddCharacter,
    required this.onClearCharacters,
    required this.onRemoveCharacter,
    required this.onMoveCharacter,
    required this.onCharacterEnabled,
    required this.onRenameCharacter,
    required this.onCharacterGender,
    required this.onCharacterToLibrary,
    required this.onAiPositionChanged,
    required this.onCharacterPosition,
    required this.onPositioningChanged,
    required this.onImg2ImgUpload,
    required this.onImg2ImgFromLibrary,
    required this.onImg2ImgSketch,
    required this.onImg2ImgChanged,
    required this.onImg2ImgEdit,
    required this.onImg2ImgInpaint,
    required this.onImg2ImgPlace,
    required this.onImg2ImgRemove,
    required this.onAddVibeFiles,
    required this.onAddVibeFromLibrary,
    required this.onAddRecentVibe,
    required this.onVibeChanged,
    required this.onEncodeVibe,
    required this.onRemoveVibe,
    required this.onClearVibes,
    required this.onSaveVibes,
    required this.onNormalizeChanged,
    required this.onAddPreciseFiles,
    required this.onAddPreciseFromLibrary,
    required this.onPreciseChanged,
    required this.onRemovePrecise,
    required this.onClearPrecise,
    required this.onSavePrecise,
    required this.onSizeChanged,
    required this.onCountChanged,
    required this.onRepeatChanged,
    required this.onParamChanged,
    required this.onSeedChanged,
    required this.onSeedPinned,
    required this.onSamplerChanged,
    required this.onNoiseChanged,
    required this.onVarietyChanged,
    required this.onDecrispChanged,
    required this.onSmeaChanged,
    required this.onGenerate,
    required this.onStop,
    required this.onEnhance,
    required this.onVariations,
    required this.onUpscale,
    required this.onUpscaleOption,
    required this.onSetInit,
    required this.onEditImage,
    required this.onInpaint,
    required this.onSendToTools,
    required this.onUseSeed,
    required this.onCopySeed,
    required this.onPin,
    required this.onCopyImage,
    required this.onSaveImage,
    required this.onOpenViewer,
    required this.onFocusTile,
    required this.onBackdropChanged,
    required this.onZoomToFillChanged,
    required this.onRetry,
    required this.onDismissError,
    required this.onFocusBatch,
    required this.onAutoSaveChanged,
    required this.onFocusPins,
    required this.onSaveImages,
    required this.onPackImages,
    required this.onDeleteImages,
    required this.onClearHistory,
    required this.onFavorite,
    required this.onSendTo,
    required this.onReveal,
    this.onUpscaleSettings,
  });

  /// 每个回调只把名字和参数交给 [log]（测试、预览用）。
  factory GenActions.logging(ValueChanged<String> log) => GenActions(
    onLayoutChanged: (v) => log('onLayoutChanged($v)'),
    onModelChanged: (v) => log('onModelChanged($v)'),
    onFurryChanged: (v) => log('onFurryChanged($v)'),
    onOpenQuota: () => log('onOpenQuota'),
    onNegativeTab: (v) => log('onNegativeTab($v)'),
    onClearPrompt: (v) => log('onClearPrompt($v)'),
    onQualityPreset: (v) => log('onQualityPreset($v)'),
    onUcPreset: (v) => log('onUcPreset($v)'),
    onTransparentChanged: (v) => log('onTransparentChanged($v)'),
    onPromptTool: (tool, value) => log('onPromptTool($tool, $value)'),
    onOpenPalette: (_) => log('onOpenPalette'),
    onTranslate: () => log('onTranslate'),
    onToggleTranslation: () => log('onToggleTranslation'),
    onTranslationSettings: () => log('onTranslationSettings'),
    onOpenBridge: (_) => log('onOpenBridge'),
    onAddCharacter: (v) => log('onAddCharacter($v)'),
    onClearCharacters: () => log('onClearCharacters'),
    onRemoveCharacter: (v) => log('onRemoveCharacter($v)'),
    onMoveCharacter: (index, delta) => log('onMoveCharacter($index, $delta)'),
    onCharacterEnabled: (index, enabled) =>
        log('onCharacterEnabled($index, $enabled)'),
    onRenameCharacter: (index, name) => log('onRenameCharacter($index, $name)'),
    onCharacterGender: (index, gender) =>
        log('onCharacterGender($index, $gender)'),
    onCharacterToLibrary: (v) => log('onCharacterToLibrary($v)'),
    onAiPositionChanged: (v) => log('onAiPositionChanged($v)'),
    onCharacterPosition: (index, position) =>
        log('onCharacterPosition($index, $position)'),
    onPositioningChanged: (v) => log('onPositioningChanged($v)'),
    onImg2ImgUpload: () => log('onImg2ImgUpload'),
    onImg2ImgFromLibrary: () => log('onImg2ImgFromLibrary'),
    onImg2ImgSketch: () => log('onImg2ImgSketch'),
    onImg2ImgChanged: (v) => log('onImg2ImgChanged($v)'),
    onImg2ImgEdit: () => log('onImg2ImgEdit'),
    onImg2ImgInpaint: () => log('onImg2ImgInpaint'),
    onImg2ImgPlace: () => log('onImg2ImgPlace'),
    onImg2ImgRemove: () => log('onImg2ImgRemove'),
    onAddVibeFiles: () => log('onAddVibeFiles'),
    onAddVibeFromLibrary: () => log('onAddVibeFromLibrary'),
    onAddRecentVibe: (v) => log('onAddRecentVibe($v)'),
    onVibeChanged: (v) => log('onVibeChanged($v)'),
    onEncodeVibe: (v) => log('onEncodeVibe($v)'),
    onRemoveVibe: (v) => log('onRemoveVibe($v)'),
    onClearVibes: () => log('onClearVibes'),
    onSaveVibes: () => log('onSaveVibes'),
    onNormalizeChanged: (v) => log('onNormalizeChanged($v)'),
    onAddPreciseFiles: () => log('onAddPreciseFiles'),
    onAddPreciseFromLibrary: () => log('onAddPreciseFromLibrary'),
    onPreciseChanged: (v) => log('onPreciseChanged($v)'),
    onRemovePrecise: (v) => log('onRemovePrecise($v)'),
    onClearPrecise: () => log('onClearPrecise'),
    onSavePrecise: () => log('onSavePrecise'),
    onSizeChanged: (width, height) => log('onSizeChanged($width, $height)'),
    onCountChanged: (v) => log('onCountChanged($v)'),
    onRepeatChanged: (v) => log('onRepeatChanged($v)'),
    onParamChanged: (param, value) => log('onParamChanged($param, $value)'),
    onSeedChanged: (v) => log('onSeedChanged($v)'),
    onSeedPinned: (v) => log('onSeedPinned($v)'),
    onSamplerChanged: (v) => log('onSamplerChanged($v)'),
    onNoiseChanged: (v) => log('onNoiseChanged($v)'),
    onVarietyChanged: (v) => log('onVarietyChanged($v)'),
    onDecrispChanged: (v) => log('onDecrispChanged($v)'),
    onSmeaChanged: (v) => log('onSmeaChanged($v)'),
    onGenerate: () => log('onGenerate'),
    onStop: () => log('onStop'),
    onEnhance: (v) => log('onEnhance($v)'),
    onVariations: (v) => log('onVariations($v)'),
    onUpscale: (v) => log('onUpscale($v)'),
    onUpscaleOption: (v) => log('onUpscaleOption($v)'),
    onSetInit: (v) => log('onSetInit($v)'),
    onEditImage: (v) => log('onEditImage($v)'),
    onInpaint: (v) => log('onInpaint($v)'),
    onSendToTools: (v) => log('onSendToTools($v)'),
    onUseSeed: (v) => log('onUseSeed($v)'),
    onCopySeed: (v) => log('onCopySeed($v)'),
    onPin: (tileId, pinned) => log('onPin($tileId, $pinned)'),
    onCopyImage: (v) => log('onCopyImage($v)'),
    onSaveImage: (v) => log('onSaveImage($v)'),
    onOpenViewer: (v) => log('onOpenViewer($v)'),
    onFocusTile: (v) => log('onFocusTile($v)'),
    onBackdropChanged: (v) => log('onBackdropChanged($v)'),
    onZoomToFillChanged: (v) => log('onZoomToFillChanged($v)'),
    onRetry: () => log('onRetry'),
    onDismissError: () => log('onDismissError'),
    onFocusBatch: (v) => log('onFocusBatch($v)'),
    onAutoSaveChanged: (v) => log('onAutoSaveChanged($v)'),
    onFocusPins: () => log('onFocusPins'),
    onSaveImages: (v) => log('onSaveImages($v)'),
    onPackImages: (v) => log('onPackImages($v)'),
    onDeleteImages: (v) => log('onDeleteImages($v)'),
    onClearHistory: () => log('onClearHistory'),
    onFavorite: (imageId, favorite) => log('onFavorite($imageId, $favorite)'),
    onSendTo: (imageId, target) => log('onSendTo($imageId, $target)'),
    onReveal: (v) => log('onReveal($v)'),
  );

  /// 拖宽松手 / 折叠展开 / 开关块库侧栏（存 `layoutState`）。
  final ValueChanged<GenLayout> onLayoutChanged;

  // 顶栏
  final ValueChanged<String> onModelChanged;
  final ValueChanged<bool> onFurryChanged;

  /// 点额度胶囊（打开订阅 / 余额说明）。
  final VoidCallback onOpenQuota;

  // 提示词
  final ValueChanged<bool> onNegativeTab;

  /// 编辑区右上角 ×：清空这一块（接线方可以给撤销提示）。
  final ValueChanged<GenEditorTarget> onClearPrompt;
  final ValueChanged<String> onQualityPreset;
  final ValueChanged<String> onUcPreset;
  final ValueChanged<bool> onTransparentChanged;

  /// “模块与开关”菜单：切换一项（钉住 / 开关），值为切换后的状态。
  final void Function(GenPromptTool tool, bool value) onPromptTool;

  /// 积木板按钮（现有 `PromptBlockPalette` 弹层由接线方贴着 [Rect] 弹）。
  final GenAnchorCallback onOpenPalette;

  /// 翻译当前这一面（`coordinator.translate`）。
  final VoidCallback onTranslate;

  /// 显示原文 / 译文（`coordinator.toggleAll`）。
  final VoidCallback onToggleTranslation;

  /// 去设置里配翻译模型。
  final VoidCallback onTranslationSettings;

  /// 桥接图标（弹现有桥接面板）。
  final GenAnchorCallback onOpenBridge;

  // 角色
  final ValueChanged<GenGender> onAddCharacter;
  final VoidCallback onClearCharacters;
  final ValueChanged<int> onRemoveCharacter;

  /// 第 [index] 个上移（-1）/ 下移（+1）。
  final void Function(int index, int delta) onMoveCharacter;
  final void Function(int index, bool enabled) onCharacterEnabled;

  /// 空字符串 = 恢复默认名。
  final void Function(int index, String name) onRenameCharacter;
  final void Function(int index, GenGender gender) onCharacterGender;

  /// 把这个角色存成块（`AddToLibraryDialog`）。
  final ValueChanged<int> onCharacterToLibrary;
  final ValueChanged<bool> onAiPositionChanged;

  /// 定位板上放下：位置 0–1（V4.5 已吸附到格子中心）。
  final void Function(int index, Offset position) onCharacterPosition;

  /// 打开 / 关闭定位板（画布换成定位板）。
  final ValueChanged<bool> onPositioningChanged;

  // 参考图 · 图生图
  final VoidCallback onImg2ImgUpload;
  final VoidCallback onImg2ImgFromLibrary;
  final VoidCallback onImg2ImgSketch;

  /// 强度 / 噪声 / 局部重绘强度 / 开关（拖动松手才回调）。
  final ValueChanged<GenImg2Img> onImg2ImgChanged;
  final VoidCallback onImg2ImgEdit;
  final VoidCallback onImg2ImgInpaint;

  /// 把原图放到画布上看。
  final VoidCallback onImg2ImgPlace;
  final VoidCallback onImg2ImgRemove;

  // 参考图 · 风格迁移
  final VoidCallback onAddVibeFiles;
  final VoidCallback onAddVibeFromLibrary;
  final ValueChanged<String> onAddRecentVibe;
  final ValueChanged<GenVibe> onVibeChanged;
  final ValueChanged<String> onEncodeVibe;
  final ValueChanged<String> onRemoveVibe;
  final VoidCallback onClearVibes;

  /// 把当前这些 Vibe 存进 Vibe 库。
  final VoidCallback onSaveVibes;
  final ValueChanged<bool> onNormalizeChanged;

  // 参考图 · 精准参考
  final VoidCallback onAddPreciseFiles;
  final VoidCallback onAddPreciseFromLibrary;
  final ValueChanged<GenPrecise> onPreciseChanged;
  final ValueChanged<String> onRemovePrecise;
  final VoidCallback onClearPrecise;
  final VoidCallback onSavePrecise;

  // 图像
  final void Function(int width, int height) onSizeChanged;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<int> onRepeatChanged;

  // 参数
  final void Function(GenParam param, double value) onParamChanged;

  /// 手动输入种子（同时固定）。
  final ValueChanged<int> onSeedChanged;
  final ValueChanged<bool> onSeedPinned;
  final ValueChanged<String> onSamplerChanged;
  final ValueChanged<String> onNoiseChanged;
  final ValueChanged<bool> onVarietyChanged;
  final ValueChanged<bool> onDecrispChanged;
  final ValueChanged<GenSmea> onSmeaChanged;

  // 生成
  final VoidCallback onGenerate;
  final VoidCallback onStop;

  // 画布（都作用在 [GenFocusInfo.tileId] 那张）
  final ValueChanged<String> onEnhance;
  final ValueChanged<String> onVariations;

  /// 放大（放大中再点 = 取消）。
  final ValueChanged<String> onUpscale;
  final ValueChanged<String> onUpscaleOption;

  /// 点放大旁的小箭头：开 / 关放大设置面板（[GenToolSheet.upscale]）。
  /// null = 老做法，箭头弹方案菜单（[GenUpscale.options]）。
  final VoidCallback? onUpscaleSettings;
  final ValueChanged<String> onSetInit;
  final ValueChanged<String> onEditImage;
  final ValueChanged<String> onInpaint;

  /// 发到画布工具（导演工具 / 增强面板）。
  final ValueChanged<String> onSendToTools;

  /// 把这张的种子写回参数（并固定）。
  final ValueChanged<String> onUseSeed;
  final ValueChanged<String> onCopySeed;
  final void Function(String tileId, bool pinned) onPin;
  final ValueChanged<String> onCopyImage;
  final ValueChanged<String> onSaveImage;

  /// 打开大图查看器（从生图页打开的那种）。
  final ValueChanged<String> onOpenViewer;

  /// 点了焦点组里的另一张。
  final ValueChanged<String> onFocusTile;

  /// 选了垫底（预设名或 `#RRGGBB`）。
  final ValueChanged<String> onBackdropChanged;
  final ValueChanged<bool> onZoomToFillChanged;
  final VoidCallback onRetry;
  final VoidCallback onDismissError;

  // 历史
  final ValueChanged<String> onFocusBatch;
  final ValueChanged<bool> onAutoSaveChanged;
  final VoidCallback onFocusPins;

  /// 存到图库（下载）。
  final ValueChanged<List<String>> onSaveImages;

  /// 打包成 zip。
  final ValueChanged<List<String>> onPackImages;

  /// 从本次会话的历史里移除（已存的文件保留），界面已经确认过。
  final ValueChanged<List<String>> onDeleteImages;
  final VoidCallback onClearHistory;
  final void Function(String imageId, bool favorite) onFavorite;
  final void Function(String imageId, GenSendTarget target) onSendTo;

  /// 在资源管理器里显示（已存过的才有意义，接线方没有文件时提示）。
  final ValueChanged<String> onReveal;
}

/// 拖文件进参考图的哪一行。
enum GenDropTarget { img2img, vibe, precise }

/// 历史图右键“发送到”。
enum GenSendTarget { img2img, vibe, precise }
