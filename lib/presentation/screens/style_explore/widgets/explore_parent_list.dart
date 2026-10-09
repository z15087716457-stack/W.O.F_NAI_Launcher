import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/pill_roll_engine.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../themes/studio_typography.dart';
import 'explore_artist_text.dart';
import 'explore_style.dart';

/// Display order and normalized bars never mutate stored preferences.
class ExploreParentList extends StatelessWidget {
  const ExploreParentList({
    super.key,
    required this.parents,
    required this.thumbBuilder,
    this.maxHeight = double.infinity,
    this.backcrossStrings = const {},
  });
  final List<ExploreParent> parents;
  final Widget Function(ExploreParent parent) thumbBuilder;
  final double maxHeight;
  final Set<String> backcrossStrings;
  @override
  Widget build(BuildContext context) {
    final indexed = parents.asMap().entries.toList()
      ..sort((a, b) {
        final order = b.value.preference.compareTo(a.value.preference);
        return order == 0 ? a.key.compareTo(b.key) : order;
      });
    final max = parents.fold<double>(0, (n, p) => math.max(n, p.preference));
    final theme = Theme.of(context), colors = theme.colorScheme;
    final rows = [
      for (final e in indexed)
        Padding(
          key: ValueKey('explore-parent-${e.value.id}'),
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 34,
                height: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: thumbBuilder(e.value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          for (final raw in PillRollEngine.splitTopLevelAtoms(
                            e.value.artistString,
                          )) ...[
                            if (raw !=
                                PillRollEngine.splitTopLevelAtoms(
                                  e.value.artistString,
                                ).first)
                              const TextSpan(text: ', '),
                            if (parseExploreArtistAtom(raw).weight
                                case final w?)
                              TextSpan(
                                text: '$w ',
                                style: StudioTypography.data.copyWith(
                                  fontSize: 10.5,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            TextSpan(text: parseExploreArtistAtom(raw).text),
                          ],
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              key: ValueKey('explore-preference-${e.value.id}'),
                              value: max > 0
                                  ? (e.value.preference / max).clamp(0, 1)
                                  : 0,
                              backgroundColor: colors.surfaceContainerHighest,
                              color: ExploreStyle.evolution(theme),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          e.value.preference
                              .toStringAsFixed(2)
                              .replaceFirst(RegExp(r'0$'), ''),
                          style: StudioTypography.data.copyWith(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (backcrossStrings.contains(
                          e.value.artistString,
                        )) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              context.l10n.styleExplore_backcross,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
    if (maxHeight.isFinite) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: rows,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
