import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_card.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_text.dart';
import '../kit/ui_tip.dart';
import 'statistics_contract.dart';
import 'statistics_derive.dart';
import 'statistics_format.dart';
import 'statistics_layout.dart';
import 'statistics_palette.dart';

/// 产量与模型：按日 / 周 / 月堆叠的产量柱（颜色是模型系列）+ 模型排行。
class StatsProductionCard extends StatefulWidget {
  const StatsProductionCard({
    super.key,
    required this.data,
    required this.snapshot,
    required this.actions,
    required this.layout,
  });

  final StatsViewData data;
  final StatsSnapshot snapshot;
  final StatsActions actions;
  final StatsLayout layout;

  @override
  State<StatsProductionCard> createState() => _StatsProductionCardState();
}

class _StatsProductionCardState extends State<StatsProductionCard> {
  StatsGranularity? _granularity;

  @override
  void didUpdateWidget(covariant StatsProductionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.range != widget.data.range) _granularity = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final range = widget.data.range;
    final g = _granularity ?? defaultGranularity(range);
    final unit = switch (g) {
      StatsGranularity.day => l10n.stats_unitDay,
      StatsGranularity.week => l10n.stats_unitWeek,
      StatsGranularity.month => l10n.stats_unitMonth,
    };
    final scope = switch (range) {
      StatsRange.all => null,
      StatsRange.thisYear => l10n.stats_rangeThisYear,
      _ => l10n.stats_lastDays('${range.days}'),
    };
    final buckets = productionBuckets(
      snapshot: widget.snapshot,
      range: range,
      today: widget.data.today,
      granularity: g,
    );
    return UiCard(
      key: const Key('stats-production'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiCardHeader(
            title: l10n.stats_productionTitle,
            subtitle: scope == null
                ? l10n.stats_productionHintAll(unit)
                : l10n.stats_productionHintRange(scope, unit),
            trailing: [
              UiSegmented<StatsGranularity>(
                key: const Key('stats-granularity'),
                height: 26,
                itemPadding: 9,
                values: StatsGranularity.values,
                selected: g,
                labelOf: (v) => switch (v) {
                  StatsGranularity.day => l10n.stats_granularityDay,
                  StatsGranularity.week => l10n.stats_granularityWeek,
                  StatsGranularity.month => l10n.stats_granularityMonth,
                },
                onChanged: (v) => setState(() => _granularity = v),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = widget.layout.wide;
              final chartWidth = wide
                  ? ((constraints.maxWidth - 28) * .65).floorToDouble()
                  : constraints.maxWidth;
              final chart = _ProductionChart(
                buckets: buckets,
                granularity: g,
                width: chartWidth,
                onOpen: (p) => widget.actions.onOpenGallery(
                  StatsDateFilter(p.start, p.end),
                ),
              );
              final ranking = _ModelRanking(
                snapshot: widget.snapshot,
                onOpen: (m) =>
                    widget.actions.onOpenGallery(StatsModelFilter(m)),
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [chart, const SizedBox(height: 28), ranking],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: Alignment.topLeft, child: chart),
                    const SizedBox(width: 28),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(left: 24),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: context.ui.border),
                          ),
                        ),
                        child: ranking,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

const _chartHeight = 230.0;
const _axisWidth = 40.0;
const _familyOrder = [
  StatsFamily.nai45,
  StatsFamily.nai5,
  StatsFamily.nai4,
  StatsFamily.nai3,
  StatsFamily.other,
  StatsFamily.noMetadata,
];

String familyName(BuildContext context, StatsFamily f) => switch (f) {
  StatsFamily.nai45 => 'NAI 4.5',
  StatsFamily.nai5 => 'NAI 5',
  StatsFamily.nai4 => 'NAI 4',
  StatsFamily.nai3 => 'NAI 3',
  StatsFamily.other => context.l10n.stats_familyOther,
  StatsFamily.noMetadata => context.l10n.stats_familyNoMetadata,
};

class _ProductionChart extends StatefulWidget {
  const _ProductionChart({
    required this.buckets,
    required this.granularity,
    required this.width,
    required this.onOpen,
  });

  final List<ProductionBucket> buckets;
  final StatsGranularity granularity;
  final double width;
  final ValueChanged<StatsPeriod> onOpen;

  @override
  State<_ProductionChart> createState() => _ProductionChartState();
}

class _ProductionChartState extends State<_ProductionChart> {
  int? _hot;

  String _label(BuildContext context, ProductionBucket b, int i) {
    final d = b.period.start;
    if (widget.granularity != StatsGranularity.month) {
      return StatsFormat.monthDay(context, d);
    }
    return d.month == 1 || i == 0
        ? context.l10n.stats_monthWithYear(
            '${d.year}',
            StatsFormat.month(context, d),
          )
        : StatsFormat.month(context, d);
  }

  String _period(BuildContext context, ProductionBucket b) {
    final p = b.period;
    return switch (widget.granularity) {
      StatsGranularity.day => StatsFormat.fullDate(context, p.start),
      StatsGranularity.week =>
        '${StatsFormat.monthDay(context, p.start)}–${StatsFormat.monthDay(context, addDays(p.end, -1))}',
      StatsGranularity.month => StatsFormat.yearMonth(context, p.start),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final pal = StatsPalette.of(context);
    final buckets = widget.buckets;
    final n = buckets.length;
    final w = widget.width;
    final bw = (w - _axisWidth) / n;
    final gap = math.max(bw * .28, 3.0);
    final top = niceCeiling(buckets.fold(0, (a, b) => math.max(a, b.total)));
    final every = math.max(1, (40 / bw).ceil());

    int? indexAt(Offset p) {
      final i = ((p.dx - _axisWidth) / bw).floor();
      return i >= 0 && i < n && p.dy <= _chartHeight + 34 ? i : null;
    }

    UiTip? tip;
    final hot = _hot;
    if (hot != null && buckets[hot].total > 0) {
      final b = buckets[hot];
      final cx = _axisWidth + hot * bw + bw / 2;
      final barTop = _chartHeight + 8 - b.total / top * _chartHeight;
      final title = richParts(
        (m) => l10n.stats_productionTipTotal(_period(context, b), m),
        StatsFormat.count(b.total),
      );
      tip = UiTip(
        anchor: Offset(cx - 14, barTop - 10),
        followerAnchor: cx - 14 > 230 ? Alignment.topRight : Alignment.topLeft,
        width: 210,
        child: Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: title[0]),
                    TextSpan(text: title[1], style: UiTipStyle.number(context)),
                    TextSpan(text: title[2]),
                  ],
                ),
                style: UiTipStyle.strong(context),
              ),
              const SizedBox(height: 5),
              for (final f in _familyOrder)
                if (b.counts[f]! > 0)
                  SizedBox(
                    height: 19,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: pal.family(f),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(familyName(context, f))),
                        Text(
                          StatsFormat.count(b.counts[f]!),
                          style: UiTipStyle.number(context),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 5),
              Text(switch (widget.granularity) {
                StatsGranularity.day => l10n.stats_productionTipOpenDay,
                StatsGranularity.week => l10n.stats_productionTipOpenWeek,
                StatsGranularity.month => l10n.stats_productionTipOpenMonth,
              }, style: UiTipStyle.secondary(context)),
            ],
          ),
        ),
      );
    }

    final axisStyle = UiText.mono(10.5, color: c.faint);
    final labelStyle = UiText.sans(10.5, color: c.faint);
    TextPainter tp(String s, TextStyle st) => TextPainter(
      text: TextSpan(text: s, style: st),
      textDirection: TextDirection.ltr,
    )..layout();

    return UiTipHost(
      tip: tip,
      child: MouseRegion(
        cursor: hot != null && buckets[hot].total > 0
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onHover: (e) {
          final i = indexAt(e.localPosition);
          if (i != _hot) setState(() => _hot = i);
        },
        onExit: (_) => setState(() => _hot = null),
        child: GestureDetector(
          key: const Key('stats-production-chart'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (e) {
            final i = indexAt(e.localPosition);
            if (i != null && buckets[i].total > 0) {
              widget.onOpen(buckets[i].period);
            }
          },
          child: CustomPaint(
            size: Size(w, _chartHeight + 34),
            painter: _ProductionPainter(
              buckets: buckets,
              top: top,
              gap: gap,
              colors: {for (final f in _familyOrder) f: pal.family(f)},
              grid: c.border,
              axis: [
                for (var t = 0; t <= 4; t++)
                  tp(StatsFormat.axis(top * t / 4), axisStyle),
              ],
              labels: [
                for (final (i, b) in buckets.indexed)
                  (n - 1 - i) % every == 0
                      ? tp(_label(context, b, i), labelStyle)
                      : null,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductionPainter extends CustomPainter {
  _ProductionPainter({
    required this.buckets,
    required this.top,
    required this.gap,
    required this.colors,
    required this.grid,
    required this.axis,
    required this.labels,
  });

  final List<ProductionBucket> buckets;
  final int top;
  final double gap;
  final Map<StatsFamily, Color> colors;
  final Color grid;
  final List<TextPainter> axis;
  final List<TextPainter?> labels;

  static void _text(Canvas c, TextPainter tp, double x, double baseline) =>
      tp.paint(
        c,
        Offset(
          x,
          baseline -
              tp.computeDistanceToActualBaseline(TextBaseline.alphabetic),
        ),
      );

  @override
  void paint(Canvas canvas, Size size) {
    const ch = _chartHeight;
    final line = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var t = 0; t <= 4; t++) {
      final y = ch - t / 4 * ch + 8 + .5;
      if (t == 0) {
        canvas.drawLine(Offset(_axisWidth, y), Offset(size.width, y), line);
      } else {
        for (var x = _axisWidth; x < size.width; x += 5) {
          canvas.drawLine(
            Offset(x, y),
            Offset(math.min(x + 2, size.width), y),
            line,
          );
        }
      }
      final a = axis[t];
      _text(canvas, a, _axisWidth - 8 - a.width, y - .5 + 4);
    }
    final bw = (size.width - _axisWidth) / buckets.length;
    for (final (i, b) in buckets.indexed) {
      var y = ch + 8;
      final x = _axisWidth + i * bw + gap / 2, w = bw - gap;
      for (final f in _familyOrder) {
        final h = b.counts[f]! / top * ch;
        if (h <= 0) continue;
        y -= h;
        canvas.drawRect(
          Rect.fromLTWH(x, y, w, h),
          Paint()
            ..color = f == StatsFamily.noMetadata
                ? colors[f]!.withValues(alpha: .9)
                : colors[f]!,
        );
      }
      final lb = labels[i];
      if (lb != null) _text(canvas, lb, x + w / 2 - lb.width / 2, ch + 26);
    }
  }

  @override
  bool shouldRepaint(_ProductionPainter old) =>
      old.buckets != buckets ||
      old.top != top ||
      old.grid != grid ||
      old.colors != colors;
}

class _ModelRanking extends StatelessWidget {
  const _ModelRanking({required this.snapshot, required this.onOpen});
  final StatsSnapshot snapshot;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final pal = StatsPalette.of(context);
    final models = snapshot.models;
    final total = totalOf(models);
    final max = models.isEmpty ? 1 : models.first.count;
    final shown = models
        .where((m) => namedModel(m.key) != null)
        .take(5)
        .toList();
    final rest = models.where((m) => !shown.contains(m)).toList();
    final restN = totalOf(rest);
    final noMeta = math.max(snapshot.images - total, 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSectionLabel(l10n.stats_productionModelsHint),
        for (final m in shown)
          StatsBarRow(
            key: Key('stats-model-${m.key}'),
            dot: pal.family(familyOf(m.key)),
            name: namedModel(m.key)!,
            value:
                '${StatsFormat.count(m.count)} · ${StatsFormat.percent(m.count, total)}',
            fraction: m.count / max,
            color: pal.family(familyOf(m.key)),
            onTap: () => onOpen(m.key),
          ),
        if (rest.isNotEmpty)
          StatsBarRow(
            dot: pal.family(StatsFamily.other),
            name: l10n.stats_productionOtherModels('${rest.length}'),
            muted: true,
            value:
                '${StatsFormat.count(restN)} · ${StatsFormat.percent(restN, total, 1)}',
            fraction: restN / max,
            color: pal.family(StatsFamily.other),
          ),
        if (noMeta > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l10n.stats_productionNoMetadata(StatsFormat.count(noMeta)),
              style: UiText.sans(11, color: c.faint),
            ),
          ),
      ],
    );
  }
}

/// 名字 + 右侧数字 + 下方 5 高进度条的一行（模型排行、参数分布共用）。
class StatsBarRow extends StatelessWidget {
  const StatsBarRow({
    super.key,
    required this.name,
    required this.value,
    required this.fraction,
    required this.color,
    this.dot,
    this.muted = false,
    this.onTap,
  });

  final String name;
  final String value;
  final double fraction;
  final Color color;
  final Color? dot;
  final bool muted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (dot != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dot,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 7),
                ],
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(
                      12.5,
                      color: hover ? c.accent : (muted ? c.muted : c.ink),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  value,
                  maxLines: 1,
                  style: UiText.mono(
                    12,
                    weight: FontWeight.w500,
                    color: c.muted,
                    // 原型 `font:` 简写 → Chrome 里 Geist Mono 12px 的 normal 行高约 21px。
                    height: 1.75,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: c.control,
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
