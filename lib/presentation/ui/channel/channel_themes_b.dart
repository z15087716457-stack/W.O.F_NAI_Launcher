import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'channel_geometry.dart';
import 'channel_paint.dart';

// 植物标本、回廊（原型 THEMES.herb / THEMES.arcade，装饰坐标）。

const _e = ChannelGeo.e;
const _zone = ChannelGeo.zone;
const _sides = [-1.0, 1.0];

const _latin = [
  'Filix elegans', 'Adiantum tenue', 'Salvia nemorosa', 'Lunaria rediviva', //
  'Briza media', 'Achillea ptarmica', 'Silene vulgaris', 'Thalictrum minus',
  'Asplenium ruta', 'Campanula patula',
];

Offset _bezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final u = 1 - t;
  return p0 * (u * u * u) +
      p1 * (3 * u * u * t) +
      p2 * (3 * u * t * t) +
      p3 * (t * t * t);
}

void paintHerb(ChannelPaint g) {
  final c = g.canvas;
  // 两列：主列贴着图片（左栏展开也看得见），次列在外侧、错开半格
  for (final side in _sides) {
    for (final col in const [0, 1]) {
      final ch = col == 1 ? 1300.0 : 900.0, oy = col == 1 ? 650.0 : 0.0;
      for (
        var j = ((g.y0 - 200 - oy) / ch).floor();
        j <= ((g.y1 + 1000 - oy) / ch).floor();
        j++
      ) {
        final r = g.r(['sp', side, col, j]);
        if (r() < (col == 1 ? 0.35 : 0.12)) continue;
        final bx =
            side * (col == 1 ? _e + 440 + r() * 200 : _e + 130 + r() * 170);
        final by = oy + j * ch + ch * 0.86 + r() * 60;
        final len = (col == 1 ? 480 : 400) + r() * 300;
        final lean = side * (r() < 0.5 ? 1 : -1) * (0.04 + r() * 0.16);
        final c1x = (r() - 0.5) * 50;
        final flower = r() < 0.5, tapeA = (r() - 0.5) * 0.5;
        final no = 100 + (r() * 900).floor();
        final nm = _latin[(r() * _latin.length).floor()];
        final yr = 1890 + (r() * 40).floor();
        final al = g.alpha(bx, by - len / 2);
        if (al < 0.01) continue;
        final sw = g.motion ? math.sin(g.t * 0.55 + j * 1.7 + side) * 10 : 0.0;
        final tx = bx + lean * len + sw, ty = by - len;
        final p0 = Offset(bx, by), p1 = Offset(bx + c1x, by - len * 0.35);
        final p2 = Offset(tx - lean * len * 0.2 + sw * 0.5, by - len * 0.75);
        final p3 = Offset(tx, ty);
        const n = 26;
        final pts = [
          for (var i = 0; i <= n; i++) _bezier(p0, p1, p2, p3, i / n),
        ];
        g.path(Path()..addPolygon(pts, false), g.ink(0.44 * al), w: 1.4);
        var alt = r() < 0.5 ? 1 : -1;
        for (var i = 4; i < n - 2; i += 2 + (r() * 2).floor()) {
          final p = pts[i], d = pts[i + 1] - pts[i - 1];
          final ang = math.atan2(d.dy, d.dx) + alt * (0.55 + r() * 0.45);
          final l = (46 + r() * 80) * (1 - i / n * 0.45),
              wr = 0.26 + r() * 0.12;
          final q = p + Offset(math.cos(ang) * l, math.sin(ang) * l);
          final m = (p + q) / 2;
          final nv = Offset(-math.sin(ang) * l * wr, math.cos(ang) * l * wr);
          final leaf = Path()
            ..moveTo(p.dx, p.dy)
            ..quadraticBezierTo(m.dx + nv.dx, m.dy + nv.dy, q.dx, q.dy)
            ..quadraticBezierTo(m.dx - nv.dx, m.dy - nv.dy, p.dx, p.dy);
          g.path(leaf, g.ink(0.05 * al), filled: true);
          g.path(leaf, g.ink(0.38 * al));
          final rib = p + (q - p) * 0.85;
          g.line(p.dx, p.dy, rib.dx, rib.dy, g.ink(0.2 * al));
          alt = -alt;
        }
        if (flower) {
          final k = 5 + (j & 1);
          for (var i = 0; i < k; i++) {
            final a = i / k * tau + j;
            c
              ..save()
              ..translate(tx + math.cos(a) * 17, ty + math.sin(a) * 17)
              ..rotate(a);
            final petal = Rect.fromCenter(
              center: Offset.zero,
              width: 34,
              height: 14,
            );
            c.drawOval(petal, g.fill(g.acc(0.07 * al)));
            c.drawOval(petal, g.stroke(g.acc(0.46 * al)));
            c.restore();
          }
          g.circle(tx, ty, 5, g.acc(0.5 * al), filled: true);
        } else {
          for (var i = 0; i < 9; i++) {
            final a = -math.pi / 2 + (i - 4) * 0.24;
            g.circle(
              tx + math.cos(a) * 30,
              ty + math.sin(a) * 30,
              3.2,
              g.ink(0.42 * al),
              filled: true,
            );
            g.line(
              tx,
              ty,
              tx + math.cos(a) * 27,
              ty + math.sin(a) * 27,
              g.ink(0.2 * al),
            );
          }
        }
        void tape(Offset at, double angle, double w, double h, double a) {
          c
            ..save()
            ..translate(at.dx, at.dy)
            ..rotate(angle)
            ..drawRect(
              Rect.fromCenter(center: Offset.zero, width: w, height: h),
              g.fill(g.ink(a)),
            )
            ..restore();
        }

        tape(Offset(bx, by - 34), tapeA, 56, 18, 0.075 * al);
        tape(pts[14], -tapeA * 1.4 + 0.2, 48, 16, 0.06 * al);
        final lx = bx - 88, ly = by + 22, card = Rect.fromLTWH(lx, ly, 176, 70);
        g.rect(card, g.bg(ly, 0.85), filled: true);
        g.rect(card, g.ink(0.32 * al));
        g.line(lx + 10, ly + 52, lx + 166, ly + 52, g.ink(0.32 * al));
        g.text(
          'No. $no',
          lx + 10,
          ly + 22,
          16,
          ChannelFont.mono,
          g.ink(0.55 * al),
        );
        g.text(nm, lx + 10, ly + 42, 13, ChannelFont.mono, g.ink(0.4 * al));
        g.text(
          '$yr · 10 · ${(1 + modI(j, 28)).toString().padLeft(2, '0')}',
          lx + 10,
          ly + 65,
          10,
          ChannelFont.mono,
          g.ink(0.32 * al),
        );
      }
    }
  }
  // 外侧散落的种子
  const cell = 380.0;
  for (var cx = (g.x0 / cell).floor(); cx <= (g.x1 / cell).floor(); cx++) {
    for (var cy = (g.y0 / cell).floor(); cy <= (g.y1 / cell).floor(); cy++) {
      if (((cx + .5) * cell).abs() < _e + 200) continue;
      final r = g.r(['seed', cx, cy]);
      if (r() < 0.62) continue;
      final x = cx * cell + r() * cell,
          y = cy * cell + r() * cell,
          a = r() * 6.28;
      final al = g.alpha(x, y);
      if (al < 0.01) continue;
      final col = g.ink(0.3 * al);
      g.circle(x, y, 5, col);
      g.line(
        x + math.cos(a) * 5,
        y + math.sin(a) * 5,
        x + math.cos(a) * 26,
        y + math.sin(a) * 26,
        col,
      );
    }
  }
}

