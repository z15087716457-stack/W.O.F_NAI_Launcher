import 'dart:io';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/pill_roll_engine.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/style_explore/explore_roll_capture.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../themes/studio_typography.dart';
import '../../../widgets/library/library_card.dart';
import '../actions/explore_candidate_actions.dart';
import '../actions/explore_shared_actions.dart';
import 'explore_icon.dart';
import 'explore_text.dart';
import 'explore_style.dart';

part 'explore_card_controller.dart';
part 'explore_card_view.dart';

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
    this.compact = false,
  });
  final ExploreRun run;
  final ExploreCandidate candidate;
  final int sequenceNumber;
  final bool focused, generating, selectionMode, selected, forceHover, compact;
  final VoidCallback onFocus, onOpenDetail;
  final VoidCallback? onToggleSelect, onEnterSelection;
  @override
  ConsumerState<ExploreCandidateCard> createState() =>
      _ExploreCandidateCardState();
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
                ExploreText(
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
          ExploreStyle.faint(Theme.of(context)),
        ),
      );
    }
    Widget missing() => ColoredBox(
      color: colors.surfaceContainerHighest,
      child: _placeholder(
        context,
        'img',
        l10n.styleExplore_imageDeleted,
        ExploreStyle.faint(Theme.of(context)),
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
            ExploreText(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: color),
            ),
            if (hint != null) ...[
              const SizedBox(height: 8),
              ExploreText(
                hint,
                style: TextStyle(
                  fontSize: 11,
                  color: ExploreStyle.faint(Theme.of(context)),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
