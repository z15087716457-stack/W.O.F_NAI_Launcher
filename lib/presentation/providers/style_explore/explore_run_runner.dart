import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/explore_mutation_engine.dart';
import '../../../data/models/image/image_params.dart';
import '../../../data/models/prompt_block/pill_document.dart';
import '../../../data/models/style_explore/explore_run.dart';
import '../image_generation_provider.dart';
import '../pill_roll_coordinator.dart';
import '../pill_workspace_provider.dart';
import 'deep_round_roll_guard.dart';
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

/// 深度轮门禁失败原因（UI 据此映射文案）。
enum ExploreDeepRoundRejection {
  /// main lane 没有可用的启用随机遗传实例（子代串没有落点）。
  noRandomInstance,

  /// 变异引擎在去重空间内无法产出任何子代串。
  mutationEmpty,

  /// 父本集/家族数据不完整。
  invalidParentSet,
}

/// 深度轮启动前的校验失败（UI 捕获后按 [reason] 提示）。
class ExploreDeepRoundException implements Exception {
  const ExploreDeepRoundException(this.reason);

  final ExploreDeepRoundRejection reason;

  @override
  String toString() => 'ExploreDeepRoundException($reason)';
}

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
  final int processedCount;
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

class _ExploreRunSession {
  _ExploreRunSession({required this.ownerId, required this.runId});

  final String ownerId;
  final String runId;
  String? roundId;
  bool persistedGenerating = false;
}

class _PreparedExploreRun {
  const _PreparedExploreRun({required this.run, required this.pendingIds});

  final ExploreRun run;
  final List<String> pendingIds;
}

/// 探索 Run 批量候选生成协调器。
///
/// Runner 在 claim 时同步取得 session，并同步抑制外部 roll；准备、循环、
/// finalize 与清理都由同一 session 包住。深度轮使用运行态 guard 投影子代串，
/// 不把子代写回工作区的真实 currentRoll。
class ExploreRunRunner extends Notifier<ExploreRunRunnerState> {
  bool _pauseRequested = false;
  bool _cancelRequested = false;
  _ExploreRunSession? _session;
  bool _suppressionHeld = false;
  bool _recoveryClaimed = false;
  bool _recoveryPending = false;

  /// 深度轮变异引擎的随机源（生产不可复现；测试换 seeded Random 锁确定性）。
  @visibleForTesting
  static Random deepRng = Random();

  @override
  ExploreRunRunnerState build() {
    _recoveryPending = true;
    Future<void>.microtask(() async {
      try {
        await _recoverInterruptedRuns();
      } finally {
        _recoveryPending = false;
      }
    });
    return const ExploreRunRunnerState();
  }

  Future<void> _recoverInterruptedRuns() async {
    // 恢复与立即 start 互斥：恢复在第一次 await 前占用 claim，start 只能等
    // 本次恢复结束后再尝试，不会在检查和 overwrite 之间插入。
    if (_session != null || state.isRunning || _recoveryClaimed) return;
    _recoveryClaimed = true;
    try {
      final repository = ref.read(styleExploreRunRepositoryProvider);
      final runs = await repository.load();
      if (_session != null || state.isRunning) return;
      var recovered = false;
      for (final run in runs) {
        if (_session != null || state.isRunning) return;
        if (run.status != ExploreRunStatus.generating) continue;
        final normalizedRounds = [
          for (final round in run.rounds)
            round.status == ExploreRoundStatus.generating
                ? round.copyWith(
                    status: _roundHasPending(run, round)
                        ? ExploreRoundStatus.pending
                        : ExploreRoundStatus.generated,
                  )
                : round,
        ];
        await repository.overwrite(
          run.copyWith(
            status: ExploreRunStatus.paused,
            rounds: normalizedRounds,
          ),
        );
        recovered = true;
        if (_session != null || state.isRunning) return;
      }
      if (recovered && _session == null && !state.isRunning) {
        await ref.read(exploreRunListNotifierProvider.notifier).refresh();
      }
    } catch (error) {
      AppLogger.w(
        'Recover interrupted explore runs failed: $error',
        'ExploreRunRunner',
      );
    } finally {
      _recoveryClaimed = false;
    }
  }

  /// 启动/续跑。返回 false = 被门禁拒绝（重入/主生成在跑/状态不可启动）。
  Future<bool> start(String runId) async {
    final session = _claim(runId);
    if (session == null) return false;
    return _executeSession(session, () => _prepareBasic(session));
  }

