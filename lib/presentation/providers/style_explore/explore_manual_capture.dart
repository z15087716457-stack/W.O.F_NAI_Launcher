import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/style_explore/explore_run.dart';
import '../image_generation_provider.dart';
import '../pill_workspace_provider.dart';
import 'explore_roll_capture.dart';
import 'explore_run_provider.dart';

/// 手动单张生成捕捉状态（探索页生成按钮触发的候选登记）。
class ExploreManualCaptureState {
  const ExploreManualCaptureState({
    this.armed = false,
    this.runId,
    this.candidateIds = const [],
    this.rollSnapshot,
    this.imageIdsBefore = const {},
    this.armedAt,
  });

  /// 已布防：等待本次生成完成并登记。
  final bool armed;

  /// 登记目标 run（arm 期间异步解析：无活跃 run 时自动建 draft）。
  final String? runId;

  /// 本次生成前建好的 pending 候选壳（与产出图按序配对）。
  final List<String> candidateIds;

  /// 点击瞬间抓的 roll 快照（生成前 main/negative lane 投影+实例明细）。
  final ExploreRollSnapshot? rollSnapshot;

  /// 点击瞬间的图库 id 基线（完成后按 id 差集找新图）。
  final Set<String> imageIdsBefore;
  final DateTime? armedAt;

  ExploreManualCaptureState copyWith({
    bool? armed,
    String? runId,
    List<String>? candidateIds,
    ExploreRollSnapshot? rollSnapshot,
    Set<String>? imageIdsBefore,
    DateTime? armedAt,
  }) {
    return ExploreManualCaptureState(
      armed: armed ?? this.armed,
      runId: runId ?? this.runId,
      candidateIds: candidateIds ?? this.candidateIds,
      rollSnapshot: rollSnapshot ?? this.rollSnapshot,
      imageIdsBefore: imageIdsBefore ?? this.imageIdsBefore,
      armedAt: armedAt ?? this.armedAt,
    );
  }
}

/// 探索页手动生成的候选登记器。
///
/// 时机链：生成按钮确认通过 → `generate()` 同步置 generating（roll 尚未
/// 发生）→ 页面钩子调 [arm] 抓 roll 快照/图 id 基线并建 pending 候选壳 →
/// 本 notifier 常驻监听生成状态：completed 时把新图复制进 run 目录并登记
/// （lineage.operation=manual），error/cancelled 时把壳标记失败。
///
/// 主生成页入口不经过 [arm]，其产出只进历史页、不进候选画廊。
class ExploreManualCaptureNotifier extends Notifier<ExploreManualCaptureState> {
  /// 首轮孤儿清扫的完成信号（arm 建壳前必须先等它，否则新鲜 pending
  /// 壳可能被清扫误标 interrupted）。
  late final Future<void> _orphanSweep = Future<void>.microtask(
    _sweepOrphanedManualCandidates,
  );

  @override
  ExploreManualCaptureState build() {
    ref.listen(imageGenerationNotifierProvider, _onGenerationChanged);
    // 应用被杀留下的 pending 手动壳是死状态，恢复为 failed(interrupted)。
    // 触发字段初始化即开始清扫。
    unawaited(_orphanSweep);
    return const ExploreManualCaptureState();
  }

