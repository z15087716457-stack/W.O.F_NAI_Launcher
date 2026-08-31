import 'package:flutter/material.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';

import '../../../../../data/models/gallery/gallery_statistics.dart';
import '../cards/chart_card.dart';
import '../charts/aspect_ratio_chart.dart';

/// 宽高比分布卡片 - 显示环形图+图例
/// Aspect ratio distribution card - displays donut chart with legend
class AspectRatioCard extends StatelessWidget {
  final GalleryStatistics stats;

  const AspectRatioCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 计算宽高比分布
    final aspectRatios = <String, int>{};
    for (final res in stats.resolutionDistribution) {
      if (res.count <= 0) continue;

      final dimensions = _parseResolutionLabel(res.label);
      if (dimensions == null) continue;

      final ratio = _simplifyRatio(dimensions.width, dimensions.height);
      aspectRatios[ratio] = (aspectRatios[ratio] ?? 0) + res.count;
    }

    if (aspectRatios.isEmpty) {
      return ChartCard(
        title: l10n.statistics_chartAspectRatio,
        titleIcon: Icons.aspect_ratio_outlined,
        child: ChartEmptyState(title: l10n.statistics_noData),
      );
    }

    final total = aspectRatios.values.fold<int>(0, (a, b) => a + b);
    final items = aspectRatios.entries.map((e) {
      return AspectRatioItem(
        ratio: e.key,
        label: _getRatioLabel(e.key, l10n),
        count: e.value,
        percentage: total > 0 ? e.value / total * 100 : 0,
      );
    }).toList()..sort((a, b) => b.count.compareTo(a.count));

    return ChartCard(
      title: l10n.statistics_chartAspectRatio,
      titleIcon: Icons.aspect_ratio_outlined,
      child: AspectRatioChart(items: items.take(8).toList(), height: 180),
    );
  }

  ({int width, int height})? _parseResolutionLabel(String label) {
    final match = RegExp(r'^\s*(\d+)\s*[xX×]\s*(\d+)\s*$').firstMatch(label);
    if (match == null) return null;

    final width = int.tryParse(match.group(1)!);
    final height = int.tryParse(match.group(2)!);
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }

    return (width: width, height: height);
  }

  String _simplifyRatio(int w, int h) {
    final gcd = _gcd(w, h);
    if (gcd <= 0) return '1:1';
    return '${w ~/ gcd}:${h ~/ gcd}';
  }

  int _gcd(int a, int b) {
    final absA = a.abs();
    final absB = b.abs();
    return absB == 0 ? absA : _gcd(absB, absA % absB);
  }

  String _getRatioLabel(String ratio, AppLocalizations l10n) {
    final parts = ratio.split(':');
    if (parts.length != 2) return l10n.statistics_aspectOther;
    final w = int.tryParse(parts[0]) ?? 1;
    final h = int.tryParse(parts[1]) ?? 1;
    if (w == h) return l10n.statistics_aspectSquare;
    if (w > h) return l10n.statistics_aspectLandscape;
    return l10n.statistics_aspectPortrait;
  }
}
