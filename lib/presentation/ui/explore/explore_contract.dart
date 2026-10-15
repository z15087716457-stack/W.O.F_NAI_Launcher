import 'package:flutter/widgets.dart';

/// 画风探索（A 工作台）：界面只认这份契约。
///
/// 口径约定：
/// - 一个“探索”= 旧代码的 `ExploreRun`；“轮”= `ExploreRound`；“候选”= `ExploreCandidate`；
///   “分组”= `ExploreCandidateFolder`；“进化线”= `ExploreFamily`；“第 N 代”= 该线第 N 个 `ExploreParentSet`；
///   “父本”= `ExploreParent`；“子代”= 深度轮候选。界面文案换了名字，类名和存储不变。
/// - 页签、筛选、排序、勾选、当前查看的候选、当前进化线、大图开没开都是界面自己的状态，不回调；
///   要记住的只有 [ExploreViewData.cardSize]、[ExploreViewData.inspectorOpen]、[ExploreViewData.editorWidth]。
/// - 编辑列里的提示词、角色、参考图、尺寸、参数摘要是生图页的组件，由接线方通过
///   [ExploreEditorBuilder] 拼进来；“随机变量”模块和底部生成条是本页自己的，界面做好交给接线方摆放。
/// - 画师串一律给原始片段（`0.6::artist:ciloranko::`），界面用 [ExploreAtom.parse] 拆权重、去前缀显示，
///   复制和存为块用 [ExploreAtom.raw]。
/// - 时间一律给本地时间的 [DateTime]，界面按 [ExploreViewData.now] 写“今天 18:54 / 9月28日”。

/// 候选的生成状态。
enum ExploreCandidateState { pending, running, done, failed }

/// 子代是怎么来的（`ExploreLineageOperation` 的深度轮三种）。
enum ExploreOp { crossover, mutation, injection }

/// 轮的来源：手动点“抽 N 张”/ 旧的批量基础轮 / 进化线生成的子代轮。
enum ExploreRoundKind { basic, deep }

/// 探索列表里只显示有操作意义的状态（草稿、已生成这类不显示）。
enum ExploreRunState { idle, running, paused, failed }

enum ExploreCardSize { small, large }

/// 两两比较的结果（`ExploreComparisonResult`）。
enum ExploreCompareResult { left, right, neither, skip }

/// 一个画师（或任意提示词片段）：`1.2::artist:sincos::` → 权重 1.2、文字 sincos。
@immutable
class ExploreAtom {
  const ExploreAtom({required this.raw, required this.text, this.weight});

  factory ExploreAtom.parse(String raw) {
    final s = raw.trim();
    final m = RegExp(
      r'^([+-]?\d+(?:\.\d+)?)::(.*)::$',
      dotAll: true,
    ).firstMatch(s);
    var text = (m?.group(2) ?? s).trim();
    if (text.startsWith('artist:')) text = text.substring(7).trim();
    return ExploreAtom(raw: s, text: text, weight: m?.group(1));
  }

  /// 原始片段（复制、存为块、父本串都用它）。
  final String raw;

  /// 显示文字（去掉权重和 `artist:` 前缀）。
  final String text;

  /// 权重原文（保留 “1.0” 这种写法）；没有权重为 null。
  final String? weight;

  @override
  bool operator ==(Object other) => other is ExploreAtom && other.raw == raw;
  @override
  int get hashCode => raw.hashCode;
}

/// 提示词中启用的顺序／随机块，包含未开启遗传的普通变量。
@immutable
class ExploreVariable {
  const ExploreVariable({
    required this.title,
    required this.color,
    this.icon,
    this.poolSize,
    this.evolution = false,
    this.missing = false,
  });

  /// 块标题（实例卡里的名字）。
  final String title;
  final Color color;

  /// 块图标键（`PromptBlock.iconName`）。
  final String? icon;

  /// 池里有多少项；拿不到为 null。
  final int? poolSize;

  /// 参与遗传；所有开启遗传的变量都标记，不暴露后端子代承接位置。
  final bool evolution;

  /// 引用的块已经被删了。
  final bool missing;
}

