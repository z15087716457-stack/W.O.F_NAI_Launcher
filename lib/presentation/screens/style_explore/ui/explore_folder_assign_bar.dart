import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../actions/explore_group_actions.dart';
import 'explore_icon.dart';
import 'explore_style.dart';

export '../actions/explore_group_actions.dart' show promptCreateExploreFolder;

class ExploreFolderAssignBar extends ConsumerWidget {
  const ExploreFolderAssignBar({
    super.key,
    required this.run,
    required this.candidate,
    this.onAssigned,
  });
  final ExploreRun run;
  final ExploreCandidate candidate;
  final void Function(String?)? onAssigned;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).colorScheme, l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l.styleExplore_groupLabel,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: .23,
                color: c.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              l.styleExplore_quickGroupHint,
              style: TextStyle(
                fontSize: 11,
                color: ExploreStyle.faint(Theme.of(context)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (final folder in run.folders)
              ExploreGroupChip(
                key: Key('explore-assign-folder-${folder.id}'),
                label: folder.name,
                selected: candidate.folderId == folder.id,
                onTap: () => assignExploreGroup(
                  context,
                  ref,
                  run,
                  candidate,
                  candidate.folderId == folder.id ? null : folder.id,
                  onAssigned,
                ),
              ),
            ExploreGroupChip(
              key: const Key('explore-assign-new-folder'),
              label: l.styleExplore_newGroupChip,
              leading: ExploreIcon('plus', size: 12, color: c.onSurfaceVariant),
              onTap: () async {
                final folder = await promptCreateExploreFolder(
                  context,
                  ref,
                  run.id,
                );
                if (folder != null && context.mounted) {
                  await assignExploreGroup(
                    context,
                    ref,
                    run,
                    candidate,
                    folder.id,
                    onAssigned,
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class ExploreGroupChip extends StatelessWidget {
  const ExploreGroupChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.leading,
  });
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget? leading;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context),
        c = t.colorScheme,
        ink = selected ? c.primary : c.onSurfaceVariant;
    return Material(
      color: selected
          ? Color.alphaBlend(
              c.primary.withValues(alpha: .07),
              ExploreStyle.raised(t),
            )
          : ExploreStyle.raised(t),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: selected ? c.primary : c.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 26,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected || leading != null) ...[
                  selected
                      ? ExploreIcon(
                          'check',
                          size: 12,
                          strokeWidth: 2.6,
                          color: ink,
                        )
                      : leading!,
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    color: ink,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
