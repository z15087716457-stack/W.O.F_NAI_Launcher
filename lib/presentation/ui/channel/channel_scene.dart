import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'channel_contract.dart';
import 'channel_geometry.dart';
import 'channel_paint.dart';
import 'channel_palette.dart';
import 'channel_themes_a.dart';
import 'channel_themes_b.dart';
import 'channel_themes_c.dart';

typedef ChannelThemeDraw = void Function(ChannelPaint g);

/// 主题 → 绘制函数。新主题：写一个 `void paintXxx(ChannelPaint g)`，在 [ChannelTheme] 加一项、
/// 在 [ChannelPalette.of] 配色，再登记到这里；设置卡片、刻度条、过渡层、全局地图都会自动带上。
const channelDraws = <ChannelTheme, ChannelThemeDraw>{
  ChannelTheme.circuit: paintCircuit,
  ChannelTheme.stars: paintStars,
  ChannelTheme.herb: paintHerb,
  ChannelTheme.arcade: paintArcade,
  ChannelTheme.abyss: paintAbyss,
  ChannelTheme.wave: paintWave,
};

/// 一帧通道场景的输入（不含图片光台和时间刻度）。
class ChannelSceneSpec {
  const ChannelSceneSpec({
    required this.env,
    required this.camera,
    required this.dark,
    required this.base,
    required this.level,
    required this.seed,
    required this.names,
    this.t = 0,
    this.motion = false,
    this.thumb = false,
    this.pinboard,
  });

  final ChannelEnv env;

  /// 世界相机（同画布引擎）。
  final ChannelCamera camera;
  final bool dark;

  /// 画布原本的底色（无主题处）。
  final Color base;
  final double level;
  final int seed;

  /// 主题名（过渡层、全局地图）。
  final Map<ChannelTheme, String> names;
  final double t;
  final bool motion;

  /// 设置卡片缩略图：不画过渡层和地图，细节不随缩放隐藏。
  final bool thumb;
  final Rect? pinboard;

  double get decorScale => camera.scale * ChannelGeo.decorScale;

  Color tint(double decorY) =>
      ChannelPalette.tint(env, decorY, base, dark, level);
}

/// 画底色 + 各段主题 + 过渡层 + 全局地图。“关闭”时什么都不画（下面是生图页原来的底纹）。
void paintChannelScene(Canvas canvas, Size size, ChannelSceneSpec o) {
  if (o.env.off || size.isEmpty) return;
  const k = ChannelGeo.decorScale;
  final view = o.camera.visibleWorldRect(size);
  final vx0 = view.left / k, vx1 = view.right / k;
  final vy0 = view.top / k, vy1 = view.bottom / k;
  final s = o.decorScale;
  final det = o.thumb ? 1.0 : ChannelGeo.detail(o.camera.scale);

  // 底色：沿视口竖向取 17 个点混出渐变（段与段之间平滑过渡）
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [for (var i = 0; i <= 16; i++) o.tint(lerpD(vy0, vy1, i / 16))],
        [for (var i = 0; i <= 16; i++) i / 16],
      ),
  );

  canvas
    ..save()
    ..clipRect(Offset.zero & size)
    ..translate(o.camera.offset.dx, o.camera.offset.dy)
    ..scale(s);
  final gain = ChannelGeo.gain(o.dark);
  final pin = o.pinboard == null
      ? null
      : Rect.fromLTRB(
          o.pinboard!.left / k,
          o.pinboard!.top / k,
          o.pinboard!.right / k,
          o.pinboard!.bottom / k,
        ).inflate(240);
  if (det > 0) {
    for (var z = ChannelGeo.zoneOf(vy0); z <= ChannelGeo.zoneOf(vy1); z++) {
      final theme = o.env.themeOf(z);
      final zs = ChannelGeo.zoneStart(z);
      if (!o.env.fixed &&
          math.min(vy1, zs + ChannelGeo.zone) - math.max(vy0, zs) < 1) {
        continue;
      }
      final g = ChannelPaint(
        canvas: canvas,
        s: s,
        k: z,
        zs: zs,
        t: o.t,
        motion: o.motion,
        dark: o.dark,
        seed: o.seed,
        camY: (vy0 + vy1) / 2,
        x0: vx0,
        x1: vx1,
        y0: math.max(vy0, zs),
        y1: math.min(vy1, zs + ChannelGeo.zone),
        themeIndex: theme.index,
        palette: ChannelPalette.of(theme),
        alpha: (x, y) =>
            o.env.weight(z, y) *
            o.level *
            gain *
            det *
            ChannelGeo.xfade(x) *
            (pin != null && pin.contains(Offset(x, y)) ? 0.25 : 1),
        bgAt: o.tint,
      );
      canvas
        ..save()
        ..clipRect(
          o.env.fixed
              ? Rect.fromLTRB(vx0 - 10, vy0 - 10, vx1 + 10, vy1 + 10)
              : Rect.fromLTWH(vx0 - 10, zs, vx1 - vx0 + 20, ChannelGeo.zone),
        );
      channelDraws[theme]!(g);
      canvas.restore();
    }
    if (!o.env.fixed && !o.thumb) {
      _paintTransitions(canvas, o, vy0, vy1, s, det);
    }
  }
  if (!o.env.fixed && !o.thumb && det < 1) {
    _paintMap(canvas, o, vy0, vy1, s, det);
  }
  canvas.restore();
}

