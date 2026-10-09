import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/style_explore/explore_manual_capture.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import '../../../widgets/common/themed_input_dialog.dart';

/// 探索切换菜单与舞台顶栏共用的界面动作。
abstract final class ExploreRunActions {
  /// 状态点颜色（draft 灰/generating 蓝/paused 橙/generated 绿/
  /// completed 青/cancelled 红）；存量 `reviewing` 按 generated 处理。
  static Color statusColor(ColorScheme scheme, ExploreRunStatus status) {
    switch (status) {
      case ExploreRunStatus.draft:
        return scheme.onSurfaceVariant;
      case ExploreRunStatus.generating:
        return Colors.blue;
      case ExploreRunStatus.paused:
        return Colors.orange;
      case ExploreRunStatus.generated:
      case ExploreRunStatus.reviewing:
        return Colors.green;
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
      case ExploreRunStatus.reviewing:
        return l10n.styleExplore_runStatusGenerated;
      case ExploreRunStatus.completed:
        return l10n.styleExplore_runStatusCompleted;
      case ExploreRunStatus.cancelled:
        return l10n.styleExplore_runStatusCancelled;
    }
  }

  static Future<void> start(
    BuildContext context,
    WidgetRef ref,
    ExploreRun run,
  ) async {
    final started = await ref
        .read(exploreRunRunnerProvider.notifier)
        .start(run.id);
    if (!started && context.mounted) {
      AppToast.info(context, context.l10n.styleExplore_runBusy);
    }
  }

  static Future<void> retryFailed(
    BuildContext context,
    WidgetRef ref,
    ExploreRun run,
  ) async {
    final started = await ref
        .read(exploreRunRunnerProvider.notifier)
        .retryFailed(run.id);
    if (!started && context.mounted) {
      AppToast.info(context, context.l10n.styleExplore_runBusy);
    }
  }

  static Future<void> cancel(
    BuildContext context,
    WidgetRef ref,
    ExploreRun run,
  ) async {
    final l10n = context.l10n;
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: l10n.styleExplore_cancelRunTitle,
      content: l10n.styleExplore_cancelRunMessage,
      confirmText: l10n.styleExplore_cancelRun,
      cancelText: l10n.common_cancel,
    );
    if (!confirmed || !context.mounted) return;
    final runner = ref.read(exploreRunRunnerProvider);
    final capture = ref.read(exploreManualCaptureProvider);
    if (runner.isRunning && runner.runId == run.id) {
      ref.read(exploreRunRunnerProvider.notifier).cancel();
    } else if (capture.armed &&
        capture.runId == run.id &&
        ref.read(imageGenerationNotifierProvider).isGenerating) {
      ref.read(imageGenerationNotifierProvider.notifier).cancel();
    } else {
      await ref
          .read(exploreRunListNotifierProvider.notifier)
          .cancelPaused(run.id);
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

    // 正在跑的 run 先取消（终态化），并等会话 finalize 收尾再删目录——
    // 在途写盘落进已删目录会变孤儿文件。
    final runner = ref.read(exploreRunRunnerProvider);
    if (runner.isRunning && runner.runId == run.id) {
      ref.read(exploreRunRunnerProvider.notifier).cancel();
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!context.mounted || !ref.read(exploreRunRunnerProvider).isRunning) {
          break;
        }
      }
    }
    // 手动登记会话挂在本 run 上时一并解除（其候选壳随 run 删除消失）。
    final capture = ref.read(exploreManualCaptureProvider);
    if (capture.armed && capture.runId == run.id) {
      ref.read(exploreManualCaptureProvider.notifier).cancelSession();
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
