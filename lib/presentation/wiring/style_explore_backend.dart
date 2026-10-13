import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage_service.dart';
import '../../core/utils/localization_extension.dart';
import '../../data/models/style_explore/explore_run.dart' as domain;
import '../providers/generation/image_workflow_controller.dart';
import '../providers/auth_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/krita/bridge_draft_snapshot.dart';
import '../providers/krita/krita_bridge_notifier.dart';
import '../providers/pill_workspace_provider.dart';
import '../providers/prompt_block_library_provider.dart';
import '../providers/style_explore/explore_manual_capture.dart';
import '../providers/style_explore/explore_roll_capture.dart';
import '../providers/style_explore/explore_run_provider.dart';
import '../providers/style_explore/explore_run_runner.dart';
import '../ui/explore/explore_contract.dart' as ui;
import 'style_explore_platform.dart';

final styleExploreBackendProvider = Provider<StyleExploreBackend>(
  (ref) => StyleExploreBackend(ref),
);
final styleExploreCardSizeProvider = StateProvider<ui.ExploreCardSize>(
  (ref) =>
      ref
              .read(localStorageServiceProvider)
              .getSetting<String>('style_explore_card_size') ==
          'small'
      ? ui.ExploreCardSize.small
      : ui.ExploreCardSize.large,
);

class StyleExploreBackend {
  StyleExploreBackend(this.ref);
  final Ref ref;
  bool _writing = false;

  ExploreRunListNotifier get notifier =>
      ref.read(exploreRunListNotifierProvider.notifier);

  Future<domain.ExploreRun> run(String id) async {
    final current = await ref
        .read(styleExploreRunRepositoryProvider)
        .getRun(id);
    if (current == null) {
      throw StateError(currentL10n.styleExplore_operationFailed);
    }
    return current;
  }

  Future<void> setFavorite(String id, List<String> keys, bool value) async {
    for (final key in keys.toSet()) {
      if ((await run(id)).candidateById(key)?.review.heart != value) {
        await notifier.updateReview(id, key, heart: value);
      }
    }
  }

  Future<void> createGroup(String id, String name, List<String> keys) async {
    final group = await notifier.createFolder(id, name);
    if (keys.isNotEmpty) {
      await notifier.assignCandidatesFolder(id, keys, group.id);
    }
  }

  Future<void> deleteCandidates(String id, List<String> keys) async {
    final deletion = await notifier.softDeleteCandidates(id, keys);
    final previous = (await ref.read(exploreRunListNotifierProvider.future))
        .deletions
        .where(
          (entry) =>
              entry.before.id == id &&
              entry.createdAt.isBefore(deletion.createdAt),
        )
        .toList();
    for (final entry in previous) {
      await notifier.dismissCandidateDeletion(entry.id);
    }
  }

  Future<void> saveBlock(ui.ExploreBlockDraft draft) async {
    if (draft.title.trim().isEmpty ||
        (draft.fullText ?? draft.atoms.join(', ')).trim().isEmpty) {
      throw StateError(currentL10n.styleExplore_adoptBlockEmpty);
    }
    await ref
        .read(promptBlockLibraryNotifierProvider.notifier)
        .createBlock(
          title: draft.title,
          content: draft.fullText ?? draft.atoms.join(', '),
          atoms: draft.fullText == null ? draft.atoms : null,
          folderId: draft.folderId,
          color:
              '#${draft.color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
        );
  }

  Future<String> startEvolution(String id, ui.ExploreEvolutionPlan plan) async {
    final current = await run(id);
    final parents = <({String? sourceCandidateId, String artistString})>[];
    for (final key in plan.candidateKeys.toSet()) {
      final candidate = current.candidateById(key);
      if (candidate == null ||
          candidate.generation.status !=
              domain.ExploreCandidateGenerationStatus.done) {
        throw StateError(currentL10n.styleExplore_operationFailed);
      }
      parents.add((
        sourceCandidateId: key,
        artistString: exploreParentStringFor(candidate),
      ));
    }
    parents.addAll(
      plan.customParents.map(
        (text) => (sourceCandidateId: null, artistString: text),
      ),
    );
    if (plan.joinLineId != null) {
      await notifier.addParentsToActiveSet(
        id,
        familyId: plan.joinLineId!,
        parents: parents,
      );
      return plan.joinLineId!;
    }
    final family = await notifier.createFamily(
      id,
      name: plan.newLineName ?? '',
      parents: parents,
    );
    return family.id;
  }

