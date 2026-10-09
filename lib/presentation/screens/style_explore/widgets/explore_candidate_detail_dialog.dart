import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_view_state.dart';
import '../../../widgets/common/image_detail/components/viewer_stage.dart';
import '../../../widgets/common/image_detail/components/viewer_top_bar.dart';
import '../../../widgets/common/image_detail/components/viewer_filmstrip.dart';
import 'explore_candidate_actions.dart';
import 'explore_inspector.dart';

/// Full-screen adapter over the shared stage. IDs snapshot the visible browsing
/// order; live records supply review and assignment state.
class ExploreCandidateDetailDialog extends ConsumerStatefulWidget {
  const ExploreCandidateDetailDialog({
    super.key,
    required this.runId,
    required this.candidateIds,
    this.initialIndex = 0,
  });
  final String runId;
  final List<String> candidateIds;
  final int initialIndex;
  static Future<String?> show(
    BuildContext context, {
    required String runId,
    required List<String> candidateIds,
    int initialIndex = 0,
  }) => showDialog<String>(
    context: context,
    useSafeArea: false,
    builder: (_) => ExploreCandidateDetailDialog(
      runId: runId,
      candidateIds: candidateIds,
      initialIndex: initialIndex,
    ),
  );
  @override
  ConsumerState<ExploreCandidateDetailDialog> createState() =>
      _ExploreCandidateDetailDialogState();
}

