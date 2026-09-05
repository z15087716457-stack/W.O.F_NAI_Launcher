import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/style_explore/explore_run.dart';
import '../generation/generation_models.dart';
import '../generation/generation_params_notifier.dart';
import '../pill_workspace_provider.dart';
import 'explore_roll_capture.dart';
import 'explore_run_provider.dart';

/// 手动单张生成捕捉状态（探索页生成按钮触发的候选登记）。
class ExploreManualCaptureState {
  const ExploreManualCaptureState({
    this.armed = false,
    this.runId,
    this.generationRunId,
    this.sessionId = 0,
    this.candidateIds = const [],
    this.rollSnapshots = const [],
    this.armedAt,
  });

  /// 已布防：等待本次生成完成并登记。
  final bool armed;

  /// 登记目标 run（arm 期间异步解析：无活跃 run 时自动建 draft）。
  final String? runId;

  final int? generationRunId;
  final int sessionId;

  /// 本次生成前建好的 pending 候选壳（与产出图按槽位配对）。
  final List<String> candidateIds;

  /// 各生成槽位发送前抓取的 roll 快照，列表下标对应 0-based 槽位。
  final List<ExploreRollSnapshot?> rollSnapshots;

  /// 兼容旧调用方的首张快照访问器。
  ExploreRollSnapshot? get rollSnapshot =>
      rollSnapshots.isEmpty ? null : rollSnapshots.first;

  final DateTime? armedAt;

  ExploreManualCaptureState copyWith({
    bool? armed,
    String? runId,
    int? generationRunId,
    int? sessionId,
    List<String>? candidateIds,
    List<ExploreRollSnapshot?>? rollSnapshots,
    DateTime? armedAt,
  }) {
    return ExploreManualCaptureState(
      armed: armed ?? this.armed,
      runId: runId ?? this.runId,
      generationRunId: generationRunId ?? this.generationRunId,
      sessionId: sessionId ?? this.sessionId,
      candidateIds: candidateIds ?? this.candidateIds,
      rollSnapshots: rollSnapshots ?? this.rollSnapshots,
      armedAt: armedAt ?? this.armedAt,
    );
  }
}

/// 探索页手动生成的候选登记器。
///
/// 时机链：主生成链发出 batch start → [arm] 在第一张请求前抓快照并建
/// pending 候选壳 → 每个 batch start 按槽位抓新快照 → batch complete 按槽位
/// 写入结果。主生成页没有 batch 回调，其产出只进历史页、不进候选画廊。
class ExploreManualCaptureNotifier extends Notifier<ExploreManualCaptureState> {
  Future<void> _batchQueue = Future<void>.value();
  int _sessionCounter = 0;

  /// 首轮孤儿清扫的完成信号（arm 建壳前必须先等它，否则新鲜 pending
  /// 壳可能被清扫误标 interrupted）。
  late final Future<void> _orphanSweep = Future<void>.microtask(
    _sweepOrphanedManualCandidates,
  );

  @override
  ExploreManualCaptureState build() {
    // 应用被杀留下的 pending 手动壳是死状态，恢复为 failed(interrupted)。
    // 触发字段初始化即开始清扫。
    unawaited(_orphanSweep);
    return const ExploreManualCaptureState();
  }

