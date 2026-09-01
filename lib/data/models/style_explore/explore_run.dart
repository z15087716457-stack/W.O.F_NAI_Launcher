import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../image/image_params.dart';
import '../prompt_block/pill_document.dart';

part 'explore_run.freezed.dart';
part 'explore_run.g.dart';

/// 探索任务（Run）生命周期：草稿 → 生成中 ⇄ 暂停 → 已生成 → 筛选/完成；
/// 取消为终态（不可再启动）。
enum ExploreRunStatus {
  draft,
  generating,
  paused,
  generated,
  reviewing,
  completed,
  cancelled,
}

/// 轮次阶段：基础探索 / 深度迭代（阶段 D）/ 手动登记（探索页单张生成）。
enum ExploreRoundPhase { basic, deep, manual }

enum ExploreRoundStatus { pending, generating, generated, cancelled }

enum ExploreCandidateGenerationStatus { pending, done, failed }

/// 候选评审标签：珍宝 / 特殊 / 拒绝（预标记与正式筛选共用）。
enum ExploreReviewLabel { treasure, special, reject }

/// 候选谱系操作：基础 roll / 变异 / 交叉 / 注入 / 手动。
enum ExploreLineageOperation {
  @JsonValue('basic_roll')
  basicRoll,
  mutation,
  crossover,
  injection,
  manual,
}

enum ExploreParentSetStatus { active, used }

/// 生成参数精简快照（创建 Run 时固化；后续主参数页改动不污染历史轮）。
///
/// 已知边界：fixed tags/质量词/UC 预设/角色/vibe 等主环境项不入快照，
/// 生成时以主参数为准（见计划书 2.4 节）。
@freezed
class ExploreParamsSnapshot with _$ExploreParamsSnapshot {
  const ExploreParamsSnapshot._();

  const factory ExploreParamsSnapshot({
    required String model,
    required int width,
    required int height,
    required int steps,
    required double scale,
    required String sampler,
    required int seed,
    required int ucPreset,
    required bool qualityToggle,
    required bool smea,
    required bool smeaDyn,
    required double cfgRescale,
    required String noiseSchedule,
    required bool varietyPlus,
    required bool decrisp,
  }) = _ExploreParamsSnapshot;

  factory ExploreParamsSnapshot.fromJson(Map<String, dynamic> json) =>
      _$ExploreParamsSnapshotFromJson(json);

  /// 从主生成参数捕获快照。
  factory ExploreParamsSnapshot.fromImageParams(ImageParams params) {
    return ExploreParamsSnapshot(
      model: params.model,
      width: params.width,
      height: params.height,
      steps: params.steps,
      scale: params.scale,
      sampler: params.sampler,
      seed: params.seed,
      ucPreset: params.ucPreset,
      qualityToggle: params.qualityToggle,
      smea: params.smea,
      smeaDyn: params.smeaDyn,
      cfgRescale: params.cfgRescale,
      noiseSchedule: params.noiseSchedule,
      varietyPlus: params.varietyPlus,
      decrisp: params.decrisp,
    );
  }
}

/// Run 创建时固化的正负药丸文档快照。
@freezed
class ExploreRecipeSnapshot with _$ExploreRecipeSnapshot {
  const factory ExploreRecipeSnapshot({
    @JsonSerializable(explicitToJson: true) required PillDocument positive,
    @JsonSerializable(explicitToJson: true) required PillDocument negative,
  }) = _ExploreRecipeSnapshot;

  factory ExploreRecipeSnapshot.fromJson(Map<String, dynamic> json) =>
      _$ExploreRecipeSnapshotFromJson(json);
}

/// 单个随机块实例的 roll 明细（复现链的一环）。
@freezed
class ExploreInstanceRoll with _$ExploreInstanceRoll {
  const factory ExploreInstanceRoll({
    /// 所在 lane：'pos' / 'neg'（两条 lane 的标记字符可能相同，需带 lane 区分）。
    required String lane,

    /// 标记字符（即实例 ID）。
    required String marker,

    /// 引用的库块 ID。
    required String blockId,

    /// 抓取时刻的块标题（块后续改名不影响快照）。
    required String blockTitle,

    /// 物化的 roll 结果串。
    required String rolledText,
  }) = _ExploreInstanceRoll;

  factory ExploreInstanceRoll.fromJson(Map<String, dynamic> json) =>
      _$ExploreInstanceRollFromJson(json);
}

/// 一张候选生成前的 roll 快照：正/负投影全文 + 随机实例明细。
@freezed
class ExploreRollSnapshot with _$ExploreRollSnapshot {
  const factory ExploreRollSnapshot({
    required String positive,
    required String negative,
    @JsonSerializable(explicitToJson: true)
    @Default([])
    List<ExploreInstanceRoll> instanceRolls,
  }) = _ExploreRollSnapshot;

