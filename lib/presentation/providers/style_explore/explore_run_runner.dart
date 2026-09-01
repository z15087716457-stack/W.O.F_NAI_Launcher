import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/image/image_params.dart';
import '../../../data/models/style_explore/explore_run.dart';
import '../image_generation_provider.dart';
import '../pill_workspace_provider.dart';
import 'explore_roll_capture.dart';
import 'explore_run_provider.dart';

/// 探索生成调用签名（runner 通过注入函数解耦生成链，测试传假函数）。
typedef ExploreGenerateFn =
    Future<ExploreGenerationResult?> Function(ImageParams params);

/// 默认实现：走主生成 notifier 的探索专用入口。
final exploreGenerateFnProvider = Provider<ExploreGenerateFn>(
  (ref) =>
      (params) => ref
          .read(imageGenerationNotifierProvider.notifier)
          .generateForExplore(params),
);

/// Runner 运行态（UI 订阅：当前 run/进度/当前张）。
class ExploreRunRunnerState {
  const ExploreRunRunnerState({
    this.runId,
    this.isRunning = false,
    this.processedCount = 0,
    this.totalCount = 0,
    this.currentCandidateId,
  });

  final String? runId;
  final bool isRunning;

  /// 本次启动已处理张数（含失败）。
  final int processedCount;

  /// 本次启动时要处理的 pending 总数。
  final int totalCount;
  final String? currentCandidateId;

  ExploreRunRunnerState copyWith({
    String? runId,
    bool? isRunning,
    int? processedCount,
    int? totalCount,
    String? currentCandidateId,
  }) {
    return ExploreRunRunnerState(
      runId: runId ?? this.runId,
      isRunning: isRunning ?? this.isRunning,
      processedCount: processedCount ?? this.processedCount,
      totalCount: totalCount ?? this.totalCount,
      currentCandidateId: currentCandidateId ?? this.currentCandidateId,
    );
  }
}

/// 探索 Run 批量候选生成协调器。
///
/// 每张循环：等冷却（每拍查暂停/取消）→ roll 主双 lane → 抓 roll 快照
/// 写候选 → 当前主参数 + 投影构建单张参数（seed=-1 逐张随机）→ 注入的生成
/// 函数 → 成功复制图到 run 目录并登记 / 失败记 error。生成状态全程落盘，
/// 应用重启后 interrupted 的 generating run 恢复为 paused 可续跑。
///
/// lane 合并后 roll 的就是 main/negative lane（探索与主生成同源）；
/// roll 后用 lane 投影直接重建参数，不读 generationParams 的提示词
/// （updatePrompt 走 microtask，读完即生成等不到下一拍——红线）。
class ExploreRunRunner extends Notifier<ExploreRunRunnerState> {
  bool _pauseRequested = false;
  bool _cancelRequested = false;

  @override
  ExploreRunRunnerState build() {
    // 崩溃/退出遗留的 generating 是死状态（内存标志已丢），恢复为 paused。
    Future<void>.microtask(_recoverInterruptedRuns);
    return const ExploreRunRunnerState();
  }

  Future<void> _recoverInterruptedRuns() async {
    try {
      final repository = ref.read(styleExploreRunRepositoryProvider);
      final runs = await repository.load();
      // 加载期间 start 已接管：不恢复，避免把活跃 run 覆写成 paused。
      if (state.isRunning) return;
      var recovered = false;
      for (final run in runs) {
        if (run.status == ExploreRunStatus.generating) {
          await repository.overwrite(
            run.copyWith(status: ExploreRunStatus.paused),
          );
          recovered = true;
        }
      }
      if (recovered) {
        await ref.read(exploreRunListNotifierProvider.notifier).refresh();
      }
    } catch (error) {
      AppLogger.w(
        'Recover interrupted explore runs failed: $error',
        'ExploreRunRunner',
      );
    }
  }

