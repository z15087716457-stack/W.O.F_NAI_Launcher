import '../../../../core/utils/pill_roll_engine.dart';
import '../../../../data/models/style_explore/explore_run.dart';

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
