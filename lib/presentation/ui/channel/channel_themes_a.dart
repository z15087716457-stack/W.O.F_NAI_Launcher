import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'channel_geometry.dart';
import 'channel_paint.dart';

// 像素电路、星图（原型 THEMES.circuit / THEMES.stars，装饰坐标）。

const _e = ChannelGeo.e;
const _m0 = ChannelGeo.m0;
const _b1 = ChannelGeo.b1;
const _b2 = ChannelGeo.b2;
const _zone = ChannelGeo.zone;
const _sides = [-1.0, 1.0];

String _hex4(int v) => v.toRadixString(16).toUpperCase().padLeft(4, '0');

/// 现有像素底纹的 5 种小件 × 4 个朝向（`canvas_pixel_background.dart`），像素电路外侧散落用。
final List<List<Rect>> channelMotifs = () {
  final out = <List<Rect>>[];
  for (var kind = 0; kind < 5; kind++) {
    for (var turns = 0; turns < 4; turns++) {
      final r = <Rect>[];
      void rect(double x, double y, double w, double h) =>
          r.add(switch (turns) {
            1 => Rect.fromLTWH(-y - h, x, h, w),
            2 => Rect.fromLTWH(-x - w, -y - h, w, h),
            3 => Rect.fromLTWH(y, -x - w, h, w),
            _ => Rect.fromLTWH(x, y, w, h),
          });
      void sq(double x, double y, double s) {
        rect(x, y, s, 2);
        rect(x, y + s - 2, s, 2);
        rect(x, y, 2, s);
        rect(x + s - 2, y, 2, s);
      }

      void line(List<List<double>> p) {
        for (var i = 1; i < p.length; i++) {
          rect(
            math.min(p[i - 1][0], p[i][0]),
            math.min(p[i - 1][1], p[i][1]),
            (p[i][0] - p[i - 1][0]).abs() + 2,
            (p[i][1] - p[i - 1][1]).abs() + 2,
          );
        }
      }

      switch (kind) {
        case 0:
          sq(0, 0, 8);
          line([
            [8, 2],
            [30, 2],
            [30, 18],
            [46, 18],
          ]);
          rect(46, 16, 6, 6);
        case 1:
          sq(0, 0, 14);
          for (final p in const [2.0, 8.0]) {
            rect(p, -6, 2, 4);
            rect(p, 16, 2, 4);
            rect(-6, p, 4, 2);
            rect(16, p, 4, 2);
          }
          rect(6, 6, 2, 2);
        case 2:
          line([
            [0, 0],
            [20, 0],
            [20, -16],
            [42, -16],
          ]);
          sq(-6, -2, 6);
          rect(44, -16, 4, 4);
        case 3:
          rect(0, 0, 4, 4);
          rect(10, 0, 4, 4);
          rect(20, 0, 4, 4);
          line([
            [0, 14],
            [24, 14],
            [24, 26],
          ]);
        default:
          sq(0, 0, 8);
          sq(28, -20, 6);
          line([
            [8, 2],
            [16, 2],
            [16, -18],
            [28, -18],
          ]);
      }
      out.add(r);
    }
  }
  return out;
}();

