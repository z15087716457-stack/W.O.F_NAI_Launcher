import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import '../../../widgets/common/themed_input_dialog.dart';
import 'explore_candidate_actions.dart';
import 'explore_candidate_hover_preview.dart';
import 'explore_shared_actions.dart';
import 'explore_folder_assign_bar.dart';
import 'explore_gallery_welcome.dart';
import 'explore_evolution_view.dart';
import 'explore_evolution_actions.dart';
import 'horizontal_edge_fade.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../providers/style_explore/explore_manual_capture.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../providers/style_explore/explore_view_state.dart';
import '../../../themes/studio_typography.dart';
import '../../../widgets/prompt/pills/dna_icon.dart';
import 'explore_candidate_card.dart';
import 'explore_icon.dart';
import 'explore_run_actions.dart';
import 'explore_selection_bar.dart';
import 'explore_style.dart';
import '../../../widgets/gallery/gallery_filter_widgets.dart';
import '../../../widgets/common/dashed_rounded_border.dart';

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
  final _stageFocus = FocusNode(debugLabel: 'exploration-stage');
  final _scroll = ScrollController();
  final _groupButton = GlobalKey();
  final Map<String, GlobalKey> _cardKeys = {};
  int _columns = 2;
  double _cardExtent = 300;
  bool get _selectionMode => ref.read(exploreSelectionModeProvider);
  Set<String> get _selectedIds => ref.read(exploreSelectionProvider);

  /// 候选堆缩略图悬停预览会话（FEAT-41）：谱系区全部堆卡共享。
  final ExploreCandidateHoverSession _hoverSession =
      ExploreCandidateHoverSession();

  @override
  void dispose() {
    _hoverSession.dispose();
    _stageFocus.dispose();
    _scroll.dispose();
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
    ref.watch(exploreSelectionProvider);
    ref.watch(exploreSelectionModeProvider);
    final tab = ref.watch(exploreStageTabProvider);
    ref.watch(exploreRunRunnerProvider);
    return Focus(
      focusNode: _stageFocus,
      onKeyEvent: (node, event) => _key(run, event),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _stageFocus.requestFocus,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTabs(theme, l10n, run, filter, tab),
                Expanded(
                  child: tab == ExploreStageTab.evolution
                      ? ExploreEvolutionView(
                          run: run,
                          cardBuilder: (c, selectable) => _buildCandidateCard(
                            run,
                            c,
                            selectable: selectable,
                          ),
                          onGridLayout: (n, extent) {
                            _columns = n;
                            _cardExtent = extent;
                          },
                        )
                      : candidates.isEmpty
                      ? const ExploreGalleryWelcome()
                      : _buildDeck(theme, l10n, run),
                ),
              ],
            ),
            if (_selectionMode && _selectedIds.isNotEmpty)
              Positioned(
                left: 14,
                right: 14,
                bottom: 18,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ExploreSelectionBar(
                    count: _selectedIds.length,
                    allHearted: run.candidates
                        .where((c) => _selectedIds.contains(c.id))
                        .every((c) => c.review.heart),
                    groupKey: _groupButton,
                    onHeart: () => _toggleHearts(run, _selectedIds),
                    onGroup: () => _assignMenu(run),
                    onAdopt: () => _adoptSelected(run),
                    evolutionLabel: tab == ExploreStageTab.evolution
                        ? l10n.styleExplore_breedNext
                        : null,
                    onEvolve: tab == ExploreStageTab.evolution
                        ? _canBreed(run)
                              ? () => breedExploreNextGeneration(
                                  context,
                                  ref,
                                  run,
                                )
                              : null
                        : () => _createFamilyFromSelection(run),
                    onDelete: () => _deleteSelected(run),
                    onExit: _exitSelection,
                  ),
                ),
              ),
          ],
        ),
      ),
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
              : ExploreEvolutionFilters(run: run),
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
    final mode = ref.watch(exploreSelectionModeProvider);
    final newest = ref.watch(exploreRoundOrderNewestFirstProvider);
    Widget chip(
      Key key,
      String label,
      ExploreGalleryFilter value, {
      IconData? icon,
      int? index,
    }) {
      final count = run.candidates
          .where((c) => exploreCandidateMatchesFilter(c, value))
          .length;
      Widget result = Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GalleryFilterChip(
          label: label,
          tooltip: label,
          active: filter == value,
          icon: icon,
          count: count,
          onTap: () => _setFilter(value),
        ),
      );
      if (value is ExploreGalleryFilterFolder && value.folderId != null) {
        result = GestureDetector(
          onSecondaryTapUp: (details) => _showFolderMenu(
            run,
            run.folderById(value.folderId!)!,
            details.globalPosition,
          ),
          child: result,
        );
      }
      return index == null
          ? KeyedSubtree(key: key, child: result)
          : ReorderableDragStartListener(key: key, index: index, child: result);
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 28,
            child: HorizontalEdgeFade(
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                onReorderItem: (a, b) => _reorderFolderChips(run, a, b),
                children: [
                  chip(
                    const Key('explore-filter-all'),
                    l10n.styleExplore_filterAll,
                    const ExploreGalleryFilterAll(),
                  ),
                  chip(
                    const Key('explore-filter-hearted'),
                    l10n.styleExplore_filterHearted,
                    const ExploreGalleryFilterHearted(),
                    icon: StudioIcons.galleryHeartFilled,
                  ),
                  chip(
                    const Key('explore-filter-uncategorized'),
                    l10n.styleExplore_folderUncategorized,
                    const ExploreGalleryFilterFolder(null),
                    icon: StudioIcons.galleryCollection,
                  ),
                  for (final entry in run.folders.indexed)
                    chip(
                      ValueKey('explore-filter-folder-${entry.$2.id}'),
                      entry.$2.name,
                      ExploreGalleryFilterFolder(entry.$2.id),
                      icon: StudioIcons.galleryFolder,
                      index: 3 + entry.$1,
                    ),
                  Padding(
                    key: const Key('explore-gallery-new-folder'),
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () =>
                          promptCreateExploreFolder(context, ref, run.id),
                      child: CustomPaint(
                        painter: DashedRoundedBorderPainter(
                          color: theme.colorScheme.outline,
                          dashedColor: theme.colorScheme.outline,
                          radius: const Radius.circular(14),
                          topRounded: true,
                          bottomRounded: true,
                          solidLeft: false,
                          solidRight: false,
                          dashedAll: true,
                        ),
                        child: Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ExploreIcon(
                                'plus',
                                size: 13,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                l10n.styleExplore_groupLabel,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        if (!mode)
          Tooltip(
            message: newest
                ? l10n.styleExplore_newestFirst
                : l10n.styleExplore_oldestFirst,
            child: IconButton(
              key: const Key('explore-round-sort'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 30),
              icon: Icon(
                newest
                    ? StudioIcons.gallerySortDesc
                    : StudioIcons.gallerySortAsc,
                size: 15,
              ),
              onPressed: () =>
                  ref
                          .read(exploreRoundOrderNewestFirstProvider.notifier)
                          .state =
                      !newest,
            ),
          ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          key: const Key('explore-gallery-select-toggle'),
          onPressed: mode
              ? _selectAll
              : () => ref.read(exploreSelectionModeProvider.notifier).state =
                    true,
          icon: const Icon(StudioIcons.gallerySelect, size: 14),
          label: Text(
            mode ? l10n.common_selectAll : l10n.styleExplore_selectCandidates,
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 30),
            maximumSize: const Size(double.infinity, 30),
            padding: const EdgeInsets.symmetric(horizontal: 11),
            textStyle: StudioTypography.body.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
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
    const locked = 3;
    final folderCount = run.folders.length;
    if (oldIndex < locked || oldIndex >= locked + folderCount) return;
    final target = newIndex.clamp(locked, locked + folderCount - 1);
    final ordered = [for (final folder in run.folders) folder.id];
    ordered.insert(target - locked, ordered.removeAt(oldIndex - locked));
    ref
        .read(exploreRunListNotifierProvider.notifier)
        .reorderFolders(run.id, ordered);
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
        _columns = columns;
        _cardExtent = cardWidth / ratio + 6 + 11.5 * 1.45 * 2 + 14;
        return CustomScrollView(
          key: ValueKey('explore-wall-${run.id}'),
          controller: _scroll,
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
          if (failures == 0 && !running) ...[
            const SizedBox(width: 10),
            TextButton.icon(
              key: Key('explore-round-select-${round.id}'),
              onPressed: () => _enterSelection(null),
              icon: DnaIcon(size: 13, color: ExploreStyle.evolution(theme)),
              label: Text(
                l10n.styleExplore_pickEvolution,
                style: const TextStyle(fontSize: 12.5),
              ),
              style: TextButton.styleFrom(
                foregroundColor: colors.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  Widget _buildCandidateCard(
    ExploreRun run,
    ExploreCandidate candidate, {
    bool selectable = true,
  }) {
    final current = ref.watch(exploreGeneratingCandidateIdProvider);
    return KeyedSubtree(
      key: ValueKey('explore-candidate-${candidate.id}'),
      child: ExploreCandidateCard(
        key: _cardKeys.putIfAbsent(candidate.id, GlobalKey.new),
        run: run,
        candidate: candidate,
        sequenceNumber:
            run.candidates.indexWhere((c) => c.id == candidate.id) + 1,
        selectionMode: selectable && _selectionMode,
        selected: selectable && _selectedIds.contains(candidate.id),
        focused: ref.watch(exploreFocusedCandidateIdProvider) == candidate.id,
        generating: candidate.id == current,
        onFocus: () => selectable
            ? _clickCandidate(candidate.id)
            : ref.read(exploreFocusedCandidateIdProvider.notifier).state =
                  candidate.id,
        onToggleSelect: selectable ? () => _clickCandidate(candidate.id) : null,
        onEnterSelection: selectable
            ? () => _enterSelection(candidate.id)
            : null,
        onOpenDetail: () => openExploreCandidate(
          context,
          ref,
          run,
          candidate,
          browsingIds:
              ref.read(exploreStageTabProvider) == ExploreStageTab.evolution
              ? [
                  for (final c in run.candidates)
                    if (c.roundId == candidate.roundId) c.id,
                ]
              : null,
        ),
      ),
    );
  }

  // ==================== 多选与出口 ====================

  bool _canBreed(ExploreRun run) {
    final family = exploreSelectedFamily(
      run,
      ref.read(exploreActiveFamilyIdProvider),
    );
    final set = run.parentSetById(family?.activeParentSetId ?? '');
    final runner = ref.read(exploreRunRunnerProvider);
    return set != null &&
        exploreParentSetRoundsComplete(run, set) &&
        !(runner.isRunning && runner.runId == run.id);
  }

  void _clickCandidate(String id) {
    _stageFocus.requestFocus();
    final focused = ref.read(exploreFocusedCandidateIdProvider);
    final selection = ref.read(exploreSelectionProvider.notifier);
    if (HardwareKeyboard.instance.isShiftPressed) {
      ref.read(exploreSelectionModeProvider.notifier).state = true;
      selection.selectRange(
        focused,
        id,
        ref.read(exploreVisibleCandidatesProvider).map((c) => c.id).toList(),
      );
    } else if (_selectionMode || HardwareKeyboard.instance.isControlPressed) {
      ref.read(exploreSelectionModeProvider.notifier).state = true;
      selection.toggle(id);
    }
    ref.read(exploreFocusedCandidateIdProvider.notifier).state = id;
  }

  void _enterSelection(String? id) {
    _stageFocus.requestFocus();
    ref.read(exploreSelectionModeProvider.notifier).state = true;
    if (id != null) {
      ref.read(exploreFocusedCandidateIdProvider.notifier).state = id;
      if (!_selectedIds.contains(id)) {
        ref.read(exploreSelectionProvider.notifier).toggle(id);
      }
    } else {
      ref.read(exploreSelectionProvider.notifier).clear();
    }
  }

  void _selectAll() {
    ref.read(exploreSelectionModeProvider.notifier).state = true;
    ref
        .read(exploreSelectionProvider.notifier)
        .selectAll(ref.read(exploreVisibleCandidatesProvider).map((c) => c.id));
  }

  void _exitSelection() {
    ref.read(exploreSelectionProvider.notifier).clear();
    ref.read(exploreSelectionModeProvider.notifier).state = false;
  }

  Future<void> _toggleHearts(ExploreRun run, Set<String> ids) async {
    final targets = run.candidates.where((c) => ids.contains(c.id)).toList();
    final heart = !targets.every((c) => c.review.heart);
    for (final target in targets) {
      await ref
          .read(exploreRunListNotifierProvider.notifier)
          .updateReview(run.id, target.id, heart: heart);
    }
  }

  Future<void> _assignMenu(ExploreRun run) async {
    final anchor =
        _groupButton.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final rect = anchor == null
        ? Rect.fromLTWH(overlay.size.width / 2, overlay.size.height - 62, 0, 0)
        : Rect.fromPoints(
            overlay.globalToLocal(anchor.localToGlobal(Offset.zero)),
            overlay.globalToLocal(
              anchor.localToGlobal(
                Offset(anchor.size.width, anchor.size.height),
              ),
            ),
          );
    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
      items: [
        for (final folder in run.folders)
          PopupMenuItem(value: folder.id, child: Text(folder.name)),
        PopupMenuItem(
          value: '__none',
          child: Text(context.l10n.styleExplore_folderUncategorized),
        ),
        PopupMenuItem(
          value: '__new',
          child: Text(context.l10n.styleExplore_newGroup),
        ),
      ],
    );
    if (value == null || !mounted) return;
    String? folderId = value == '__none' ? null : value;
    if (value == '__new') {
      final folder = await promptCreateExploreFolder(context, ref, run.id);
      if (folder == null) return;
      folderId = folder.id;
    }
    if (_selectedIds.isNotEmpty) {
      await ref
          .read(exploreRunListNotifierProvider.notifier)
          .assignCandidatesFolder(run.id, _selectedIds.toList(), folderId);
    }
  }

  KeyEventResult _key(ExploreRun run, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (FocusManager.instance.primaryFocus?.context
            ?.findAncestorStateOfType<EditableTextState>() !=
        null) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final visible = ref.read(exploreVisibleCandidatesProvider);
    final focused = ref.read(exploreFocusedCandidateIdProvider);
    final targets = _selectionMode && _selectedIds.isNotEmpty
        ? _selectedIds
        : {if (focused != null) focused};
    if (HardwareKeyboard.instance.isControlPressed) {
      if (key == LogicalKeyboardKey.keyA) {
        _selectAll();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final horizontal = key == LogicalKeyboardKey.arrowLeft
        ? -1
        : key == LogicalKeyboardKey.arrowRight
        ? 1
        : 0;
    final vertical = key == LogicalKeyboardKey.arrowUp
        ? -1
        : key == LogicalKeyboardKey.arrowDown
        ? 1
        : 0;
    if (horizontal != 0 || vertical != 0) {
      final id = exploreMovedFocus(
        visible,
        focused,
        horizontal,
        vertical,
        _columns,
      );
      ref.read(exploreFocusedCandidateIdProvider.notifier).state = id;
      if (id != null) unawaited(_reveal(id, visible));
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      final candidate = run.candidateById(focused ?? '');
      if (candidate != null) _openCandidateDetail(run, candidate);
    } else if (key == LogicalKeyboardKey.keyF) {
      if (targets.isNotEmpty) unawaited(_toggleHearts(run, targets));
    } else if (key == LogicalKeyboardKey.keyE) {
      if (targets.isNotEmpty) {
        if (ref.read(exploreStageTabProvider) == ExploreStageTab.evolution) {
          if (_canBreed(run)) {
            unawaited(
              breedExploreNextGeneration(context, ref, run, ids: targets),
            );
          }
        } else {
          unawaited(_createFamilyFromSelection(run, ids: targets));
        }
      }
    } else if (key == LogicalKeyboardKey.delete) {
      if (targets.isNotEmpty) {
        unawaited(_deleteSelected(run, ids: targets));
      }
    } else if (key == LogicalKeyboardKey.escape) {
      if (_selectionMode) {
        _exitSelection();
      } else {
        ref.read(exploreFocusedCandidateIdProvider.notifier).state = null;
      }
    } else {
      final number =
          int.tryParse(key.keyLabel) ??
          [
            LogicalKeyboardKey.numpad0,
            LogicalKeyboardKey.numpad1,
            LogicalKeyboardKey.numpad2,
            LogicalKeyboardKey.numpad3,
            LogicalKeyboardKey.numpad4,
            LogicalKeyboardKey.numpad5,
            LogicalKeyboardKey.numpad6,
            LogicalKeyboardKey.numpad7,
            LogicalKeyboardKey.numpad8,
            LogicalKeyboardKey.numpad9,
          ].indexOf(key);
      if (number < 0 || number > 9) return KeyEventResult.ignored;
      if (number > run.folders.length) return KeyEventResult.handled;
      String? folderId = number == 0 ? null : run.folders[number - 1].id;
      if (folderId != null &&
          run.candidates
              .where((c) => targets.contains(c.id))
              .every((c) => c.folderId == folderId)) {
        folderId = null;
      }
      if (targets.isNotEmpty) {
        unawaited(
          ref
              .read(exploreRunListNotifierProvider.notifier)
              .assignCandidatesFolder(run.id, targets.toList(), folderId),
        );
      }
    }
    return KeyEventResult.handled;
  }

  Future<void> _reveal(String id, List<ExploreCandidate> visible) async {
    var target = _cardKeys[id]?.currentContext;
    if (target == null && _scroll.hasClients) {
      double offset = 0;
      for (final group in visible.map((c) => c.roundId).toSet()) {
        final candidates = visible.where((c) => c.roundId == group).toList();
        final index = candidates.indexWhere((c) => c.id == id);
        if (index >= 0) {
          offset += 48 + (index ~/ _columns) * _cardExtent;
          break;
        }
        offset += 48 + (candidates.length / _columns).ceil() * _cardExtent;
      }
      await _scroll.animateTo(
        offset.clamp(0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      target = _cardKeys[id]?.currentContext;
    }
    if (target != null && target.mounted) {
      await Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 200),
      );
    }
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
  /// 同链路；无副本记录也可删除。生成中的候选保持原状态。
  Future<void> _deleteSelected(ExploreRun run, {Set<String>? ids}) async {
    final targets = [
      for (final candidate in run.candidates)
        if ((ids ?? _selectedIds).contains(candidate.id) &&
            candidate.generation.status !=
                ExploreCandidateGenerationStatus.pending)
          candidate,
    ];
    if (targets.isEmpty) return;
    final l10n = context.l10n;
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: l10n.styleExplore_deleteCandidatesTitle,
      content: l10n.styleExplore_deleteCandidatesMessage(targets.length),
      confirmText: l10n.common_delete,
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
      for (final target in targets) {
        final candidate = ref
            .read(exploreRunListNotifierProvider)
            .valueOrNull
            ?.runById(run.id)
            ?.candidateById(target.id);
        if (candidate == null ||
            candidate.generation.status ==
                ExploreCandidateGenerationStatus.pending) {
          continue;
        }
        final filePath = candidate.generation.filePath;
        if (filePath != null && !await store.deleteCandidateImage(filePath)) {
          continue;
        }
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
  void _openCandidateDetail(ExploreRun run, ExploreCandidate candidate) =>
      openExploreCandidate(context, ref, run, candidate);

  Future<void> _createFamilyFromSelection(
    ExploreRun run, {
    Set<String>? ids,
  }) async {
    final selected = [
      for (final candidate in run.candidates)
        if ((ids ?? _selectedIds).contains(candidate.id)) candidate,
    ];
    if (selected.isEmpty) return;
    if (await startExploreEvolution(context, ref, run, selected) && mounted) {
      _exitSelection();
    }
  }
}
