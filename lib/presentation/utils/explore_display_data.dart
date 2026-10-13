import '../../core/utils/pill_roll_engine.dart';
import '../../data/models/style_explore/explore_run.dart';

typedef ExploreArtistAtom = ({String? weight, String text});
ExploreArtistAtom parseExploreArtistAtom(String value) {
  final match = RegExp(
    r'^([+-]?\d+(?:\.\d+)?)::(.*)::$',
    dotAll: true,
  ).firstMatch(value.trim());
  final text = match?.group(2) ?? value.trim();
  return (
    weight: match?.group(1),
    text: text.startsWith('artist:') ? text.substring(7) : text,
  );
}

List<String> exploreRawArtistAtoms(ExploreCandidate candidate) =>
    candidate.rollSnapshot == null
    ? []
    : candidate.rollSnapshot!.instanceRolls.isEmpty
    ? PillRollEngine.splitTopLevelAtoms(candidate.rollSnapshot!.positive)
    : [
        for (final roll in candidate.rollSnapshot!.instanceRolls)
          ...PillRollEngine.splitTopLevelAtoms(roll.rolledText),
      ];
List<String> exploreMergedArtistAtoms(Iterable<ExploreCandidate> candidates) =>
    {
      for (final candidate in candidates) ...exploreRawArtistAtoms(candidate),
    }.toList();
String exploreInspectorArtists(ExploreCandidate candidate) =>
    candidate.rollSnapshot?.instanceRolls.isNotEmpty == true
    ? candidate.rollSnapshot!.instanceRolls
          .map((r) => r.rolledText)
          .where((s) => s.trim().isNotEmpty)
          .join(', ')
    : candidate.rollSnapshot?.positive ?? '';

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

List<({int start, int end, String blockId})> explorePromptMatches(
  ExploreRollSnapshot snapshot,
) {
  final matches = <({int start, int end, String blockId})>[];
  for (final roll in snapshot.instanceRolls.where(
    (r) => r.lane == 'pos' && r.rolledText.isNotEmpty,
  )) {
    var from = 0;
    while (from < snapshot.positive.length) {
      final start = snapshot.positive.indexOf(roll.rolledText, from);
      if (start < 0) break;
      matches.add((
        start: start,
        end: start + roll.rolledText.length,
        blockId: roll.blockId,
      ));
      from = start + roll.rolledText.length;
    }
  }
  matches.sort((a, b) => a.start.compareTo(b.start));
  final kept = <({int start, int end, String blockId})>[];
  for (final match in matches) {
    if (kept.isEmpty || match.start >= kept.last.end) kept.add(match);
  }
  return kept;
}
