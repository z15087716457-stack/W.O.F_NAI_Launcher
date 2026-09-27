import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/gallery_scan_progress_provider.dart';

/// 本地画廊扫描时固定显示在分类侧栏底部的进度卡。
class GalleryScanProgressPanel extends ConsumerWidget {
  const GalleryScanProgressPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(galleryScanProgressProvider);
    if (!scanState.isScanning) return const SizedBox.shrink();
    return GalleryScanProgressCard(state: scanState);
  }
}

/// 单次扫描的进度使用 processed / total；元数据数量是图库累计值，
/// 因此只放在统计区，不能再混入进度条的分段比例。
class GalleryScanProgressCard extends StatelessWidget {
  const GalleryScanProgressCard({super.key, required this.state});

  final ScanProgressState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final stats = state.cacheStats;
    final progress = state.progress.clamp(0.0, 1.0);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final fileName = stats.currentFile.split(RegExp(r'[/\\]')).last;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.38),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.galleryScan_organizingGallery,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: stats.totalImages > 0 ? progress : null,
              minHeight: 4,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                l10n.galleryScan_processing,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${number.format(stats.processed)} / ${number.format(stats.totalImages)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Divider(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: 0.32),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: l10n.localGallery_withMetadata,
                  value: number.format(stats.withMetadata),
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: colors.outlineVariant.withValues(alpha: 0.32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(
                  label: l10n.localGallery_skipped,
                  value: number.format(stats.skipped),
                ),
              ),
            ],
          ),
          if (stats.failedMetadata > 0) ...[
            const SizedBox(height: 8),
            Text(
              l10n.galleryScan_failed(stats.failedMetadata),
              style: theme.textTheme.labelSmall?.copyWith(color: colors.error),
            ),
          ],
          if (fileName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 13,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
