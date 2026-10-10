import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../../../../core/utils/localization_extension.dart';
import 'explore_controls.dart';
import 'explore_text.dart';
import 'explore_icon.dart';
import 'explore_style.dart';

class ExploreSelectionBar extends StatelessWidget {
  const ExploreSelectionBar({
    super.key,
    this.groupKey,
    required this.count,
    required this.allHearted,
    required this.onHeart,
    required this.onGroup,
    required this.onAdopt,
    required this.onEvolve,
    required this.onDelete,
    required this.onExit,
    this.evolutionLabel,
  });
  final Key? groupKey;
  final int count;
  final String? evolutionLabel;
  final bool allHearted;
  final VoidCallback onHeart, onGroup, onAdopt, onDelete, onExit;
  final VoidCallback? onEvolve;
  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    final fg = c.surface,
        bg = c.onSurface,
        purple = ExploreStyle.evolution(
          t,
          highContrast: MediaQuery.highContrastOf(context),
        );
    return LayoutBuilder(
      builder: (context, space) {
        final compact = space.maxWidth < 700;
        Widget divider() =>
            Container(width: 1, height: 20, color: fg.withValues(alpha: .25));
        Widget action(
          Key key,
          String label,
          String icon,
          VoidCallback? callback, {
          Color? background,
          Widget? trailing,
        }) => Tooltip(
          message: label,
          child: ExploreButton(
            key: key,
            height: 32,
            label: compact ? '' : label,
            horizontal: compact ? 9 : 11,
            icon: ExploreIcon(
              icon,
              size: 15,
              color: background == null
                  ? fg
                  : ExploreStyle.evolutionForeground(t),
            ),
            color: background == null
                ? fg
                : ExploreStyle.evolutionForeground(t),
            background: background ?? Colors.transparent,
            border: Colors.transparent,
            trailing: compact ? null : trailing,
            onPressed: callback,
          ),
        );
        return Align(
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: t.brightness == Brightness.dark ? .45 : .14,
                  ),
                  offset: const Offset(0, 10),
                  blurRadius: 30,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ExploreText(
                    l.styleExplore_selectedCount(count),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                divider(),
                const SizedBox(width: 6),
                action(
                  const Key('explore-selection-heart'),
                  allHearted
                      ? l.styleExplore_unfavorite
                      : l.styleExplore_filterHearted,
                  'heart',
                  onHeart,
                ),
                const SizedBox(width: 6),
                KeyedSubtree(
                  key: const Key('explore-gallery-group'),
                  child: action(
                    groupKey ?? const Key('explore-selection-group'),
                    l.styleExplore_groupLabel,
                    'folder',
                    onGroup,
                    trailing: ExploreIcon('chevD', size: 12, color: fg),
                  ),
                ),
                const SizedBox(width: 6),
                action(
                  const Key('explore-gallery-merge-adopt'),
                  l.styleExplore_saveBlock,
                  'box',
                  onAdopt,
                ),
                const SizedBox(width: 6),
                action(
                  const Key('explore-gallery-create-family'),
                  evolutionLabel ?? l.styleExplore_startEvolution,
                  'evo',
                  onEvolve,
                  background: purple,
                ),
                const SizedBox(width: 6),
                divider(),
                const SizedBox(width: 6),
                ExploreIconButton(
                  'trash',
                  key: const Key('explore-gallery-delete'),
                  width: 32,
                  height: 32,
                  size: 15,
                  color: ExploreStyle.heart(t),
                  tooltip: l.common_delete,
                  onPressed: onDelete,
                ),
                const SizedBox(width: 6),
                ExploreIconButton(
                  'x',
                  key: const Key('explore-selection-exit'),
                  width: 32,
                  height: 32,
                  size: 15,
                  color: fg,
                  tooltip: l.common_close,
                  onPressed: onExit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