  /// 启动深度轮（阶段 D）。子代串和目标块 id 只登记在 lineage；生成时
  /// 由运行态 guard 投影目标串，普通工作区文档不被改写。
  Future<bool> startDeepRound(
    String runId, {
    required String familyId,
    required String parentSetId,
    required int count,
  }) async {
    final session = _claim(runId);
    if (session == null) return false;
    return _executeSession(
      session,
      () => _prepareDeep(
        session,
        familyId: familyId,
        parentSetId: parentSetId,
        count: count,
      ),
    );
  }

  /// 暂停：当前张完成后退出循环，run → paused，剩余 pending 保留可续跑。
  void pause() {
    if (!state.isRunning) return;
    _pauseRequested = true;
  }

  /// 取消：中断在途生成，剩余 pending 标 failed(cancelled)，run → cancelled。
  void cancel() {
    if (!state.isRunning) return;
    _cancelRequested = true;
    if (ref.read(imageGenerationNotifierProvider).isGenerating) {
      ref.read(imageGenerationNotifierProvider.notifier).cancel();
    }
  }

  /// 失败重试：在同一 session 内把 failed 转 pending，再走公共准备和循环路径。
  Future<bool> retryFailed(String runId) async {
    final session = _claim(runId);
    if (session == null) return false;
    return _executeSession(
      session,
      () => _prepareBasic(session, resetFailed: true),
    );
  }

  _ExploreRunSession? _claim(String runId) {
    if (_session != null ||
        state.isRunning ||
        _recoveryClaimed ||
        _recoveryPending) {
      return null;
    }
    if (ref.read(imageGenerationNotifierProvider).isGenerating) return null;
    final session = _ExploreRunSession(
      ownerId: const Uuid().v4(),
      runId: runId,
    );
    _session = session;
    _pauseRequested = false;
    _cancelRequested = false;
    _suppressionHeld = true;
    PillRollCoordinator.suppressRoll();
    state = ExploreRunRunnerState(runId: runId, isRunning: true);
    return session;
  }

  Future<bool> _executeSession(
    _ExploreRunSession session,
    Future<_PreparedExploreRun?> Function() prepare,
  ) async {
    var persistedGenerating = false;
    try {
      final prepared = await prepare();
      if (prepared == null) return false;
      persistedGenerating = true;
      state = state.copyWith(totalCount: prepared.pendingIds.length);
      await _runLoop(session, prepared);
      return true;
    } catch (error, stackTrace) {
      AppLogger.e(
        'Explore run session aborted',
        error,
        stackTrace,
        'ExploreRunRunner',
      );
      final runWasPersisted =
          persistedGenerating || session.persistedGenerating;
      if (error is ExploreDeepRoundException && !runWasPersisted) {
        rethrow;
      }
      if (runWasPersisted) {
        await _normalizeAfterException(session.runId, error, stackTrace);
      }
      return true;
    } finally {
      await _cleanupSession(session);
    }
  }

  Future<_PreparedExploreRun?> _prepareBasic(
    _ExploreRunSession session, {
    bool resetFailed = false,
  }) async {
    final repository = ref.read(styleExploreRunRepositoryProvider);
    var run = await repository.getRun(session.runId);
    if (run == null) return null;

    const startable = {
      ExploreRunStatus.draft,
      ExploreRunStatus.paused,
      ExploreRunStatus.generated,
    };
    if (!startable.contains(run.status)) return null;
    if (resetFailed) {
      if (run.failedCount == 0) return null;
      run = run.copyWith(
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
      );
    }

    var pending = run.pendingCandidates;
    if (pending.isEmpty) {
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
      final pendingRoundIds = pending.map((c) => c.roundId).toSet();
      run = run.copyWith(
        rounds: [
          for (final round in run.rounds)
            pendingRoundIds.contains(round.id)
                ? round.copyWith(status: ExploreRoundStatus.generating)
                : round,
        ],
      );
    }

    final saved = await ref
        .read(exploreRunListNotifierProvider.notifier)
        .overwrite(run.copyWith(status: ExploreRunStatus.generating));
    session.persistedGenerating = true;
    if (pending.isNotEmpty) {
      final firstPendingRound = saved.roundById(pending.first.roundId);
      if (firstPendingRound?.phase == ExploreRoundPhase.deep) {
        await _ensureDeepGuard(session, firstPendingRound!.id);
      } else {
        _clearGuardForSession(session);
      }
    } else {
      _clearGuardForSession(session);
    }
    return _PreparedExploreRun(
      run: saved,
      pendingIds: [for (final candidate in pending) candidate.id],
    );
  }

