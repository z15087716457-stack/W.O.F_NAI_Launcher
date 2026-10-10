part of 'explore_inspector.dart';

class _ExploreInspectorState extends _ExploreInspectorController {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    final run = widget.runId == null
        ? ref.watch(exploreActiveRunProvider)
        : ref
              .watch(exploreRunListNotifierProvider)
              .valueOrNull
              ?.runById(widget.runId!);
    final candidate = run?.candidateById(
      widget.candidateId ?? ref.watch(exploreFocusedCandidateIdProvider) ?? '',
    );
    final evolutionary =
        !widget.viewer &&
        candidate != null &&
        exploreHasLineage(candidate) &&
        ref.watch(exploreStageTabProvider) == ExploreStageTab.evolution;
    final ids = ref.watch(exploreSelectionProvider);
    final selected =
        !widget.viewer &&
            ref.watch(exploreSelectionModeProvider) &&
            ids.isNotEmpty &&
            !evolutionary
        ? [
            for (final item in run?.candidates ?? <ExploreCandidate>[])
              if (ids.contains(item.id)) item,
          ]
        : <ExploreCandidate>[];
    ref.listen(
      exploreFocusedCandidateIdProvider,
      (_, next) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      }),
    );
    return LayoutBuilder(
      builder: (context, space) => Container(
        decoration: BoxDecoration(
          color: ExploreStyle.panel(t),
          border: Border(left: BorderSide(color: c.outlineVariant)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.outlineVariant)),
              ),
              child: WindowPanelHeader(
                headerHeight: 51,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 8),
                  child: Row(
                    children: [
                      if (widget.viewer) ...[
                        const Spacer(),
                        ExploreIconButton(
                          'x',
                          size: 18,
                          tooltip: l.common_close,
                          onPressed:
                              widget.onClose ?? () => Navigator.pop(context),
                        ),
                      ] else if (selected.isNotEmpty)
                        Expanded(
                          child: ExploreText(
                            l.styleExplore_selectedCount(selected.length),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else if (run != null && candidate != null) ...[
                        ExploreText(
                          evolutionary
                              ? l.styleExplore_childLabel(
                                  run.candidates.indexOf(candidate) + 1,
                                )
                              : '#${run.candidates.indexOf(candidate) + 1}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: evolutionary
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    height: 20,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ExploreStyle.evolutionBg(t),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      widthFactor: 1,
                                      child: ExploreText(
                                        '${l.styleExplore_generationNumber(candidate.lineage.generation)} · ${switch (candidate.lineage.operation) {
                                          ExploreLineageOperation.mutation => l.styleExplore_opMutation,
                                          ExploreLineageOperation.crossover => l.styleExplore_opCrossover,
                                          _ => l.styleExplore_opInjection,
                                        }}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: ExploreStyle.evolution(t),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : ExploreText(
                                  _roundStamp(run, candidate),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.onSurfaceVariant,
                                  ),
                                ),
                        ),
                      ] else
                        Expanded(
                          child: ExploreText(
                            l.styleExplore_inspectorTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: run == null || (candidate == null && selected.isEmpty)
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: ExploreText(
                          l.styleExplore_inspectorEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: ExploreStyle.faint(t),
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: selected.isNotEmpty
                          ? _multi(run, selected)
                          : widget.viewer
                          ? _viewer(run, candidate!)
                          : evolutionary
                          ? _evolutionSingle(run, candidate)
                          : _single(run, candidate!, space.maxWidth),
                    ),
            ),
            if (widget.viewer &&
                run != null &&
                candidate?.generation.filePath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ExploreButton(
                    key: const Key('explore-candidate-delete-image'),
                    label: l.styleExplore_deleteImage,
                    color: c.error,
                    background: Colors.transparent,
                    icon: ExploreIcon('trash', size: 14, color: c.error),
                    onPressed: () => _delete(run, candidate!),
                  ),
                ),
              ),
            if (!widget.viewer &&
                !evolutionary &&
                run != null &&
                candidate != null &&
                selected.isEmpty) ...[
              if (_expanded && candidate.rollSnapshot != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: space.maxHeight * .4),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExploreText(
                          l.prompt_positivePrompt,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          candidate.rollSnapshot!.positive,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        ExploreText(
                          l.prompt_negativePrompt,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          candidate.rollSnapshot!.negative,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.outlineVariant)),
                ),
                child: Row(
                  children: [
                    ExploreButton(
                      key: const Key('explore-inspector-full-prompt'),
                      label: l.styleExplore_fullPrompt,
                      ghost: true,
                      horizontal: 0,
                      fontSize: 12,
                      color: c.onSurfaceVariant,
                      icon: ExploreIcon(
                        _expanded ? 'chevU' : 'chevD',
                        size: 13,
                        color: c.onSurfaceVariant,
                      ),
                      onPressed: () => setState(() => _expanded = !_expanded),
                    ),
                    const Spacer(),
                    ExploreButton(
                      key: const Key('explore-inspector-delete'),
                      label: l.common_delete,
                      ghost: true,
                      horizontal: 0,
                      color: c.error,
                      fontSize: 12,
                      icon: ExploreIcon('trash', size: 14, color: c.error),
                      onPressed:
                          candidate.generation.status ==
                              ExploreCandidateGenerationStatus.pending
                          ? null
                          : () => _delete(run, candidate),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _evolutionSingle(ExploreRun run, ExploreCandidate candidate) {
    final l = context.l10n;
    Widget action(
      String icon,
      String label,
      VoidCallback onPressed,
      String key,
    ) => Expanded(
      child: ExploreButton(
        key: Key(key),
        label: label,
        expand: true,
        height: 34,
        icon: ExploreIcon(icon, size: 14),
        onPressed: onPressed,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 340,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ExploreCandidateImage(
              candidate: candidate,
              sequenceNumber: run.candidates.indexOf(candidate) + 1,
              generating:
                  ref.watch(exploreGeneratingCandidateIdProvider) ==
                  candidate.id,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ExploreLineageInfo(run: run, candidate: candidate),
        const SizedBox(height: 14),
        Row(
          children: [
            action(
              'heart',
              candidate.review.heart
                  ? l.styleExplore_hearted
                  : l.styleExplore_filterHearted,
              () => ref
                  .read(exploreRunListNotifierProvider.notifier)
                  .updateReview(
                    run.id,
                    candidate.id,
                    heart: !candidate.review.heart,
                  ),
              'explore-inspector-heart',
            ),
            const SizedBox(width: 6),
            action(
              'box',
              l.styleExplore_saveBlock,
              () => ExploreCandidateActions.adoptSingle(
                context,
                ref,
                run: run,
                candidate: candidate,
              ),
              'explore-inspector-save',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            action(
              'enter',
              l.styleExplore_applyToEditor,
              () => ExploreCandidateActions.fixateAsTemplate(
                context,
                ref,
                candidate: candidate,
              ),
              'explore-inspector-apply',
            ),
            const SizedBox(width: 6),
            action(
              'max',
              l.styleExplore_viewLarge,
              () => openExploreCandidate(context, ref, run, candidate),
              'explore-inspector-view',
            ),
          ],
        ),
      ],
    );
  }

  Widget _single(ExploreRun run, ExploreCandidate candidate, double width) {
    final visible = ref.watch(exploreVisibleCandidatesProvider),
        index = visible.indexWhere((item) => item.id == candidate.id);
    final done =
        candidate.generation.status == ExploreCandidateGenerationStatus.done;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: (372 * ((width - 28) / 284)).clamp(372.0, 480.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ExploreCandidateImage(
                  candidate: candidate,
                  sequenceNumber: run.candidates.indexOf(candidate) + 1,
                  generating:
                      ref.watch(exploreGeneratingCandidateIdProvider) ==
                      candidate.id,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _imageButton(
                    'max',
                    context.l10n.styleExplore_candidateDetailTitle,
                    () => openExploreCandidate(context, ref, run, candidate),
                  ),
                ),
                if (index > 0)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _imageButton(
                      'chevL',
                      context.l10n.styleExplore_prevCandidate,
                      () =>
                          ref
                              .read(exploreFocusedCandidateIdProvider.notifier)
                              .state = visible[index - 1]
                              .id,
                    ),
                  ),
                if (index >= 0 && index < visible.length - 1)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _imageButton(
                      'chevR',
                      context.l10n.styleExplore_nextCandidate,
                      () =>
                          ref
                              .read(exploreFocusedCandidateIdProvider.notifier)
                              .state = visible[index + 1]
                              .id,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (exploreHasLineage(candidate)) ...[
          ExploreLineageInfo(run: run, candidate: candidate),
          const SizedBox(height: 14),
        ],
        _draws(candidate),
        if (done) ...[
          const SizedBox(height: 14),
          _actions(run, candidate),
          const SizedBox(height: 14),
          ExploreFolderAssignBar(run: run, candidate: candidate),
          const SizedBox(height: 14),
          _params(run, candidate),
        ],
      ],
    );
  }

  Widget _heading(String label, {Widget? trailing}) => Row(
    children: [
      Expanded(
        child: ExploreText(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: .23,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 6), trailing],
    ],
  );

  Widget _draws(ExploreCandidate candidate) {
    final c = Theme.of(context).colorScheme, l = context.l10n;
    final done =
        candidate.generation.status == ExploreCandidateGenerationStatus.done;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          l.styleExplore_drawsTitle,
          trailing: GestureDetector(
            key: const Key('explore-inspector-copy-artists'),
            onTap: () => _copy(exploreInspectorArtists(candidate)),
            child: Tooltip(
              message: l.styleExplore_copyArtists,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExploreIcon('copy', size: 12, color: c.primary),
                  const SizedBox(width: 4),
                  ExploreText(
                    l.styleExplore_copyArtists,
                    style: TextStyle(fontSize: 11, color: c.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        if (!done)
          ExploreText(
            candidate.generation.status ==
                    ExploreCandidateGenerationStatus.failed
                ? candidate.generation.error ?? l.styleExplore_generationFailed
                : l.styleExplore_drawsAfterGeneration,
            style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
          )
        else if (candidate.rollSnapshot?.instanceRolls.isNotEmpty == true)
          for (final roll in candidate.rollSnapshot!.instanceRolls)
            Padding(
              padding: EdgeInsets.only(
                bottom: roll == candidate.rollSnapshot!.instanceRolls.last
                    ? 0
                    : 7,
              ),
              child: _roll(roll),
            )
        else
          _atoms(exploreRawArtistAtoms(candidate)),
      ],
    );
  }

  Widget _roll(ExploreInstanceRoll roll) {
    final t = Theme.of(context), c = t.colorScheme;
    final block = ref
        .watch(promptBlockLibraryNotifierProvider)
        .valueOrNull
        ?.blockById(roll.blockId);
    final color = block == null
        ? ExploreStyle.faint(t)
        : promptBlockColorFromString(block.color);
    return Container(
      key: ValueKey('explore-inspector-roll-${roll.lane}-${roll.marker}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: ExploreStyle.raised(t),
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: PromptPill(
                  title: roll.blockTitle,
                  color: color,
                  appearance: block?.appearance ?? 'classic',
                  leading: ExploreIcon(
                    'dice',
                    size: 12,
                    color: color,
                    strokeWidth: 2,
                  ),
                ),
              ),
              if (roll.lane == 'neg') ...[
                const SizedBox(width: 6),
                ExploreText(
                  context.l10n.styleExplore_variableNegative,
                  style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (roll.rolledText.trim().isEmpty)
            ExploreText(
              context.l10n.styleExplore_emptyDraw,
              style: TextStyle(fontSize: 12, color: ExploreStyle.faint(t)),
            )
          else
            _atoms(PillRollEngine.splitTopLevelAtoms(roll.rolledText)),
        ],
      ),
    );
  }

  Widget _atoms(List<String> atoms) => Wrap(
    spacing: 5,
    runSpacing: 5,
    children: [
      for (final atom in atoms)
        ExploreArtistChip(atom: parseExploreArtistAtom(atom)),
    ],
  );

  Widget _actions(ExploreRun run, ExploreCandidate candidate) {
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    Widget action(
      String icon,
      String label,
      VoidCallback onPressed, {
      String? key,
      String? hotkey,
      bool heart = false,
      bool evo = false,
    }) {
      final color = heart
          ? ExploreStyle.heart(t)
          : evo
          ? ExploreStyle.evolution(t)
          : c.onSurface;
      return Expanded(
        child: ExploreButton(
          key: key == null ? null : Key(key),
          label: label,
          height: 34,
          horizontal: 10,
          expand: true,
          color: color,
          border: heart ? color.withValues(alpha: .4) : c.outlineVariant,
          background: heart
              ? Color.alphaBlend(
                  color.withValues(alpha: .06),
                  ExploreStyle.raised(t),
                )
              : ExploreStyle.raised(t),
          icon: ExploreIcon(icon, size: 14, filled: heart, color: color),
          trailing: hotkey == null ? null : ExploreKeyCap(hotkey),
          onPressed: onPressed,
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            action(
              'heart',
              candidate.review.heart
                  ? l.styleExplore_hearted
                  : l.styleExplore_filterHearted,
              () => ref
                  .read(exploreRunListNotifierProvider.notifier)
                  .updateReview(
                    run.id,
                    candidate.id,
                    heart: !candidate.review.heart,
                  ),
              key: widget.viewer
                  ? 'explore-candidate-heart'
                  : 'explore-inspector-heart',
              hotkey: 'F',
              heart: candidate.review.heart,
            ),
            const SizedBox(width: 6),
            action(
              'evo',
              l.styleExplore_joinEvolution,
              widget.onEvolution ??
                  () => startExploreEvolution(context, ref, run, [candidate]),
              hotkey: 'E',
              evo: true,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            action(
              'box',
              l.styleExplore_saveBlock,
              () => ExploreCandidateActions.adoptSingle(
                context,
                ref,
                run: run,
                candidate: candidate,
              ),
              key: widget.viewer
                  ? 'explore-candidate-adopt-block'
                  : 'explore-inspector-save',
            ),
            const SizedBox(width: 6),
            action(
              'enter',
              l.styleExplore_applyToEditor,
              () => ExploreCandidateActions.fixateAsTemplate(
                context,
                ref,
                candidate: candidate,
              ),
              key: widget.viewer
                  ? 'explore-candidate-fixate'
                  : 'explore-inspector-apply',
            ),
          ],
        ),
      ],
    );
  }

  Widget _params(ExploreRun run, ExploreCandidate candidate) {
    final p = run.paramsSnapshot,
        g = candidate.generation,
        c = Theme.of(context).colorScheme,
        l = context.l10n;
    final values = [
      (
        widget.viewer ? l.styleExplore_seedClickCopy : l.styleExplore_seedName,
        g.seed?.toString() ?? '—',
        true,
      ),
      (
        l.styleExplore_elapsedName,
        g.elapsedMs == null
            ? '—'
            : '${(g.elapsedMs! / 1000).toStringAsFixed(1)} s',
        true,
      ),
      (
        l.styleExplore_parameters,
        '${l.styleExplore_parameterSummary(p.width, p.height, p.steps, p.scale.toStringAsFixed(1))}${widget.viewer ? ' · ${p.sampler}' : ''}',
        true,
      ),
      if (widget.viewer)
        (
          l.styleExplore_modelName,
          ImageModels.modelDisplayNames[p.model] ?? p.model,
          false,
        ),
    ];
    final ordered = widget.viewer
        ? [values[3], values[2], values[0], values[1]]
        : values;
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        for (var i = 0; i < ordered.length; i++)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 3),
                child: ExploreText(
                  ordered[i].$1,
                  style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: GestureDetector(
                  onTap:
                      ordered[i].$1 ==
                              (widget.viewer
                                  ? l.styleExplore_seedClickCopy
                                  : l.styleExplore_seedName) &&
                          g.seed != null
                      ? () => _copy('${g.seed}')
                      : null,
                  child: ExploreText(
                    ordered[i].$2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ordered[i].$3
                        ? StudioTypography.data.copyWith(fontSize: 12)
                        : const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _viewer(ExploreRun run, ExploreCandidate candidate) {
    final c = Theme.of(context).colorScheme, l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (candidate.generation.status ==
            ExploreCandidateGenerationStatus.done) ...[
          _actions(run, candidate),
          const SizedBox(height: 14),
        ],
        if (exploreHasLineage(candidate)) ...[
          ExploreLineageInfo(run: run, candidate: candidate),
          const SizedBox(height: 14),
        ],
        _draws(candidate),
        const SizedBox(height: 14),
        _heading(
          l.styleExplore_fullPrompt,
          trailing: GestureDetector(
            key: const Key('explore-candidate-copy-snapshot'),
            onTap: () => _copySnapshot(candidate.rollSnapshot),
            child: ExploreIcon('copy', size: 12, color: c.primary),
          ),
        ),
        const SizedBox(height: 7),
        if (candidate.rollSnapshot != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ClipRect(
              child: ExploreHighlightedPrompt(
                snapshot: candidate.rollSnapshot!,
              ),
            ),
          ),
        const SizedBox(height: 14),
        GestureDetector(
          key: const Key('explore-viewer-negative'),
          onTap: () => setState(() => _negativeExpanded = !_negativeExpanded),
          child: _heading(
            l.prompt_negativePrompt,
            trailing: ExploreIcon(
              _negativeExpanded ? 'chevU' : 'chevD',
              size: 12,
              color: c.onSurfaceVariant,
            ),
          ),
        ),
        if (_negativeExpanded) ...[
          const SizedBox(height: 7),
          SelectableText(
            candidate.rollSnapshot?.negative ?? '',
            style: const TextStyle(fontSize: 12),
          ),
        ],
        const SizedBox(height: 14),
        ExploreFolderAssignBar(
          run: run,
          candidate: candidate,
          onAssigned: widget.onAssigned,
        ),
        const SizedBox(height: 14),
        _params(run, candidate),
      ],
    );
  }

  Widget _multi(ExploreRun run, List<ExploreCandidate> selected) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: selected.length.clamp(0, 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio:
              run.paramsSnapshot.width / run.paramsSnapshot.height,
        ),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExploreCandidateImage(
                candidate: selected[i],
                sequenceNumber: run.candidates.indexOf(selected[i]) + 1,
              ),
              if (i == 7 && selected.length > 8)
                ColoredBox(
                  color: const Color(0x80000000),
                  child: Center(
                    child: ExploreText(
                      '+${selected.length - 8}',
                      style: StudioTypography.data.copyWith(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      _heading(context.l10n.styleExplore_mergedArtists),
      const SizedBox(height: 7),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: ExploreStyle.raised(Theme.of(context)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: _atoms(exploreMergedArtistAtoms(selected)),
      ),
      const SizedBox(height: 7),
      ExploreText(
        context.l10n.styleExplore_selectionExplanation,
        style: TextStyle(
          fontSize: 11.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _imageButton(String icon, String tooltip, VoidCallback onPressed) =>
      ExploreIconButton(
        icon,
        key: Key('explore-inspector-image-$icon'),
        tooltip: tooltip,
        color: Colors.white,
        background: const Color(0x73000000),
        onPressed: onPressed,
      );
}

class ExploreArtistChip extends StatelessWidget {
  const ExploreArtistChip({super.key, required this.atom});
  final ExploreArtistAtom atom;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (atom.weight != null) ...[
            ExploreText(
              atom.weight!,
              style: StudioTypography.data.copyWith(
                fontSize: 11,
                color: c.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: ExploreText(
              atom.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
