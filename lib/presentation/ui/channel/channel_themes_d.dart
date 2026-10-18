import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'channel_geometry.dart';
import 'channel_paint.dart';

// 机芯、地层、地铁（原型 canvas-channel-more/themes_new.js，装饰坐标）。
// 共同点：都有跟着视口走的东西（齿轮随滚动啮合、钻头、列车），滚动本身就是互动。

const _e = ChannelGeo.e;
const _zone = ChannelGeo.zone;
const _tr = ChannelGeo.transition;
const _sides = [-1.0, 1.0];

Path _poly(List<Offset> pts, {bool close = false}) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    p.lineTo(pts[i].dx, pts[i].dy);
  }
  if (close) p.close();
  return p;
}

TextAlign _away(double side) => side < 0 ? TextAlign.right : TextAlign.left;

// ═════════════════════════ 机芯 ═════════════════════════

void _gear(
  ChannelPaint g,
  double cx,
  double cy,
  double r,
  double ang,
  double al,
  bool jewel,
) {
  final n = math.max(8, (r / 6.5).round());
  final dep = math.min(9.0, r * 0.2), rr = r - dep;
  final p = Path();
  for (var i = 0; i < n; i++) {
    final a = ang + i / n * tau, w = tau / n;
    for (final (rad, f) in [(rr, 0.0), (r, 0.18), (r, 0.42), (rr, 0.6)]) {
      final q = a + w * f;
      final x = cx + math.cos(q) * rad, y = cy + math.sin(q) * rad;
      i == 0 && f == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
  }
  p.close();
  g
    ..path(p, g.bg(cy, 1), filled: true)
    ..path(p, g.ink(0.05 * al), filled: true)
    ..path(p, g.ink(0.44 * al));
  if (r > 34) {
    final ri = rr - 8, hub = math.max(9.0, r * 0.2);
    g
      ..circle(cx, cy, ri, g.ink(0.3 * al))
      ..circle(cx, cy, hub, g.ink(0.3 * al));
    final ns = r > 70 ? 5 : 4;
    final spokes = Path();
    for (var i = 0; i < ns; i++) {
      final a = ang + i / ns * tau, co = math.cos(a), si = math.sin(a);
      final ox = -si * 4, oy = co * 4;
      for (final s in _sides) {
        spokes
          ..moveTo(cx + co * hub + s * ox, cy + si * hub + s * oy)
          ..lineTo(cx + co * ri + s * ox, cy + si * ri + s * oy);
      }
    }
    g.path(spokes, g.ink(0.3 * al));
  } else {
    g.circle(cx, cy, r * 0.42, g.ink(0.3 * al));
  }
  if (jewel) {
    g
      ..circle(cx, cy, 5, g.acc(0.55 * al), filled: true)
      ..circle(cx, cy, 9, g.acc(0.4 * al));
  } else {
    g.circle(cx, cy, 3, g.ink(0.4 * al), filled: true);
  }
}

const _engraving = [
  'CAL. W-25',
  '25 JEWELS',
  'ADJ. 5 POS',
  'UNADJUSTED',
  'W.O.F · GENÈVE',
  'SWISS MOVT',
  'ANTI-SHOCK',
];

void paintCaliber(ChannelPaint g) {
  final c = g.canvas;
  // 外侧：珍珠纹（圆形打磨）
  const pg = 54.0;
  for (var cx = (g.x0 / pg).floor(); cx <= (g.x1 / pg).floor(); cx++) {
    for (var cy = (g.y0 / pg).floor() - 1; cy <= (g.y1 / pg).floor(); cy++) {
      final x = cx * pg + (cy.isOdd ? pg / 2 : 0), y = cy * pg;
      if (x.abs() < _e + 360) continue;
      if (vnoise(x / 700, y / 700, g.seed + 3) < 0.52) continue;
      final al = g.alpha(x, y);
      if (al < 0.01) continue;
      g
        ..circle(x, y, 24, g.ink(0.11 * al))
        ..circle(x, y, 14, g.ink(0.06 * al));
    }
  }
  // 夹板：日内瓦纹 + 螺丝 + 刻字
  const pl = 1300.0;
  for (final side in _sides) {
    for (var j = ((g.y0 - 1000) / pl).floor(); j <= (g.y1 / pl).floor(); j++) {
      final r = g.r(['plate', side, j]);
      if (r() < 0.25) continue;
      final y0 = j * pl + r() * 300, h = 520 + r() * 380;
      final xi = _e + 50 + r() * 30, xo = _e + 300 + r() * 50;
      final cut = 60 + r() * 80;
      final al = g.alpha(side * (xi + xo) / 2, y0 + h / 2);
      if (al < 0.01 || y0 > g.y1 || y0 + h < g.y0) continue;
      final plate = _poly([
        for (final (px, py) in [
          (xi, y0 + cut),
          (xi + cut, y0),
          (xo, y0),
          (xo, y0 + h - cut * 1.4),
          (xo - cut * 1.4, y0 + h),
          (xi, y0 + h),
        ])
          Offset(side * px, py),
      ], close: true);
      g.path(plate, g.ink(0.03 * al), filled: true);
      c
        ..save()
        ..clipPath(plate);
      final band = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12;
      for (var d = -400.0; d < h + 400; d += 26) {
        band.color = g.ink(((d / 26).floor().isOdd ? 0.025 : 0.06) * al);
        c.drawLine(
          Offset(side * (xi - 20), y0 + d),
          Offset(side * (xo + 20), y0 + d - (xo - xi) * 0.5),
          band,
        );
      }
      c.restore();
      g.path(plate, g.ink(0.36 * al));
      for (final (sx, sy) in [(xi + 26, y0 + h - 26), (xo - 26, y0 + 26)]) {
        final a = r() * 3.14;
        g
          ..circle(side * sx, sy, 10, g.bg(sy, 1), filled: true)
          ..circle(side * sx, sy, 10, g.ink(0.46 * al))
          ..circle(side * sx, sy, 6.5, g.ink(0.46 * al))
          ..line(
            side * sx - math.cos(a) * 9,
            sy - math.sin(a) * 9,
            side * sx + math.cos(a) * 9,
            sy + math.sin(a) * 9,
            g.ink(0.46 * al),
          );
      }
      final ex = side * (xi + 30), ey = y0 + h * (0.35 + r() * 0.3);
      g.text(
        _engraving[r.below(_engraving.length)],
        ex,
        ey,
        15,
        ChannelFont.mono,
        g.ink(0.42 * al),
        align: _away(side),
      );
    }
  }
  // 齿轮串：随滚动啮合转动（角速度 ∝ 1/半径，相邻反向，齿面线速度相同）
  const ch = 640.0;
  final drive = g.camY * 0.55 + (g.motion ? g.t * 26 : 0);
  for (final side in _sides) {
    for (
      var j = ((g.y0 - 700) / ch).floor();
      j <= ((g.y1 + 100) / ch).floor();
      j++
    ) {
      final r = g.r(['train', side, j]);
      if (r() < 0.2) continue;
      var rad = 34 + r() * 52, x = _e + 90 + r() * 120;
      var y = j * ch + 60 + r() * 220, dir = r() < 0.5 ? 1.0 : -1.0;
      final n = 2 + r.below(3);
      final list = <(double, double, double, double, double, bool)>[];
      for (var i = 0; i < n; i++) {
        list.add((x, y, rad, dir, r() * tau, r() < 0.5));
        final r2 = 16 + r() * 50;
        var th = math.pi / 2 + (r() - 0.5) * 1.8;
        final reach = rad + r2 - math.min(9.0, rad * 0.2) * 0.75;
        var nx = x + math.cos(th) * reach;
        if (nx - r2 < _e + 50 || nx + r2 > _e + 360) {
          th = math.pi - th;
          nx = x + math.cos(th) * reach;
        }
        y += math.sin(th) * reach;
        x = nx;
        rad = r2;
        dir = -dir;
      }
      for (final (gx, gy, gr, gd, ph, jw) in list) {
        if (gy + gr < g.y0 || gy - gr > g.y1) continue;
        final al = g.alpha(side * gx, gy);
        if (al < 0.01) continue;
        _gear(g, side * gx, gy, gr, ph + side * gd * drive / gr, al, jw);
      }
    }
  }
  _balance(g);
}

/// 每段一组摆轮 + 游丝 + 擒纵轮（空闲时滴答走动）。
void _balance(ChannelPaint g) {
  final c = g.canvas;
  final r = g.r(['balance', g.k]);
  final side = r() < 0.5 ? -1.0 : 1.0;
  final cx = side * (_e + 215), cy = g.zs + _zone * (0.3 + 0.4 * r());
  final al = g.alpha(cx, cy);
  if (al <= 0.01 || cy + 330 <= g.y0 || cy - 140 >= g.y1) return;
  final osc = g.motion ? math.sin(g.t * tau * 1.1) * 2.1 : 0.5;
  const rb = 96.0;
  // 擒纵轮（离散跳动）
  final ex = cx - side * 30, ey = cy + 220;
  const er = 50.0;
  final tick = g.motion ? (g.t * 2.2 * 2).floor() / 2 : 0.0;
  final eAng = (tick * tau / 15) * side + g.camY * 0.004;
  final wheel = Path();
  Offset at(double q, double rr) =>
      Offset(ex + math.cos(q) * rr, ey + math.sin(q) * rr);
  for (var i = 0; i < 15; i++) {
    final a = eAng + i / 15 * tau, a2 = a + tau / 15;
    final p1 = at(a, er - 12), p2 = at(a + 0.05, er), p3 = at(a2, er - 12);
    i == 0 ? wheel.moveTo(p1.dx, p1.dy) : wheel.lineTo(p1.dx, p1.dy);
    wheel
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy);
  }
  wheel.close();
  g
    ..path(wheel, g.bg(ey, 1), filled: true)
    ..path(wheel, g.ink(0.46 * al))
    ..circle(ex, ey, er - 22, g.ink(0.3 * al))
    ..circle(ex, ey, 9, g.ink(0.3 * al))
    ..circle(ex, ey, 4, g.acc(0.55 * al), filled: true);
  // 擒纵叉
  final fork = (math.sin(g.t * tau * 1.1)).sign * (g.motion ? 0.14 : 0.1);
  final fx = cx - side * 6, fy = cy + 130;
  c
    ..save()
    ..translate(fx, fy)
    ..rotate(fork);
  g
    ..line(0, -34, 0, 38, g.ink(0.44 * al))
    ..line(-26, 30, 26, 30, g.ink(0.44 * al))
    ..rect(const Rect.fromLTWH(-30, 30, 8, 12), g.acc(0.5 * al), filled: true)
    ..rect(const Rect.fromLTWH(22, 30, 8, 12), g.acc(0.5 * al), filled: true)
    ..circle(0, 0, 6, g.bg(fy, 1), filled: true)
    ..circle(0, 0, 6, g.ink(0.46 * al));
  c.restore();
  // 摆轮
  g
    ..circle(cx, cy, rb + 6, g.bg(cy, 1), filled: true)
    ..circle(cx, cy, rb, g.ink(0.5 * al))
    ..circle(cx, cy, rb - 12, g.ink(0.5 * al))
    ..path(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: rb))
        ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: rb - 12)),
      g.ink(0.06 * al),
      filled: true,
    );
  for (var i = 0; i < 3; i++) {
    final a = osc + i / 3 * tau;
    g.line(
      cx + math.cos(a) * 14,
      cy + math.sin(a) * 14,
      cx + math.cos(a) * (rb - 12),
      cy + math.sin(a) * (rb - 12),
      g.ink(0.42 * al),
    );
  }
  for (var i = 0; i < 12; i++) {
    final a = osc + (i + 0.5) / 12 * tau;
    final sx = cx + math.cos(a) * (rb + 1), sy = cy + math.sin(a) * (rb + 1);
    g
      ..circle(sx, sy, 5, g.bg(cy, 1), filled: true)
      ..circle(sx, sy, 5, g.ink(0.44 * al));
  }
  // 游丝：阿基米德螺线，随摆动“呼吸”
  final br = 1 + 0.07 * math.sin(osc);
  final spring = Path();
  for (var i = 0; i <= 200; i++) {
    final th = i / 200 * 4.5 * tau;
    final rr = (14 + th / (4.5 * tau) * 56) * br, a = th + osc * 0.35;
    final x = cx + math.cos(a) * rr, y = cy + math.sin(a) * rr;
    i == 0 ? spring.moveTo(x, y) : spring.lineTo(x, y);
  }
  g
    ..path(spring, g.acc(0.38 * al))
    ..circle(cx, cy, 6, g.acc(0.6 * al), filled: true)
    ..circle(cx, cy, 11, g.acc(0.5 * al));
  final lx = cx + side * (rb + 26), la = _away(side);
  g
    ..text(
      'W.O.F CAL.2',
      lx,
      cy - 18,
      22,
      ChannelFont.pixel,
      g.ink(0.55 * al),
      align: la,
    )
    ..text(
      '28 800 A/h · 4 Hz',
      lx,
      cy + 4,
      13,
      ChannelFont.mono,
      g.ink(0.4 * al),
      align: la,
    )
    ..text(
      '${g.motion ? (g.t * 4).floor() % 10000 : 0} TICKS',
      lx,
      cy + 22,
      13,
      ChannelFont.mono,
      g.acc(0.55 * al),
      align: la,
    );
}

