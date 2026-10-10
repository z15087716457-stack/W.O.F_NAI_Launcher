part of 'explore_start_evolution_dialog.dart';

class _StartEvolutionState extends _StartEvolutionController {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    ref.watch(exploreActiveFamilyIdProvider);
    final run = _run, family = _family(run);
    if (family == null) _join = false;
    final minimum = _minimum(run, family);
    if (!_initialized) {
      _initialized = true;
      _name.text = l.styleExplore_defaultEvolutionName(run.families.length + 1);
    }
    if (!_countEdited) _count.text = '${minimum + 1}';
    final doc = ref.watch(pillWorkspaceProvider(PillScopes.main)).document;
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final marker = resolveExploreOverrideMarkerInDocument(doc);
    final block = marker == null
        ? null
        : library?.blockById(doc.instances[marker]!.blockId);
    final valid = block != null && _parents.isNotEmpty && !_submitting;
    final count = int.tryParse(_count.text) ?? minimum + 1;
    final purple = ExploreStyle.evolution(t), muted = c.onSurfaceVariant;
    return ExploreDialogFrame(
      key: const Key('explore-start-evolution-dialog'),
      width: 660,
      top: 110,
      title: l.styleExplore_startDialogTitle(widget.candidates.length),
      icon: 'evo',
      footer: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        spacing: 12,
        overflowSpacing: 10,
        overflowAlignment: OverflowBarAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExploreText(
                l.styleExplore_evolutionFirstBatch,
                style: TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(width: 8),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: ExploreStyle.raised(t),
                  border: Border.all(color: c.outlineVariant),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _countArrow(
                      'chevL',
                      () => _setCount((count - 1).clamp(minimum, 10000)),
                    ),
                    SizedBox(
                      width: 34,
                      child: TextField(
                        key: const Key('explore-evolution-count'),
                        controller: _count,
                        enabled: !_submitting,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: StudioTypography.data.copyWith(fontSize: 12.5),
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() => _countEdited = true),
                      ),
                    ),
                    _countArrow(
                      'chevR',
                      () => _setCount((count + 1).clamp(minimum, 10000)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ExploreText(
                l.styleExplore_evolutionMinimum(minimum),
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              ExploreButton(
                key: const Key('explore-evolution-only-create'),
                height: 36,
                fontSize: 13.5,
                horizontal: 14,
                label: _join
                    ? l.styleExplore_evolutionOnlyJoin
                    : l.styleExplore_evolutionOnlyCreate,
                onPressed: valid ? () => _submit(false) : null,
              ),
              ExploreButton(
                key: const Key('explore-evolution-create-generate'),
                height: 36,
                fontSize: 13.5,
                horizontal: 14,
                fontWeight: FontWeight.w600,
                icon: const ExploreIcon('play', size: 13),
                background: purple,
                border: purple,
                color: ExploreStyle.evolutionForeground(t),
                label: _join
                    ? l.styleExplore_evolutionJoinGenerate(
                        count.clamp(minimum, 10000),
                      )
                    : l.styleExplore_evolutionCreateGenerate(
                        count.clamp(minimum, 10000),
                      ),
                onPressed: valid ? () => _submit(true) : null,
              ),
            ],
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ExploreStyle.evolutionBg(t),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: purple,
                              shape: BoxShape.circle,
                            ),
                            child: ExploreText(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ExploreStyle.evolutionForeground(t),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ExploreText(
                                  [
                                    l.styleExplore_stepGenerate,
                                    l.styleExplore_stepPick,
                                    l.styleExplore_stepBreed,
                                  ][i],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                ExploreText(
                                  [
                                    l.styleExplore_evolutionStepOne,
                                    l.styleExplore_evolutionStepTwo,
                                    l.styleExplore_evolutionStepThree,
                                  ][i],
                                  style: TextStyle(fontSize: 12, color: muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (family != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: c.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final join in [false, true])
                      ExploreButton(
                        key: Key(
                          join
                              ? 'explore-evolution-mode-join'
                              : 'explore-evolution-mode-new',
                        ),
                        height: 28,
                        horizontal: 9,
                        radius: 5,
                        ghost: true,
                        fontWeight: join == _join
                            ? FontWeight.w600
                            : FontWeight.w400,
                        label: join
                            ? l.styleExplore_evolutionJoinLine(family.name)
                            : l.styleExplore_evolutionNewLine,
                        color: join == _join ? c.onSurface : muted,
                        background: join == _join
                            ? ExploreStyle.raised(t)
                            : Colors.transparent,
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _join = join),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (!_join) ...[
            _label(l.styleExplore_evolutionName),
            ExploreDialogFocusRing(
              child: SizedBox(
                height: 38,
                child: TextField(
                  key: const Key('explore-family-name'),
                  controller: _name,
                  enabled: !_submitting,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14, height: 1.45),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: ExploreDialogFrame.inputDecoration(context),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          _label(l.styleExplore_firstGenerationParents(_parents.length)),
          for (final candidate in _candidates)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _parent(candidate),
            ),
          for (var i = 0; i < _custom.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: Key('explore-custom-parent-$i'),
                      controller: _custom[i],
                      enabled: !_submitting,
                      minLines: 1,
                      maxLines: 3,
                      style: StudioTypography.data.copyWith(fontSize: 12),
                      decoration: ExploreDialogFrame.inputDecoration(
                        context,
                        hint: l.styleExplore_evolutionCustomHint,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ExploreIconButton(
                    'x',

                    tooltip: l.common_delete,
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _custom.removeAt(i).dispose()),
                  ),
                ],
              ),
            ),
          CustomPaint(
            painter: DashedRoundedBorderPainter(
              color: c.outlineVariant,
              dashedColor: c.outlineVariant,
              radius: const Radius.circular(9),
              topRounded: true,
              bottomRounded: true,
              solidLeft: false,
              solidRight: false,
              dashedAll: true,
            ),
            child: ExploreButton(
              key: const Key('explore-add-custom-parent'),
              label: l.styleExplore_evolutionAddCustom,
              icon: const ExploreIcon('plus', size: 15),
              height: 46,
              ghost: true,
              horizontal: 14,
              fontSize: 12,
              color: muted,
              expand: true,
              onPressed: _submitting
                  ? null
                  : () => setState(() => _custom.add(TextEditingController())),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            key: const Key('explore-evolution-target'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: ExploreStyle.panel(t),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ExploreIcon(
                  block == null ? 'warn' : 'dice',
                  size: 15,
                  color: block == null
                      ? c.error
                      : promptBlockColorFromString(block.color),
                ),
                ExploreText(
                  block == null
                      ? l.styleExplore_variablesEmpty
                      : l.styleExplore_evolutionTarget,
                  style: TextStyle(
                    fontSize: 12,
                    color: block == null ? c.error : muted,
                  ),
                ),
                if (block != null)
                  PromptPill(
                    title: block.title,
                    color: promptBlockColorFromString(block.color),
                    appearance: block.appearance,
                    leading: ExploreIcon(
                      'dice',
                      size: 12,
                      color: promptBlockColorFromString(block.color),
                    ),
                  ),
                if (block != null)
                  ExploreText(
                    l.styleExplore_evolutionTargetAfter,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setCount(int value) => setState(() {
    _countEdited = true;
    _count.text = '$value';
  });
  Widget _countArrow(String icon, VoidCallback action) => ExploreIconButton(
    icon,

    width: 22,
    height: 32,
    size: 12,
    onPressed: _submitting ? null : action,
  );
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: ExploreText(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
  Widget _parent(ExploreCandidate candidate) {
    final t = Theme.of(context),
        c = t.colorScheme,
        text = exploreParentStringFor(candidate);
    return Container(
      key: Key('explore-evolution-parent-${candidate.id}'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ExploreStyle.raised(t),
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 58,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: ExploreCandidateImage(
                candidate: candidate,
                sequenceNumber: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ExploreText(
              text.isEmpty
                  ? context.l10n.styleExplore_evolutionParentEmpty
                  : text,
              style: StudioTypography.data.copyWith(
                fontSize: 12,
                height: 1.5,
                color: text.isEmpty ? c.error : c.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ExploreIconButton(
            'x',
            key: Key('explore-evolution-remove-${candidate.id}'),

            tooltip: context.l10n.common_delete,
            onPressed: _submitting
                ? null
                : () => setState(() => _candidates.remove(candidate)),
          ),
        ],
      ),
    );
  }
}
