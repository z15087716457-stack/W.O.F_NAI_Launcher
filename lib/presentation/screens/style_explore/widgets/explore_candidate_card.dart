import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/pill_roll_engine.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/style_explore/explore_roll_capture.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../themes/studio_typography.dart';
import '../../../widgets/library/library_card.dart';
import '../../../widgets/common/studio_icons.dart';
import '../../../widgets/prompt/pills/dna_icon.dart';
import 'explore_candidate_actions.dart';
import 'explore_icon.dart';

List<({String? weight, String text})> exploreCandidateArtistAtoms(
  ExploreCandidate candidate,
) {
  final roll = candidate.rollSnapshot;
  if (roll == null) return [];
  if (roll.instanceRolls.isEmpty) {
    return [
      (weight: null, text: String.fromCharCodes(roll.positive.runes.take(60))),
    ];
  }
  return [
    for (final instance in roll.instanceRolls)
      for (final atom in PillRollEngine.splitTopLevelAtoms(instance.rolledText))
        _displayAtom(atom),
  ];
}

({String? weight, String text}) _displayAtom(String atom) {
  final match = RegExp(
    r'^([+-]?\d+(?:\.\d+)?)::(.*)::$',
    dotAll: true,
  ).firstMatch(atom.trim());
  final text = match?.group(2) ?? atom.trim();
  return (
    weight: match?.group(1),
    text: text.startsWith('artist:') ? text.substring(7) : text,
  );
}

class ExploreCandidateCard extends ConsumerStatefulWidget {
  const ExploreCandidateCard({
    super.key,
    required this.run,
    required this.candidate,
    required this.sequenceNumber,
    required this.focused,
    required this.generating,
    required this.onFocus,
    required this.onOpenDetail,
    this.selectionMode = false,
    this.selected = false,
    this.onToggleSelect,
    this.onEnterSelection,
    this.forceHover = false,
  });
  final ExploreRun run;
  final ExploreCandidate candidate;
  final int sequenceNumber;
  final bool focused, generating, selectionMode, selected, forceHover;
  final VoidCallback onFocus, onOpenDetail;
  final VoidCallback? onToggleSelect, onEnterSelection;
  @override
  ConsumerState<ExploreCandidateCard> createState() =>
      _ExploreCandidateCardState();
}