// ═════════════════════════ 地层 ═════════════════════════

const _periods = [
  ('QUATERNARY', 0.0),
  ('NEOGENE', 2.6),
  ('PALEOGENE', 23.0),
  ('CRETACEOUS', 66.0),
  ('JURASSIC', 145.0),
  ('TRIASSIC', 201.0),
  ('PERMIAN', 252.0),
  ('CARBONIFEROUS', 299.0),
  ('DEVONIAN', 359.0),
  ('SILURIAN', 419.0),
  ('ORDOVICIAN', 444.0),
  ('CAMBRIAN', 485.0),
  ('PRECAMBRIAN', 539.0),
];

double _maAt(ChannelPaint g, double y) {
  final f = (((y - g.zs) / _zone - 0.12) / 0.76).clamp(0.0, 1.0);
  return 539 * math.pow(f, 1.6).toDouble();
}

double _yAtMa(ChannelPaint g, double ma) =>
    g.zs + _zone * (0.12 + 0.76 * math.pow(ma / 539, 1 / 1.6));

int _periodOf(double ma) {
  var i = 0;
  while (i + 1 < _periods.length && _periods[i + 1].$2 <= ma) {
    i++;
  }
  return i;
}

void _fossil(
  ChannelPaint g,
  int kind,
  double x,
  double y,
  double s,
  double rot,
  double al,
) {
  final c = g.canvas;
  c
    ..save()
    ..translate(x, y)
    ..rotate(rot)
    ..scale(s, s);
  // 画笔线宽按屏幕像素给；这里装饰被再放大了 s 倍，线宽要除回去
  final line = g.ink(0.46 * al), fill = g.ink(0.05 * al), w = 1 / s;
  void ln(double ax, double ay, double bx, double by) =>
      g.line(ax, ay, bx, by, line, w);
  switch (kind) {
    case 0: // 鱼骨
      ln(-34, 0, 30, 0);
      final head = _poly(const [
        Offset(30, 0),
        Offset(44, -9),
        Offset(48, 0),
        Offset(44, 9),
      ], close: true);
      g
        ..path(head, fill, filled: true)
        ..path(head, line, w: w);
      for (var i = -26.0; i < 26; i += 7) {
        ln(i, 0, i - 6, -11 + i.abs() * 0.12);
        ln(i, 0, i - 6, 11 - i.abs() * 0.12);
      }
      g
        ..path(
          _poly(const [
            Offset(-34, 0),
            Offset(-46, -10),
            Offset(-42, 0),
            Offset(-46, 10),
          ], close: true),
          line,
          w: w,
        )
        ..circle(40, -2, 1.6, g.ink(0.4 * al), filled: true);
    case 1: // 菊石
      final shell = Path();
      for (var i = 0; i <= 90; i++) {
        final th = i / 90 * 3.6 * math.pi, rr = 3 * math.exp(0.19 * th);
        final px = math.cos(th) * rr, py = math.sin(th) * rr;
        i == 0 ? shell.moveTo(px, py) : shell.lineTo(px, py);
      }
      g.path(shell, line, w: w);
      for (var i = 26; i <= 90; i += 3) {
        final th = i / 90 * 3.6 * math.pi;
        final r1 = 3 * math.exp(0.19 * th),
            r0 = 3 * math.exp(0.19 * (th - tau));
        ln(
          math.cos(th) * r0,
          math.sin(th) * r0,
          math.cos(th) * r1,
          math.sin(th) * r1,
        );
      }
    case 2: // 蕨叶
      g.path(
        Path()
          ..moveTo(0, 40)
          ..quadraticBezierTo(6, 0, -2, -42),
        line,
        w: w,
      );
      for (var i = 0; i < 9; i++) {
        final t = i / 9,
            yy = 34 - t * 72,
            xx = 4 * (1 - t),
            l = 22 * (1 - t * 0.7);
        for (final s2 in _sides) {
          c
            ..save()
            ..translate(xx + s2 * l / 2, yy - 4)
            ..rotate(s2 * -0.5);
          final leaf = Path()
            ..addOval(
              Rect.fromCenter(center: Offset.zero, width: l, height: 7.2),
            );
          g
            ..path(leaf, fill, filled: true)
            ..path(leaf, line, w: w);
          c.restore();
        }
      }
    default: // 三叶虫
      final body = Path()
        ..addOval(
          Rect.fromCenter(center: const Offset(0, 4), width: 40, height: 56),
        );
      g
        ..path(body, fill, filled: true)
        ..path(body, line, w: w);
      final head = Path()
        ..addArc(
          Rect.fromCircle(center: const Offset(0, -16), radius: 22),
          math.pi,
          math.pi,
        )
        ..close();
      g
        ..path(head, g.bg(y, 1), filled: true)
        ..path(head, fill, filled: true)
        ..path(head, line, w: w);
      ln(-7, -14, -7, 30);
      ln(7, -14, 7, 30);
      for (var yy = -6.0; yy < 28; yy += 5) {
        ln(-18 + (yy - 8).abs() * 0.12, yy, 18 - (yy - 8).abs() * 0.12, yy);
      }
      g
        ..circle(-12, -22, 2.2, g.ink(0.4 * al), filled: true)
        ..circle(12, -22, 2.2, g.ink(0.4 * al), filled: true);
  }
  c.restore();
}

