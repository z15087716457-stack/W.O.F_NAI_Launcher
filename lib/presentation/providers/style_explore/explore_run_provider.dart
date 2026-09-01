import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/style_explore_run_storage.dart';
import '../../../data/models/style_explore/explore_run.dart';
import '../../../data/repositories/style_explore_run_repository.dart';
import '../../../data/services/explore_run_image_store.dart';
import 'explore_roll_capture.dart';

final styleExploreRunStorageProvider = Provider<StyleExploreRunStorage>(
  (ref) => StyleExploreRunStorage(),
);

final styleExploreRunRepositoryProvider = Provider<StyleExploreRunRepository>(
  (ref) => StyleExploreRunRepository(ref.watch(styleExploreRunStorageProvider)),
);

/// 候选图副本存储（copy-in / delete-dir）。
final exploreRunImageStoreProvider = Provider<ExploreRunImageStore>(
  (ref) => ExploreRunImageStore(),
);

/// Run 列表只读快照，按更新时间新→旧排列。
class ExploreRunListState {
  ExploreRunListState({required List<ExploreRun> runs})
    : runs = List.unmodifiable(runs);

  final List<ExploreRun> runs;

  ExploreRun? runById(String id) {
    for (final run in runs) {
      if (run.id == id) return run;
    }
    return null;
  }
}

/// Run 列表管理（增删改/归档/重命名 + 候选字段细粒度更新）。
class ExploreRunListNotifier extends AsyncNotifier<ExploreRunListState> {
  @override
  Future<ExploreRunListState> build() async {
    final runs = await ref.watch(styleExploreRunRepositoryProvider).load();
    return ExploreRunListState(runs: runs);
  }

