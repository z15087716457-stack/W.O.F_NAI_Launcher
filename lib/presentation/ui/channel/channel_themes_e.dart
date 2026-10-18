import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'channel_geometry.dart';
import 'channel_paint.dart';

// 乐谱、月相（原型 canvas-channel-more/themes_new.js，装饰坐标）。

const _e = ChannelGeo.e;
const _zone = ChannelGeo.zone;
const _tr = ChannelGeo.transition;

void _glowE(ChannelPaint g, double x, double y, double r, Color c) =>
    g.canvas.drawCircle(
      Offset(x, y),
      r,
      Paint()
        ..shader = ui.Gradient.radial(Offset(x, y), r, [
          c,
          c.withValues(alpha: 0),
        ]),
    );

// ───────────── 乐谱 ─────────────

/// 一小节的节奏（时值，单位拍）。
const _rhythms = <List<double>>[
  [1, 1, 1, 1],
  [2, 1, 1],
  [0.5, 0.5, 1, 2],
  [1, 0.5, 0.5, 1, 1],
  [4],
  [2, 2],
  [1.5, 0.5, 2],
  [0.5, 0.5, 0.5, 0.5, 1, 1],
  [1, 1, 2],
];

const _marks = ['p', 'mf', 'f', 'cresc.', 'rit.', 'dolce', 'a tempo', 'pp'];

const _sp = 13.0;
const _m = 280.0;

/// 三条谱表：左右各一条全尺寸，外侧一条 0.7 淡。
const _staves = <(double, double)>[
  (-(_e + 130), 1.0),
  (_e + 130, 1.0),
  (_e + 320, 0.7),
];