class _ExploreCandidateDetailDialogState
    extends ConsumerState<ExploreCandidateDetailDialog> {
  late String? _current = widget.candidateIds.isEmpty
      ? null
      : widget.candidateIds[widget.initialIndex.clamp(
          0,
          widget.candidateIds.length - 1,
        )];
  late final _pages = PageController(initialPage: widget.initialIndex);
  final _transforms = <String, TransformationController>{};
  final _fitScales = <String, double>{};
  bool? _manualPanel;
  bool _closing = false;
  TransformationController get _transform =>
      _transforms.putIfAbsent(_current!, TransformationController.new);
  @override
  void dispose() {
    _pages.dispose();
    for (final c in _transforms.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _resolve(ExploreRun run) {
    if (run.candidateById(_current ?? '') != null) return _current;
    final previous = widget.candidateIds.indexOf(_current ?? '');
    for (var i = previous + 1; i < widget.candidateIds.length; i++) {
      if (run.candidateById(widget.candidateIds[i]) != null) {
        return widget.candidateIds[i];
      }
    }
    for (var i = previous - 1; i >= 0; i--) {
      if (run.candidateById(widget.candidateIds[i]) != null) {
        return widget.candidateIds[i];
      }
    }
    return null;
  }

  void _close([String? evolution]) {
    if (_closing) return;
    _closing = true;
    ref.read(exploreFocusedCandidateIdProvider.notifier).state = ref
        .read(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(widget.runId)
        ?.candidateById(_current ?? '')
        ?.id;
    Navigator.of(context).pop(evolution);
  }

  void _jump(List<ExploreCandidate> candidates, int index) {
    if (index < 0 || index >= candidates.length) return;
    setState(() => _current = candidates[index].id);
    if (_pages.hasClients) _pages.jumpToPage(index);
  }

  Future<void> _assign(ExploreRun run, ExploreCandidate c, int number) async {
    final id = number == 0 ? null : run.folders.elementAtOrNull(number - 1)?.id;
    if (number > 0 && id == null) return;
    await ref
        .read(exploreRunListNotifierProvider.notifier)
        .assignCandidateFolder(
          run.id,
          c.id,
          number != 0 && c.folderId == id ? null : id,
        );
  }

  void _advance(ExploreRun run, String? folder) {
    if (folder == null) return;
    final visible = [
      for (final id in widget.candidateIds)
        if (run.candidateById(id) case final c?) c,
    ];
    final index = visible.indexWhere((c) => c.id == _current);
    for (var i = index + 1; i < visible.length; i++) {
      if (visible[i].folderId == null) {
        _jump(visible, i);
        return;
      }
    }
  }

  void _zoom(double factor) {
    setState(
      () =>
          _transform.value = _transform.value.clone()
            ..scaleByDouble(factor, factor, 1, 1),
    );
  }

  void _fit() {
    setState(() => _transform.value = Matrix4.identity());
  }

  void _original() {
    final s = 1 / (_fitScales[_current] ?? 1);
    setState(
      () => _transform.value = Matrix4.identity()..scaleByDouble(s, s, 1, 1),
    );
  }

  Future<void> _fullscreen() async {
    try {
      await windowManager.setFullScreen(!await windowManager.isFullScreen());
    } on MissingPluginException {
      // No native window in widget tests.
    }
  }

  void _help() {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shortcut_help_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '← → · ${l10n.styleExplore_prevCandidate} / ${l10n.styleExplore_nextCandidate}',
            ),
            Text('F · ${l10n.styleExplore_filterHearted}'),
            Text('E · ${l10n.styleExplore_startEvolution}'),
            Text(l10n.styleExplore_viewerGroupsShortcut),
            Text('I · ${l10n.styleExplore_inspectorTitle}'),
            Text('Delete · ${l10n.common_delete}'),
            Text('Esc · ${l10n.common_close}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final runs = ref.watch(exploreRunListNotifierProvider);
    if (runs.isLoading && !runs.hasValue) {
      return const Dialog.fullscreen(
        child: ColoredBox(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final run = runs.valueOrNull?.runById(widget.runId);
    final resolved = run == null ? null : _resolve(run);
    if (resolved == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _close();
      });
      return const Dialog.fullscreen(child: ColoredBox(color: Colors.black));
    }
    final changed = resolved != _current;
    _current = resolved;
    final candidates = [
      for (final id in widget.candidateIds)
        if (run!.candidateById(id) case final c?) c,
    ];
    final index = candidates.indexWhere((c) => c.id == _current),
        candidate = candidates[index],
        round = run!.roundById(candidate.roundId);
    if (changed || (_pages.hasClients && _pages.page?.round() != index)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(index);
      });
    }
    String two(int n) => n.toString().padLeft(2, '0');
    final time = round?.createdAt.toLocal();
    return Dialog.fullscreen(
      key: const Key('explore-candidate-detail'),
      child: LayoutBuilder(
        builder: (context, box) {
          final narrow = ViewerStage.isNarrow(box.maxWidth),
              visible = _manualPanel ?? !narrow;
          void toggle() => setState(() => _manualPanel = !visible);
          return ViewerStage(
            itemCount: candidates.length,
            currentIndex: index,
            pageController: _pages,
            onIndexChanged: (i) => setState(() => _current = candidates[i].id),
            onEscape: _close,
            panelVisible: visible,
            onTogglePanel: toggle,
            previousLabel: context.l10n.styleExplore_prevCandidate,
            nextLabel: context.l10n.styleExplore_nextCandidate,
            extraShortcuts: {
              const SingleActivator(LogicalKeyboardKey.keyF): () => unawaited(
                ref
                    .read(exploreRunListNotifierProvider.notifier)
                    .updateReview(
                      run.id,
                      candidate.id,
                      heart: !candidate.review.heart,
                    ),
              ),
              const SingleActivator(LogicalKeyboardKey.keyE): () =>
                  _close(candidate.id),
              const SingleActivator(LogicalKeyboardKey.delete): () => unawaited(
                ExploreCandidateActions.deleteImage(
                  context,
                  ref,
                  runId: run.id,
                  candidate: candidate,
                ),
              ),
              for (var i = 0; i <= 9; i++)
                SingleActivator(
                  [
                    LogicalKeyboardKey.digit0,
                    LogicalKeyboardKey.digit1,
                    LogicalKeyboardKey.digit2,
                    LogicalKeyboardKey.digit3,
                    LogicalKeyboardKey.digit4,
                    LogicalKeyboardKey.digit5,
                    LogicalKeyboardKey.digit6,
                    LogicalKeyboardKey.digit7,
                    LogicalKeyboardKey.digit8,
                    LogicalKeyboardKey.digit9,
                  ][i],
                ): () =>
                    unawaited(_assign(run, candidate, i)),
              const SingleActivator(LogicalKeyboardKey.numpad4): () =>
                  _jump(candidates, index - 1),
              const SingleActivator(LogicalKeyboardKey.numpad6): () =>
                  _jump(candidates, index + 1),
              const SingleActivator(LogicalKeyboardKey.keyR): _fit,
              const SingleActivator(LogicalKeyboardKey.equal): () => _zoom(1.2),
              const SingleActivator(LogicalKeyboardKey.minus): () =>
                  _zoom(1 / 1.2),
              const SingleActivator(LogicalKeyboardKey.slash, shift: true):
                  _help,
            },
            topBar: ValueListenableBuilder<Matrix4>(
              valueListenable: _transform,
              builder: (context, matrix, child) => ViewerTopBar(
                backLabel: context.l10n.styleExplore_viewerBack,
                onBack: _close,
                position: Row(
                  children: [
                    Text(
                      '#${run.candidates.indexOf(candidate) + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '${context.l10n.styleExplore_viewerPosition(index + 1, candidates.length)} · ${context.l10n.styleExplore_roundNumber(round?.number ?? 1)}${time == null ? '' : ' · ${two(time.hour)}:${two(time.minute)}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: .55),
                        ),
                      ),
                    ),
                  ],
                ),
                onZoomIn: () => _zoom(1.2),
                onZoomOut: () => _zoom(1 / 1.2),
                onOriginalSize: _original,
                onFit: _fit,
                onFullscreen: () => unawaited(_fullscreen()),
                onTogglePanel: toggle,
                panelVisible: visible,
                reserveWindowButtons: narrow || !visible,
                zoomLabel:
                    _transforms[_current] == null ||
                        _transform.value.getMaxScaleOnAxis() == 1
                    ? context.l10n.viewer_fit
                    : '${(_transform.value.getMaxScaleOnAxis() * (_fitScales[_current] ?? 1) * 100).round()}%',
              ),
            ),
            pageBuilder: (context, i) {
              final c = candidates[i];
              return LayoutBuilder(
                builder: (context, box) {
                  _fitScales[c.id] = math.min(
                    box.maxWidth / run.paramsSnapshot.width,
                    box.maxHeight / run.paramsSnapshot.height,
                  );
                  final transform = _transforms.putIfAbsent(
                    c.id,
                    TransformationController.new,
                  );
                  return GestureDetector(
                    onDoubleTap: () {
                      transform.value = Matrix4.identity();
                      if (mounted) setState(() {});
                    },
                    child: InteractiveViewer(
                      transformationController: transform,
                      minScale: .05,
                      maxScale: 20,
                      child: SizedBox.expand(
                        child: c.generation.filePath == null
                            ? Center(
                                child: Text(
                                  context.l10n.styleExplore_candidateMissing,
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              )
                            : Image.file(
                                File(c.generation.filePath!),
                                fit: BoxFit.contain,
                                cacheWidth: 1600,
                                gaplessPlayback: true,
                                errorBuilder: (_, error, stack) => Center(
                                  child: Text(
                                    context.l10n.styleExplore_candidateMissing,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              );
            },
            filmstrip: ViewerFilmstrip(
              items: [
                for (final c in candidates)
                  ViewerFilmstripItem(
                    thumbnail: c.generation.filePath == null
                        ? null
                        : FileImage(File(c.generation.filePath!)),
                    aspectRatio:
                        run.paramsSnapshot.width / run.paramsSnapshot.height,
                    semanticLabel: '#${run.candidates.indexOf(c) + 1}',
                  ),
              ],
              currentIndex: index,
              onTap: (i) => _jump(candidates, i),
            ),
            panel: ExploreInspector(
              runId: run.id,
              candidateId: candidate.id,
              viewer: true,
              onEvolution: () => _close(candidate.id),
              onAssigned: (folder) => _advance(run, folder),
            ),
          );
        },
      ),
    );
  }
}