/// 本张从某个随机块里抽到了什么（`ExploreInstanceRoll`）。抽到空项时 [atoms] 为空。
@immutable
class ExploreDraw {
  const ExploreDraw({
    required this.title,
    required this.color,
    this.icon,
    this.evolution = false,
    this.atoms = const [],
  });

  /// 抓取时刻的块标题（块后来改名不影响）。
  final String title;
  final Color color;
  final String? icon;
  final bool evolution;
  final List<ExploreAtom> atoms;
}

/// 完整提示词里“本张抽到”的那一段（左闭右开字符下标），按块色高亮。
@immutable
class ExploreHit {
  const ExploreHit({
    required this.start,
    required this.end,
    required this.color,
  });
  final int start;
  final int end;
  final Color color;
}

@immutable
class ExploreCandidate {
  const ExploreCandidate({
    required this.key,
    required this.roundId,
    required this.number,
    this.state = ExploreCandidateState.done,
    this.image,
    this.thumb,
    this.width = 832,
    this.height = 1216,
    this.favorite = false,
    this.groupId,
    this.draws = const [],
    this.prompt = '',
    this.negative = '',
    this.hits = const [],
    this.seed,
    this.elapsed,
    this.model,
    this.steps,
    this.scale,
    this.sampler,
    this.createdAt,
    this.error,
    this.op,
    this.lineId,
    this.generation,
    this.parentKeys = const [],
    this.changedAtoms = const [],
    this.opNote,
    this.inEvolution = false,
  });

  /// 候选 id。
  final String key;
  final String roundId;

  /// 在本探索里的序号（“#27”，按生成顺序从 1 起，删了不重排）。
  final int number;
  final ExploreCandidateState state;

  /// 原图（大图、检查器）；缩略图（候选墙、胶片条）。都没有时显示占位。
  final ImageProvider? image;
  final ImageProvider? thumb;
  final int width;
  final int height;
  final bool favorite;

  /// 所在分组；null = 未分组。
  final String? groupId;

  /// 本张抽到（按提示词里随机块的顺序）。
  final List<ExploreDraw> draws;

  /// roll 快照的正向 / 负向全文。
  final String prompt;
  final String negative;
  final List<ExploreHit> hits;
  final int? seed;
  final Duration? elapsed;

  /// 模型友好名（`ImageModels.modelDisplayNames`）、步数、引导、采样器友好名。
  final String? model;
  final int? steps;
  final double? scale;
  final String? sampler;
  final DateTime? createdAt;

  /// 失败原因（`generation.error`）。
  final String? error;

  /// 子代：怎么来的、属于哪条线的第几代、父本是谁、哪些画师是新的。
  final ExploreOp? op;
  final String? lineId;
  final int? generation;
  final List<String> parentKeys;
  final List<ExploreAtom> changedAtoms;

  /// 变化说明（“替换 1 位画师、调整 1 个权重”），接线方拼好；null 不写。
  final String? opNote;

  /// 已经是某条进化线的父本（卡片左下角紫色角标）。
  final bool inEvolution;

  bool get done => state == ExploreCandidateState.done;
  double get aspect => width > 0 && height > 0 ? width / height : 832 / 1216;

  /// 本张抽到的全部画师（按块顺序，去重）。
  List<ExploreAtom> get atoms => {for (final d in draws) ...d.atoms}.toList();

  /// 接线方增量更新（收藏、归组、出图）时用。
  ExploreCandidate copyWith({
    ExploreCandidateState? state,
    ImageProvider? image,
    ImageProvider? thumb,
    bool? favorite,
    String? Function()? groupId,
    String? Function()? error,
    bool? inEvolution,
  }) => ExploreCandidate(
    key: key,
    roundId: roundId,
    number: number,
    state: state ?? this.state,
    image: image ?? this.image,
    thumb: thumb ?? this.thumb,
    width: width,
    height: height,
    favorite: favorite ?? this.favorite,
    groupId: groupId != null ? groupId() : this.groupId,
    draws: draws,
    prompt: prompt,
    negative: negative,
    hits: hits,
    seed: seed,
    elapsed: elapsed,
    model: model,
    steps: steps,
    scale: scale,
    sampler: sampler,
    createdAt: createdAt,
    error: error != null ? error() : this.error,
    op: op,
    lineId: lineId,
    generation: generation,
    parentKeys: parentKeys,
    changedAtoms: changedAtoms,
    opNote: opNote,
    inEvolution: inEvolution ?? this.inEvolution,
  );
}

