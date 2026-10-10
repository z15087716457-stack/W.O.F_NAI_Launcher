import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_input_dialog.dart';

Future<ExploreCandidateFolder?> promptCreateExploreFolder(
  BuildContext context,
  WidgetRef ref,
  String runId,
) async {
  final l10n = context.l10n;
  final name = await ThemedInputDialog.show(
    context: context,
    title: l10n.styleExplore_newGroupChip,
    labelText: l10n.styleExplore_groupLabel,
    validator: (value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return l10n.styleExplore_nameRequired;
      // 重名预检（provider 层同名硬校验兜底）。
      final run = ref
          .read(exploreRunListNotifierProvider)
          .valueOrNull
          ?.runById(runId);
      if (run != null && run.folders.any((f) => f.name == trimmed)) {
        return l10n.toast_renameNameConflict;
      }
      return null;
    },
  );
  if (name == null || name.trim().isEmpty) return null;
  try {
    final folder = await ref
        .read(exploreRunListNotifierProvider.notifier)
        .createFolder(runId, name);
    if (context.mounted) {
      AppToast.success(context, l10n.styleExplore_folderCreated(folder.name));
    }
    return folder;
  } catch (error) {
    AppLogger.e('Create explore folder failed', error, null, 'StyleExplore');
    if (context.mounted) {
      AppToast.error(context, l10n.styleExplore_operationFailed);
    }
    return null;
  }
}

Future<void> assignExploreGroup(
  BuildContext context,
  WidgetRef ref,
  ExploreRun run,
  ExploreCandidate candidate,
  String? folderId,
  void Function(String?)? onAssigned,
) async {
  final l10n = context.l10n;
  try {
    await ref
        .read(exploreRunListNotifierProvider.notifier)
        .assignCandidateFolder(run.id, candidate.id, folderId);
    onAssigned?.call(folderId);
  } catch (error) {
    AppLogger.e('Assign explore folder failed', error, null, 'StyleExplore');
    if (context.mounted) {
      AppToast.error(context, l10n.styleExplore_operationFailed);
    }
  }
}
