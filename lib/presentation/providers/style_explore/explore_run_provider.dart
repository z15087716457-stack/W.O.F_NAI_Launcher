import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/style_explore_run_storage.dart';
import '../../../data/models/style_explore/explore_run.dart';
import '../../../data/repositories/style_explore_run_repository.dart';
import '../../../data/services/explore_run_image_store.dart';

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
  Future<ExploreRun> updateReview(
    String runId,
    String candidateId, {
    bool? heart,
    ExploreReviewLabel? preliminaryLabel,
    bool clearPreliminaryLabel = false,
    ExploreReviewLabel? label,
    bool clearLabel = false,
  }) {
    return updateCandidate(runId, candidateId, (candidate) {
      var review = candidate.review;
      if (heart != null) review = review.copyWith(heart: heart);
      if (preliminaryLabel != null || clearPreliminaryLabel) {
        review = review.copyWith(preliminaryLabel: preliminaryLabel);
      }
      if (label != null || clearLabel) {
        review = review.copyWith(label: label);
      }
      return candidate.copyWith(review: review);
    });
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
