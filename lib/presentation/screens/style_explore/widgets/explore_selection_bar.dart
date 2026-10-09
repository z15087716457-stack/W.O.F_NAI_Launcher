import 'package:flutter/material.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../widgets/library/library_selection_bar.dart';
import '../../../widgets/prompt/pills/dna_icon.dart';
import 'explore_icon.dart';
import 'explore_style.dart';
import '../../../widgets/common/studio_icons.dart';

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
  });
  final Key? groupKey;
  final int count;
  final bool allHearted;
  final VoidCallback onHeart, onGroup, onAdopt, onEvolve, onDelete, onExit;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n, theme = Theme.of(context);
    final hc = MediaQuery.highContrastOf(context);
    final foreground = ExploreStyle.evolutionForeground(
      theme,
      highContrast: hc,
    );
    return LibrarySelectionBar(
      selectedCount: count,
      selectionLabel: l10n.styleExplore_selectedCount(count),
      onExit: onExit,
      actions: [
        LibraryAction(
          key: const Key('explore-selection-heart'),
          label: allHearted
              ? l10n.styleExplore_unfavorite
              : l10n.styleExplore_filterHearted,
          icon: 'heart',
          iconWidget: Icon(
            StudioIcons.galleryHeart,
            size: 14,
            color: theme.colorScheme.surface,
          ),
          onPressed: onHeart,
        ),
        LibraryAction(
          key: groupKey ?? const Key('explore-selection-group'),
          label: l10n.styleExplore_groupLabel,
          icon: 'folder',
          trailing: const ExploreIcon('chevD', size: 12),
          onPressed: onGroup,
        ),
        LibraryAction(
          key: const Key('explore-gallery-merge-adopt'),
          label: l10n.styleExplore_saveBlock,
          icon: 'box',
          iconWidget: ExploreIcon(
            'box',
            size: 14,
            color: theme.colorScheme.surface,
          ),
          onPressed: onAdopt,
        ),
        LibraryAction(
          key: const Key('explore-gallery-create-family'),
          label: l10n.styleExplore_startEvolution,
          icon: 'evo',
          iconWidget: DnaIcon(size: 14, color: foreground),
          backgroundColor: ExploreStyle.evolution(theme, highContrast: hc),
          foregroundColor: foreground,
          onPressed: onEvolve,
        ),
        LibraryAction(
          key: const Key('explore-gallery-delete'),
          label: l10n.common_delete,
          icon: 'trash',
          destructive: true,
          onPressed: onDelete,
        ),
      ],
    );
  }
}
