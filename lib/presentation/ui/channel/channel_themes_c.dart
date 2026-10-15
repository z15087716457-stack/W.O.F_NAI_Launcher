import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'channel_geometry.dart';
import 'channel_paint.dart';

// 深海、青海波（原型 THEMES.abyss / THEMES.wave，装饰坐标）。

const _e = ChannelGeo.e;
const _b2 = ChannelGeo.b2;
const _zone = ChannelGeo.zone;
const _sides = [-1.0, 1.0];

void _glow(ChannelPaint g, double x, double y, double r, Color c) =>
    g.canvas.drawCircle(
      Offset(x, y),
      r,
      Paint()
        ..shader = ui.Gradient.radial(Offset(x, y), r, [
          c,
          c.withValues(alpha: 0),
        ]),
    );

void paintAbyss(ChannelPaint g) {
  final k = g.k;
  // 等深线
  for (final side in _sides) {
    for (var i = 0; i < 7; i++) {
      final base = side * ((side < 0 ? _e + 200 : _e + 70) + i * 82),
          ai = 1 - i / 9;
      double xAt(double y) =>
          base +
          side *
              (math.sin(y / 900 + i * 1.3 + k * 2.1) * 36 +
                  math.sin(y / 260 + i * 2.1) * 10);
      for (var cy = (g.y0 / 240).floor() * 240.0; cy < g.y1; cy += 240) {
        final al = g.alpha(base, cy + 120) * ai;
        if (al < 0.01) continue;
        final p = Path()..moveTo(xAt(cy), cy);
        for (var y = cy + 30; y <= cy + 240; y += 30) {
          p.lineTo(xAt(y), y);
        }
        if (i.isOdd) {
          g.dashed(p, g.ink(0.3 * al), const [10, 8]);
        } else {
          g.path(p, g.ink(0.3 * al));
        }
        if (i == 2 && modD(cy, 1680) == 0) {
          final x = xAt(cy);
          g.rect(
            Rect.fromLTWH(x - 22, cy - 12, 44, 22),
            g.bg(cy, 1),
            filled: true,
          );
          g.text(
            '${200 * (1 + modI(k, 4)) + modI((cy / 240).round(), 7) * 20}',
            x,
            cy + 5,
            14,
            ChannelFont.mono,
            g.ink(0.46 * al),
            align: TextAlign.center,
          );
        }
      }
    }
  }
  // 深度尺（左）
  const x = -(_e + 150);
  String depth(double y) => '${((y - g.zs) / 5).round() + modI(k, 5) * 1280} m';
  g.line(x, g.y0, x, g.y1, g.ink(0.3 * g.alpha(x, (g.y0 + g.y1) / 2)));
  for (var y = (g.y0 / 100).ceil() * 100.0; y <= g.y1; y += 100) {
    final al = g.alpha(x, y);
    if (al < 0.01) continue;
    final big = modD(y, 500) == 0;
    g.line(x, y, x - (big ? 28 : 12), y, g.ink(0.32 * al));
    if (big) {
      g.text(
        depth(y),
        x - 38,
        y + 6,
        16,
        ChannelFont.mono,
        g.ink(0.44 * al),
        align: TextAlign.right,
      );
    }
  }
  if (g.camY > g.zs && g.camY < g.zs + _zone) {
    final al = g.alpha(x, g.camY);
    g.path(
      Path()
        ..moveTo(x + 4, g.camY)
        ..lineTo(x + 22, g.camY - 9)
        ..lineTo(x + 22, g.camY + 9)
        ..close(),
      g.acc(0.75 * al),
      filled: true,
    );
    g.text(
      depth(g.camY),
      x + 30,
      g.camY + 6,
      18,
      ChannelFont.mono,
      g.acc(0.85 * al),
    );
  }
  // 海雪
  const cell = 170.0;
  for (var cx = (g.x0 / cell).floor(); cx <= (g.x1 / cell).floor(); cx++) {
    for (
      var cy = (g.y0 / cell).floor() - 1;
      cy <= (g.y1 / cell).floor();
      cy++
    ) {
      final r = g.r(['sn', cx, cy]);
      for (var i = 0; i < 2; i++) {
        final x = cx * cell + r() * cell, sp = 0.5 + r(), y0 = r() * cell;
        final rad = (0.8 + r() * 1.1) * g.px;
        final y = cy * cell + modD(y0 + (g.motion ? g.t * 16 * sp : 0), cell);
        final al = g.alpha(x, y);
        if (al < 0.01) continue;
        g.circle(x, y, rad, g.ink(0.3 * al), filled: true);
      }
    }
  }
  // 气泡
  for (final side in _sides) {
    for (var col = 0; col < 3; col++) {
      final colX = side * ((side < 0 ? _e + 250 : _e + 150) + col * 170);
      for (var j = (g.y0 / 760).floor() - 1; j <= (g.y1 / 760).floor(); j++) {
        final r = g.r(['bb', side, col, j]);
        for (var b = 0; b < 3; b++) {
          final ox = (r() - 0.5) * 80, oy = r() * 760, sp = 0.6 + r() * 0.6;
          final rad = 5 + r() * 12, ph = r() * 6.28;
          final x = colX + ox + (g.motion ? math.sin(g.t * 1.3 + ph) * 6 : 0);
          final y = j * 760 + modD(oy - (g.motion ? g.t * 40 * sp : 0), 760);
          final al = g.alpha(x, y);
          if (al < 0.01) continue;
          final c = g.ink(0.34 * al);
          g.circle(x, y, rad, c);
          g.path(
            Path()..addArc(
              Rect.fromCircle(center: Offset(x, y), radius: rad * 0.62),
              math.pi * 1.1,
              math.pi * 0.45,
            ),
            c,
          );
        }
      }
    }
  }
  // 每段一只水母（缓慢上下漂）
  {
    final r = g.r(['jelly', k]);
    final side = r() < 0.5 ? -1.0 : 1.0;
    final cx = side * (_e + 220), cy0 = g.zs + _zone * (0.3 + 0.4 * r());
    final ph = r() * 6.28;
    final cy = cy0 + (g.motion ? math.sin(g.t * 0.35 + ph) * 24 : 0);
    final al = g.alpha(cx, cy);
    const bw = 120.0, bh = 96.0;
    if (al > 0.01 && cy + 520 > g.y0 && cy - 140 < g.y1) {
      if (g.dark) _glow(g, cx, cy, 240, g.acc(0.16 * al));
      for (var i = 0; i < 7; i++) {
        final x0 = cx - bw * 0.8 + i * bw * 1.6 / 6,
            l = 300 + ((i * 37) % 5) * 40;
        final p = Path();
        for (var s = 0; s <= l; s += 12) {
          final x =
              x0 +
              math.sin(s / 60 + i + (g.motion ? g.t * 0.9 : 0)) *
                  (6 + s * 0.05);
          s == 0 ? p.moveTo(x, cy + s) : p.lineTo(x, cy + s);
        }
        g.path(p, g.ink((i.isOdd ? 0.22 : 0.32) * al));
      }
      final bell = Path()
        ..moveTo(cx - bw, cy)
        ..cubicTo(
          cx - bw,
          cy - bh * 1.35,
          cx + bw,
          cy - bh * 1.35,
          cx + bw,
          cy,
        );
      for (var i = 0; i < 8; i++) {
        final xa = cx + bw - (i + 1) * bw / 4;
        bell.quadraticBezierTo(xa + bw / 8, cy + 16, xa, cy);
      }
      bell.close();
      g.path(bell, g.bg(cy, 0.9), filled: true);
      g.path(bell, g.acc(0.08 * al), filled: true);
      g.path(bell, g.ink(0.5 * al));
      for (final f in const [0.45, 0.75]) {
        g.path(
          Path()
            ..moveTo(cx - bw * f, cy - 4)
            ..cubicTo(
              cx - bw * f,
              cy - bh * 1.3 * f,
              cx + bw * f,
              cy - bh * 1.3 * f,
              cx + bw * f,
              cy - 4,
            ),
          g.ink(0.24 * al),
        );
      }
      for (var i = 0; i < 4; i++) {
        g.circle(cx - 36 + i * 24, cy - 30, 5, g.acc(0.4 * al), filled: true);
      }
    }
  }
  // 深色模式的生物光
  if (!g.dark) return;
  const c2 = 640.0;
  for (var cx = (g.x0 / c2).floor(); cx <= (g.x1 / c2).floor(); cx++) {
    for (var cy = (g.y0 / c2).floor(); cy <= (g.y1 / c2).floor(); cy++) {
      if (((cx + .5) * c2).abs() < _e + 150) continue;
      final r = g.r(['bio', cx, cy]);
      if (r() < 0.72) continue;
      final x = cx * c2 + r() * c2, y = cy * c2 + r() * c2, ph = r() * 6.28;
      final al =
          g.alpha(x, y) * (g.motion ? 0.6 + 0.4 * math.sin(g.t * 0.9 + ph) : 1);
      if (al < 0.01) continue;
      _glow(g, x, y, 46, g.acc(0.32 * al));
      g.circle(x, y, 3, g.acc(0.7 * al), filled: true);
    }
  }
}

