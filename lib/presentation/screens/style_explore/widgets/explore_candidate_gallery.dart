import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/style_explore/explore_run_provider.dart';

/// 右栏候选画廊：筛选 chips + 候选网格 + 大图详情弹窗。
///
/// 牌堆语义：心形与 T/S/R 预标记全部是纯数据注释（review 字段），
/// 任何时刻不移动/改名图库文件；run 目录副本随 run 删除。
class ExploreCandidateGallery extends ConsumerWidget {
  const ExploreCandidateGallery({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final filtered = [
      for (final candidate in candidates)
        if (exploreCandidateMatchesFilter(candidate, filter)) candidate,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
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
              // 正式筛选（阶段 C 开放，先置灰）。
              Tooltip(
                message: l10n.styleExplore_formalReviewNextStage,
                child: ActionChip(
                  key: const Key('explore-formal-review'),
                  avatar: const Icon(Icons.rate_review_outlined, size: 16),
                  label: Text(l10n.styleExplore_formalReview),
                  onPressed: null,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyHint(
                  icon: Icons.filter_alt_off_outlined,
                  text: l10n.styleExplore_galleryEmptyHint,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = (constraints.maxWidth / 160)
                        .floor()
                        .clamp(2, 3);
                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final candidate = filtered[index];
                        return _CandidateCard(
                          key: ValueKey('explore-candidate-${candidate.id}'),
                          run: run,
                          candidate: candidate,
                          sequenceNumber: candidates.indexOf(candidate) + 1,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
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
class _CandidateCard extends ConsumerWidget {
  const _CandidateCard({
    super.key,
    required this.run,
    required this.candidate,
    required this.sequenceNumber,
  });

  final ExploreRun run;
  final ExploreCandidate candidate;
  final int sequenceNumber;

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
        onTap: () => _showDetail(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnail(theme, l10n),
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
                    child: _buildStatusIcon(theme, l10n),
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

  Widget _buildThumbnail(ThemeData theme, AppLocalizations l10n) {
    final filePath = candidate.generation.filePath;
    if (candidate.generation.status ==
            ExploreCandidateGenerationStatus.pending ||
        filePath == null) {
      return _ThumbnailPlaceholder(
        icon:
            candidate.generation.status ==
                ExploreCandidateGenerationStatus.failed
            ? Icons.error_outline
            : Icons.hourglass_empty,
        tooltip:
            candidate.generation.status ==
                ExploreCandidateGenerationStatus.failed
            ? (candidate.generation.error ?? '')
            : null,
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

  void _showDetail(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          ExploreCandidateDetailDialog(run: run, candidate: candidate),
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

/// 候选详情弹窗：大图 + Roll 快照全文（可复制）+ seed + 参数快照 + 状态。
class ExploreCandidateDetailDialog extends StatelessWidget {
  const ExploreCandidateDetailDialog({
    super.key,
    required this.run,
    required this.candidate,
  });

  final ExploreRun run;
  final ExploreCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
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
                  Expanded(flex: 7, child: _buildDetailImage(theme, l10n)),
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

  Widget _buildDetailImage(ThemeData theme, AppLocalizations l10n) {
    final filePath = candidate.generation.filePath;
    if (filePath == null) {
      return _ThumbnailPlaceholder(
        icon: Icons.hourglass_empty,
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
