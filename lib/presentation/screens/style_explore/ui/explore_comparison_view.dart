part of 'explore_preference_sort_dialog.dart';

class _ExplorePreferenceSortDialogState extends _ExploreComparisonController {
  @override
  Widget build(BuildContext context) {
    if (_pairs.isEmpty || _index >= _pairs.length) {
      return const Dialog(child: SizedBox(width: 240, height: 120));
    }
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    final run = ref
        .watch(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(widget.runId);
    final (left, right) = _pairs[_index];
    final narrow = MediaQuery.sizeOf(context).width < 1280;
    final purple = ExploreStyle.evolution(t);
    return Dialog(
      key: const Key('explore-preference-sort-dialog'),
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: ExploreStyle.raised(t),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) => _key(event),
        child: SizedBox(
          width: 1380,
          height: math.min(888, MediaQuery.sizeOf(context).height - 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 18, 6),
                child: Row(
                  children: [
                    ExploreIcon('sort', size: 20, color: purple),
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: narrow
                            ? MediaQuery.sizeOf(context).width * .35
                            : 480,
                      ),
                      child: ExploreText(
                        l.styleExplore_compareTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (run?.families
                            .where((f) => f.id == widget.parentSet.familyId)
                            .firstOrNull
                        case final family?) ...[
                      const SizedBox(width: 10),
                      Container(
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          color: ExploreStyle.evolutionBg(t),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: ExploreText(
                            '${family.name} · ${l.styleExplore_generationNumber(widget.parentSet.generation)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: purple,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (!narrow)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ExploreText(
                          l.styleExplore_sortLiveSave,
                          style: TextStyle(
                            fontSize: 12,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ExploreIconButton(
                      'x',
                      size: 18,
                      tooltip: l.common_close,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                  child: narrow
                      ? Column(
                          children: [
                            Expanded(child: _pair(run, left, right)),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 168,
                              child: _ranking(run, below: true),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _pair(run, left, right)),
                            const SizedBox(width: 18),
                            SizedBox(width: 280, child: _ranking(run)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pair(ExploreRun? run, ExploreParent left, ExploreParent right) {
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            ExploreText(
              l.styleExplore_compareQuestion,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExploreText(
                  l.styleExplore_sortProgress(_index + 1, _pairs.length),
                  style: StudioTypography.data.copyWith(
                    fontSize: 12,
                    color: c.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: LinearProgressIndicator(
                    value: (_index + 1) / _pairs.length,
                    minHeight: 4,
                    color: ExploreStyle.evolution(t),
                    backgroundColor: c.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Flexible(
          fit: FlexFit.loose,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _side(run, left, true)),
              const SizedBox(width: 16),
              Expanded(child: _side(run, right, false)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            _choice(
              'explore-sort-neither',
              l.styleExplore_sortNeither,
              '↓',
              ExploreComparisonResult.neither,
              'arrD',
              height: 30,
            ),
            _choice(
              'explore-sort-skip',
              l.styleExplore_sortSkip,
              l.styleExplore_sortSpace,
              ExploreComparisonResult.skip,
              'skip',
              height: 30,
              ghost: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _side(ExploreRun? run, ExploreParent parent, bool left) {
    final t = Theme.of(context), path = _filePathOf(run, parent);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: Key(left ? 'explore-sort-side-left' : 'explore-sort-side-right'),
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 610),
            child: SizedBox(
              width: double.infinity,
              height: 610,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                  color: ExploreStyle.panel(t),
                  child: parent.sourceCandidateId == null
                      ? Padding(
                          padding: const EdgeInsets.all(22),
                          child: Center(
                            child: ExploreText(
                              parent.artistString,
                              textAlign: TextAlign.center,
                              style: StudioTypography.data.copyWith(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        )
                      : path == null
                      ? _missing()
                      : Image.file(
                          File(path),
                          fit: BoxFit.contain,
                          cacheWidth: 1000,
                          errorBuilder: (_, e, s) => _missing(),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ExploreArtistLine(
          text: parent.artistString,
          textAlign: TextAlign.center,
          fontSize: 12.5,
          maxLines: 1,
        ),
        const SizedBox(height: 10),
        _choice(
          left ? 'explore-sort-left' : 'explore-sort-right',
          left
              ? context.l10n.styleExplore_sortLeft
              : context.l10n.styleExplore_sortRight,
          left ? '←' : '→',
          left ? ExploreComparisonResult.left : ExploreComparisonResult.right,
          left ? 'arrL' : 'arrR',
          fullWidthCenter: true,
        ),
      ],
    );
  }

  Widget _choice(
    String key,
    String label,
    String shortcut,
    ExploreComparisonResult result,
    String icon, {
    double height = 36,
    bool fullWidthCenter = false,
    bool ghost = false,
  }) => ExploreButton(
    key: Key(key),
    label: label,
    height: height,
    fullWidthCenter: fullWidthCenter,
    ghost: ghost,
    fontSize: height == 36 ? 13.5 : 12.5,
    icon: result == ExploreComparisonResult.right
        ? null
        : ExploreIcon(icon, size: 15),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (result == ExploreComparisonResult.right) ...[
          ExploreIcon(icon, size: 15),
          const SizedBox(width: 6),
        ],
        ExploreKeyCap(shortcut),
      ],
    ),
    onPressed: _submitting ? null : () => _answer(result),
  );
  Widget _missing() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExploreIcon(
          'img',
          size: 32,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        ExploreText(
          context.l10n.styleExplore_candidateMissing,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
  Widget _thumbnail(ExploreRun? run, ExploreParent parent) {
    final candidate = run?.candidateById(parent.sourceCandidateId ?? '');
    return candidate != null
        ? ExploreCandidateImage(candidate: candidate, sequenceNumber: 1)
        : ColoredBox(
            color: ExploreStyle.evolutionBg(Theme.of(context)),
            child: Center(
              child: ExploreIcon(
                'dice',
                size: 15,
                color: ExploreStyle.evolution(Theme.of(context)),
              ),
            ),
          );
  }

  Widget _ranking(ExploreRun? run, {bool below = false}) {
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    final parents = [...widget.parentSet.parents]
      ..sort((a, b) => _preferenceOf(run, b).compareTo(_preferenceOf(run, a)));
    final max = parents.map((p) => _preferenceOf(run, p)).reduce(math.max);
    return Container(
      key: const Key('explore-sort-ranking'),
      padding: EdgeInsets.only(left: below ? 0 : 18, top: below ? 10 : 0),
      decoration: BoxDecoration(
        border: below
            ? Border(top: BorderSide(color: c.outlineVariant))
            : Border(left: BorderSide(color: c.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExploreText(
            l.styleExplore_sortRanking,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              children: [
                for (final parent in parents)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          height: 44,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: _thumbnail(run, parent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ExploreArtistLine(
                                text: parent.artistString,
                                fontSize: 12,
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: max <= 0
                                    ? 0
                                    : _preferenceOf(run, parent) / max,
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                                color: ExploreStyle.evolution(t),
                                backgroundColor: c.surfaceContainerHighest,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ExploreText(
                          _preferenceOf(run, parent).toStringAsFixed(
                            _preferenceOf(run, parent) < 1 ? 2 : 1,
                          ),
                          style: StudioTypography.data.copyWith(
                            fontSize: 11,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ExploreText(
                    l.styleExplore_sortRankingHint,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.6,
                      color: ExploreStyle.faint(t),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
