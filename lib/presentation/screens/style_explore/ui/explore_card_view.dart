part of 'explore_candidate_card.dart';

class _ExploreCandidateCardState extends _ExploreCardController {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    final candidate = widget.candidate, hover = _hover || widget.forceHover;
    final done =
        candidate.generation.status == ExploreCandidateGenerationStatus.done;
    final adopted = widget.run.parentSets.any(
      (set) =>
          set.parents.any((parent) => parent.sourceCandidateId == candidate.id),
    );
    final folder = widget.run.folderById(candidate.folderId ?? '');
    final operation = candidate.lineage.operation;
    final atoms = exploreCandidateArtistAtoms(candidate);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: widget.focused || widget.selected
                    ? [
                        BoxShadow(color: c.primary, spreadRadius: 4),
                        BoxShadow(color: c.surface, spreadRadius: 2),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.selectionMode
                      ? widget.onToggleSelect
                      : widget.onFocus,
                  onDoubleTap: widget.onOpenDetail,
                  onLongPress: widget.onEnterSelection,
                  onSecondaryTapUp: (details) => _more(details.globalPosition),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ExploreCandidateImage(
                        candidate: candidate,
                        sequenceNumber: widget.sequenceNumber,
                        generating: widget.generating,
                      ),
                      if (widget.selected)
                        ColoredBox(color: c.primary.withValues(alpha: .14)),
                      if (done && candidate.review.heart)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _heartCircle(
                            Colors.white,
                            ExploreStyle.heart(t),
                            true,
                          ),
                        ),
                      if (done && (hover || widget.selectionMode))
                        Positioned(
                          left: 6,
                          top: 6,
                          child: GestureDetector(
                            key: Key(
                              'explore-candidate-select-${candidate.id}',
                            ),
                            onTap: widget.selectionMode
                                ? widget.onToggleSelect
                                : widget.onEnterSelection,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.selected
                                    ? c.primary
                                    : Colors.black.withValues(alpha: .25),
                                border: Border.all(
                                  color: widget.selected
                                      ? c.primary
                                      : Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x4d000000),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: widget.selected
                                  ? const Center(
                                      child: ExploreIcon(
                                        'check',
                                        size: 12,
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      if (done &&
                          !hover &&
                          (adopted ||
                              operation == ExploreLineageOperation.mutation ||
                              operation == ExploreLineageOperation.crossover ||
                              operation == ExploreLineageOperation.injection))
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: _badge(
                            adopted
                                ? l.styleExplore_parentBadge
                                : switch (operation) {
                                    ExploreLineageOperation.mutation =>
                                      l.styleExplore_opMutation,
                                    ExploreLineageOperation.crossover =>
                                      l.styleExplore_opCrossover,
                                    _ => l.styleExplore_opInjection,
                                  },
                            background: adopted
                                ? const Color(0x99000000)
                                : switch (operation) {
                                    ExploreLineageOperation.mutation =>
                                      const Color(0xffc2410c),
                                    ExploreLineageOperation.injection =>
                                      const Color(0xff0e7490),
                                    _ => const Color(0xff6e56cf),
                                  },
                            color: Colors.white,
                            icon: adopted ? 'evo' : null,
                            height: 19,
                            fontSize: 10.5,
                          ),
                        ),
                      if (done && folder != null && !hover && !widget.compact)
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: _badge(
                            folder.name,
                            background: const Color(0xe0ffffff),
                            color: const Color(0xff222222),
                            icon: 'folder',
                          ),
                        ),
                      if (done && hover)
                        Positioned(
                          left: 6,
                          right: 6,
                          bottom: 6,
                          child: LibraryHoverActionBar(
                            key: Key('explore-hover-actions-${candidate.id}'),
                            backgroundColor: const Color(0xb8000000),
                            children: [
                              _action(
                                'heart',
                                l.styleExplore_filterHearted,
                                _heart,
                              ),
                              _action(
                                'evo',
                                l.styleExplore_startEvolution,
                                () => startExploreEvolution(
                                  context,
                                  ref,
                                  widget.run,
                                  [candidate],
                                ),
                              ),
                              _action(
                                'box',
                                l.styleExplore_saveBlock,
                                () => ExploreCandidateActions.adoptSingle(
                                  context,
                                  ref,
                                  run: widget.run,
                                  candidate: candidate,
                                ),
                              ),
                              _action(
                                'max',
                                l.styleExplore_candidateDetailTitle,
                                widget.onOpenDetail,
                              ),
                              _action('more', l.library_more, () {
                                final box =
                                    context.findRenderObject()! as RenderBox;
                                _more(
                                  box.localToGlobal(
                                    Offset(box.size.width, box.size.height / 2),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
            child: SizedBox(
              height: 11.5 * 1.45 * (widget.compact ? 1 : 2),
              child: Tooltip(
                message: exploreParentStringFor(candidate),
                child: ExploreText.rich(
                  TextSpan(
                    children: [
                      for (var i = 0; i < atoms.length; i++) ...[
                        if (i > 0)
                          TextSpan(
                            text: ' · ',
                            style: TextStyle(color: ExploreStyle.faint(t)),
                          ),
                        if (atoms[i].weight != null) ...[
                          TextSpan(
                            text: atoms[i].weight,
                            style: StudioTypography.data.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: ExploreStyle.faint(t),
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 4)),
                        ],
                        TextSpan(text: atoms[i].text),
                      ],
                    ],
                  ),
                  maxLines: widget.compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: c.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heartCircle(Color background, Color ink, bool filled) =>
      GestureDetector(
        key: Key('explore-candidate-heart-${widget.candidate.id}'),
        onTap: _heart,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Center(
            child: ExploreIcon('heart', size: 14, color: ink, filled: filled),
          ),
        ),
      );

  Widget _badge(
    String text, {
    required Color background,
    required Color color,
    String? icon,
    double height = 20,
    double fontSize = 11,
  }) => Container(
    height: height,
    constraints: const BoxConstraints(maxWidth: 140),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          ExploreIcon(icon, size: 11, color: color),
          const SizedBox(width: 3),
        ],
        Flexible(
          child: ExploreText(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _action(String name, String tooltip, VoidCallback action) => Expanded(
    child: Tooltip(
      key: name == 'heart' && !widget.candidate.review.heart
          ? Key('explore-candidate-heart-${widget.candidate.id}')
          : null,
      message: tooltip,
      child: Center(
        child: SizedBox(
          width: 30,
          height: 28,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: action,
              borderRadius: BorderRadius.circular(6),
              child: Center(
                child: ExploreIcon(name, size: 15, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
