import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/app_toast.dart';
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
import 'statistics_production.dart' show StatsBarRow;

void _text(Canvas canvas, TextPainter tp, double x, double baseline) =>
    tp.paint(
      canvas,
      Offset(
        x,
        baseline - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic),
      ),
    );

TextPainter _tp(String s, TextStyle st) => TextPainter(
  text: TextSpan(text: s, style: st),
  textDirection: TextDirection.ltr,
)..layout();

// ------------------------------------------------------------ 什么时候画

/// 星期 × 小时点阵 + 三个结论。不可点（本地画廊没有按小时筛选）。
class StatsPunchCard extends StatelessWidget {
  const StatsPunchCard({super.key, required this.snapshot});
  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final sum = punchSummary(snapshot.weekHour);
    final has = sum.max > 0;
    final label = UiText.sans(11, color: c.faint);
    return UiCard(
      key: const Key('stats-punch'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiCardHeader(
            title: l10n.stats_punchTitle,
            subtitle: l10n.stats_punchHint,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                UiFactPill(
                  label: l10n.stats_punchPeak,
                  value: has
                      ? l10n.stats_punchPeakValue(
                          StatsFormat.weekday(context, sum.peakWeekday),
                          '${sum.peakHour}',
                          '${sum.peakHour + 1}',
                        )
                      : '—',
                ),
                UiFactPill(
                  label: l10n.stats_punchBusiest,
                  value: has
                      ? StatsFormat.weekday(context, sum.busiestWeekday)
                      : '—',
                ),
                UiFactPill(
                  label: l10n.stats_punchLateNight,
                  value: StatsFormat.percent(sum.nightShare, 1),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 7 * 24 + 18,
            width: double.infinity,
            child: CustomPaint(
              painter: _PunchPainter(
                weekHour: snapshot.weekHour,
                max: sum.max,
                accent: c.accent,
                zero: c.strong,
                rows: [
                  for (var w = 1; w <= 7; w++)
                    _tp(StatsFormat.weekdayNarrow(context, w), label),
                ],
                hours: [
                  for (final h in [0, 6, 12, 18, 23])
                    _tp('$h', UiText.mono(10.5, color: c.faint)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.stats_punchNote, style: label),
        ],
      ),
    );
  }
}

class _PunchPainter extends CustomPainter {
  _PunchPainter({
    required this.weekHour,
    required this.max,
    required this.accent,
    required this.zero,
    required this.rows,
    required this.hours,
  });

  final List<int> weekHour;
  final int max;
  final Color accent;
  final Color zero;
  final List<TextPainter> rows;
  final List<TextPainter> hours;

  @override
  void paint(Canvas canvas, Size size) {
    const lx = 30.0, rh = 24.0;
    final cw = math.min(16.0, (size.width - lx) / 24);
    final mx = math.max(max, 1);
    for (var w = 1; w <= 7; w++) {
      final cy = (w - 1) * rh + rh / 2;
      _text(canvas, rows[w - 1], 0, cy + 4);
      for (var h = 0; h < 24; h++) {
        final v = punchAt(weekHour, w, h);
        final k = math.sqrt(v / mx);
        canvas.drawCircle(
          Offset(lx + h * cw + cw / 2, cy),
          v > 0 ? math.max(k * 7.2, 1.6) : 1.2,
          Paint()
            ..color = v > 0
                ? accent.withValues(alpha: .35 + .65 * k)
                : zero.withValues(alpha: .5),
        );
      }
    }
    for (final (i, h) in [0, 6, 12, 18, 23].indexed) {
      final tp = hours[i];
      _text(canvas, tp, lx + h * cw + cw / 2 - tp.width / 2, 7 * rh + 14);
    }
  }

  @override
  bool shouldRepaint(_PunchPainter old) =>
      old.weekHour != weekHour || old.accent != accent;
}

// ------------------------------------------------------------ Anlas

/// Anlas 消耗：今天 / 7 / 30 / 90 天四格 + 近 30 天柱状。不受时间范围约束，不可点。
class StatsAnlasCard extends StatelessWidget {
  const StatsAnlasCard({
    super.key,
    required this.snapshot,
    required this.today,
  });
  final StatsSnapshot snapshot;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final an = snapshot.dailyAnlas;
    final days = lastDays(an, today, 30);
    final sum30 = days.fold(0, (a, b) => a + b);
    final active = days.where((v) => v > 0).length;
    var peak = 0;
    for (var i = 1; i < 30; i++) {
      if (days[i] > days[peak]) peak = i;
    }
    final muted = UiText.sans(12, color: c.muted);
    final bold = UiText.mono(12, weight: FontWeight.w600, color: c.ink);
    final activeParts = richParts(l10n.stats_anlasActiveDays, '$active');
    Widget box(String label, int v) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: c.control,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(11.5, color: c.muted),
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                StatsFormat.count(v),
                maxLines: 1,
                style: UiText.mono(
                  16,
                  weight: FontWeight.w600,
                  color: c.ink,
                  height: null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return UiCard(
      key: const Key('stats-anlas'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiCardHeader(
            title: l10n.stats_anlasTitle,
            subtitle: l10n.stats_lastDays('30'),
          ),
          Row(
            children: [
              box(l10n.stats_anlasToday, anlasLast(an, today, 1)),
              const SizedBox(width: 8),
              box(l10n.stats_lastDaysShort('7'), anlasLast(an, today, 7)),
              const SizedBox(width: 8),
              box(l10n.stats_lastDaysShort('30'), sum30),
              const SizedBox(width: 8),
              box(l10n.stats_lastDaysShort('90'), anlasLast(an, today, 90)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 96 + 20,
            width: double.infinity,
            child: CustomPaint(
              painter: _AnlasPainter(
                days: days,
                amber: c.amber,
                empty: c.control,
                line: c.border,
                labels: {
                  for (var i = 0; i < 30; i++)
                    if (i % 7 == 1 || i == 29)
                      i: _tp(
                        StatsFormat.monthDay(context, addDays(today, i - 29)),
                        UiText.mono(10.5, color: c.faint),
                      ),
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${l10n.stats_anlasDailyAvg} '),
                    TextSpan(text: StatsFormat.count(sum30 / 30), style: bold),
                  ],
                ),
                style: muted,
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: activeParts[0]),
                    TextSpan(text: activeParts[1], style: bold),
                    TextSpan(text: activeParts[2]),
                  ],
                ),
                style: muted,
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${l10n.stats_anlasPeak} '),
                    TextSpan(
                      text: sum30 == 0
                          ? '—'
                          : '${StatsFormat.monthDay(context, addDays(today, peak - 29))} · ${StatsFormat.count(days[peak])}',
                      style: bold,
                    ),
                  ],
                ),
                style: muted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1.5),
                child: UiGlyph(UiGlyphs.info, size: 13, color: c.faint),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  l10n.stats_anlasNote,
                  style: UiText.sans(11, color: c.faint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnlasPainter extends CustomPainter {
  _AnlasPainter({
    required this.days,
    required this.amber,
    required this.empty,
    required this.line,
    required this.labels,
  });

  final List<int> days;
  final Color amber;
  final Color empty;
  final Color line;
  final Map<int, TextPainter> labels;

  @override
  void paint(Canvas canvas, Size size) {
    const ch = 96.0;
    final w = size.width, bw = w / 30;
    final mx = math.max(days.reduce(math.max), 1);
    canvas.drawLine(
      const Offset(0, ch + .5),
      Offset(w, ch + .5),
      Paint()..color = line,
    );
    for (final (i, v) in days.indexed) {
      final h = v > 0 ? math.max(v / mx * ch, 2.0) : 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * bw + 1.5, ch - h, bw - 3, h),
          Radius.circular(v > 0 ? 2 : 1),
        ),
        Paint()..color = v > 0 ? amber : empty,
      );
      final tp = labels[i];
      if (tp != null) {
        final x = i == 29 ? w - tp.width : i * bw + bw / 2 - tp.width / 2;
        _text(canvas, tp, x, ch + 15);
      }
    }
  }

  @override
  bool shouldRepaint(_AnlasPainter old) =>
      old.days != days || old.amber != amber;
}

// ------------------------------------------------------------ 画幅

/// 画幅：前四个尺寸按真实比例画框 + 方向占比。尺寸和方向可点。
class StatsAspectCard extends StatelessWidget {
  const StatsAspectCard({
    super.key,
    required this.snapshot,
    required this.actions,
  });
  final StatsSnapshot snapshot;
  final StatsActions actions;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final pal = StatsPalette.of(context);
    final res = snapshot.resolutions;
    final total = res.fold(0, (a, r) => a + r.count);
    final top = res.take(4).toList();
    final restN = total - top.fold(0, (a, r) => a + r.count);
    final ori = orientationTotals(res);
    String oriName(StatsOrientation o) => switch (o) {
      StatsOrientation.portrait => l10n.stats_orientationPortrait,
      StatsOrientation.landscape => l10n.stats_orientationLandscape,
      StatsOrientation.square => l10n.stats_orientationSquare,
    };
    const order = [
      StatsOrientation.portrait,
      StatsOrientation.landscape,
      StatsOrientation.square,
    ];
    return UiCard(
      key: const Key('stats-aspect'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiCardHeader(
            title: l10n.stats_aspectTitle,
            subtitle: l10n.stats_aspectHint,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, r) in top.indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: UiPressable(
                    key: Key('stats-resolution-${r.width}x${r.height}'),
                    onTap: () => actions.onOpenGallery(
                      StatsResolutionFilter(r.width, r.height),
                    ),
                    builder: (context, hover) {
                      final k = 60 / math.max(r.width, r.height);
                      final first = i == 0;
                      return Column(
                        children: [
                          Container(
                            height: 64,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: r.width * k,
                              height: r.height * k,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: first
                                    ? c.accent.withValues(alpha: .12)
                                    : c.control,
                                border: Border.all(
                                  color: first || hover ? c.accent : c.strong,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                StatsFormat.percent(r.count, total),
                                style: UiText.mono(
                                  12,
                                  weight: FontWeight.w600,
                                  color: first ? c.accent : c.muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '${r.width}×${r.height}',
                            maxLines: 1,
                            style: UiText.mono(
                              11,
                              color: hover ? c.accent : c.ink,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            l10n.stats_aspectShapeCount(
                              oriName(orientationOf(r.width, r.height)),
                              StatsFormat.count(r.count),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(11, color: c.faint),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              for (var i = top.length; i < 4; i++) ...[
                const SizedBox(width: 6),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
          const SizedBox(height: 16),
          UiSectionLabel(l10n.stats_aspectOrientation),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, o)
                      in order.where((o) => ori[o]! > 0).indexed) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: math.max(
                        1,
                        (ori[o]! / math.max(total, 1) * 1000).round(),
                      ),
                      child: ColoredBox(color: pal.orientation(o)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    for (final o in order)
                      UiPressable(
                        key: Key('stats-orientation-${o.name}'),
                        onTap: ori[o]! > 0
                            ? () => actions.onOpenGallery(
                                StatsOrientationFilter(o),
                              )
                            : null,
                        builder: (context, hover) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: pal.orientation(o),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${oriName(o)} ${StatsFormat.percent(ori[o]!, total)}',
                              style: UiText.sans(
                                12,
                                color: hover ? c.accent : c.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (res.length > 4) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    l10n.stats_aspectOthers(
                      '${res.length - 4}',
                      StatsFormat.percent(restN, total, 1),
                    ),
                    style: UiText.sans(11, color: c.faint),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Text(
              l10n.stats_aspectClickHint,
              style: UiText.sans(11, color: c.faint),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ 参数习惯

/// 参数习惯：最常用的一组设置 + 采样器 / 步数 / CFG / 噪声调度前三。前三项可点。
class StatsParamsCard extends StatelessWidget {
  const StatsParamsCard({
    super.key,
    required this.snapshot,
    required this.actions,
  });
  final StatsSnapshot snapshot;
  final StatsActions actions;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final s = snapshot;
    String? mode<T>(List<StatsCount<T>> l, String Function(T) f) =>
        l.isEmpty ? null : f(l.first.key);
    final combo = [
      mode(s.samplers, StatsFormat.sampler),
      mode(s.steps, (v) => l10n.stats_paramsStepsValue('$v')),
      mode(s.cfg, (v) => 'CFG ${StatsFormat.trim(v)}'),
      mode(s.noiseSchedules, (v) => v),
    ].nonNulls.toList();

    Widget list<T>(
      String title,
      List<StatsCount<T>> items,
      String Function(T) name,
      StatsGalleryFilter Function(T)? filter,
    ) {
      final t = totalOf(items);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiSectionLabel(title),
          for (final (i, it) in items.take(3).indexed)
            StatsBarRow(
              name: name(it.key),
              value: StatsFormat.percent(it.count, t),
              fraction: it.count / items.first.count,
              color: i == 0 ? c.accent : c.strong,
              onTap: filter == null
                  ? null
                  : () => actions.onOpenGallery(filter(it.key)),
            ),
        ],
      );
    }

    return UiCard(
      key: const Key('stats-params'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiCardHeader(
            title: l10n.stats_paramsTitle,
            subtitle: l10n.stats_paramsHint,
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.control,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.stats_paramsCombo,
                  style: UiText.sans(11.5, color: c.muted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in combo.isEmpty ? ['—'] : combo)
                      UiPill(t, background: c.card),
                  ],
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: list(
                  l10n.stats_paramsSampler,
                  s.samplers,
                  StatsFormat.sampler,
                  (v) => StatsSamplerFilter(v),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: list(
                  l10n.stats_paramsSteps,
                  s.steps,
                  (v) => l10n.stats_paramsStepsValue('$v'),
                  (v) => StatsStepsFilter(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: list(
                  'CFG',
                  s.cfg,
                  StatsFormat.trim,
                  (v) => StatsCfgFilter(v),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: list<String>(
                  l10n.stats_paramsNoise,
                  s.noiseSchedules,
                  (v) => v,
                  null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ 常用画师

/// 常用画师 Top 10。点一行在本地画廊搜 `artist:名字`，右键复制名字。
class StatsArtistsCard extends StatelessWidget {
  const StatsArtistsCard({
    super.key,
    required this.snapshot,
    required this.actions,
    required this.layout,
  });
  final StatsSnapshot snapshot;
  final StatsActions actions;
  final StatsLayout layout;

  /// 进度条宽：原型固定 120；卡片窄到名字不足 140 时先缩进度条（最窄 48）。
  double get _barWidth {
    final inner = layout.cardWidth - 38;
    return (inner - 22 - 30 - 64 - 140).clamp(48.0, 120.0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final a = snapshot.artists;
    final note = UiText.sans(11, color: c.faint);
    return UiCard(
      key: const Key('stats-artists'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiCardHeader(
            title: l10n.stats_artistsTitle,
            subtitle: a == null
                ? l10n.stats_artistsComputing
                : l10n.stats_artistsHint(
                    StatsFormat.count(a.imagesWithArtist),
                    StatsFormat.percent(a.imagesWithArtist, snapshot.images),
                  ),
          ),
          if (a == null)
            for (var i = 0; i < 10; i++)
              SizedBox(
                height: 30,
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: UiSkeleton(height: 10, opacity: 1 - i * .07),
                    ),
                    const SizedBox(width: 74),
                  ],
                ),
              )
          else if (a.top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.stats_artistsNone,
                textAlign: TextAlign.center,
                style: UiText.sans(12.5, color: c.muted),
              ),
            )
          else
            for (final (i, it) in a.top.indexed)
              _ArtistRow(
                key: Key('stats-artist-$i'),
                rank: i + 1,
                name: it.key,
                count: it.count,
                fraction: it.count / a.top.first.count,
                barWidth: _barWidth,
                onOpen: () => actions.onOpenGallery(StatsArtistFilter(it.key)),
              ),
          const SizedBox(height: 8),
          Text(l10n.stats_artistsNote, style: note),
        ],
      ),
    );
  }
}

class _ArtistRow extends StatefulWidget {
  const _ArtistRow({
    super.key,
    required this.rank,
    required this.name,
    required this.count,
    required this.fraction,
    required this.barWidth,
    required this.onOpen,
  });

  final int rank;
  final double barWidth;
  final String name;
  final int count;
  final double fraction;
  final VoidCallback onOpen;

  @override
  State<_ArtistRow> createState() => _ArtistRowState();
}

class _ArtistRowState extends State<_ArtistRow> {
  var _hover = false;

  Future<void> _copy() async {
    final l10n = context.l10n;
    await Clipboard.setData(ClipboardData(text: widget.name));
    if (mounted) {
      AppToast.success(context, l10n.stats_artistsCopied(widget.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final query = 'artist:${widget.name}';
    final parts = richParts(l10n.stats_artistsTipSearch, query);
    return UiTipHost(
      tip: _hover
          ? UiTip(
              targetAnchor: Alignment.topRight,
              anchor: const Offset(8, -6),
              followerAnchor: Alignment.bottomRight,
              child: Builder(
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: parts[0]),
                          TextSpan(
                            text: parts[1],
                            style: UiTipStyle.number(context),
                          ),
                          TextSpan(text: parts[2]),
                        ],
                      ),
                    ),
                    Text(
                      l10n.stats_artistsTipCopy,
                      style: UiTipStyle.secondary(context),
                    ),
                  ],
                ),
              ),
            )
          : null,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onOpen,
          onSecondaryTap: _copy,
          child: SizedBox(
            height: 30,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -8,
                  right: -8,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _hover ? c.hover : null,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${widget.rank}',
                        textAlign: TextAlign.right,
                        style: UiText.mono(
                          11,
                          weight: FontWeight.w500,
                          color: c.faint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(12.5, color: c.ink),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: widget.barWidth,
                      height: 5,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: c.control,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: widget.fraction.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.accent.withValues(alpha: .75),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 64,
                      child: Text(
                        StatsFormat.count(widget.count),
                        textAlign: TextAlign.right,
                        style: UiText.mono(
                          12,
                          weight: FontWeight.w500,
                          color: c.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ 存储

/// 存储：总量、近 12 个月每月新增、大小分档、两个清理入口。
class StatsStorageCard extends StatelessWidget {
  const StatsStorageCard({
    super.key,
    required this.snapshot,
    required this.today,
    required this.actions,
  });
  final StatsSnapshot snapshot;
  final DateTime today;
  final StatsActions actions;

  static const _bucketLabels = [
    '< 1 MB',
    '1–2 MB',
    '2–5 MB',
    '5–10 MB',
    '> 10 MB',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final pal = StatsPalette.of(context);
    final s = snapshot;
    final (size, unit) = StatsFormat.bytes(s.bytes);
    final months = [
      for (var i = 11; i >= 0; i--)
        s.monthlyBytes[DateTime(today.year, today.month - i)] ?? 0,
    ];
    final buckets = s.sizeBuckets;
    final totalBytes = math.max(buckets.fold(0, (a, b) => a + b.bytes), 1);
    final noMeta = math.max(s.images - s.withMetadata, 0);
    final big = buckets[4];
    final legend = [
      for (final (i, b) in buckets.indexed)
        if (b.count > 0)
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: pal.sizeBuckets[i],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${_bucketLabels[i]} '),
                      TextSpan(
                        text: StatsFormat.bytesText(b.bytes),
                        style: UiText.mono(11, color: c.faint),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(11, color: c.ink),
                ),
              ),
            ],
          ),
    ];
    return UiCard(
      key: const Key('stats-storage'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiCardHeader(
            title: l10n.stats_storageTitle,
            subtitle: l10n.stats_storageFiles(StatsFormat.count(s.images)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: size),
                    TextSpan(
                      text: ' $unit',
                      style: UiText.mono(
                        14,
                        weight: FontWeight.w500,
                        color: c.muted,
                        height: null,
                      ),
                    ),
                  ],
                ),
                style: UiText.mono(
                  26,
                  weight: FontWeight.w600,
                  color: c.ink,
                  letterSpacing: -.6,
                  height: null,
                ),
              ),
              const Spacer(),
              CustomPaint(
                size: const Size(150, 38),
                painter: _MonthsPainter(months, c.strong),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 12),
            child: Text(
              l10n.stats_storageMonthly,
              textAlign: TextAlign.right,
              style: UiText.sans(11, color: c.faint),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, b)
                      in buckets.indexed
                          .where((e) => e.$2.count > 0)
                          .indexed) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: math.max(
                        1,
                        (b.$2.bytes / totalBytes * 1000).round(),
                      ),
                      child: ColoredBox(color: pal.sizeBuckets[b.$1]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          // 原型 `grid-template-columns: repeat(3, auto)`：按内容宽、剩余空间均分。
          Table(
            defaultColumnWidth: const IntrinsicColumnWidth(flex: 1),
            children: [
              for (var r = 0; r < legend.length; r += 3)
                TableRow(
                  children: [
                    for (var k = r; k < r + 3; k++)
                      Padding(
                        padding: EdgeInsets.only(
                          top: r == 0 ? 0 : 4,
                          right: k % 3 == 2 ? 0 : 14,
                        ),
                        child: k < legend.length ? legend[k] : const SizedBox(),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (noMeta > 0)
            _ActionRow(
              key: const Key('stats-storage-no-metadata'),
              text: l10n.stats_storageNoMetadata(StatsFormat.count(noMeta)),
              link: l10n.stats_storageViewInGallery,
              onTap: () => actions.onOpenGallery(const StatsNoMetadataFilter()),
            ),
          if (noMeta > 0 && big.count > 0) const SizedBox(height: 8),
          if (big.count > 0)
            _ActionRow(
              key: const Key('stats-storage-large'),
              text: l10n.stats_storageLarge(
                StatsFormat.count(big.count),
                StatsFormat.bytesText(big.bytes),
              ),
              link: l10n.stats_storageView,
              onTap: () => actions.onOpenGallery(
                const StatsMinFileSizeFilter(10 * 1024 * 1024),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthsPainter extends CustomPainter {
  _MonthsPainter(this.months, this.color);
  final List<int> months;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final mx = math.max(months.reduce(math.max), 1);
    for (final (i, v) in months.indexed) {
      final h = math.max(v / mx * 34, 2.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * 12.5, size.height - h, 9, h),
          const Radius.circular(2),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_MonthsPainter old) =>
      old.months != months || old.color != color;
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.text,
    required this.link,
    required this.onTap,
  });

  final String text;
  final String link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hover ? c.hover : null,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(12.5, color: c.ink),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              link,
              style: UiText.sans(12, weight: FontWeight.w500, color: c.accent),
            ),
            const SizedBox(width: 4),
            UiGlyph(UiGlyphs.arrowRight, size: 13, color: c.accent),
          ],
        ),
      ),
    );
  }
}
