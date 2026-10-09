import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../providers/style_explore_provider.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import 'explore_adopt_block_dialog.dart';

/// 探索候选的出口动作（收编为块 / 导入元数据 / 删除候选图），
/// 候选详情弹窗与画廊多选条共用。
abstract final class ExploreCandidateActions {
  /// 单候选收编为块：内容 = `rollSnapshot.positive` 原文，
  /// 默认名 = run 名 + 候选序号。返回是否实际建块。
  static Future<bool> adoptSingle(
    BuildContext context,
    WidgetRef ref, {
    required ExploreRun run,
    required ExploreCandidate candidate,
  }) async {
    final positive = candidate.rollSnapshot?.positive;
    if (positive == null || positive.trim().isEmpty) {
      AppToast.warning(context, context.l10n.styleExplore_adoptBlockEmpty);
      return false;
    }
    final sequence = run.candidates.indexWhere((c) => c.id == candidate.id) + 1;
    return _adopt(
      context,
      ref,
      defaultTitle: '${run.displayName} #$sequence',
      content: positive,
    );
  }

  /// 多选合并收编：多候选 roll 正向串合并去重成一块。返回是否实际建块。
  static Future<bool> adoptMerged(
    BuildContext context,
    WidgetRef ref, {
    required ExploreRun run,
    required List<ExploreCandidate> candidates,
  }) async {
    final content = mergeExploreRollPositives([
      for (final candidate in candidates)
        if (candidate.rollSnapshot?.positive case final positive?) positive,
    ]);
    if (content.isEmpty) {
      if (context.mounted) {
        AppToast.warning(context, context.l10n.styleExplore_adoptBlockEmpty);
      }
      return false;
    }
    return _adopt(
      context,
      ref,
      defaultTitle: '${run.displayName} ×${candidates.length}',
      content: content,
    );
  }

  static Future<bool> _adopt(
    BuildContext context,
    WidgetRef ref, {
    required String defaultTitle,
    required String content,
  }) async {
    final result = await ExploreAdoptBlockDialog.show(
      context,
      initialTitle: defaultTitle,
      contentPreview: content,
    );
    if (result == null) return false;
    try {
      await ref
          .read(promptBlockLibraryNotifierProvider.notifier)
          .createBlock(
            title: result.title,
            content: content,
            color: result.color,
            iconName: result.iconName,
          );
      if (context.mounted) {
        AppToast.success(
          context,
          context.l10n.styleExplore_adoptBlockSaved(result.title),
        );
      }
      return true;
    } catch (error) {
      AppLogger.e(
        'Adopt explore candidate as block failed',
        error,
        null,
        'StyleExplore',
      );
      if (context.mounted) {
        AppToast.error(context, context.l10n.styleExplore_operationFailed);
      }
      return false;
    }
  }

  /// 导入元数据：roll 正向串灌进 main lane（纯文本重建，负向不动）。
  /// main/negative lane 有未备份内容时先覆盖确认（与 Recipe 载入同款）。
  static Future<void> fixateAsTemplate(
    BuildContext context,
    WidgetRef ref, {
    required ExploreCandidate candidate,
  }) async {
    final positive = candidate.rollSnapshot?.positive;
    if (positive == null) return;
    final l10n = context.l10n;
    // runner 会话逐张读主工作区投影；导入元数据会覆写 main lane，
    // 使后续候选脱离 run 快照语义（深度轮还会丢 override marker）——
    // 运行中禁止。
    if (ref.read(exploreRunRunnerProvider).isRunning) {
      AppToast.info(context, l10n.styleExplore_runBusy);
      return;
    }
    if (ref.read(styleExploreNeedsOverwriteConfirmProvider)) {
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
        .read(pillWorkspaceProvider(PillScopes.main).notifier)
        .replaceWithPlainText(positive);
    if (context.mounted) {
      AppToast.success(context, context.l10n.styleExplore_appliedToEditor);
    }
  }

  /// 删图 = 连记录删（FEAT-55）：删 run 目录副本文件 + 移除候选记录。
  static Future<void> deleteImage(
    BuildContext context,
    WidgetRef ref, {
    required String runId,
    required ExploreCandidate candidate,
  }) async {
    final filePath = candidate.generation.filePath;
    if (filePath == null) return;
    final l10n = context.l10n;
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: l10n.styleExplore_deleteImageTitle,
      content: l10n.styleExplore_deleteImageMessage,
      confirmText: l10n.styleExplore_deleteImage,
      type: ThemedConfirmDialogType.danger,
      icon: Icons.delete_outline,
    );
    if (!confirmed) return;
    try {
      final deleted = await ref
          .read(exploreRunImageStoreProvider)
          .deleteCandidateImage(filePath);
      if (!deleted) {
        if (context.mounted) {
          AppToast.error(context, context.l10n.styleExplore_operationFailed);
        }
        return;
      }
      // FEAT-55 拍板 = 连记录删：副本删成功后整条候选记录移除
      // （清 rounds.candidateIds / lineage.parentCandidateIds 引用）。
      await ref
          .read(exploreRunListNotifierProvider.notifier)
          .removeCandidates(runId, [candidate.id]);
      if (context.mounted) {
        AppToast.success(context, context.l10n.styleExplore_deleteImageDone);
      }
    } catch (error) {
      AppLogger.e(
        'Delete explore candidate image failed',
        error,
        null,
        'StyleExplore',
      );
      if (context.mounted) {
        AppToast.error(context, context.l10n.styleExplore_operationFailed);
      }
    }
  }
}
