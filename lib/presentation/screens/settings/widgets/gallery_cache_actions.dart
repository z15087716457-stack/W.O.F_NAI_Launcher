import 'settings_tile.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/datasources/gallery_data_source.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/repositories/gallery_folder_repository.dart';
import '../../../../data/services/gallery/index.dart';
import '../../../../data/services/thumbnail_service.dart';
import '../../../providers/local_gallery_provider.dart';
import '../../../widgets/common/app_toast.dart';
import 'cache_statistics_tile.dart';
import 'settings_columns.dart';

/// 画廊重新扫描按钮
///
/// 触发全局扫描任务（与自动扫描使用同一套逻辑）：
/// - 检查数据一致性（标记不存在的文件）
/// - 查漏补缺（新文件、变更文件）
/// - 提取元数据
///
/// 注意：不清空数据，只做增量更新
class GalleryCacheActions extends ConsumerStatefulWidget {
  const GalleryCacheActions({super.key});

  @override
  ConsumerState<GalleryCacheActions> createState() =>
      _GalleryCacheActionsState();
}

class _GalleryCacheActionsState extends ConsumerState<GalleryCacheActions> {
  bool _isScanning = false;

  // 扫描进度（来自全局 ScanStateManager）
  double? _scanProgress;
  String? _scanPhase;
  int _processedCount = 0;
  int _totalCount = 0;

  // 缩略图缓存清理进行中标志（防重入）
  bool _isEvictingThumbnails = false;

  /// 重新扫描
  ///
  /// 触发全局扫描任务（与自动扫描使用同一套逻辑）：
  /// - 检查数据一致性（标记不存在的文件）
  /// - 查漏补缺（新文件、变更文件）
  /// - 提取元数据
  Future<void> _rescanGallery() async {
    if (_isScanning) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.refresh_rounded, size: 22),
        title: Text(context.l10n.galleryCache_rescanTitle),
        content: Text(context.l10n.galleryCache_rescanContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.galleryCache_startScan),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;

