import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../ui/explore_branch_dialog.dart';
import '../ui/explore_family_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_view_state.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';

final _openBranchDialogs = <String>{};

Future<void> breedExploreNextGeneration(
  BuildContext context,
  WidgetRef ref,
  ExploreRun run, {
  Set<String>? ids,
}) async {
  final family =
      run.familyById(ref.read(exploreActiveFamilyIdProvider) ?? '') ??
      run.families.lastOrNull;
  if (family == null) return;
  final currentSelection = ref.read(exploreSelectionProvider);
  final selected = (ids ?? currentSelection).toList();
  final l10n = context.l10n;
  final key = '${run.id}/${family.id}';
  if (!_openBranchDialogs.add(key)) return;
  try {
    final name = await showExploreBranchDialog(context);
    if (name == null || !context.mounted) return;
    try {
      final next = await ref
          .read(exploreRunListNotifierProvider.notifier)
          .createBranch(
            run.id,
            familyId: family.id,
            selectedCandidateIds: selected,
            branchName: name.trim().isEmpty ? null : name.trim(),
          );
      if (!context.mounted) return;
      AppToast.success(
        context,
        l10n.styleExplore_branchCreated(next.parents.length),
      );
      if (ref.read(exploreActiveRunIdProvider) == run.id &&
          (ref.read(exploreActiveFamilyIdProvider) == null ||
              ref.read(exploreActiveFamilyIdProvider) == family.id)) {
        ref.read(exploreSelectionProvider.notifier).clear();
        ref.read(exploreSelectionModeProvider.notifier).state = false;
      }
    } on StateError catch (error) {
      if (!context.mounted) return;
      final reason = error.message;
      AppToast.error(
        context,
        reason.contains('未完成')
            ? l10n.styleExplore_branchRoundsIncomplete
            : reason.contains('最新代')
            ? l10n.styleExplore_branchNeedLatest
            : reason.contains('完全重复')
            ? l10n.styleExplore_branchDuplicate
            : reason.contains('至少')
            ? l10n.styleExplore_branchEmpty
            : l10n.styleExplore_operationFailed,
      );
    }
  } finally {
    _openBranchDialogs.remove(key);
  }
}

Future<void> showExploreFamilyMenu(
  BuildContext context,
  WidgetRef ref,
  ExploreRun run,
  ExploreFamily target,
  Offset position,
) async {
  final l10n = context.l10n;
  final choice = await chooseExploreFamilyAction(context, position);
  if (choice != 'delete' || !context.mounted) return;
  final setIds = {
    for (final set in run.parentSets)
      if (set.familyId == target.id) set.id,
  };
  final count = run.candidates
      .where((c) => setIds.contains(run.roundById(c.roundId)?.parentSetId))
      .length;
  final confirmed = await ThemedConfirmDialog.show(
    context: context,
    title: l10n.styleExplore_deleteFamily,
    content: l10n.styleExplore_deleteFamilyMessage(target.name, count),
    confirmText: l10n.common_delete,
    type: ThemedConfirmDialogType.danger,
    icon: Icons.delete_outline,
  );
  if (!confirmed || !context.mounted) return;
  try {
    await ref
        .read(exploreRunListNotifierProvider.notifier)
        .deleteFamily(run.id, target.id);
  } on StateError catch (e) {
    if (context.mounted) {
      AppToast.error(
        context,
        e.message.contains('未完成')
            ? l10n.styleExplore_familyBusy
            : l10n.styleExplore_operationFailed,
      );
    }
  }
}
