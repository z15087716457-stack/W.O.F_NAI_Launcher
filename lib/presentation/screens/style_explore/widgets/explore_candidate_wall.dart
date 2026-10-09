import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/style_explore/explore_roll_capture.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import '../../../widgets/common/themed_input_dialog.dart';
import 'explore_candidate_actions.dart';
import 'explore_candidate_hover_preview.dart';
import 'explore_create_family_dialog.dart';
import 'explore_folder_assign_bar.dart';
import 'explore_gallery_welcome.dart';
import 'explore_lineage_panel.dart';
import 'horizontal_edge_fade.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../providers/style_explore/explore_manual_capture.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../providers/style_explore/explore_view_state.dart';
import '../../../themes/studio_typography.dart';
import '../../../widgets/prompt/pills/dna_icon.dart';
import 'explore_candidate_card.dart';
import 'explore_candidate_detail_dialog.dart';
import 'explore_icon.dart';
import 'explore_run_actions.dart';

/// 右栏候选画廊：筛选 chips + 新建文件夹 + 牌堆分组 + 大图详情弹窗。
///
/// 牌堆分组 = 用户自建文件夹 + 未分类（与谱系 pile 的遗传血缘完全平行解耦）；
/// 收藏（heart 字段）是纯数据注释，任何时刻不移动/改名图库文件，
/// run 目录副本随 run 删除。
class ExploreCandidateWall extends ConsumerStatefulWidget {
  const ExploreCandidateWall({super.key});

  @override
  ConsumerState<ExploreCandidateWall> createState() =>
      _ExploreCandidateWallState();
}