@immutable
class ExploreRound {
  const ExploreRound({
    required this.id,
    required this.number,
    required this.createdAt,
    required this.keys,
    this.kind = ExploreRoundKind.basic,
    this.lineName,
    this.generation,
  });
  final String id;

  /// 轮次序号（1 起）。
  final int number;
  final DateTime createdAt;

  /// 本轮候选，按生成顺序。
  final List<String> keys;
  final ExploreRoundKind kind;

  /// 子代轮：属于哪条进化线的第几代。
  final String? lineName;
  final int? generation;
}

@immutable
class ExploreGroup {
  const ExploreGroup({required this.id, required this.name});
  final String id;
  final String name;
}

/// 父本：来自某张候选，或用户加的自定义画师串（[candidateKey] 为 null）。
@immutable
class ExploreParent {
  const ExploreParent({
    required this.id,
    required this.atoms,
    this.candidateKey,
    this.image,
    this.preference = 1,
  });
  final String id;
  final List<ExploreAtom> atoms;
  final String? candidateKey;

  /// 来源候选的缩略图（自定义串为 null）。
  final ImageProvider? image;

  /// 偏好值（两两比较排序的结果，越大越常被选为父本）。
  final double preference;
}

/// 进化线的一代：父本 + 由它们生成的子代。
@immutable
class ExploreGeneration {
  const ExploreGeneration({
    required this.number,
    required this.parents,
    this.childKeys = const [],
    this.fromGeneration,
    this.picked = 0,
    this.backcross = false,
  });

  /// 第几代（1 起）。
  final int number;
  final List<ExploreParent> parents;

  /// 本代父本生成的子代，按生成顺序。
  final List<String> childKeys;

  /// 由上一代哪一代挑出来的（第 1 代为 null：从候选里选的）。
  final int? fromGeneration;

  /// 第 1 代：从候选里选了几张；之后：从上一代子代里挑了几张。
  final int picked;

  /// 带了第 1 代父本回交。
  final bool backcross;
}

@immutable
class ExploreLine {
  const ExploreLine({
    required this.id,
    required this.name,
    required this.generations,
  });
  final String id;
  final String name;

  /// 从第 1 代到最新一代。
  final List<ExploreGeneration> generations;

  ExploreGeneration get current => generations.last;
}

/// 正在生成（或暂停）的一批：顶栏进度。
@immutable
class ExploreProgress {
  const ExploreProgress({
    required this.done,
    required this.total,
    this.round,
    this.lineName,
    this.generation,
    this.paused = false,
  });
  final int done;
  final int total;

  /// 手动抽取：第几轮；子代：哪条线第几代。
  final int? round;
  final String? lineName;
  final int? generation;

  /// 暂停中（子代批次可以暂停 / 继续；手动抽取只能停止）。
  final bool paused;
}

/// 当前打开的探索。
@immutable
class ExploreRunView {
  const ExploreRunView({
    required this.id,
    required this.name,
    required this.createdAt,
    this.candidates = const [],
    this.rounds = const [],
    this.groups = const [],
    this.lines = const [],
    this.progress,
  });
  final String id;
  final String name;
  final DateTime createdAt;

  /// 全部候选（顺序不重要，界面按 [rounds] 排）。
  final List<ExploreCandidate> candidates;

  /// 按创建先后；界面默认最新的在上面。候选页签只列 [ExploreRoundKind.basic] 的轮（海选），
  /// 子代轮只在进化页签里按“代”显示；顶栏张数、筛选计数也只算海选候选。
  final List<ExploreRound> rounds;
  final List<ExploreGroup> groups;
  final List<ExploreLine> lines;
  final ExploreProgress? progress;

