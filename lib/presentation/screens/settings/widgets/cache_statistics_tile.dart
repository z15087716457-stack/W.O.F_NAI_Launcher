import 'dart:async';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/cache/gallery_cache_manager.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../widgets/common/app_toast.dart';
import 'settings_tile.dart';

/// 缓存统计 Provider
///
/// 使用 autoDispose 确保组件销毁时释放资源
/// 通过统计信息失效回调机制实现实时刷新
final cacheStatisticsProvider = FutureProvider.autoDispose<CacheStatistics>((
  ref,
) async {
  GalleryCacheManager().registerOnStatisticsInvalidated(ref.invalidateSelf);
  ref.onDispose(
    () => GalleryCacheManager().unregisterOnStatisticsInvalidated(
      ref.invalidateSelf,
    ),
  );
  return await GalleryCacheManager().getStatistics();
});

/// 缓存统计展示组件
///
/// 支持自动刷新，每 3 秒更新一次统计数据
class CacheStatisticsTile extends ConsumerStatefulWidget {
  const CacheStatisticsTile({super.key});

  @override
  ConsumerState<CacheStatisticsTile> createState() =>
      _CacheStatisticsTileState();
}

class _CacheStatisticsTileState extends ConsumerState<CacheStatisticsTile> {
  Timer? _refreshTimer;
  DateTime _lastRefreshTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 启动定时器，每 3 秒自动刷新一次
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshStats(),
    );
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _refreshStats() {
    if (mounted) {
      ref.invalidate(cacheStatisticsProvider);
      setState(() {
        _lastRefreshTime = DateTime.now();
      });
    }
  }

  String _getTimeSinceLastRefresh() {
    final diff = DateTime.now().difference(_lastRefreshTime);
    if (diff.inSeconds < 5) {
      return context.l10n.common_justNow;
    } else if (diff.inSeconds < 60) {
      return context.l10n.cacheStats_secondsAgo(diff.inSeconds);
    } else {
      return context.l10n.common_minutesAgo(diff.inMinutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(cacheStatisticsProvider);

    return statsAsync.when(
      data: (stats) => _buildContent(context, ref, stats),
      loading: () => SettingsTile(
        leading: const Icon(Icons.analytics_outlined),
        title: Text(context.l10n.cacheStats_title),
        subtitle: const LinearProgressIndicator(),
      ),
      error: (error, _) => SettingsTile(
        leading: const Icon(Icons.error_outline, color: Colors.red),
        title: Text(context.l10n.cacheStats_title),
        subtitle: Text(context.l10n.settings_loadFailed(error.toString())),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    CacheStatistics stats,
  ) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final metrics = [
      _CacheMetric(
        key: const Key('settings-cache-l1'),
        label: context.l10n.cacheStats_l1Memory,
        count: stats.l1MemorySize,
        unit: context.l10n.settings_records,
        detail:
            '${context.l10n.settings_hitRate} ${(stats.l1HitRate * 100).toStringAsFixed(1)}%',
      ),
      _CacheMetric(
        key: const Key('settings-cache-l2'),
        label: context.l10n.cacheStats_l2Hive,
        count: stats.l2HiveSize,
        unit: context.l10n.settings_records,
        detail:
            '${context.l10n.settings_hitRate} ${(stats.l2HitRate * 100).toStringAsFixed(1)}%',
      ),
      _CacheMetric(
        key: const Key('settings-cache-l3'),
        label: context.l10n.cacheStats_l3Sqlite,
        count: stats.l3DatabaseImageCount,
        unit: context.l10n.settings_images,
        detail:
            '${context.l10n.detail_metadata} ${NumberFormat.decimalPattern(Localizations.localeOf(context).languageCode).format(stats.l3DatabaseMetadataCount)}',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsTile(
          hoverFeedback: false,
          title: Text(
            context.l10n.settings_cacheOverview,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            context.l10n.cacheStats_autoRefreshUpdated(
              _getTimeSinceLastRefresh(),
            ),
          ),
          controlWrapWidth: 320 * scale,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _AutoRefreshIndicator(
                key: Key('settings-auto-refresh-indicator'),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: TextButton.icon(
                  key: const Key('settings-reset-cache-statistics'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: Text(context.l10n.cacheStats_resetStats),
                  onPressed: () {
                    GalleryCacheManager().resetStatistics();
                    _refreshStats();
                    AppToast.success(
                      context,
                      context.l10n.cacheStats_statsReset,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth >= 600 * scale
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < metrics.length; i++)
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 0 : 24,
                              right: i == 2 ? 0 : 24,
                            ),
                            decoration: BoxDecoration(
                              border: i == 0
                                  ? null
                                  : Border(
                                      left: BorderSide(
                                        color: theme.colorScheme.outlineVariant
                                            .withValues(alpha: .5),
                                      ),
                                    ),
                            ),
                            child: metrics[i],
                          ),
                        ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < metrics.length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(),
                          ),
                        metrics[i],
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _AutoRefreshIndicator extends StatefulWidget {
  const _AutoRefreshIndicator({super.key});

  @override
  State<_AutoRefreshIndicator> createState() => _AutoRefreshIndicatorState();
}

class _AutoRefreshIndicatorState extends State<_AutoRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    duration: const Duration(seconds: 3),
    vsync: this,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
      _controller.value = .75;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: context.l10n.settings_autoRefresh,
    child: SizedBox(
      width: 16,
      height: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CircularProgressIndicator(
          value: _controller.value,
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .6),
        ),
      ),
    ),
  );
}

class _CacheMetric extends StatelessWidget {
  const _CacheMetric({
    super.key,
    required this.label,
    required this.count,
    required this.unit,
    required this.detail,
  });
  final String label, unit, detail;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              NumberFormat.decimalPattern(
                Localizations.localeOf(context).languageCode,
              ).format(count),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              unit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