void paintStrata(ChannelPaint g) {
  const bh = 190.0;
  double bandY(int b) =>
      b * bh + (channelHash([b, g.seed, 41]) / 4294967296 - 0.5) * 90;
  double curve(int b, double x) =>
      bandY(b) + (vnoise(x / 520, b * 1.7, g.seed) - 0.5) * 90 + x * 0.02;
  // 岩层：两侧分层，层内岩性花纹
  for (final side in _sides) {
    final xa = side < 0 ? _e + 300 : _e + 50;
    final xb = math.min(2400.0, side < 0 ? -g.x0 : g.x1);
    if (xb <= xa) continue;
    final xs = [for (var x = xa; x <= xb + 40; x += 40) x];
    for (
      var b = ((g.y0 - 200) / bh).floor() - 1;
      b <= ((g.y1 + 200) / bh).floor() + 1;
      b++
    ) {
      final lith = channelHash([b, g.seed, 9]) % 5;
      final al = g.alpha(side * (xa + 200), bandY(b));
      if (al < 0.01) continue;
      final top = [for (final x in xs) Offset(side * x, curve(b, x))];
      if (b.isOdd) {
        g.path(
          _poly([
            ...top,
            for (final x in xs.reversed) Offset(side * x, curve(b + 1, x)),
          ], close: true),
          g.ink(0.035 * al),
          filled: true,
        );
      }
      g.path(_poly(top), g.ink(0.34 * al));
      // 花纹（只在主带附近）
      final xe = math.min(xb, side < 0 ? _e + 640 : _e + 560);
      final pat = Path();
      for (var x = xa + 14; x < xe; x += 30) {
        final t0 = curve(b, x) + 12, b0 = curve(b + 1, x) - 10;
        for (var y = t0; y < b0; y += 26) {
          final h2 = channelHash([x.floor(), y.floor(), b, 3]);
          if (h2 % 3 == 0) continue;
          final px = side * (x + (h2 & 7)), py = y + ((h2 >> 3) & 7);
          switch (lith) {
            case 0:
              pat.addOval(Rect.fromCircle(center: Offset(px, py), radius: 1.6));
            case 1:
              pat
                ..moveTo(px - 13, py)
                ..lineTo(px + 13, py);
              if (h2 & 64 != 0) {
                pat
                  ..moveTo(px, py)
                  ..lineTo(px, py + 12);
              }
            case 2:
              pat
                ..moveTo(px - 7, py)
                ..lineTo(px + 7, py);
            case 3:
              pat.addOval(Rect.fromCircle(center: Offset(px, py), radius: 5));
          }
        }
      }
      if (lith == 0) {
        g.path(pat, g.ink(0.24 * al), filled: true);
      } else {
        g.path(pat, g.ink(0.2 * al));
      }
    }
  }
  // 化石：按所在年代挑种类
  const fc = 520.0;
  for (final side in _sides) {
    for (
      var j = ((g.y0 - 100) / fc).floor();
      j <= ((g.y1 + 100) / fc).floor();
      j++
    ) {
      final r = g.r(['fossil', side, j]);
      if (r() < 0.42) continue;
      final x = side * (side < 0 ? _e + 340 + r() * 260 : _e + 130 + r() * 380);
      final y = j * fc + r() * fc, ma = _maAt(g, y);
      final kind = ma < 66
          ? 0
          : ma < 252
          ? 1
          : ma < 359
          ? 2
          : 3;
      final al = g.alpha(x, y);
      if (al < 0.01) continue;
      final fs = 1.3 + r() * 0.7;
      g
        ..circle(x, y, 44 * fs, g.bg(y, 0.92), filled: true)
        ..dashedCircle(x, y, 44 * fs, g.ink(0.14 * al), const [3, 4]);
      _fossil(g, kind, x, y, fs, r() * tau, al);
    }
  }
  _timeColumn(g);
  _drill(g);
  // 剖面标题 + 比例尺（每段一处）
  final r = g.r(['sec', g.k]);
  final y = g.zs + _zone * (0.18 + r() * 0.1);
  const x = _e + 380;
  final al = g.alpha(x, y);
  if (al > 0.01 && y > g.y0 - 60 && y < g.y1 + 60) {
    final l = 'ABCDEFGH'[modI(g.k, 8)];
    g.text('SECTION $l–$l′', x, y, 22, ChannelFont.pixel, g.ink(0.55 * al));
    for (var i = 0; i < 4; i++) {
      final box = Rect.fromLTWH(x + i * 40, y + 14, 40, 7);
      g
        ..rect(box, i.isOdd ? g.bg(y, 1) : g.ink(0.35 * al), filled: true)
        ..rect(box, g.ink(0.42 * al));
    }
    for (final (i, s) in const ['0', '100', '200 m'].indexed) {
      g.text(
        s,
        x + i * 80,
        y + 36,
        11,
        ChannelFont.mono,
        g.ink(0.4 * al),
        align: i == 0 ? TextAlign.left : TextAlign.center,
      );
    }
  }
}