void paintScore(ChannelPaint g) {
  double played(double y) => y < g.camY ? math.exp(-(g.camY - y) / 380) : 0;
  double hl(double y) => math.exp(-math.pow((y - g.camY) / 70, 2));
  // 左外侧：音频波形，播放过的部分上色
  {
    const x = -(_e + 330);
    for (var y = (g.y0 / 9).floor() * 9.0; y < g.y1; y += 9) {
      final al = g.alpha(x, y);
      if (al < 0.01) continue;
      final amp =
          (vnoise(y / 140, 3, g.seed) * 0.7 + vnoise(y / 33, 7, g.seed) * 0.3) *
          70 *
          (0.5 + 0.5 * math.sin(y / 900).abs());
      final p = played(y) + hl(y);
      final col = p > 0.02
          ? g.acc((0.25 + 0.5 * math.min(1, p)) * al)
          : g.ink(0.2 * al);
      g.line(x - amp, y, x + amp, y, col, 3.5 * g.s);
    }
  }
  for (final (cx, w) in _staves) {
    final side = cx.sign;
    final alc = g.alpha(cx, (g.y0 + g.y1) / 2) * w;
    if (alc < 0.01) continue;
    for (var i = -2; i <= 2; i++) {
      g.line(cx + i * _sp, g.y0, cx + i * _sp, g.y1, g.ink(0.3 * alc));
    }
    for (var mi = (g.y0 / _m).floor(); mi <= (g.y1 / _m).floor(); mi++) {
      final by = mi * _m;
      final al = g.alpha(cx, by + _m / 2) * w;
      if (al < 0.01) continue;
      g.line(cx - 2 * _sp, by, cx + 2 * _sp, by, g.ink(0.42 * al));
      if (w == 1) {
        g.text(
          '${modI(mi, 400) + 1}',
          cx + side * (2 * _sp + 8),
          by + 12,
          11,
          ChannelFont.mono,
          g.ink(0.36 * al),
          align: side < 0 ? TextAlign.right : TextAlign.left,
        );
      }
      final r = g.r(['ms', cx, mi]);
      final rh = _rhythms[(r() * _rhythms.length).floor()];
      if (r() < 0.16) {
        g.text(
          _marks[(r() * _marks.length).floor()],
          cx - side * (2 * _sp + 14),
          by + 60,
          15,
          ChannelFont.mono,
          g.ink(0.42 * al),
          align: side < 0 ? TextAlign.left : TextAlign.right,
        );
      }
      var beat = 0.0;
      var p = (r() * 9).floor() - 4;
      for (final dur in rh) {
        final y = by + 26 + beat / 4 * (_m - 44);
        final rest = r() < 0.08;
        p = (p + ((r() - 0.5) * 5).round()).clamp(-6, 6).toInt();
        final x = cx + side * p * _sp / 2;
        final h = hl(y);
        final pl = played(y);
        beat += dur;
        if (rest) {
          g.path(
            Path()
              ..moveTo(cx - 6, y - 10)
              ..lineTo(cx + 4, y - 4)
              ..lineTo(cx - 4, y + 2)
              ..lineTo(cx + 6, y + 9),
            g.ink(0.44 * al),
            w: 1.6,
          );
          continue;
        }
        if (p.abs() >= 6) {
          g.line(
            cx + side * 3 * _sp,
            y - 11,
            cx + side * 3 * _sp,
            y + 11,
            g.ink(0.4 * al),
          );
        }
        if (h > 0.05 && g.motion) {
          final ph = modD(g.t * 1.2 + p * 0.1, 1);
          g.circle(x, y, 9 + ph * 24, g.acc(0.5 * h * (1 - ph) * al));
        }
        if (h > 0.05) _glowE(g, x, y, 30, g.acc(0.3 * h * al));
        final tone = h + pl * 0.45;
        final ink = tone > 0.05
            ? g.acc((0.45 + 0.5 * math.min(1, tone)) * al)
            : g.ink(0.55 * al);
        g.canvas
          ..save()
          ..translate(x, y)
          ..rotate(-0.35 * side);
        final head = Path()
          ..addOval(
            Rect.fromCenter(center: Offset.zero, width: 12.4, height: 16.8),
          );
        if (dur >= 2) {
          g.canvas
            ..drawPath(head, g.fill(g.bg(y, 1)))
            ..drawPath(head, g.stroke(ink, 1.6));
        } else {
          g.canvas.drawPath(head, g.fill(ink));
        }
        g.canvas.restore();
        if (dur == 1.5) g.circle(x, y + 14, 2.2, ink, filled: true);
        if (dur < 4) {
          final sd = p * side > 0 ? -1.0 : 1.0;
          final sx0 = x + sd * 6;
          final sx1 = sx0 + sd * 3.4 * _sp;
          final sy = y + (sd > 0 ? -2 : 2);
          g.line(sx0, sy, sx1, sy, ink, 1.2);
          if (dur == 0.5) {
            g.path(
              Path()
                ..moveTo(sx1, sy)
                ..quadraticBezierTo(
                  sx1 - sd * 2,
                  sy + 12,
                  sx1 - sd * 11,
                  sy + 16,
                ),
              ink,
            );
          }
        }
        if (r() < 0.08) {
          final ax = x;
          final ay = y - 18;
          g.line(ax - 5, ay - 5, ax - 5, ay + 5, ink);
          g.line(ax + 5, ay - 5, ax + 5, ay + 5, ink);
          g.line(ax - 8, ay - 2, ax + 8, ay - 3, ink);
          g.line(ax - 8, ay + 3, ax + 8, ay + 2, ink);
        }
      }
    }
    // 播放线
    if (g.camY > g.y0 && g.camY < g.y1) {
      final al = g.alpha(cx, g.camY) * w;
      g.line(
        cx - 2 * _sp - 10,
        g.camY,
        cx + 2 * _sp + 10,
        g.camY,
        g.acc(0.7 * al),
        1.6,
      );
      g.path(
        Path()
          ..moveTo(cx - 2 * _sp - 10, g.camY - 5)
          ..lineTo(cx - 2 * _sp - 2, g.camY)
          ..lineTo(cx - 2 * _sp - 10, g.camY + 5)
          ..close(),
        g.acc(0.8 * al),
        filled: true,
      );
    }
  }
  // 每段开头的拍号与速度
  {
    final y = g.zs + _tr * 0.65;
    const cx = _e + 130;
    final al = g.alpha(cx, y);
    if (al > 0.01 && y > g.y0 - 100 && y < g.y1 + 100) {
      g.text(
        '4',
        cx,
        y - 4,
        26,
        ChannelFont.mono,
        g.ink(0.6 * al),
        align: TextAlign.center,
      );
      g.text(
        '4',
        cx,
        y + 22,
        26,
        ChannelFont.mono,
        g.ink(0.6 * al),
        align: TextAlign.center,
      );
      g.text(
        'Andante · ${84 + modI(g.k * 7, 30)} BPM',
        cx + 2 * _sp + 16,
        y + 8,
        15,
        ChannelFont.mono,
        g.ink(0.5 * al),
      );
    }
  }
  // 每段一张黑胶，随滚动转动
  {
    final r = g.r(['vinyl', g.k]);
    final side = r() < 0.5 ? -1.0 : 1.0;
    final cx = side * (_e + 250);
    final cy = g.zs + _zone * (0.3 + 0.4 * r());
    const radius = 128.0;
    final al = g.alpha(cx, cy);
    if (al > 0.01 && cy + 200 > g.y0 && cy - 200 < g.y1) {
      final ang = g.camY / 160 + (g.motion ? g.t * 0.9 : 0.0);
      g.circle(cx, cy, radius + 4, g.bg(cy, 1), filled: true);
      g.circle(cx, cy, radius, g.ink(0.1 * al), filled: true);
      for (var rr = 50.0; rr < radius; rr += 5) {
        final q = (rr / 5).floor();
        g.circle(cx, cy, rr, g.ink((modI(q, 3) != 0 ? 0.08 : 0.18) * al));
      }
      g.circle(cx, cy, radius, g.ink(0.5 * al));
      for (final o in const [0.0, math.pi]) {
        g.path(
          Path()
            ..moveTo(cx, cy)
            ..arcTo(
              Rect.fromCircle(center: Offset(cx, cy), radius: radius - 4),
              ang + o,
              0.45,
              false,
            )
            ..close(),
          g.acc(0.08 * al),
          filled: true,
        );
      }
      g.circle(cx, cy, 44, g.acc(0.3 * al), filled: true);
      g.circle(cx, cy, 44, g.acc(0.55 * al));
      g.canvas
        ..save()
        ..translate(cx, cy)
        ..rotate(ang);
      g.text(
        'W.O.F',
        0,
        -14,
        15,
        ChannelFont.pixel,
        g.ink(0.7 * al),
        align: TextAlign.center,
      );
      g.text(
        'SIDE A · 33 RPM',
        0,
        20,
        9,
        ChannelFont.mono,
        g.ink(0.55 * al),
        align: TextAlign.center,
      );
      g.canvas.restore();
      g.circle(cx, cy, 4, g.bg(cy, 1), filled: true);
      // 唱臂
      final pvx = cx + side * (radius + 10);
      final pvy = cy - radius - 10;
      const na = -0.15;
      final nx = cx + side * (radius - 22) * math.cos(math.pi / 2 * 0.6);
      final ny = cy + (radius - 22) * 0.4;
      g.path(
        Path()
          ..moveTo(pvx, pvy)
          ..lineTo(pvx - side * 8, ny - 40)
          ..lineTo(nx, ny),
        g.ink(0.5 * al),
        w: 3 * g.s,
      );
      g.circle(pvx, pvy, 13, g.bg(cy, 1), filled: true);
      g.circle(pvx, pvy, 13, g.ink(0.5 * al));
      g.circle(pvx, pvy, 5, g.ink(0.5 * al));
      g.canvas
        ..save()
        ..translate(nx, ny)
        ..rotate(na * side);
      g.rect(
        const Rect.fromLTWH(-9, -6, 18, 12),
        g.ink(0.4 * al),
        filled: true,
      );
      g.canvas.restore();
    }
  }
}

