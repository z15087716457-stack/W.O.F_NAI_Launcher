part of 'explore_evolution_view.dart';

class ExploreEvolutionFilters extends ConsumerWidget {
  const ExploreEvolutionFilters({super.key, required this.run});
  final ExploreRun run;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    final current = exploreSelectedFamily(
      run,
      ref.watch(exploreActiveFamilyIdProvider),
    );
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 28,
            child: HorizontalEdgeFade(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                children: [
                  for (final family in run.families)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onSecondaryTapUp: (d) => showExploreFamilyMenu(
                          context,
                          ref,
                          run,
                          family,
                          d.globalPosition,
                        ),
                        child: ExploreButton(
                          key: ValueKey('explore-family-chip-${family.id}'),
                          label: family.name,
                          height: 28,
                          radius: 14,
                          color: current?.id == family.id
                              ? ExploreStyle.evolutionForeground(t)
                              : c.onSurfaceVariant,
                          background: current?.id == family.id
                              ? ExploreStyle.evolution(t)
                              : Colors.transparent,
                          border: current?.id == family.id
                              ? Colors.transparent
                              : c.outlineVariant,
                          ghost: current?.id != family.id,
                          fontWeight: current?.id == family.id
                              ? FontWeight.w600
                              : FontWeight.w400,

                          trailing: Opacity(
                            opacity: .75,
                            child: ExploreText(
                              'G${run.parentSetById(family.activeParentSetId)?.generation ?? 1}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: current?.id == family.id
                                    ? ExploreStyle.evolutionForeground(t)
                                    : c.onSurfaceVariant,
                              ),
                            ),
                          ),
                          onPressed: () {
                            ref
                                .read(exploreActiveFamilyIdProvider.notifier)
                                .state = family
                                .id;
                            ref.read(exploreSelectionProvider.notifier).clear();
                            ref
                                    .read(
                                      exploreFocusedCandidateIdProvider
                                          .notifier,
                                    )
                                    .state =
                                null;
                          },
                        ),
                      ),
                    ),
                  ExploreButton(
                    key: const Key('explore-new-family'),
                    label: l.styleExplore_evolutionNewLine,
                    height: 28,
                    radius: 14,
                    color: c.onSurfaceVariant,
                    background: Colors.transparent,
                    icon: const ExploreIcon('plus', size: 13),
                    onPressed: () {
                      final selected = ref.read(exploreSelectionProvider);
                      if (selected.isNotEmpty) {
                        startExploreEvolution(context, ref, run, [
                          for (final candidate in run.candidates)
                            if (selected.contains(candidate.id)) candidate,
                        ]);
                      } else {
                        ref.read(exploreStageTabProvider.notifier).state =
                            ExploreStageTab.candidates;
                        ref.read(exploreSelectionModeProvider.notifier).state =
                            true;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ExploreButton(
          key: const Key('explore-evolution-help'),
          label: l.styleExplore_howToUse,
          icon: ExploreIcon('info', size: 14, color: c.onSurfaceVariant),
          height: 28,
          fontSize: 12,
          ghost: true,
          color: c.onSurfaceVariant,
          horizontal: 6,
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialog) => ExploreDialogFrame(
              width: 500,
              title: l.styleExplore_howToUse,
              icon: 'info',
              footer: Align(
                alignment: Alignment.centerRight,
                child: ExploreButton(
                  label: l.common_close,
                  height: 36,
                  onPressed: () => Navigator.pop(dialog),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final text in [
                    l.styleExplore_helpParents,
                    l.styleExplore_helpChildren,
                    l.styleExplore_helpCompare,
                    l.styleExplore_helpBackcross,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ExploreText(text),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExploreEvolutionViewState extends _ExploreEvolutionController {
  @override
  Widget build(BuildContext context) {
    final run = widget.run,
        family = exploreSelectedFamily(
          widget.run,
          ref.watch(exploreActiveFamilyIdProvider),
        );
    if (family == null) return _empty();
    return SingleChildScrollView(
      key: ValueKey('explore-evolution-${run.id}-${family.id}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final generation in exploreFamilyGenerations(
            run,
            family,
          ).reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  generation.parentSet.id == family.activeParentSetId ||
                      _expanded.contains(generation.parentSet.id)
                  ? _generation(run, family, generation)
                  : _history(run, family, generation),
            ),
        ],
      ),
    );
  }

  Widget _empty() {
    final t = Theme.of(context), l = context.l10n;
    final missing =
        resolveExploreOverrideMarkerInDocument(
          ref.watch(pillWorkspaceProvider(PillScopes.main)).document,
        ) ==
        null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExploreIcon('evo', size: 72, color: ExploreStyle.evolution(t)),
            const SizedBox(height: 20),
            ExploreText(
              l.styleExplore_evolutionEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ExploreButton(
              key: const Key('explore-evolution-pick'),
              label: l.styleExplore_pickFromCandidates,
              background: t.colorScheme.primary,
              border: t.colorScheme.primary,
              color: t.colorScheme.onPrimary,
              onPressed: () {
                ref.read(exploreStageTabProvider.notifier).state =
                    ExploreStageTab.candidates;
                ref.read(exploreSelectionModeProvider.notifier).state = true;
              },
            ),
            if (missing)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ExploreText(
                  l.styleExplore_variablesEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: t.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tag(int number, {bool old = false}) {
    final t = Theme.of(context);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),

      decoration: BoxDecoration(
        color: old
            ? t.colorScheme.surfaceContainerHighest
            : ExploreStyle.evolution(t),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        widthFactor: 1,
        child: ExploreText(
          context.l10n.styleExplore_generationNumber(number),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: old
                ? t.colorScheme.onSurfaceVariant
                : ExploreStyle.evolutionForeground(t),
          ),
        ),
      ),
    );
  }

  Widget _thumb(
    ExploreRun run,
    ExploreCandidate? candidate, {
    double width = 36,
    double height = 52,
    bool picked = false,
  }) {
    final t = Theme.of(context);
    final image = Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: picked
            ? Border.all(color: ExploreStyle.evolution(t), width: 2)
            : null,
      ),
      child: candidate == null
          ? Center(
              child: ExploreIcon(
                'edit',
                size: 15,
                color: t.colorScheme.onSurfaceVariant,
              ),
            )
          : ExploreCandidateImage(
              candidate: candidate,
              sequenceNumber: run.candidates.indexOf(candidate) + 1,
              generating: false,
              fit: BoxFit.cover,
            ),
    );
    return candidate == null
        ? image
        : ExploreCandidateHoverThumb(
            session: _hover,
            candidateId: candidate.id,
            filePath: candidate.generation.filePath,
            badgeText: '#${run.candidates.indexOf(candidate) + 1}',
            child: GestureDetector(
              onTap: () => openExploreCandidate(context, ref, run, candidate),
              child: image,
            ),
          );
  }

  Widget _history(
    ExploreRun run,
    ExploreFamily family,
    ExploreLineageGeneration generation,
  ) {
    final c = Theme.of(context).colorScheme, l = context.l10n;
    final next = run.parentSets
        .where(
          (s) =>
              s.familyId == family.id &&
              s.generation == generation.parentSet.generation + 1,
        )
        .firstOrNull;
    final selected =
        next?.parents.map((p) => p.sourceCandidateId).toSet() ?? <String?>{};
    return Container(
      key: ValueKey('explore-generation-collapsed-${generation.parentSet.id}'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            _tag(generation.parentSet.generation, old: true),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.max(
                  0,
                  constraints.maxWidth -
                      (generation.parentSet.generation > 1 ? 358 : 158),
                ),
              ),
              child: ExploreText(
                generation.parentSet.generation == 1
                    ? l.styleExplore_generationStart(
                        generation.parentSet.parents.length,
                      )
                    : l.styleExplore_generationSummary(
                        generation.parentSet.parents.length,
                        generation.pile.length,
                        generation.pile
                            .where(
                              (candidate) => selected.contains(candidate.id),
                            )
                            .length,
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
              ),
            ),
            if (generation.parentSet.generation > 1)
              SizedBox(
                width: 218,
                child: Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final candidate in generation.pile.take(8))
                          Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: _thumb(
                              run,
                              candidate,
                              width: 22,
                              height: 32,
                              picked: selected.contains(candidate.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const Spacer(),
            const SizedBox(width: 10),
            ExploreButton(
              key: ValueKey(
                'explore-generation-expand-${generation.parentSet.id}',
              ),
              label: l.common_expand,
              trailing: const ExploreIcon('chevD', size: 13),
              ghost: true,
              color: c.onSurfaceVariant,
              onPressed: () =>
                  setState(() => _expanded.add(generation.parentSet.id)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _generation(
    ExploreRun run,
    ExploreFamily family,
    ExploreLineageGeneration generation,
  ) {
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    final set = generation.parentSet,
        active = set.id == family.activeParentSetId,
        root = run.parentSetById(family.rootParentSetId);
    final roots = {
      if (set.generation > 1)
        for (final parent in root?.parents ?? <ExploreParent>[])
          parent.artistString,
    };
    final explanation = set.generation == 1
        ? l.styleExplore_generationStart(set.parents.length)
        : l.styleExplore_generationSource(
            set.generation - 1,
            set.parents.where((p) => !roots.contains(p.artistString)).length,
            set.parents.where((p) => roots.contains(p.artistString)).length,
          );
    final runner = ref.watch(exploreRunRunnerProvider);
    final busy =
        !exploreParentSetRoundsComplete(run, set) ||
        (runner.isRunning && runner.runId == run.id);
    final selected = ref
        .watch(exploreSelectionProvider)
        .intersection(generation.pile.map((c) => c.id).toSet());
    return Container(
      key: ValueKey('explore-generation-${set.id}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(bottom: BorderSide(color: c.outlineVariant)),
            ),
            child: Row(
              children: [
                _tag(set.generation, old: !active),
                const SizedBox(width: 10),
                if (active) ...[
                  ExploreText(
                    l.styleExplore_currentGeneration,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Tooltip(
                    message: explanation,
                    child: ExploreText(
                      '${l.styleExplore_generationCounts(set.parents.length, generation.pile.length)} · $explanation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (active) ...[
                  ExploreButton(
                    key: ValueKey('explore-sort-parents-${set.id}'),
                    label: l.styleExplore_pairCompare,
                    fontSize: 12,
                    icon: const ExploreIcon('sort', size: 14),
                    onPressed: set.parents.length < 2
                        ? null
                        : () => ExplorePreferenceSortDialog.show(
                            context,
                            runId: run.id,
                            parentSet: set,
                          ),
                  ),
                  const SizedBox(width: 10),
                  _DeepRoundControl(
                    key: ValueKey('explore-deep-round-control-${set.id}'),
                    run: run,
                    family: family,
                    parentSet: set,
                  ),
                ] else
                  ExploreIconButton(
                    'chevU',
                    key: ValueKey('explore-generation-collapse-${set.id}'),
                    size: 14,
                    onPressed: () => setState(() => _expanded.remove(set.id)),
                  ),
              ],
            ),
          ),
          Stack(
            children: [
              Positioned(
                left: 269,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: c.outlineVariant),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 270,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExploreText(
                          l.styleExplore_parentsByPreference,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ExploreParentList(
                          parents: set.parents,
                          backcrossStrings: roots,
                          thumbBuilder: (parent) => _thumb(
                            run,
                            run.candidateById(parent.sourceCandidateId ?? ''),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              ExploreText(
                                l.styleExplore_childrenCount(
                                  generation.pile.length,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (active) ...[
                                ExploreText(
                                  l.styleExplore_selectedCount(selected.length),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: ExploreButton(
                                    key: ValueKey('explore-breed-${set.id}'),
                                    height: 28,
                                    fontSize: 12,
                                    label: l.styleExplore_breedSelected(
                                      selected.length,
                                      set.generation + 1,
                                    ),
                                    icon: ExploreIcon(
                                      'evo',
                                      size: 14,
                                      color: ExploreStyle.evolutionForeground(
                                        t,
                                      ),
                                    ),
                                    color: ExploreStyle.evolutionForeground(t),
                                    background: ExploreStyle.evolution(t),
                                    border: ExploreStyle.evolution(t),
                                    onPressed:
                                        selected.isEmpty || busy || _submitting
                                        ? null
                                        : () => _breed(run, selected),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (active && busy)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: ExploreText(
                                l.styleExplore_generationBusy,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: c.onSurfaceVariant,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (generation.pile.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: ExploreText(
                                l.styleExplore_childrenEmpty,
                                style: TextStyle(color: c.onSurfaceVariant),
                              ),
                            )
                          else
                            LayoutBuilder(
                              builder: (context, box) {
                                final columns = (box.maxWidth / 78)
                                    .floor()
                                    .clamp(1, 6);
                                final width =
                                    (box.maxWidth - 8 * (columns - 1)) /
                                    columns;
                                final extent =
                                    width /
                                        (run.paramsSnapshot.width /
                                            run.paramsSnapshot.height) +
                                    6 +
                                    11.5 * 1.45;
                                if (active) {
                                  widget.onGridLayout?.call(
                                    columns,
                                    extent + 10,
                                  );
                                }
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: generation.pile.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 10,
                                        mainAxisExtent: extent,
                                      ),
                                  itemBuilder: (_, i) => widget.cardBuilder(
                                    generation.pile[i],
                                    active,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _breed(ExploreRun run, Set<String> selected) async {
    setState(() => _submitting = true);
    try {
      await breedExploreNextGeneration(context, ref, run, ids: selected);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _DeepRoundControlState extends _ExploreDeepRoundController {
  @override
  Widget build(BuildContext context) {
    final runner = ref.watch(exploreRunRunnerProvider),
        busy = runner.isRunning && runner.runId == widget.run.id;
    final t = Theme.of(context),
        l = context.l10n,
        fg = ExploreStyle.evolutionForeground(t);
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: busy
            ? t.colorScheme.surfaceContainerHighest
            : ExploreStyle.evolution(t),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            key: ValueKey('explore-deep-round-${widget.parentSet.id}'),
            onTap: busy ? null : _generate,
            child: Padding(
              padding: const EdgeInsets.only(left: 11, right: 3),
              child: Row(
                children: [
                  ExploreIcon('play', size: 12, color: fg),
                  const SizedBox(width: 5),
                  ExploreText(
                    l.styleExplore_regeneratePrefix,
                    style: TextStyle(fontSize: 12, color: fg),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 18,
            child: TextField(
              key: ValueKey('explore-deep-round-count-${widget.parentSet.id}'),
              controller: _count,
              enabled: !busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: StudioTypography.data.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _generate(),
            ),
          ),
          GestureDetector(
            onTap: busy ? null : _generate,
            child: Padding(
              padding: const EdgeInsets.only(left: 3, right: 11),
              child: ExploreText(
                l.styleExplore_regenerateSuffix,
                style: TextStyle(fontSize: 12, color: fg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
