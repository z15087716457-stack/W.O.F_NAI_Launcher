import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'explore_lineage_panel.dart';

/// 右栏候选画廊：筛选 chips + 新建文件夹 + 牌堆分组 + 大图详情弹窗。
///
/// 牌堆分组 = 用户自建文件夹 + 未分类（与谱系 pile 的遗传血缘完全平行解耦）；
/// 收藏（heart 字段）是纯数据注释，任何时刻不移动/改名图库文件，
/// run 目录副本随 run 删除。
class ExploreCandidateGallery extends ConsumerStatefulWidget {
  const ExploreCandidateGallery({super.key});

  @override
  ConsumerState<ExploreCandidateGallery> createState() =>
      _ExploreCandidateGalleryState();
}

class _ExploreCandidateGalleryState
    extends ConsumerState<ExploreCandidateGallery> {
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
    final filter = ref.watch(exploreGalleryFilterProvider);

    if (run == null) {
      return _EmptyHint(
        icon: Icons.collections_outlined,
        text: l10n.styleExplore_galleryEmptyHint,
      );
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

    // 展示层反转：新生成图排最前（存储序与 #N 序号不动，牌堆组内同样最新在前）。
    final filtered = [
      for (final candidate in candidates)
        if (exploreCandidateMatchesFilter(candidate, filter)) candidate,
    ].reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectionMode)
          _buildSelectionBar(l10n, run)
        else
          _buildToolbar(theme, l10n, run, filter),
        Divider(height: 1, color: theme.dividerColor),
        // 谱系区（阶段 D）：无家族时不渲染，只留工具条+候选牌堆。
        ExploreLineagePanel(
          run: run,
          onOpenCandidate: (candidate) => _openCandidateDetail(run, candidate),
          hoverSession: _hoverSession,
        ),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyHint(
                  icon: Icons.filter_alt_off_outlined,
                  text: l10n.styleExplore_galleryEmptyHint,
                )
              : _buildDeck(theme, l10n, run, filtered),
        ),
      ],
    );
  }

  // ==================== 工具条 ====================

  Widget _buildToolbar(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreRun run,
    ExploreGalleryFilter filter,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final entry in _filterEntries(l10n))
            FilterChip(
              key: Key('explore-filter-${entry.value.name}'),
              label: Text(entry.key),
              selected: filter == entry.value,
              visualDensity: VisualDensity.compact,
              onSelected: (_) =>
                  ref.read(exploreGalleryFilterProvider.notifier).state =
                      entry.value,
            ),
          // 新建文件夹：牌堆分组即文件夹，未分类组恒在最后。
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
            icon: const Icon(Icons.account_tree_outlined, size: 16),
            label: Text(l10n.styleExplore_createFamily),
          ),
          FilledButton.tonalIcon(
            key: const Key('explore-gallery-merge-adopt'),
            onPressed: _selectedIds.isEmpty ? null : () => _adoptSelected(run),
            icon: const Icon(Icons.inventory_2_outlined, size: 16),
            label: Text(l10n.styleExplore_mergeAdopt),
          ),
        ],
      ),
    );
  }

  // ==================== 牌堆（分组） ====================

  /// 牌堆：按用户自建文件夹分组（未分类恒在最后），组头计数，
  /// 组内复用候选卡；筛选 chips 在其上叠加过滤。
  Widget _buildDeck(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreRun run,
    List<ExploreCandidate> filtered,
  ) {
    final groups = <({String? folderId, String title, IconData icon})>[
      for (final folder in run.folders)
        (folderId: folder.id, title: folder.name, icon: Icons.folder_outlined),
      (
        folderId: null,
        title: l10n.styleExplore_folderUncategorized,
        icon: Icons.inbox_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 160).floor().clamp(2, 3);
        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            for (final group in groups)
              ..._deckSection(
                theme,
                run,
                filtered,
                folderId: group.folderId,
                title: group.title,
                icon: group.icon,
                crossAxisCount: crossAxisCount,
              ),
          ],
        );
      },
    );
  }

  List<Widget> _deckSection(
    ThemeData theme,
    ExploreRun run,
    List<ExploreCandidate> filtered, {
    required String? folderId,
    required String title,
    required IconData icon,
    required int crossAxisCount,
  }) {
    final members = [
      for (final candidate in filtered)
        if (candidate.folderId == folderId) candidate,
    ];
    if (members.isEmpty) return const [];
    final color = folderId == null
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;
    return [
      Padding(
        key: Key('explore-deck-header-${folderId ?? 'uncategorized'}'),
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '$title · ${members.length}',
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
            const Spacer(),
            if (folderId != null) ...[
              IconButton(
                key: Key('explore-folder-rename-$folderId'),
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                tooltip: context.l10n.styleExplore_renameFolder,
                onPressed: () => _renameFolder(run, folderId),
                icon: const Icon(Icons.drive_file_rename_outline),
              ),
              IconButton(
                key: Key('explore-folder-delete-$folderId'),
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                tooltip: context.l10n.styleExplore_deleteFolder,
                onPressed: () => _deleteFolder(run, folderId),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
      ),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: members.length,
        itemBuilder: (context, index) =>
            _buildCandidateCard(run, members[index]),
      ),
    ];
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
    return _CandidateCard(
      key: ValueKey('explore-candidate-${candidate.id}'),
      run: run,
      candidate: candidate,
      sequenceNumber:
          run.candidates.indexWhere((c) => c.id == candidate.id) + 1,
      selectionMode: _selectionMode,
      selected: _selectedIds.contains(candidate.id),
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

  /// 候选详情弹窗（画廊卡片与谱系区候选堆缩略图点击共用）。
  ///
  /// 翻页序 = 打开瞬间的筛选快照；点开的候选不在快照内（谱系区旁路）
  /// 时退化为单张序列。
  void _openCandidateDetail(ExploreRun run, ExploreCandidate candidate) {
    final filter = ref.read(exploreGalleryFilterProvider);
    // 翻页序 = 展示序（最新在前），与画廊反转对齐——向右箭头 = 下一张更新的图。
    final candidateIds = [
      for (final item in run.candidates)
        if (exploreCandidateMatchesFilter(item, filter)) item.id,
    ].reversed.toList();
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

  static List<MapEntry<String, ExploreGalleryFilter>> _filterEntries(
    AppLocalizations l10n,
  ) {
    return [
      MapEntry(l10n.styleExplore_filterAll, ExploreGalleryFilter.all),
      MapEntry(l10n.styleExplore_filterHearted, ExploreGalleryFilter.hearted),
      MapEntry(l10n.styleExplore_filterFailed, ExploreGalleryFilter.failed),
    ];
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              text,
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
}

/// 候选卡：缩略图 + #序号 + 轮次号 + 状态图标 + 右上角收藏钮。
/// 多选模式下点按切换选择、角标换勾选圈；普通模式长按进入多选。
class _CandidateCard extends ConsumerWidget {
  const _CandidateCard({
    super.key,
    required this.run,
    required this.candidate,
    required this.sequenceNumber,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
    required this.onEnterSelection,
    required this.onOpenDetail,
  });

  final ExploreRun run;
  final ExploreCandidate candidate;
  final int sequenceNumber;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelect;
  final VoidCallback onEnterSelection;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final roundNumber = run.roundById(candidate.roundId)?.number;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: selectionMode ? onToggleSelect : onOpenDetail,
        onLongPress: selectionMode ? null : onEnterSelection,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildThumbnail(theme, l10n),
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
            Positioned(
              left: 4,
              top: 4,
              child: _OverlayChip(
                text:
                    '#$sequenceNumber'
                    '${roundNumber != null ? ' · ${l10n.styleExplore_roundNumber(roundNumber)}' : ''}',
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: selectionMode
                  ? _buildSelectionIndicator(theme)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 待生成/失败态保留状态徽标，与收藏钮并存。
                        if (candidate.generation.status !=
                            ExploreCandidateGenerationStatus.done) ...[
                          _buildStatusIcon(theme),
                          const SizedBox(width: 4),
                        ],
                        _buildHeartButton(theme, ref),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(ThemeData theme) {
    return Icon(
      selected ? Icons.check_circle : Icons.radio_button_unchecked,
      size: 18,
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant,
    );
  }

  Widget _buildThumbnail(ThemeData theme, AppLocalizations l10n) {
    final filePath = candidate.generation.filePath;
    if (candidate.generation.status ==
            ExploreCandidateGenerationStatus.pending ||
        filePath == null) {
      return _ThumbnailPlaceholder(
        icon: switch (candidate.generation.status) {
          ExploreCandidateGenerationStatus.failed => Icons.error_outline,
          // done 但无副本 = 已删图（记录保留）。
          ExploreCandidateGenerationStatus.done => Icons.broken_image_outlined,
          ExploreCandidateGenerationStatus.pending => Icons.hourglass_empty,
        },
        tooltip:
            candidate.generation.status ==
                ExploreCandidateGenerationStatus.failed
            ? (candidate.generation.error ?? '')
            : (candidate.generation.status ==
                      ExploreCandidateGenerationStatus.done
                  ? l10n.styleExplore_candidateMissing
                  : null),
      );
    }
    return Image.file(
      File(filePath),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: 360,
      errorBuilder: (context, error, stackTrace) => _ThumbnailPlaceholder(
        icon: Icons.broken_image_outlined,
        tooltip: l10n.styleExplore_candidateMissing,
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme) {
    switch (candidate.generation.status) {
      case ExploreCandidateGenerationStatus.pending:
        return const _OverlayIcon(icon: Icons.schedule);
      case ExploreCandidateGenerationStatus.failed:
        return _OverlayIcon(
          icon: Icons.error_outline,
          color: theme.colorScheme.error,
        );
      case ExploreCandidateGenerationStatus.done:
        return const SizedBox.shrink();
    }
  }

  /// 收藏钮（原心形角标原位改造）：点即切换 heart 字段。
  Widget _buildHeartButton(ThemeData theme, WidgetRef ref) {
    final hearted = candidate.review.heart;
    return InkWell(
      key: Key('explore-candidate-heart-${candidate.id}'),
      customBorder: const CircleBorder(),
      onTap: () => _toggleHeart(ref),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.75),
          shape: BoxShape.circle,
        ),
        child: Icon(
          hearted ? Icons.favorite : Icons.favorite_border,
          size: 14,
          color: hearted
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  void _toggleHeart(WidgetRef ref) {
    ref
        .read(exploreRunListNotifierProvider.notifier)
        .updateReview(run.id, candidate.id, heart: !candidate.review.heart);
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder({required this.icon, this.tooltip});

  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Center(
      child: Icon(icon, size: 32, color: theme.colorScheme.onSurfaceVariant),
    );
    final message = tooltip;
    if (message == null || message.isEmpty) return child;
    return Tooltip(message: message, child: child);
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({required this.text});

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

class _OverlayIcon extends StatelessWidget {
  const _OverlayIcon({required this.icon, this.color});

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

/// 候选详情弹窗：大图 + Roll 快照全文（可复制）+ seed + 参数快照 + 归类区
/// + 出口动作（收编为块 / 导入元数据 / 删除候选图）。
///
/// 按 id 实时解析 run 与候选，收藏/归类/删图等写操作后内容自动刷新。
/// 翻页（左右箭头 + ←/→/小键盘）走打开瞬间传入的快照序列，边界停住不循环。
class ExploreCandidateDetailDialog extends ConsumerStatefulWidget {
  const ExploreCandidateDetailDialog({
    super.key,
    required this.runId,
    required this.candidateIds,
    this.initialIndex = 0,
  });

  final String runId;

  /// 翻页序（打开瞬间的筛选快照，按顺序）。
  final List<String> candidateIds;

  final int initialIndex;

  @override
  ConsumerState<ExploreCandidateDetailDialog> createState() =>
      _ExploreCandidateDetailDialogState();
}

class _ExploreCandidateDetailDialogState
    extends ConsumerState<ExploreCandidateDetailDialog> {
  late int _index = widget.initialIndex.clamp(
    0,
    widget.candidateIds.isEmpty ? 0 : widget.candidateIds.length - 1,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final run = ref
        .watch(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(widget.runId);
    final candidate = _resolve(run);

    if (run == null || candidate == null) {
      return Dialog(
        key: const Key('explore-candidate-detail'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.styleExplore_candidateMissing,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.common_close),
              ),
            ],
          ),
        ),
      );
    }

    final generation = candidate.generation;
    final snapshot = run.paramsSnapshot;
    final roll = candidate.rollSnapshot;

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        key: const Key('explore-candidate-detail'),
        child: ConstrainedBox(
          // 详情弹窗给足图区：窗口随屏取 85%×88%（E2 定稿，网格排版不动）。
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.styleExplore_candidateDetailTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (widget.candidateIds.length > 1)
                      Text(
                        l10n.styleExplore_candidatePosition(
                          _index + 1,
                          widget.candidateIds.length,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    IconButton(
                      tooltip: l10n.common_close,
                      iconSize: 18,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.dividerColor),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 图:信息 = 7:3（静定）：图区给足，信息列窄排
                    Expanded(
                      flex: 7,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _buildDetailImage(theme, l10n, candidate),
                          ),
                          if (_canMove(run, -1))
                            Positioned(
                              left: 4,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: _buildPagerButton(
                                  key: const Key('explore-candidate-prev'),
                                  icon: Icons.chevron_left,
                                  tooltip: l10n.styleExplore_prevCandidate,
                                  onPressed: () => _move(run, -1),
                                ),
                              ),
                            ),
                          if (_canMove(run, 1))
                            Positioned(
                              right: 4,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: _buildPagerButton(
                                  key: const Key('explore-candidate-next'),
                                  icon: Icons.chevron_right,
                                  tooltip: l10n.styleExplore_nextCandidate,
                                  onPressed: () => _move(run, 1),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    VerticalDivider(width: 1, color: theme.dividerColor),
                    Expanded(
                      flex: 3,
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                snapshot.model,
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                '${snapshot.width}×${snapshot.height}',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                'steps ${snapshot.steps}',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                'scale ${snapshot.scale}',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                snapshot.sampler,
                                style: theme.textTheme.bodySmall,
                              ),
                              if (generation.seed != null)
                                Text(
                                  l10n.styleExplore_seedLabel(
                                    generation.seed.toString(),
                                  ),
                                  style: theme.textTheme.bodySmall,
                                ),
                              if (generation.elapsedMs != null)
                                Text(
                                  '${generation.elapsedMs} ms',
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                          if (generation.error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              generation.error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildExportActions(
                            context,
                            ref,
                            theme,
                            l10n,
                            run,
                            candidate,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                l10n.styleExplore_rollSnapshot,
                                style: theme.textTheme.titleSmall,
                              ),
                              const Spacer(),
                              IconButton(
                                key: const Key(
                                  'explore-candidate-copy-snapshot',
                                ),
                                tooltip: l10n.common_copy,
                                iconSize: 18,
                                onPressed: roll == null
                                    ? null
                                    : () => _copySnapshot(context, roll),
                                icon: const Icon(Icons.copy_outlined),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (roll != null) ...[
                            SelectableText(
                              roll.positive,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              roll.negative,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (roll.instanceRolls.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              for (final instance in roll.instanceRolls)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: SelectableText(
                                    '[${instance.lane}] '
                                    '${instance.blockTitle}: '
                                    '${instance.rolledText}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ] else
                            Text(
                              l10n.styleExplore_previewEmpty,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 16),
                          ExploreFolderAssignBar(
                            run: run,
                            candidate: candidate,
                            onAssigned: (folderId) =>
                                _advanceAfterAssign(run, folderId),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 当前位候选；记录已删（详情打开期间）返回 null。
  ExploreCandidate? _resolve(ExploreRun? run) {
    if (run == null || widget.candidateIds.isEmpty) return null;
    return run.candidateById(widget.candidateIds[_index]);
  }

  /// 该方向是否还有可翻的候选（跳过已删记录；边界停住不循环）。
  bool _canMove(ExploreRun run, int delta) {
    var next = _index + delta;
    while (next >= 0 && next < widget.candidateIds.length) {
      if (run.candidateById(widget.candidateIds[next]) != null) return true;
      next += delta;
    }
    return false;
  }

  void _move(ExploreRun run, int delta) {
    var next = _index + delta;
    while (next >= 0 && next < widget.candidateIds.length) {
      if (run.candidateById(widget.candidateIds[next]) != null) {
        setState(() => _index = next);
        return;
      }
      next += delta;
    }
  }

  /// 归档后自动跳到下一张未分类候选（连续归档不打断）；已无则留在原地。
  void _advanceAfterAssign(ExploreRun run, String? folderId) {
    if (folderId == null || !mounted) return;
    for (var next = _index + 1; next < widget.candidateIds.length; next++) {
      final candidate = run.candidateById(widget.candidateIds[next]);
      if (candidate == null) continue;
      if (candidate.folderId == null) {
        setState(() => _index = next);
        return;
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final run = ref
        .read(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(widget.runId);
    if (run == null) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.numpad4) {
      if (_canMove(run, -1)) _move(run, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.numpad6) {
      if (_canMove(run, 1)) _move(run, 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildPagerButton({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      key: key,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }

  /// 出口动作行：收编为块 / 导入元数据 / 删除候选图（有副本即可删）。
  Widget _buildExportActions(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    ExploreRun run,
    ExploreCandidate candidate,
  ) {
    final roll = candidate.rollSnapshot;
    final canDeleteImage = candidate.generation.filePath != null;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        OutlinedButton.icon(
          key: const Key('explore-candidate-adopt-block'),
          onPressed: roll == null
              ? null
              : () => ExploreCandidateActions.adoptSingle(
                  context,
                  ref,
                  run: run,
                  candidate: candidate,
                ),
          icon: const Icon(Icons.inventory_2_outlined, size: 16),
          label: Text(l10n.styleExplore_adoptAsBlock),
        ),
        OutlinedButton.icon(
          key: const Key('explore-candidate-fixate'),
          onPressed: roll == null
              ? null
              : () => ExploreCandidateActions.fixateAsTemplate(
                  context,
                  ref,
                  candidate: candidate,
                ),
          icon: const Icon(Icons.input_outlined, size: 16),
          label: Text(l10n.styleExplore_fixateAsTemplate),
        ),
        if (canDeleteImage)
          OutlinedButton.icon(
            key: const Key('explore-candidate-delete-image'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () => ExploreCandidateActions.deleteImage(
              context,
              ref,
              runId: run.id,
              candidate: candidate,
            ),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: Text(l10n.styleExplore_deleteImage),
          ),
      ],
    );
  }

  Widget _buildDetailImage(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreCandidate candidate,
  ) {
    final filePath = candidate.generation.filePath;
    if (filePath == null) {
      return _ThumbnailPlaceholder(
        icon: Icons.broken_image_outlined,
        tooltip: l10n.styleExplore_candidateMissing,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Image.file(
        File(filePath),
        fit: BoxFit.contain,
        // 详情大图按图区尺寸解码（原图全尺寸解码是内存尖峰）。
        cacheWidth: 1600,
        errorBuilder: (context, error, stackTrace) => _ThumbnailPlaceholder(
          icon: Icons.broken_image_outlined,
          tooltip: l10n.styleExplore_candidateMissing,
        ),
      ),
    );
  }

  void _copySnapshot(BuildContext context, ExploreRollSnapshot roll) {
    final buffer = StringBuffer()
      ..writeln(roll.positive)
      ..write('---\n')
      ..writeln(roll.negative);
    for (final instance in roll.instanceRolls) {
      buffer.writeln(
        '[${instance.lane}] ${instance.blockTitle}: ${instance.rolledText}',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.styleExplore_copiedToClipboard),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }
}