  Future<void> refresh() async {
    final repository = ref.read(styleExploreRunRepositoryProvider);
    state = const AsyncLoading();
    try {
      state = AsyncData(ExploreRunListState(runs: await repository.load()));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<ExploreRun> create({
    required String name,
    required ExploreRecipeSnapshot recipeSnapshot,
    required ExploreParamsSnapshot paramsSnapshot,
    required int targetCount,
  }) {
    return _mutate(
      (repository) => repository.create(
        name: name,
        recipeSnapshot: recipeSnapshot,
        paramsSnapshot: paramsSnapshot,
        targetCount: targetCount,
      ),
    );
  }

  Future<ExploreRun> overwrite(ExploreRun run) =>
      _mutate((repository) => repository.overwrite(run));

  Future<ExploreRun> rename(String id, String name) =>
      _mutate((repository) => repository.rename(id, name));

  Future<ExploreRun> setArchived(String id, bool archived) =>
      _mutate((repository) => repository.setArchived(id, archived));

  /// 删除 Run，连带删除候选图副本目录（源图不动）。
  Future<void> delete(String id) async {
    await _mutate((repository) => repository.delete(id));
    await ref.read(exploreRunImageStoreProvider).deleteRunDir(id);
  }

  /// 出图数编辑（草稿态 + generated 追加轮前可编辑）。
  Future<ExploreRun> updateTargetCount(String id, int targetCount) {
    return _mutateRun(id, (run) {
      const editable = {ExploreRunStatus.draft, ExploreRunStatus.generated};
      if (!editable.contains(run.status)) {
        throw StateError('Only draft/generated runs can edit targetCount: $id');
      }
      return run.copyWith(targetCount: targetCount);
    });
  }

  /// 追加手动候选（探索页生成按钮登记）：复用最近的手动轮（无则新建，
  /// 状态直接 generated 不经 runner），一次落盘追加 [count] 个 pending
  /// 候选（lineage.operation=manual），首张带 [firstRollSnapshot]。
  Future<List<ExploreCandidate>> addManualCandidates(
    String runId, {
    required int count,
    ExploreRollSnapshot? firstRollSnapshot,
  }) async {
    final repository = ref.read(styleExploreRunRepositoryProvider);
    final run = await repository.getRun(runId);
    if (run == null) {
      throw StateError('Style explore run does not exist: $runId');
    }

    ExploreRound? manualRound;
    for (final round in run.rounds.reversed) {
      if (round.phase == ExploreRoundPhase.manual) {
        manualRound = round;
        break;
      }
    }
    final rounds = [...run.rounds];
    if (manualRound == null) {
      manualRound = ExploreRound(
        id: const Uuid().v4(),
        number: rounds.length + 1,
        phase: ExploreRoundPhase.manual,
        status: ExploreRoundStatus.generated,
        createdAt: DateTime.now(),
        targetCount: 0,
      );
      rounds.add(manualRound);
    }
    final roundId = manualRound.id;

    final candidates = [
      for (var i = 0; i < count; i++)
        ExploreCandidate(
          id: const Uuid().v4(),
          roundId: roundId,
          rollSnapshot: i == 0 ? firstRollSnapshot : null,
          lineage: const ExploreLineage(
            operation: ExploreLineageOperation.manual,
          ),
        ),
    ];
    final roundIndex = rounds.indexWhere((round) => round.id == roundId);
    rounds[roundIndex] = rounds[roundIndex].copyWith(
      candidateIds: [
        ...rounds[roundIndex].candidateIds,
        for (final candidate in candidates) candidate.id,
      ],
    );
    await overwrite(
      run.copyWith(
        rounds: rounds,
        candidates: [...run.candidates, ...candidates],
      ),
    );
    return candidates;
  }

  /// 候选通用更新：读-改-写单个候选后落盘。
  Future<ExploreRun> updateCandidate(
    String runId,
    String candidateId,
    ExploreCandidate Function(ExploreCandidate candidate) update,
  ) {
    return _mutateRun(runId, (run) {
      if (!run.candidates.any((c) => c.id == candidateId)) {
        throw StateError('Candidate $candidateId not in run $runId');
      }
      final candidates = [
        for (final candidate in run.candidates)
          candidate.id == candidateId ? update(candidate) : candidate,
      ];
      return run.copyWith(candidates: candidates);
    });
  }

  /// 评审字段更新（心形/预标记/正式标签）。
  ///
  /// 写正式标签时传 [formalReviewedAt]（筛选会话打标=写当前时间）；
  /// [clearLabel] 会一并清掉归类时间。
  Future<ExploreRun> updateReview(
    String runId,
    String candidateId, {
    bool? heart,
    ExploreReviewLabel? preliminaryLabel,
    bool clearPreliminaryLabel = false,
    ExploreReviewLabel? label,
    bool clearLabel = false,
    DateTime? formalReviewedAt,
  }) {
    return updateCandidate(runId, candidateId, (candidate) {
      var review = candidate.review;
      if (heart != null) review = review.copyWith(heart: heart);
      if (preliminaryLabel != null || clearPreliminaryLabel) {
        review = review.copyWith(preliminaryLabel: preliminaryLabel);
      }
      if (label != null || clearLabel) {
        review = review.copyWith(
          label: label,
          formalReviewedAt: formalReviewedAt,
        );
      }
      return candidate.copyWith(review: review);
    });
  }

  /// 进入正式筛选：run → reviewing。
  ///
  /// 允许从 draft（手动候选 run）/generated/reviewing（续筛）/completed
  /// （复筛）进入；必须有可审查候选（done）。
  Future<ExploreRun> beginReview(String runId) {
    return _mutateRun(runId, (run) {
      if (!exploreReviewableStatuses.contains(run.status)) {
        throw StateError('Run $runId cannot enter review from ${run.status}');
      }
      if (run.reviewableCandidates.isEmpty) {
        throw StateError('Run $runId has no reviewable candidates');
      }
      return run.copyWith(status: ExploreRunStatus.reviewing);
    });
  }

  /// 完成正式筛选：全部可审查候选都有正式标签才允许 → completed。
  /// 返回 false = 门禁拒绝（状态非 reviewing 或未归类完），不改动数据。
  Future<bool> completeReview(String runId) async {
    final repository = ref.read(styleExploreRunRepositoryProvider);
    final run = await repository.getRun(runId);
    if (run == null) return false;
    if (run.status != ExploreRunStatus.reviewing) return false;
    if (!run.isReviewComplete) return false;
    await overwrite(run.copyWith(status: ExploreRunStatus.completed));
    return true;
  }

  /// 生成结果字段更新。
  Future<ExploreRun> updateGeneration(
    String runId,
    String candidateId,
    ExploreCandidateGeneration generation,
  ) {
    return updateCandidate(
      runId,
      candidateId,
      (candidate) => candidate.copyWith(generation: generation),
    );
  }

  /// 建家族（阶段 D）：父本串列表 → 家族 + 第一代父本集（active）。
  ///
  /// 父本串去首尾空白、去空、按串去重（保序）；至少需要一个有效串，
  /// 否则抛 [StateError]。名称为空时回退「家族 N」。
  Future<ExploreFamily> createFamily(
    String runId, {
    required String name,
    required List<({String? sourceCandidateId, String artistString})> parents,
  }) {
    return _mutateRun(runId, (run) {
      final deduped = <({String? sourceCandidateId, String artistString})>[];
      final seen = <String>{};
      for (final parent in parents) {
        final text = parent.artistString.trim();
        if (text.isEmpty) continue;
        if (seen.add(text)) {
          deduped.add((
            sourceCandidateId: parent.sourceCandidateId,
            artistString: text,
          ));
        }
      }
      if (deduped.isEmpty) {
        throw StateError('创建家族至少需要一个有效父本串');
      }
      final familyId = const Uuid().v4();
      final parentSet = ExploreParentSet(
        id: const Uuid().v4(),
        familyId: familyId,
        generation: 1,
        status: ExploreParentSetStatus.active,
        parents: [
          for (final parent in deduped)
            ExploreParent(
              id: const Uuid().v4(),
              sourceCandidateId: parent.sourceCandidateId,
              artistString: parent.artistString,
            ),
        ],
      );
      final trimmedName = name.trim();
      final family = ExploreFamily(
        id: familyId,
        name: trimmedName.isEmpty
            ? '家族 ${run.families.length + 1}'
            : trimmedName,
        createdAt: DateTime.now(),
        rootParentSetId: parentSet.id,
        activeParentSetId: parentSet.id,
      );
      return run.copyWith(
        parentSets: [...run.parentSets, parentSet],
        families: [...run.families, family],
      );
    }).then((run) => run.families.last);
  }

  /// 建分支（阶段 D）：多选最新代优秀子代 + 第一代父本回交 →
  /// 新父本集（generation+1，旧活跃集置 used，家族活跃指针前移）。
  ///
  /// 不变量（违反抛 [StateError]，消息为稳定语义串供测试断言）：
  /// - 所选候选必须全部属于活跃父本集的深度轮（只能从最新代选）；
  /// - 活跃集的所有深度轮必须全部完成（无 pending 候选/未完成轮次）；
  /// - 子代串去重后不得与第一代回交父本串完全重复。
  Future<ExploreParentSet> createBranch(
    String runId, {
    required String familyId,
    required List<String> selectedCandidateIds,
    String? branchName,
  }) {
    String? newParentSetId;
    return _mutateRun(runId, (run) {
      final family = run.familyById(familyId);
      if (family == null) throw StateError('家族不存在: $familyId');
      final activeSet = run.parentSetById(family.activeParentSetId);
      if (activeSet == null) {
        throw StateError('活跃父本集不存在: ${family.activeParentSetId}');
      }

      // 当前代轮次全完成。
      if (!exploreParentSetRoundsComplete(run, activeSet)) {
        throw StateError('当前代还有未完成的候选轮');
      }

      // 只能从最新代选：所选候选必须属于活跃集的深度轮。
      final activeRoundIds = {
        for (final round in run.rounds)
          if (round.parentSetId == activeSet.id) round.id,
      };
      final selected = <ExploreCandidate>[];
      for (final id in selectedCandidateIds) {
        final candidate = run.candidateById(id);
        if (candidate == null || !activeRoundIds.contains(candidate.roundId)) {
          throw StateError('只能从最新代候选堆建分支');
        }
        selected.add(candidate);
      }
      if (selected.isEmpty) {
        throw StateError('请选择至少一张子代候选');
      }

      // 子代串：优先登记时的变异串，回退 roll 快照提取；按串去重。
      final newParents = <ExploreParent>[];
      final seenStrings = <String>{};
      for (final candidate in selected) {
        final text =
            (candidate.lineage.mutatedText ?? exploreParentStringFor(candidate))
                .trim();
        if (text.isEmpty || !seenStrings.add(text)) continue;
        newParents.add(
          ExploreParent(
            id: const Uuid().v4(),
            sourceCandidateId: candidate.id,
            artistString: text,
          ),
        );
      }
      if (newParents.isEmpty) {
        throw StateError('所选子代没有可用的串');
      }

      // 回交：第一代父本全部并入（新 id、保留偏好）；子代串不得与其重复。
      final rootSet = run.parentSetById(family.rootParentSetId);
      final backcross = [
        if (rootSet != null)
          for (final parent in rootSet.parents)
            ExploreParent(
              id: const Uuid().v4(),
              sourceCandidateId: parent.sourceCandidateId,
              artistString: parent.artistString,
              preference: parent.preference,
            ),
      ];
      final backcrossStrings = {
        for (final parent in backcross) parent.artistString,
      };
      for (final child in newParents) {
        if (backcrossStrings.contains(child.artistString)) {
          throw StateError('所选子代与父本串完全重复');
        }
      }

      final trimmedBranch = branchName?.trim();
      final newSet = ExploreParentSet(
        id: const Uuid().v4(),
        familyId: family.id,
        generation: activeSet.generation + 1,
        status: ExploreParentSetStatus.active,
        branchName: trimmedBranch == null || trimmedBranch.isEmpty
            ? null
            : trimmedBranch,
        parents: [...newParents, ...backcross],
      );
      newParentSetId = newSet.id;
      return run.copyWith(
        parentSets: [
          for (final set in run.parentSets)
            set.id == activeSet.id
                ? set.copyWith(status: ExploreParentSetStatus.used)
                : set,
          newSet,
        ],
        families: [
          for (final entry in run.families)
            entry.id == family.id
                ? entry.copyWith(activeParentSetId: newSet.id)
                : entry,
        ],
      );
    }).then((run) => run.parentSetById(newParentSetId!)!);
  }

  /// 两两比较登记（阶段 D 偏好排序简版）：
  /// left/right 胜方 preference +1.0；neither 各 -0.25（下限 0.25）；
  /// skip 只记录不改偏好。记录附加到父本集 comparisons。
  Future<ExploreRun> recordComparison(
    String runId,
    String parentSetId, {
    required String leftParentId,
    required String rightParentId,
    required ExploreComparisonResult result,
  }) {
    return _mutateRun(runId, (run) {
      final set = run.parentSetById(parentSetId);
      if (set == null) throw StateError('父本集不存在: $parentSetId');
      final ids = {for (final parent in set.parents) parent.id};
      if (!ids.contains(leftParentId) || !ids.contains(rightParentId)) {
        throw StateError('比较目标父本不在父本集中: $parentSetId');
      }
      final parents = [
        for (final parent in set.parents)
          if (parent.id == leftParentId &&
              result == ExploreComparisonResult.left)
            parent.copyWith(preference: parent.preference + 1.0)
          else if (parent.id == rightParentId &&
              result == ExploreComparisonResult.right)
            parent.copyWith(preference: parent.preference + 1.0)
          else if ((parent.id == leftParentId || parent.id == rightParentId) &&
              result == ExploreComparisonResult.neither)
            parent.copyWith(
              preference: (parent.preference - 0.25)
                  .clamp(0.25, double.infinity)
                  .toDouble(),
            )
          else
            parent,
      ];
      final comparison = ExplorePairwiseComparison(
        leftParentId: leftParentId,
        rightParentId: rightParentId,
        result: result,
        comparedAt: DateTime.now(),
      );
      final updated = set.copyWith(
        parents: parents,
        comparisons: [...set.comparisons, comparison],
      );
      return run.copyWith(
        parentSets: [
          for (final entry in run.parentSets)
            entry.id == parentSetId ? updated : entry,
        ],
      );
    });
  }

  Future<ExploreRun> _mutateRun(
    String runId,
    ExploreRun Function(ExploreRun run) update,
  ) async {
    final repository = ref.read(styleExploreRunRepositoryProvider);
    final run = await repository.getRun(runId);
    if (run == null) {
      throw StateError('Style explore run does not exist: $runId');
    }
    return overwrite(update(run));
  }

  Future<T> _mutate<T>(
    Future<T> Function(StyleExploreRunRepository repository) action,
  ) async {
    final repository = ref.read(styleExploreRunRepositoryProvider);
    try {
      final result = await action(repository);
      state = AsyncData(ExploreRunListState(runs: await repository.load()));
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final exploreRunListNotifierProvider =
    AsyncNotifierProvider<ExploreRunListNotifier, ExploreRunListState>(
      ExploreRunListNotifier.new,
    );

/// 当前选中的 Run（右栏画廊与控制条的目标）。
final exploreActiveRunIdProvider = StateProvider<String?>((ref) => null);

/// 当前选中的 Run 实体（可能为 null：未选中或列表未就绪）。
final exploreActiveRunProvider = Provider<ExploreRun?>((ref) {
  final activeId = ref.watch(exploreActiveRunIdProvider);
  if (activeId == null) return null;
  return ref
      .watch(exploreRunListNotifierProvider)
      .valueOrNull
      ?.runById(activeId);
});

/// 候选画廊筛选（牌堆语义：全部/心形/待审/T/S/R/失败）。
enum ExploreGalleryFilter {
  all,
  hearted,
  pendingReview,
  treasure,
  special,
  reject,
  failed,
}

final exploreGalleryFilterProvider = StateProvider<ExploreGalleryFilter>(
  (ref) => ExploreGalleryFilter.all,
);

/// 筛选匹配（纯函数，widget 测试可直接断言）。
bool exploreCandidateMatchesFilter(
  ExploreCandidate candidate,
  ExploreGalleryFilter filter,
) {
  switch (filter) {
    case ExploreGalleryFilter.all:
      return true;
    case ExploreGalleryFilter.hearted:
      return candidate.review.heart;
    case ExploreGalleryFilter.pendingReview:
      return !candidate.review.heart &&
          candidate.review.preliminaryLabel == null &&
          candidate.review.label == null;
    case ExploreGalleryFilter.treasure:
      return _hasLabel(candidate, ExploreReviewLabel.treasure);
    case ExploreGalleryFilter.special:
      return _hasLabel(candidate, ExploreReviewLabel.special);
    case ExploreGalleryFilter.reject:
      return _hasLabel(candidate, ExploreReviewLabel.reject);
    case ExploreGalleryFilter.failed:
      return candidate.generation.status ==
          ExploreCandidateGenerationStatus.failed;
  }
}

bool _hasLabel(ExploreCandidate candidate, ExploreReviewLabel label) {
  return candidate.review.preliminaryLabel == label ||
      candidate.review.label == label;
}

/// 允许进入正式筛选的 run 状态（generating/paused 有未跑完的生成，
/// cancelled 是终态，均不放行）。
const exploreReviewableStatuses = {
  ExploreRunStatus.draft,
  ExploreRunStatus.generated,
  ExploreRunStatus.reviewing,
  ExploreRunStatus.completed,
};

/// 候选画廊视图模式：网格 / 牌堆（按正式标签分组）。
enum ExploreGalleryViewMode { grid, deck }

final exploreGalleryViewModeProvider = StateProvider<ExploreGalleryViewMode>(
  (ref) => ExploreGalleryViewMode.grid,
);

/// 多候选 roll 正向串合并：顶层逗号切原子、去重（保序）、`, ` 拼接
/// （无尾部逗号）。单串输入等价于原子规范化。
String mergeExploreRollPositives(Iterable<String> positives) {
  final seen = <String>{};
  final atoms = <String>[];
  for (final positive in positives) {
    for (final raw in positive.split(',')) {
      final atom = raw.trim();
      if (atom.isEmpty) continue;
      if (seen.add(atom)) atoms.add(atom);
    }
  }
  return atoms.join(', ');
}

// ==================== 阶段 D：家族 / 谱系 ====================

/// 谱系区当前选中的家族 id（UI 态；切换 run 时由谱系面板校正）。
final exploreActiveFamilyIdProvider = StateProvider<String?>((ref) => null);

/// 谱系区代际卡片列的内容高度（session 态，拖拽手柄调整，重启不保留）。
final exploreLineagePanelHeightProvider = StateProvider<double>((ref) => 320);

/// 谱系区内容高度的可调范围。
const exploreLineagePanelMinHeight = 160.0;
const exploreLineagePanelMaxHeight = 600.0;

/// 父本集的所有深度轮是否全部完成（建分支前置条件）：
/// 无未完成状态的轮次，且轮内无 pending 候选。
bool exploreParentSetRoundsComplete(
  ExploreRun run,
  ExploreParentSet parentSet,
) {
  final roundIds = <String>{};
  for (final round in run.rounds) {
    if (round.parentSetId != parentSet.id) continue;
    if (round.status == ExploreRoundStatus.pending ||
        round.status == ExploreRoundStatus.generating) {
      return false;
    }
    roundIds.add(round.id);
  }
  return !run.candidates.any(
    (candidate) =>
        roundIds.contains(candidate.roundId) &&
        candidate.generation.status == ExploreCandidateGenerationStatus.pending,
  );
}

/// 谱系区一代的展示数据：父本集 + 该集深度轮 + 深度轮产出的候选堆。
class ExploreLineageGeneration {
  ExploreLineageGeneration({
    required this.parentSet,
    required List<ExploreRound> rounds,
    required List<ExploreCandidate> pile,
  }) : rounds = List.unmodifiable(rounds),
       pile = List.unmodifiable(pile);

  final ExploreParentSet parentSet;
  final List<ExploreRound> rounds;

  /// 该父本集深度轮产出的候选（按登记序）。
  final List<ExploreCandidate> pile;
}

/// 组装家族的代际卡片列（按父本集 generation 升序；纯函数可测）。
List<ExploreLineageGeneration> exploreFamilyGenerations(
  ExploreRun run,
  ExploreFamily family,
) {
  final sets = [
    for (final set in run.parentSets)
      if (set.familyId == family.id) set,
  ]..sort((a, b) => a.generation.compareTo(b.generation));
  return [
    for (final set in sets)
      ExploreLineageGeneration(
        parentSet: set,
        rounds: [
          for (final round in run.rounds)
            if (round.parentSetId == set.id) round,
        ],
        pile: [
          for (final candidate in run.candidates)
            if (run.roundById(candidate.roundId)?.parentSetId == set.id)
              candidate,
        ],
      ),
  ];
}
