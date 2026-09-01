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
import 'explore_candidate_actions.dart';
import 'explore_create_family_dialog.dart';
import 'explore_formal_review_overlay.dart';
import 'explore_lineage_panel.dart';

/// 右栏候选画廊：筛选 chips + 正式筛选入口 + 网格/牌堆视图 + 大图详情弹窗。
///
/// 牌堆语义：心形与 T/S/R 预标记全部是纯数据注释（review 字段），
/// 任何时刻不移动/改名图库文件；run 目录副本随 run 删除。
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final run = ref.watch(exploreActiveRunProvider);
    final filter = ref.watch(exploreGalleryFilterProvider);
    final viewMode = ref.watch(exploreGalleryViewModeProvider);

    if (run == null) {
      return _EmptyHint(
        icon: Icons.collections_outlined,
        text: l10n.styleExplore_galleryEmptyHint,
      );
    }

    final candidates = run.candidates;
    // 候选集合变化后清掉失效的选择项（删 run/重选 run 等）。
    final existingIds = candidates.map((c) => c.id).toSet();
    _selectedIds.removeWhere((id) => !existingIds.contains(id));

    final filtered = [
      for (final candidate in candidates)
        if (exploreCandidateMatchesFilter(candidate, filter)) candidate,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectionMode)
          _buildSelectionBar(l10n, run)
        else
          _buildToolbar(theme, l10n, run, filter, viewMode),
        Divider(height: 1, color: theme.dividerColor),
        // 谱系区（阶段 D）：无家族时不渲染，只留工具条+候选网格。
        ExploreLineagePanel(
          run: run,
          onOpenCandidate: (candidate) => _openCandidateDetail(run, candidate),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyHint(
                  icon: Icons.filter_alt_off_outlined,
                  text: l10n.styleExplore_galleryEmptyHint,
                )
              : _selectionMode || viewMode == ExploreGalleryViewMode.grid
              ? _buildGrid(run, filtered)
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
    ExploreGalleryViewMode viewMode,
  ) {
    final canReview =
        exploreReviewableStatuses.contains(run.status) &&
        run.reviewableCandidates.isNotEmpty;
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
          // 正式筛选入口：有可审查候选（done）且状态允许时可用。
          ActionChip(
            key: const Key('explore-formal-review'),
            avatar: const Icon(Icons.rate_review_outlined, size: 16),
            label: Text(l10n.styleExplore_formalReview),
            onPressed: canReview ? () => _enterFormalReview(run) : null,
          ),
          // 网格/牌堆视图切换。
          IconButton(
            key: const Key('explore-gallery-view-toggle'),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: viewMode == ExploreGalleryViewMode.grid
                ? l10n.styleExplore_viewDeck
                : l10n.styleExplore_viewGrid,
            onPressed: () =>
                ref
                    .read(exploreGalleryViewModeProvider.notifier)
                    .state = viewMode == ExploreGalleryViewMode.grid
                ? ExploreGalleryViewMode.deck
                : ExploreGalleryViewMode.grid,
            icon: Icon(
              viewMode == ExploreGalleryViewMode.grid
                  ? Icons.view_agenda_outlined
                  : Icons.grid_view_outlined,
            ),
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

  // ==================== 网格 / 牌堆 ====================

  Widget _buildGrid(ExploreRun run, List<ExploreCandidate> filtered) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 160).floor().clamp(2, 3);
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) =>
              _buildCandidateCard(run, filtered[index]),
        );
      },
    );
  }

  /// 牌堆视图：按正式标签分组（珍宝/特殊/拒绝/未归类），组头计数，
  /// 组内复用候选卡；预标记仍作角标留在卡上。
  Widget _buildDeck(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreRun run,
    List<ExploreCandidate> filtered,
  ) {
    final groups = <(ExploreReviewLabel?, String, IconData, Color)>[
      (
        ExploreReviewLabel.treasure,
        l10n.styleExplore_markTreasure,
        Icons.diamond_outlined,
        Colors.amber.shade700,
      ),
      (
        ExploreReviewLabel.special,
        l10n.styleExplore_markSpecial,
        Icons.star_outline,
        Colors.deepPurple,
      ),
      (
        ExploreReviewLabel.reject,
        l10n.styleExplore_markReject,
        Icons.block,
        theme.colorScheme.error,
      ),
      (
        null,
        l10n.styleExplore_reviewUnlabeled,
        Icons.inbox_outlined,
        theme.colorScheme.onSurfaceVariant,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 160).floor().clamp(2, 3);
        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            for (final (label, title, icon, color) in groups)
              ..._deckSection(
                theme,
                run,
                filtered,
                label: label,
                title: title,
                icon: icon,
                color: color,
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
    required ExploreReviewLabel? label,
    required String title,
    required IconData icon,
    required Color color,
    required int crossAxisCount,
  }) {
    final members = [
      for (final candidate in filtered)
        if (candidate.review.label == label) candidate,
    ];
    if (members.isEmpty) return const [];
    return [
      Padding(
        key: Key('explore-deck-header-${label?.name ?? 'unlabeled'}'),
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '$title · ${members.length}',
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
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

  Widget _buildCandidateCard(ExploreRun run, ExploreCandidate candidate) {
    return _CandidateCard(
      key: ValueKey('explore-candidate-${candidate.id}'),
      run: run,
      candidate: candidate,
      sequenceNumber: run.candidates.indexOf(candidate) + 1,
      selectionMode: _selectionMode,
      selected: _selectedIds.contains(candidate.id),
      onToggleSelect: () => _toggleSelect(candidate.id),
      onEnterSelection: () => _enterSelection(candidate.id),
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

  /// 候选详情弹窗（谱系区候选堆缩略图点击共用）。
  void _openCandidateDetail(ExploreRun run, ExploreCandidate candidate) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ExploreCandidateDetailDialog(
        runId: run.id,
        candidateId: candidate.id,
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

  Future<void> _enterFormalReview(ExploreRun run) async {
    try {
      await ref
          .read(exploreRunListNotifierProvider.notifier)
          .beginReview(run.id);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final completed = await ExploreFormalReviewOverlay.show(
      context,
      runId: run.id,
    );
    if (completed && mounted) {
      AppToast.success(context, context.l10n.styleExplore_reviewCompleted);
    }
  }

  static List<MapEntry<String, ExploreGalleryFilter>> _filterEntries(
    AppLocalizations l10n,
  ) {
    return [
      MapEntry(l10n.styleExplore_filterAll, ExploreGalleryFilter.all),
      MapEntry(l10n.styleExplore_filterHearted, ExploreGalleryFilter.hearted),
      MapEntry(
        l10n.styleExplore_filterPendingReview,
        ExploreGalleryFilter.pendingReview,
      ),
      MapEntry(l10n.styleExplore_markTreasure, ExploreGalleryFilter.treasure),
      MapEntry(l10n.styleExplore_markSpecial, ExploreGalleryFilter.special),
      MapEntry(l10n.styleExplore_markReject, ExploreGalleryFilter.reject),
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

/// 候选卡：缩略图 + #序号 + 轮次号 + 状态图标 + 心形 + T/S/R 预标记。
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
  });

  final ExploreRun run;
  final ExploreCandidate candidate;
  final int sequenceNumber;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelect;
  final VoidCallback onEnterSelection;

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
        onTap: selectionMode ? onToggleSelect : () => _showDetail(context),
        onLongPress: selectionMode ? null : onEnterSelection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
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
                        : _buildStatusIcon(theme, l10n),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SmallActionButton(
                    key: Key('explore-candidate-heart-${candidate.id}'),
                    icon: candidate.review.heart
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: candidate.review.heart
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    tooltip: l10n.styleExplore_filterHearted,
                    onPressed: () => _toggleHeart(ref),
                  ),
                  _SmallLabelButton(
                    key: Key('explore-candidate-treasure-${candidate.id}'),
                    label: 'T',
                    selected:
                        candidate.review.preliminaryLabel ==
                        ExploreReviewLabel.treasure,
                    tooltip: l10n.styleExplore_markTreasure,
                    onPressed: () =>
                        _toggleLabel(ref, ExploreReviewLabel.treasure),
                  ),
                  _SmallLabelButton(
                    key: Key('explore-candidate-special-${candidate.id}'),
                    label: 'S',
                    selected:
                        candidate.review.preliminaryLabel ==
                        ExploreReviewLabel.special,
                    tooltip: l10n.styleExplore_markSpecial,
                    onPressed: () =>
                        _toggleLabel(ref, ExploreReviewLabel.special),
                  ),
                  _SmallLabelButton(
                    key: Key('explore-candidate-reject-${candidate.id}'),
                    label: 'R',
                    selected:
                        candidate.review.preliminaryLabel ==
                        ExploreReviewLabel.reject,
                    tooltip: l10n.styleExplore_markReject,
                    onPressed: () =>
                        _toggleLabel(ref, ExploreReviewLabel.reject),
                  ),
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

  Widget _buildStatusIcon(ThemeData theme, AppLocalizations l10n) {
    switch (candidate.generation.status) {
      case ExploreCandidateGenerationStatus.pending:
        return const _OverlayIcon(icon: Icons.schedule);
      case ExploreCandidateGenerationStatus.failed:
        return _OverlayIcon(
          icon: Icons.error_outline,
          color: theme.colorScheme.error,
        );
      case ExploreCandidateGenerationStatus.done:
        if (candidate.review.heart) {
          return _OverlayIcon(
            icon: Icons.favorite,
            color: theme.colorScheme.error,
          );
        }
        return const SizedBox.shrink();
    }
  }

  void _toggleHeart(WidgetRef ref) {
    ref
        .read(exploreRunListNotifierProvider.notifier)
        .updateReview(run.id, candidate.id, heart: !candidate.review.heart);
  }

  void _toggleLabel(WidgetRef ref, ExploreReviewLabel label) {
    final selected = candidate.review.preliminaryLabel == label;
    ref
        .read(exploreRunListNotifierProvider.notifier)
        .updateReview(
          run.id,
          candidate.id,
          preliminaryLabel: selected ? null : label,
          clearPreliminaryLabel: selected,
        );
  }

  void _showDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ExploreCandidateDetailDialog(
        runId: run.id,
        candidateId: candidate.id,
      ),
    );
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

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: color ?? theme.colorScheme.onSurfaceVariant),
    );
  }
}

class _SmallLabelButton extends StatelessWidget {
  const _SmallLabelButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.tooltip,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// 候选详情弹窗：大图 + Roll 快照全文（可复制）+ seed + 参数快照 + 出口动作
/// （收编为块 / 固化为模板 / Reject 删图）。
///
/// 按 id 实时解析 run 与候选，评审/删图等写操作后内容自动刷新。
class ExploreCandidateDetailDialog extends ConsumerWidget {
  const ExploreCandidateDetailDialog({
    super.key,
    required this.runId,
    required this.candidateId,
  });

  final String runId;
  final String candidateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final run = ref
        .watch(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(runId);
    final candidate = run?.candidateById(candidateId);

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

    return Dialog(
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
                    child: _buildDetailImage(theme, l10n, candidate),
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
                              key: const Key('explore-candidate-copy-snapshot'),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 出口动作行：收编为块 / 固化为模板 / Reject 删图（仅 reject 且有副本）。
  Widget _buildExportActions(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    ExploreRun run,
    ExploreCandidate candidate,
  ) {
    final roll = candidate.rollSnapshot;
    final canDeleteImage =
        ExploreCandidateActions.isRejected(candidate) &&
        candidate.generation.filePath != null;
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
          icon: const Icon(Icons.push_pin_outlined, size: 16),
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