void paintWave(ChannelPaint g) {
  const rr = 60.0, dx = 2 * rr, dy = rr * 0.5;
  // 按行合并路径：一行一次底色填充（遮住上一行），描边按透明度分 20 档各一条路径
  for (
    var row = ((g.y0 - rr) / dy).floor();
    row <= ((g.y1 + rr) / dy).floor();
    row++
  ) {
    final y = row * dy, off = row.isOdd ? rr : 0.0;
    final fill = Path(), buckets = <int, Path>{};
    for (
      var col = ((g.x0 - off) / dx).floor() - 1;
      col <= ((g.x1 - off) / dx).floor() + 1;
      col++
    ) {
      final x = col * dx + off, ax = x.abs();
      if (ax < _e + 20 || ax > _b2 + 500) continue;
      final m =
          ((vnoise(x / 900, y / 1100, g.seed) * 1.15 +
                      smooth(_e, _e + 420, ax) * 0.7 -
                      0.72) *
                  3.2)
              .clamp(0.0, 1.0);
      if (m < 0.02) continue;
      final al = g.alpha(x, y) * m;
      if (al < 0.01) continue;
      final sh = g.motion
          ? 1 + 0.45 * math.sin(y * 0.003 - g.t * 1.1 + x * 0.0007)
          : 1.0;
      fill
        ..addArc(
          Rect.fromCircle(center: Offset(x, y), radius: rr),
          math.pi,
          math.pi,
        )
        ..close();
      final q = ((0.3 * al * sh).clamp(0.0, 1.0) * 20).round();
      if (q == 0) continue;
      final p = buckets.putIfAbsent(q, Path.new);
      for (final f in const [1.0, .76, .52, .28]) {
        p.addArc(
          Rect.fromCircle(center: Offset(x, y), radius: rr * f),
          math.pi,
          math.pi,
        );
      }
    }
    g.path(fill, g.bg(y, 1), filled: true);
    for (final MapEntry(key: q, value: p) in buckets.entries) {
      g.path(p, g.ink(q / 20));
    }
  }
  // 霞
  const ch = 900.0;
  for (var j = (g.y0 / ch).floor() - 1; j <= (g.y1 / ch).floor(); j++) {
    for (final side in _sides) {
      final r = g.r(['kasumi', side, j]);
      if (r() < 0.5) continue;
      final w = 200 + r() * 260,
          x = side * (_e + 30 + r() * 220),
          y = j * ch + r() * ch;
      const h = 40.0;
      final al = g.alpha(x, y);
      if (al < 0.01) continue;
      final box = Rect.fromLTWH(side < 0 ? x - w : x, y - h / 2, w, h);
      final band = RRect.fromRectAndRadius(box, const Radius.circular(h / 2));
      g.canvas
        ..drawRRect(band, g.fill(g.bg(y, 1)))
        ..drawRRect(band, g.stroke(g.acc(0.34 * al)))
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              box.left + 10,
              box.top + 9,
              box.right - 10,
              box.bottom - 9,
            ),
            const Radius.circular((h - 18) / 2),
          ),
          g.stroke(g.acc(0.2 * al)),
        );
    }
  }
  // 朱日（每段一轮）
  final r = g.r(['sun', g.k]);
  final side = r() < 0.5 ? -1.0 : 1.0;
  final cx = side * (_e + 250 + r() * 100),
      cy = g.zs + _zone * (0.28 + 0.44 * r());
  final al = g.alpha(cx, cy);
  if (al > 0.01 && cy + 260 > g.y0 && cy - 260 < g.y1) {
    g.circle(cx, cy, 112, g.acc(0.36 * al), filled: true);
    g.circle(cx, cy, 134, g.acc(0.34 * al));
    g.circle(cx, cy, 144, g.acc(0.34 * al));
  }
}