  Future<void> compare(
    String id,
    String lineId,
    String left,
    String right,
    ui.ExploreCompareResult result,
  ) async {
    final current = await run(id);
    final set = current.familyById(lineId)?.activeParentSetId;
    if (set == null) throw StateError(currentL10n.styleExplore_operationFailed);
    await notifier.recordComparison(
      id,
      set,
      leftParentId: left,
      rightParentId: right,
      result: domain.ExploreComparisonResult.values.byName(result.name),
    );
  }

  Future<void> generateChildren(String id, String lineId, int count) async {
    final current = await run(id);
    final family = current.familyById(lineId);
    if (family == null || count < 1 || count > 100) {
      throw StateError(currentL10n.styleExplore_operationFailed);
    }
    final started = await ref
        .read(exploreRunRunnerProvider.notifier)
        .startDeepRound(
          id,
          familyId: lineId,
          parentSetId: family.activeParentSetId,
          count: count,
        );
    if (!started) throw StateError(currentL10n.styleExplore_runBusy);
  }

  Future<void> breed(String id, String lineId, List<String> keys) async {
    await notifier.createBranch(
      id,
      familyId: lineId,
      selectedCandidateIds: keys.toSet().toList(),
    );
  }

  Future<void> deleteRun(String id) async {
    await ref.read(exploreRunRunnerProvider.notifier).cancelAndWait(id);
    final capture = ref.read(exploreManualCaptureProvider);
    if (capture.armed && capture.runId == id) {
      final generation = ref.read(imageGenerationNotifierProvider);
      if (generation.isGenerating &&
          generation.generationRunId == capture.generationRunId) {
        ref.read(imageGenerationNotifierProvider.notifier).cancel();
      }
      await ref.read(exploreManualCaptureProvider.notifier).cancelAndWait();
    }
    final deletions = (await ref.read(
      exploreRunListNotifierProvider.future,
    )).deletions.where((entry) => entry.before.id == id).toList();
    for (final deletion in deletions) {
      await notifier.dismissCandidateDeletion(deletion.id);
    }
    await notifier.delete(id);
    if (ref.read(exploreActiveRunIdProvider) == id) {
      ref.read(exploreActiveRunIdProvider.notifier).state = null;
    }
  }

  Future<void> deleteLine(String id, String lineId) async {
    final current = await run(id);
    final sets = current.parentSets
        .where((set) => set.familyId == lineId)
        .map((set) => set.id)
        .toSet();
    final children = current.candidates
        .where(
          (candidate) =>
              sets.contains(current.roundById(candidate.roundId)?.parentSetId),
        )
        .map((candidate) => candidate.id)
        .toList();
    final deletion = children.isEmpty
        ? null
        : await notifier.softDeleteCandidates(id, children);
    try {
      await notifier.deleteFamily(id, lineId);
    } catch (_) {
      if (deletion != null) await notifier.undoCandidateDeletion(deletion.id);
      rethrow;
    }
    if (deletion != null) await notifier.dismissCandidateDeletion(deletion.id);
  }

  Future<void> stop(
    String? id, {
    String? runnerOwnerId,
    int? captureSessionId,
  }) async {
    final runner = ref.read(exploreRunRunnerProvider);
    if (runner.isRunning &&
        runner.runId == id &&
        (runnerOwnerId == null || runnerOwnerId == runner.ownerId)) {
      ref.read(exploreRunRunnerProvider.notifier).cancel();
      return;
    }
    final capture = ref.read(exploreManualCaptureProvider);
    if (capture.armed &&
        capture.runId == id &&
        (captureSessionId == null || captureSessionId == capture.sessionId)) {
      final generation = ref.read(imageGenerationNotifierProvider);
      if (generation.isGenerating &&
          generation.generationRunId == capture.generationRunId) {
        ref.read(imageGenerationNotifierProvider.notifier).cancel();
      }
      await ref
          .read(exploreManualCaptureProvider.notifier)
          .cancelAndWait(
            generationRunId: capture.generationRunId,
            sessionId: capture.sessionId,
          );
      return;
    }
    if (id != null &&
        (await ref.read(styleExploreRunRepositoryProvider).getRun(id))
                ?.status ==
            domain.ExploreRunStatus.paused) {
      await notifier.cancelPaused(id);
    }
  }

