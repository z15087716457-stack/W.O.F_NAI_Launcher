import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/style_explore_run_storage.dart';
import '../../../core/utils/nai_prompt_segments.dart';
import '../../../core/utils/nai_prompt_syntax.dart';
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

  /// 删除 Run，连带删除候选图副本目录（源图不动）。
  Future<void> delete(String id) async {
    await _mutate((repository) => repository.delete(id));
    await ref.read(exploreRunImageStoreProvider).deleteRunDir(id);
  }

  /// 追加手动候选（探索页生成按钮登记）：每次调用新建一个手动轮（
  /// 状态直接 generated 不经 runner），一次落盘追加 [count] 个 pending
  /// 候选（lineage.operation=manual）。[rollSnapshots] 按追加候选顺序写入。
  Future<List<ExploreCandidate>> addManualCandidates(
    String runId, {
    required int count,
    List<ExploreRollSnapshot?>? rollSnapshots,
  }) {
    return _serializeMutation(
      () => _performMutation((repository) async {
        final run = await repository.getRun(runId);
        if (run == null) {
          throw StateError('Style explore run does not exist: $runId');
        }

        final manualRound = ExploreRound(
          id: const Uuid().v4(),
          number: run.rounds.length + 1,
          phase: ExploreRoundPhase.manual,
          status: ExploreRoundStatus.generated,
          createdAt: DateTime.now(),
          targetCount: count,
        );
        final rounds = [...run.rounds, manualRound];
        final roundId = manualRound.id;
        final snapshots = rollSnapshots;

        final candidates = [
          for (var i = 0; i < count; i++)
            ExploreCandidate(
              id: const Uuid().v4(),
              roundId: roundId,
              rollSnapshot: snapshots != null && i < snapshots.length
                  ? snapshots[i]
                  : null,
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
        await repository.overwrite(
          run.copyWith(
            rounds: rounds,
            candidates: [...run.candidates, ...candidates],
          ),
        );
        return candidates;
      }),
    );
  }

  /// Cancel only a still-paused run, reading its latest state in the queue.
  Future<ExploreRun> cancelPaused(String id) => _mutateRun(id, (current) {
    if (current.status != ExploreRunStatus.paused) return current;
    return current.copyWith(
      status: ExploreRunStatus.cancelled,
      candidates: [
        for (final candidate in current.candidates)
          candidate.generation.status == ExploreCandidateGenerationStatus.pending
              ? candidate.copyWith(
                  generation: candidate.generation.copyWith(
                    status: ExploreCandidateGenerationStatus.failed,
                    error: 'cancelled',
                  ),
                )
              : candidate,
      ],
      rounds: [
        for (final round in current.rounds)
          round.status == ExploreRoundStatus.generating ||
                  round.status == ExploreRoundStatus.pending
              ? round.copyWith(status: ExploreRoundStatus.cancelled)
              : round,
      ],
    );
  });

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

  /// 收藏标记更新。
  Future<ExploreRun> updateReview(
    String runId,
    String candidateId, {
    bool? heart,
  }) {
    return updateCandidate(runId, candidateId, (candidate) {
      var review = candidate.review;
      if (heart != null) review = review.copyWith(heart: heart);
      return candidate.copyWith(review: review);
    });
  }

  /// 新建用户文件夹（名称去首尾空白；空名抛 [StateError]）。
  Future<ExploreCandidateFolder> createFolder(String runId, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw StateError('文件夹名称不能为空');
    }
    final folder = ExploreCandidateFolder(
      id: const Uuid().v4(),
      name: trimmed,
      createdAt: DateTime.now(),
    );
    return _mutateRun(runId, (run) {
      if (run.folders.any((entry) => entry.name == trimmed)) {
        throw StateError('文件夹名称已存在: $trimmed');
      }
      return run.copyWith(folders: [...run.folders, folder]);
    }).then((_) => folder);
  }

  /// 重命名用户文件夹。
  Future<ExploreRun> renameFolder(String runId, String folderId, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw StateError('文件夹名称不能为空');
    }
    return _mutateRun(runId, (run) {
      if (run.folderById(folderId) == null) {
        throw StateError('文件夹不存在: $folderId');
      }
      if (run.folders.any(
        (entry) => entry.id != folderId && entry.name == trimmed,
      )) {
        throw StateError('文件夹名称已存在: $trimmed');
      }
      return run.copyWith(
        folders: [
          for (final folder in run.folders)
            folder.id == folderId ? folder.copyWith(name: trimmed) : folder,
        ],
      );
    });
  }

  /// 删除用户文件夹：成员回未分类，候选图与记录不动。
  Future<ExploreRun> deleteFolder(String runId, String folderId) {
    return _mutateRun(runId, (run) {
      if (run.folderById(folderId) == null) {
        throw StateError('文件夹不存在: $folderId');
      }
      return run.copyWith(
        folders: [
          for (final folder in run.folders)
            if (folder.id != folderId) folder,
        ],
        candidates: [
          for (final candidate in run.candidates)
            candidate.folderId == folderId
                ? candidate.copyWith(folderId: null)
                : candidate,
        ],
      );
    }).then((updated) {
      // 画廊筛选正指着被删文件夹时回落「全部」。
      final filter = ref.read(exploreGalleryFilterProvider);
      if (filter is ExploreGalleryFilterFolder && filter.folderId == folderId) {
        ref.read(exploreGalleryFilterProvider.notifier).state =
            const ExploreGalleryFilterAll();
      }
      return updated;
    });
  }

  /// 调整文件夹顺序（画廊筛选排拖动落序）：orderedIds 必须与现状
  /// 同集合同长度，否则抛 [StateError]。牌堆分组顺序同源跟随。
  Future<ExploreRun> reorderFolders(String runId, List<String> orderedIds) {
    return _mutateRun(runId, (run) {
      final byId = {for (final folder in run.folders) folder.id: folder};
      if (orderedIds.length != run.folders.length ||
          orderedIds.any((id) => !byId.containsKey(id))) {
        throw StateError('文件夹顺序与现状不一致');
      }
      return run.copyWith(folders: [for (final id in orderedIds) byId[id]!]);
    });
  }

  /// 单候选归类：`folderId` 为 null = 移回未分类。
  Future<ExploreRun> assignCandidateFolder(
    String runId,
    String candidateId,
    String? folderId,
  ) {
    return assignCandidatesFolder(runId, [candidateId], folderId);
  }

  /// 批量归类（多选归档与批量动作共用）。
  Future<ExploreRun> assignCandidatesFolder(
    String runId,
    List<String> candidateIds,
    String? folderId,
  ) {
    final target = candidateIds.toSet();
    if (target.isEmpty) {
      throw StateError('请选择至少一张候选');
    }
    return _mutateRun(runId, (run) {
      if (folderId != null && run.folderById(folderId) == null) {
        throw StateError('文件夹不存在: $folderId');
      }
      for (final id in target) {
        if (run.candidateById(id) == null) {
          throw StateError('Candidate $id not in run $runId');
        }
      }
      return run.copyWith(
        candidates: [
          for (final candidate in run.candidates)
            target.contains(candidate.id)
                ? candidate.copyWith(folderId: folderId)
                : candidate,
        ],
      );
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

  /// 连记录删除候选（FEAT-55 拍板方向 = 连记录删）：从 `run.candidates`
  /// 移除 + 清 `rounds.candidateIds` 与其余候选 `lineage.parentCandidateIds`
  /// 的引用；父本集 `sourceCandidateId` 溯源标记留作留痕（查不到候选自然
  /// 不显示角标）。图片副本由调用方先经 imageStore 删，本方法只动记录。
  Future<ExploreRun> removeCandidates(String runId, List<String> candidateIds) {
    final target = candidateIds.toSet();
    if (target.isEmpty) {
      throw StateError('请选择至少一张候选');
    }
    return _mutateRun(runId, (run) {
      for (final id in target) {
        if (run.candidateById(id) == null) {
          throw StateError('Candidate $id not in run $runId');
        }
      }
      return run.copyWith(
        candidates: [
          for (final candidate in run.candidates)
            if (!target.contains(candidate.id))
              candidate.lineage.parentCandidateIds.any(target.contains)
                  ? candidate.copyWith(
                      lineage: candidate.lineage.copyWith(
                        parentCandidateIds: [
                          for (final pid
                              in candidate.lineage.parentCandidateIds)
                            if (!target.contains(pid)) pid,
                        ],
                      ),
                    )
                  : candidate,
        ],
        rounds: [
          for (final round in run.rounds)
            round.candidateIds.any(target.contains)
                ? round.copyWith(
                    candidateIds: [
                      for (final id in round.candidateIds)
                        if (!target.contains(id)) id,
                    ],
                  )
                : round,
        ],
      );
    });
  }

  /// 删除整个家族（谱系整族清出画廊）：移除 family + 其全部父本集 +
  /// 这些集的深度轮 + 轮内全部候选记录，并清掉存活候选
  /// `lineage.parentCandidateIds` 里的已删引用。候选图片文件不动
  /// （图走正常生图流程进历史，由用户自行清理）。
  ///
  /// 拒删条件（抛 [StateError]，消息为稳定语义串供 UI/测试断言）：
  /// - 家族不存在；
  /// - 族内任一深度轮处于 pending/generating，或轮内还有 pending
  ///   候选（在途删除会中断生成会话，先取消/续跑完再删）。
  Future<ExploreRun> deleteFamily(String runId, String familyId) {
    return _mutateRun(runId, (run) {
      if (run.familyById(familyId) == null) {
        throw StateError('家族不存在: $familyId');
      }
      // 与 exploreFamilyGenerations 同口径：轮归属按 parentSetId 判定
      // （familyId 字段只是冗余标注，归组真源是 parentSetId）。
      final setIds = {
        for (final set in run.parentSets)
          if (set.familyId == familyId) set.id,
      };
      final roundIds = {
        for (final round in run.rounds)
          if (round.parentSetId != null && setIds.contains(round.parentSetId))
            round.id,
      };
      for (final round in run.rounds) {
        if (roundIds.contains(round.id) &&
            (round.status == ExploreRoundStatus.pending ||
                round.status == ExploreRoundStatus.generating)) {
          throw StateError('家族内还有未完成的候选轮');
        }
      }
      final removedCandidateIds = {
        for (final candidate in run.candidates)
          if (roundIds.contains(candidate.roundId)) candidate.id,
      };
      if (run.candidates.any(
        (candidate) =>
            removedCandidateIds.contains(candidate.id) &&
            candidate.generation.status ==
                ExploreCandidateGenerationStatus.pending,
      )) {
        throw StateError('家族内还有未完成的候选轮');
      }
      return run.copyWith(
        families: [
          for (final family in run.families)
            if (family.id != familyId) family,
        ],
        parentSets: [
          for (final set in run.parentSets)
            if (!setIds.contains(set.id)) set,
        ],
        rounds: [
          for (final round in run.rounds)
            if (!roundIds.contains(round.id)) round,
        ],
        candidates: [
          for (final candidate in run.candidates)
            if (!removedCandidateIds.contains(candidate.id))
              candidate.lineage.parentCandidateIds.any(
                    removedCandidateIds.contains,
                  )
                  ? candidate.copyWith(
                      lineage: candidate.lineage.copyWith(
                        parentCandidateIds: [
                          for (final pid
                              in candidate.lineage.parentCandidateIds)
                            if (!removedCandidateIds.contains(pid)) pid,
                        ],
                      ),
                    )
                  : candidate,
        ],
      );
    }).then((updated) {
      // 谱系面板正指着被删家族时清指针（面板本身有 ?? families.last 兜底，
      // 显式清掉避免悬空 id 残留）。
      if (ref.read(exploreActiveFamilyIdProvider) == familyId) {
        ref.read(exploreActiveFamilyIdProvider.notifier).state = null;
      }
      return updated;
    });
  }

  /// 建家族（阶段 D）：父本串列表 → 家族 + 第一代父本集（active）。
  ///
  /// 父本串去首尾空白、去空、按串去重（保序）；至少需要一个有效串，
  /// 否则抛 [StateError]。名称为空时用调用方传入的本地化默认名。
  Future<ExploreFamily> createFamily(
    String runId, {
    required String name,
    String defaultName = '',
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
      final trimmedName = name.trim().isEmpty
          ? defaultName.trim()
          : name.trim();
      if (trimmedName.isEmpty) throw StateError('进化线名称不能为空');
      final family = ExploreFamily(
        id: familyId,
        name: trimmedName,
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

  /// Append only to the active generation, on the same serialized mutation
  /// chain as generation and review updates. Existing preference stays intact.
  Future<ExploreParentSet> addParentsToActiveSet(
    String runId, {
    required String familyId,
    required List<({String? sourceCandidateId, String artistString})> parents,
  }) {
    String? activeId;
    return _mutateRun(runId, (run) {
      final family = run.familyById(familyId);
      if (family == null) throw StateError('进化线不存在');
      final active = run.parentSetById(family.activeParentSetId);
      if (active == null) throw StateError('活跃父本集不存在');
      if (!exploreParentSetRoundsComplete(run, active)) {
        throw StateError('这一代还在生成');
      }
      activeId = active.id;
      final seen = active.parents.map((p) => p.artistString.trim()).toSet();
      final added = <ExploreParent>[];
      for (final parent in parents) {
        final text = parent.artistString.trim();
        if (text.isEmpty || !seen.add(text)) continue;
        added.add(
          ExploreParent(
            id: const Uuid().v4(),
            sourceCandidateId: parent.sourceCandidateId,
            artistString: text,
          ),
        );
      }
      if (seen.isEmpty) throw StateError('至少需要一个有效父本串');
      return run.copyWith(
        parentSets: [
          for (final set in run.parentSets)
            if (set.id == active.id)
              set.copyWith(parents: [...set.parents, ...added])
            else
              set,
        ],
      );
    }).then((run) => run.parentSetById(activeId!)!);
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
      if (leftParentId == rightParentId) {
        throw StateError('比较双方不能是同一父本: $parentSetId');
      }
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

  /// 变更尾链：读-改-写跨 await，并发变更若无序交错会读同一旧快照
  /// 互相覆盖（lost update）。所有变更（_mutate/_mutateRun/
  /// addManualCandidates）都经同一尾链串行。
  Future<void> _mutationTail = Future<void>.value();

  Future<T> _serializeMutation<T>(Future<T> Function() action) {
    final result = _mutationTail.then((_) => action());
    // 尾链自身不携带错误（错误经 result 传给调用方），保证后续变更
    // 不被前一次失败卡死。
    _mutationTail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<ExploreRun> _mutateRun(
    String runId,
    ExploreRun Function(ExploreRun run) update,
  ) {
    // 整段读-改-写纳入串行；直接打 repository，不绕道 overwrite()
    // （会二次进 _serializeMutation 自我死锁）。
    return _serializeMutation(
      () => _performMutation((repository) async {
        final run = await repository.getRun(runId);
        if (run == null) {
          throw StateError('Style explore run does not exist: $runId');
        }
        return repository.overwrite(update(run));
      }),
    );
  }

  Future<T> _mutate<T>(
    Future<T> Function(StyleExploreRunRepository repository) action,
  ) => _serializeMutation(() => _performMutation(action));

  Future<T> _performMutation<T>(
    Future<T> Function(StyleExploreRunRepository repository) action,
  ) async {
    final repository = ref.read(styleExploreRunRepositoryProvider);
    try {
      final result = await action(repository);
      state = AsyncData(ExploreRunListState(runs: await repository.load()));
      return result;
    } catch (error, stackTrace) {
      // 单次变更失败不污染列表：保留既有数据快照让 UI 继续可用（错误
      // 由调用方 toast），仅在还没有任何数据时才落 AsyncError。
      final previous = state.valueOrNull;
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
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

/// 候选画廊筛选：全部 / 收藏 / 文件夹（folderId 为 null 即未分类）。
/// 「失败」chip 已退役——失败候选只在「全部」可见（卡片状态徽标照旧），
/// 垃圾清理走「自建文件夹 + 全选删除」工作流。
sealed class ExploreGalleryFilter {
  const ExploreGalleryFilter();
}

final class ExploreGalleryFilterAll extends ExploreGalleryFilter {
  const ExploreGalleryFilterAll();
}

final class ExploreGalleryFilterHearted extends ExploreGalleryFilter {
  const ExploreGalleryFilterHearted();
}

final class ExploreGalleryFilterFolder extends ExploreGalleryFilter {
  const ExploreGalleryFilterFolder(this.folderId);

  /// null = 未分类分组。
  final String? folderId;

  @override
  bool operator ==(Object other) =>
      other is ExploreGalleryFilterFolder && other.folderId == folderId;

  @override
  int get hashCode => folderId.hashCode;
}

final exploreGalleryFilterProvider = StateProvider<ExploreGalleryFilter>(
  (ref) => const ExploreGalleryFilterAll(),
);

/// 文件夹筛选指向不存在的文件夹（已删/切 run 的悬空指针）时回落「全部」。
ExploreGalleryFilter effectiveExploreGalleryFilter(
  ExploreRun run,
  ExploreGalleryFilter filter,
) {
  if (filter is ExploreGalleryFilterFolder &&
      filter.folderId != null &&
      run.folderById(filter.folderId!) == null) {
    return const ExploreGalleryFilterAll();
  }
  return filter;
}

/// 筛选匹配（纯函数，widget 测试可直接断言）。
bool exploreCandidateMatchesFilter(
  ExploreCandidate candidate,
  ExploreGalleryFilter filter,
) {
  return switch (filter) {
    ExploreGalleryFilterAll() => true,
    ExploreGalleryFilterHearted() => candidate.review.heart,
    ExploreGalleryFilterFolder(:final folderId) =>
      candidate.folderId == folderId,
  };
}

/// 多候选 roll 正向串合并：顶层逗号切原子、去重（保序）、`, ` 拼接
/// （无尾部逗号）。单串输入等价于原子规范化。
String mergeExploreRollPositives(Iterable<String> positives) {
  final seen = <String>{};
  final atoms = <String>[];
  for (final positive in positives) {
    final pending = <String>[];
    var weighted = false;
    void appendPending() {
      final atom = pending.join(', ');
      if (atom.isNotEmpty && seen.add(atom)) atoms.add(atom);
      pending.clear();
    }

    for (final raw in splitNaiPromptSegments(positive)) {
      pending.add(raw);
      for (final token in NaiPromptSyntax.scan(raw)) {
        if (token.kind == NaiPromptTokenKind.prefix) weighted = true;
        if (token.kind == NaiPromptTokenKind.closure) weighted = false;
      }
      if (!weighted) appendPending();
    }
    appendPending();
  }
  return atoms.join(', ');
}

// ==================== 阶段 D：家族 / 谱系 ====================

/// 谱系区当前选中的家族 id（UI 态；切换 run 时由谱系面板校正）。
final exploreActiveFamilyIdProvider = StateProvider<String?>((ref) => null);

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