void paintCircuit(ChannelPaint g) {
  const seg = 520.0;
  final j0 = ((g.y0 - seg) / seg).floor(), j1 = ((g.y1 + seg) / seg).floor();
  for (final side in _sides) {
    for (var b = 0; b < 2; b++) {
      final base = side * (_e + 80 + b * 190);
      double xAt(int j) =>
          base + side * (g.r(['bus', side, b, j])() < 0.5 ? 0 : 48);
      for (var j = j0; j <= j1; j++) {
        final r = g.r(['seg', side, b, j]);
        final xa = xAt(j), xb = xAt(j + 1), yA = j * seg, yB = yA + seg;
        final dx = (xb - xa).abs();
        final rb = r(), by = yA + 70 + r() * (seg - 200), out = r() < 0.65;
        final blen = 70 + r() * 170,
            jog = (r() < 0.5 ? -1 : 1) * (20 + r() * 30);
        final pad = r() < 0.5, rc = r(), rl = r(), hx = (r() * 65535).floor();
        final ph = r();
        final al = g.alpha(xa, yA + seg / 2);
        if (al < 0.01) continue;
        g.path(
          Path()
            ..moveTo(xa, yA)
            ..lineTo(xa, yB - dx)
            ..lineTo(xb, yB),
          g.ink((b == 1 ? 0.2 : 0.3) * al),
          w: b == 1 ? 1.2 : 2,
        );
        if (rb < 0.6) {
          final dir = out ? side : -side;
          final len = out ? blen : math.min(blen, xa.abs() - (_m0 - 30));
          if (len > 40) {
            final xm = xa + dir * len * 0.55, c = g.ink(0.24 * al);
            g.path(
              Path()
                ..moveTo(xa, by)
                ..lineTo(xm, by)
                ..lineTo(xm + dir * jog.abs(), by + jog)
                ..lineTo(xa + dir * len, by + jog),
              c,
              w: 1.2,
            );
            final ex = xa + dir * len, ey = by + jog;
            if (pad) {
              g.rect(Rect.fromLTWH(ex - 7, ey - 7, 14, 14), c, w: 1.2);
            } else {
              g.circle(ex + dir * 6, ey, 6, c, w: 1.2);
            }
            g.rect(
              Rect.fromLTWH(xa - 4, by - 4, 8, 8),
              g.ink(0.36 * al),
              filled: true,
            );
          }
        }
        if (b == 0 && rc < 0.24) {
          const cw = 84.0, ch = 124.0;
          final cx = xa + side * 44 + (side < 0 ? -cw : 0), cy = yA + seg * 0.3;
          final box = Rect.fromLTWH(cx, cy, cw, ch), c = g.ink(0.28 * al);
          g.rect(box, g.ink(0.035 * al), filled: true);
          g.rect(box, c, w: 1.2);
          final pins = Path();
          for (var p = cy + 16; p < cy + ch - 8; p += 18) {
            pins
              ..moveTo(cx - 12, p)
              ..lineTo(cx, p)
              ..moveTo(cx + cw, p)
              ..lineTo(cx + cw + 12, p);
          }
          pins.addArc(
            Rect.fromCircle(center: Offset(cx + cw / 2, cy), radius: 10),
            0,
            math.pi,
          );
          g.path(pins, c, w: 1.2);
          g.line(
            xa,
            cy + ch / 2,
            side < 0 ? cx + cw + 12 : cx - 12,
            cy + ch / 2,
            c,
            1.2,
          );
          g.text(
            'U${modI(j * 7, 89) + 10}',
            cx + 12,
            cy + 34,
            22,
            ChannelFont.pixel,
            g.ink(0.42 * al),
          );
        }
        if (rl < 0.3) {
          g.text(
            '0x${_hex4(hx)}',
            xa + side * 16,
            yA + 44,
            16,
            ChannelFont.pixel,
            g.ink(0.34 * al),
            align: side < 0 ? TextAlign.right : TextAlign.left,
          );
        }
        if (g.motion && b == 0 && ph < 0.7) {
          final span = yB - dx - yA;
          if (span > 40) {
            final y = yA + modD(g.t * 170 + ph * 900, span);
            g.rect(
              Rect.fromLTWH(xa - 9, y - 26, 18, 52),
              g.acc(0.14 * al),
              filled: true,
            );
            g.rect(
              Rect.fromLTWH(xa - 4, y - 9, 8, 18),
              g.acc(0.6 * al),
              filled: true,
            );
          }
        }
      }
    }
  }
  // 每段一颗“主芯片”
  {
    final r = g.r(['cpu', g.k]);
    final side = r() < 0.5 ? -1.0 : 1.0;
    const s2 = 200.0;
    final cx = side * (_e + 250), cy = g.zs + _zone * (0.3 + 0.4 * r());
    final al = g.alpha(cx, cy);
    final code = (r() * 4095).floor().toRadixString(16).toUpperCase();
    if (al > 0.01 && cy + 400 > g.y0 && cy - 400 < g.y1) {
      final x0 = cx - s2 / 2, y0 = cy - s2 / 2;
      final pins = Path();
      for (var p = 20.0; p < s2; p += 20) {
        final q = ((p / 20).round() % 3) * 16;
        pins
          ..moveTo(x0 + p, y0)
          ..lineTo(x0 + p, y0 - 40 - q)
          ..moveTo(x0 + p, y0 + s2)
          ..lineTo(x0 + p, y0 + s2 + 40 + q)
          ..moveTo(x0, y0 + p)
          ..lineTo(x0 - 40 - q, y0 + p)
          ..moveTo(x0 + s2, y0 + p)
          ..lineTo(x0 + s2 + 40 + q, y0 + p);
      }
      g.path(pins, g.ink(0.2 * al));
      final box = Rect.fromLTWH(x0, y0, s2, s2);
      g.rect(box, g.bg(cy, 1), filled: true);
      g.rect(box, g.ink(0.05 * al), filled: true);
      g.rect(box, g.ink(0.42 * al), w: 1.4);
      g.rect(box.deflate(14), g.ink(0.42 * al));
      g.rect(
        Rect.fromCenter(center: Offset(cx, cy), width: 120, height: 120),
        g.acc(0.5 * al),
      );
      final dots = Path();
      for (var i = 0; i < 6; i++) {
        for (var j = 0; j < 6; j++) {
          dots.addRect(
            Rect.fromLTWH(cx - 50 + i * 18 + 5, cy - 50 + j * 18 + 5, 6, 6),
          );
        }
      }
      g.path(dots, g.acc(0.32 * al), filled: true);
      g.path(
        Path()
          ..moveTo(x0 + 14, y0 + 14)
          ..lineTo(x0 + 40, y0 + 14)
          ..lineTo(x0 + 14, y0 + 40)
          ..close(),
        g.ink(0.5 * al),
        filled: true,
      );
      g.text(
        'W.O.F-N5',
        x0 + 26,
        y0 + s2 - 34,
        24,
        ChannelFont.pixel,
        g.ink(0.55 * al),
      );
      g.text(
        'REV $code · 2026',
        x0 + 26,
        y0 + s2 - 14,
        13,
        ChannelFont.mono,
        g.ink(0.4 * al),
      );
    }
  }
  // 远处散落的像素小件（现在的底纹，放大一倍）
  const cell = 220.0;
  for (var cx = (g.x0 / cell).floor(); cx <= (g.x1 / cell).floor(); cx++) {
    for (
      var cy = ((g.y0 - 60) / cell).floor();
      cy <= ((g.y1 + 60) / cell).floor();
      cy++
    ) {
      if (((cx + .5) * cell).abs() < _b1 + 40) continue;
      final r = g.r(['far', cx, cy]);
      if (r() < 0.55) continue;
      final x = cx * cell + r() * cell * 0.7, y = cy * cell + r() * cell * 0.7;
      final v = (r() * channelMotifs.length).floor(), al = g.alpha(x, y);
      if (al < 0.01) continue;
      final p = Path();
      for (final q in channelMotifs[v]) {
        p.addRect(
          Rect.fromLTWH(
            x + q.left * 2,
            y + q.top * 2,
            q.width * 2,
            q.height * 2,
          ),
        );
      }
      g.path(p, g.ink(0.2 * al), filled: true);
    }
  }
}