  bool Function() captureGeneration(
    String? id, {
    required bool Function() alive,
  }) {
    final params = ref.read(generationParamsNotifierProvider);
    final version = ref.read(bridgeDraftVersionProvider);
    final account = ref.read(authNotifierProvider).accountId;
    final selection = ref.read(exploreRunSelectionEpochProvider);
    return () =>
        alive() &&
        !busy &&
        ref.read(exploreActiveRunIdProvider) == id &&
        ref.read(exploreRunSelectionEpochProvider) == selection &&
        ref.read(generationParamsNotifierProvider) == params &&
        ref.read(bridgeDraftVersionProvider) == version &&
        ref.read(authNotifierProvider).accountId == account;
  }

  Future<void> setCardSize(ui.ExploreCardSize value) async {
    ref.read(styleExploreCardSizeProvider.notifier).state = value;
    await ref
        .read(localStorageServiceProvider)
        .setSetting<String>('style_explore_card_size', value.name);
  }

  bool get busy =>
      ref.read(exploreRunRunnerProvider).isRunning ||
      ref.read(imageGenerationNotifierProvider).isGenerating ||
      ref.read(imageWorkflowControllerProvider).isToolRunning ||
      (ref.exists(kritaBridgeNotifierProvider) &&
          ref.read(kritaBridgeNotifierProvider).isBridgeGenerating);

  Future<void> Function(FutureOr<void> Function()) captureDraft({
    required bool Function() alive,
  }) {
    final params = ref.read(generationParamsNotifierProvider);
    final version = ref.read(bridgeDraftVersionProvider);
    final workflow = ref.read(imageWorkflowControllerProvider);
    void check() {
      if (!alive() ||
          ref.read(generationParamsNotifierProvider) != params ||
          ref.read(bridgeDraftVersionProvider) != version ||
          !identical(workflow, ref.read(imageWorkflowControllerProvider))) {
        throw StateError(currentL10n.bridge_conflict);
      }
      if (busy) throw StateError(currentL10n.styleExplore_runBusy);
    }

    check();
    final draft = readBridgeDraft(ref).toJson();
    return (write) async {
      if (_writing) throw StateError(currentL10n.bridge_conflict);
      _writing = true;
      try {
        check();
        await ref
            .read(styleExplorePlatformProvider)
            .backupDraft(
              jsonEncode({
                ...draft,
                'generation': params.toJson(),
                'sourceImage': params.sourceImage == null
                    ? null
                    : base64Encode(params.sourceImage!),
                'maskImage': params.maskImage == null
                    ? null
                    : base64Encode(params.maskImage!),
                'vibes': [
                  for (final vibe in params.vibeReferencesV4)
                    {
                      ...vibe.toJson(),
                      'rawImageData': vibe.rawImageData == null
                          ? null
                          : base64Encode(vibe.rawImageData!),
                      'thumbnail': vibe.thumbnail == null
                          ? null
                          : base64Encode(vibe.thumbnail!),
                    },
                ],
              }),
            );
        check();
        await write();
      } finally {
        _writing = false;
      }
    };
  }

  Future<void> applyCandidate(
    String id,
    String key,
    Future<void> Function(FutureOr<void> Function()) write,
  ) async {
    final current = await run(id);
    final candidate = current.candidateById(key);
    final positive = candidate?.rollSnapshot?.positive;
    if (positive == null) {
      throw StateError(currentL10n.styleExplore_operationFailed);
    }
    await write(() {
      ref
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .replaceWithPlainText(positive);
      ref
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately(
            ref.read(pillWorkspaceProvider(PillScopes.main)).projection,
          );
    });
  }
}
