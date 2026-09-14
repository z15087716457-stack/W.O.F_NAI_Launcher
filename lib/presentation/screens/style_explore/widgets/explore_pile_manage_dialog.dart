import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../../data/services/gallery/gallery_column_width_store.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/column_width_menu_panel.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import '../../../widgets/common/themed_input_dialog.dart';
import 'explore_candidate_actions.dart';
import 'explore_candidate_gallery.dart';
import 'explore_folder_assign_bar.dart';

/// 候选堆「管理」大弹窗（FEAT-42）：网格/瀑布流两档 + 列宽 + 多选全选
/// + 底部批量动作条（收藏/归类/合并收编/建分支/删图）。
///
/// 弹窗持 runId + parentSetId，数据按 id 实时解析（评审/删除/归类后
/// 自动刷新）；选择集为弹窗局部状态，关闭即清。
class ExplorePileManageDialog extends ConsumerStatefulWidget {
  const ExplorePileManageDialog({
    super.key,
    required this.runId,
    required this.familyId,
    required this.parentSetId,
  });

  final String runId;

  /// 建分支动作需要家族上下文（`createBranch` 按家族活跃集校验）。
  final String familyId;
  final String parentSetId;

  static Future<void> show(
    BuildContext context, {
    required String runId,
    required String familyId,
    required String parentSetId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ExplorePileManageDialog(
        runId: runId,
        familyId: familyId,
        parentSetId: parentSetId,
      ),
    );
  }

  @override
  ConsumerState<ExplorePileManageDialog> createState() =>
      _ExplorePileManageDialogState();
}