  Future<_PreparedExploreRun?> _prepareDeep(
    _ExploreRunSession session, {
    required String familyId,
    required String parentSetId,
    required int count,
  }) async {
    final repository = ref.read(styleExploreRunRepositoryProvider);
    final loaded = await repository.getRun(session.runId);
    if (loaded == null) return null;
    const startable = {
      ExploreRunStatus.draft,
      ExploreRunStatus.paused,
      ExploreRunStatus.generated,
      ExploreRunStatus.reviewing,
      ExploreRunStatus.completed,
    };
    if (!startable.contains(loaded.status) ||
        loaded.pendingCandidates.isNotEmpty) {
      return null;
    }

    final family = loaded.familyById(familyId);
    final parentSet = loaded.parentSetById(parentSetId);
    if (family == null ||
        parentSet == null ||
        parentSet.familyId != family.id ||
        parentSet.parents.isEmpty) {
      throw const ExploreDeepRoundException(
        ExploreDeepRoundRejection.invalidParentSet,
      );
    }

    final targetBlockId = exploreTargetBlockIdForParentSet(loaded, parentSet);
    final initialMainDocument = _documentForGuard(PillScopes.main);
    final targetMarker = resolveExploreOverrideMarkerInDocument(
      initialMainDocument,
      blockId: targetBlockId,
    );
    if (targetMarker == null) {
      throw const ExploreDeepRoundException(
        ExploreDeepRoundRejection.noRandomInstance,
      );
    }

    final children = ExploreMutationEngine.generateDeepCandidates(
      parents: [
        for (final parent in parentSet.parents)
          ExploreMutationParent(
            id: parent.id,
            text: parent.artistString,
            preference: parent.preference,
            sourceCandidateId: parent.sourceCandidateId,
          ),
      ],
      count: count,
      injectionPool: buildExploreInjectionPool(ref, loaded),
      rng: deepRng,
    );
    if (children.isEmpty) {
      throw const ExploreDeepRoundException(
        ExploreDeepRoundRejection.mutationEmpty,
      );
    }

    final childGeneration = parentSet.generation + 1;
    final round = ExploreRound(
      id: const Uuid().v4(),
      number: loaded.rounds.length + 1,
      phase: ExploreRoundPhase.deep,
      status: ExploreRoundStatus.generating,
      createdAt: DateTime.now(),
      targetCount: children.length,
      familyId: family.id,
      parentSetId: parentSet.id,
      generation: childGeneration,
    );
    final candidates = [
      for (final child in children)
        ExploreCandidate(
          id: const Uuid().v4(),
          roundId: round.id,
          lineage: ExploreLineage(
            parentCandidateIds: [
              ...{
                for (final parent in child.parents)
                  if (parent.sourceCandidateId case final sourceId?) sourceId,
              },
            ],
            operation: child.operation,
            generation: childGeneration,
            mutatedText: child.text,
            targetBlockId: targetBlockId,
          ),
        ),
    ];

    final saved = await ref
        .read(exploreRunListNotifierProvider.notifier)
        .overwrite(
          loaded.copyWith(
            status: ExploreRunStatus.generating,
            rounds: [
              ...loaded.rounds,
              round.copyWith(candidateIds: [for (final c in candidates) c.id]),
            ],
            candidates: [...loaded.candidates, ...candidates],
          ),
        );
    session.persistedGenerating = true;

    // Capture raw/current documents before either lane is first built under the
    // guard; otherwise a missing currentRoll could be materialized too early.
    final guard = DeepRoundRollGuard.capture(
      ownerId: session.ownerId,
      runId: session.runId,
      roundId: round.id,
      documents: {
        PillScopes.main: _documentForGuard(PillScopes.main),
        PillScopes.negative: _documentForGuard(PillScopes.negative),
      },
    );
    final installed = ref
        .read(deepRoundRollGuardControllerProvider)
        .install(guard);
    if (!installed) {
      throw StateError('Unable to install deep-round roll guard');
    }
    session.roundId = round.id;
    return _PreparedExploreRun(
      run: saved,
      pendingIds: [for (final candidate in candidates) candidate.id],
    );
  }

