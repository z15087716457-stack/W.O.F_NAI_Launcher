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
import '../../../widgets/common/themed_confirm_dialog.dart';
import '../../../widgets/common/themed_input_dialog.dart';
import '../../generation/widgets/resize_handle.dart';
import 'explore_candidate_hover_preview.dart';
import 'explore_parent_list.dart';
import 'horizontal_edge_fade.dart';
import 'explore_pile_manage_dialog.dart';
import 'explore_preference_sort_dialog.dart';

/// 谱系区（阶段 D）：候选画廊顶部可折叠区。
///
/// 家族 chips 横排 + 选中家族的代际卡片列（父本集卡：父本两列限高列表+
/// 「生成候选图」+出图数框+「A/B 组对照」；候选堆卡：缩略图横排+「多选建分支」）。
/// 无家族时整个面板不渲染（入口 = 画廊多选「建家族」）。
class ExploreLineagePanel extends ConsumerStatefulWidget {
  const ExploreLineagePanel({
    super.key,
    required this.run,
    required this.onOpenCandidate,
    this.hoverSession,
  });

  final ExploreRun run;

  /// 点击候选缩略图打开详情（由画廊注入，复用候选详情弹窗）。
  final void Function(ExploreCandidate candidate) onOpenCandidate;

  /// 候选堆缩略图悬停预览会话（FEAT-41）；null = 不启用预览
  /// （组件级测试与复用场景可不传）。
  final ExploreCandidateHoverSession? hoverSession;

  @override
  ConsumerState<ExploreLineagePanel> createState() =>
      _ExploreLineagePanelState();
}

class _ExploreLineagePanelState extends ConsumerState<ExploreLineagePanel> {
  bool _expanded = true;
  bool _branchSelecting = false;
  final Set<String> _branchSelected = {};