  /// 在第一批请求发送前布防并建立全部候选壳。
  Future<void> arm({
    required String autoRunName,
    int expectedCount = 1,
    int? generationRunId,
    String? activeRunId,
  }) async {
    if (state.armed) return;
    final rollSnapshot = captureExploreRollSnapshot(ref);
    final sessionId = ++_sessionCounter;
    state = ExploreManualCaptureState(
      armed: true,
      generationRunId: generationRunId != null && generationRunId >= 0
          ? generationRunId
          : null,
      sessionId: sessionId,
      rollSnapshots: [rollSnapshot],
      armedAt: DateTime.now(),
    );
    try {
      await _orphanSweep;
      final runId = await _ensureActiveRun(autoRunName, activeRunId);
      if (!_isSessionActive(sessionId, generationRunId)) return;
      final shells = await ref
          .read(exploreRunListNotifierProvider.notifier)
          .addManualCandidates(
            runId,
            count: expectedCount < 1 ? 1 : expectedCount,
            rollSnapshots: [rollSnapshot],
          );
      if (!_isSessionActive(sessionId, generationRunId)) {
        await _failShells(runId, [
          for (final shell in shells) shell.id,
        ], 'cancelled');
        return;
      }
      state = state.copyWith(
        runId: runId,
        candidateIds: [for (final shell in shells) shell.id],
      );
    } catch (error, stackTrace) {
      AppLogger.e(
        'Arm explore manual capture failed',
        error,
        stackTrace,
        'ExploreManualCapture',
      );
      state = const ExploreManualCaptureState();
    }
  }

  bool _isSessionActive(int sessionId, int? generationRunId) {
    final current = state;
    return current.armed &&
        current.sessionId == sessionId &&
        (generationRunId == null || current.generationRunId == generationRunId);
  }

  /// 无活跃 run 时自动建 draft run（快照=当前 main lane 文档+主参数）。
  Future<String> _ensureActiveRun(
    String autoRunName,
    String? activeRunId,
  ) async {
    if (activeRunId != null) {
      final run = await ref
          .read(styleExploreRunRepositoryProvider)
          .getRun(activeRunId);
      if (run == null) {
        throw StateError('Style explore run does not exist: $activeRunId');
      }
      return activeRunId;
    }
    final params = ref.read(generationParamsNotifierProvider);
    final created = await ref
        .read(exploreRunListNotifierProvider.notifier)
        .create(
          name: autoRunName,
          recipeSnapshot: ExploreRecipeSnapshot(
            positive: ref.read(pillWorkspaceProvider(PillScopes.main)).document,
            negative: ref
                .read(pillWorkspaceProvider(PillScopes.negative))
                .document,
          ),
          paramsSnapshot: ExploreParamsSnapshot.fromImageParams(params),
          targetCount: 10,
        );
    ref.read(exploreActiveRunIdProvider.notifier).state = created.id;
    return created.id;
  }

