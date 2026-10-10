import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_card.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_text.dart';
import 'statistics_contract.dart';
import 'statistics_derive.dart';
import 'statistics_format.dart';
import 'statistics_layout.dart';

/// 总数行：图片 / 收藏 / Anlas / 连续创作 / 占用。
class StatsKpiRow extends StatelessWidget {
  const StatsKpiRow({
    super.key,
    required this.data,
    required this.snapshot,
    required this.layout,
  });

  final StatsViewData data;
  final StatsSnapshot snapshot;
  final StatsLayout layout;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final s = snapshot;
    final today = data.today;
    final range = data.range;
    final all = range == StatsRange.all;
    final spark = layout.wide;

    // 图片
    final _KpiCell images;
    if (all) {
      final active = activeDays(s.dailyImages);
      images = _KpiCell(
        glyph: UiGlyphs.image,
        label: l10n.stats_kpiImages,
        value: StatsFormat.count(s.images),
        sub: TextSpan(
          text: l10n.stats_kpiActiveDays(
            '$active',
            StatsFormat.count(active == 0 ? 0 : s.images / active),
          ),
        ),
        spark: spark
            ? _Spark(lastMonths(s.dailyImages, today, 20), c.accent)
            : null,
      );
    } else {
      final prev = sumIn(s.dailyImages, previousPeriod(range, today)!);
      final vs = range == StatsRange.thisYear
          ? l10n.stats_kpiVsLastYear
          : l10n.stats_kpiVsPrevious('${range.days}');
      final change = prev == 0 ? null : (s.images - prev) / prev * 100;
      images = _KpiCell(
        glyph: UiGlyphs.image,
        label: l10n.stats_kpiNewImages,
        value: StatsFormat.count(s.images),
        sub: TextSpan(
          children: [
            TextSpan(text: vs),
            if (change != null)
              TextSpan(
                text: ' ${change >= 0 ? '↑' : '↓'} ${change.abs().round()}%',
                style: TextStyle(color: change >= 0 ? c.ok : c.error),
              ),
            TextSpan(
              text: l10n.stats_kpiPreviousValue(StatsFormat.count(prev)),
            ),
          ],
        ),
        spark: spark
            ? _Spark(
                _rangeSeries(s.dailyImages, range, today),
                c.accent,
                bars: true,
              )
            : null,
      );
    }

    // 收藏
    final favorites = _KpiCell(
      glyph: UiGlyphs.heart,
      label: l10n.stats_kpiFavorites,
      value: StatsFormat.count(s.favorites),
      sub: TextSpan(
        text: l10n.stats_kpiFavoriteRate(
          StatsFormat.percent(s.favorites, s.images, all ? 2 : 1),
        ),
      ),
    );

    // Anlas（记录只保留 90 天）
    final anlasDays = range.days;
    final _KpiCell anlas;
    if (anlasDays == null) {
      anlas = _KpiCell(
        glyph: UiGlyphs.coin,
        label: l10n.stats_kpiAnlas90,
        value: StatsFormat.count(anlasLast(s.dailyAnlas, today, 90)),
        sub: TextSpan(
          text: l10n.stats_kpiAnlasRecent(
            StatsFormat.count(anlasLast(s.dailyAnlas, today, 7)),
            StatsFormat.count(anlasLast(s.dailyAnlas, today, 1)),
          ),
        ),
        spark: spark
            ? _Spark(lastDays(s.dailyAnlas, today, 30), c.amber, bars: true)
            : null,
      );
    } else {
      final total = anlasLast(s.dailyAnlas, today, anlasDays);
      anlas = _KpiCell(
        glyph: UiGlyphs.coin,
        label: l10n.stats_kpiAnlasSpent,
        value: StatsFormat.count(total),
        sub: TextSpan(
          text: l10n.stats_kpiAnlasDaily(
            StatsFormat.count(total / anlasDays),
            StatsFormat.count(anlasLast(s.dailyAnlas, today, 1)),
          ),
        ),
        spark: spark
            ? _Spark(
                lastDays(s.dailyAnlas, today, math.min(anlasDays, 30)),
                c.amber,
                bars: true,
              )
            : null,
      );
    }

