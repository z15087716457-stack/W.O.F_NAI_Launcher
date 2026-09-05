import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import 'explore_run_actions.dart';

/// 中栏顶部 Run 控制条（activeRun 非空时显示）。
///
/// 按钮按状态显隐：generating=暂停+取消 / paused=继续+取消；
/// 失败重试与 More 菜单保留。基础轮批量入口统一由底部主生成控制条承载。
class ExploreRunControlBar extends ConsumerStatefulWidget {
  const ExploreRunControlBar({super.key, required this.run});

  final ExploreRun run;

  @override
  ConsumerState<ExploreRunControlBar> createState() =>
      _ExploreRunControlBarState();
}

class _ExploreRunControlBarState extends ConsumerState<ExploreRunControlBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final run = widget.run;
    final runnerState = ref.watch(exploreRunRunnerProvider);
    final isRunningThis = runnerState.isRunning && runnerState.runId == run.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Wrap(
        key: const Key('explore-run-control-bar-content'),
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: ExploreRunActions.statusColor(
                    theme.colorScheme,
                    run.status,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    run.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isRunningThis
                ? l10n.styleExplore_runGeneratingProgress(
                    (runnerState.processedCount + 1).clamp(
                      1,
                      runnerState.totalCount,
                    ),
                    runnerState.totalCount,
                  )
                : l10n.styleExplore_runTotalCount(run.candidates.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          ..._buildActionButtons(context, l10n, run, isRunningThis),
          _buildMoreMenu(context, l10n, run),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    AppLocalizations l10n,
    ExploreRun run,
    bool isRunningThis,
  ) {
    switch (run.status) {
      case ExploreRunStatus.draft:
        return const [];
      case ExploreRunStatus.generating:
        if (!isRunningThis) return const [];
        return [
          FilledButton.tonalIcon(
            key: const Key('explore-run-pause'),
            onPressed: () =>
                ref.read(exploreRunRunnerProvider.notifier).pause(),
            icon: const Icon(Icons.pause, size: 18),
            label: Text(l10n.styleExplore_pauseRun),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            key: const Key('explore-run-cancel'),
            onPressed: () => _confirmCancel(run),
            icon: const Icon(Icons.stop, size: 18),
            label: Text(l10n.common_cancel),
          ),
        ];
      case ExploreRunStatus.paused:
        return [
          FilledButton.tonalIcon(
            key: const Key('explore-run-resume'),
            onPressed: () => _start(run.id),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: Text(l10n.common_continue),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            key: const Key('explore-run-cancel'),
            onPressed: () => _confirmCancel(run),
            icon: const Icon(Icons.stop, size: 18),
            label: Text(l10n.common_cancel),
          ),
        ];
      case ExploreRunStatus.generated:
        return run.failedCount > 0
            ? [
                FilledButton.tonalIcon(
                  key: const Key('explore-run-retry'),
                  onPressed: () => _retryFailed(run.id),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.styleExplore_retryFailed(run.failedCount)),
                ),
              ]
            : const [];
      case ExploreRunStatus.reviewing:
      case ExploreRunStatus.completed:
      case ExploreRunStatus.cancelled:
        return const [];
    }
  }

  Widget _buildMoreMenu(
    BuildContext context,
    AppLocalizations l10n,
    ExploreRun run,
  ) {
    return PopupMenuButton<String>(
      key: const Key('explore-run-actions'),
      iconSize: 18,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'load',
          child: Text(l10n.styleExplore_loadSnapshot),
        ),
        PopupMenuItem(value: 'rename', child: Text(l10n.styleExplore_rename)),
        PopupMenuItem(
          value: 'archive',
          child: Text(
            run.isArchived
                ? l10n.styleExplore_unarchive
                : l10n.styleExplore_archive,
          ),
        ),
        PopupMenuItem(value: 'delete', child: Text(l10n.common_delete)),
      ],
      onSelected: (action) {
        switch (action) {
          case 'load':
            ExploreRunActions.loadSnapshot(context, ref, run);
          case 'rename':
            ExploreRunActions.rename(context, ref, run);
          case 'archive':
            ExploreRunActions.toggleArchive(ref, run);
          case 'delete':
            ExploreRunActions.delete(context, ref, run);
        }
      },
    );
  }

  Future<void> _start(String runId) async {
    final l10n = context.l10n;
    final started = await ref
        .read(exploreRunRunnerProvider.notifier)
        .start(runId);
    if (!started && mounted) {
      AppToast.info(context, l10n.styleExplore_runBusy);
    }
  }

  Future<void> _retryFailed(String runId) async {
    final l10n = context.l10n;
    final started = await ref
        .read(exploreRunRunnerProvider.notifier)
        .retryFailed(runId);
    if (!started && mounted) {
      AppToast.info(context, l10n.styleExplore_runBusy);
    }
  }

  Future<void> _confirmCancel(ExploreRun run) async {
    final l10n = context.l10n;
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: l10n.styleExplore_cancelRunTitle,
      content: l10n.styleExplore_cancelRunMessage,
      confirmText: l10n.styleExplore_cancelRun,
      cancelText: l10n.common_cancel,
    );
    if (!confirmed) return;
    if (ref.read(exploreRunRunnerProvider).isRunning) {
      ref.read(exploreRunRunnerProvider.notifier).cancel();
    } else {
      // 暂停态直接终态化：剩余 pending 标记为已取消。
      await _cancelPausedRun(run);
    }
  }

  Future<void> _cancelPausedRun(ExploreRun run) async {
    final notifier = ref.read(exploreRunListNotifierProvider.notifier);
    var current = run;
    for (final candidate in current.pendingCandidates) {
      current = await notifier.updateGeneration(
        current.id,
        candidate.id,
        const ExploreCandidateGeneration(
          status: ExploreCandidateGenerationStatus.failed,
          error: 'cancelled',
        ),
      );
    }
    await notifier.overwrite(
      current.copyWith(
        status: ExploreRunStatus.cancelled,
        rounds: [
          for (final round in current.rounds)
            round.status == ExploreRoundStatus.generating
                ? round.copyWith(status: ExploreRoundStatus.cancelled)
                : round,
        ],
      ),
    );
  }
}