// ───────────── 月相 ─────────────

const _syn = 29.53;
const _dy = 150.0;

const _phases = [
  'NEW MOON',
  'WAXING CRESCENT',
  'FIRST QUARTER',
  'WAXING GIBBOUS',
  'FULL MOON',
  'WANING GIBBOUS',
  'LAST QUARTER',
  'WANING CRESCENT',
];

double _phaseAt(double y) => modD(y / _dy, _syn) / _syn;

/// 一轮月相：暗面 + 亮面（两段椭圆弧拼出月牙），大月亮带环形山。
void _moon(
  ChannelPaint g,
  double cx,
  double cy,
  double r,
  double ph,
  double al,
  bool big,
) {
  final k = math.cos(ph * tau);
  final sx = ph < 0.5 ? 1.0 : -1.0;
  g.circle(cx, cy, r, g.bg(cy, 1), filled: true);
  g.circle(cx, cy, r, g.ink((big ? 0.07 : 0.09) * al), filled: true);
  final pts = <Offset>[];
  for (var i = 0; i <= 24; i++) {
    final f = -math.pi / 2 + i / 24 * math.pi;
    pts.add(Offset(cx + sx * math.cos(f) * r, cy + math.sin(f) * r));
  }
  for (var i = 24; i >= 0; i--) {
    final f = -math.pi / 2 + i / 24 * math.pi;
    pts.add(Offset(cx + sx * math.cos(f) * r * k, cy + math.sin(f) * r));
  }
  final shape = Path()..addPolygon(pts, true);
  g.path(shape, g.bg(cy, 1), filled: true);
  g.path(shape, g.acc((big ? 0.32 : 0.55) * al), filled: true);
  if (big) {
    g.canvas
      ..save()
      ..clipPath(shape);
    for (final (dx, dy, rr) in const [
      (-0.3, -0.25, 0.2),
      (0.25, -0.35, 0.12),
      (0.1, 0.2, 0.26),
      (-0.35, 0.35, 0.1),
      (0.45, 0.1, 0.09),
      (-0.05, -0.55, 0.07),
      (-0.5, -0.05, 0.08),
    ]) {
      final mx = cx + dx * r;
      final my = cy + dy * r;
      final mr = rr * r;
      g.circle(mx, my, mr, g.ink(0.07 * al), filled: true);
      g.circle(mx, my, mr, g.ink(0.18 * al));
    }
    g.canvas.restore();
  }
  g.circle(cx, cy, r, g.ink((big ? 0.5 : 0.36) * al));
}

