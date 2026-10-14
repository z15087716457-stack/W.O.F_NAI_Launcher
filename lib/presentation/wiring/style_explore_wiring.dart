import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../data/models/style_explore/explore_run.dart'
    show ExploreRunStatus, ExploreCandidateGenerationStatus;
import '../../core/utils/localization_extension.dart';
import '../providers/cost_estimate_provider.dart';
import '../providers/generation/image_workflow_controller.dart';
import '../providers/generation/local_upscale_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/krita/krita_bridge_notifier.dart';
import '../providers/layout_state_provider.dart';
import '../providers/pill_workspace_provider.dart';
import '../providers/prompt_block_library_provider.dart';
import '../providers/style_explore/explore_manual_capture.dart';
import '../providers/style_explore/explore_run_provider.dart';
import '../providers/style_explore/explore_run_runner.dart';
import '../providers/style_explore_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/generation/widgets/generation_controls/generation_controls.dart';
import '../utils/explore_auto_run_name.dart';
import '../utils/explore_display_data.dart';
import '../ui/explore/explore_contract.dart';
import '../ui/explore/explore_page.dart';
import '../utils/asset_protection_guard.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/themed_confirm_dialog.dart';
import '../widgets/navigation/integrated_title_bar.dart';
import 'generation_blocks_dock.dart';
import 'style_explore_backend.dart';
import 'style_explore_blocks_wiring.dart';
import 'style_explore_editor_wiring.dart';
import 'style_explore_mapping.dart';
import 'style_explore_platform.dart';

class StyleExploreWiring extends ConsumerStatefulWidget {
  const StyleExploreWiring({super.key, this.editor, this.generationController});
  final ExploreEditorBuilder? editor;
  final GenerationControlsController? generationController;

  @override
  ConsumerState<StyleExploreWiring> createState() => _StyleExploreWiringState();
}

class _StyleExploreWiringState extends ConsumerState<StyleExploreWiring> {
  late final _generation =
      widget.generationController ?? GenerationControlsController();
  late final StyleExploreWindow _window;
  late final ExploreManualCaptureNotifier _capture;
  final _owner = Object();
  late final StateController<Object?> _windowOwner;
  late final StateController<({bool fullscreen, bool captionOverStage})>
  _windowState;
  bool _generating = false;
  String? _manualRunId;
  String _manualRunName = '';
  bool Function()? _manualGuard;

