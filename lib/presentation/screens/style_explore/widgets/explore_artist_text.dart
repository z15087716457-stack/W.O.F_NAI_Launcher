import 'package:flutter/material.dart';
import '../../../../core/utils/pill_roll_engine.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../themes/studio_typography.dart';

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

/// Readable artist names with the prototype's separate numeric font role.
/// Parsing affects display only; tooltip/copy/storage retain the original string.
class ExploreArtistLine extends StatelessWidget {
  const ExploreArtistLine({
    super.key,
    required this.text,
    this.fontSize = 12.5,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
  });
  final String text;
  final double fontSize;
  final int maxLines;
  final TextAlign textAlign;
  @override
  Widget build(BuildContext context) {
    final atoms = PillRollEngine.splitTopLevelAtoms(text),
        muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: text,
      child: Text.rich(
        TextSpan(
          children: [
            for (var i = 0; i < atoms.length; i++) ...[
              if (i > 0) const TextSpan(text: ' · '),
              if (parseExploreArtistAtom(atoms[i]).weight case final w?)
                TextSpan(
                  text: '$w ',
                  style: StudioTypography.data.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
              TextSpan(text: parseExploreArtistAtom(atoms[i]).text),
            ],
          ],
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: TextStyle(fontSize: fontSize),
      ),
    );
  }
}