  Future<void> _runLoop(
    _ExploreRunSession session,
    _PreparedExploreRun prepared,
  ) async {
    final listNotifier = ref.read(exploreRunListNotifierProvider.notifier);
    final lineageByCandidateId = {
      for (final candidate in prepared.run.candidates)
        candidate.id: candidate.lineage,
    };

    for (final candidateId in prepared.pendingIds) {
      if (_cancelRequested || _pauseRequested) break;

      await _waitCooldownAvailable();
      if (_cancelRequested || _pauseRequested) break;

      final candidate = prepared.run.candidateById(candidateId);
      final round = candidate == null
          ? null
          : prepared.run.roundById(candidate.roundId);
      if (candidate == null || round == null) {
        throw StateError('Candidate $candidateId is not in prepared run');
      }
      state = state.copyWith(currentCandidateId: candidateId);

      String? targetMarker;
      final lineage = lineageByCandidateId[candidateId];
      if (round.phase == ExploreRoundPhase.deep) {
        final mutatedText = lineage?.mutatedText;
        if (mutatedText == null) {
          await _markFailed(
            session.runId,
            candidateId,
            'deep lineage missing mutatedText',
          );
          _incrementProcessed();
          continue;
        }
        targetMarker = resolveExploreOverrideMarker(
          ref,
          blockId: lineage?.targetBlockId,
        );
        if (targetMarker == null) {
          await _markFailed(
            session.runId,
            candidateId,
            'no random instance for deep target',
          );
          _incrementProcessed();
          continue;
        }
        await _ensureDeepGuard(session, round.id);
        final controller = ref.read(deepRoundRollGuardControllerProvider);
        final updated = controller.updateCandidate(
          ownerId: session.ownerId,
          runId: session.runId,
          roundId: round.id,
          targetScope: PillScopes.main,
          targetMarker: targetMarker,
          mutatedText: mutatedText,
        );
        final targetInstance = ref
            .read(pillWorkspaceProvider(PillScopes.main))
            .document
            .instances[targetMarker];
        if (!updated ||
            targetInstance == null ||
            controller.guard?.kindFor(PillScopes.main, targetMarker) !=
                DeepRoundRollOverrideKind.explicitTarget ||
            !controller.hasOverride(
              PillScopes.main,
              targetMarker,
              instance: targetInstance,
            )) {
          await _markFailed(
            session.runId,
            candidateId,
            'no random instance for deep target',
          );
          _incrementProcessed();
          continue;
        }
      } else {
        _clearGuardForSession(session);
      }

      // The runner owns roll timing. Guard entries are skipped before _rollFor,
      // so automatic suppression and explicit target override consume no RNG.
      ref.read(pillWorkspaceProvider(PillScopes.main).notifier).rollAllRandom();
      ref
          .read(pillWorkspaceProvider(PillScopes.negative).notifier)
          .rollAllRandom();

      final rollSnapshot = captureExploreRollSnapshot(ref);
      final tempParams = ref
          .read(generationParamsNotifierProvider)
          .copyWith(
            prompt: rollSnapshot.positive,
            negativePrompt: rollSnapshot.negative,
            nSamples: 1,
            seed: -1,
          );

      await listNotifier.updateCandidate(
        session.runId,
        candidateId,
        (current) => current.copyWith(rollSnapshot: rollSnapshot),
      );

      final result = await ref.read(exploreGenerateFnProvider)(tempParams);
      if (result != null) {
        final storedPath = await ref
            .read(exploreRunImageStoreProvider)
            .storeCandidateImage(
              runId: session.runId,
              candidateId: candidateId,
              bytes: result.imageBytes,
              sourceFilePath: result.filePath,
            );
        await listNotifier.updateGeneration(
          session.runId,
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
          session.runId,
          candidateId,
          ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.failed,
            error: errorText,
          ),
        );
      }
      _incrementProcessed();
      if (_cancelRequested) break;
    }

