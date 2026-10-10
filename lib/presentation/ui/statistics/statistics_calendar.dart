import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_card.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_text.dart';
import '../kit/ui_tip.dart';
import 'statistics_contract.dart';
import 'statistics_derive.dart';
import 'statistics_format.dart';
import 'statistics_layout.dart';
import 'statistics_palette.dart';

/// 创作日历：一整年按天的格子 + 年度小结。点一格打开本地画廊的这一天。
class StatsCalendarCard extends StatefulWidget {
  const StatsCalendarCard({
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
  State<StatsCalendarCard> createState() => _StatsCalendarCardState();
}

class _StatsCalendarCardState extends State<StatsCalendarCard> {
  /// null = 近一年。
  int? _year;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final pal = StatsPalette.of(context);
    final s = widget.snapshot;
    final today = widget.data.today;
    final years = yearsWithImages(s.dailyImages);
    final year = years.contains(_year) ? _year : null;
    final window = year == null
        ? recentWindow(today, 53)
        : yearWindow(year, today);

    return UiCard(
      key: const Key('stats-calendar'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiCardHeader(
            title: l10n.stats_calendarTitle,
            subtitle: l10n.stats_calendarHint,
            trailing: [
              _Legend(colors: pal.heat),
              const SizedBox(width: 10),
              MenuAnchor(
                alignmentOffset: const Offset(0, 4),
                menuChildren: [
                  for (final y in <int?>[null, ...years])
                    MenuItemButton(
                      onPressed: () => setState(() => _year = y),
                      child: Text(
                        y == null
                            ? l10n.stats_calendarPastYear
                            : l10n.stats_calendarYear('$y'),
                        style: UiText.sans(
                          12.5,
                          color: c.ink,
                          weight: y == year ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                ],
                builder: (context, menu, _) => UiChipButton(
                  key: const Key('stats-calendar-year'),
                  height: 26,
                  onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                  children: [
                    Text(
                      year == null
                          ? l10n.stats_calendarPastYear
                          : l10n.stats_calendarYear('$year'),
                    ),
                    UiGlyph(UiGlyphs.chevronDown, size: 13, color: c.muted),
                  ],
                ),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = widget.layout.wide;
              final sideWidth = wide ? 260.0 + 28 : 0.0;
              final grid = _CalendarGrid(
                window: window,
                daily: s.dailyImages,
                anlas: s.dailyAnlas,
                today: today,
                range: year == null
                    ? rangePeriod(widget.data.range, today)
                    : null,
                maxWidth: constraints.maxWidth - sideWidth,
                onOpenDay: (d) => widget.actions.onOpenGallery(
                  StatsDateFilter(d, addDays(d, 1)),
                ),
              );
              final side = _Summary(
                window: window,
                year: year,
                daily: s.dailyImages,
                today: today,
                wide: wide,
              );
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [grid, const SizedBox(width: 28), side],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [grid, const SizedBox(height: 16), side],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.colors});
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final style = UiText.sans(11, color: c.faint);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.stats_less, style: style),
        const SizedBox(width: 6),
        for (final (i, color) in colors.indexed) ...[
          if (i > 0) const SizedBox(width: 3),
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text(l10n.stats_more, style: style),
      ],
    );
  }
}

const _labelWidth = 30.0;
const _top = 18.0;
const _gap = 3.0;

class _CalendarGrid extends StatefulWidget {
  const _CalendarGrid({
    required this.window,
    required this.daily,
    required this.anlas,
    required this.today,
    required this.range,
    required this.maxWidth,
    required this.onOpenDay,
  });

  final CalendarWindow window;
  final Map<DateTime, int> daily;
  final Map<DateTime, int> anlas;
  final DateTime today;
  final StatsPeriod? range;
  final double maxWidth;
  final ValueChanged<DateTime> onOpenDay;

  @override
  State<_CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<_CalendarGrid> {
  DateTime? _hot;

  /// 格子边长：放得下整年就用 14，放不下先缩到 11，再不行只显示最近的若干周。
  (double, CalendarWindow) _fit() {
    final w = widget.window;
    final avail = widget.maxWidth - _labelWidth;
    final cell = (avail / w.weeks - _gap).floorToDouble().clamp(11.0, 14.0);
    final fits = ((avail + _gap) / (cell + _gap)).floor();
    if (fits >= w.weeks) return (cell, w);
    final drop = w.weeks - math.max(fits, 1).toInt();
    return (
      cell,
      CalendarWindow(addDays(w.start, drop * 7), w.weeks - drop, w.last),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final (cell, window) = _fit();
    final step = cell + _gap;
    final size = Size(_labelWidth + window.weeks * step, _top + 7 * step);
    final values = <int>[
      for (var d = window.start; !d.isAfter(window.last); d = addDays(d, 1))
        countOn(widget.daily, d),
    ];
    final th = heatThresholds(values);

    DateTime? dayAt(Offset p) {
      final col = ((p.dx - _labelWidth) / step).floor();
      final row = ((p.dy - _top) / step).floor();
      if (col < 0 || col >= window.weeks || row < 0 || row > 6) return null;
      final inX = (p.dx - _labelWidth) - col * step <= cell;
      final inY = (p.dy - _top) - row * step <= cell;
      final d = window.dayAt(col, row);
      return inX && inY && window.shows(d) ? d : null;
    }

    UiTip? tip;
    final hot = _hot;
    if (hot != null) {
      final col = hot.difference(window.start).inDays ~/ 7;
      final row = hot.weekday - 1;
      final v = countOn(widget.daily, hot);
      final an = countOn(widget.anlas, hot);
      final images = richParts(l10n.stats_imagesCount, StatsFormat.count(v));
      tip = UiTip(
        anchor: Offset(
          _labelWidth + col * step + cell / 2,
          _top + row * step - 6,
        ),
        followerAnchor: Alignment.bottomCenter,
        width: 240,
        child: Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                StatsFormat.fullDate(context, hot),
                style: UiTipStyle.strong(context),
              ),
              const SizedBox(height: 3),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: images[0]),
                    TextSpan(
                      text: images[1],
                      style: UiTipStyle.number(context),
                    ),
                    TextSpan(text: images[2]),
                    if (an > 0) ...[
                      const TextSpan(text: ' · Anlas '),
                      TextSpan(
                        text: StatsFormat.count(an),
                        style: UiTipStyle.number(context),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.stats_calendarTipOpen,
                style: UiTipStyle.secondary(context),
              ),
            ],
          ),
        ),
      );
    }

    final labelStyle = UiText.sans(11, color: c.faint);
    return UiTipHost(
      tip: tip,
      child: MouseRegion(
        cursor: hot == null ? MouseCursor.defer : SystemMouseCursors.click,
        onHover: (e) {
          final d = dayAt(e.localPosition);
          if (d != _hot) setState(() => _hot = d);
        },
        onExit: (_) => setState(() => _hot = null),
        child: GestureDetector(
          key: const Key('stats-calendar-grid'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (e) {
            final d = dayAt(e.localPosition);
            if (d != null) widget.onOpenDay(d);
          },
          child: CustomPaint(
            size: size,
            painter: _CalendarPainter(
              window: window,
              cell: cell,
              values: values,
              thresholds: th,
              heat: StatsPalette.of(context).heat,
              ink: c.ink,
              accent: c.accent,
              today: widget.today,
              hot: hot,
              range: widget.range,
              weekdayLabels: [
                for (final w in [1, 3, 5])
                  _label(StatsFormat.weekdayNarrow(context, w), labelStyle),
              ],
              monthLabel: (m) => _label(
                StatsFormat.month(context, DateTime(2024, m)),
                labelStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static TextPainter _label(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
}

class _CalendarPainter extends CustomPainter {
  _CalendarPainter({
    required this.window,
    required this.cell,
    required this.values,
    required this.thresholds,
    required this.heat,
    required this.ink,
    required this.accent,
    required this.today,
    required this.hot,
    required this.range,
    required this.weekdayLabels,
    required this.monthLabel,
  });

  final CalendarWindow window;
  final double cell;
  final List<int> values;
  final List<int> thresholds;
  final List<Color> heat;
  final Color ink;
  final Color accent;
  final DateTime today;
  final DateTime? hot;
  final StatsPeriod? range;
  final List<TextPainter> weekdayLabels;
  final TextPainter Function(int month) monthLabel;

  /// 按基线放文字（和 SVG `<text y=…>` 一致）。
  static void _text(Canvas canvas, TextPainter tp, double x, double baseline) {
    final b = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(canvas, Offset(x, baseline - b));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final step = cell + _gap;
    var lastMonth = -1;
    final fill = Paint();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = ink;
    var i = 0;
    for (var w = 0; w < window.weeks; w++) {
      for (var r = 0; r < 7; r++) {
        final d = window.dayAt(w, r);
        if (d.isAfter(window.last)) break;
        final x = _labelWidth + w * step, y = _top + r * step;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cell, cell),
          const Radius.circular(3),
        );
        canvas.drawRRect(
          rect,
          fill..color = heat[heatLevel(values[i++], thresholds)],
        );
        if (d == today || d == hot) {
          canvas.drawRRect(rect.deflate(.75), stroke);
        }
        if (r == 0 && d.month != lastMonth && d.day <= 7) {
          lastMonth = d.month;
          _text(canvas, monthLabel(d.month), x, 11);
        }
      }
    }
    for (final (k, tp) in weekdayLabels.indexed) {
      _text(canvas, tp, 0, _top + k * 2 * step + cell - 3);
    }
    final r = range;
    if (r != null && r.end.isAfter(window.start)) {
      final from = r.start.isBefore(window.start) ? window.start : r.start;
      final col = from.difference(window.start).inDays ~/ 7;
      final x0 = _labelWidth + col * step - 3;
      final box = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x0,
          _top - 4,
          _labelWidth + window.weeks * step - x0,
          7 * step + 5,
        ),
        const Radius.circular(6),
      );
      _dashed(canvas, Path()..addRRect(box), accent);
    }
  }

  static void _dashed(Canvas canvas, Path path, Color color) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color;
    for (final ui.PathMetric m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, math.min(d + 4, m.length)), p);
      }
    }
  }

  @override
  bool shouldRepaint(_CalendarPainter old) =>
      old.window.start != window.start ||
      old.window.weeks != window.weeks ||
      old.cell != cell ||
      old.values != values ||
      old.hot != hot ||
      old.range?.start != range?.start ||
      old.heat.first != heat.first ||
      old.ink != ink;
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.window,
    required this.year,
    required this.daily,
    required this.today,
    required this.wide,
  });

  final CalendarWindow window;
  final int? year;
  final Map<DateTime, int> daily;
  final DateTime today;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    var sum = 0, active = 0, days = 0, best = 0;
    DateTime? bestDay;
    for (var d = window.start; !d.isAfter(window.last); d = addDays(d, 1)) {
      final v = countOn(daily, d);
      days++;
      sum += v;
      if (v > 0) active++;
      if (v > best) {
        best = v;
        bestDay = d;
      }
    }
    final streak = streaksOf(daily, today).best;
    final value = UiText.mono(
      18,
      weight: FontWeight.w600,
      color: c.ink,
      letterSpacing: -.4,
      height: 1.05,
    );
    final small = UiText.sans(12, color: c.muted, height: null);
    final label = UiText.sans(11.5, color: c.muted);
    Widget item(InlineSpan v, String l, [String? extra]) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(v, style: value, maxLines: 1),
        Text(l, style: label, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (extra != null)
          Text(extra, style: label.copyWith(color: c.faint), maxLines: 1),
      ],
    );
    final items = [
      item(
        TextSpan(text: StatsFormat.count(sum)),
        year == null
            ? l10n.stats_calendarImagesPastYear
            : l10n.stats_calendarImagesInYear('$year'),
      ),
      item(
        TextSpan(
          children: [
            TextSpan(text: '$active'),
            TextSpan(text: ' / $days', style: small),
          ],
        ),
        l10n.stats_calendarActiveDays,
      ),
      item(
        TextSpan(text: StatsFormat.count(best)),
        l10n.stats_calendarBestDay,
        bestDay == null ? null : StatsFormat.longDate(context, bestDay),
      ),
      item(
        TextSpan(
          children: [
            TextSpan(text: '$streak'),
            TextSpan(text: ' ${_days(l10n, streak)}', style: small),
          ],
        ),
        l10n.stats_calendarLongestStreak,
      ),
    ];
    if (!wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, it) in items.indexed) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(child: it),
          ],
        ],
      );
    }
    return Container(
      width: 260,
      padding: const EdgeInsets.only(left: 24),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          for (final i in [0, 2]) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: items[i]),
                const SizedBox(width: 16),
                Expanded(child: items[i + 1]),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _days(AppLocalizations l10n, int n) =>
    n == 1 ? l10n.stats_unitDay : l10n.stats_unitDays;
