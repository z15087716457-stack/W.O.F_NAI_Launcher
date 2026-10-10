import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../themes/studio_typography.dart';
import 'explore_artist_text.dart';
import 'explore_candidate_card.dart';
import 'explore_icon.dart';
import 'explore_style.dart';

export '../actions/explore_display_data.dart'
    show exploreHasLineage, exploreNewLineageAtoms;

class ExploreLineageInfo extends StatelessWidget {
  const ExploreLineageInfo({
    super.key,
    required this.run,
    required this.candidate,
  });
  final ExploreRun run;
  final ExploreCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), c = theme.colorScheme, l = context.l10n;
    final parents = [
      for (final id in candidate.lineage.parentCandidateIds.take(3))
        if (run.candidateById(id) case final parent?) parent,
    ];
    final atoms = exploreNewLineageAtoms(run, candidate);
    final operationColor = switch (candidate.lineage.operation) {
      ExploreLineageOperation.mutation => const Color(0xffc2410c),
      ExploreLineageOperation.injection => const Color(0xff0e7490),
      _ => ExploreStyle.evolution(theme),
    };
    final explanation = switch (candidate.lineage.operation) {
      ExploreLineageOperation.crossover => l.styleExplore_originCross,
      ExploreLineageOperation.mutation => l.styleExplore_originMutation,
      _ => l.styleExplore_originInjection,
    };
    return Column(
      key: const Key('explore-lineage-info'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.styleExplore_originTitle,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.45,
            fontWeight: FontWeight.w600,
            letterSpacing: .23,
            color: c.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 7),
        DecoratedBox(
          decoration: BoxDecoration(
            color: ExploreStyle.raised(theme),
            border: Border.all(color: c.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final parent in parents)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 26,
                            height: 38,
                            child: ExploreCandidateImage(
                              candidate: parent,
                              sequenceNumber:
                                  run.candidates.indexOf(parent) + 1,
                              generating: false,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ExploreArtistLine(
                            text: exploreInspectorArtists(parent),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExploreIcon('arrD', size: 13, color: c.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          explanation,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (atoms.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (var i = 0; i < atoms.length; i++)
                        _NewArtist(
                          raw: atoms[i],
                          // The prototype keeps the first atom in its ordinary
                          // gray box and accents the following origin atoms.
                          accent: i == 0 ? null : operationColor,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NewArtist extends StatelessWidget {
  const _NewArtist({required this.raw, this.accent});
  final String raw;
  final Color? accent;
  @override
  Widget build(BuildContext context) {
    final atom = parseExploreArtistAtom(raw), c = Theme.of(context).colorScheme;
    final ink = accent ?? c.onSurface;
    return Tooltip(
      message: context.l10n.styleExplore_newArtist,
      child: Container(
        key: ValueKey('explore-new-artist-$raw'),
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color:
              accent?.withValues(alpha: .14) ??
              Color(
                Theme.of(context).brightness == Brightness.dark
                    ? 0xff222222
                    : 0xfff2f2f2,
              ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          widthFactor: 1,
          child: Text.rich(
            TextSpan(
              children: [
                if (atom.weight case final weight?)
                  TextSpan(
                    text: '$weight ',
                    style: StudioTypography.data.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                TextSpan(text: atom.text),
              ],
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}
