import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../themes/studio_typography.dart';
import 'channel_geometry.dart';
import 'channel_palette.dart';

/// 装饰里的三种字：像素字（代号、芯片标号）、等宽（坐标、编号）、正文（过渡层主题名）。
enum ChannelFont { pixel, mono, sans }

/// 一段主题的绘制上下文（原型 `g`）：画布已经变换到装饰坐标。
class ChannelPaint {
  ChannelPaint({
    required this.canvas,
    required this.s,
    required this.k,
    required this.zs,
    required this.t,
    required this.motion,
    required this.dark,
    required this.seed,
    required this.camY,
    required this.x0,
    required this.x1,
    required this.y0,
    required this.y1,
    required this.themeIndex,
    required this.palette,
    required this.alpha,
    required this.bgAt,
  });

  final Canvas canvas;

  /// 屏幕像素 / 装饰单位。
  final double s;

  /// 段号、段起点（装饰 y）。
  final int k;
  final double zs;

  /// 动画时间（秒）；[motion] 为 false 时各主题画静止帧。
  final double t;
  final bool motion;
  final bool dark;
  final int seed;

  /// 视口中心的装饰 y（深海的“当前深度”指针）。
  final double camY;
  final double x0, x1, y0, y1;
  final int themeIndex;
  final ChannelPalette palette;

  /// 这一点的装饰透明度（段权重 × 浓淡 × 增益 × 细节 × 横向淡出）。
  final double Function(double x, double y) alpha;
  final Color Function(double y) bgAt;

  double get px => 1 / s;

  Color ink(double a) => palette.inkOf(dark).withValues(alpha: a.clamp(0, 1));
  Color acc(double a) =>
      palette.accentOf(dark).withValues(alpha: a.clamp(0, 1));
  Color bg(double y, double a) => bgAt(y).withValues(alpha: a.clamp(0, 1));

  ChannelRng r(List<Object> keys) =>
      ChannelRng(channelHash([themeIndex, seed, ...keys]));

  // ───────────── 画笔 ─────────────

  final _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.butt
    ..isAntiAlias = true;
  final _fill = Paint()..isAntiAlias = true;

  /// 线宽按屏幕像素给。
  Paint stroke(Color c, [double w = 1]) => _stroke
    ..color = c
    ..strokeWidth = w * px;
  Paint fill(Color c) => _fill
    ..color = c
    ..shader = null;

  void line(
    double ax,
    double ay,
    double bx,
    double by,
    Color c, [
    double w = 1,
  ]) => canvas.drawLine(Offset(ax, ay), Offset(bx, by), stroke(c, w));

  void circle(
    double x,
    double y,
    double r,
    Color c, {
    bool filled = false,
    double w = 1,
  }) => canvas.drawCircle(Offset(x, y), r, filled ? fill(c) : stroke(c, w));

  void rect(Rect r, Color c, {bool filled = false, double w = 1}) =>
      canvas.drawRect(r, filled ? fill(c) : stroke(c, w));

  void path(Path p, Color c, {bool filled = false, double w = 1}) =>
      canvas.drawPath(p, filled ? fill(c) : stroke(c, w));

  /// 虚线：[pattern] 按屏幕像素（同原型 `setLineDash([a*px, b*px])`）。
  void dashed(Path p, Color c, List<double> pattern, [double w = 1]) {
    if (!_inClip(p.getBounds(), w)) return;
    canvas.drawPath(_dashPath(p, pattern), stroke(c, w));
  }

  bool _inClip(Rect bounds, double w) =>
      bounds.inflate((w + 2) * px).overlaps(canvas.getLocalClipBounds());

  Path _dashPath(Path p, List<double> pattern) {
    final dashes = [for (final d in pattern) d * px];
    final out = Path();
    for (final m in p.computeMetrics()) {
      var d = 0.0, i = 0;
      while (d < m.length) {
        final len = dashes[i % dashes.length];
        if (i.isEven) out.addPath(m.extractPath(d, d + len), Offset.zero);
        d += len;
        i++;
      }
    }
    return out;
  }

  // Retain the exact native path produced by computeMetrics/extractPath.
  // Colour/width remain live; geometry depends on coordinates and dash scale.
  static final _dashedPaths = <Object, Path>{};