  ExploreCandidate? candidate(String key) =>
      (_index[this] ??= {for (final c in candidates) c.key: c})[key];

  static final _index = Expando<Map<String, ExploreCandidate>>();
}

/// 切换探索下拉里的一行。
@immutable
class ExploreRunSummary {
  const ExploreRunSummary({
    required this.id,
    required this.name,
    required this.updatedAt,
    this.total = 0,
    this.favorites = 0,
    this.lines = 0,
    this.thumbs = const [],
    this.state = ExploreRunState.idle,
    this.done = 0,
    this.target = 0,
    this.failed = 0,
  });
  final String id;
  final String name;

  /// 最后一次有动静（生成、收藏、改名）的时间：下拉按“今天 / 本周 / 更早”分段。
  final DateTime updatedAt;
  final int total;
  final int favorites;
  final int lines;

  /// 最多 3 张缩略图（最新的收藏优先）。
  final List<ImageProvider?> thumbs;
  final ExploreRunState state;

  /// 生成中 / 暂停：已完成 / 本批总数。
  final int done;
  final int target;

  /// 有失败：失败张数。
  final int failed;
}

enum ExploreGeneratePhase {
  /// 可以抽。
  ready,

  /// 本页这批正在出图：按钮变成“停止生成 9 / 12”。
  running,

  /// 别处在生成（生图页 / 子代批次）：按钮灰掉写“生成中”。
  busy,

  /// 冷却中：按钮灰掉写“冷却 3 秒”。
  cooldown,
}

/// 底部生成条。张数就是生图页的 `nSamples`（逐张生成，每张重新抽）。
@immutable
class ExploreGenerate {
  const ExploreGenerate({
    this.count = 10,
    this.maxCount = 100,
    this.cost = 0,
    this.insufficient = false,
    this.phase = ExploreGeneratePhase.ready,
    this.done = 0,
    this.total = 0,
    this.cooldown = 0,
  });
  final int count;
  final int maxCount;

  /// 预计 Anlas（Opus 免费时为 0）。
  final int cost;

  /// 余额不够：价格角标变红。
  final bool insufficient;
  final ExploreGeneratePhase phase;
  final int done;
  final int total;

  /// 冷却剩余秒数。
  final int cooldown;
}

/// 块库目录（存为块时选放哪），按树序拍平；根目录 id 为 null。
@immutable
class ExploreBlockFolder {
  const ExploreBlockFolder({
    required this.id,
    required this.name,
    this.depth = 0,
  });
  final String? id;
  final String name;
  final int depth;
}

/// 刚删掉的候选：底部提示带撤销，界面 6 秒后调 [ExploreActions.onDismissUndo]。
@immutable
class ExploreUndo {
  const ExploreUndo({required this.id, required this.count});

  /// 每次删除换一个 id。
  final String id;
  final int count;
}

@immutable
class ExploreViewData {
  const ExploreViewData({
    required this.now,
    this.loading = false,
    this.runs = const [],
    this.run,
    this.variables = const [],
    this.generate = const ExploreGenerate(),
    this.cardSize = ExploreCardSize.large,
    this.inspectorOpen = true,
    this.editorWidth = 384,
    this.blockFolders = const [ExploreBlockFolder(id: null, name: '')],
    this.undo,
    this.fullscreen = false,
  });

  final DateTime now;

  /// 探索列表还在读。
  final bool loading;

  /// 全部探索（新的在前）。
  final List<ExploreRunSummary> runs;

  /// 当前打开的探索；null = 还没有探索（首次使用）。
  final ExploreRunView? run;

  /// 当前提示词里的随机块（编辑列“随机变量”和首次使用第一步）。
  final List<ExploreVariable> variables;
  final ExploreGenerate generate;
  final ExploreCardSize cardSize;

  /// 检查器开关（宽窗口；窄窗口时检查器盖在候选墙上，不回调）。
  final bool inspectorOpen;

  /// 编辑列宽（352–560，拖右缘改）。
  final double editorWidth;
  final List<ExploreBlockFolder> blockFolders;
  final ExploreUndo? undo;