class _ExploreCandidateCardState extends ConsumerState<ExploreCandidateCard> {
  bool _hover = false;
  Future<void> _heart() => ref
      .read(exploreRunListNotifierProvider.notifier)
      .updateReview(
        widget.run.id,
        widget.candidate.id,
        heart: !widget.candidate.review.heart,
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final candidate = widget.candidate;
    final hovered = _hover || widget.forceHover;
    final done =
        candidate.generation.status == ExploreCandidateGenerationStatus.done;
    final adopted = widget.run.parentSets.any(
      (set) =>
          set.parents.any((parent) => parent.sourceCandidateId == candidate.id),
    );
    final folder = widget.run.folderById(candidate.folderId ?? '');
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
                        BoxShadow(color: colors.primary, spreadRadius: 4),
                        BoxShadow(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.selectionMode
                        ? widget.onToggleSelect
                        : widget.onFocus,
                    onDoubleTap: widget.onOpenDetail,
                    onLongPress: widget.onEnterSelection,
                    onSecondaryTapUp: (details) =>
                        _more(details.globalPosition),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _image(),
                        if (widget.selected)
                          ColoredBox(
                            color: colors.primary.withValues(alpha: .14),
                          ),
                        if (done && candidate.review.heart)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: _heartButton(
                              Colors.white,
                              colors.error,
                              true,
                            ),
                          ),
                        if (done && (hovered || widget.selectionMode))
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
                                      ? colors.primary
                                      : Colors.black.withValues(alpha: .25),
                                  border: Border.all(
                                    color: widget.selected
                                        ? colors.primary
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
                            !hovered &&
                            (adopted ||
                                candidate.lineage.operation ==
                                    ExploreLineageOperation.mutation ||
                                candidate.lineage.operation ==
                                    ExploreLineageOperation.crossover ||
                                candidate.lineage.operation ==
                                    ExploreLineageOperation.injection))
                          Positioned(
                            left: 6,
                            bottom: 6,
                            child: _badge(
                              adopted
                                  ? l10n.styleExplore_parentBadge
                                  : switch (candidate.lineage.operation) {
                                      ExploreLineageOperation.mutation =>
                                        l10n.styleExplore_opMutation,
                                      ExploreLineageOperation.crossover =>
                                        l10n.styleExplore_opCrossover,
                                      _ => l10n.styleExplore_opInjection,
                                    },
                              background: adopted
                                  ? const Color(0x99000000)
                                  : switch (candidate.lineage.operation) {
                                      ExploreLineageOperation.mutation =>
                                        const Color(0xffc2410c),
                                      ExploreLineageOperation.injection =>
                                        const Color(0xff0e7490),
                                      _ => const Color(0xff6e56cf),
                                    },
                              foreground: Colors.white,
                              icon: adopted
                                  ? const DnaIcon(size: 11, color: Colors.white)
                                  : null,
                              height: 19,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (done && folder != null && !hovered)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: _badge(
                              folder.name,
                              background: const Color(0xe0ffffff),
                              foreground: const Color(0xff222222),
                              icon: const ExploreIcon(
                                'folder',
                                size: 11,
                                color: Color(0xff222222),
                              ),
                            ),
                          ),
                        if (done && hovered)
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: LibraryHoverActionBar(
                              children: [
                                _action(
                                  'heart',
                                  l10n.styleExplore_filterHearted,
                                  _heart,
                                ),
                                _action(
                                  'box',
                                  l10n.styleExplore_adoptAsBlock,
                                  () => ExploreCandidateActions.adoptSingle(
                                    context,
                                    ref,
                                    run: widget.run,
                                    candidate: candidate,
                                  ),
                                ),
                                _action(
                                  'max',
                                  l10n.styleExplore_candidateDetailTitle,
                                  widget.onOpenDetail,
                                ),
                                _action('more', l10n.library_more, () {
                                  final box =
                                      context.findRenderObject()! as RenderBox;
                                  _more(
                                    box.localToGlobal(
                                      Offset(
                                        box.size.width,
                                        box.size.height / 2,
                                      ),
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
            child: SizedBox(
              height: 11.5 * 1.45 * 2,
              child: Text.rich(
                TextSpan(
                  children: [
                    for (var i = 0; i < atoms.length; i++) ...[
                      if (i > 0)
                        TextSpan(
                          text: ' · ',
                          style: TextStyle(color: colors.outline),
                        ),
                      if (atoms[i].weight != null) ...[
                        TextSpan(
                          text: atoms[i].weight,
                          style: StudioTypography.data.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: .7,
                            ),
                          ),
                        ),
                        const WidgetSpan(child: SizedBox(width: 4)),
                      ],
                      TextSpan(text: atoms[i].text),
                    ],
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.45,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heartButton(Color background, Color foreground, bool filled) =>
      GestureDetector(
        key: Key('explore-candidate-heart-${widget.candidate.id}'),
        onTap: _heart,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Center(
            child: Icon(
              filled
                  ? StudioIcons.galleryHeartFilled
                  : StudioIcons.galleryHeart,
              size: 14,
              color: foreground,
            ),
          ),
        ),
      );

  Widget _badge(
    String text, {
    required Color background,
    required Color foreground,
    required Widget? icon,
    double height = 20,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w500,
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
        if (icon != null) ...[icon, const SizedBox(width: 3)],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: foreground,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _action(String icon, String tooltip, VoidCallback action) => Expanded(
    child: Tooltip(
      key: icon == 'heart' && !widget.candidate.review.heart
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
              borderRadius: BorderRadius.circular(6),
              onTap: action,
              child: Center(
                child: icon == 'heart'
                    ? const Icon(
                        StudioIcons.galleryHeart,
                        size: 13,
                        color: Colors.white,
                      )
                    : ExploreIcon(icon, size: 13, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _image() => ExploreCandidateImage(
    candidate: widget.candidate,
    sequenceNumber: widget.sequenceNumber,
    generating: widget.generating,
  );

  Future<void> _more(Offset position) async {
    final l10n = context.l10n;
    final candidate = widget.candidate;
    final box = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & box.size,
      ),
      items: [
        PopupMenuItem(
          value: 'apply',
          child: Text(l10n.styleExplore_applyToEditor),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Text(l10n.styleExplore_copyArtists),
        ),
        PopupMenuItem(
          value: 'delete',
          enabled: candidate.generation.filePath != null,
          child: Text(
            l10n.styleExplore_deleteImage,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case 'apply':
        await ExploreCandidateActions.fixateAsTemplate(
          context,
          ref,
          candidate: candidate,
        );
      case 'copy':
        await Clipboard.setData(
          ClipboardData(text: exploreParentStringFor(candidate)),
        );
      case 'delete':
        await ExploreCandidateActions.deleteImage(
          context,
          ref,
          runId: widget.run.id,
          candidate: candidate,
        );
    }
  }
}

class _GeneratingCandidate extends StatefulWidget {
  const _GeneratingCandidate({required this.number});
  final int number;
  @override
  State<_GeneratingCandidate> createState() => _GeneratingCandidateState();
}

class _GeneratingCandidateState extends State<_GeneratingCandidate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _scan.stop();
    } else {
      _scan.repeat();
    }
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!reduced)
            AnimatedBuilder(
              animation: _scan,
              builder: (_, child) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-3 + _scan.value * 6, -.3),
                    end: Alignment(-1 + _scan.value * 6, .3),
                    colors: [
                      Colors.transparent,
                      colors.primary.withValues(alpha: .16),
                      Colors.transparent,
                    ],
                    stops: const [0, .5, 1],
                  ),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 22,
                  child: reduced
                      ? ExploreIcon('swap', size: 22, color: colors.primary)
                      : CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.primary,
                          backgroundColor: colors.primary.withValues(
                            alpha: .25,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.styleExplore_generatingCandidate(widget.number),
                  style: TextStyle(fontSize: 12, color: colors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Candidate imagery shared by the wall, inspector and evolution views.
class ExploreCandidateImage extends StatelessWidget {
  const ExploreCandidateImage({
    super.key,
    required this.candidate,
    required this.sequenceNumber,
    this.generating = false,
    this.fit = BoxFit.cover,
  });
  final ExploreCandidate candidate;
  final int sequenceNumber;
  final bool generating;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final gen = candidate.generation;
    if (gen.status == ExploreCandidateGenerationStatus.failed) {
      final error = switch (gen.error) {
        'cancelled' => l10n.styleExplore_runStatusCancelled,
        'interrupted' => l10n.styleExplore_interrupted,
        _ => gen.error ?? l10n.styleExplore_operationFailed,
      };
      return Tooltip(
        message: error,
        child: ColoredBox(
          color: Color.alphaBlend(
            colors.error.withValues(alpha: .08),
            colors.surfaceContainerHighest,
          ),
          child: _placeholder(
            context,
            'warn',
            l10n.styleExplore_generationFailed,
            colors.error,
            hint: l10n.styleExplore_failureHint,
          ),
        ),
      );
    }
    if (gen.status == ExploreCandidateGenerationStatus.pending) {
      if (generating) {
        return _GeneratingCandidate(number: sequenceNumber);
      }
      return ColoredBox(
        color: colors.surfaceContainerHighest,
        child: _placeholder(
          context,
          'dice',
          l10n.styleExplore_queued(sequenceNumber),
          colors.onSurfaceVariant.withValues(alpha: .6),
        ),
      );
    }
    Widget missing() => ColoredBox(
      color: colors.surfaceContainerHighest,
      child: _placeholder(
        context,
        'img',
        l10n.styleExplore_imageDeleted,
        colors.onSurfaceVariant.withValues(alpha: .6),
      ),
    );
    if (gen.filePath == null) return missing();
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Image.file(
        File(gen.filePath!),
        fit: fit,
        gaplessPlayback: true,
        cacheWidth: 360,
        errorBuilder: (_, error, stack) => missing(),
      ),
    );
  }

  Widget _placeholder(
    BuildContext context,
    String icon,
    String text,
    Color color, {
    String? hint,
  }) => LayoutBuilder(
    builder: (context, space) {
      if (space.maxHeight < 100 || space.maxWidth < 80) {
        return Center(
          child: Tooltip(
            message: text,
            child: ExploreIcon(icon, size: 18, color: color, strokeWidth: 1.5),
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExploreIcon(icon, size: 22, color: color, strokeWidth: 1.5),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: color),
            ),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: .7),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
