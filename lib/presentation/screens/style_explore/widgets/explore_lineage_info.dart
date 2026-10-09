import 'package:flutter/material.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/pill_roll_engine.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../themes/studio_typography.dart';
import 'explore_artist_text.dart';
import 'explore_candidate_card.dart';
import 'explore_style.dart';

bool exploreHasLineage(ExploreCandidate c) => switch (c.lineage.operation) {
  ExploreLineageOperation.crossover ||
  ExploreLineageOperation.mutation ||
  ExploreLineageOperation.injection => true,
  _ => false,
};
List<String> exploreNewLineageAtoms(
  ExploreRun run,
  ExploreCandidate candidate,
) {
  final parentAtoms = {
    for (final id in candidate.lineage.parentCandidateIds)
      if (run.candidateById(id) case final p?)
        ...PillRollEngine.splitTopLevelAtoms(
          p.lineage.mutatedText ?? exploreInspectorArtists(p),
        ),
  };
  return PillRollEngine.splitTopLevelAtoms(
    candidate.lineage.mutatedText ?? exploreInspectorArtists(candidate),
  ).where((a) => !parentAtoms.contains(a)).toSet().toList();
}

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
    final l10n = context.l10n,
        theme = Theme.of(context),
        colors = theme.colorScheme;
    final label = switch (candidate.lineage.operation) {
      ExploreLineageOperation.crossover => l10n.styleExplore_opCrossover,
      ExploreLineageOperation.mutation => l10n.styleExplore_opMutation,
      _ => l10n.styleExplore_opInjection,
    };
    final explanation = switch (candidate.lineage.operation) {
      ExploreLineageOperation.crossover => l10n.styleExplore_originCross,
      ExploreLineageOperation.mutation => l10n.styleExplore_originMutation,
      _ => l10n.styleExplore_originInjection,
    };
    return Column(
      key: const Key('explore-lineage-info'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.styleExplore_originTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: ExploreStyle.evolution(theme),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (candidate.lineage.parentCandidateIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      for (final id
                          in candidate.lineage.parentCandidateIds.take(3))
                        if (run.candidateById(id) case final p?)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: SizedBox(
                              width: 26,
                              height: 38,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: ExploreCandidateImage(
                                  candidate: p,
                                  sequenceNumber: run.candidates.indexOf(p) + 1,
                                  generating: false,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              Text(
                explanation,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
              if (exploreNewLineageAtoms(run, candidate).isNotEmpty) ...[
                const SizedBox(height: 7),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final raw in exploreNewLineageAtoms(run, candidate))
                      Container(
                        key: ValueKey('explore-new-artist-$raw'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: ExploreStyle.evolutionBg(theme),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              if (parseExploreArtistAtom(raw).weight
                                  case final w?)
                                TextSpan(
                                  text: '$w ',
                                  style: StudioTypography.data.copyWith(
                                    fontSize: 10.5,
                                  ),
                                ),
                              TextSpan(
                                text:
                                    '${parseExploreArtistAtom(raw).text} · ${l10n.styleExplore_newArtist}',
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: ExploreStyle.evolution(theme),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