/// 左：地质年代柱 + 当前年代指针。
void _timeColumn(ChannelPaint g) {
  const x0 = -(_e + 104), x1 = -(_e + 72), lx = -(_e + 118);
  final top = math.max(g.y0, g.zs), bot = math.min(g.y1, g.zs + _zone);
  for (var i = 0; i < _periods.length - 1; i++) {
    final ya = _yAtMa(g, _periods[i].$2), yb = _yAtMa(g, _periods[i + 1].$2);
    if (yb < top || ya > bot) continue;
    final al = g.alpha(x0, (ya + yb) / 2);
    if (al < 0.01) continue;
    final box = Rect.fromLTRB(x0, ya, x1, yb);
    g
      ..rect(box, g.ink((0.04 + (i % 3) * 0.04) * al), filled: true)
      ..rect(box, g.ink(0.4 * al));
    final hatch = Path();
    for (var y = ya + 10; y < yb - 4; y += 14) {
      if (i.isOdd) {
        hatch
          ..moveTo(x0 + 4, y)
          ..lineTo(x1 - 4, y);
      } else {
        final o = (y / 14).floor().isOdd ? 8.0 : 0.0;
        hatch
          ..moveTo(x0 + 8 + o, y)
          ..lineTo(x0 + 12 + o, y);
      }
    }
    g
      ..path(hatch, g.ink(0.18 * al))
      ..line(x0, ya, x0 - 10, ya, g.ink(0.18 * al));
    if (((ya + yb) / 2 - g.camY).abs() >= 40) {
      g.text(
        _periods[i].$1,
        lx,
        (ya + yb) / 2 + 5,
        15,
        ChannelFont.mono,
        g.ink(0.46 * al),
        align: TextAlign.right,
      );
    }
    if ((ya - g.camY).abs() > 44) {
      g.text(
        '${_fmtMa(_periods[i].$2)} Ma',
        lx,
        ya + 14,
        12,
        ChannelFont.mono,
        g.ink(0.32 * al),
        align: TextAlign.right,
      );
    }
  }
  if (g.camY > _yAtMa(g, 0) && g.camY < _yAtMa(g, 539)) {
    final al = g.alpha(x0, g.camY), ma = _maAt(g, g.camY);
    g
      ..path(
        _poly([
          Offset(x1 + 4, g.camY),
          Offset(x1 + 20, g.camY - 8),
          Offset(x1 + 20, g.camY + 8),
        ], close: true),
        g.acc(0.8 * al),
        filled: true,
      )
      ..line(x0 - 4, g.camY, x1 + 4, g.camY, g.acc(0.6 * al), 1.5)
      ..text(
        '${ma < 10 ? ma.toStringAsFixed(1) : ma.round()} Ma',
        lx,
        g.camY - 3,
        18,
        ChannelFont.mono,
        g.acc(0.9 * al),
        align: TextAlign.right,
      )
      ..text(
        _periods[_periodOf(ma)].$1,
        lx,
        g.camY + 16,
        13,
        ChannelFont.mono,
        g.acc(0.7 * al),
        align: TextAlign.right,
      );
  }
}

