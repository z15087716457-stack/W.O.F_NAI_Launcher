part of 'explore_candidate_detail_dialog.dart';

class _ExploreViewerState extends _ExploreViewerController {
  @override
  Widget build(BuildContext context) {
    final runs = ref.watch(exploreRunListNotifierProvider);
    final run = runs.valueOrNull?.runById(widget.runId);
    final id = run == null ? null : _resolve(run);
    if (id == null) {
      if (!runs.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _close();
        });
      }
      return Dialog.fullscreen(
        child: ColoredBox(
          color: Colors.black,
          child: runs.isLoading
              ? const Center(child: CircularProgressIndicator())
              : null,
        ),
      );
    }
    final candidates = [
      for (final key in widget.candidateIds)
        if (run!.candidateById(key) case final item?) item,
    ];
    final index = candidates.indexWhere((item) => item.id == id);
    final changed = _current != id;
    _current = id;
    if (changed || (_pages.hasClients && _pages.page?.round() != index)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(index);
      });
    }
    final current = candidates[index], round = run!.roundById(current.roundId);
    final l = context.l10n;
    return Dialog.fullscreen(
      key: const Key('explore-candidate-detail'),
      child: LayoutBuilder(
        builder: (context, bounds) {
          final narrow = ViewerStage.isNarrow(bounds.maxWidth),
              panelVisible = _manualPanel ?? !narrow;
          void togglePanel() => setState(() => _manualPanel = !panelVisible);
          return ViewerStage(
            itemCount: candidates.length,
            currentIndex: index,
            pageController: _pages,
            onIndexChanged: (i) => setState(() => _current = candidates[i].id),
            previousLabel: l.styleExplore_prevCandidate,
            nextLabel: l.styleExplore_nextCandidate,
            onEscape: _close,
            panelVisible: panelVisible,
            onTogglePanel: togglePanel,
            extraShortcuts: {
              const SingleActivator(LogicalKeyboardKey.keyF): () => unawaited(
                ref
                    .read(exploreRunListNotifierProvider.notifier)
                    .updateReview(
                      run.id,
                      current.id,
                      heart: !current.review.heart,
                    ),
              ),
              const SingleActivator(LogicalKeyboardKey.keyE): () =>
                  _close(current.id),
              const SingleActivator(LogicalKeyboardKey.delete): () => unawaited(
                ExploreCandidateActions.deleteImage(
                  context,
                  ref,
                  runId: run.id,
                  candidate: current,
                ),
              ),
              for (final (number, key) in [
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
              ].indexed)
                SingleActivator(key): () =>
                    unawaited(_assign(run, current, number)),
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
              builder: (context, matrix, _) {
                final scale = matrix.getMaxScaleOnAxis();
                return ViewerTopBar(
                  backLabel: l.styleExplore_viewerBack,
                  onBack: _close,
                  position: _ViewerPosition(
                    sequence: run.candidates.indexOf(current) + 1,
                    position: l.styleExplore_viewerPosition(
                      index + 1,
                      candidates.length,
                    ),
                    round: l.styleExplore_roundNumber(round?.number ?? 1),
                    time: round?.createdAt.toLocal(),
                  ),
                  onZoomIn: () => _zoom(1.2),
                  onZoomOut: () => _zoom(1 / 1.2),
                  onOriginalSize: _original,
                  onFit: _fit,
                  onFullscreen: () => unawaited(_fullscreen()),
                  onTogglePanel: togglePanel,
                  panelVisible: panelVisible,
                  reserveWindowButtons: narrow || !panelVisible,
                  zoomLabel: scale == 1
                      ? l.viewer_fit
                      : '${(scale * (_fitScales[_current] ?? 1) * 100).round()}%',
                );
              },
            ),
            pageBuilder: (context, i) => LayoutBuilder(
              builder: (context, box) {
                final candidate = candidates[i];
                _fitScales[candidate.id] = math.min(
                  box.maxWidth / run.paramsSnapshot.width,
                  box.maxHeight / run.paramsSnapshot.height,
                );
                final controller = _transforms.putIfAbsent(
                  candidate.id,
                  TransformationController.new,
                );
                return GestureDetector(
                  onDoubleTap: () {
                    controller.value = Matrix4.identity();
                    if (mounted) setState(() {});
                  },
                  child: InteractiveViewer(
                    transformationController: controller,
                    minScale: .05,
                    maxScale: 20,
                    child: SizedBox.expand(
                      child: candidate.generation.filePath != null
                          ? Image.file(
                              File(candidate.generation.filePath!),
                              fit: BoxFit.contain,
                              cacheWidth: 1600,
                              errorBuilder: (_, _, _) => _missing(context),
                            )
                          : _missing(context),
                    ),
                  ),
                );
              },
            ),
            filmstrip: ViewerFilmstrip(
              items: [
                for (final item in candidates)
                  ViewerFilmstripItem(
                    thumbnail: item.generation.filePath != null
                        ? FileImage(File(item.generation.filePath!))
                        : null,
                    aspectRatio:
                        run.paramsSnapshot.width / run.paramsSnapshot.height,
                    semanticLabel: '#${run.candidates.indexOf(item) + 1}',
                  ),
              ],
              currentIndex: index,
              onTap: (i) => _jump(candidates, i),
            ),
            panel: Theme(
              data: GeistTheme.dark,
              child: DefaultTextStyle(
                style: GeistTheme.dark.textTheme.bodyMedium!,
                child: ExploreInspector(
                  runId: run.id,
                  candidateId: current.id,
                  viewer: true,
                  onClose: _close,
                  onEvolution: () => _close(current.id),
                  onAssigned: (folder) => _advance(run, folder),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _missing(BuildContext context) => Center(
    child: Text(
      context.l10n.styleExplore_candidateMissing,
      style: const TextStyle(color: Colors.white54),
    ),
  );
}

class _ViewerPosition extends StatelessWidget {
  const _ViewerPosition({
    required this.sequence,
    required this.position,
    required this.round,
    this.time,
  });
  final int sequence;
  final String position, round;
  final DateTime? time;
  @override
  Widget build(BuildContext context) {
    final date = time;
    final clock = date == null
        ? ''
        : ' · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Row(
      children: [
        Text(
          '#$sequence',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            '$position · $round$clock',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: .55),
            ),
          ),
        ),
      ],
    );
  }
}

void _showViewerHelp(BuildContext context) {
  final l = context.l10n;
  showDialog<void>(
    context: context,
    builder: (context) => ExploreDialogFrame(
      title: l.shortcut_help_title,
      icon: 'info',
      width: 480,
      footer: Align(
        alignment: Alignment.centerRight,
        child: ExploreButton(
          label: l.common_close,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (keys, label) in [
            (
              '← →',
              '${l.styleExplore_prevCandidate} / ${l.styleExplore_nextCandidate}',
            ),
            ('F', l.styleExplore_filterHearted),
            ('E', l.styleExplore_startEvolution),
            ('1–9 / 0', l.styleExplore_viewerGroupsShortcut),
            ('I', l.styleExplore_inspectorTitle),
            ('Delete', l.common_delete),
            ('Esc', l.common_close),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(width: 80, child: ExploreKeyCap(keys)),
                  Expanded(
                    child: Text(label, style: const TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