  /// 大图真全屏（接线方藏起主导航和窗口按钮）。
  final bool fullscreen;
}

/// 存为块：界面整理好的内容。
@immutable
class ExploreBlockDraft {
  const ExploreBlockDraft({
    required this.title,
    required this.atoms,
    required this.color,
    this.fullText,
    this.folderId,
  });
  final String title;

  /// 只要抽到的画师：保留下来的原始片段（显式传给 `createBlock(atoms:)`，保护片段里的逗号）。
  final List<String> atoms;

  /// 完整正向模式：整段正向提示词（此时 [atoms] 为空）。
  final String? fullText;
  final Color color;
  final String? folderId;
}

/// 开始进化：界面整理好的计划。
@immutable
class ExploreEvolutionPlan {
  const ExploreEvolutionPlan({
    required this.candidateKeys,
    this.customParents = const [],
    this.newLineName,
    this.joinLineId,
    this.generate,
  });

  /// 作为父本的候选（每张的画师串是一个父本）。
  final List<String> candidateKeys;

  /// 用户加的自定义画师串（原文）。
  final List<String> customParents;

  /// 新建进化线的名字；和 [joinLineId] 二选一。
  final String? newLineName;

  /// 加入这条线的当前代（`addParentsToActiveSet`）。
  final String? joinLineId;

  /// 创建后马上生成多少张子代；null = 只创建。
  final int? generate;
}

/// 编辑列里本页自己的两块，接线方拼进生图页的组件之间。
@immutable
class ExploreEditorParts {
  const ExploreEditorParts({
    required this.randomVariables,
    required this.generateBar,
  });

  /// “随机变量”模块（放在提示词模块下面）。
  final Widget randomVariables;

  /// 底部生成条：张数 + “抽 N 张候选”（放在参数摘要下面）。
  final Widget generateBar;
}

/// 编辑列：接线方用生图页的组件拼，中间插 [ExploreEditorParts]。外框（右边线、宽度）由页面画。
typedef ExploreEditorBuilder =
    Widget Function(BuildContext context, ExploreEditorParts parts);

/// 回调。候选 `key` 都是 [ExploreCandidate.key]。
@immutable
class ExploreActions {
  const ExploreActions({
    required this.onOpenRun,
    required this.onNewRun,
    required this.onRenameRun,
    required this.onDeleteRun,
    required this.onGenerate,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onCountChanged,
    required this.onRetryFailed,
    required this.onSetFavorite,
    required this.onAssignGroup,
    required this.onCreateGroup,
    required this.onRenameGroup,
    required this.onDeleteGroup,
    required this.onDeleteCandidates,
    required this.onUndoDelete,
    required this.onDismissUndo,
    required this.onCopyArtists,
    required this.onApplyToEditor,
    required this.onSaveBlock,
    required this.onStartEvolution,
    required this.onCompare,
    required this.onBreed,
    required this.onGenerateChildren,
    required this.onRenameLine,
    required this.onDeleteLine,
    required this.onOpenVariable,
    required this.onOpenBlockLibrary,
    required this.onCardSizeChanged,
    required this.onInspectorChanged,
    required this.onEditorWidthChanged,
    required this.onFullscreenChanged,
    required this.onCaptionOverStage,
  });

  /// 切换到另一个探索。
  final ValueChanged<String> onOpenRun;

  /// 新建探索：用当前提示词和参数直接建（名字自动起“随机块名 + 日期”，不弹命名框）。
  final VoidCallback onNewRun;
  final void Function(String runId, String name) onRenameRun;

  /// 删除探索（界面已经确认过）。正在跑的先取消再删。
  final ValueChanged<String> onDeleteRun;

  /// 抽 N 张候选（沿用生图页的生成：消耗确认、冷却、逐张参数）。每次点击新建一轮。
  final VoidCallback onGenerate;

  /// 停止当前这批（手动抽取或子代批次）。
  final VoidCallback onStop;

  /// 暂停 / 继续子代批次。
  final VoidCallback onPause;
  final VoidCallback onResume;
  final ValueChanged<int> onCountChanged;