  /// 接收真实主生成链的批次事件，并串行完成快照与结果落盘。
  Future<void> handleBatchEvent(
    GenerationBatchEvent event, {
    required String autoRunName,
    String? activeRunId,
  }) {
    final operation = _batchQueue.then<void>(
      (_) => _handleBatchEvent(
        event,
        autoRunName: autoRunName,
        activeRunId: activeRunId,
      ),
    );
    _batchQueue = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.e(
          'Handle explore batch event failed',
          error,
          stackTrace,
          'ExploreManualCapture',
        );
      },
    );
    return operation;
  }

  Future<void> _handleBatchEvent(
    GenerationBatchEvent event, {
    required String autoRunName,
    String? activeRunId,
  }) async {
    final currentGenerationRunId = state.generationRunId;
    if (event.generationRunId >= 0 &&
        currentGenerationRunId != null &&
        currentGenerationRunId != event.generationRunId) {
      return;
    }

    if (event.kind == GenerationBatchEventKind.start) {
      if (!state.armed) {
        await arm(
          autoRunName: autoRunName,
          expectedCount: event.totalSlots,
          generationRunId: event.generationRunId,
          activeRunId: activeRunId,
        );
      }
      if (!state.armed) return;
      if (event.generationRunId >= 0 && state.generationRunId == null) {
        state = state.copyWith(generationRunId: event.generationRunId);
      }
      if (event.generationRunId >= 0 &&
          state.generationRunId != event.generationRunId) {
        return;
      }

      final slotIndex = event.slotStart - 1;
      if (slotIndex == 0 &&
          state.rollSnapshots.isNotEmpty &&
          event.slotCount == 1) {
        return;
      }
      final snapshot = captureExploreRollSnapshot(ref);
      await _recordSnapshot(
        slotStart: event.slotStart,
        slotCount: event.slotCount,
        snapshot: snapshot,
      );
      return;
    }

    if (!state.armed) return;
    if (event.generationRunId >= 0 &&
        state.generationRunId != event.generationRunId) {
      return;
    }
    await _completeBatch(event);
  }

  void cancelSession({int? generationRunId, String error = 'cancelled'}) {
    final capture = state;
    if (!capture.armed ||
        (generationRunId != null &&
            capture.generationRunId != null &&
            capture.generationRunId != generationRunId)) {
      return;
    }
    state = const ExploreManualCaptureState();
    final runId = capture.runId;
    if (runId == null || capture.candidateIds.isEmpty) return;

    final operation = _batchQueue.then<void>(
      (_) => _failShells(runId, capture.candidateIds, error),
    );
    _batchQueue = operation.then<void>(
      (_) {},
      onError: (Object failure, StackTrace stackTrace) {
        AppLogger.e(
          'Cancel explore manual capture failed',
          failure,
          stackTrace,
          'ExploreManualCapture',
        );
      },
    );
  }

  Future<void> _recordSnapshot({
    required int slotStart,
    required int slotCount,
    required ExploreRollSnapshot snapshot,
  }) async {
    final capture = state;
    final runId = capture.runId;
    if (runId == null) return;

    final snapshots = [...capture.rollSnapshots];
    final firstIndex = slotStart - 1;
    for (var offset = 0; offset < slotCount; offset++) {
      final index = firstIndex + offset;
      while (snapshots.length <= index) {
        snapshots.add(null);
      }
      if (index != 0 || capture.rollSnapshots.isEmpty) {
        snapshots[index] = snapshot;
      }
    }
    state = capture.copyWith(rollSnapshots: snapshots);

    final listNotifier = ref.read(exploreRunListNotifierProvider.notifier);
    for (var offset = 0; offset < slotCount; offset++) {
      final index = firstIndex + offset;
      if (index < 0 || index >= capture.candidateIds.length) continue;
      if (index == 0 && capture.rollSnapshots.isNotEmpty) continue;
      final candidateId = capture.candidateIds[index];
      await listNotifier.updateCandidate(runId, candidateId, (candidate) {
        if (candidate.generation.status !=
            ExploreCandidateGenerationStatus.pending) {
          return candidate;
        }
        return candidate.copyWith(rollSnapshot: snapshot);
      });
    }
  }

  Future<void> _completeBatch(GenerationBatchEvent event) async {
    final capture = state;
    final runId = capture.runId;
    if (runId == null) return;

    final listNotifier = ref.read(exploreRunListNotifierProvider.notifier);
    final imageStore = ref.read(exploreRunImageStoreProvider);
    final firstIndex = event.slotStart - 1;
    for (var offset = 0; offset < event.slotCount; offset++) {
      final index = firstIndex + offset;
      if (index < 0 || index >= capture.candidateIds.length) continue;
      final candidateId = capture.candidateIds[index];
      final run = await ref
          .read(styleExploreRunRepositoryProvider)
          .getRun(runId);
      final candidate = run?.candidateById(candidateId);
      if (candidate == null ||
          candidate.generation.status !=
              ExploreCandidateGenerationStatus.pending) {
        continue;
      }

      final image = offset < event.images.length ? event.images[offset] : null;
      if (image == null || !image.canSave) {
        await listNotifier.updateCandidate(
          runId,
          candidateId,
          (current) =>
              current.generation.status ==
                  ExploreCandidateGenerationStatus.pending
              ? current.copyWith(
                  generation: ExploreCandidateGeneration(
                    status: ExploreCandidateGenerationStatus.failed,
                    error: event.error?.toString() ?? 'no image produced',
                    elapsedMs: event.elapsedMs,
                  ),
                )
              : current,
        );
        continue;
      }

      try {
        final storedPath = await imageStore.storeCandidateImage(
          runId: runId,
          candidateId: candidateId,
          bytes: image.bytes,
          sourceFilePath: image.filePath,
        );
        await listNotifier.updateCandidate(
          runId,
          candidateId,
          (current) =>
              current.generation.status ==
                  ExploreCandidateGenerationStatus.pending
              ? current.copyWith(
                  generation: ExploreCandidateGeneration(
                    status: ExploreCandidateGenerationStatus.done,
                    filePath: storedPath ?? image.filePath,
                    seed: image.metadata?.seed,
                    elapsedMs: event.elapsedMs,
                  ),
                )
              : current,
        );
      } catch (error) {
        await listNotifier.updateCandidate(
          runId,
          candidateId,
          (current) =>
              current.generation.status ==
                  ExploreCandidateGenerationStatus.pending
              ? current.copyWith(
                  generation: ExploreCandidateGeneration(
                    status: ExploreCandidateGenerationStatus.failed,
                    error: error.toString(),
                    elapsedMs: event.elapsedMs,
                  ),
                )
              : current,
        );
      }
    }

    final updated = await ref
        .read(styleExploreRunRepositoryProvider)
        .getRun(runId);
    if (updated == null ||
        !capture.candidateIds.any(
          (id) =>
              updated.candidateById(id)?.generation.status ==
              ExploreCandidateGenerationStatus.pending,
        )) {
      state = const ExploreManualCaptureState();
    }
  }

  Future<void> _failShells(
    String runId,
    List<String> candidateIds,
    String error,
  ) async {
    try {
      final listNotifier = ref.read(exploreRunListNotifierProvider.notifier);
      for (final candidateId in candidateIds) {
        await listNotifier.updateCandidate(
          runId,
          candidateId,
          (current) =>
              current.generation.status ==
                  ExploreCandidateGenerationStatus.pending
              ? current.copyWith(
                  generation: ExploreCandidateGeneration(
                    status: ExploreCandidateGenerationStatus.failed,
                    error: error,
                  ),
                )
              : current,
        );
      }
    } catch (error, stackTrace) {
      AppLogger.e(
        'Fail explore manual capture shells failed',
        error,
        stackTrace,
        'ExploreManualCapture',
      );
    }
  }

  /// 应用被杀遗留的 pending 手动壳 → failed(interrupted)。
  Future<void> _sweepOrphanedManualCandidates() async {
    try {
      final repository = ref.read(styleExploreRunRepositoryProvider);
      final runs = await repository.load();
      var swept = false;
      for (final run in runs) {
        final orphans = [
          for (final candidate in run.candidates)
            if (candidate.lineage.operation == ExploreLineageOperation.manual &&
                candidate.generation.status ==
                    ExploreCandidateGenerationStatus.pending)
              candidate,
        ];
        if (orphans.isEmpty) continue;
        swept = true;
        await repository.overwrite(
          run.copyWith(
            candidates: [
              for (final candidate in run.candidates)
                orphans.contains(candidate)
                    ? candidate.copyWith(
                        generation: const ExploreCandidateGeneration(
                          status: ExploreCandidateGenerationStatus.failed,
                          error: 'interrupted',
                        ),
                      )
                    : candidate,
            ],
          ),
        );
      }
      if (swept) {
        await ref.read(exploreRunListNotifierProvider.notifier).refresh();
      }
    } catch (error) {
      AppLogger.w(
        'Sweep orphaned manual candidates failed: $error',
        'ExploreManualCapture',
      );
    }
  }
}

final exploreManualCaptureProvider =
    NotifierProvider<ExploreManualCaptureNotifier, ExploreManualCaptureState>(
      ExploreManualCaptureNotifier.new,
    );
