import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../providers/style_explore_provider.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import '../../../widgets/common/themed_input_dialog.dart';

/// 探索 Run 的共享界面动作（左栏卡片菜单与中栏控制条菜单共用）。
abstract final class ExploreRunActions {
  /// 状态点颜色（draft 灰/generating 蓝/paused 橙/generated 绿/
  /// reviewing 紫/completed 青/cancelled 红）。
  static Color statusColor(ColorScheme scheme, ExploreRunStatus status) {
    switch (status) {
      case ExploreRunStatus.draft:
        return scheme.onSurfaceVariant;
      case ExploreRunStatus.generating:
        return Colors.blue;
      case ExploreRunStatus.paused:
        return Colors.orange;
      case ExploreRunStatus.generated:
        return Colors.green;
      case ExploreRunStatus.reviewing:
        return Colors.purple;
      case ExploreRunStatus.completed:
        return Colors.teal;
      case ExploreRunStatus.cancelled:
        return scheme.error;
    }
  }

  static String statusLabel(AppLocalizations l10n, ExploreRunStatus status) {
    switch (status) {
      case ExploreRunStatus.draft:
        return l10n.styleExplore_runStatusDraft;
      case ExploreRunStatus.generating:
        return l10n.styleExplore_runStatusGenerating;
      case ExploreRunStatus.paused:
        return l10n.styleExplore_runStatusPaused;
      case ExploreRunStatus.generated:
        return l10n.styleExplore_runStatusGenerated;
      case ExploreRunStatus.reviewing:
        return l10n.styleExplore_runStatusReviewing;
      case ExploreRunStatus.completed:
        return l10n.styleExplore_runStatusCompleted;
      case ExploreRunStatus.cancelled:
        return l10n.styleExplore_runStatusCancelled;
    }
  }

  /// 把 Run 的提示词快照载入探索双 lane（档案快照覆盖当前编辑内容，
  /// 有未保存修改时先确认）。
  static Future<void> loadSnapshot(
    BuildContext context,
    WidgetRef ref,
    ExploreRun run,
  ) async {
    final l10n = context.l10n;
    if (ref.read(styleExploreDirtyProvider)) {
      final confirmed = await ThemedConfirmDialog.show(
        context: context,
        title: l10n.styleExplore_discardChangesTitle,
        content: l10n.styleExplore_discardChangesMessage,
        confirmText: l10n.styleExplore_discardChangesConfirm,
        cancelText: MaterialLocalizations.of(context).cancelButtonLabel,
      );
      if (!confirmed) return;
    }
    ref
        .read(pillWorkspaceProvider(PillScopes.explorePos).notifier)
        .restoreDocument(run.recipeSnapshot.positive);
    ref
        .read(pillWorkspaceProvider(PillScopes.exploreNeg).notifier)
        .restoreDocument(run.recipeSnapshot.negative);
    if (context.mounted) {
      AppToast.success(
        context,
        l10n.styleExplore_snapshotLoaded(run.displayName),
      );
    }
  }

  static Future<void> rename(
    BuildContext context,
    WidgetRef ref,
    ExploreRun run,
  ) async {
    final l10n = context.l10n;
    final name = await ThemedInputDialog.show(
      context: context,
      title: l10n.styleExplore_rename,
      labelText: l10n.styleExplore_runNameLabel,
      initialValue: run.displayName,
      validator: (value) =>
          value.trim().isEmpty ? l10n.styleExplore_nameRequired : null,
    );
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(exploreRunListNotifierProvider.notifier)
        .rename(run.id, name.trim());
  }

  static Future<void> toggleArchive(WidgetRef ref, ExploreRun run) {
    return ref
        .read(exploreRunListNotifierProvider.notifier)
        .setArchived(run.id, !run.isArchived);
  }

  /// 删除 Run（连带删候选图副本目录；图库源图不动）。
  static Future<void> delete(
    BuildContext context,
    WidgetRef ref,
    ExploreRun run,
  ) async {
    final l10n = context.l10n;
    final confirmed = await ThemedConfirmDialog.showDelete(
      context: context,
      itemName: run.displayName,
      title: l10n.styleExplore_deleteRunTitle,
      content: l10n.styleExplore_deleteRunMessage(run.displayName),
    );
    if (!confirmed) return;

    // 正在跑的 run 先取消（终态化），再删记录。
    final runner = ref.read(exploreRunRunnerProvider);
    if (runner.isRunning && runner.runId == run.id) {
      ref.read(exploreRunRunnerProvider.notifier).cancel();
    }
    try {
      await ref.read(exploreRunListNotifierProvider.notifier).delete(run.id);
      if (ref.read(exploreActiveRunIdProvider) == run.id) {
        ref.read(exploreActiveRunIdProvider.notifier).state = null;
      }
      if (context.mounted) {
        AppToast.success(
          context,
          l10n.styleExplore_runDeleted(run.displayName),
        );
      }
    } catch (error) {
      AppLogger.e('Delete explore run failed', error, null, 'StyleExplore');
      if (context.mounted) {
        AppToast.error(context, l10n.styleExplore_operationFailed);
      }
    }
  }
}