  /// 重试当前探索里失败的候选。
  final VoidCallback onRetryFailed;
  final void Function(List<String> keys, bool value) onSetFavorite;

  /// 归组；[groupId] 为 null = 移出分组。
  final void Function(List<String> keys, String? groupId) onAssignGroup;

  /// 新建分组，并把 [keys]（可以为空）放进去。重名由接线方提示。
  final void Function(String name, List<String> keys) onCreateGroup;
  final void Function(String groupId, String name) onRenameGroup;

  /// 删除分组（成员回到未分组）。
  final ValueChanged<String> onDeleteGroup;

  /// 删除候选（连图带记录）。成功后给 [ExploreViewData.undo]。
  final ValueChanged<List<String>> onDeleteCandidates;
  final VoidCallback onUndoDelete;
  final VoidCallback onDismissUndo;

  /// 复制这些候选抽到的画师串（去重，逗号连接）。
  final ValueChanged<List<String>> onCopyArtists;

  /// 套用到编辑区：把这张的正向全文放进主提示词（运行中拒绝、未备份先确认，都由接线方做）。
  final ValueChanged<String> onApplyToEditor;
  final ValueChanged<ExploreBlockDraft> onSaveBlock;
  final ValueChanged<ExploreEvolutionPlan> onStartEvolution;

  /// 两两比较的一对（父本 id）。结果马上保存。
  final void Function(
    String lineId,
    String leftParentId,
    String rightParentId,
    ExploreCompareResult result,
  )
  onCompare;

  /// 用选中的子代培育下一代（`createBranch`）。
  final void Function(String lineId, List<String> childKeys) onBreed;

  /// 用当前代父本再生成 N 张子代（`startDeepRound`）。
  final void Function(String lineId, int count) onGenerateChildren;
  final void Function(String lineId, String name) onRenameLine;

  /// 删除进化线（界面已经确认过；它生成的子代一起删）。
  final ValueChanged<String> onDeleteLine;

  /// 点“随机变量”里的一行：在提示词里打开这个实例的实例卡。
  final ValueChanged<int> onOpenVariable;

  /// 打开块库侧栏（首次使用、没有随机块时）。
  final VoidCallback onOpenBlockLibrary;
  final ValueChanged<ExploreCardSize> onCardSizeChanged;
  final ValueChanged<bool> onInspectorChanged;
  final ValueChanged<double> onEditorWidthChanged;

  /// 大图全屏（同大图查看器）。
  final ValueChanged<bool> onFullscreenChanged;

  /// 大图打开时窗口按钮是否压在黑底舞台上（同大图查看器 `onCaptionOverStage`）；
  /// 大图关着时报 false。变化时才调。
  final ValueChanged<bool> onCaptionOverStage;

  static final none = ExploreActions(
    onOpenRun: (_) {},
    onNewRun: () {},
    onRenameRun: (_, _) {},
    onDeleteRun: (_) {},
    onGenerate: () {},
    onStop: () {},
    onPause: () {},
    onResume: () {},
    onCountChanged: (_) {},
    onRetryFailed: () {},
    onSetFavorite: (_, _) {},
    onAssignGroup: (_, _) {},
    onCreateGroup: (_, _) {},
    onRenameGroup: (_, _) {},
    onDeleteGroup: (_) {},
    onDeleteCandidates: (_) {},
    onUndoDelete: () {},
    onDismissUndo: () {},
    onCopyArtists: (_) {},
    onApplyToEditor: (_) {},
    onSaveBlock: (_) {},
    onStartEvolution: (_) {},
    onCompare: (_, _, _, _) {},
    onBreed: (_, _) {},
    onGenerateChildren: (_, _) {},
    onRenameLine: (_, _) {},
    onDeleteLine: (_) {},
    onOpenVariable: (_) {},
    onOpenBlockLibrary: () {},
    onCardSizeChanged: (_) {},
    onInspectorChanged: (_) {},
    onEditorWidthChanged: (_) {},
    onFullscreenChanged: (_) {},
    onCaptionOverStage: (_) {},
  );
}