  factory ExploreRollSnapshot.fromJson(Map<String, dynamic> json) =>
      _$ExploreRollSnapshotFromJson(json);
}

/// 候选的生成结果。
@freezed
class ExploreCandidateGeneration with _$ExploreCandidateGeneration {
  const factory ExploreCandidateGeneration({
    required ExploreCandidateGenerationStatus status,

    /// 候选图在 run 目录内的自包含副本路径。
    String? filePath,

    /// 实际生成种子（随机种子在请求前已实体化）。
    int? seed,

    /// 本张消耗点数（预留，暂无精确来源）。
    int? anlas,

    /// 单张耗时（毫秒）。
    int? elapsedMs,

    /// 失败原因。
    String? error,
  }) = _ExploreCandidateGeneration;

  factory ExploreCandidateGeneration.fromJson(Map<String, dynamic> json) =>
      _$ExploreCandidateGenerationFromJson(json);
}

/// 候选评审：心形 + 轻预标记（T/S/R）+ 正式筛选标签（阶段 C）。
/// 全部纯数据标记，任何时刻不移动图库文件。
@freezed
class ExploreCandidateReview with _$ExploreCandidateReview {
  const factory ExploreCandidateReview({
    @Default(false) bool heart,
    ExploreReviewLabel? preliminaryLabel,
    ExploreReviewLabel? label,

    /// 正式筛选归类时间（随 label 写入/清除）。
    DateTime? formalReviewedAt,
  }) = _ExploreCandidateReview;

  factory ExploreCandidateReview.fromJson(Map<String, dynamic> json) =>
      _$ExploreCandidateReviewFromJson(json);
}

/// 候选谱系：父本 + 产生方式 + 代际。
@freezed
class ExploreLineage with _$ExploreLineage {
  const factory ExploreLineage({
    @Default([]) List<String> parentCandidateIds,
    required ExploreLineageOperation operation,
    @Default(1) int generation,
  }) = _ExploreLineage;

  factory ExploreLineage.fromJson(Map<String, dynamic> json) =>
      _$ExploreLineageFromJson(json);
}

/// 一张候选图。
@freezed
class ExploreCandidate with _$ExploreCandidate {
  const ExploreCandidate._();

  const factory ExploreCandidate({
    required String id,
    required String roundId,

    /// roll 快照（每张生成前一刻抓取；pending 壳阶段为 null）。
    @JsonSerializable(explicitToJson: true) ExploreRollSnapshot? rollSnapshot,

    @JsonSerializable(explicitToJson: true)
    @Default(
      ExploreCandidateGeneration(
        status: ExploreCandidateGenerationStatus.pending,
      ),
    )
    ExploreCandidateGeneration generation,

    @JsonSerializable(explicitToJson: true)
    @Default(ExploreCandidateReview())
    ExploreCandidateReview review,

    @JsonSerializable(explicitToJson: true) required ExploreLineage lineage,
  }) = _ExploreCandidate;

  factory ExploreCandidate.fromJson(Map<String, dynamic> json) =>
      _$ExploreCandidateFromJson(json);

  /// 创建基础轮的 pending 候选壳（roll 快照待生成前抓填）。
  factory ExploreCandidate.shell({
    required String roundId,
    int generation = 1,
    String? id,
  }) {
    return ExploreCandidate(
      id: id ?? const Uuid().v4(),
      roundId: roundId,
      lineage: ExploreLineage(
        operation: ExploreLineageOperation.basicRoll,
        generation: generation,
      ),
    );
  }
}

/// 一轮候选生成。
@freezed
class ExploreRound with _$ExploreRound {
  const factory ExploreRound({
    required String id,

    /// 轮次序号（1 起）。
    required int number,
    required ExploreRoundPhase phase,
    required ExploreRoundStatus status,
    required DateTime createdAt,
    required int targetCount,
    @Default([]) List<String> candidateIds,

    /// 深度轮关联的家族/父本集（阶段 D）。
    String? familyId,
    String? parentSetId,

    /// 深度轮的代际号（基础轮为 null）。
    int? generation,
  }) = _ExploreRound;

  factory ExploreRound.fromJson(Map<String, dynamic> json) =>
      _$ExploreRoundFromJson(json);
}

/// 父本条（阶段 D）：候选串收编而来，或自定义串。
@freezed
class ExploreParent with _$ExploreParent {
  const factory ExploreParent({
    required String id,

    /// 来源候选（自定义串为 null）。
    String? sourceCandidateId,

    /// 父本串（roll 快照正向全文或变异产物）。
    required String artistString,

    /// 偏好值（两两比较排序产出，影响变异时父本被选权重）。
    @Default(1.0) double preference,
  }) = _ExploreParent;

  factory ExploreParent.fromJson(Map<String, dynamic> json) =>
      _$ExploreParentFromJson(json);
}

