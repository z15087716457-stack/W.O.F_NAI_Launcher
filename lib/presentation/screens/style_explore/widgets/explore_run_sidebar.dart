import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/generation/generation_params_notifier.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_input_dialog.dart';
import 'explore_run_actions.dart';

/// 左栏探索任务区：Run 列表 + 新建入口。
///
/// Run 快照是档案：点选只切换右栏候选与控制条目标，**不自动载入编辑器**；
/// 「载入快照到编辑器」是卡片菜单里的显式动作。
class ExploreRunSidebarSection extends ConsumerWidget {
  const ExploreRunSidebarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final listAsync = ref.watch(exploreRunListNotifierProvider);
    final activeRunId = ref.watch(exploreActiveRunIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.styleExplore_runSectionTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                key: const Key('style-explore-new-run'),
                tooltip: l10n.styleExplore_newRun,
                iconSize: 18,
                onPressed: () => _createRun(context, ref),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: listAsync.maybeWhen(
            data: (list) {
              final runs = list.runs;
              if (runs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.styleExplore_noRunsYet,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.styleExplore_runEmptyHint,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  for (final run in runs)
                    _ExploreRunCard(
                      key: ValueKey('explore-run-${run.id}'),
                      run: run,
                      selected: run.id == activeRunId,
                    ),
                ],
              );
            },
            orElse: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  /// 新建任务：从当前 main/negative lane + 主生成参数捕获快照建 draft Run。
  Future<void> _createRun(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await ThemedInputDialog.show(
      context: context,
      title: l10n.styleExplore_newRun,
      labelText: l10n.styleExplore_runNameLabel,
      hintText: l10n.styleExplore_runNameHint,
      validator: (value) =>
          value.trim().isEmpty ? l10n.styleExplore_nameRequired : null,
    );
    if (name == null || name.trim().isEmpty) return;

    final positive = ref.read(pillWorkspaceProvider(PillScopes.main)).document;
    final negative = ref
        .read(pillWorkspaceProvider(PillScopes.negative))
        .document;
    final params = ref.read(generationParamsNotifierProvider);

    try {
      final created = await ref
          .read(exploreRunListNotifierProvider.notifier)
          .create(
            name: name.trim(),
            recipeSnapshot: ExploreRecipeSnapshot(
              positive: positive,
              negative: negative,
            ),
            paramsSnapshot: ExploreParamsSnapshot.fromImageParams(params),
            targetCount: 10,
          );
      ref.read(exploreActiveRunIdProvider.notifier).state = created.id;
      if (context.mounted) {
        AppToast.success(
          context,
          l10n.styleExplore_runCreated(created.displayName),
        );
      }
    } catch (error) {
      AppLogger.e('Create explore run failed', error, null, 'StyleExplore');
      if (context.mounted) {
        AppToast.error(context, l10n.styleExplore_operationFailed);
      }
    }
  }
}

/// Run 卡片：状态点 + 名称 + 候选总数 + 更新时间 + 菜单。
class _ExploreRunCard extends ConsumerWidget {
  const _ExploreRunCard({super.key, required this.run, required this.selected});

  final ExploreRun run;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final statusColor = ExploreRunActions.statusColor(
      theme.colorScheme,
      run.status,
    );

    return Opacity(
      opacity: run.isArchived ? 0.55 : 1,
      child: ListTile(
        dense: true,
        selected: selected,
        contentPadding: const EdgeInsets.only(left: 12),
        leading: Icon(Icons.circle, size: 10, color: statusColor),
        minLeadingWidth: 14,
        title: Text(
          run.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${l10n.styleExplore_runTotalCount(run.candidates.length)}'
          ' · ${ExploreRunActions.statusLabel(l10n, run.status)}'
          '${run.isArchived ? ' · ${l10n.styleExplore_archivedTag}' : ''}'
          ' · ${_formatTime(run.updatedAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: PopupMenuButton<String>(
          key: Key('explore-run-menu-${run.id}'),
          iconSize: 18,
          tooltip: l10n.styleExplore_manageRecipes,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'load',
              child: Text(l10n.styleExplore_loadSnapshot),
            ),
            PopupMenuItem(
              value: 'rename',
              child: Text(l10n.styleExplore_rename),
            ),
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
        ),
        onTap: () {
          ref.read(exploreActiveRunIdProvider.notifier).state = run.id;
        },
      ),
    );
  }

  static String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
  }
}
