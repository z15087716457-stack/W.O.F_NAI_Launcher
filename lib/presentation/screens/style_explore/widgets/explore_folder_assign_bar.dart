import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_input_dialog.dart';

/// 弹出命名框新建候选文件夹；取消或失败返回 null。
Future<ExploreCandidateFolder?> promptCreateExploreFolder(
  BuildContext context,
  WidgetRef ref,
  String runId,
) async {
  final l10n = context.l10n;
  final name = await ThemedInputDialog.show(
    context: context,
    title: l10n.styleExplore_newFolder,
    labelText: l10n.styleExplore_folderNameLabel,
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

/// 候选「归类到」区：文件夹横排按钮 + 新建文件夹。
///
/// 点文件夹即归档落盘；再点当前所属文件夹 = 移回未分类。
/// 详情弹窗与批量管理弹窗（FEAT-42）共用。
class ExploreFolderAssignBar extends ConsumerWidget {
  const ExploreFolderAssignBar({
    super.key,
    required this.run,
    required this.candidate,
    this.onAssigned,
  });

  final ExploreRun run;
  final ExploreCandidate candidate;

  /// 归档成功（含移回未分类）后回调，供宿主跳到下一张未分类项。
  final void Function(String? folderId)? onAssigned;

  Future<void> _assign(
    BuildContext context,
    WidgetRef ref,
    String? folderId,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.styleExplore_assignToFolder,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final folder in run.folders)
              FilterChip(
                key: Key('explore-assign-folder-${folder.id}'),
                label: Text(folder.name),
                avatar: const Icon(Icons.folder_outlined, size: 16),
                selected: candidate.folderId == folder.id,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => _assign(
                  context,
                  ref,
                  candidate.folderId == folder.id ? null : folder.id,
                ),
              ),
            IconButton(
              key: const Key('explore-assign-new-folder'),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              tooltip: l10n.styleExplore_newFolder,
              onPressed: () async {
                final folder = await promptCreateExploreFolder(
                  context,
                  ref,
                  run.id,
                );
                if (folder == null || !context.mounted) return;
                await _assign(context, ref, folder.id);
              },
              icon: const Icon(Icons.create_new_folder_outlined),
            ),
          ],
        ),
      ],
    );
  }
}