/// 过渡层中线：两侧虚线，左边写“↑ 上一段 / ↓ 下一段”，右边写代号。
void _paintTransitions(
  Canvas canvas,
  ChannelSceneSpec o,
  double vy0,
  double vy1,
  double s,
  double det,
) {
  const e = ChannelGeo.e;
  final px = 1 / s, al = 0.5 * det;
  // 字至少 13px（主题名），缩小时文字和间距一起按屏幕尺寸保底
  final m = math.max(1.0, 13 / (26 * ChannelText.boost * s));
  void label(
    String str,
    double x,
    double y,
    double size,
    ChannelFont f,
    Color c, [
    TextAlign align = TextAlign.left,
  ]) {
    ChannelText.paint(
      canvas,
      str,
      Offset(x, y),
      size * ChannelText.boost * m,
      f,
      c,
      align: align,
    );
  }

  for (
    var z = ChannelGeo.zoneOf(vy0) + 1;
    z <= ChannelGeo.zoneOf(vy1) + 1;
    z++
  ) {
    final y = ChannelGeo.zoneStart(z);
    if (y < vy0 - 100 || y > vy1 + 100) continue;
    final ta = o.env.themeOf(z - 1), tb = o.env.themeOf(z);
    final a = ChannelPalette.of(ta), b = ChannelPalette.of(tb);
    final dots = Paint()
      ..color = b.inkOf(o.dark).withValues(alpha: 0.22 * al)
      ..strokeWidth = px;
    for (final sd in const [-1.0, 1.0]) {
      for (var x = e + 40; x < ChannelGeo.b2; x += 8 * px) {
        canvas.drawLine(Offset(sd * x, y), Offset(sd * (x + 2 * px), y), dots);
      }
    }
    final ia = a.inkOf(o.dark), ib = b.inkOf(o.dark);
    label(
      '↑ ${o.names[ta]}',
      -(e + 50),
      y - 22 * m,
      26,
      ChannelFont.sans,
      ia.withValues(alpha: 0.6 * al),
      TextAlign.right,
    );
    label(
      '↓ ${o.names[tb]}',
      -(e + 50),
      y + 44 * m,
      26,
      ChannelFont.sans,
      ib.withValues(alpha: 0.85 * al),
      TextAlign.right,
    );
    label(
      a.code,
      e + 50,
      y - 22 * m,
      20,
      ChannelFont.pixel,
      ia.withValues(alpha: 0.5 * al),
    );
    label(
      b.code,
      e + 50,
      y + 40 * m,
      20,
      ChannelFont.pixel,
      ib.withValues(alpha: 0.8 * al),
    );
  }
}

/// 缩到全局：每段左边一根色条 + 主题名（按屏幕尺寸画），整条通道变成一张地图。
void _paintMap(
  Canvas canvas,
  ChannelSceneSpec o,
  double vy0,
  double vy1,
  double s,
  double det,
) {
  final u = 1 / s, al = 1 - det;
  for (var z = ChannelGeo.zoneOf(vy0); z <= ChannelGeo.zoneOf(vy1); z++) {
    final theme = o.env.themeOf(z), p = ChannelPalette.of(theme);
    final zs = ChannelGeo.zoneStart(z), cy = zs + ChannelGeo.zone / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -ChannelGeo.m0 - 34 * u,
          zs + ChannelGeo.transition / 2,
          3 * u,
          ChannelGeo.zone - ChannelGeo.transition,
        ),
        Radius.circular(1.5 * u),
      ),
      Paint()..color = p.swatch.withValues(alpha: 0.75 * al),
    );
    final x = -ChannelGeo.m0 - 48 * u, ink = p.inkOf(o.dark);
    ChannelText.paint(
      canvas,
      o.names[theme] ?? '',
      Offset(x, cy + 5 * u),
      15 * u,
      ChannelFont.sans,
      ink.withValues(alpha: 0.85 * al),
      align: TextAlign.right,
      weight: FontWeight.w500,
    );
    ChannelText.paint(
      canvas,
      p.code,
      Offset(x, cy + 20 * u),
      10 * u,
      ChannelFont.pixel,
      ink.withValues(alpha: 0.55 * al),
      align: TextAlign.right,
    );
  }
}
