import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_input_dialog.dart';
import '../../generation/widgets/resize_handle.dart';
import 'explore_preference_sort_dialog.dart';

/// 谱系区（阶段 D）：候选画廊顶部可折叠区。
///
/// 家族 chips 横排 + 选中家族的代际卡片列（父本集卡：串列表+缩略图+
/// 「创建候选轮」「排序」；候选堆卡：缩略图横排+「多选建分支」「新增一轮」）。
/// 无家族时整个面板不渲染（入口 = 画廊多选「建家族」）。
class ExploreLineagePanel extends ConsumerStatefulWidget {
  const ExploreLineagePanel({
    super.key,
    required this.run,
    required this.onOpenCandidate,
  });

  final ExploreRun run;

  /// 点击候选缩略图打开详情（由画廊注入，复用候选详情弹窗）。
  final void Function(ExploreCandidate candidate) onOpenCandidate;

  @override
  ConsumerState<ExploreLineagePanel> createState() =>
      _ExploreLineagePanelState();
}

class _ExploreLineagePanelState extends ConsumerState<ExploreLineagePanel> {
  bool _expanded = true;
  bool _branchSelecting = false;
  final Set<String> _branchSelected = {};

  @override
  void didUpdateWidget(covariant ExploreLineagePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换 run 时放弃进行中的分支选择（选择集属于旧 run 的候选堆）。
    if (oldWidget.run.id != widget.run.id &&
        (_branchSelecting || _branchSelected.isNotEmpty)) {
      _branchSelecting = false;
      _branchSelected.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final run = widget.run;
    final families = run.families;
    if (families.isEmpty) return const SizedBox.shrink();

    final watchedId = ref.watch(exploreActiveFamilyIdProvider);
    final family = run.familyById(watchedId ?? '') ?? families.last;
    final generations = exploreFamilyGenerations(run, family);
    final activeSet = run.parentSetById(family.activeParentSetId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: const Key('explore-lineage-toggle'),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            child: Row(
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${l10n.styleExplore_lineageTitle} · ${families.length}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final entry in families)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      key: Key('explore-family-chip-${entry.id}'),
                      label: Text(entry.name),
                      selected: entry.id == family.id,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() {
                        _exitBranchSelection();
                        ref.read(exploreActiveFamilyIdProvider.notifier).state =
                            entry.id;
                      }),
                    ),
                  ),
              ],
            ),
          ),
          // 代际卡片列：内容高度 session 可调（底部拖拽手柄），上限随
          // 窗口高度收缩，防止窄窗口把候选网格挤没。
          Builder(
            builder: (context) {
              final maxAllowed = (MediaQuery.sizeOf(context).height * 0.6)
                  .clamp(
                    exploreLineagePanelMinHeight,
                    exploreLineagePanelMaxHeight,
                  );
              final contentHeight = ref
                  .watch(exploreLineagePanelHeightProvider)
                  .clamp(exploreLineagePanelMinHeight, maxAllowed);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: contentHeight,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 4),
                      children: [
                        for (final generation in generations) ...[
                          _buildParentSetCard(
                            theme,
                            l10n,
                            run,
                            family,
                            generation,
                          ),
                          _buildPileCard(
                            theme,
                            l10n,
                            run,
                            family,
                            generation,
                            isActive: generation.parentSet.id == activeSet?.id,
                          ),
                        ],
                      ],
                    ),
                  ),
                  VerticalResizeHandle(
                    onDrag: (delta) {
                      final current = ref.read(
                        exploreLineagePanelHeightProvider,
                      );
                      ref
                          .read(exploreLineagePanelHeightProvider.notifier)
                          .state = (current + delta).clamp(
                        exploreLineagePanelMinHeight,
                        exploreLineagePanelMaxHeight,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
        Divider(height: 1, color: theme.dividerColor),
      ],
    );
  }

  // ==================== 父本集卡 ====================

  Widget _buildParentSetCard(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreRun run,
    ExploreFamily family,
    ExploreLineageGeneration generation,
  ) {
    final parentSet = generation.parentSet;
    final isActive = parentSet.status == ExploreParentSetStatus.active;
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 2),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.styleExplore_parentSetTitle(parentSet.generation),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                _StatusChip(
                  text: isActive
                      ? l10n.styleExplore_parentSetActive
                      : l10n.styleExplore_parentSetUsed,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                if (parentSet.branchName != null) ...[
                  const SizedBox(width: 4),
                  _StatusChip(
                    text: l10n.styleExplore_branchLabel(parentSet.branchName!),
                    color: theme.colorScheme.tertiary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            for (final parent in parentSet.parents)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ParentThumb(run: run, parent: parent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        parent.artistString,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    if (parent.preference != 1.0)
                      Text(
                        l10n.styleExplore_preferenceValue(
                          parent.preference.toStringAsFixed(2),
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            if (isActive) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    key: Key('explore-deep-round-${parentSet.id}'),
                    onPressed: () => _showDeepRoundDialog(family, parentSet),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: Text(l10n.styleExplore_createDeepRound),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: Key('explore-sort-parents-${parentSet.id}'),
                    onPressed: parentSet.parents.length >= 2
                        ? () => ExplorePreferenceSortDialog.show(
                            context,
                            runId: run.id,
                            parentSet: parentSet,
                          )
                        : null,
                    icon: const Icon(Icons.sort, size: 16),
                    label: Text(l10n.styleExplore_sortParents),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== 候选堆卡 ====================

  Widget _buildPileCard(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreRun run,
    ExploreFamily family,
    ExploreLineageGeneration generation, {
    required bool isActive,
  }) {
    final parentSet = generation.parentSet;
    final pile = generation.pile;
    // 分支选择状态只对活跃集的候选堆有效；切家族/卡片重建时清失效项。
    final pileIds = pile.map((c) => c.id).toSet();
    _branchSelected.removeWhere((id) => !pileIds.contains(id));

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.styleExplore_candidatePileTitle(
                      parentSet.generation + 1,
                      pile.length,
                    ),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (generation.rounds.isNotEmpty)
                  Text(
                    l10n.styleExplore_roundsSummary(generation.rounds.length),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (pile.isEmpty)
              Text(
                l10n.styleExplore_pileEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: pile.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final candidate = pile[index];
                    return _PileThumb(
                      candidate: candidate,
                      selecting: _branchSelecting,
                      selected: _branchSelected.contains(candidate.id),
                      onTap: () {
                        if (_branchSelecting) {
                          setState(() {
                            if (!_branchSelected.remove(candidate.id)) {
                              _branchSelected.add(candidate.id);
                            }
                          });
                        } else {
                          widget.onOpenCandidate(candidate);
                        }
                      },
                    );
                  },
                ),
              ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (!_branchSelecting)
                    Tooltip(
                      // 轮次未完成/空堆时禁用并说明原因。
                      message: exploreParentSetRoundsComplete(run, parentSet)
                          ? ''
                          : l10n.styleExplore_branchRoundsIncomplete,
                      child: OutlinedButton.icon(
                        key: const Key('explore-branch-select'),
                        onPressed:
                            pile.isEmpty ||
                                !exploreParentSetRoundsComplete(run, parentSet)
                            ? null
                            : () => setState(() => _branchSelecting = true),
                        icon: const Icon(Icons.call_split, size: 16),
                        label: Text(l10n.styleExplore_branchSelect),
                      ),
                    )
                  else ...[
                    FilledButton.tonalIcon(
                      key: const Key('explore-branch-confirm'),
                      onPressed: _branchSelected.isEmpty
                          ? null
                          : () => _createBranch(family, parentSet),
                      icon: const Icon(Icons.call_split, size: 16),
                      label: Text(
                        '${l10n.styleExplore_createBranch}'
                        ' (${_branchSelected.length})',
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      key: const Key('explore-branch-cancel'),
                      tooltip: l10n.common_cancel,
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      onPressed: _exitBranchSelection,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    key: Key('explore-pile-another-${parentSet.id}'),
                    onPressed: () => _showDeepRoundDialog(family, parentSet),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l10n.styleExplore_anotherDeepRound),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _exitBranchSelection() {
    setState(() {
      _branchSelecting = false;
      _branchSelected.clear();
    });
  }

  // ==================== 深度轮 ====================

  Future<void> _showDeepRoundDialog(
    ExploreFamily family,
    ExploreParentSet parentSet,
  ) async {
    final l10n = context.l10n;
    final minCount = parentSet.parents.length;
    final controller = TextEditingController(text: '${minCount + 1}');
    final count = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('explore-deep-round-dialog'),
          title: Text(l10n.styleExplore_deepRoundTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.styleExplore_deepRoundCountHint(minCount),
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('explore-deep-round-count'),
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.styleExplore_targetCountLabel,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.common_cancel),
            ),
            FilledButton(
              key: const Key('explore-deep-round-confirm'),
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value < minCount) {
                  AppToast.warning(
                    dialogContext,
                    l10n.styleExplore_deepRoundCountHint(minCount),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(value.clamp(minCount, 50));
              },
              child: Text(l10n.styleExplore_createDeepRound),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (count == null || !mounted) return;

    try {
      final started = await ref
          .read(exploreRunRunnerProvider.notifier)
          .startDeepRound(
            widget.run.id,
            familyId: family.id,
            parentSetId: parentSet.id,
            count: count,
          );
      if (!started && mounted) {
        AppToast.info(context, l10n.styleExplore_runBusy);
      }
    } on ExploreDeepRoundException catch (error) {
      if (!mounted) return;
      final message = switch (error.reason) {
        ExploreDeepRoundRejection.noRandomInstance =>
          l10n.styleExplore_deepRoundNoInstance,
        ExploreDeepRoundRejection.mutationEmpty =>
          l10n.styleExplore_deepRoundEmpty,
        ExploreDeepRoundRejection.invalidParentSet =>
          l10n.styleExplore_operationFailed,
      };
      AppToast.error(context, message);
    }
  }

  // ==================== 建分支 ====================

  Future<void> _createBranch(
    ExploreFamily family,
    ExploreParentSet parentSet,
  ) async {
    final l10n = context.l10n;
    final name = await ThemedInputDialog.show(
      context: context,
      title: l10n.styleExplore_createBranch,
      labelText: l10n.styleExplore_branchNameLabel,
    );
    if (name == null || !mounted) return;

    try {
      final newSet = await ref
          .read(exploreRunListNotifierProvider.notifier)
          .createBranch(
            widget.run.id,
            familyId: family.id,
            selectedCandidateIds: _branchSelected.toList(),
            branchName: name.trim().isEmpty ? null : name.trim(),
          );
      if (mounted) {
        AppToast.success(
          context,
          l10n.styleExplore_branchCreated(newSet.parents.length),
        );
        _exitBranchSelection();
      }
    } on StateError catch (error) {
      if (!mounted) return;
      final reason = error.message;
      final message = reason.contains('未完成')
          ? l10n.styleExplore_branchRoundsIncomplete
          : reason.contains('最新代')
          ? l10n.styleExplore_branchNeedLatest
          : reason.contains('完全重复')
          ? l10n.styleExplore_branchDuplicate
          : reason.contains('至少')
          ? l10n.styleExplore_branchEmpty
          : l10n.styleExplore_operationFailed;
      AppToast.error(context, message);
    }
  }
}

/// 父本来源候选的小缩略图（无来源/无图时显示文本图标）。
class _ParentThumb extends StatelessWidget {
  const _ParentThumb({required this.run, required this.parent});

  final ExploreRun run;
  final ExploreParent parent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filePath = parent.sourceCandidateId == null
        ? null
        : run.candidateById(parent.sourceCandidateId!)?.generation.filePath;
    final placeholder = Icon(
      Icons.text_snippet_outlined,
      size: 14,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 24,
        height: 24,
        child: filePath == null
            ? ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: placeholder,
              )
            : Image.file(
                File(filePath),
                fit: BoxFit.cover,
                cacheWidth: 96,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: placeholder,
                ),
              ),
      ),
    );
  }
}

/// 候选堆缩略图：完成态显示图，pending/failed 显示状态图标；
/// 分支选择模式叠勾选圈。
class _PileThumb extends StatelessWidget {
  const _PileThumb({
    required this.candidate,
    required this.selecting,
    required this.selected,
    required this.onTap,
  });

  final ExploreCandidate candidate;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filePath = candidate.generation.filePath;
    final Widget content;
    if (candidate.generation.status == ExploreCandidateGenerationStatus.done &&
        filePath != null) {
      content = Image.file(
        File(filePath),
        fit: BoxFit.cover,
        cacheWidth: 192,
        errorBuilder: (context, error, stackTrace) =>
            _placeholder(theme, Icons.broken_image_outlined),
      );
    } else {
      content = _placeholder(theme, switch (candidate.generation.status) {
        ExploreCandidateGenerationStatus.pending => Icons.hourglass_empty,
        ExploreCandidateGenerationStatus.failed => Icons.error_outline,
        ExploreCandidateGenerationStatus.done => Icons.broken_image_outlined,
      });
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            fit: StackFit.expand,
            children: [
              content,
              if (selected)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              if (selecting)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme, IconData icon) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