  /// 布防（探索页生成按钮钩子，generate() 已同步启动后调用）。
  ///
  /// [expectedCount] = 本次预计产出张数（nSamples × 每请求张数）。
  /// roll 快照/基线同步抓取（必须在第一张 roll 之前）；run 解析与建壳
  /// 异步完成（生成耗时秒级，远慢于存储毫秒级，无竞态）。
  Future<void> arm({required String autoRunName, int expectedCount = 1}) async {
    if (state.armed) return;
    final generationState = ref.read(imageGenerationNotifierProvider);
    final rollSnapshot = captureExploreRollSnapshot(ref);
    final idsBefore = <String>{
      for (final image in generationState.currentImages) image.id,
      for (final image in generationState.history) image.id,
    };
    state = ExploreManualCaptureState(
      armed: true,
      rollSnapshot: rollSnapshot,
      imageIdsBefore: idsBefore,
      armedAt: DateTime.now(),
    );
    try {
      await _orphanSweep;
      final runId = await _ensureActiveRun(autoRunName);
      if (!state.armed) return;
      final shells = await ref
          .read(exploreRunListNotifierProvider.notifier)
          .addManualCandidates(
            runId,
            count: expectedCount < 1 ? 1 : expectedCount,
            firstRollSnapshot: rollSnapshot,
          );
      if (!state.armed) return;
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

  /// 无活跃 run 时自动建 draft run（快照=当前 main lane 文档+主参数）。
  Future<String> _ensureActiveRun(String autoRunName) async {
    final active = ref.read(exploreActiveRunProvider);
    if (active != null) return active.id;
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

  void _onGenerationChanged(
    ImageGenerationState? previous,
    ImageGenerationState next,
  ) {
    final capture = state;
    if (!capture.armed) return;
    switch (next.status) {
      case GenerationStatus.completed:
        unawaited(_finalizeCapture(capture, next));
      case GenerationStatus.error:
      case GenerationStatus.cancelled:
        unawaited(
          _failCapture(
            capture,
            next.status == GenerationStatus.cancelled
                ? 'cancelled'
                : (next.errorMessage ?? 'generation failed'),
          ),
        );
      case GenerationStatus.generating:
      case GenerationStatus.idle:
        break;
    }
  }

  /// 完成登记：新图按序与 pending 壳配对，复制进 run 目录并写结果。
  Future<void> _finalizeCapture(
    ExploreManualCaptureState capture,
    ImageGenerationState next,
  ) async {
    state = const ExploreManualCaptureState(); // 先卸防，防重复登记
    final runId = capture.runId;
    if (runId == null) return;
    try {
      final produced = [
        for (final image in next.mergedPanelImages)
          if (!capture.imageIdsBefore.contains(image.id) && image.canSave)
            image,
      ];
      final elapsedMs = capture.armedAt == null
          ? null
          : DateTime.now().difference(capture.armedAt!).inMilliseconds;
      final listNotifier = ref.read(exploreRunListNotifierProvider.notifier);
      final imageStore = ref.read(exploreRunImageStoreProvider);
      for (var i = 0; i < capture.candidateIds.length; i++) {
        final candidateId = capture.candidateIds[i];
        if (i < produced.length) {
          final image = produced[i];
          final storedPath = await imageStore.storeCandidateImage(
            runId: runId,
            candidateId: candidateId,
            bytes: image.bytes,
            sourceFilePath: image.filePath,
          );
          await listNotifier.updateGeneration(
            runId,
            candidateId,
            ExploreCandidateGeneration(
              status: ExploreCandidateGenerationStatus.done,
              filePath: storedPath ?? image.filePath,
              seed: image.metadata?.seed,
              elapsedMs: elapsedMs,
            ),
          );
        } else {
          // 部分失败：多建的壳没有对应产出，标失败不留死壳。
          await listNotifier.updateGeneration(
            runId,
            candidateId,
            const ExploreCandidateGeneration(
              status: ExploreCandidateGenerationStatus.failed,
              error: 'no image produced',
            ),
          );
        }
      }
    } catch (error, stackTrace) {
      AppLogger.e(
        'Finalize explore manual capture failed',
        error,
        stackTrace,
        'ExploreManualCapture',
      );
    }
  }

  Future<void> _failCapture(
    ExploreManualCaptureState capture,
    String error,
  ) async {
    state = const ExploreManualCaptureState();
    final runId = capture.runId;
    if (runId == null) return;
    try {
      final listNotifier = ref.read(exploreRunListNotifierProvider.notifier);
      for (final candidateId in capture.candidateIds) {
        await listNotifier.updateGeneration(
          runId,
          candidateId,
          ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.failed,
            error: error,
          ),
        );
      }
    } catch (error, stackTrace) {
      AppLogger.e(
        'Fail explore manual capture failed',
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