  Path _retainedDash(Object key, Path Function() path, List<double> pattern) {
    final hit = _dashedPaths.remove(key);
    if (hit != null) return _dashedPaths[key] = hit;
    final value = _dashPath(path(), pattern);
    if (_dashedPaths.length >= 512) {
      _dashedPaths.remove(_dashedPaths.keys.first);
    }
    return _dashedPaths[key] = value;
  }

  void dashedLine(
    double ax,
    double ay,
    double bx,
    double by,
    Color c,
    List<double> pattern, [
    double w = 1,
  ]) {
    if (!_inClip(Rect.fromPoints(Offset(ax, ay), Offset(bx, by)), w)) return;
    canvas.drawPath(
      _retainedDash(
        ('line', ax, ay, bx, by, s, pattern.join(',')),
        () => Path()
          ..moveTo(ax, ay)
          ..lineTo(bx, by),
        pattern,
      ),
      stroke(c, w),
    );
  }

  void dashedCircle(
    double x,
    double y,
    double r,
    Color c,
    List<double> pattern,
  ) {
    final bounds = Rect.fromCircle(center: Offset(x, y), radius: r);
    if (!_inClip(bounds, 1)) return;
    canvas.drawPath(
      _retainedDash(
        ('circle', x, y, r, s, pattern.join(',')),
        () => Path()..addOval(bounds),
        pattern,
      ),
      stroke(c),
    );
  }

  /// 文字：[y] 是基线（同 canvas `fillText`）；屏幕上小于 5.5px 的不画。
  void text(
    String str,
    double x,
    double y,
    double size,
    ChannelFont font,
    Color c, {
    TextAlign align = TextAlign.left,
    FontWeight weight = FontWeight.w400,
  }) {
    final z = size * ChannelText.boost;
    if (z * s < 5.5 || c.a < 0.004) return;
    ChannelText.paint(
      canvas,
      str,
      Offset(x, y),
      z,
      font,
      c,
      align: align,
      weight: weight,
    );
  }
}

/// 文字排版缓存：装饰里的标签反复出现（每帧都画），按 字 + 字号 + 颜色 缓存排好的 [TextPainter]。
abstract final class ChannelText {
  /// 真实画布的装饰缩放比原型小，字整体放大一点，默认聚焦时和原型的屏幕字号接近。
  static const boost = 1.25;

  static final _cache = <String, TextPainter>{};

  static TextStyle style(
    ChannelFont font,
    double size,
    Color c,
    FontWeight w,
  ) => switch (font) {
    ChannelFont.pixel => TextStyle(
      fontFamily: StudioTypography.pixelSquare,
      fontFamilyFallback: const [
        StudioTypography.mono,
        ...StudioTypography.fallback,
      ],
      fontSize: size,
      color: c,
      fontWeight: w,
      height: 1,
    ),
    ChannelFont.mono => TextStyle(
      fontFamily: StudioTypography.mono,
      fontFamilyFallback: StudioTypography.fallback,
      fontSize: size,
      color: c,
      fontWeight: w,
      height: 1,
    ),
    ChannelFont.sans => TextStyle(
      fontFamily: StudioTypography.cjk,
      fontFamilyFallback: StudioTypography.fallback,
      fontSize: size,
      color: c,
      fontWeight: w,
      height: 1,
    ),
  };

  static TextPainter layout(
    String s,
    double size,
    ChannelFont font,
    Color c, [
    FontWeight w = FontWeight.w400,
  ]) {
    final key = '${font.index}|$size|${c.toARGB32()}|${w.value}|$s';
    final hit = _cache.remove(key);
    if (hit != null) return _cache[key] = hit;
    if (_cache.length > 600) {
      for (final k in _cache.keys.take(200).toList()) {
        _cache.remove(k)!.dispose();
      }
    }
    return _cache[key] = TextPainter(
      text: TextSpan(text: s, style: style(font, size, c, w)),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static void paint(
    Canvas canvas,
    String s,
    Offset at,
    double size,
    ChannelFont font,
    Color c, {
    TextAlign align = TextAlign.left,
    FontWeight weight = FontWeight.w400,
  }) {
    final tp = layout(s, size, font, c, weight);
    final base = tp.computeDistanceToActualBaseline(ui.TextBaseline.alphabetic);
    final dx = switch (align) {
      TextAlign.right || TextAlign.end => -tp.width,
      TextAlign.center => -tp.width / 2,
      _ => 0.0,
    };
    tp.paint(canvas, at + Offset(dx, -base));
  }
}
