import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/local_gallery_provider.dart';

/// Error state view for gallery
/// 画廊错误状态视图
class GalleryErrorView extends StatelessWidget {
  /// Error message to display
  /// 显示的错误信息
  final String? error;

  /// Callback when retry button is pressed
  /// 重试按钮回调
  final VoidCallback? onRetry;

  const GalleryErrorView({super.key, this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            context.l10n.localGallery_loadFailed(
              error ?? context.l10n.localGallery_unknownError,
            ),
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(
              context.l10n.common_retry,
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading/indexing state view for gallery
/// 画廊加载/索引状态视图
class GalleryLoadingView extends StatelessWidget {
  /// Loading message to display
  /// 显示的加载信息
  final String? message;

  const GalleryLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            message ?? context.l10n.localGallery_indexingLocalImages,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

/// Empty state view for gallery
/// 画廊空状态视图
class GalleryEmptyView extends StatelessWidget {
  /// Title text
  /// 标题文本
  final String? title;

  /// Subtitle text
  /// 副标题文本
  final String? subtitle;

  /// Icon to display
  /// 显示的图标
  final IconData icon;

  const GalleryEmptyView({
    super.key,
    this.title,
    this.subtitle,
    this.icon = Icons.image_not_supported,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(
              alpha: isDark ? 0.6 : 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title ?? context.l10n.localGallery_emptyTitle,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle ?? context.l10n.localGallery_emptySubtitle,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: isDark ? 0.7 : 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// No results view for gallery (when filters applied)
/// 画廊无结果视图（应用过滤器后）
class GalleryNoResultsView extends ConsumerWidget {
  /// Callback when clear filters button is pressed
  /// 清除过滤按钮回调
  final VoidCallback? onClearFilters;

  /// Custom title text
  /// 自定义标题文本
  final String? title;

  /// Custom subtitle text
  /// 自定义副标题文本
  final String? subtitle;

  /// Custom icon
  /// 自定义图标
  final IconData? icon;

  const GalleryNoResultsView({
    super.key,
    this.onClearFilters,
    this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.search_off,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(
              alpha: isDark ? 0.6 : 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title ?? context.l10n.localGallery_noMatchingResults,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed:
                onClearFilters ??
                () {
                  ref
                      .read(localGalleryNotifierProvider.notifier)
                      .clearAllFilters();
                },
            icon: const Icon(Icons.filter_alt_off, size: 16),
            label: Text(context.l10n.localGallery_clearFilters),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grouped loading view for gallery
/// 画廊分组加载视图
class GalleryGroupedLoadingView extends StatelessWidget {
  const GalleryGroupedLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            context.l10n.localGallery_loadingGroupedImages,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