/// 父本集（阶段 D）：平铺存于 Run 内，家族按 id 引用。
@freezed
class ExploreParentSet with _$ExploreParentSet {
  const factory ExploreParentSet({
    required String id,
    required String familyId,
    required int generation,
    required ExploreParentSetStatus status,

    /// 分支名（回交产生的新父本集）。
    String? branchName,
    @JsonSerializable(explicitToJson: true)
    @Default([])
    List<ExploreParent> parents,
  }) = _ExploreParentSet;

  factory ExploreParentSet.fromJson(Map<String, dynamic> json) =>
      _$ExploreParentSetFromJson(json);
}

/// 家族（阶段 D）：从一组 Treasure 父本出发的深度迭代主线。
@freezed
class ExploreFamily with _$ExploreFamily {
  const factory ExploreFamily({
    required String id,
    required String name,
    required DateTime createdAt,

    /// 第一代父本集 id。
    required String rootParentSetId,

    /// 当前活跃父本集 id。
    required String activeParentSetId,
  }) = _ExploreFamily;

  factory ExploreFamily.fromJson(Map<String, dynamic> json) =>
      _$ExploreFamilyFromJson(json);
}

/// 探索任务（Run）：提示词+参数快照固化的批量候选生成与筛选单位。
@freezed
class ExploreRun with _$ExploreRun {
  const ExploreRun._();

  const factory ExploreRun({
    required String id,
    required String name,
    required ExploreRunStatus status,

    /// 归档时间；非 null 即已归档。
    DateTime? archivedAt,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// 基础轮出图数（仅草稿态可编辑）。
    required int targetCount,

    @JsonSerializable(explicitToJson: true)
    required ExploreRecipeSnapshot recipeSnapshot,

    @JsonSerializable(explicitToJson: true)
    required ExploreParamsSnapshot paramsSnapshot,

    @JsonSerializable(explicitToJson: true)
    @Default([])
    List<ExploreRound> rounds,

    @JsonSerializable(explicitToJson: true)
    @Default([])
    List<ExploreCandidate> candidates,

    /// 父本集平铺存储（阶段 D），家族按 id 引用。
    @JsonSerializable(explicitToJson: true)
    @Default([])
    List<ExploreParentSet> parentSets,

    @JsonSerializable(explicitToJson: true)
    @Default([])
    List<ExploreFamily> families,
  }) = _ExploreRun;

  factory ExploreRun.fromJson(Map<String, dynamic> json) =>
      _$ExploreRunFromJson(json);

  /// 创建草稿 Run；名称去除首尾空白。
  factory ExploreRun.create({
    required String name,
    required ExploreRecipeSnapshot recipeSnapshot,
    required ExploreParamsSnapshot paramsSnapshot,
    required int targetCount,
    String? id,
    DateTime? createdAt,
  }) {
    final created = createdAt ?? DateTime.now();
    return ExploreRun(
      id: id ?? const Uuid().v4(),
      name: name.trim(),
      status: ExploreRunStatus.draft,
      createdAt: created,
      updatedAt: created,
      targetCount: targetCount,
      recipeSnapshot: recipeSnapshot,
      paramsSnapshot: paramsSnapshot,
    );
  }

  /// 空名称的界面兜底。
  String get displayName => name.isNotEmpty ? name : '未命名任务';

  bool get isArchived => archivedAt != null;

  ExploreCandidate? candidateById(String candidateId) {
    for (final candidate in candidates) {
      if (candidate.id == candidateId) return candidate;
    }
    return null;
  }

  ExploreRound? roundById(String roundId) {
    for (final round in rounds) {
      if (round.id == roundId) return round;
    }
    return null;
  }

  /// 待生成候选（按列表顺序）。
  List<ExploreCandidate> get pendingCandidates => [
    for (final candidate in candidates)
      if (candidate.generation.status ==
          ExploreCandidateGenerationStatus.pending)
        candidate,
  ];

  /// 生成成功数。
  int get generatedCount => candidates
      .where(
        (c) => c.generation.status == ExploreCandidateGenerationStatus.done,
      )
      .length;

  /// 生成失败数。
  int get failedCount => candidates
      .where(
        (c) => c.generation.status == ExploreCandidateGenerationStatus.failed,
      )
      .length;

  /// 可审查候选（生成成功，正式筛选的归类目标）。
  List<ExploreCandidate> get reviewableCandidates => [
    for (final candidate in candidates)
      if (candidate.generation.status == ExploreCandidateGenerationStatus.done)
        candidate,
  ];

  /// 已正式归类的可审查候选数。
  int get formallyReviewedCount => reviewableCandidates
      .where((candidate) => candidate.review.label != null)
      .length;

  /// 全部可审查候选都已正式归类（完成筛选的判定）。
  bool get isReviewComplete =>
      reviewableCandidates.isNotEmpty &&
      formallyReviewedCount == reviewableCandidates.length;
}