  /// 建分支在飞（命名对话框敞开期间连点确认不重入）。
  var _branchSubmitting = false;

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
            child: HorizontalEdgeFade(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final entry in families)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        // 右键小菜单：删除整个谱系（家族 chip 的唯一出口，
                        // 左键点按/选择行为不变）
                        onSecondaryTapUp: (details) => _showFamilyMenu(
                          context,
                          run,
                          entry,
                          details.globalPosition,
                        ),
                        child: ChoiceChip(
                          key: Key('explore-family-chip-${entry.id}'),
                          label: Text(entry.name),
                          selected: entry.id == family.id,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) {
                            // 重按当前家族 chip 早退：不清掉进行中的分支选择。
                            if (entry.id == family.id) return;
                            _exitBranchSelection();
                            ref
                                .read(exploreActiveFamilyIdProvider.notifier)
                                .state = entry
                                .id;
                          },
                        ),
                      ),
                    ),
                ],
              ),
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
                            isActive: generation.parentSet.id == activeSet?.id,
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
    ExploreLineageGeneration generation, {
    required bool isActive,
  }) {
    final parentSet = generation.parentSet;
    // 「活跃」口径统一取家族 activeParentSetId 指针（深度轮/分支/对照
    // 都按它走），不另看 parentSet.status，避免两源不一致时 UI 分裂。
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
            ExploreParentList(
              parents: parentSet.parents,
              thumbBuilder: (parent) => _ParentThumb(run: run, parent: parent),
            ),
            if (isActive) ...[
              // 与上方父本串留足呼吸位：2px 时按钮行贴着文字。
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _DeepRoundControl(
                    key: ValueKey('explore-deep-round-control-${parentSet.id}'),
                    run: run,
                    family: family,
                    parentSet: parentSet,
                  ),
                  OutlinedButton.icon(
                    key: Key('explore-sort-parents-${parentSet.id}'),
                    onPressed: parentSet.parents.length >= 2
                        ? () => ExplorePreferenceSortDialog.show(
                            context,
                            runId: run.id,
                            parentSet: parentSet,
                          )
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
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
    // 展示层反转：与画廊/详情翻页同为「最新在前」（登记序与 #N 序号不动）。
    final pile = generation.pile.reversed.toList();
    // 分支选择只对活跃（最新代）候选堆有效（provider `createBranch` 硬校验
    // 只能从最新代选）：失效清理只由活跃堆执行，非活跃堆各清一遍会跨代误删
    // 活跃堆的选择。切家族的选择清空由家族 chip 的 _exitBranchSelection 负责。
    final pileIds = pile.map((c) => c.id).toSet();
    if (isActive) _branchSelected.removeWhere((id) => !pileIds.contains(id));
    // 已被收编为父本的候选（任一父本集的 sourceCandidateId）——堆内
    // 缩略图给角标，避免重复收编/误选。
    final adoptedIds = {
      for (final set in run.parentSets)
        for (final parent in set.parents)
          if (parent.sourceCandidateId case final id?) id,
    };

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
              // FEAT-57：单行横滚 → 最多三排折行 + 内部纵滚（无滚动条）+
              // ▲▼余量箭头；缩略图 64px、悬停/点按/分支勾选语义全不动。
              _PileThumbFlow(
                keyPrefix: 'explore-pile-${parentSet.id}',
                children: [
                  for (var index = 0; index < pile.length; index++)
                    () {
                      final candidate = pile[index];
                      final thumb = _PileThumb(
                        candidate: candidate,
                        // 勾选圈与点选只在活跃堆开放：非活跃堆的候选进不了
                        // provider 校验，点了也只落 StateError。
                        selecting: _branchSelecting && isActive,
                        selected: _branchSelected.contains(candidate.id),
                        adopted: adoptedIds.contains(candidate.id),
                        onTap: () {
                          if (_branchSelecting && isActive) {
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
                      // 悬停大图预览（FEAT-41）：外包一层，不改缩略图尺寸、
                      // 折行排布与点按/选择态；ValueKey 绑定候选防元素复用串位。
                      final session = widget.hoverSession;
                      if (session == null) return thumb;
                      final filePath =
                          candidate.generation.status ==
                              ExploreCandidateGenerationStatus.done
                          ? candidate.generation.filePath
                          : null;
                      final roundNumber = run
                          .roundById(candidate.roundId)
                          ?.number;
                      return ExploreCandidateHoverThumb(
                        key: ValueKey('pile-hover-${candidate.id}'),
                        session: session,
                        candidateId: candidate.id,
                        filePath: filePath,
                        badgeText:
                            '#${run.candidates.indexWhere((c) => c.id == candidate.id) + 1}'
                            '${roundNumber != null ? ' · ${l10n.styleExplore_roundNumber(roundNumber)}' : ''}',
                        child: thumb,
                      );
                    }(),
                ],
              ),
            // 按钮行：管理入口每个堆都有（含非活跃集）；分支组仅活跃集。
            if (pile.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (isActive)
                    if (!_branchSelecting)
                      Tooltip(
                        // 轮次未完成/空堆时禁用并说明原因。
                        message: exploreParentSetRoundsComplete(run, parentSet)
                            ? ''
                            : l10n.styleExplore_branchRoundsIncomplete,
                        child: OutlinedButton.icon(
                          key: const Key('explore-branch-select'),
                          onPressed:
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
                  const SizedBox(width: 4),
                  // 管理弹窗（FEAT-42）：大图网格/瀑布流 + 多选批量动作。
                  OutlinedButton.icon(
                    key: Key('explore-pile-manage-${parentSet.id}'),
                    onPressed: () => ExplorePileManageDialog.show(
                      context,
                      runId: run.id,
                      familyId: family.id,
                      parentSetId: parentSet.id,
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: Text(l10n.styleExplore_managePile),
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

  // ==================== 家族 chip 右键菜单 ====================

  /// 家族 chip 右键小菜单：当前只有「删除谱系」一项（整族删除，
  /// 家族是唯一有谱系归属语义的粒度）。
  Future<void> _showFamilyMenu(
    BuildContext context,
    ExploreRun run,
    ExploreFamily target,
    Offset globalPosition,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;
    final localPosition = overlay.globalToLocal(globalPosition);
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(localPosition, localPosition),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              context.l10n.styleExplore_deleteFamily,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    );
    if (choice == 'delete' && mounted) {
      await _deleteFamily(run, target);
    }
  }

  /// 整族删除：确认框带族名与候选计数；族内有在途候选时 provider
  /// 拒删（StateError「未完成」），提示先取消任务。
  Future<void> _deleteFamily(ExploreRun run, ExploreFamily target) async {
    final l10n = context.l10n;
    final setIds = {
      for (final set in run.parentSets)
        if (set.familyId == target.id) set.id,
    };
    final candidateCount = run.candidates
        .where((c) => setIds.contains(run.roundById(c.roundId)?.parentSetId))
        .length;
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: l10n.styleExplore_deleteFamily,
      content: l10n.styleExplore_deleteFamilyMessage(
        target.name,
        candidateCount,
      ),
      confirmText: l10n.common_delete,
      type: ThemedConfirmDialogType.danger,
      icon: Icons.delete_outline,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref
          .read(exploreRunListNotifierProvider.notifier)
          .deleteFamily(run.id, target.id);
    } on StateError catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        error.message.contains('未完成')
            ? l10n.styleExplore_familyBusy
            : l10n.styleExplore_operationFailed,
      );
    }
  }

  // ==================== 建分支 ====================

  Future<void> _createBranch(
    ExploreFamily family,
    ExploreParentSet parentSet,
  ) async {
    if (_branchSubmitting) return;
    _branchSubmitting = true;
    try {
      // 进对话框前快照目标 run 与选择集：开窗期间切 run 会让
      // _branchSelected 被 didUpdateWidget 清掉，快照保住本次意图。
      final runId = widget.run.id;
      final selectedIds = _branchSelected.toList();
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
              runId,
              familyId: family.id,
              selectedCandidateIds: selectedIds,
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
    } finally {
      _branchSubmitting = false;
    }
  }
}

/// 活跃父本集的生成入口：「生成候选图」+ 出图数小框（一步出图）。
///
/// 数字框自持 controller（`ValueKey(parentSet.id)` 保证切父本集重置默认值）；
/// 生成中按 runner 运行态禁用（`isRunning` 且 `runId` 匹配当前 run，跨 run
/// 不误伤），失败/完成由 runner 状态复位，不做点击后的局部禁用。
class _DeepRoundControl extends ConsumerStatefulWidget {
  const _DeepRoundControl({
    super.key,
    required this.run,
    required this.family,
    required this.parentSet,
  });

  final ExploreRun run;
  final ExploreFamily family;
  final ExploreParentSet parentSet;

  @override
  ConsumerState<_DeepRoundControl> createState() => _DeepRoundControlState();
}

class _DeepRoundControlState extends ConsumerState<_DeepRoundControl> {
  /// 出图数下限：每个父本保底一张（引擎约束）。
  int get _minCount => widget.parentSet.parents.length;

  late final TextEditingController _controller = TextEditingController(
    text: '${_minCount + 1}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final l10n = context.l10n;
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < _minCount) {
      AppToast.warning(
        context,
        l10n.styleExplore_deepRoundCountHint(_minCount),
      );
      return;
    }
    try {
      final started = await ref
          .read(exploreRunRunnerProvider.notifier)
          .startDeepRound(
            widget.run.id,
            familyId: widget.family.id,
            parentSetId: widget.parentSet.id,
            // 父本数 >50 时 _minCount 已超上限，上界抬到 _minCount
            // 防止 clamp 上下界倒置抛 ArgumentError。
            count: value.clamp(_minCount, _minCount > 50 ? _minCount : 50),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final runner = ref.watch(exploreRunRunnerProvider);
    final busy = runner.isRunning && runner.runId == widget.run.id;

    return Wrap(
      // 默认画廊宽下（卡内容区 ~328px）三件同排：改名后的「A/B 组对照」
      // 比原「排序」宽 ~30px，靠收紧按钮内边距 + 数字框让位（实测量得）。
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.tonalIcon(
          key: Key('explore-deep-round-${widget.parentSet.id}'),
          onPressed: busy ? null : _generate,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.play_arrow, size: 16),
          label: Text(l10n.styleExplore_createDeepRound),
        ),
        Tooltip(
          // 下限口径与点按校验同源（每个父本保底一张）。
          message: l10n.styleExplore_deepRoundCountHint(_minCount),
          child: SizedBox(
            width: 64,
            child: TextField(
              key: Key('explore-deep-round-count-${widget.parentSet.id}'),
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: l10n.styleExplore_targetCountLabel,
                // 标签常驻边框顶：窄框内联放不下「出图数」会截成「出…」。
                floatingLabelBehavior: FloatingLabelBehavior.always,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                if (!busy) _generate();
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 父本来源候选的小缩略图：无来源（自定义串）显示文本图标，有来源但
/// 图缺失/加载失败显示破图图标；悬停 tooltip 给完整父本串。
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
    // 图标区分两类占位：自定义串（无来源候选）vs 有来源但图缺失。
    final placeholder = Icon(
      parent.sourceCandidateId == null
          ? Icons.text_snippet_outlined
          : Icons.broken_image_outlined,
      size: 14,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Tooltip(
      message: parent.artistString,
      child: ClipRRect(
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
      ),
    );
  }
}

/// 候选堆缩略图：完成态显示图，pending/failed 显示状态图标（failed 悬停
/// 给错误原因）；已收编为父本的候选左下角叠谱系角标；分支选择模式叠勾选圈。
class _PileThumb extends StatelessWidget {
  const _PileThumb({
    required this.candidate,
    required this.selecting,
    required this.selected,
    required this.onTap,
    this.adopted = false,
  });

  final ExploreCandidate candidate;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;

  /// 已被收编为任一父本集的父本（sourceCandidateId 命中）。
  final bool adopted;

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
    // 失败态悬停给错误原因（无图可预览时 tooltip 是唯一信息出口）。
    final errorText =
        candidate.generation.status == ExploreCandidateGenerationStatus.failed
        ? candidate.generation.error
        : null;
    final Widget tailed = errorText == null || errorText.isEmpty
        ? content
        : Tooltip(message: errorText, child: content);

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
              tailed,
              if (adopted)
                const Positioned(left: 2, bottom: 2, child: _AdoptedBadge()),
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

/// 候选堆缩略图容器（FEAT-57）：64px 缩略图按可用宽折行、最多渲染三排，
/// 第 4 排起内部纵滚（不渲染滚动条）；右上/下缘各浮一枚小箭头提示该方向
/// 还有余量、点按平滑滚一行；不足三排时容器随内容收缩。
class _PileThumbFlow extends StatefulWidget {
  const _PileThumbFlow({required this.keyPrefix, required this.children});

  /// 箭头 key 前缀（一张谱系页有多张堆卡，按父本集 id 区分）。
  final String keyPrefix;
  final List<Widget> children;

  static const double thumbSize = 64;
  static const double gap = 6;
  static const double maxHeight = thumbSize * 3 + gap * 2;

  @override
  State<_PileThumbFlow> createState() => _PileThumbFlowState();
}

class _PileThumbFlowState extends State<_PileThumbFlow> {
  final ScrollController _controller = ScrollController();
  bool _canScrollUp = false;
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncArrows);
    // 首帧布局后才有 maxScrollExtent。
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncArrows());
  }

  @override
  void didUpdateWidget(covariant _PileThumbFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      // 堆内容变化后滚动范围变化，下一帧再同步箭头。
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncArrows());
    }
  }

  void _syncArrows() {
    if (!mounted || !_controller.hasClients) return;
    final pos = _controller.position;
    final canUp = pos.pixels > pos.minScrollExtent + 0.5;
    final canDown = pos.pixels < pos.maxScrollExtent - 0.5;
    if (canUp != _canScrollUp || canDown != _canScrollDown) {
      setState(() {
        _canScrollUp = canUp;
        _canScrollDown = canDown;
      });
    }
  }

  void _scrollBy(double delta) {
    final pos = _controller.position;
    _controller.animateTo(
      (pos.pixels + delta).clamp(pos.minScrollExtent, pos.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 外层 Column 是 crossAxisAlignment.start（松约束）：不锁满宽的话
    // shrinkWrap 列表按内容宽排成单行，永远只有一排。满宽后 Wrap 按
    // 可用宽折行，才是「最多三排」。
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _PileThumbFlow.maxHeight),
        child: Stack(
          children: [
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: ListView(
                controller: _controller,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  Wrap(
                    spacing: _PileThumbFlow.gap,
                    runSpacing: _PileThumbFlow.gap,
                    children: widget.children,
                  ),
                ],
              ),
            ),
            if (_canScrollUp)
              Positioned(
                top: 2,
                right: 2,
                child: _ScrollArrow(
                  key: Key('${widget.keyPrefix}-scroll-up'),
                  icon: Icons.keyboard_arrow_up,
                  color: theme.colorScheme.surface.withValues(alpha: 0.85),
                  iconColor: theme.colorScheme.onSurfaceVariant,
                  onTap: () => _scrollBy(
                    -(_PileThumbFlow.thumbSize + _PileThumbFlow.gap),
                  ),
                ),
              ),
            if (_canScrollDown)
              Positioned(
                bottom: 2,
                right: 2,
                child: _ScrollArrow(
                  key: Key('${widget.keyPrefix}-scroll-down'),
                  icon: Icons.keyboard_arrow_down,
                  color: theme.colorScheme.surface.withValues(alpha: 0.85),
                  iconColor: theme.colorScheme.onSurfaceVariant,
                  onTap: () =>
                      _scrollBy(_PileThumbFlow.thumbSize + _PileThumbFlow.gap),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScrollArrow extends StatelessWidget {
  const _ScrollArrow({
    super.key,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 20,
          height: 20,
          child: Icon(icon, size: 14, color: iconColor),
        ),
      ),
    );
  }
}

/// 「已收编为父本」角标：候选堆缩略图左下角的谱系小标。
class _AdoptedBadge extends StatelessWidget {
  const _AdoptedBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Icon(
        Icons.account_tree_outlined,
        size: 12,
        color: theme.colorScheme.tertiary,
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
