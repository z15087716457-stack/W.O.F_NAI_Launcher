import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/pill_roll_engine.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_view_state.dart';
import '../../../themes/studio_typography.dart';
import '../../../widgets/common/studio_icons.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import '../../../widgets/navigation/window_chrome_layout.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/pills/prompt_pill.dart';
import '../../../widgets/prompt/pills/dna_icon.dart';
import 'explore_artist_text.dart';
import 'explore_candidate_actions.dart';
import 'explore_candidate_card.dart';
import 'explore_folder_assign_bar.dart';
import 'explore_icon.dart';
import 'explore_shared_actions.dart';
import 'explore_style.dart';
import 'explore_highlighted_prompt.dart';

class ExploreInspector extends ConsumerStatefulWidget {
  const ExploreInspector({
    super.key,
    this.runId,
    this.candidateId,
    this.viewer = false,
    this.onEvolution,
    this.onAssigned,
  });
  final String? runId, candidateId;
  final bool viewer;
  final VoidCallback? onEvolution;
  final void Function(String?)? onAssigned;
  @override
  ConsumerState<ExploreInspector> createState() => _ExploreInspectorState();
}

class _ExploreInspectorState extends ConsumerState<ExploreInspector> {
  final _scroll = ScrollController();
  bool _expanded = false;
  bool _negativeExpanded = false;
  @override
  void didUpdateWidget(covariant ExploreInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidateId != widget.candidateId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context),
        colors = theme.colorScheme,
        l10n = context.l10n;
    final run = widget.runId == null
        ? ref.watch(exploreActiveRunProvider)
        : ref
              .watch(exploreRunListNotifierProvider)
              .valueOrNull
              ?.runById(widget.runId!);
    final focus =
        widget.candidateId ?? ref.watch(exploreFocusedCandidateIdProvider);
    final candidate = run?.candidateById(focus ?? '');
    final ids = ref.watch(exploreSelectionProvider);
    final selected = ref.watch(exploreSelectionModeProvider) && ids.isNotEmpty
        ? [
            for (final c in run?.candidates ?? <ExploreCandidate>[])
              if (ids.contains(c.id)) c,
          ]
        : <ExploreCandidate>[];
    ref.listen(exploreFocusedCandidateIdProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    });
    if (widget.viewer && run != null && candidate != null) {
      return _viewer(run, candidate);
    }
    return LayoutBuilder(
      builder: (context, box) => Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          border: Border(left: BorderSide(color: colors.outlineVariant)),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: WindowPanelHeader(
                headerHeight: 51,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 28),
                  child: Row(
                    children: [
                      if (selected.isNotEmpty)
                        Expanded(
                          child: Text(
                            l10n.styleExplore_selectedCount(selected.length),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (candidate != null && run != null) ...[
                        Text(
                          '#${run.candidates.indexOf(candidate) + 1}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _roundStamp(run, candidate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ] else
                        Expanded(
                          child: Text(
                            l10n.styleExplore_inspectorTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
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
                        child: Text(
                          l10n.styleExplore_inspectorEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: .7,
                            ),
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: selected.isNotEmpty
                          ? _multi(selected, run)
                          : _single(run, candidate!, box.maxWidth),
                    ),
            ),
            if (run != null && candidate != null && selected.isEmpty) ...[
              if (_expanded && candidate.rollSnapshot != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: box.maxHeight * .4),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.prompt_positivePrompt,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          candidate.rollSnapshot!.positive,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.prompt_negativePrompt,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.onSurfaceVariant,
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
                height: 43,
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.outlineVariant)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        key: const Key('explore-inspector-full-prompt'),
                        onPressed: () => setState(() => _expanded = !_expanded),
                        icon: ExploreIcon(
                          _expanded ? 'chevU' : 'chevD',
                          size: 13,
                        ),
                        label: Text(
                          l10n.styleExplore_fullPrompt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          minimumSize: const Size(0, 30),
                          textStyle: StudioTypography.body.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                          foregroundColor: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      key: const Key('explore-inspector-delete'),
                      onPressed:
                          candidate.generation.status ==
                              ExploreCandidateGenerationStatus.pending
                          ? null
                          : () => _delete(run, candidate),
                      icon: ExploreIcon('trash', size: 14, color: colors.error),
                      label: Text(l10n.common_delete),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        minimumSize: const Size(0, 30),
                        textStyle: StudioTypography.body.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                        foregroundColor: colors.error,
                      ),
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

  String _roundStamp(ExploreRun run, ExploreCandidate candidate) {
    final round = run.roundById(candidate.roundId),
        time = round?.createdAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${context.l10n.styleExplore_roundNumber(round?.number ?? 1)}${time == null ? '' : ' · ${two(time.hour)}:${two(time.minute)}'}';
  }

  Widget _heading(String text, {Widget? trailing}) => Row(
    children: [
      Expanded(
        child: Text(
          text,
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
  Widget _single(ExploreRun run, ExploreCandidate candidate, double width) {
    final l10n = context.l10n;
    final done =
        candidate.generation.status == ExploreCandidateGenerationStatus.done;
    final visible = ref.watch(exploreVisibleCandidatesProvider),
        index = visible.indexWhere((c) => c.id == candidate.id);
    final imageHeight = (372 * ((width - 28) / 284)).clamp(372.0, 480.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: imageHeight,
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
                  right: 8,
                  top: 8,
                  child: _imageButton(
                    'max',
                    l10n.styleExplore_candidateDetailTitle,
                    () => openExploreCandidate(context, ref, run, candidate),
                  ),
                ),
                if (index > 0)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _imageButton(
                      'chevL',
                      l10n.styleExplore_prevCandidate,
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
                      l10n.styleExplore_nextCandidate,
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

  Widget _draws(ExploreCandidate candidate) {
    final colors = Theme.of(context).colorScheme, l10n = context.l10n;
    final done =
        candidate.generation.status == ExploreCandidateGenerationStatus.done;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          l10n.styleExplore_drawsTitle,
          trailing: GestureDetector(
            key: const Key('explore-inspector-copy-artists'),
            onTap: () => _copy(exploreInspectorArtists(candidate)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExploreIcon('copy', size: 12, color: colors.primary),
                const SizedBox(width: 4),
                Text(
                  l10n.styleExplore_copyArtists,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        if (!done)
          Text(
            candidate.generation.status ==
                    ExploreCandidateGenerationStatus.failed
                ? candidate.generation.error ??
                      l10n.styleExplore_generationFailed
                : l10n.styleExplore_drawsAfterGeneration,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          )
        else if (candidate.rollSnapshot?.instanceRolls.isNotEmpty == true) ...[
          for (final roll in candidate.rollSnapshot!.instanceRolls)
            Padding(
              padding: EdgeInsets.only(
                bottom: roll == candidate.rollSnapshot!.instanceRolls.last
                    ? 0
                    : 7,
              ),
              child: _block(roll),
            ),
        ] else
          _atoms(exploreRawArtistAtoms(candidate)),
      ],
    );
  }

  Widget _actions(ExploreRun run, ExploreCandidate candidate) {
    final l10n = context.l10n;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _action(
                'heart',
                candidate.review.heart
                    ? l10n.styleExplore_hearted
                    : l10n.styleExplore_filterHearted,
                () => ref
                    .read(exploreRunListNotifierProvider.notifier)
                    .updateReview(
                      run.id,
                      candidate.id,
                      heart: !candidate.review.heart,
                    ),
                key: Key(
                  widget.viewer
                      ? 'explore-candidate-heart'
                      : 'explore-inspector-heart',
                ),
                hotkey: 'F',
                hearted: candidate.review.heart,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _action(
                'evo',
                l10n.styleExplore_joinEvolution,
                widget.onEvolution ??
                    () => startExploreEvolution(context, ref, run, [candidate]),
                hotkey: 'E',
                evolution: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _action(
                'box',
                l10n.styleExplore_saveBlock,
                () => ExploreCandidateActions.adoptSingle(
                  context,
                  ref,
                  run: run,
                  candidate: candidate,
                ),
                key: Key(
                  widget.viewer
                      ? 'explore-candidate-adopt-block'
                      : 'explore-inspector-save',
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _action(
                'enter',
                l10n.styleExplore_applyToEditor,
                () => ExploreCandidateActions.fixateAsTemplate(
                  context,
                  ref,
                  candidate: candidate,
                ),
                key: Key(
                  widget.viewer
                      ? 'explore-candidate-fixate'
                      : 'explore-inspector-apply',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _viewer(ExploreRun run, ExploreCandidate candidate) {
    final colors = Theme.of(context).colorScheme, l10n = context.l10n;
    return Container(
      color: colors.surfaceContainerLow,
      child: Column(
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: WindowPanelHeader(
              headerHeight: 51,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '#${run.candidates.indexOf(candidate) + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (candidate.generation.status ==
                      ExploreCandidateGenerationStatus.done) ...[
                    _actions(run, candidate),
                    const SizedBox(height: 14),
                  ],
                  _draws(candidate),
                  const SizedBox(height: 14),
                  _heading(
                    l10n.styleExplore_fullPrompt,
                    trailing: GestureDetector(
                      key: const Key('explore-candidate-copy-snapshot'),
                      onTap: () => _copySnapshot(candidate.rollSnapshot),
                      child: ExploreIcon(
                        'copy',
                        size: 12,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (candidate.rollSnapshot != null)
                    ExploreHighlightedPrompt(snapshot: candidate.rollSnapshot!),
                  const SizedBox(height: 14),
                  GestureDetector(
                    key: const Key('explore-viewer-negative'),
                    onTap: () =>
                        setState(() => _negativeExpanded = !_negativeExpanded),
                    child: _heading(
                      l10n.prompt_negativePrompt,
                      trailing: ExploreIcon(
                        _negativeExpanded ? 'chevU' : 'chevD',
                        size: 12,
                        color: colors.onSurfaceVariant,
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
                  _params(run, candidate),
                  const SizedBox(height: 14),
                  ExploreFolderAssignBar(
                    run: run,
                    candidate: candidate,
                    onAssigned: widget.onAssigned,
                  ),
                  if (candidate.generation.filePath != null) ...[
                    const SizedBox(height: 14),
                    TextButton.icon(
                      key: const Key('explore-candidate-delete-image'),
                      onPressed: () => _delete(run, candidate),
                      icon: ExploreIcon('trash', size: 14, color: colors.error),
                      label: Text(l10n.common_delete),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.zero,
                        foregroundColor: colors.error,
                        textStyle: StudioTypography.body.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _block(ExploreInstanceRoll roll) {
    final colors = Theme.of(context).colorScheme;
    final block = ref
        .watch(promptBlockLibraryNotifierProvider)
        .valueOrNull
        ?.blockById(roll.blockId);
    final color = block == null
        ? colors.outline
        : promptBlockColorFromString(block.color);
    return Container(
      key: ValueKey('explore-inspector-roll-${roll.lane}-${roll.marker}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
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
                ),
              ),
              if (roll.lane == 'neg') ...[
                const SizedBox(width: 6),
                Text(
                  context.l10n.styleExplore_variableNegative,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          roll.rolledText.trim().isEmpty
              ? Text(
                  context.l10n.styleExplore_emptyDraw,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant.withValues(alpha: .7),
                  ),
                )
              : _atoms(PillRollEngine.splitTopLevelAtoms(roll.rolledText)),
        ],
      ),
    );
  }

  Widget _atoms(List<String> raw) => Wrap(
    spacing: 5,
    runSpacing: 5,
    children: [
      for (final value in raw)
        ExploreArtistChip(atom: parseExploreArtistAtom(value)),
    ],
  );
  Widget _imageButton(String icon, String tooltip, VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        child: GestureDetector(
          key: Key('explore-inspector-image-$icon'),
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ExploreIcon(
              icon,
              size: icon == 'max' ? 15 : 16,
              color: Colors.white,
            ),
          ),
        ),
      );
  Widget _action(
    String icon,
    String label,
    VoidCallback onTap, {
    Key? key,
    String? hotkey,
    bool hearted = false,
    bool evolution = false,
  }) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final color = hearted
        ? colors.error
        : evolution
        ? ExploreStyle.evolution(theme)
        : colors.onSurface;
    return Tooltip(
      message: label,
      child: Material(
        color: hearted
            ? Color.alphaBlend(
                colors.error.withValues(alpha: .06),
                colors.surfaceContainer,
              )
            : colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(
            color: hearted
                ? colors.error.withValues(alpha: .4)
                : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: key,
          onTap: onTap,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: Row(
              children: [
                icon == 'heart'
                    ? Icon(
                        hearted
                            ? StudioIcons.galleryHeartFilled
                            : StudioIcons.galleryHeart,
                        size: 15,
                        color: color,
                      )
                    : icon == 'evo'
                    ? DnaIcon(size: 15, color: color)
                    : ExploreIcon(icon, size: 15, color: color),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                if (hotkey != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    height: 18,
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                      border: Border(
                        top: BorderSide(color: colors.outlineVariant),
                        left: BorderSide(color: colors.outlineVariant),
                        right: BorderSide(color: colors.outlineVariant),
                        bottom: BorderSide(
                          color: colors.outlineVariant,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      hotkey,
                      style: StudioTypography.data.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _params(ExploreRun run, ExploreCandidate candidate) {
    final l10n = context.l10n, p = run.paramsSnapshot, g = candidate.generation;
    final entries =
        <({String label, String value, bool mono, VoidCallback? onTap})>[
          (
            label: widget.viewer
                ? l10n.styleExplore_seedClickCopy
                : l10n.styleExplore_seedName,
            value: g.seed?.toString() ?? '—',
            mono: true,
            onTap: g.seed == null ? null : () => _copy(g.seed.toString()),
          ),
          (
            label: l10n.styleExplore_elapsedName,
            value: g.elapsedMs == null
                ? '—'
                : '${(g.elapsedMs! / 1000).toStringAsFixed(1)} s',
            mono: true,
            onTap: null,
          ),
          (
            label: l10n.styleExplore_parameters,
            value: l10n.styleExplore_parameterSummary(
              p.width,
              p.height,
              p.steps,
              p.scale.toStringAsFixed(1),
            ),
            mono: true,
            onTap: null,
          ),
          (
            label: l10n.styleExplore_modelName,
            value: ImageModels.modelDisplayNames[p.model] ?? p.model,
            mono: false,
            onTap: null,
          ),
        ];
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        for (final entry in entries)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 3),
                child: Text(
                  entry.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: GestureDetector(
                  onTap: entry.onTap,
                  child: Text(
                    entry.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: entry.mono
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

  Widget _multi(List<ExploreCandidate> selected, ExploreRun run) {
    final colors = Theme.of(context).colorScheme;
    return Column(
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
          itemBuilder: (_, index) => ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ExploreCandidateImage(
                  candidate: selected[index],
                  sequenceNumber: run.candidates.indexOf(selected[index]) + 1,
                  generating: false,
                ),
                if (index == 7 && selected.length > 8)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: .5),
                    child: Center(
                      child: Text(
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
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: _atoms(exploreMergedArtistAtoms(selected)),
        ),
        const SizedBox(height: 7),
        Text(
          context.l10n.styleExplore_selectionExplanation,
          style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Future<void> _copySnapshot(ExploreRollSnapshot? snapshot) async {
    if (snapshot == null) return;
    final buffer = StringBuffer()
      ..writeln(snapshot.positive)
      ..write('---${String.fromCharCode(10)}')
      ..writeln(snapshot.negative);
    for (final instance in snapshot.instanceRolls) {
      buffer.writeln(
        '[${instance.lane}] ${instance.blockTitle}: ${instance.rolledText}',
      );
    }
    await _copy(buffer.toString());
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) AppToast.success(context, context.l10n.common_copied);
  }

  Future<void> _delete(ExploreRun run, ExploreCandidate candidate) async {
    if (candidate.generation.filePath != null) {
      await ExploreCandidateActions.deleteImage(
        context,
        ref,
        runId: run.id,
        candidate: candidate,
      );
      return;
    }
    final yes = await ThemedConfirmDialog.show(
      context: context,
      title: context.l10n.styleExplore_deleteCandidatesTitle,
      content: context.l10n.styleExplore_deleteCandidatesMessage(1),
      confirmText: context.l10n.common_delete,
      type: ThemedConfirmDialogType.danger,
    );
    if (!yes || !mounted) return;
    final latest = ref
        .read(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(run.id)
        ?.candidateById(candidate.id);
    if (latest != null &&
        latest.generation.status != ExploreCandidateGenerationStatus.pending) {
      await ref.read(exploreRunListNotifierProvider.notifier).removeCandidates(
        run.id,
        [candidate.id],
      );
    }
  }
}

class ExploreArtistChip extends StatelessWidget {
  const ExploreArtistChip({super.key, required this.atom});
  final ExploreArtistAtom atom;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (atom.weight != null) ...[
            Text(
              atom.weight!,
              style: StudioTypography.data.copyWith(
                fontSize: 11,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
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
