part of 'explore_candidate_wall.dart';

class _ExploreCandidateWallState extends _ExploreWallController {
  @override
  Widget build(BuildContext context) {
    final run = ref.watch(exploreActiveRunProvider);
    if (run == null) {
      return ExploreOnboarding(
        onGenerate: widget.onGenerate,
        onOpenPrevious: widget.onOpenPrevious,
      );
    }
    final filter = effectiveExploreGalleryFilter(
      run,
      ref.watch(exploreGalleryFilterProvider),
    );
    final tab = ref.watch(exploreStageTabProvider);
    ref.watch(exploreSelectionProvider);
    ref.watch(exploreSelectionModeProvider);
    ref.watch(exploreRunRunnerProvider);
    return Focus(
      focusNode: _stageFocus,
      onKeyEvent: (_, event) => _key(run, event),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _stageFocus.requestFocus,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tabs(run, filter, tab),
                Expanded(
                  child: tab == ExploreStageTab.evolution
                      ? ExploreEvolutionView(
                          run: run,
                          cardBuilder: (candidate, selectable) =>
                              _buildCandidateCard(
                                run,
                                candidate,
                                selectable: selectable,
                              ),
                          onGridLayout: (columns, extent) {
                            _columns = columns;
                            _cardExtent = extent;
                          },
                        )
                      : run.candidates.isEmpty
                      ? ExploreOnboarding(
                          onGenerate: widget.onGenerate,
                          onOpenPrevious: widget.onOpenPrevious,
                        )
                      : _deck(run),
                ),
              ],
            ),
            if (_selectionMode && _selectedIds.isNotEmpty)
              Positioned(
                left: 14,
                right: 14,
                bottom: 18,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ExploreSelectionBar(
                    count: _selectedIds.length,
                    allHearted: run.candidates
                        .where((c) => _selectedIds.contains(c.id))
                        .every((c) => c.review.heart),
                    groupKey: _groupButton,
                    onHeart: () => _toggleHearts(run, _selectedIds),
                    onGroup: () => _assignMenu(run),
                    onAdopt: () => _adoptSelected(run),
                    evolutionLabel: tab == ExploreStageTab.evolution
                        ? context.l10n.styleExplore_breedNext
                        : null,
                    onEvolve: tab == ExploreStageTab.evolution
                        ? _canBreed(run)
                              ? () => breedExploreNextGeneration(
                                  context,
                                  ref,
                                  run,
                                )
                              : null
                        : () => _createFamilyFromSelection(run),
                    onDelete: () => _deleteSelected(run),
                    onExit: _exitSelection,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tabs(
    ExploreRun run,
    ExploreGalleryFilter filter,
    ExploreStageTab selected,
  ) {
    final c = Theme.of(context).colorScheme, l = context.l10n;
    Widget tab(ExploreStageTab value, String label, int count, String icon) {
      final ink = selected == value ? c.onSurface : c.onSurfaceVariant;
      return GestureDetector(
        key: Key('explore-tab-${value.name}'),
        onTap: () => ref.read(exploreStageTabProvider.notifier).state = value,
        child: Container(
          height: 46,
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: selected == value
                ? Border(bottom: BorderSide(color: ink, width: 2))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon == 'img'
                  ? Icon(StudioIcons.galleryImage, size: 15, color: ink)
                  : ExploreIcon(icon, size: 15, color: ink),
              const SizedBox(width: 6),
              ExploreText(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              const SizedBox(width: 6),
              ExploreCount(count),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.outlineVariant)),
      ),
      child: Row(
        children: [
          tab(
            ExploreStageTab.candidates,
            l.styleExplore_candidatesTab,
            run.candidates.length,
            'img',
          ),
          tab(
            ExploreStageTab.evolution,
            l.styleExplore_evolutionTab,
            run.families.length,
            'evo',
          ),
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: c.outlineVariant,
          ),
          Expanded(
            child: selected == ExploreStageTab.candidates
                ? _toolbar(run, filter)
                : ExploreEvolutionFilters(run: run),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(ExploreRun run, ExploreGalleryFilter filter) {
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    final mode = ref.watch(exploreSelectionModeProvider),
        newest = ref.watch(exploreRoundOrderNewestFirstProvider);
    Widget chip(
      Key key,
      String label,
      ExploreGalleryFilter value, {
      String? icon,
      int? index,
    }) {
      final active = filter == value;
      final count = run.candidates
          .where((candidate) => exploreCandidateMatchesFilter(candidate, value))
          .length;
      Widget result = Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Material(
          color: active ? c.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _setFilter(value),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    ExploreIcon(
                      icon,
                      size: 12,
                      filled: icon == 'heart',
                      color: icon == 'heart'
                          ? ExploreStyle.heart(t)
                          : active
                          ? c.surface
                          : c.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                  ],
                  ExploreText(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? c.surface : c.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Opacity(
                    opacity: .75,
                    child: ExploreText(
                      '$count',
                      style: StudioTypography.data.copyWith(
                        fontSize: 11,
                        color: active ? c.surface : c.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (value is ExploreGalleryFilterFolder && value.folderId != null) {
        result = GestureDetector(
          onSecondaryTapUp: (details) => _showFolderMenu(
            run,
            run.folderById(value.folderId!)!,
            details.globalPosition,
          ),
          child: result,
        );
      }
      return index == null
          ? KeyedSubtree(key: key, child: result)
          : ReorderableDragStartListener(key: key, index: index, child: result);
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 28,
            child: HorizontalEdgeFade(
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                onReorderItem: (a, b) => _reorderFolderChips(run, a, b),
                children: [
                  chip(
                    const Key('explore-filter-all'),
                    l.styleExplore_filterAll,
                    const ExploreGalleryFilterAll(),
                  ),
                  chip(
                    const Key('explore-filter-hearted'),
                    l.styleExplore_filterHearted,
                    const ExploreGalleryFilterHearted(),
                    icon: 'heart',
                  ),
                  chip(
                    const Key('explore-filter-uncategorized'),
                    l.styleExplore_folderUncategorized,
                    const ExploreGalleryFilterFolder(null),
                    icon: 'inbox',
                  ),
                  for (final entry in run.folders.indexed)
                    chip(
                      ValueKey('explore-filter-folder-${entry.$2.id}'),
                      entry.$2.name,
                      ExploreGalleryFilterFolder(entry.$2.id),
                      icon: 'folder',
                      index: 3 + entry.$1,
                    ),
                  Padding(
                    key: const Key('explore-gallery-new-folder'),
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () =>
                          promptCreateExploreFolder(context, ref, run.id),
                      child: CustomPaint(
                        painter: DashedRoundedBorderPainter(
                          color: ExploreStyle.strong(t),
                          dashedColor: ExploreStyle.strong(t),
                          radius: const Radius.circular(14),
                          topRounded: true,
                          bottomRounded: true,
                          solidLeft: false,
                          solidRight: false,
                          dashedAll: true,
                        ),
                        child: SizedBox(
                          height: 28,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ExploreIcon(
                                  'plus',
                                  size: 13,
                                  color: ExploreStyle.faint(t),
                                ),
                                const SizedBox(width: 5),
                                ExploreText(
                                  l.styleExplore_groupLabel,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: ExploreStyle.faint(t),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        if (!mode)
          ExploreIconButton(
            'sort',
            key: const Key('explore-round-sort'),
            tooltip: newest
                ? l.styleExplore_newestFirst
                : l.styleExplore_oldestFirst,
            onPressed: () =>
                ref.read(exploreRoundOrderNewestFirstProvider.notifier).state =
                    !newest,
          ),
        const SizedBox(width: 6),
        ExploreButton(
          key: const Key('explore-gallery-select-toggle'),
          label: mode ? l.common_selectAll : l.styleExplore_selectCandidates,
          icon: ExploreIcon('sel', size: 14, color: c.onSurface),
          onPressed: mode
              ? _selectAll
              : () => ref.read(exploreSelectionModeProvider.notifier).state =
                    true,
        ),
      ],
    );
  }

  Widget _deck(ExploreRun run) {
    final filter = effectiveExploreGalleryFilter(
      run,
      ref.watch(exploreGalleryFilterProvider),
    );
    final newest = ref.watch(exploreRoundOrderNewestFirstProvider);
    final large = ref.watch(
      layoutStateNotifierProvider.select((s) => s.styleExploreGridLarge),
    );
    final rounds = [
      for (final r in exploreOrderedRounds(run, newest))
        if (exploreRoundCandidates(run, r, filter).isNotEmpty ||
            (filter is ExploreGalleryFilterAll && r.candidateIds.isEmpty))
          r,
    ];
    if (rounds.isEmpty) {
      return Center(child: ExploreText(context.l10n.styleExplore_emptyFilter));
    }
    return LayoutBuilder(
      builder: (context, space) {
        final available = space.maxWidth - 28;
        // The original 1600-wide A view has four 198px cards. Its density is the
        // user's accepted reference, including when the nominal 200px floor disagrees.
        final columns = ((available + 12) / ((large ? 198 : 150) + 12))
            .floor()
            .clamp(2, 100);
        final width = (available - 12 * (columns - 1)) / columns;
        final ratio = run.paramsSnapshot.width / run.paramsSnapshot.height;
        _columns = columns;
        _cardExtent = width / ratio + 6 + 11.5 * 1.45 * 2 + 14;
        return CustomScrollView(
          key: ValueKey('explore-wall-${run.id}'),
          controller: _scroll,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              sliver: SliverMainAxisGroup(
                slivers: [
                  for (final round in rounds) ...[
                    SliverToBoxAdapter(child: _round(run, round)),
                    if (round.candidateIds.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: ExploreText(
                            context.l10n.styleExplore_emptyRound,
                          ),
                        ),
                      )
                    else
                      SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          mainAxisExtent: width / ratio + 6 + 11.5 * 1.45 * 2,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildCandidateCard(
                            run,
                            exploreRoundCandidates(run, round, filter)[index],
                          ),
                          childCount: exploreRoundCandidates(
                            run,
                            round,
                            filter,
                          ).length,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _round(ExploreRun run, ExploreRound round) {
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    final all = exploreRoundCandidates(
      run,
      round,
      const ExploreGalleryFilterAll(),
    );
    final failures = all
        .where(
          (candidate) =>
              candidate.generation.status ==
              ExploreCandidateGenerationStatus.failed,
        )
        .length;
    final runner = ref.watch(exploreRunRunnerProvider),
        manual = ref.watch(exploreManualCaptureProvider);
    final running =
        (runner.isRunning &&
            runner.runId == run.id &&
            round.status == ExploreRoundStatus.generating) ||
        (manual.armed &&
            manual.runId == run.id &&
            all.any(
              (candidate) =>
                  manual.candidateIds.contains(candidate.id) &&
                  candidate.generation.status ==
                      ExploreCandidateGenerationStatus.pending,
            ));
    final now = DateTime.now(), time = round.createdAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${time.year == now.year && time.month == now.month && time.day == now.day ? '${l.styleExplore_today} ' : '${two(time.month)}-${two(time.day)} '}${two(time.hour)}:${two(time.minute)}';
    final deep = round.phase == ExploreRoundPhase.deep;
    final title = deep
        ? l.styleExplore_deepRoundTitle(
            run.familyById(round.familyId ?? '')?.name ??
                l.styleExplore_evolutionTab,
            round.generation ?? 1,
          )
        : l.styleExplore_roundNumber(round.number);
    return Padding(
      key: Key('explore-round-${round.id}'),
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
      child: Row(
        children: [
          if (deep) ...[
            ExploreIcon('evo', size: 14, color: ExploreStyle.evolution(t)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => Row(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: box.maxWidth * .85),
                    child: ExploreText.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c.onSurface,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 10)),
                          TextSpan(
                            text:
                                '$stamp · ${l.styleExplore_wallRoundCount(all.length)}${running
                                    ? ' · ${l.styleExplore_wallGenerating}'
                                    : failures > 0
                                    ? ' · ${l.styleExplore_roundFailures(failures)}'
                                    : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Divider(height: 1, color: c.outlineVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (failures > 0 && !runner.isRunning && !manual.armed)
            ExploreButton(
              label: l.styleExplore_retryFailed(failures),
              height: 26,
              ghost: true,
              color: c.error,
              icon: ExploreIcon('swap', size: 12, color: c.error),
              onPressed: () => ExploreRunActions.retryFailed(context, ref, run),
            ),
          if (failures == 0 && !running)
            ExploreButton(
              key: Key('explore-round-select-${round.id}'),
              label: l.styleExplore_pickEvolution,
              ghost: true,
              height: 26,
              color: c.onSurfaceVariant,
              horizontal: 8,
              icon: ExploreIcon(
                'evo',
                size: 13,
                color: ExploreStyle.evolution(t),
              ),
              onPressed: () => _enterSelection(null),
            ),
        ],
      ),
    );
  }
}