  @override
  void initState() {
    super.initState();
    _window = StyleExploreWindow(ref.read(styleExplorePlatformProvider));
    _capture = ref.read(exploreManualCaptureProvider.notifier);
    _windowState = ref.read(styleExploreWindowProvider.notifier);
    _windowOwner = ref.read(styleExploreWindowOwnerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _windowOwner.state = _owner;
        _windowState.state = (fullscreen: false, captionOverStage: false);
      }
    });
  }

  @override
  void dispose() {
    if (widget.generationController == null) _generation.dispose();
    unawaited(
      _window
          .restore()
          .then((_) {
            if (_windowOwner.mounted &&
                _windowState.mounted &&
                identical(_windowOwner.state, _owner)) {
              _windowOwner.state = null;
              _windowState.state = (fullscreen: false, captionOverStage: false);
            }
          })
          .catchError((Object error, StackTrace stack) {
            AppLogger.e(
              'Restore explore window failed',
              error,
              stack,
              'StyleExplore',
            );
          }),
    );
    super.dispose();
  }

  Future<void> _run(FutureOr<void> Function() action) async {
    try {
      await action();
    } catch (error, stack) {
      AppLogger.e('Explore action failed', error, stack, 'StyleExplore');
      if (mounted) {
        AppToast.error(context, context.l10n.styleExplore_operationFailed);
      }
    }
  }

  Future<void> _generate(String? id) async {
    if (_generating) return;
    final backend = ref.read(styleExploreBackendProvider);
    if (backend.busy || ref.read(generationCooldownProvider).isActive) return;
    _generating = true;
    _manualRunId = id;
    _manualRunName = exploreAutoRunName(
      document: ref.read(pillWorkspaceProvider(PillScopes.main)).document,
      library: ref.read(promptBlockLibraryNotifierProvider).valueOrNull,
      l10n: context.l10n,
    );
    try {
      _manualGuard = backend.captureGeneration(id, alive: () => mounted);
      if (id != null) await backend.run(id);
      if (_manualGuard!()) await _generation.generate();
    } finally {
      _generating = false;
    }
  }

  Future<void> _batch(GenerationBatchEvent event) => _capture.handleBatchEvent(
    event,
    autoRunName: _manualRunName,
    activeRunId: _manualRunId,
  );

  Future<void> _children(
    String id,
    String lineId,
    int count, {
    List<String>? breed,
  }) async {
    if (_generating) return;
    final backend = ref.read(styleExploreBackendProvider);
    if (backend.busy) throw StateError(context.l10n.styleExplore_runBusy);
    _generating = true;
    final l10n = context.l10n;
    try {
      final valid = backend.captureGeneration(id, alive: () => mounted);
      final original = await backend.run(id);
      if (!mounted) return;
      final family = original.familyById(lineId);
      final parentSet = family == null
          ? null
          : original.parentSetById(family.activeParentSetId);
      final cost = ref.read(styleExploreCostForCountProvider(count));
      final confirmed = await AssetProtectionGuard.confirmHighAnlasCost(
        context: context,
        ref: ref,
        cost: cost,
      );
      if (!confirmed || !mounted) return;
      final latest = await backend.run(id);
      if (!valid() ||
          latest.familyById(lineId) != family ||
          (family != null &&
              latest.parentSetById(family.activeParentSetId) != parentSet) ||
          ref.read(styleExploreCostForCountProvider(count)) != cost) {
        throw StateError(l10n.bridge_conflict);
      }
      if (breed != null) await backend.breed(id, lineId, breed);
      await backend.generateChildren(id, lineId, count);
    } finally {
      _generating = false;
    }
  }

  Future<void> _retry(String id, {bool resume = false}) async {
    final backend = ref.read(styleExploreBackendProvider);
    if (_generating || backend.busy) return;
    _generating = true;
    final l10n = context.l10n;
    try {
      final valid = backend.captureGeneration(id, alive: () => mounted);
      final original = await backend.run(id);
      if (!mounted) return;
      final targets = resume
          ? original.pendingCandidates
          : original.candidates
                .where(
                  (candidate) =>
                      candidate.generation.status ==
                      ExploreCandidateGenerationStatus.failed,
                )
                .toList();
      if (targets.isEmpty ||
          (resume && original.status != ExploreRunStatus.paused)) {
        return;
      }
      final cost = ref.read(styleExploreCostForCountProvider(targets.length));
      final confirmed = await AssetProtectionGuard.confirmHighAnlasCost(
        context: context,
        ref: ref,
        cost: cost,
      );
      if (!confirmed || !mounted) return;
      final latest = await backend.run(id);
      if (!valid() ||
          latest.status != original.status ||
          !targets.every(
            (candidate) => latest.candidateById(candidate.id) == candidate,
          ) ||
          ref.read(styleExploreCostForCountProvider(targets.length)) != cost) {
        throw StateError(l10n.bridge_conflict);
      }
      final runner = ref.read(exploreRunRunnerProvider.notifier);
      final started = await (resume
          ? runner.start(id)
          : runner.retryFailed(id));
      if (!started && mounted) {
        AppToast.info(context, context.l10n.styleExplore_runBusy);
      }
    } finally {
      _generating = false;
    }
  }

  Future<void> _apply(String id, String key) async {
    final backend = ref.read(styleExploreBackendProvider);
    final original = await backend.run(id);
    if (!mounted) return;
    final snapshot = original.candidateById(key)?.rollSnapshot;
    final write = backend.captureDraft(
      alive: () =>
          mounted &&
          ref.read(exploreActiveRunIdProvider) == id &&
          ref
                  .read(exploreActiveRunProvider)
                  ?.candidateById(key)
                  ?.rollSnapshot ==
              snapshot,
    );
    if (ref.read(styleExploreNeedsOverwriteConfirmProvider)) {
      final confirmed = await ThemedConfirmDialog.show(
        context: context,
        title: context.l10n.styleExplore_discardChangesTitle,
        content: context.l10n.styleExplore_discardChangesMessage,
        confirmText: context.l10n.styleExplore_discardChangesConfirm,
        cancelText: context.l10n.common_cancel,
      );
      if (!confirmed || !mounted) return;
    }
    await backend.applyCandidate(id, key, write);
    if (mounted) {
      AppToast.success(context, context.l10n.styleExplore_appliedToEditor);
    }
  }

  Future<void> _fullscreen(bool value) async {
    await _window.change(value);
    if (mounted) {
      _windowState.state = (fullscreen: value, captionOverStage: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(exploreRunListNotifierProvider);
    final current = ref.watch(exploreActiveRunProvider);
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final runner = ref.watch(exploreRunRunnerProvider);
    final capture = ref.watch(exploreManualCaptureProvider);
    final generation = ref.watch(imageGenerationNotifierProvider);
    final params = ref.watch(generationParamsNotifierProvider);
    final layout = ref.watch(layoutStateNotifierProvider);
    final window = ref.watch(styleExploreWindowProvider);
    final backend = ref.read(styleExploreBackendProvider);
    final undo = current == null
        ? null
        : list.valueOrNull?.undoForRun(current.id);
    final runId = current?.id;
    final activeId = ref.watch(exploreActiveRunIdProvider);
    void withRun(FutureOr<void> Function(String id) action) {
      if (runId != null) unawaited(_run(() => action(runId)));
    }

    final data = ExploreViewData(
      now: DateTime.now(),
      loading: list.isLoading,
      runs: [
        for (final run in list.valueOrNull?.runs ?? [])
          styleExploreRunSummary(run, runner: runner, capture: capture),
      ],
      run: current == null
          ? null
          : styleExploreRunView(
              current,
              library: library,
              runner: runner,
              capture: capture,
            ),
      variables: styleExploreVariables(
        ref.watch(pillWorkspaceProvider(PillScopes.main)).document,
        library,
        missingLabel: context.l10n.blocks_missing,
      ),
      generate: styleExploreGenerate(
        count: params.nSamples,
        cost: ref.watch(estimatedCostForBatchSizeProvider(1)),
        balance: ref.watch(anlasBalanceProvider),
        generation: generation,
        runner: runner,
        capture: capture,
        activeRunId: runId,
        cooldown: ref.watch(generationCooldownProvider).remainingSeconds,
        otherBusy:
            ref.watch(localUpscaleTaskProvider).running ||
            ref.watch(imageWorkflowControllerProvider).isToolRunning ||
            ref.watch(kritaBridgeNotifierProvider).isBridgeGenerating,
      ),
      cardSize: ref.watch(styleExploreCardSizeProvider),
      inspectorOpen: layout.styleExploreInspectorVisible ?? true,
      editorWidth: layout.styleExploreEditorWidth,
      blockFolders: styleExploreBlockFolders(
        library,
        context.l10n.promptBlockLibrary_title,
      ),
      undo: undo == null
          ? null
          : ExploreUndo(id: undo.id, count: undo.candidateIds.length),
      fullscreen: window.fullscreen,
    );
    final actions = ExploreActions(
      onOpenRun: (id) {
        ref.read(exploreRunSelectionEpochProvider.notifier).state++;
        ref.read(exploreActiveRunIdProvider.notifier).state = id;
      },
      onNewRun: () {
        ref.read(exploreRunSelectionEpochProvider.notifier).state++;
        ref.read(exploreActiveRunIdProvider.notifier).state = null;
      },
      onRenameRun: (id, name) => unawaited(
        _run(() async {
          await backend.notifier.rename(id, name);
        }),
      ),
      onDeleteRun: (id) => unawaited(_run(() => backend.deleteRun(id))),
      onGenerate: () => unawaited(_run(() => _generate(activeId))),
      onStop: () => unawaited(
        _run(
          () => backend.stop(
            activeId,
            runnerOwnerId: runner.ownerId,
            captureSessionId: capture.sessionId,
          ),
        ),
      ),
      onPause: () {
        final latest = ref.read(exploreRunRunnerProvider);
        if (latest.runId == runId &&
            latest.isRunning &&
            latest.ownerId == runner.ownerId) {
          ref.read(exploreRunRunnerProvider.notifier).pause();
        }
      },
      onResume: () => withRun((id) => _retry(id, resume: true)),
      onCountChanged: (count) {
        ref
            .read(generationParamsNotifierProvider.notifier)
            .updateNSamples(count.clamp(1, 100));
      },
      onRetryFailed: () => withRun(_retry),
      onSetFavorite: (keys, value) =>
          withRun((id) => backend.setFavorite(id, keys, value)),
      onAssignGroup: (keys, group) => withRun((id) async {
        if (keys.isNotEmpty) {
          await backend.notifier.assignCandidatesFolder(
            id,
            keys.toSet().toList(),
            group,
          );
        }
      }),
      onCreateGroup: (name, keys) =>
          withRun((id) => backend.createGroup(id, name, keys)),
      onRenameGroup: (group, name) => withRun((id) async {
        await backend.notifier.renameFolder(id, group, name);
      }),
      onDeleteGroup: (group) => withRun((id) async {
        await backend.notifier.deleteFolder(id, group);
      }),
      onDeleteCandidates: (keys) =>
          withRun((id) => backend.deleteCandidates(id, keys)),
      onUndoDelete: () {
        if (undo != null) {
          unawaited(
            _run(() => backend.notifier.undoCandidateDeletion(undo.id)),
          );
        }
      },
      onDismissUndo: () {
        if (undo != null) {
          unawaited(
            _run(() => backend.notifier.dismissCandidateDeletion(undo.id)),
          );
        }
      },
      onCopyArtists: (keys) => withRun((id) async {
        final run = await backend.run(id);
        await Clipboard.setData(
          ClipboardData(
            text: exploreMergedArtistAtoms([
              for (final key in keys)
                if (run.candidateById(key) case final candidate?) candidate,
            ]).join(', '),
          ),
        );
      }),
      onApplyToEditor: (key) => withRun((id) => _apply(id, key)),
      onSaveBlock: (draft) => unawaited(
        _run(() async {
          await backend.saveBlock(draft);
          if (context.mounted) {
            AppToast.success(
              context,
              context.l10n.styleExplore_adoptBlockSaved(draft.title),
            );
          }
        }),
      ),
      onStartEvolution: (plan) => withRun((id) async {
        final line = await backend.startEvolution(id, plan);
        if (plan.generate != null && mounted) {
          await _children(id, line, plan.generate!);
        }
      }),
      onCompare: (line, left, right, result) =>
          withRun((id) => backend.compare(id, line, left, right, result)),
      onBreed: (line, keys) =>
          withRun((id) => _children(id, line, 8, breed: keys)),
      onGenerateChildren: (line, count) =>
          withRun((id) => _children(id, line, count)),
      onRenameLine: (line, name) => withRun((id) async {
        await backend.notifier.renameFamily(id, line, name);
      }),
      onDeleteLine: (line) => withRun((id) => backend.deleteLine(id, line)),
      onOpenVariable: (index) =>
          unawaited(_run(() => openStyleExploreVariable(context, ref, index))),
      onOpenBlockLibrary: () => unawaited(
        _run(
          () => ref
              .read(layoutStateNotifierProvider.notifier)
              .setBlockLibraryPanelExpanded(true),
        ),
      ),
      onCardSizeChanged: (value) =>
          unawaited(_run(() => backend.setCardSize(value))),
      onInspectorChanged: (value) => unawaited(
        _run(
          () => ref
              .read(layoutStateNotifierProvider.notifier)
              .setStyleExploreInspectorVisible(value),
        ),
      ),
      onEditorWidthChanged: (value) => unawaited(
        _run(
          () => ref
              .read(layoutStateNotifierProvider.notifier)
              .setStyleExploreEditorWidth(value),
        ),
      ),
      onFullscreenChanged: (value) => unawaited(_run(() => _fullscreen(value))),
      onCaptionOverStage: (value) {
        if (mounted && identical(_windowOwner.state, _owner)) {
          final latest = _windowState.state;
          _windowState.state = (
            fullscreen: latest.fullscreen,
            captionOverStage: value && !latest.fullscreen,
          );
        }
      },
    );
    return Material(
      type: MaterialType.transparency,
      child: WindowChromePage(
        captionHeight: 61,
        hideCaptions: window.fullscreen,
        captionTheme: window.captionOverStage
            ? Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  brightness: Brightness.dark,
                  surface: const Color(0xff0b0b0b),
                  onSurface: Colors.white,
                ),
              )
            : null,
        child: StyleExplorePage(
          data: data,
          actions: actions,
          dock: layout.blockLibraryPanelExpanded
              ? BlocksDockWiring(
                  onInsert: (id) async {
                    await insertStyleExploreBlock(context, ref, id);
                  },
                )
              : null,
          editor:
              widget.editor ??
              (context, parts) => StyleExploreEditorWiring(
                parts: parts,
                controller: _generation,
                onBatchEvent: _batch,
                canGenerate: () => _manualGuard?.call() ?? false,
              ),
        ),
      ),
    );
  }
}