const _constellations = [
  'LYRA', 'VELA', 'CETUS', 'ARA', 'NORMA', 'PYXIS', 'MENSA', //
  'CRUX', 'DORADO', 'LUPUS', 'CORVUS', 'FORNAX', 'OCTANS', 'TUCANA',
];
const _greek = 'αβγδεζηθ';

String _two(int v) => v.toString().padLeft(2, '0');
String _signed(int v) => v > 0 ? '+$v' : '$v';

void paintStars(ChannelPaint g) {
  // 星点
  const cell = 160.0;
  for (var cx = (g.x0 / cell).floor(); cx <= (g.x1 / cell).floor(); cx++) {
    for (
      var cy = (g.y0 / cell).floor() - 1;
      cy <= (g.y1 / cell).floor();
      cy++
    ) {
      final r = g.r(['st', cx, cy]);
      final corr = ((cx + .5) * cell).abs() < _e, u = r();
      final n = corr
          ? (u < 0.16 ? 1 : 0)
          : (u < 0.28
                ? 0
                : u < 0.74
                ? 1
                : 2);
      for (var i = 0; i < n; i++) {
        final x = cx * cell + r() * cell, y = cy * cell + r() * cell;
        final mag = math.pow(r(), 2.4).toDouble(), rate = 1.2 + r() * 1.6;
        final phs = r() * 6.28, warm = r() < 0.16;
        final al = g.alpha(x, y);
        if (al < 0.01) continue;
        final tw = g.motion && mag > 0.45
            ? 0.68 + 0.32 * math.sin(g.t * rate + phs)
            : 1.0;
        final col = warm ? g.acc : g.ink;
        g.circle(
          x,
          y,
          (0.7 + mag * 2.1) * g.px,
          col((0.32 + mag * 0.62) * al * tw),
          filled: true,
        );
        if (mag > 0.7) {
          final l = (5 + mag * 7) * g.px, c = col(0.42 * al * tw);
          g.line(x - l, y, x + l, y, c);
          g.line(x, y - l, x, y + l, c);
        }
      }
    }
  }
  // 星座：每侧从图片边往外 330 一列，竖向 760 一格
  const bw = 330.0, bh = 760.0;
  for (final side in _sides) {
    for (var bi = 0; bi < 5; bi++) {
      final xa = _e + 40 + bi * bw;
      for (var by = (g.y0 / bh).floor() - 1; by <= (g.y1 / bh).floor(); by++) {
        final r = g.r(['cn', side, bi, by]);
        if (r() < (bi == 0 ? 0.3 : 0.5)) continue;
        final lx = xa + 30, rx = xa + bw - 30;
        final n = 4 + (r() * 3).floor();
        var x = lerpD(lx, rx, 0.15 + r() * 0.7),
            y = by * bh + bh * (0.1 + r() * 0.3);
        var ang = r() * 6.28;
        final pts = [Offset(side * x, y)];
        for (var i = 1; i < n; i++) {
          ang += (r() - 0.5) * 1.7;
          final st = 80 + r() * 110;
          x = (x + math.cos(ang) * st).clamp(lx, rx);
          y = (y + math.sin(ang).abs() * st + 30).clamp(
            by * bh + 30,
            by * bh + bh - 30,
          );
          pts.add(Offset(side * x, y));
        }
        final nm = _constellations[(r() * _constellations.length).floor()];
        final gl = _greek[(r() * 8).floor()], h = (r() * 24).floor();
        final mi = (r() * 60).floor(), dec = (r() * 120 - 60).truncate();
        final al = g.alpha(pts[0].dx, pts[0].dy);
        if (al < 0.01) continue;
        g.path(Path()..addPolygon(pts, false), g.ink(0.26 * al));
        for (final p in pts) {
          g.circle(p.dx, p.dy, 4 * g.px, g.bg(p.dy, 1), filled: true);
          g.circle(p.dx, p.dy, 4 * g.px, g.ink(0.55 * al));
        }
        final lx0 = pts[0].dx + side * 16;
        final align = side < 0 ? TextAlign.right : TextAlign.left;
        g.text(
          nm,
          lx0,
          pts[0].dy - 18,
          20,
          ChannelFont.mono,
          g.ink(0.46 * al),
          align: align,
        );
        g.text(
          '$gl  ${_two(h)}h${_two(mi)}m  ${_signed(dec)}°',
          lx0,
          pts[0].dy + 4,
          14,
          ChannelFont.mono,
          g.ink(0.3 * al),
          align: align,
        );
      }
    }
  }
  // 刻度环：每段每侧一组，圆心在次带外沿，弧线扫进主带
  for (final side in _sides) {
    final r = g.r(['ring', g.k, side]);
    final cx = side * (_b2 - 40 + r() * 120),
        cy = g.zs + _zone * (0.22 + 0.56 * r());
    final al = g.alpha(side * (_e + 300), cy);
    if (al < 0.01 || cy + 640 < g.y0 || cy - 640 > g.y1) continue;
    const ro = 540.0;
    for (final (i, rad) in const [300.0, 380.0, 450.0, ro].indexed) {
      final c = g.ink((0.26 - i * 0.03) * al);
      if (i.isOdd) {
        g.dashedCircle(cx, cy, rad, c, const [4, 7]);
      } else {
        g.circle(cx, cy, rad, c);
      }
    }
    final ticks = Path();
    for (var d = 0; d < 360; d += 3) {
      final a = d * math.pi / 180,
          l = d % 30 == 0
              ? 34
              : d % 15 == 0
              ? 20
              : 10;
      final co = math.cos(a), si = math.sin(a);
      ticks
        ..moveTo(cx + co * ro, cy + si * ro)
        ..lineTo(cx + co * (ro - l), cy + si * (ro - l));
    }
    g.path(ticks, g.ink(0.28 * al));
    for (var d = 0; d < 360; d += 30) {
      final a = d * math.pi / 180;
      g.text(
        '$d°',
        cx + math.cos(a) * (ro - 58),
        cy + math.sin(a) * (ro - 58) + 6,
        16,
        ChannelFont.mono,
        g.ink(0.4 * al),
        align: TextAlign.center,
      );
    }
    final cross = g.ink(0.16 * al);
    g.line(cx, cy - ro - 30, cx, cy + ro + 30, cross);
    g.line(cx - ro - 30, cy, cx + ro + 30, cy, cross);
    g.circle(
      cx - side * ro * math.cos(0.5),
      cy - ro * math.sin(0.5),
      5,
      g.acc(0.55 * al),
      filled: true,
    );
  }
  // 赤纬尺（左侧，贴着图片）
  const x = -(_e + 40);
  g.line(x, g.y0, x, g.y1, g.ink(0.26 * g.alpha(x, (g.y0 + g.y1) / 2)));
  for (var y = (g.y0 / 100).ceil() * 100.0; y <= g.y1; y += 100) {
    final al = g.alpha(x, y);
    if (al < 0.01) continue;
    final big = modD(y, 500) == 0;
    g.line(x, y, x - (big ? 26 : 10), y, g.ink(0.3 * al));
    if (big) {
      final dec = (60 - (y - g.zs) / _zone * 120).round();
      g.text(
        '${_signed(dec)}°',
        x - 34,
        y + 6,
        16,
        ChannelFont.mono,
        g.ink(0.4 * al),
        align: TextAlign.right,
      );
    }
  }
}