String _fmtMa(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

String _thousands(int v) {
  final s = v.abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// 右：钻杆一路钻到视口中心。
void _drill(ChannelPaint g) {
  const dx = _e + 66;
  final start = g.zs + _tr * 0.5;
  final end = g.camY.clamp(start, g.zs + _zone - _tr * 0.5);
  final al = g.alpha(dx, end);
  if (al <= 0.01 || end <= g.y0 - 100 || start >= g.y1) return;
  final ink = g.ink(0.4 * al);
  final from = math.max(start, g.y0 - 10);
  g
    ..line(dx - 5, from, dx - 5, end - 30, ink)
    ..line(dx + 5, from, dx + 5, end - 30, ink);
  for (var y = (start / 260).ceil() * 260.0; y < end - 40; y += 260) {
    if (y < g.y0 - 20 || y > g.y1 + 20) continue;
    final joint = Rect.fromLTWH(dx - 8, y - 9, 16, 18);
    g
      ..rect(joint, g.bg(y, 1), filled: true)
      ..rect(joint, ink);
  }
  final sp = g.motion ? g.t * 9 : g.camY * 0.05;
  final bit = _poly([
    Offset(dx - 12, end - 30),
    Offset(dx + 12, end - 30),
    Offset(dx + 12, end - 12),
    Offset(dx, end + 6),
    Offset(dx - 12, end - 12),
  ], close: true);
  g
    ..path(bit, g.bg(end, 1), filled: true)
    ..path(bit, g.acc(0.22 * al), filled: true)
    ..path(bit, g.acc(0.7 * al));
  for (var i = 0; i < 3; i++) {
    final o = modD(sp + i / 3, 1) * 24 - 12;
    g.line(dx + o, end - 28, dx + o * 0.3, end - 4, g.acc(0.55 * al));
  }
  if (g.motion) {
    for (var i = 0; i < 7; i++) {
      final ph = modD(g.t * 0.9 + i / 7, 1), a = i / 7 * tau;
      g.circle(
        dx + math.cos(a) * (14 + ph * 40),
        end - 10 + math.sin(a) * (8 + ph * 26) - ph * 20,
        1.8,
        g.ink(0.4 * (1 - ph) * al),
        filled: true,
      );
    }
  }
  g.text(
    '${_thousands(((end - start) / 4).round())} m',
    dx + 22,
    end - 4,
    16,
    ChannelFont.mono,
    g.acc(0.85 * al),
  );
}

// ═════════════════════════ 地铁 ═════════════════════════

/// 四条线：代号、浅色、深色、内侧基线。
const _lines = [
  ('G', Color(0xFF009664), Color(0xFF34DEA0), -(_e + 92)),
  ('Y', Color(0xFFD68000), Color(0xFFFAC446), -(_e + 232)),
  ('B', Color(0xFF2563EB), Color(0xFF6EA0FF), _e + 96),
  ('R', Color(0xFFD63040), Color(0xFFFA7882), _e + 246),
];
const _lineNames = [
  'Gallery Line',
  'Ochre Line',
  'Cobalt Line',
  'Carmine Line',
];
const _stations = [
  'Easel Park', 'Pigment Row', 'Canvas Yard', 'Sketch Hill', 'Ink Bridge', //
  'Vellum', 'Prism Sq.', 'Atelier', 'Gallery', 'Old Mint', //
  'Paper Mill', 'Glasshouse', 'Lantern St.', 'Mirror Lake', 'Archive', //
  'Foundry', 'Orchard', 'Observatory', 'Clocktower', 'Seed Bank', //
  'Lighthouse', 'Quay', 'Gouache', 'Sepia Gate', 'Charcoal', //
  'Umber Rd.', 'Cobalt', 'Vermilion', 'Studio', 'Kiln',
];
const _seg = 640.0;

double _metroX(ChannelPaint g, int li, double y) {
  final base = _lines[li].$4, side = base.sign, j = (y / _seg).floor();
  double off(int jj) => (channelHash([li, jj, g.seed, 5]) % 2) * 70 * side;
  final xa = base + off(j), xb = base + off(j + 1), d = (xb - xa).abs();
  final l = y - j * _seg;
  return l < _seg - d ? xa : xa + (xb - xa) * (l - (_seg - d)) / d;
}

void paintMetro(ChannelPaint g) {
  final c = g.canvas;
  Color col(int li, double a) =>
      (g.dark ? _lines[li].$3 : _lines[li].$2).withValues(alpha: a.clamp(0, 1));
  Paint wide(Color color, double w, {bool round = false}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = round ? StrokeCap.round : StrokeCap.butt
    ..color = color;

  // 河：每段一条横穿两侧
  {
    final r = g.r(['river', g.k]);
    final ry = g.zs + _zone * (0.25 + 0.5 * r());
    if (ry > g.y0 - 300 && ry < g.y1 + 300) {
      for (final side in _sides) {
        final al = g.alpha(side * (_e + 300), ry);
        if (al < 0.01) continue;
        double yAt(double x) =>
            ry + math.sin(x / 260 + g.k) * 50 + (x - _e) * 0.08 * side;
        final xs = [for (var x = _e + 30; x < 2400; x += 40) x];
        c.drawPath(
          _poly([for (final x in xs) Offset(side * x, yAt(x))]),
          wide(g.ink(0.07 * al), 46, round: true),
        );
        for (final o in const [-23.0, 23.0]) {
          g.path(
            _poly([for (final x in xs) Offset(side * x, yAt(x) + o)]),
            g.ink(0.18 * al),
          );
        }
        if (side > 0) {
          g.text(
            'INK RIVER',
            _e + 420,
            ry + math.sin((_e + 420) / 260 + g.k) * 50 + 34,
            14,
            ChannelFont.mono,
            g.ink(0.42 * al),
          );
        }
      }
    }
  }
  // 线路
  final midBg = g.bg((g.y0 + g.y1) / 2, 1);
  for (var li = 0; li < 4; li++) {
    final al = g.alpha(_lines[li].$4, (g.y0 + g.y1) / 2);
    if (al < 0.01) continue;
    final route = _poly([
      for (var y = (g.y0 / 20).floor() * 20.0 - 20; y <= g.y1 + 20; y += 20)
        Offset(_metroX(g, li, y), y),
    ]);
    c
      ..drawPath(route, wide(midBg, 16))
      ..drawPath(route, wide(col(li, (g.dark ? 0.42 : 0.5) * al), 8));
  }
  // 车站：先找出 G 线离视口中心最近的一站（它的站名由下面的高亮来写）
  (double, double, String, String, double)? near;
  final inZone = g.camY > g.zs && g.camY < g.zs + _zone;
  if (inZone) {
    final j0 = (g.camY / _seg).floor();
    for (var j = j0 - 1; j <= j0 + 1; j++) {
      final r = g.r(['st', 0, j]);
      final y = j * _seg + 90 + r() * 330;
      if (near != null && (y - g.camY).abs() >= (near.$2 - g.camY).abs()) {
        continue;
      }
      final x = _metroX(g, 0, y);
      near = (
        x,
        y,
        _stations[modI(j * 7, _stations.length)],
        'G${'${modI(j, 60) + 1}'.padLeft(2, '0')}',
        g.alpha(x, y),
      );
    }
    if (near != null && (near.$2 - g.camY).abs() >= 500) near = null;
  }
  for (var li = 0; li < 4; li++) {
    final base = _lines[li].$4, side = base.sign, inner = li.isEven;
    for (
      var j = (g.y0 / _seg).floor() - 1;
      j <= (g.y1 / _seg).floor() + 1;
      j++
    ) {
      final r = g.r(['st', li, j]);
      final y = j * _seg + 90 + r() * 330, x = _metroX(g, li, y);
      final al = g.alpha(x, y);
      if (al < 0.01 || y < g.y0 - 60 || y > g.y1 + 60) continue;
      final xfer = inner && r() < 0.3;
      final name = _stations[modI(j * 7 + li * 13, _stations.length)];
      final code = '${_lines[li].$1}${'${modI(j, 60) + 1}'.padLeft(2, '0')}';
      if (xfer) {
        final x2 = _metroX(g, li + 1, y);
        final pill = RRect.fromRectAndRadius(
          Rect.fromLTWH(math.min(x, x2) - 11, y - 11, (x2 - x).abs() + 22, 22),
          const Radius.circular(11),
        );
        c
          ..drawRRect(pill, g.fill(g.bg(y, 1)))
          ..drawRRect(pill, wide(g.ink(0.6 * al), 2.2));
        g
          ..circle(x, y, 5.5, g.ink(0.6 * al), w: 2.2 * g.s)
          ..circle(x2, y, 5.5, g.ink(0.6 * al), w: 2.2 * g.s);
      } else {
        g.rect(
          Rect.fromLTWH(side > 0 ? x + 3 : x - 15, y - 3, 12, 6),
          col(li, 0.7 * al),
          filled: true,
        );
      }
      // 视口旁那一站留给下面的高亮重画
      if (li == 0 && near != null && near.$2 == y) continue;
      final lx = x + side * 22;
      g
        ..text(
          name,
          lx,
          y + (xfer ? 26 : 5),
          14,
          ChannelFont.mono,
          g.ink(0.5 * al),
          align: _away(side),
        )
        ..text(
          code,
          lx,
          y + (xfer ? 42 : 21),
          11,
          ChannelFont.pixel,
          col(li, 0.75 * al),
          align: _away(side),
        );
    }
  }
  // 列车
  void train(int li, double y, double al, bool lit) {
    final body = _poly([
      for (var k = -54.0; k <= 54; k += 6) Offset(_metroX(g, li, y + k), y + k),
    ]);
    c
      ..drawPath(body, wide(g.bg(y, 1), 26, round: true))
      ..drawPath(
        body,
        wide(col(li, (lit ? 0.95 : 0.75) * al), 18, round: true),
      );
    for (var k = -40.0; k <= 40; k += 16) {
      final x = _metroX(g, li, y + k);
      g.rect(
        Rect.fromLTWH(x - 4, y + k - 4, 8, 8),
        g.bg(y, 0.9 * al),
        filled: true,
      );
    }
    g.circle(
      _metroX(g, li, y + 54),
      y + 54,
      3,
      (g.dark ? const Color(0xFFFFF0B4) : const Color(0xFFFFFFFF)).withValues(
        alpha: al.clamp(0, 1),
      ),
      filled: true,
    );
  }

  // G 线列车停在视口旁，最近一站亮起
  if (inZone) {
    final al = g.alpha(_lines[0].$4, g.camY);
    if (near case (
      final x,
      final y,
      final name,
      final code,
      final a2,
    ) when a2 > 0.01) {
      final pulse = g.motion ? modD(g.t * 0.8, 1) : 0.3;
      g
        ..circle(x, y, 12 + pulse * 26, col(0, 0.5 * (1 - pulse) * a2), w: 1.5)
        ..circle(x, y, 9, g.bg(y, 1), filled: true)
        ..circle(x, y, 9, col(0, 0.9 * a2), w: 3 * g.s)
        ..text(
          name,
          x - 24,
          y + 6,
          17,
          ChannelFont.mono,
          col(0, 0.95 * a2),
          align: TextAlign.right,
        )
        ..text(
          '$code · NEXT',
          x - 24,
          y + 24,
          11,
          ChannelFont.pixel,
          col(0, 0.8 * a2),
          align: TextAlign.right,
        );
    }
    if (al > 0.01) train(0, g.camY, al, true);
  }
  // B / R 线空闲时自己跑
  for (final li in const [2, 3]) {
    const l = 2600.0;
    final dir = li == 2 ? 1 : -1;
    for (var j = (g.y0 / l).floor() - 1; j <= (g.y1 / l).floor() + 1; j++) {
      final r = g.r(['tr', li, j]);
      final y = j * l + modD(r() * l + (g.motion ? g.t * 110 * dir : 0), l);
      if (y < g.y0 - 80 || y > g.y1 + 80) continue;
      final al = g.alpha(_lines[li].$4, y);
      if (al > 0.01) train(li, y, al * 0.85, false);
    }
  }
  // 线路徽标
  for (var li = 0; li < 4; li++) {
    for (
      var j = (g.y0 / (_seg * 4)).floor();
      j <= (g.y1 / (_seg * 4)).floor();
      j++
    ) {
      final y = j * _seg * 4 + 30, x = _metroX(g, li, y);
      final al = g.alpha(x, y);
      if (al < 0.01) continue;
      g
        ..circle(x, y, 15, col(li, 0.9 * al), filled: true)
        ..text(
          _lines[li].$1,
          x,
          y + 6,
          17,
          ChannelFont.mono,
          (g.dark ? const Color(0xFF0A0E0E) : const Color(0xFFFFFFFF))
              .withValues(alpha: al.clamp(0, 1)),
          align: TextAlign.center,
        );
    }
  }
  // 图例（每段一块）
  final r = g.r(['legend', g.k]);
  final side = r() < 0.5 ? -1.0 : 1.0;
  final x = side * (_e + 400), y = g.zs + _zone * (0.35 + 0.3 * r());
  final al = g.alpha(x, y);
  if (al > 0.01 && y > g.y0 - 200 && y < g.y1 + 60) {
    const w = 210.0;
    final x0 = side < 0 ? x - w : x;
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(x0, y - 30, w, 162),
      const Radius.circular(8),
    );
    c
      ..drawRRect(card, g.fill(g.bg(y, 1)))
      ..drawRRect(card, g.stroke(g.ink(0.4 * al)));
    g.text(
      'W.O.F METRO',
      x0 + 16,
      y - 4,
      18,
      ChannelFont.pixel,
      g.ink(0.6 * al),
    );
    for (var i = 0; i < 4; i++) {
      final yy = y + 24 + i * 26;
      g
        ..rect(
          Rect.fromLTWH(x0 + 16, yy - 4, 26, 7),
          col(i, 0.8 * al),
          filled: true,
        )
        ..text(
          '${_lines[i].$1}  ${_lineNames[i]}',
          x0 + 52,
          yy + 4,
          13,
          ChannelFont.mono,
          g.ink(0.5 * al),
        );
    }
  }
}