  /// 启动/续跑。返回 false = 被门禁拒绝（重入/主生成在跑/状态不可启动）。
  Future<bool> start(String runId) async {
    if (state.isRunning) return false; // 防重入：同时间只允许一个 run
    if (ref.read(imageGenerationNotifierProvider).isGenerating) return false;
    final repository = ref.read(styleExploreRunRepositoryProvider);
    var run = await repository.getRun(runId);
    if (run == null) return false;
    const startable = {
      ExploreRunStatus.draft,
      ExploreRunStatus.paused,
      ExploreRunStatus.generated,
    };
    if (!startable.contains(run.status)) return false;

    var pending = run.pendingCandidates;
    if (pending.isEmpty) {
      // 新建基础轮 + pending 候选壳；roll 快照在每张生成前一刻才抓填。
      final round = ExploreRound(
        id: const Uuid().v4(),
        number: run.rounds.length + 1,
        phase: ExploreRoundPhase.basic,
        status: ExploreRoundStatus.generating,
        createdAt: DateTime.now(),
        targetCount: run.targetCount,
      );
      final shells = [
        for (var i = 0; i < run.targetCount; i++)
          ExploreCandidate.shell(roundId: round.id),
      ];
      run = run.copyWith(
        rounds: [
          ...run.rounds,
          round.copyWith(candidateIds: [for (final shell in shells) shell.id]),
        ],
        candidates: [...run.candidates, ...shells],
      );
      pending = shells;
    } else {
      // 续跑：含 pending 候选的轮次标回 generating。
      final pendingRoundIds = pending.map((c) => c.roundId).toSet();
      run = run.copyWith(
        rounds: [
          for (final round in run.rounds)
            pendingRoundIds.contains(round.id) &&
                    round.status == ExploreRoundStatus.pending
                ? round.copyWith(status: ExploreRoundStatus.generating)
                : round,
        ],
      );
    }

    final listNotifier = ref.read(exploreRunListNotifierProvider.notifier);
    run = await listNotifier.overwrite(
      run.copyWith(status: ExploreRunStatus.generating),
    );

    _pauseRequested = false;
    _cancelRequested = false;
    state = ExploreRunRunnerState(
      runId: runId,
      isRunning: true,
      totalCount: pending.length,
    );

    await _runLoop(runId, [for (final candidate in pending) candidate.id]);
    return true;
  }

  /// 暂停：当前张完成后退出循环，run → paused，剩余 pending 保留可续跑。
  void pause() {
    if (!state.isRunning) return;
    _pauseRequested = true;
  }

  /// 取消：中断在途生成，剩余 pending 标 failed(cancelled)，
  /// run → cancelled（终态不可再 start）。
  void cancel() {
    if (!state.isRunning) return;
    _cancelRequested = true;
    // 仅当生成确实在跑才调 cancel，避免无谓污染主生成状态。
    if (ref.read(imageGenerationNotifierProvider).isGenerating) {
      ref.read(imageGenerationNotifierProvider.notifier).cancel();
    }
  }

  /// 失败重试：failed 重置 pending 后再 start。
  Future<bool> retryFailed(String runId) async {
    if (state.isRunning) return false;
    final repository = ref.read(styleExploreRunRepositoryProvider);
    final run = await repository.getRun(runId);
    if (run == null || run.failedCount == 0) return false;
    const startable = {
      ExploreRunStatus.draft,
      ExploreRunStatus.paused,
      ExploreRunStatus.generated,
    };
    if (!startable.contains(run.status)) return false;

    await ref
        .read(exploreRunListNotifierProvider.notifier)
        .overwrite(
          run.copyWith(
            candidates: [
              for (final candidate in run.candidates)
                candidate.generation.status ==
                        ExploreCandidateGenerationStatus.failed
                    ? candidate.copyWith(
                        generation: const ExploreCandidateGeneration(
                          status: ExploreCandidateGenerationStatus.pending,
                        ),
                      )
                    : candidate,
            ],
          ),
        );
    return start(runId);
  }

