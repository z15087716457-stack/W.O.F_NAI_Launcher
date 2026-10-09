import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/style_explore/explore_roll_capture.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../providers/style_explore/explore_view_state.dart';
import '../../../themes/studio_typography.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/gallery/gallery_filter_widgets.dart';
import '../../../widgets/prompt/pills/dna_icon.dart';
import 'explore_candidate_card.dart';
import 'explore_candidate_hover_preview.dart';
import 'explore_evolution_actions.dart';
import 'explore_icon.dart';
import 'explore_parent_list.dart';
import 'explore_preference_sort_dialog.dart';
import 'explore_shared_actions.dart';
import 'explore_style.dart';
import 'horizontal_edge_fade.dart';

ExploreFamily? exploreSelectedFamily(ExploreRun run, String? id) =>
    run.familyById(id ?? '') ?? run.families.lastOrNull;

class ExploreEvolutionFilters extends ConsumerWidget {
  const ExploreEvolutionFilters({super.key, required this.run});
  final ExploreRun run;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context), l10n = context.l10n;
    final selected = exploreSelectedFamily(
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
                  for (final f in run.families)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onSecondaryTapUp: (d) => showExploreFamilyMenu(
                          context,
                          ref,
                          run,
                          f,
                          d.globalPosition,
                        ),
                        child: GalleryFilterChip(
                          key: ValueKey('explore-family-chip-${f.id}'),
                          label: f.name,
                          tooltip: f.name,
                          active: f.id == selected?.id,
                          activeColor: ExploreStyle.evolution(theme),
                          activeForeground: ExploreStyle.evolutionForeground(
                            theme,
                          ),
                          iconWidget: DnaIcon(
                            size: 13,
                            color: f.id == selected?.id
                                ? ExploreStyle.evolutionForeground(theme)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          trailing: Opacity(
                            opacity: .75,
                            child: Text(
                              l10n.styleExplore_generationNumber(
                                run
                                        .parentSetById(f.activeParentSetId)
                                        ?.generation ??
                                    1,
                              ),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: f.id == selected?.id
                                    ? ExploreStyle.evolutionForeground(theme)
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          onTap: () {
                            ref
                                .read(exploreActiveFamilyIdProvider.notifier)
                                .state = f
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
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        TextButton(
          key: const Key('explore-evolution-help'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(l10n.styleExplore_howToUse),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final text in [
                      l10n.styleExplore_helpParents,
                      l10n.styleExplore_helpChildren,
                      l10n.styleExplore_helpCompare,
                      l10n.styleExplore_helpBackcross,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(text),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: Text(l10n.common_close),
                ),
              ],
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 28),
          ),
          child: Text(
            l10n.styleExplore_howToUse,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class ExploreEvolutionView extends ConsumerStatefulWidget {
  const ExploreEvolutionView({
    super.key,
    required this.run,
    required this.cardBuilder,
    this.onGridLayout,
  });
  final ExploreRun run;
  final Widget Function(ExploreCandidate candidate, bool selectable)
  cardBuilder;
  final void Function(int columns, double extent)? onGridLayout;
  @override
  ConsumerState<ExploreEvolutionView> createState() =>
      _ExploreEvolutionViewState();
}

class _ExploreEvolutionViewState extends ConsumerState<ExploreEvolutionView> {
  final _expanded = <String>{};
  final _hover = ExploreCandidateHoverSession();
  bool _submitting = false;
  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ExploreEvolutionView old) {
    super.didUpdateWidget(old);
    if (old.run.id != widget.run.id) _expanded.clear();
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run,
        family = exploreSelectedFamily(
          run,
          ref.watch(exploreActiveFamilyIdProvider),
        );
    if (family == null) return _empty();
    final generations = exploreFamilyGenerations(run, family).reversed.toList();
    return SingleChildScrollView(
      key: ValueKey('explore-evolution-${run.id}-${family.id}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final g in generations)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  g.parentSet.id == family.activeParentSetId ||
                      _expanded.contains(g.parentSet.id)
                  ? _card(run, family, g)
                  : _collapsed(run, family, g),
            ),
        ],
      ),
    );
  }

  Widget _empty() {
    final l10n = context.l10n, theme = Theme.of(context);
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
            DnaIcon(size: 72, color: ExploreStyle.evolution(theme)),
            const SizedBox(height: 20),
            Text(
              l10n.styleExplore_evolutionEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('explore-evolution-pick'),
              onPressed: () {
                ref.read(exploreStageTabProvider.notifier).state =
                    ExploreStageTab.candidates;
                ref.read(exploreSelectionModeProvider.notifier).state = true;
              },
              child: Text(l10n.styleExplore_pickFromCandidates),
            ),
            if (missing) ...[
              const SizedBox(height: 16),
              Text(
                l10n.styleExplore_variablesEmpty,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(int generation, {bool old = false}) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: old
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : ExploreStyle.evolution(Theme.of(context)),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      '$generation',
      style: StudioTypography.data.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: old
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Colors.white,
      ),
    ),
  );
  Widget _thumb(
    ExploreRun run,
    ExploreCandidate? c, {
    double width = 34,
    double height = 48,
    bool picked = false,
  }) {
    Widget image = Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: picked
            ? Border.all(
                color: ExploreStyle.evolution(Theme.of(context)),
                width: 2,
              )
            : null,
      ),
      child: c == null
          ? const Icon(Icons.text_fields, size: 18)
          : ExploreCandidateImage(
              candidate: c,
              sequenceNumber: run.candidates.indexOf(c) + 1,
              generating: false,
              fit: BoxFit.cover,
            ),
    );
    if (c != null) {
      image = ExploreCandidateHoverThumb(
        session: _hover,
        candidateId: c.id,
        filePath: c.generation.filePath,
        badgeText: '#${run.candidates.indexOf(c) + 1}',
        child: GestureDetector(
          onTap: () => openExploreCandidate(context, ref, run, c),
          child: image,
        ),
      );
    }
    return image;
  }

  Widget _collapsed(
    ExploreRun run,
    ExploreFamily f,
    ExploreLineageGeneration g,
  ) {
    final theme = Theme.of(context), l10n = context.l10n;
    final next = run.parentSets
        .where(
          (s) =>
              s.familyId == f.id && s.generation == g.parentSet.generation + 1,
        )
        .firstOrNull;
    final picked =
        next?.parents.map((p) => p.sourceCandidateId).toSet() ?? <String?>{};
    return Container(
      key: ValueKey('explore-generation-collapsed-${g.parentSet.id}'),
      height: 64,
      padding: const EdgeInsets.fromLTRB(14, 5, 10, 5),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        children: [
          _badge(g.parentSet.generation, old: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.styleExplore_generationNumber(g.parentSet.generation),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  l10n.styleExplore_generationSummary(
                    g.parentSet.parents.length,
                    g.pile.length,
                    g.pile.where((c) => picked.contains(c.id)).length,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in g.pile.take(8))
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _thumb(
                        run,
                        c,
                        width: 36,
                        height: 52,
                        picked: picked.contains(c.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            key: ValueKey('explore-generation-expand-${g.parentSet.id}'),
            onPressed: () => setState(() => _expanded.add(g.parentSet.id)),
            icon: const ExploreIcon('chevD', size: 14),
          ),
        ],
      ),
    );
  }

  Widget _card(ExploreRun run, ExploreFamily f, ExploreLineageGeneration g) {
    final theme = Theme.of(context),
        l10n = context.l10n,
        colors = theme.colorScheme;
    final set = g.parentSet, active = set.id == f.activeParentSetId;
    final root = run.parentSetById(f.rootParentSetId);
    final rootStrings = {
      if (set.generation > 1)
        for (final p in root?.parents ?? <ExploreParent>[]) p.artistString,
    };
    final sourceCount = set.parents
        .where((p) => !rootStrings.contains(p.artistString))
        .length;
    final explanation = set.generation == 1
        ? l10n.styleExplore_generationStart(set.parents.length)
        : l10n.styleExplore_generationSource(
            set.generation - 1,
            sourceCount,
            root?.parents.length ?? 0,
          );
    final busy =
        !exploreParentSetRoundsComplete(run, set) ||
        (ref.watch(exploreRunRunnerProvider).isRunning &&
            ref.watch(exploreRunRunnerProvider).runId == run.id);
    final selected = ref
        .watch(exploreSelectionProvider)
        .intersection(g.pile.map((c) => c.id).toSet());
    return Container(
      key: ValueKey('explore-generation-${set.id}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 46,
            padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
            decoration: BoxDecoration(
              color: ExploreStyle.evolutionBg(theme),
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              children: [
                _badge(set.generation, old: !active),
                const SizedBox(width: 8),
                Expanded(
                  child: Tooltip(
                    message: explanation,
                    child: Row(
                      children: [
                        Text(
                          l10n.styleExplore_generationNumber(set.generation),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (active) ...[
                          const SizedBox(width: 8),
                          Text(
                            l10n.styleExplore_currentGeneration,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (set.branchName case final name?) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            explanation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (active) ...[
                  OutlinedButton.icon(
                    key: ValueKey('explore-sort-parents-${set.id}'),
                    onPressed: set.parents.length < 2
                        ? null
                        : () => ExplorePreferenceSortDialog.show(
                            context,
                            runId: run.id,
                            parentSet: set,
                          ),
                    style: _buttonStyle(),
                    icon: const ExploreIcon('sort', size: 14),
                    label: Text(
                      l10n.styleExplore_pairCompare,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _DeepRoundControl(
                    key: ValueKey('explore-deep-round-control-${set.id}'),
                    run: run,
                    family: f,
                    parentSet: set,
                  ),
                ] else
                  IconButton(
                    key: ValueKey('explore-generation-collapse-${set.id}'),
                    onPressed: () => setState(() => _expanded.remove(set.id)),
                    icon: const ExploreIcon('chevU', size: 14),
                  ),
              ],
            ),
          ),
          Stack(
            children: [
              Positioned(
                left: 299,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 1,
                  child: ColoredBox(color: colors.outlineVariant),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 300,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.styleExplore_parentsByPreference,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ExploreParentList(
                          parents: set.parents,
                          backcrossStrings: rootStrings,
                          thumbBuilder: (p) => _thumb(
                            run,
                            run.candidateById(p.sourceCandidateId ?? ''),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.styleExplore_childrenCount(g.pile.length),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  active
                                      ? l10n.styleExplore_pickForGeneration(
                                          set.generation + 1,
                                        )
                                      : l10n.styleExplore_branchNeedLatest,
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (g.pile.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                l10n.styleExplore_childrenEmpty,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            LayoutBuilder(
                              builder: (context, c) {
                                final n = ((c.maxWidth + 8) / 128)
                                        .floor()
                                        .clamp(1, 100),
                                    w = (c.maxWidth - 8 * (n - 1)) / n;
                                final extent =
                                    w /
                                        (run.paramsSnapshot.width /
                                            run.paramsSnapshot.height) +
                                    6 +
                                    11.5 * 1.45 * 2;
                                if (active) {
                                  widget.onGridLayout?.call(n, extent + 10);
                                }
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: g.pile.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: n,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 10,
                                        mainAxisExtent: extent,
                                      ),
                                  itemBuilder: (_, i) =>
                                      widget.cardBuilder(g.pile[i], active),
                                );
                              },
                            ),
                          if (active) ...[
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                key: ValueKey('explore-breed-${set.id}'),
                                onPressed:
                                    selected.isEmpty || busy || _submitting
                                    ? null
                                    : () async {
                                        setState(() => _submitting = true);
                                        try {
                                          await breedExploreNextGeneration(
                                            context,
                                            ref,
                                            run,
                                            ids: selected,
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() => _submitting = false);
                                          }
                                        }
                                      },
                                style: _buttonStyle().copyWith(
                                  backgroundColor:
                                      WidgetStateProperty.resolveWith(
                                        (s) => s.contains(WidgetState.disabled)
                                            ? colors.surfaceContainerHighest
                                            : ExploreStyle.evolution(theme),
                                      ),
                                  foregroundColor:
                                      WidgetStateProperty.resolveWith(
                                        (s) => s.contains(WidgetState.disabled)
                                            ? colors.onSurfaceVariant
                                            : ExploreStyle.evolutionForeground(
                                                theme,
                                              ),
                                      ),
                                ),
                                icon: DnaIcon(
                                  size: 14,
                                  color: ExploreStyle.evolutionForeground(
                                    theme,
                                  ),
                                ),
                                label: Text(
                                  l10n.styleExplore_breedSelected(
                                    selected.length,
                                    set.generation + 1,
                                  ),
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              busy
                                  ? l10n.styleExplore_generationBusy
                                  : l10n.styleExplore_backcrossHint,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
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

  ButtonStyle _buttonStyle() => OutlinedButton.styleFrom(
    minimumSize: const Size(0, 30),
    padding: const EdgeInsets.symmetric(horizontal: 9),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  );
}

class _DeepRoundControl extends ConsumerStatefulWidget {
  const _DeepRoundControl({
    super.key,
    required this.run,
    required this.family,
    required this.parentSet,
  });
  final ExploreRun run;
  final ExploreFamily family;
  final ExploreParentSet parentSet;
  @override
  ConsumerState<_DeepRoundControl> createState() => _DeepRoundControlState();
}

class _DeepRoundControlState extends ConsumerState<_DeepRoundControl> {
  int get _min => widget.parentSet.parents.length;
  int get _max => math.max(50, _min);
  late final _count = TextEditingController(text: '${_min + 1}');
  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final l10n = context.l10n, value = int.tryParse(_count.text.trim());
    if (value == null || value < _min) {
      AppToast.warning(context, l10n.styleExplore_deepRoundCountHint(_min));
      return;
    }
    try {
      final started = await ref
          .read(exploreRunRunnerProvider.notifier)
          .startDeepRound(
            widget.run.id,
            familyId: widget.family.id,
            parentSetId: widget.parentSet.id,
            count: value.clamp(_min, _max),
          );
      if (!started && mounted) {
        AppToast.info(context, l10n.styleExplore_runBusy);
      }
    } on ExploreDeepRoundException catch (e) {
      if (!mounted) return;
      AppToast.error(context, switch (e.reason) {
        ExploreDeepRoundRejection.noRandomInstance =>
          l10n.styleExplore_deepRoundNoInstance,
        ExploreDeepRoundRejection.mutationEmpty =>
          l10n.styleExplore_deepRoundEmpty,
        ExploreDeepRoundRejection.invalidParentSet =>
          l10n.styleExplore_operationFailed,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(exploreRunRunnerProvider),
        busy = r.isRunning && r.runId == widget.run.id;
    final theme = Theme.of(context),
        l10n = context.l10n,
        fg = ExploreStyle.evolutionForeground(theme);
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: busy
            ? theme.colorScheme.surfaceContainerHighest
            : ExploreStyle.evolution(theme),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            key: ValueKey('explore-deep-round-${widget.parentSet.id}'),
            onTap: busy ? null : _generate,
            child: Padding(
              padding: const EdgeInsets.only(left: 9, right: 5),
              child: Row(
                children: [
                  ExploreIcon('play', size: 12, color: fg),
                  const SizedBox(width: 5),
                  Text(
                    l10n.styleExplore_regeneratePrefix,
                    style: TextStyle(fontSize: 12, color: fg),
                  ),
                ],
              ),
            ),
          ),
          _step(-1, busy, fg),
          SizedBox(
            width: 26,
            child: TextField(
              key: ValueKey('explore-deep-round-count-${widget.parentSet.id}'),
              enabled: !busy,
              controller: _count,
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
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _generate(),
            ),
          ),
          _step(1, busy, fg),
          GestureDetector(
            onTap: busy ? null : _generate,
            child: Padding(
              padding: const EdgeInsets.only(left: 5, right: 9),
              child: Text(
                l10n.styleExplore_regenerateSuffix,
                style: TextStyle(fontSize: 12, color: fg),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(int delta, bool busy, Color fg) => GestureDetector(
    key: ValueKey('explore-deep-step-${widget.parentSet.id}-$delta'),
    onTap: busy
        ? null
        : () {
            _count.text =
                '${((int.tryParse(_count.text) ?? _min) + delta).clamp(_min, _max)}';
          },
    child: SizedBox(
      width: 15,
      height: 30,
      child: Center(
        child: ExploreIcon(delta > 0 ? 'plus' : 'minus', size: 10, color: fg),
      ),
    ),
  );
}