class _ExplorePileManageDialogState
    extends ConsumerState<ExplorePileManageDialog> {
  static const _columnWidthStore = GalleryColumnWidthStore(
    storageKey: StorageKeys.styleExplorePileColumnWidth,
  );

  bool _masonry = false;
  double _columnWidth = GalleryColumnWidthStore.defaultColumnWidth;
  final Set<String> _selected = {};

  /// 批量动作在飞（连点不重入）。
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _columnWidthStore.load().then((width) {
      if (mounted) setState(() => _columnWidth = width);
    });
  }

  /// 该堆候选（展示层反转 = 最新在前，与画廊/谱系堆一致）。
  List<ExploreCandidate> _pileOf(ExploreRun run) {
    final roundIds = {
      for (final round in run.rounds)
        if (round.parentSetId == widget.parentSetId) round.id,
    };
    return [
      for (final candidate in run.candidates)
        if (roundIds.contains(candidate.roundId)) candidate,
    ].reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final listAsync = ref.watch(exploreRunListNotifierProvider);
    final run = listAsync.valueOrNull?.runById(widget.runId);
    final parentSet = run?.parentSetById(widget.parentSetId);
    if (run == null || parentSet == null) {
      // 数据已加载但 run/父本集不在 → 被删 → 收窗；
      // 仍在加载时先空着，不可抢收（打开瞬间 provider 可能未落定）。
      if (listAsync.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
      return const SizedBox.shrink();
    }

    final pile = _pileOf(run);
    final pileIds = pile.map((c) => c.id).toSet();
    _selected.removeWhere((id) => !pileIds.contains(id));
    final family = run.familyById(widget.familyId);
    // 建分支只能发自最新代（活跃集）候选堆（provider 硬校验同款口径）。
    final isActivePile =
        family != null && family.activeParentSetId == parentSet.id;
    final branchReady =
        isActivePile && exploreParentSetRoundsComplete(run, parentSet);
    final branchTooltip = branchReady
        ? ''
        : isActivePile
        ? l10n.styleExplore_branchRoundsIncomplete
        : l10n.styleExplore_branchNeedLatest;

    return Dialog(
      key: const Key('explore-pile-manage'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.9,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitleRow(theme, l10n, parentSet, pile),
            Divider(height: 1, color: theme.dividerColor),
            Expanded(child: _buildBody(l10n, run, pile)),
            Divider(height: 1, color: theme.dividerColor),
            _buildActionBar(theme, l10n, run, pile, branchReady, branchTooltip),
          ],
        ),
      ),
    );
  }

  // ==================== 标题行 ====================

  Widget _buildTitleRow(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreParentSet parentSet,
    List<ExploreCandidate> pile,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            l10n.styleExplore_candidatePileTitle(
              parentSet.generation + 1,
              pile.length,
            ),
            style: theme.textTheme.titleMedium,
          ),
          if (_selected.isNotEmpty)
            Text(
              l10n.styleExplore_selectedCount(_selected.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          TextButton(
            key: const Key('explore-pile-manage-select-all'),
            onPressed: pile.isEmpty || _busy
                ? null
                : () => setState(
                    () => _selected
                      ..clear()
                      ..addAll(pile.map((c) => c.id)),
                  ),
            child: Text(l10n.common_selectAll),
          ),
          TextButton(
            key: const Key('explore-pile-manage-deselect-all'),
            onPressed: _selected.isEmpty || _busy
                ? null
                : () => setState(_selected.clear),
            child: Text(l10n.common_deselectAll),
          ),
          // 视图两档：网格（等宽方格 cover）/ 瀑布流（原比例 contain）。
          SegmentedButton<bool>(
            key: const Key('explore-pile-manage-view'),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.grid_on, size: 16),
                tooltip: l10n.common_grid,
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.dashboard_outlined, size: 16),
                tooltip: l10n.localGallery_masonryViewLabel,
              ),
            ],
            selected: {_masonry},
            onSelectionChanged: _busy
                ? null
                : (selection) => setState(() => _masonry = selection.first),
          ),
          IconButton(
            tooltip: l10n.common_close,
            iconSize: 18,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  // ==================== 网格 / 瀑布流 ====================

  Widget _buildBody(
    AppLocalizations l10n,
    ExploreRun run,
    List<ExploreCandidate> pile,
  ) {
    if (pile.isEmpty) {
      return Center(
        child: Text(
          l10n.styleExplore_pileEmpty,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        const padding = 12.0;
        final columns = ((constraints.maxWidth - padding * 2) / _columnWidth)
            .floor()
            .clamp(1, 24);
        final itemWidth =
            (constraints.maxWidth - padding * 2 - (columns - 1) * spacing) /
            columns;
        // 解码宽按实际显示宽给（×2 覆盖高分屏），勿全尺寸。
        final cacheWidth = (itemWidth * 2).round().clamp(64, 2048);

        if (_masonry) {
          return MasonryGridView.count(
            padding: const EdgeInsets.all(padding),
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            itemCount: pile.length,
            itemBuilder: (context, index) =>
                _buildCard(run, pile[index], cacheWidth, masonry: true),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
          ),
          itemCount: pile.length,
          itemBuilder: (context, index) =>
              _buildCard(run, pile[index], cacheWidth, masonry: false),
        );
      },
    );
  }

  Widget _buildCard(
    ExploreRun run,
    ExploreCandidate candidate,
    int cacheWidth, {
    required bool masonry,
  }) {
    return _PileManageCard(
      key: ValueKey('explore-pile-manage-${candidate.id}'),
      run: run,
      candidate: candidate,
      sequenceNumber:
          run.candidates.indexWhere((c) => c.id == candidate.id) + 1,
      cacheWidth: cacheWidth,
      masonry: masonry,
      selected: _selected.contains(candidate.id),
      // 有选择集时点按 = 切换选择（批量管理是本职）；无选择时点按 = 详情。
      onTap: () {
        if (_busy) return;
        if (_selected.isNotEmpty) {
          _toggleSelect(candidate.id);
        } else {
          _openDetail(run, candidate);
        }
      },
      onToggleSelect: _busy ? null : () => _toggleSelect(candidate.id),
    );
  }

  void _toggleSelect(String candidateId) {
    setState(() {
      if (!_selected.remove(candidateId)) {
        _selected.add(candidateId);
      }
    });
  }

  void _openDetail(ExploreRun run, ExploreCandidate candidate) {
    final ids = _pileOf(run).map((c) => c.id).toList();
    showDialog<void>(
      context: context,
      builder: (_) => ExploreCandidateDetailDialog(
        runId: run.id,
        candidateIds: ids,
        initialIndex: ids.indexOf(candidate.id),
      ),
    );
  }

  // ==================== 底部批量动作条 ====================

  Widget _buildActionBar(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreRun run,
    List<ExploreCandidate> pile,
    bool branchReady,
    String branchTooltip,
  ) {
    final selected = [
      for (final candidate in pile)
        if (_selected.contains(candidate.id)) candidate,
    ];
    final enabled = selected.isNotEmpty && !_busy;
    final allHearted =
        selected.isNotEmpty && selected.every((c) => c.review.heart);
    final hasImages = selected.any((c) => c.generation.filePath != null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 收藏 / 取消收藏（全选已收藏时反转为取消）。
                OutlinedButton.icon(
                  key: const Key('explore-pile-manage-heart'),
                  onPressed: enabled
                      ? () => _setHearts(run, selected, !allHearted)
                      : null,
                  icon: Icon(
                    allHearted ? Icons.favorite_border : Icons.favorite,
                    size: 16,
                  ),
                  label: Text(
                    allHearted ? l10n.common_unfavorite : l10n.common_favorite,
                  ),
                ),
                // 归类到：文件夹菜单（含未分类 + 新建）。
                PopupMenuButton<String>(
                  key: const Key('explore-pile-manage-assign'),
                  enabled: enabled,
                  tooltip: l10n.styleExplore_assignToFolder,
                  itemBuilder: (context) => [
                    for (final folder in run.folders)
                      PopupMenuItem(
                        value: folder.id,
                        child: Row(
                          children: [
                            const Icon(Icons.folder_outlined, size: 16),
                            const SizedBox(width: 8),
                            Text(folder.name),
                          ],
                        ),
                      ),
                    if (run.folders.isNotEmpty) const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: '',
                      child: Row(
                        children: [
                          Icon(Icons.inbox_outlined, size: 16),
                          SizedBox(width: 8),
                          // 占位文本在 onSelected 里取 l10n，itemBuilder 无 context.l10n
                          // 闭包问题——直接在下面用 Builder 不合适，这里用固定引用。
                          _UncategorizedLabel(),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: '__new__',
                      child: Row(
                        children: [
                          Icon(Icons.create_new_folder_outlined, size: 16),
                          SizedBox(width: 8),
                          _NewFolderLabel(),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _assignSelected(run, selected, value),
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.drive_file_move_outlined, size: 16),
                    label: Text(l10n.styleExplore_assignToFolder),
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: enabled
                          ? theme.colorScheme.onSurface
                          : null,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('explore-pile-manage-adopt'),
                  onPressed: enabled
                      ? () => _adoptSelected(run, selected)
                      : null,
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: Text(l10n.styleExplore_mergeAdopt),
                ),
                Tooltip(
                  message: branchTooltip,
                  child: OutlinedButton.icon(
                    key: const Key('explore-pile-manage-branch'),
                    onPressed: enabled && branchReady
                        ? () => _createBranch(run, selected)
                        : null,
                    icon: const Icon(Icons.call_split, size: 16),
                    label: Text(l10n.styleExplore_createBranch),
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('explore-pile-manage-delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: enabled && hasImages
                      ? () => _deleteSelected(run, selected)
                      : null,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(l10n.styleExplore_deleteImage),
                ),
              ],
            ),
          ),
          // 列宽控件放右下角（对齐本地画廊分页条先例）。
          ColumnWidthMenuButton(
            key: const Key('explore-pile-manage-column-width'),
            width: _columnWidth,
            onChanged: (width) => setState(
              () => _columnWidth = GalleryColumnWidthStore.clampColumnWidth(
                width,
              ),
            ),
            onChangeEnd: (width) => _columnWidthStore.save(width),
          ),
        ],
      ),
    );
  }

  Future<void> _setHearts(
    ExploreRun run,
    List<ExploreCandidate> selected,
    bool heart,
  ) async {
    setState(() => _busy = true);
    try {
      final notifier = ref.read(exploreRunListNotifierProvider.notifier);
      for (final candidate in selected) {
        if (candidate.review.heart == heart) continue;
        await notifier.updateReview(run.id, candidate.id, heart: heart);
      }
      if (mounted) setState(() => _selected.clear());
    } catch (error) {
      AppLogger.e('Batch heart update failed', error, null, 'StyleExplore');
      if (mounted) {
        AppToast.error(context, context.l10n.styleExplore_operationFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assignSelected(
    ExploreRun run,
    List<ExploreCandidate> selected,
    String value,
  ) async {
    String? folderId = value.isEmpty ? null : value;
    if (value == '__new__') {
      final folder = await promptCreateExploreFolder(context, ref, run.id);
      if (folder == null) return;
      folderId = folder.id;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(exploreRunListNotifierProvider.notifier)
          .assignCandidatesFolder(run.id, [
            for (final candidate in selected) candidate.id,
          ], folderId);
      if (mounted) setState(() => _selected.clear());
    } catch (error) {
      AppLogger.e('Batch assign folder failed', error, null, 'StyleExplore');
      if (mounted) {
        AppToast.error(context, context.l10n.styleExplore_operationFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _adoptSelected(
    ExploreRun run,
    List<ExploreCandidate> selected,
  ) async {
    setState(() => _busy = true);
    try {
      final created = await ExploreCandidateActions.adoptMerged(
        context,
        ref,
        run: run,
        candidates: selected,
      );
      if (created && mounted) setState(() => _selected.clear());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 建分支：与谱系区 `_createBranch` 同链路（命名框 → provider → toast）。
  Future<void> _createBranch(
    ExploreRun run,
    List<ExploreCandidate> selected,
  ) async {
    final l10n = context.l10n;
    final name = await ThemedInputDialog.show(
      context: context,
      title: l10n.styleExplore_createBranch,
      labelText: l10n.styleExplore_branchNameLabel,
    );
    if (name == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final newSet = await ref
          .read(exploreRunListNotifierProvider.notifier)
          .createBranch(
            run.id,
            familyId: widget.familyId,
            selectedCandidateIds: [
              for (final candidate in selected) candidate.id,
            ],
            branchName: name.trim().isEmpty ? null : name.trim(),
          );
      if (mounted) {
        AppToast.success(
          context,
          l10n.styleExplore_branchCreated(newSet.parents.length),
        );
        setState(() => _selected.clear());
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
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 批量删图：一次确认 → 逐张删副本文件 + 清 filePath（候选记录保留）。
  Future<void> _deleteSelected(
    ExploreRun run,
    List<ExploreCandidate> selected,
  ) async {
    final l10n = context.l10n;
    final targets = [
      for (final candidate in selected)
        if (candidate.generation.filePath != null) candidate,
    ];
    if (targets.isEmpty) return;
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: l10n.styleExplore_pileManageDeleteTitle,
      content: l10n.styleExplore_pileManageDeleteMessage(targets.length),
      confirmText: l10n.styleExplore_deleteImage,
      type: ThemedConfirmDialogType.danger,
      icon: Icons.delete_outline,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    var deleted = 0;
    try {
      final store = ref.read(exploreRunImageStoreProvider);
      final notifier = ref.read(exploreRunListNotifierProvider.notifier);
      for (final candidate in targets) {
        final filePath = candidate.generation.filePath!;
        if (!await store.deleteCandidateImage(filePath)) continue;
        await notifier.updateGeneration(
          run.id,
          candidate.id,
          candidate.generation.copyWith(filePath: null),
        );
        deleted++;
      }
      if (mounted) {
        AppToast.success(
          context,
          l10n.styleExplore_pileManageDeleteDone(deleted),
        );
        setState(() => _selected.clear());
      }
    } catch (error) {
      AppLogger.e('Batch delete images failed', error, null, 'StyleExplore');
      if (mounted) {
        AppToast.error(context, l10n.styleExplore_operationFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// PopupMenuItem 里取 l10n 的小包装（itemBuilder 的 context 在菜单层，
/// 直接用 context.l10n 可行，这里仅为保持 itemBuilder 简洁拆出）。
class _UncategorizedLabel extends StatelessWidget {
  const _UncategorizedLabel();

  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.styleExplore_folderUncategorized);
  }
}

class _NewFolderLabel extends StatelessWidget {
  const _NewFolderLabel();

  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.styleExplore_newFolder);
  }
}

/// 弹窗候选卡：图 + 左上常驻复选框 + 左下 `#序号 · 第N轮` + 右上收藏/状态
/// 徽标 + 选中描边。网格 = 方格 cover；瀑布流 = 原比例 contain。
class _PileManageCard extends StatelessWidget {
  const _PileManageCard({
    super.key,
    required this.run,
    required this.candidate,
    required this.sequenceNumber,
    required this.cacheWidth,
    required this.masonry,
    required this.selected,
    required this.onTap,
    required this.onToggleSelect,
  });

  final ExploreRun run;
  final ExploreCandidate candidate;
  final int sequenceNumber;
  final int cacheWidth;
  final bool masonry;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final roundNumber = run.roundById(candidate.roundId)?.number;
    final generation = candidate.generation;
    // 瀑布流按 run 快照宽高比撑高（同 run 候选同参数出图）；
    // 快照缺失时回退方形占位。
    final snapshot = run.paramsSnapshot;
    final aspect = snapshot.height > 0 ? snapshot.width / snapshot.height : 1.0;

    final card = Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          // 瀑布流模式下尺寸由外层 AspectRatio 提供，同样 expand。
          fit: StackFit.expand,
          children: [
            _buildImage(theme, l10n, aspect),
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            // 常驻复选框（勾选 = 多选）。
            Positioned(
              left: 4,
              top: 4,
              child: InkWell(
                key: Key('explore-pile-manage-check-${candidate.id}'),
                customBorder: const CircleBorder(),
                onTap: onToggleSelect,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (generation.status ==
                      ExploreCandidateGenerationStatus.pending)
                    const _BadgeIcon(icon: Icons.schedule)
                  else if (generation.status ==
                      ExploreCandidateGenerationStatus.failed)
                    _BadgeIcon(
                      icon: Icons.error_outline,
                      color: theme.colorScheme.error,
                    ),
                  if (candidate.review.heart) ...[
                    if (generation.status !=
                        ExploreCandidateGenerationStatus.done)
                      const SizedBox(width: 4),
                    _BadgeIcon(
                      icon: Icons.favorite,
                      color: theme.colorScheme.error,
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: _BadgeChip(
                text:
                    '#$sequenceNumber'
                    '${roundNumber != null ? ' · ${l10n.styleExplore_roundNumber(roundNumber)}' : ''}',
              ),
            ),
          ],
        ),
      ),
    );

    if (!masonry) return card;
    return AspectRatio(aspectRatio: aspect, child: card);
  }

  Widget _buildImage(ThemeData theme, AppLocalizations l10n, double aspect) {
    final filePath = candidate.generation.filePath;
    final placeholderIcon = switch (candidate.generation.status) {
      ExploreCandidateGenerationStatus.failed => Icons.error_outline,
      ExploreCandidateGenerationStatus.pending => Icons.hourglass_empty,
      // done 但无副本 = 已删图（记录保留）。
      ExploreCandidateGenerationStatus.done => Icons.broken_image_outlined,
    };
    final tooltip =
        candidate.generation.status == ExploreCandidateGenerationStatus.failed
        ? (candidate.generation.error ?? '')
        : (candidate.generation.status ==
                  ExploreCandidateGenerationStatus.done &&
              filePath == null)
        ? l10n.styleExplore_candidateMissing
        : null;

    Widget placeholder() => Center(
      child: Icon(
        placeholderIcon,
        size: 32,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    if (filePath == null) {
      final child = placeholder();
      return tooltip == null || tooltip.isEmpty
          ? child
          : Tooltip(message: tooltip, child: child);
    }
    return Image.file(
      File(filePath),
      fit: masonry ? BoxFit.contain : BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      errorBuilder: (context, error, stackTrace) => Tooltip(
        message: l10n.styleExplore_candidateMissing,
        child: placeholder(),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: theme.textTheme.labelSmall),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.75),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: color ?? theme.colorScheme.onSurface),
    );
  }
}