    // 连续创作（全部时间）
    final st = streaksOf(s.dailyImages, today);
    final bestUnit = _days(l10n, st.best);
    final streak = _KpiCell(
      glyph: UiGlyphs.flame,
      label: l10n.stats_kpiStreak,
      value: '${st.current}',
      unit: _days(l10n, st.current),
      sub: TextSpan(
        text: st.bestStart == null
            ? l10n.stats_kpiLongest('${st.best}', bestUnit)
            : l10n.stats_kpiLongestRange(
                '${st.best}',
                bestUnit,
                '${StatsFormat.monthDay(context, st.bestStart!)}–'
                    '${StatsFormat.monthDay(context, st.bestEnd!)}',
              ),
      ),
    );

    // 占用
    final (size, unit) = StatsFormat.bytes(s.bytes);
    final storage = _KpiCell(
      glyph: UiGlyphs.disk,
      label: l10n.stats_kpiStorage,
      value: size,
      unit: unit,
      sub: TextSpan(
        text: l10n.stats_kpiStorageDetail(
          StatsFormat.averageMb(s.bytes, s.images),
          StatsFormat.percent(s.withMetadata, s.images),
        ),
      ),
    );

    return UiCard(
      key: const Key('stats-kpis'),
      padding: EdgeInsets.zero,
      child: StatsKpiFrame(cells: [images, favorites, anlas, streak, storage]),
    );
  }

  /// 非“全部”时迷你柱：7 / 30 天按天，90 天按周，今年按月。
  static List<int> _rangeSeries(
    Map<DateTime, int> daily,
    StatsRange range,
    DateTime today,
  ) => switch (range) {
    StatsRange.days7 => lastDays(daily, today, 7),
    StatsRange.days30 => lastDays(daily, today, 30),
    StatsRange.days90 => [
      for (var w = 12; w >= 0; w--)
        sumIn(
          daily,
          StatsPeriod(
            addDays(mondayOf(today), -7 * w),
            addDays(mondayOf(today), 7 - 7 * w),
          ),
        ),
    ],
    _ => lastMonths(daily, today, today.month),
  };
}

class _KpiCell extends StatelessWidget {
  const _KpiCell({
    required this.glyph,
    required this.label,
    required this.value,
    required this.sub,
    this.unit,
    this.spark,
  });

  final String glyph;
  final String label;
  final String value;
  final String? unit;
  final InlineSpan sub;
  final _Spark? spark;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(right: spark == null ? 0 : 100),
              child: Row(
                children: [
                  UiGlyph(glyph, size: 14, color: c.muted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // 窄窗口时数字整体缩小，不截断。
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: value),
                    if (unit != null) ...[
                      const WidgetSpan(child: SizedBox(width: 3)),
                      TextSpan(
                        text: unit,
                        style: UiText.mono(
                          15,
                          weight: FontWeight.w500,
                          color: c.muted,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ],
                ),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: UiText.mono(
                  28,
                  weight: FontWeight.w600,
                  color: c.ink,
                  height: 1.15,
                  letterSpacing: -.8,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              sub,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: c.faint),
            ),
          ],
        ),
        if (spark != null) Positioned(right: -2, top: 0, child: spark!),
      ],
    );
  }
}

/// 92 × 30 的迷你图：折线（带 14% 填充）或柱。
class _Spark extends StatelessWidget {
  const _Spark(this.values, this.color, {this.bars = false});
  final List<int> values;
  final Color color;
  final bool bars;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(92, 30),
    painter: _SparkPainter(values, color, bars, context.ui.control),
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.bars, this.empty);
  final List<int> values;
  final Color color;
  final bool bars;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final w = size.width, h = size.height;
    final mx = math.max(values.reduce(math.max), 1);
    if (bars) {
      final bw = w / values.length;
      for (final (i, v) in values.indexed) {
        final bh = math.max(v / mx * h, v > 0 ? 2.0 : 1.0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(i * bw + 1, h - bh, math.max(bw - 2, 1), bh),
            const Radius.circular(1),
          ),
          Paint()..color = v > 0 ? color : empty,
        );
      }
      return;
    }
    final n = values.length;
    final pts = [
      for (final (i, v) in values.indexed)
        Offset(n == 1 ? w : i / (n - 1) * w, h - 2 - v / mx * (h - 4)),
    ];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final area = Path.from(line)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: .14));
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.color != color || old.bars != bars;
}

String _days(AppLocalizations l10n, int n) =>
    n == 1 ? l10n.stats_unitDay : l10n.stats_unitDays;