  Future<void> _runLoop(String runId, List<String> pendingIds) async {
    final repository = ref.read(styleExploreRunRepositoryProvider);
    final listNotifier = ref.read(exploreRunListNotifierProvider.notifier);
    final loaded = await repository.getRun(runId);
    if (loaded == null) {
      state = const ExploreRunRunnerState();
      return;
    }

    try {
      for (final candidateId in pendingIds) {
        if (_cancelRequested || _pauseRequested) break;

        await _waitCooldownAvailable();
        if (_cancelRequested || _pauseRequested) break;

        state = state.copyWith(currentCandidateId: candidateId);

        // roll 主双 lane（runner 自控节奏，不经 PillRollCoordinator——
        // 协调器会顺带推 generationParams，runner 只需要 lane 投影现值）。
        ref
            .read(pillWorkspaceProvider(PillScopes.main).notifier)
            .rollAllRandom();
        ref
            .read(pillWorkspaceProvider(PillScopes.negative).notifier)
            .rollAllRandom();
        final rollSnapshot = captureExploreRollSnapshot(ref);

        // 红线：roll 后立刻读 generationParams 的 prompt 是旧值
        // （updatePrompt 走 microtask）——用 roll 后投影直接重建；
        // 其余字段取当前主参数现值（characters 用现值，角色 roll 变化
        // 下一张生效，接受）；单张、逐张随机种子。
        final tempParams = ref
            .read(generationParamsNotifierProvider)
            .copyWith(
              prompt: rollSnapshot.positive,
              negativePrompt: rollSnapshot.negative,
              nSamples: 1,
              seed: -1,
            );

        // 生成前抓填 roll 快照（生成中状态由 runner state 表达）。
        await listNotifier.updateCandidate(
          runId,
          candidateId,
          (candidate) => candidate.copyWith(rollSnapshot: rollSnapshot),
        );

        final generate = ref.read(exploreGenerateFnProvider);
        final result = await generate(tempParams);

        if (result != null) {
          final storedPath = await ref
              .read(exploreRunImageStoreProvider)
              .storeCandidateImage(
                runId: runId,
                candidateId: candidateId,
                bytes: result.imageBytes,
                sourceFilePath: result.filePath,
              );
          await listNotifier.updateGeneration(
            runId,
            candidateId,
            ExploreCandidateGeneration(
              status: ExploreCandidateGenerationStatus.done,
              filePath: storedPath ?? result.filePath,
              seed: result.seed,
              elapsedMs: result.elapsedMs,
            ),
          );
        } else {
          final errorText = _cancelRequested
              ? 'cancelled'
              : (ref.read(imageGenerationNotifierProvider).errorMessage ??
                    'generation failed');
          await listNotifier.updateGeneration(
            runId,
            candidateId,
            ExploreCandidateGeneration(
              status: ExploreCandidateGenerationStatus.failed,
              error: errorText,
            ),
          );
        }
        state = state.copyWith(processedCount: state.processedCount + 1);
        if (_cancelRequested) break;
      }
    } catch (error, stackTrace) {
      // 中途异常（如 run 被删）：复位 runner，run 保持 generating，
      // 由下次启动的恢复流程归位 paused。
      AppLogger.e(
        'Explore run loop aborted',
        error,
        stackTrace,
        'ExploreRunRunner',
      );
      state = const ExploreRunRunnerState();
      return;
    }

    await _finalize(runId, pendingIds);
  }

  Future<void> _finalize(String runId, List<String> processedIds) async {
    final repository = ref.read(styleExploreRunRepositoryProvider);
    final listNotifier = ref.read(exploreRunListNotifierProvider.notifier);
    final loaded = await repository.getRun(runId);
    if (loaded == null) {
      state = const ExploreRunRunnerState();
      return;
    }
    ExploreRun run = loaded;

    if (_cancelRequested) {
      // 剩余 pending 全部标 failed(cancelled)。
      for (final candidate in run.pendingCandidates) {
        run = await listNotifier.updateGeneration(
          runId,
          candidate.id,
          const ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.failed,
            error: 'cancelled',
          ),
        );
      }
      run = run.copyWith(
        status: ExploreRunStatus.cancelled,
        rounds: [
          for (final round in run.rounds)
            round.status == ExploreRoundStatus.generating
                ? round.copyWith(status: ExploreRoundStatus.cancelled)
                : round,
        ],
      );
      await listNotifier.overwrite(run);
    } else if (_pauseRequested) {
      // 轮次保持 generating，续跑接着处理剩余 pending。
      await listNotifier.overwrite(
        run.copyWith(status: ExploreRunStatus.paused),
      );
    } else {
      // 处理完的轮次内无 pending → generated。
      final processed = processedIds.toSet();
      run = run.copyWith(
        status: ExploreRunStatus.generated,
        rounds: [
          for (final round in run.rounds)
            round.status == ExploreRoundStatus.generating &&
                    round.candidateIds.any(processed.contains) &&
                    !run.candidates.any(
                      (c) =>
                          c.roundId == round.id &&
                          c.generation.status ==
                              ExploreCandidateGenerationStatus.pending,
                    )
                ? round.copyWith(status: ExploreRoundStatus.generated)
                : round,
        ],
      );
      await listNotifier.overwrite(run);
    }
    state = const ExploreRunRunnerState();
  }

  /// 与 GenerationCooldownNotifier.waitUntilAvailable 同节拍，
  /// 但每拍检查暂停/取消标志保证响应。
  Future<void> _waitCooldownAvailable() async {
    while (ref.read(generationCooldownProvider).isActive) {
      if (_pauseRequested || _cancelRequested) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
}

final exploreRunRunnerProvider =
    NotifierProvider<ExploreRunRunner, ExploreRunRunnerState>(
      ExploreRunRunner.new,
    );