void paintLuna(ChannelPaint g) {
  // 星（少量，空闲闪）
  const sc = 210.0;
  for (var cx = (g.x0 / sc).floor(); cx <= (g.x1 / sc).floor(); cx++) {
    for (var cy = (g.y0 / sc).floor(); cy <= (g.y1 / sc).floor(); cy++) {
      if (((cx + 0.5) * sc).abs() < _e + 120) continue;
      final r = g.r(['ls', cx, cy]);
      if (r() < 0.45) continue;
      final x = cx * sc + r() * sc;
      final y = cy * sc + r() * sc;
      final m = r();
      final ph = r() * tau;
      final al =
          g.alpha(x, y) *
          (g.motion && m > 0.6 ? 0.6 + 0.4 * math.sin(g.t * 1.7 + ph) : 1.0);
      if (al < 0.01) continue;
      g.circle(
        x,
        y,
        (0.8 + m * 1.4) * g.px,
        g.ink((0.25 + m * 0.4) * al),
        filled: true,
      );
      if (m > 0.86) {
        final l = 7 * g.px;
        g.line(x - l, y, x + l, y, g.ink(0.35 * al));
        g.line(x, y - l, x, y + l, g.ink(0.35 * al));
      }
    }
  }
  // 流星（空闲时偶尔划过）
  if (g.motion) {
    const mc = 1500.0;
    for (var j = (g.y0 / mc).floor(); j <= (g.y1 / mc).floor(); j++) {
      final r = g.r(['meteor', j]);
      final per = 7 + r() * 6;
      final off = r() * per;
      final side = r() < 0.5 ? -1.0 : 1.0;
      final f = modD(g.t + off, per) / 1.1;
      if (f > 1) continue;
      final x0 = side * (_e + 200 + r() * 300);
      final y0 = j * mc + r() * mc;
      final x = x0 + side * f * 260;
      final y = y0 + f * 140;
      final al = g.alpha(x, y) * math.sin(f * math.pi);
      g.canvas.drawLine(
        Offset(x - side * 120, y - 65),
        Offset(x, y),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(x - side * 120, y - 65),
            Offset(x, y),
            [g.acc(0), g.acc(0.7 * al)],
          )
          ..strokeWidth = 1.6 * g.px
          ..style = PaintingStyle.stroke,
      );
    }
  }
  // 左：月相历，一天一格
  const lx = -(_e + 120);
  g.line(lx, g.y0, lx, g.y1, g.ink(0.2 * g.alpha(lx, (g.y0 + g.y1) / 2)));
  final cur = (g.camY / _dy).round();
  for (
    var di = (g.y0 / _dy).floor() - 1;
    di <= (g.y1 / _dy).floor() + 1;
    di++
  ) {
    final y = di * _dy;
    final ph = _phaseAt(y);
    final al = g.alpha(lx, y);
    if (al < 0.01) continue;
    final isCur = di == cur && g.camY > g.zs && g.camY < g.zs + _zone;
    _moon(g, lx, y, isCur ? 19 : 14, ph, al, false);
    if (isCur) g.circle(lx, y, 26, g.acc(0.75 * al), w: 1.5);
    g.text(
      '${modD(di.toDouble(), _syn).floor() + 1}'.padLeft(2, '0'),
      lx - 30,
      y + 5,
      13,
      ChannelFont.mono,
      g.ink((isCur ? 0.0 : 0.36) * al),
      align: TextAlign.right,
    );
    final prev = _phaseAt(y - _dy);
    final next = _phaseAt(y + _dy);
    if (ph < prev && ph < next) {
      g.text('NEW', lx + 24, y + 5, 12, ChannelFont.pixel, g.acc(0.7 * al));
    }
    if ((ph - 0.5).abs() < (prev - 0.5).abs() &&
        (ph - 0.5).abs() <= (next - 0.5).abs()) {
      g.text('FULL', lx + 24, y + 5, 12, ChannelFont.pixel, g.acc(0.7 * al));
    }
    // 朔望月分隔
    if (ph < prev) {
      g.dashedLine(
        lx - 90,
        y - _dy / 2,
        lx + 40,
        y - _dy / 2,
        g.ink(0.3 * al),
        const [3, 5],
      );
      g.text(
        'LUNATION ${1200 + (di / _syn).floor()}',
        lx - 90,
        y - _dy / 2 - 8,
        11,
        ChannelFont.mono,
        g.ink(0.36 * al),
      );
    }
  }
  if (g.camY > g.zs && g.camY < g.zs + _zone) {
    final y = cur * _dy;
    final ph = _phaseAt(g.camY);
    final al = g.alpha(lx, y);
    final illum = ((1 - math.cos(ph * tau)) / 2 * 100).round();
    g.text(
      _phases[modI((ph * 8).round(), 8)],
      lx - 34,
      y + 1,
      15,
      ChannelFont.mono,
      g.acc(0.9 * al),
      align: TextAlign.right,
    );
    g.text(
      '$illum% · DAY ${(ph * _syn).toStringAsFixed(1)}',
      lx - 34,
      y + 18,
      12,
      ChannelFont.mono,
      g.acc(0.65 * al),
      align: TextAlign.right,
    );
  }
  // 右外侧：潮汐曲线（大潮 / 小潮跟着月相）
  {
    const bx = _e + 430;
    final pts = <Offset>[];
    for (var y = (g.y0 / 12).floor() * 12.0 - 12; y <= g.y1 + 12; y += 12) {
      final a = 26 + 22 * math.cos(2 * tau * _phaseAt(y));
      pts.add(Offset(bx + a * math.sin(tau * y / 300), y));
    }
    final al = g.alpha(bx, (g.y0 + g.y1) / 2);
    if (al > 0.01) {
      g.line(bx, g.y0, bx, g.y1, g.ink(0.16 * al));
      g.path(Path()..addPolygon(pts, false), g.ink(0.4 * al));
      for (var n = (g.y0 / 300).floor(); n <= (g.y1 / 300).floor(); n++) {
        final y = n * 300 + 75.0;
        final a = 26 + 22 * math.cos(2 * tau * _phaseAt(y));
        final a2 = g.alpha(bx, y);
        if (a2 < 0.01 || modI(n, 2) != 0) continue;
        g.circle(bx + a, y, 2.5, g.ink(0.45 * a2), filled: true);
        g.text(
          '${(1.2 + a / 16).toStringAsFixed(1)} m',
          bx + a + 10,
          y + 4,
          12,
          ChannelFont.mono,
          g.ink(0.4 * a2),
        );
      }
      g.text(
        'TIDE',
        bx - 18,
        math.max(g.y0, g.zs) + 40,
        14,
        ChannelFont.pixel,
        g.ink(0.4 * al),
        align: TextAlign.right,
      );
    }
  }
  // 右：一轮大月亮跟着视口走，盈亏随滚动变化
  {
    final cy = g.camY
        .clamp(g.zs + _tr * 0.55, g.zs + _zone - _tr * 0.55)
        .toDouble();
    const cx = _e + 215;
    const radius = 82.0;
    final al = g.alpha(cx, cy);
    final ph = _phaseAt(cy);
    if (al > 0.01 && cy + 200 > g.y0 && cy - 200 < g.y1) {
      if (g.dark) {
        _glowE(g, cx, cy, 230, g.acc(0.12 * al * (1 - math.cos(ph * tau)) / 2));
      }
      g.dashedCircle(cx, cy, 128, g.ink(0.22 * al), const [4, 7]);
      for (var i = 0; i < 8; i++) {
        final a = -math.pi / 2 + i / 8 * tau;
        final mx = cx + math.cos(a) * 128;
        final my = cy + math.sin(a) * 128;
        final on = modI((ph * 8).round(), 8) == i;
        _moon(g, mx, my, on ? 10 : 7, i / 8, al * (on ? 1.0 : 0.8), false);
        if (on) g.circle(mx, my, 15, g.acc(0.7 * al), w: 1.4);
      }
      _moon(g, cx, cy, radius, ph, al, true);
    }
  }
}
