import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../../../../core/utils/pill_roll_engine.dart';
import '../../../themes/studio_typography.dart';
import '../actions/explore_display_data.dart';

export '../actions/explore_display_data.dart';

/// The prototype's inline artist names and independent numeric font.
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
    final atoms = PillRollEngine.splitTopLevelAtoms(
      text,
    ).map(parseExploreArtistAtom).toList();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: text,
      child: Text.rich(
        TextSpan(
          children: [
            for (var i = 0; i < atoms.length; i++) ...[
              if (i != 0) const TextSpan(text: ' · '),
              if (atoms[i].weight case final weight?)
                TextSpan(
                  text: '$weight ',
                  style: StudioTypography.data.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
              TextSpan(text: atoms[i].text),
            ],
          ],
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: TextStyle(fontSize: fontSize, height: 1.45),
      ),
    );
  }
}
