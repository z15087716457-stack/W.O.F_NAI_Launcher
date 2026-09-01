import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/generation/generation_params_notifier.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import 'explore_run_actions.dart';

/// 中栏 Run 控制条 + 参数摘要条（activeRun 非空时显示在顶栏下方）。
///
/// 按钮按状态显隐：draft=开始 / generating=暂停+取消 / paused=继续+取消 /
/// generated=重试失败（有失败时）。出图数与「同步自主生成页」仅草稿可编辑。
class ExploreRunControlBar extends ConsumerStatefulWidget {
  const ExploreRunControlBar({super.key, required this.run});

  final ExploreRun run;

  @override
  ConsumerState<ExploreRunControlBar> createState() =>
      _ExploreRunControlBarState();
}

class _ExploreRunControlBarState extends ConsumerState<ExploreRunControlBar> {
  late final TextEditingController _targetController;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(
      text: widget.run.targetCount.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant ExploreRunControlBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.run.id != widget.run.id ||
        oldWidget.run.targetCount != widget.run.targetCount) {
      _targetController.text = widget.run.targetCount.toString();
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final run = widget.run;
    final runnerState = ref.watch(exploreRunRunnerProvider);
    final isDraft = run.status == ExploreRunStatus.draft;
    final isRunningThis = runnerState.isRunning && runnerState.runId == run.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
              const SizedBox(width: 8),
              Text(
                isRunningThis
                    ? l10n.styleExplore_runGeneratingProgress(
                        (runnerState.processedCount + 1).clamp(
                          1,
                          runnerState.totalCount,
                        ),
                        runnerState.totalCount,
                      )
                    : l10n.styleExplore_runProgress(
                        run.generatedCount,
                        run.targetCount,
                      ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              ..._buildActionButtons(context, l10n, run, isRunningThis),
              _buildMoreMenu(context, l10n, run),
            ],
          ),
          const SizedBox(height: 8),
          _buildParamsSummary(theme, l10n, run, isDraft),
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
        return [
          FilledButton.tonalIcon(
            key: const Key('explore-run-start'),
            onPressed: () => _start(run.id),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: Text(l10n.styleExplore_startRun),
          ),
        ];
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
        if (run.failedCount == 0) return const [];
        return [
          FilledButton.tonalIcon(
            key: const Key('explore-run-retry'),
            onPressed: () => _retryFailed(run.id),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.styleExplore_retryFailed(run.failedCount)),
          ),
        ];
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

  /// 参数摘要条：快照字段只读 chips；draft 加出图数编辑与重新捕获按钮。
  Widget _buildParamsSummary(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreRun run,
    bool isDraft,
  ) {
    final snapshot = run.paramsSnapshot;
    final chipStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(snapshot.model, style: chipStyle),
        Text('${snapshot.width}×${snapshot.height}', style: chipStyle),
        Text('steps ${snapshot.steps}', style: chipStyle),
        Text('scale ${snapshot.scale}', style: chipStyle),
        Text(snapshot.sampler, style: chipStyle),
        if (isDraft) ...[
          const SizedBox(width: 4),
          Text('${l10n.styleExplore_targetCountLabel}:', style: chipStyle),
          SizedBox(
            width: 56,
            height: 32,
            child: TextField(
              key: const Key('explore-run-target-count'),
              controller: _targetController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: theme.textTheme.bodySmall,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                border: OutlineInputBorder(),
              ),
              onSubmitted: _submitTargetCount,
              onTapOutside: (_) => _submitTargetCount(_targetController.text),
            ),
          ),
          TextButton.icon(
            key: const Key('explore-run-sync-params'),
            onPressed: _syncParams,
            icon: const Icon(Icons.sync, size: 16),
            label: Text(l10n.styleExplore_syncParams),
          ),
        ],
      ],
    );
  }

  Future<void> _submitTargetCount(String raw) async {
    final value = int.tryParse(raw.trim());
    if (value == null) return;
    final clamped = value.clamp(1, 200);
    if (clamped == widget.run.targetCount) return;
    try {
      await ref
          .read(exploreRunListNotifierProvider.notifier)
          .updateTargetCount(widget.run.id, clamped);
    } catch (error) {
      AppLogger.e('Update target count failed', error, null, 'StyleExplore');
    }
  }

  Future<void> _syncParams() async {
    final l10n = context.l10n;
    try {
      final snapshot = ExploreParamsSnapshot.fromImageParams(
        ref.read(generationParamsNotifierProvider),
      );
      await ref
          .read(exploreRunListNotifierProvider.notifier)
          .syncParamsSnapshot(widget.run.id, snapshot);
      if (mounted) AppToast.success(context, l10n.styleExplore_paramsSynced);
    } catch (error) {
      AppLogger.e('Sync params snapshot failed', error, null, 'StyleExplore');
      if (mounted) {
        AppToast.error(context, l10n.styleExplore_operationFailed);
      }
    }
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