    await _finalize(session);
  }

  Future<void> _ensureDeepGuard(
    _ExploreRunSession session,
    String roundId,
  ) async {
    final controller = ref.read(deepRoundRollGuardControllerProvider);
    if (controller.guard?.owns(
          ownerId: session.ownerId,
          runId: session.runId,
          roundId: roundId,
        ) ==
        true) {
      session.roundId = roundId;
      return;
    }
    _clearGuardForSession(session);
    if (!controller.install(
      DeepRoundRollGuard.capture(
        ownerId: session.ownerId,
        runId: session.runId,
        roundId: roundId,
        documents: {
          PillScopes.main: _documentForGuard(PillScopes.main),
          PillScopes.negative: _documentForGuard(PillScopes.negative),
        },
      ),
    )) {
      throw StateError('Unable to rebuild deep-round roll guard');
    }
    session.roundId = roundId;
  }

  PillDocument _documentForGuard(String scope) {
    final provider = pillWorkspaceProvider(scope);
    if (ref.exists(provider)) return ref.read(provider).document;
    return ref.read(pillWorkspaceStorageProvider).tryLoadSync(scope) ??
        PillDocument.empty();
  }

  Future<void> _markFailed(
    String runId,
    String candidateId,
    String error,
  ) async {
    await ref
        .read(exploreRunListNotifierProvider.notifier)
        .updateGeneration(
          runId,
          candidateId,
          ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.failed,
            error: error,
          ),
        );
  }

  void _incrementProcessed() {
    state = state.copyWith(processedCount: state.processedCount + 1);
  }

  Future<void> _finalize(_ExploreRunSession session) async {
    final listNotifier = ref.read(exploreRunListNotifierProvider.notifier);
    final run = await ref
        .read(styleExploreRunRepositoryProvider)
        .getRun(session.runId);
    if (run == null) throw StateError('Run disappeared during finalize');
    var currentRun = run;

    if (_cancelRequested) {
      for (final candidate in currentRun.pendingCandidates) {
        currentRun = await listNotifier.updateGeneration(
          session.runId,
          candidate.id,
          const ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.failed,
            error: 'cancelled',
          ),
        );
      }
      currentRun = currentRun.copyWith(
        status: ExploreRunStatus.cancelled,
        rounds: [
          for (final round in currentRun.rounds)
            round.status == ExploreRoundStatus.generating ||
                    round.status == ExploreRoundStatus.pending
                ? round.copyWith(status: ExploreRoundStatus.cancelled)
                : round,
        ],
      );
      await listNotifier.overwrite(currentRun);
      return;
    }

    final paused = _pauseRequested;
    final rounds = [
      for (final round in currentRun.rounds)
        round.status == ExploreRoundStatus.generating
            ? round.copyWith(
                status: _roundHasPending(currentRun, round)
                    ? ExploreRoundStatus.pending
                    : ExploreRoundStatus.generated,
              )
            : round,
    ];
    final normalized = currentRun.copyWith(
      status: paused && currentRun.pendingCandidates.isNotEmpty
          ? ExploreRunStatus.paused
          : ExploreRunStatus.generated,
      rounds: rounds,
    );
    await listNotifier.overwrite(normalized);
  }

  Future<void> _normalizeAfterException(
    String runId,
    Object error,
    StackTrace stackTrace,
  ) async {
    try {
      final repository = ref.read(styleExploreRunRepositoryProvider);
      final listNotifier = ref.read(exploreRunListNotifierProvider.notifier);
      final run = await repository.getRun(runId);
      if (run == null) return;
      final rounds = [
        for (final round in run.rounds)
          round.status == ExploreRoundStatus.generating
              ? round.copyWith(
                  status: _roundHasPending(run, round)
                      ? ExploreRoundStatus.pending
                      : ExploreRoundStatus.generated,
                )
              : round,
      ];
      await listNotifier.overwrite(
        run.copyWith(
          status: run.pendingCandidates.isNotEmpty
              ? ExploreRunStatus.paused
              : ExploreRunStatus.generated,
          rounds: rounds,
        ),
      );
    } catch (normalizationError, normalizationStack) {
      AppLogger.e(
        'Normalize failed explore run state failed: $normalizationError',
        normalizationError,
        normalizationStack,
        'ExploreRunRunner',
      );
      AppLogger.e(
        'Original explore run error: $error',
        error,
        stackTrace,
        'ExploreRunRunner',
      );
    }
  }

  Future<void> _cleanupSession(_ExploreRunSession session) async {
    if (!identical(_session, session)) return;
    _clearGuardForSession(session);
    if (_suppressionHeld) {
      PillRollCoordinator.releaseRollSuppression();
      _suppressionHeld = false;
    }
    _session = null;
    state = const ExploreRunRunnerState();
  }

  void _clearGuardForSession(_ExploreRunSession session) {
    final controller = ref.read(deepRoundRollGuardControllerProvider);
    final guard = controller.guard;
    if (guard == null ||
        guard.ownerId != session.ownerId ||
        guard.runId != session.runId) {
      return;
    }
    controller.clear(
      ownerId: guard.ownerId,
      runId: guard.runId,
      roundId: guard.roundId,
    );
  }

  static bool _roundHasPending(ExploreRun run, ExploreRound round) {
    final ids = round.candidateIds.toSet();
    return run.candidates.any(
      (candidate) =>
          ids.contains(candidate.id) &&
          candidate.generation.status ==
              ExploreCandidateGenerationStatus.pending,
    );
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