class _ExploreCandidateWallState extends ConsumerState<ExploreCandidateWall> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  /// 最近一次渲染的 run id：切 run 时多选态随之清空（选择集只对
  /// 旧 run 的候选有意义）。
  String? _lastRunId;

  /// 候选堆缩略图悬停预览会话（FEAT-41）：谱系区全部堆卡共享。
  final ExploreCandidateHoverSession _hoverSession =
      ExploreCandidateHoverSession();

  @override
  void dispose() {
    _hoverSession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final run = ref.watch(exploreActiveRunProvider);
    // 文件夹筛选指向已删/跨 run 的悬空 id 时回落「全部」（deleteFolder
    // 本侧已同步回落，这里再兜一层防跨 run 残留）。
    final filter = run == null
        ? ref.watch(exploreGalleryFilterProvider)
        : effectiveExploreGalleryFilter(
            run,
            ref.watch(exploreGalleryFilterProvider),
          );

    if (run == null) {
      return const ExploreGalleryWelcome();
    }

    final candidates = run.candidates;
    if (run.id != _lastRunId) {
      _lastRunId = run.id;
      _selectionMode = false;
      _selectedIds.clear();
    }
    // 候选集合变化后清掉失效的选择项（删 run/重选 run 等）。
    final existingIds = candidates.map((c) => c.id).toSet();
    _selectedIds.removeWhere((id) => !existingIds.contains(id));

    final tab = ref.watch(exploreStageTabProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabs(theme, l10n, run, filter, tab),
        if (_selectionMode) _buildSelectionBar(l10n, run),
        Expanded(
          child: tab == ExploreStageTab.evolution
              ? SingleChildScrollView(
                  child: ExploreLineagePanel(
                    run: run,
                    onOpenCandidate: (candidate) =>
                        _openCandidateDetail(run, candidate),
                    hoverSession: _hoverSession,
                  ),
                )
              : candidates.isEmpty
              ? const ExploreGalleryWelcome()
              : _buildDeck(theme, l10n, run),
        ),
      ],
    );
  }

  Widget _buildTabs(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreRun run,
    ExploreGalleryFilter filter,
    ExploreStageTab tab,
  ) => Container(
    height: 46,
    padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
    ),
    child: Row(
      children: [
        _tab(
          ExploreStageTab.candidates,
          l10n.styleExplore_candidatesTab,
          run.candidates.length,
          tab,
        ),
        const SizedBox(width: 10),
        _tab(
          ExploreStageTab.evolution,
          l10n.styleExplore_evolutionTab,
          run.families.length,
          tab,
        ),
        Container(
          height: 20,
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          color: theme.colorScheme.outlineVariant,
        ),
        Expanded(
          child: tab == ExploreStageTab.candidates
              ? _buildToolbar(theme, l10n, run, filter)
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );

  Widget _tab(
    ExploreStageTab value,
    String text,
    int count,
    ExploreStageTab selected,
  ) {
    final colors = Theme.of(context).colorScheme;
    final color = selected == value
        ? colors.onSurface
        : colors.onSurfaceVariant;
    return GestureDetector(
      key: Key('explore-tab-${value.name}'),
      onTap: () => ref.read(exploreStageTabProvider.notifier).state = value,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: selected == value
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.onSurface, width: 2),
                ),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            value == ExploreStageTab.evolution
                ? DnaIcon(size: 15, color: color)
                : Icon(StudioIcons.galleryImage, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: StudioTypography.data.copyWith(
                    fontSize: 11,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 工具条 ====================

  Widget _buildToolbar(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreRun run,
    ExploreGalleryFilter filter,
  ) {
    // 锁定 chip 数：全部/收藏 两枚钉死在筛选排最前，文件夹 chips 才可拖。
    const lockedChipCount = 2;
    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: HorizontalEdgeFade(
                child: ReorderableListView(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  onReorderItem: (oldIndex, newIndex) =>
                      _reorderFolderChips(run, oldIndex, newIndex),
                  children: [
                    _filterChip(
                      key: const Key('explore-filter-all'),
                      label: l10n.styleExplore_filterAll,
                      selected: filter is ExploreGalleryFilterAll,
                      onTap: () => _setFilter(const ExploreGalleryFilterAll()),
                    ),
                    _filterChip(
                      key: const Key('explore-filter-hearted'),
                      label: l10n.styleExplore_filterHearted,
                      selected: filter is ExploreGalleryFilterHearted,
                      onTap: () =>
                          _setFilter(const ExploreGalleryFilterHearted()),
                    ),
                    for (final entry in run.folders.indexed)
                      ReorderableDragStartListener(
                        key: ValueKey('explore-filter-folder-${entry.$2.id}'),
                        index: lockedChipCount + entry.$1,
                        child: GestureDetector(
                          // 右键小菜单：重命名/删除。空文件夹不渲染牌堆
                          // 组头，chip 是其唯一管理入口（FEAT 补充）。
                          onSecondaryTapUp: (details) => _showFolderMenu(
                            run,
                            entry.$2,
                            details.globalPosition,
                          ),
                          child: _filterChip(
                            label: entry.$2.name,
                            icon: Icons.folder_outlined,
                            selected:
                                filter is ExploreGalleryFilterFolder &&
                                filter.folderId == entry.$2.id,
                            onTap: () => _setFilter(
                              ExploreGalleryFilterFolder(entry.$2.id),
                            ),
                          ),
                        ),
                      ),
                    _filterChip(
                      key: const Key('explore-filter-uncategorized'),
                      label: l10n.styleExplore_folderUncategorized,
                      icon: Icons.inbox_outlined,
                      selected:
                          filter is ExploreGalleryFilterFolder &&
                          filter.folderId == null,
                      onTap: () =>
                          _setFilter(const ExploreGalleryFilterFolder(null)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 钉右两钮：chips 溢出横滚时常显不挤没。
          IconButton(
            key: const Key('explore-gallery-new-folder'),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: l10n.styleExplore_newFolder,
            onPressed: () => promptCreateExploreFolder(context, ref, run.id),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          // 多选模式。
          IconButton(
            key: const Key('explore-gallery-select-toggle'),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: l10n.styleExplore_selectCandidates,
            onPressed: () => setState(() => _selectionMode = true),
            icon: const Icon(Icons.checklist),
          ),
        ],
      ),
    );
  }

  void _setFilter(ExploreGalleryFilter filter) {
    ref.read(exploreGalleryFilterProvider.notifier).state = filter;
  }

  /// 文件夹 chip 右键小菜单：重命名/删除。与牌堆组头按钮同链路，
  /// 覆盖「空文件夹没有组头、无处删除」的缺口。
  Future<void> _showFolderMenu(
    ExploreRun run,
    ExploreCandidateFolder folder,
    Offset globalPosition,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;
    final localPosition = overlay.globalToLocal(globalPosition);
    final errorColor = Theme.of(context).colorScheme.error;
    final choice = await showMenu<String>(
      context: context,
      constraints: const BoxConstraints(minWidth: 144, maxWidth: 188),
      menuPadding: const EdgeInsets.symmetric(vertical: 4),
      position: RelativeRect.fromRect(
        Rect.fromPoints(localPosition, localPosition),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          key: const Key('explore-folder-menu-rename'),
          value: 'rename',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 10),
              Text(context.l10n.styleExplore_renameFolder),
            ],
          ),
        ),
        PopupMenuItem(
          key: const Key('explore-folder-menu-delete'),
          value: 'delete',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: errorColor),
              const SizedBox(width: 10),
              Text(
                context.l10n.styleExplore_deleteFolder,
                style: TextStyle(color: errorColor),
              ),
            ],
          ),
        ),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case 'rename':
        await _renameFolder(run, folder.id);
        break;
      case 'delete':
        await _deleteFolder(run, folder.id);
        break;
    }
  }

  /// 文件夹 chip 拖动落序：全部/收藏在前、未分类在尾均锁定，
  /// 拖入落点夹回文件夹区间，写回 run.folders 顺序（牌堆分组同源）。
  /// onReorderItem 的 newIndex 已按移除项调整（= 最终插入位）。
  void _reorderFolderChips(ExploreRun run, int oldIndex, int newIndex) {
    const locked = 2;
    final folderCount = run.folders.length;
    if (oldIndex < locked || oldIndex >= locked + folderCount) return;
    final target = newIndex.clamp(locked, locked + folderCount - 1);
    final ordered = [for (final folder in run.folders) folder.id];
    ordered.insert(target - locked, ordered.removeAt(oldIndex - locked));
    ref
        .read(exploreRunListNotifierProvider.notifier)
        .reorderFolders(run.id, ordered);
  }

  Widget _filterChip({
    Key? key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
        selected: selected,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildSelectionBar(AppLocalizations l10n, ExploreRun run) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      // 窄栏（320px）下按钮可换行，防多语言长文案溢出。
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            key: const Key('explore-gallery-select-exit'),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: l10n.common_close,
            onPressed: _exitSelection,
            icon: const Icon(Icons.close),
          ),
          Text(
            l10n.styleExplore_selectedCount(_selectedIds.length),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          FilledButton.tonalIcon(
            key: const Key('explore-gallery-create-family'),
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _createFamilyFromSelection(run),
            icon: const Icon(StudioIcons.styleExplore, size: 16),
            label: Text(l10n.styleExplore_createFamily),
          ),
          FilledButton.tonalIcon(
            key: const Key('explore-gallery-merge-adopt'),
            onPressed: _selectedIds.isEmpty ? null : () => _adoptSelected(run),
            icon: const Icon(Icons.inventory_2_outlined, size: 16),
            label: Text(l10n.styleExplore_mergeAdopt),
          ),
          // FEAT-56：无底色删除钮——批量删图（FEAT-42 同链路），
          // 仅当选择集里有已落副本的候选时启用。
          TextButton.icon(
            key: const Key('explore-gallery-delete'),
            onPressed:
                run.candidates.any(
                  (candidate) =>
                      _selectedIds.contains(candidate.id) &&
                      candidate.generation.filePath != null,
                )
                ? () => _deleteSelected(run)
                : null,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: Text(l10n.styleExplore_deleteImage),
          ),
        ],
      ),
    );
  }

  // ==================== 牌堆（分组） ====================

  /// 牌堆：按用户自建文件夹分组（未分类恒在最后），组头计数，
  /// 组内复用候选卡；筛选 chips 在其上叠加过滤。
  Widget _buildDeck(ThemeData theme, AppLocalizations l10n, ExploreRun run) {
    final filter = effectiveExploreGalleryFilter(
      run,
      ref.watch(exploreGalleryFilterProvider),
    );
    final newest = ref.watch(exploreRoundOrderNewestFirstProvider);
    final large = ref.watch(
      layoutStateNotifierProvider.select(
        (layout) => layout.styleExploreGridLarge,
      ),
    );
    final visibleRounds = [
      for (final round in exploreOrderedRounds(run, newest))
        if (exploreRoundCandidates(run, round, filter).isNotEmpty ||
            (filter is ExploreGalleryFilterAll && round.candidateIds.isEmpty))
          round,
    ];
    if (visibleRounds.isEmpty) {
      return Center(child: Text(l10n.styleExplore_emptyFilter));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - 28;
        final columns = ((available + 12) / ((large ? 200 : 150) + 12))
            .floor()
            .clamp(2, 100);
        final cardWidth = (available - 12 * (columns - 1)) / columns;
        final ratio = run.paramsSnapshot.width / run.paramsSnapshot.height;
        return CustomScrollView(
          key: ValueKey('explore-wall-${run.id}'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              sliver: SliverMainAxisGroup(
                slivers: [
                  for (final round in visibleRounds) ...[
                    SliverToBoxAdapter(child: _roundHeader(theme, run, round)),
                    if (round.candidateIds.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(l10n.styleExplore_emptyRound),
                        ),
                      )
                    else
                      SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          mainAxisExtent:
                              cardWidth / ratio + 6 + 11.5 * 1.45 * 2,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildCandidateCard(
                            run,
                            exploreRoundCandidates(run, round, filter)[index],
                          ),
                          childCount: exploreRoundCandidates(
                            run,
                            round,
                            filter,
                          ).length,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _roundHeader(ThemeData theme, ExploreRun run, ExploreRound round) {
    final l10n = context.l10n;
    final colors = theme.colorScheme;
    final now = DateTime.now();
    final time = round.createdAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${time.year == now.year && time.month == now.month && time.day == now.day ? '' : '${two(time.month)}-${two(time.day)} '}${two(time.hour)}:${two(time.minute)}';
    final all = exploreRoundCandidates(
      run,
      round,
      const ExploreGalleryFilterAll(),
    );
    final failures = all
        .where(
          (c) => c.generation.status == ExploreCandidateGenerationStatus.failed,
        )
        .length;
    final runner = ref.watch(exploreRunRunnerProvider);
    final manual = ref.watch(exploreManualCaptureProvider);
    final running =
        (runner.isRunning &&
            runner.runId == run.id &&
            round.status == ExploreRoundStatus.generating) ||
        (manual.armed &&
            manual.runId == run.id &&
            all.any(
              (c) =>
                  manual.candidateIds.contains(c.id) &&
                  c.generation.status ==
                      ExploreCandidateGenerationStatus.pending,
            ));
    final deep = round.phase == ExploreRoundPhase.deep;
    return Padding(
      key: Key('explore-round-${round.id}'),
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
      child: Row(
        children: [
          if (deep) ...[
            DnaIcon(size: 14, color: DnaIcon.prototypeColor(theme.brightness)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, space) => Row(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: (space.maxWidth - 20).clamp(0, double.infinity),
                    ),
                    child: IntrinsicWidth(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: deep
                                  ? l10n.styleExplore_deepRoundTitle(
                                      run
                                              .familyById(round.familyId ?? '')
                                              ?.name ??
                                          l10n.styleExplore_evolutionTab,
                                      round.generation ?? 1,
                                    )
                                  : l10n.styleExplore_roundNumber(round.number),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                            const WidgetSpan(child: SizedBox(width: 10)),
                            TextSpan(
                              text:
                                  '$stamp · ${l10n.styleExplore_wallRoundCount(all.length)}${running
                                      ? ' · ${l10n.styleExplore_wallGenerating}'
                                      : failures > 0
                                      ? ' · ${l10n.styleExplore_roundFailures(failures)}'
                                      : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Divider(height: 1, color: colors.outlineVariant),
                  ),
                ],
              ),
            ),
          ),
          if (failures > 0 && !runner.isRunning && !manual.armed) ...[
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: () => ExploreRunActions.retryFailed(context, ref, run),
              icon: ExploreIcon('swap', size: 12, color: colors.error),
              style: TextButton.styleFrom(
                foregroundColor: colors.error,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              label: Text(
                l10n.styleExplore_retryFailed(failures),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _renameFolder(ExploreRun run, String folderId) async {
    final l10n = context.l10n;
    final folder = run.folderById(folderId);
    if (folder == null) return;
    final name = await ThemedInputDialog.show(
      context: context,
      title: l10n.styleExplore_renameFolder,
      labelText: l10n.styleExplore_folderNameLabel,
      initialValue: folder.name,
      validator: (value) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return l10n.styleExplore_nameRequired;
        // 重名预检（provider 层同名硬校验兜底）。
        if (run.folders.any((f) => f.id != folderId && f.name == trimmed)) {
          return l10n.toast_renameNameConflict;
        }
        return null;
      },
    );
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(exploreRunListNotifierProvider.notifier)
        .renameFolder(run.id, folderId, name);
  }

  Future<void> _deleteFolder(ExploreRun run, String folderId) async {
    final l10n = context.l10n;
    final folder = run.folderById(folderId);
    if (folder == null) return;
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: l10n.styleExplore_deleteFolder,
      content: l10n.styleExplore_deleteFolderMessage(folder.name),
      confirmText: l10n.common_delete,
      type: ThemedConfirmDialogType.danger,
      icon: Icons.delete_outline,
    );
    if (!confirmed) return;
    await ref
        .read(exploreRunListNotifierProvider.notifier)
        .deleteFolder(run.id, folderId);
  }

  Widget _buildCandidateCard(ExploreRun run, ExploreCandidate candidate) {
    final runner = ref.watch(exploreRunRunnerProvider);
    final manual = ref.watch(exploreManualCaptureProvider);
    String? current;
    if (runner.isRunning && runner.runId == run.id) {
      for (final round in run.rounds.where(
        (r) => r.status == ExploreRoundStatus.generating,
      )) {
        current =
            exploreRoundCandidates(run, round, const ExploreGalleryFilterAll())
                .where(
                  (c) =>
                      c.generation.status ==
                      ExploreCandidateGenerationStatus.pending,
                )
                .firstOrNull
                ?.id;
        if (current != null) break;
      }
    } else if (manual.armed && manual.runId == run.id) {
      current = manual.candidateIds
          .where(
            (id) =>
                run.candidateById(id)?.generation.status ==
                ExploreCandidateGenerationStatus.pending,
          )
          .firstOrNull;
    }
    return ExploreCandidateCard(
      key: ValueKey('explore-candidate-${candidate.id}'),
      run: run,
      candidate: candidate,
      sequenceNumber:
          run.candidates.indexWhere((c) => c.id == candidate.id) + 1,
      selectionMode: _selectionMode,
      selected: _selectedIds.contains(candidate.id),
      focused: ref.watch(exploreFocusedCandidateIdProvider) == candidate.id,
      generating: candidate.id == current,
      onFocus: () =>
          ref.read(exploreFocusedCandidateIdProvider.notifier).state =
              candidate.id,
      onToggleSelect: () => _toggleSelect(candidate.id),
      onEnterSelection: () => _enterSelection(candidate.id),
      onOpenDetail: () => _openCandidateDetail(run, candidate),
    );
  }

  // ==================== 多选与出口 ====================

  void _toggleSelect(String candidateId) {
    setState(() {
      if (!_selectedIds.remove(candidateId)) {
        _selectedIds.add(candidateId);
      }
    });
  }

  void _enterSelection(String candidateId) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(candidateId);
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  /// 多选合并收编：成功后退出多选，取消则保留选择。
  Future<void> _adoptSelected(ExploreRun run) async {
    final selected = [
      for (final candidate in run.candidates)
        if (_selectedIds.contains(candidate.id)) candidate,
    ];
    if (selected.isEmpty) return;
    final created = await ExploreCandidateActions.adoptMerged(
      context,
      ref,
      run: run,
      candidates: selected,
    );
    if (created && mounted) _exitSelection();
  }

  /// 多选批量删图（FEAT-56，FEAT-55 拍板 = 连记录删）：一次确认 → 逐张
  /// 删副本文件 + 移除候选记录，与 FEAT-42 管理弹窗 `_deleteSelected`
  /// 同链路；无副本项不参与（确认框计数只含有副本张数），成功后退出多选。
  Future<void> _deleteSelected(ExploreRun run) async {
    final targets = [
      for (final candidate in run.candidates)
        if (_selectedIds.contains(candidate.id) &&
            candidate.generation.filePath != null)
          candidate,
    ];
    if (targets.isEmpty) return;
    final l10n = context.l10n;
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: l10n.styleExplore_pileManageDeleteTitle,
      content: l10n.styleExplore_pileManageDeleteMessage(targets.length),
      confirmText: l10n.styleExplore_deleteImage,
      type: ThemedConfirmDialogType.danger,
      icon: Icons.delete_outline,
    );
    if (!confirmed || !mounted) return;
    var deleted = 0;
    try {
      final store = ref.read(exploreRunImageStoreProvider);
      final notifier = ref.read(exploreRunListNotifierProvider.notifier);
      // FEAT-55 拍板 = 连记录删：副本删成功的候选整条记录移除。
      final deletedIds = <String>[];
      for (final candidate in targets) {
        final filePath = candidate.generation.filePath!;
        if (!await store.deleteCandidateImage(filePath)) continue;
        deletedIds.add(candidate.id);
        deleted++;
      }
      if (deletedIds.isNotEmpty) {
        await notifier.removeCandidates(run.id, deletedIds);
      }
      if (mounted) {
        AppToast.success(
          context,
          l10n.styleExplore_pileManageDeleteDone(deleted),
        );
        _exitSelection();
      }
    } catch (error) {
      AppLogger.e('Batch delete images failed', error, null, 'StyleExplore');
      if (mounted) {
        AppToast.error(context, l10n.styleExplore_operationFailed);
      }
    }
  }

  /// 候选详情弹窗（画廊卡片与谱系区候选堆缩略图点击共用）。
  ///
  /// 翻页序 = 打开瞬间的筛选快照；点开的候选不在快照内（谱系区旁路）
  /// 时退化为单张序列。
  void _openCandidateDetail(ExploreRun run, ExploreCandidate candidate) {
    final filter = effectiveExploreGalleryFilter(
      run,
      ref.read(exploreGalleryFilterProvider),
    );
    final candidateIds = [
      for (final item in exploreWallCandidates(
        run,
        filter,
        newestFirst: ref.read(exploreRoundOrderNewestFirstProvider),
      ))
        item.id,
    ];
    var index = candidateIds.indexOf(candidate.id);
    if (index < 0) {
      candidateIds
        ..clear()
        ..add(candidate.id);
      index = 0;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ExploreCandidateDetailDialog(
        runId: run.id,
        candidateIds: candidateIds,
        initialIndex: index,
      ),
    );
  }

  /// 多选建家族（阶段 D）：对话框确认命名/自定义串后创建家族 +
  /// 第一代父本集，谱系区选中新家族并退出多选。
  Future<void> _createFamilyFromSelection(ExploreRun run) async {
    final selected = [
      for (final candidate in run.candidates)
        if (_selectedIds.contains(candidate.id)) candidate,
    ];
    if (selected.isEmpty) return;
    final l10n = context.l10n;
    final result = await ExploreCreateFamilyDialog.show(
      context,
      candidates: selected,
    );
    if (result == null || !mounted) return;

    final parents = <({String? sourceCandidateId, String artistString})>[
      for (final candidate in selected)
        (
          sourceCandidateId: candidate.id,
          artistString: exploreParentStringFor(candidate),
        ),
      for (final text in result.customStrings)
        (sourceCandidateId: null, artistString: text),
    ];
    try {
      final family = await ref
          .read(exploreRunListNotifierProvider.notifier)
          .createFamily(run.id, name: result.name, parents: parents);
      ref.read(exploreActiveFamilyIdProvider.notifier).state = family.id;
      if (mounted) {
        AppToast.success(context, l10n.styleExplore_familyCreated(family.name));
        _exitSelection();
      }
    } on StateError {
      if (mounted) {
        AppToast.warning(context, l10n.styleExplore_createFamilyEmpty);
      }
    }
  }
}