    // 检查是否已有扫描在进行中
    if (ScanStateManager.instance.isScanning) {
      AppToast.warning(context, context.l10n.galleryCache_scanAlreadyRunning);
      return;
    }

    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _scanPhase = context.l10n.galleryCache_preparing;
      _processedCount = 0;
      _totalCount = 0;
    });

    try {
      // 主源 + 全部存在的额外源
      final rootDirs = await GalleryFolderRepository.instance.getAllRootDirs();

      if (!mounted) return;

      if (rootDirs.isEmpty) {
        AppToast.error(context, context.l10n.galleryCache_noGalleryFolder);
        return;
      }

      // 使用流式扫描器处理文件（边扫描边处理，实时更新）
      // 这与自动扫描使用同一套逻辑
      final dataSource = GalleryDataSource();
      final scanner = GalleryStreamScanner(dataSource: dataSource);

      // 订阅统计流以实时更新UI
      final statsSubscription = scanner.statsStream.listen((stats) {
        if (!mounted) return;
        setState(() {
          _totalCount = stats.totalDiscovered;
          _processedCount = stats.processed + stats.skipped;
          _scanProgress = stats.progress;
          _scanPhase = context.l10n.galleryCache_scanningPhase(
            stats.processed + stats.skipped,
            stats.totalDiscovered,
          );
        });
      });

      await scanner.startScanning(
        rootDirs,
        retryMissingMetadata: true,
        retryFailedMetadata: true,
        onFileProcessed: (result, stats) {
          AppLogger.d(
            '[Rescan] Processed: ${result.path.split(Platform.pathSeparator).last}, '
                'stage: ${result.stage}',
            'RescanGallery',
          );
        },
      );

      await statsSubscription.cancel();

      if (!mounted) return;

      // 刷新 Provider
      ref.invalidate(localGalleryNotifierProvider);
      ref.invalidate(cacheStatisticsProvider);

      AppToast.success(context, context.l10n.galleryCache_scanComplete);
    } catch (e, stack) {
      AppLogger.e('Rescan failed', e, stack, 'RescanGallery');
      if (!mounted) return;
      AppToast.error(context, context.l10n.galleryCache_scanFailed(e));
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanProgress = null;
          _scanPhase = null;
        });
      }
    }
  }

  /// 清理缩略图缓存（P7）
  ///
  /// 对每个图库源按 LRU 淘汰超限的 `.thumbs` 缩略图缓存（只删 `.thumbs`
  /// 内的 `.thumb.jpg`，不触碰原图），完成后提示清理数量与释放空间。
  Future<void> _evictThumbnailCache() async {
    if (_isEvictingThumbnails) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.cleaning_services_rounded,
          color: Colors.blue,
          size: 48,
        ),
        title: Text(l10n.galleryCache_evictThumbnailsTitle),
        content: Text(l10n.galleryCache_evictThumbnailsContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.cleaning_services_rounded),
            label: Text(l10n.galleryCache_evictThumbnailsStart),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isEvictingThumbnails = true);
    final progress = AppToast.showProgress(
      context,
      l10n.galleryCache_evictThumbnailsRunning,
    );

    try {
      final service = ref.read(thumbnailServiceProvider);
      final roots = await GalleryFolderRepository.instance.getAllRootDirs();

      var evictedCount = 0;
      var evictedBytes = 0;
      for (final dir in roots) {
        final result = await service.evictThumbnailCache(dir.path);
        evictedCount += result.evictedCount;
        evictedBytes += result.evictedBytes;
      }

      if (evictedCount > 0) {
        final freedMB = (evictedBytes / 1024 / 1024).toStringAsFixed(1);
        progress.complete(
          message: l10n.galleryCache_evictThumbnailsDone(evictedCount, freedMB),
        );
      } else {
        progress.complete(message: l10n.galleryCache_evictThumbnailsNone);
      }
    } catch (e, stack) {
      AppLogger.e(
        'Evict thumbnail cache failed',
        e,
        stack,
        'GalleryCacheActions',
      );
      progress.fail(message: l10n.galleryCache_evictThumbnailsFailed('$e'));
    } finally {
      if (mounted) {
        setState(() => _isEvictingThumbnails = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SettingsColumns(
      equalHeights: true,
      left: SettingsTile(
        key: const Key('settings-rescan-row'),
        controlWrapWidth: 300 * MediaQuery.textScalerOf(context).scale(1),
        hoverFeedback: !_isScanning,
        title: Text(context.l10n.galleryCache_rescan),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isScanning
                  ? (_scanPhase ?? context.l10n.galleryCache_scanning)
                  : context.l10n.galleryCache_rescanSubtitle,
            ),
            if (_isScanning && _scanProgress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _scanProgress,
                color: colors.primary,
              ),
              if (_totalCount > 0) Text('$_processedCount / $_totalCount'),
            ],
          ],
        ),
        trailing: OutlinedButton.icon(
          key: const Key('settings-rescan-action'),
          onPressed: _isScanning ? null : _rescanGallery,
          icon: const Icon(Icons.refresh),
          label: Text(
            _isScanning
                ? context.l10n.galleryCache_scanning
                : context.l10n.galleryCache_scanAction,
          ),
        ),
      ),
      right: SettingsTile(
        key: const Key('settings-thumbnails-row'),
        controlWrapWidth: 300 * MediaQuery.textScalerOf(context).scale(1),
        hoverFeedback: !_isEvictingThumbnails,
        title: Text(context.l10n.galleryCache_evictThumbnailsTitle),
        subtitle: Text(
          _isEvictingThumbnails
              ? context.l10n.galleryCache_evictThumbnailsRunning
              : context.l10n.galleryCache_evictThumbnailsSubtitle,
        ),
        trailing: OutlinedButton.icon(
          key: const Key('settings-thumbnails-action'),
          onPressed: _isEvictingThumbnails ? null : _evictThumbnailCache,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: Text(context.l10n.galleryCache_evictThumbnailsStart),
        ),
      ),
    );
  }
}