void paintArcade(ChannelPaint g) {
  final c = g.canvas;
  const bay = 340.0, xi = _e + 56, xo = _e + 300, xw = _e + 372;
  final j0 = (g.y0 / bay).floor() - 1, j1 = (g.y1 / bay).floor() + 1;
  void pier(double x, double y, double al) {
    final sq = Rect.fromCenter(center: Offset(x, y), width: 30, height: 30);
    g.rect(sq, g.ink(0.14 * al), filled: true);
    g.rect(sq, g.ink(0.42 * al));
    for (final d in const [
      Offset(17, 0),
      Offset(-17, 0),
      Offset(0, 17),
      Offset(0, -17),
    ]) {
      g.circle(x + d.dx, y + d.dy, 5.5, g.bg(y, 1), filled: true);
      g.circle(x + d.dx, y + d.dy, 5.5, g.ink(0.42 * al));
    }
  }

  const dash = [7.0, 6.0];
  for (var j = j0; j <= j1; j++) {
    final y = j * bay, sec = g.r(['bay', j])() < 0.1;
    // 中殿肋拱（图片后面，极淡）
    final an = g.alpha(0, y + bay / 2) * 0.6;
    if (an > 0.01) {
      g.dashedLine(-xi, y, xi, y + bay, g.ink(0.16 * an), dash);
      g.dashedLine(xi, y, -xi, y + bay, g.ink(0.16 * an), dash);
      final rib = g.ink(0.2 * an);
      g.line(-xi, y - 5, xi, y - 5, rib);
      g.line(-xi, y + 5, xi, y + 5, rib);
      g.circle(0, y + bay / 2, 10, rib);
    }
    for (final sd in _sides) {
      final al = g.alpha(sd * (xi + xo) / 2, y + bay / 2);
      if (al < 0.01) continue;
      g.dashedLine(sd * xi, y, sd * xo, y + bay, g.ink(0.22 * al), dash);
      g.dashedLine(sd * xo, y, sd * xi, y + bay, g.ink(0.22 * al), dash);
      final rib = g.ink(0.28 * al);
      g.line(sd * xi, y - 5, sd * xo, y - 5, rib);
      g.line(sd * xi, y + 5, sd * xo, y + 5, rib);
      g.line(sd * (xi - 6), y, sd * (xi - 6), y + bay, rib);
      g.line(sd * (xo + 6), y, sd * (xo + 6), y + bay, rib);
      g.circle(sd * (xi + xo) / 2, y + bay / 2, 9, g.ink(0.36 * al));
      pier(sd * xi, y, al);
      pier(sd * xo, y, al);
      // 外墙 + 窗
      final g0 = y + bay / 2 - 56,
          g1 = y + bay / 2 + 56,
          wall = g.ink(0.4 * al);
      for (final wx in const [xw, xw + 28]) {
        g.line(sd * wx, y, sd * wx, g0, wall);
        g.line(sd * wx, g1, sd * wx, y + bay, wall);
      }
      final hatch = Path();
      for (var hy = y; hy < y + bay; hy += 22) {
        if (hy > g0 - 28 && hy < g1) continue;
        hatch
          ..moveTo(sd * xw, hy)
          ..lineTo(sd * (xw + 28), hy + 28);
      }
      g.path(hatch, g.ink(0.2 * al));
      final win = g.ink(0.26 * al);
      for (final wx in const [xw, xw + 14, xw + 28]) {
        g.line(sd * wx, g0, sd * wx, g1, win);
      }
      g.line(sd * xw, g0, sd * (xw + 28), g0, win);
      g.line(sd * xw, g1, sd * (xw + 28), g1, win);
      // 尺寸线
      final dx = sd * (_e + 432), dim = g.ink(0.3 * al);
      g.line(dx, y, dx, y + bay, dim);
      g.line(dx - 8, y + 8, dx + 8, y - 8, dim);
      g.line(dx - 14, y, dx + 14, y, dim);
      c
        ..save()
        ..translate(dx - sd * 12, y + bay / 2)
        ..rotate(-math.pi / 2);
      g.text(
        '3 400',
        0,
        sd < 0 ? -2 : 12,
        16,
        ChannelFont.mono,
        g.ink(0.4 * al),
        align: TextAlign.center,
      );
      c.restore();
      // 轴线 + 轴号
      g.dashedLine(
        sd * (_e + 446),
        y,
        sd * (_e + 478),
        y,
        g.ink(0.18 * al),
        const [18, 4, 2, 4],
      );
      g.circle(sd * (_e + 502), y, 24, g.ink(0.42 * al));
      g.text(
        sd < 0 ? '${modI(j, 40) + 1}' : 'ABCDEFGHJKLMNPQRSTUVWXYZ'[modI(j, 24)],
        sd * (_e + 502),
        y + 7,
        20,
        ChannelFont.mono,
        g.ink(0.55 * al),
        align: TextAlign.center,
      );
      if (sec && sd > 0) {
        const sx = _e + 600;
        final sy = y + bay / 2;
        c.drawPath(
          Path()
            ..moveTo(sx, sy)
            ..arcTo(
              Rect.fromCircle(center: Offset(sx, sy), radius: 36),
              -math.pi / 2,
              math.pi,
              false,
            )
            ..close(),
          g.fill(g.acc(0.5 * al)),
        );
        g.circle(sx, sy, 36, g.acc(0.6 * al));
        g.line(sx - 36, sy, sx + 36, sy, g.acc(0.6 * al));
        g.text(
          'A',
          sx - 14,
          sy - 8,
          18,
          ChannelFont.mono,
          g.acc(0.7 * al),
          align: TextAlign.center,
        );
        g.text(
          '${modI(j, 9) + 1}',
          sx - 14,
          sy + 24,
          16,
          ChannelFont.mono,
          g.acc(0.7 * al),
          align: TextAlign.center,
        );
      }
    }
  }
  // 每段一扇玫瑰窗（嵌在外墙上）
  final r = g.r(['rose', g.k]);
  final side = r() < 0.5 ? -1.0 : 1.0;
  final cx = side * (xw + 14), cy = g.zs + _zone * (0.3 + 0.4 * r());
  final al = g.alpha(cx, cy);
  const big = 250.0, n = 12, k = 0.62, w = 1 / k;
  if (al <= 0.01 || cy + big < g.y0 || cy - big > g.y1) return;
  c
    ..save()
    ..translate(cx, cy)
    ..scale(k, k);
  g.circle(0, 0, big + 18, g.bg(cy, 1), filled: true);
  g.circle(0, 0, big + 18, g.ink(0.46 * al), w: w);
  g.circle(0, 0, big, g.ink(0.46 * al), w: w);
  for (var i = 0; i < n; i++) {
    final a = i / n * tau, a2 = (i + .5) / n * tau;
    final lobe = Offset(math.cos(a) * 168, math.sin(a) * 168);
    g.circle(
      lobe.dx,
      lobe.dy,
      58,
      i.isOdd ? g.acc(0.1 * al) : g.ink(0.06 * al),
      filled: true,
    );
    g.circle(lobe.dx, lobe.dy, 58, g.ink(0.38 * al), w: w);
    g.line(
      math.cos(a2) * 84,
      math.sin(a2) * 84,
      math.cos(a2) * big,
      math.sin(a2) * big,
      g.ink(0.3 * al),
      w,
    );
    g.circle(math.cos(a) * 112, math.sin(a) * 112, 22, g.ink(0.3 * al), w: w);
  }
  g.circle(0, 0, 84, g.acc(0.16 * al), filled: true);
  g.circle(0, 0, 84, g.ink(0.46 * al), w: w);
  for (var i = 0; i < 6; i++) {
    final a = i / 6 * tau;
    g.circle(math.cos(a) * 42, math.sin(a) * 42, 30, g.ink(0.3 * al), w: w);
  }
  g.circle(0, 0, 12, g.acc(0.45 * al), filled: true);
  c.restore();
}
