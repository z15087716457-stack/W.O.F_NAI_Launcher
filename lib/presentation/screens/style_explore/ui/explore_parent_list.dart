import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../themes/studio_typography.dart';
import 'explore_artist_text.dart';
import 'explore_style.dart';

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
    final order = parents.asMap().entries.toList()
      ..sort((a, b) {
        final value = b.value.preference.compareTo(a.value.preference);
        return value == 0 ? a.key.compareTo(b.key) : value;
      });
    final maximum = parents.fold<double>(
      0,
      (value, parent) => math.max(value, parent.preference),
    );
    final rows = [
      for (final item in order)
        _ParentRow(
          key: ValueKey('explore-parent-${item.value.id}'),
          parent: item.value,
          preference: maximum == 0
              ? 0
              : (item.value.preference / maximum).clamp(0, 1),
          backcross: backcrossStrings.contains(item.value.artistString),
          thumbnail: thumbBuilder(item.value),
        ),
    ];
    return maxHeight.isFinite
        ? ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: rows,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          );
  }
}

class _ParentRow extends StatelessWidget {
  const _ParentRow({
    super.key,
    required this.parent,
    required this.preference,
    required this.thumbnail,
    required this.backcross,
  });
  final ExploreParent parent;
  final double preference;
  final Widget thumbnail;
  final bool backcross;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Tooltip(
      message: backcross ? context.l10n.styleExplore_backcross : '',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(width: 36, height: 52, child: thumbnail),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExploreArtistLine(text: parent.artistString, fontSize: 12),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 4,
                          child: LinearProgressIndicator(
                            key: ValueKey('explore-preference-${parent.id}'),
                            value: preference,
                            borderRadius: BorderRadius.circular(2),
                            backgroundColor: colors.surfaceContainerHighest,
                            color: ExploreStyle.evolution(theme),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        parent.preference
                            .toStringAsFixed(2)
                            .replaceFirst(RegExp(r'0$'), ''),
                        style: StudioTypography.data.copyWith(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
