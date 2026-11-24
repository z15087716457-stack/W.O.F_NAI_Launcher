import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'channel_ascii_themes.dart';
import 'channel_contract.dart';
import 'channel_geometry.dart';
import 'channel_paint.dart';
import 'channel_palette.dart';

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
    this.welcome = false,
    this.pinboard,
    this.stageCenterX,
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

  /// 设置卡片缩略图：直接以标志性构图渲染完整主题，不画过渡层和地图。
  final bool thumb;

  /// 空画布欢迎态：无需中央审图走廊压暗，完整呈现字符艺术舞台。
  final bool welcome;
  final Rect? pinboard;

  /// 全窗口模式下的主舞台水平中心（通常为中央画布中轴）。
  final double? stageCenterX;

  double get decorScale => camera.scale * ChannelGeo.decorScale;

  Color tint(double decorY) =>
      ChannelPalette.tint(env, decorY, base, dark, level);
}

/// 英雄初始相位（秒）：让静止帧与首帧默认处于最具美感的构图姿态。
const double _heroBaseTime = 3.4;

/// 画底色 + 字符艺术主题 + 过渡层 + 全局地图。“关闭”时什么都不画（下面是生图页原来的底纹）。
void paintChannelScene(Canvas canvas, Size size, ChannelSceneSpec o) {
  if (o.env.off || size.isEmpty) return;

  // 1. 缩略图模式：直接整块绘制该主题的标志性全景
  if (o.thumb) {
    canvas
      ..save()
      ..clipRect(Offset.zero & size);
    paintAsciiTheme(
      o.env.themeOf(0),
      ChannelAsciiFrame(
        canvas: canvas,
        size: size,
        dark: o.dark,
        level: o.level,
        t: _heroBaseTime + o.t,
        scrollX: 0,
        scrollY: 0,
        seed: o.seed,
        zoneAlpha: 1.0,
        corridorCenterX: size.width * 0.5,
        corridorHalfW: 0,
        hasCorridor: false,
        pinboardScreen: null,
        stageCenterX: size.width * 0.5,
        thumb: true,
      ),
    );
    canvas.restore();
    return;
  }

  const k = ChannelGeo.decorScale;
  final view = o.camera.visibleWorldRect(size);
  final vy0 = view.top / k;
  final vy1 = view.bottom / k;
  final s = o.decorScale;
  final det = ChannelGeo.detail(o.camera.scale);

  // 2. 底色渐变（缩放到全局地图或段间过渡时作为平滑衔接底板）
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

  // 3. 屏幕空间字符艺术主题绘制（视差滚动与审图走廊与世界相机实时联动）
  final centerDecorY = (vy0 + vy1) * 0.5;
  // 空画布 welcome 态与最新首图焦点态（世界 y≈608）归零为视差基点，避免初始构图偏上裁切
  final scrollY = o.welcome ? 0.0 : view.center.dy - 608.0;
  final scrollX = o.welcome ? 0.0 : view.center.dx;
  final corridorCenterX = o.camera.worldToScreen(Offset.zero).dx;
  final corridorHalfW = 416.0 * o.camera.scale;
  final stageCenterX = o.stageCenterX ?? size.width * 0.5;
  final pinScreen = o.pinboard == null
      ? null
      : Rect.fromPoints(
          o.camera.worldToScreen(o.pinboard!.topLeft),
          o.camera.worldToScreen(o.pinboard!.bottomRight),
        ).inflate(28.0);

  if (det > 0) {
    canvas
      ..save()
      ..clipRect(Offset.zero & size);

    if (o.env.fixed) {
      paintAsciiTheme(
        o.env.themeOf(0),
        ChannelAsciiFrame(
          canvas: canvas,
          size: size,
          dark: o.dark,
          level: o.level,
          t: _heroBaseTime + o.t,
          scrollX: scrollX,
          scrollY: scrollY,
          seed: o.seed,
          zoneAlpha: det,
          corridorCenterX: corridorCenterX,
          corridorHalfW: corridorHalfW,
          hasCorridor: false,
          pinboardScreen: pinScreen,
          stageCenterX: stageCenterX,
          thumb: false,
        ),
      );
    } else {
      // 随机分段模式：以视口中心所在段为主舞台，按段权重平滑进出过渡层
      final z = ChannelGeo.zoneOf(centerDecorY);
      final w = o.env.weight(z, centerDecorY) * det;
      if (w > 0.01) {
        paintAsciiTheme(
          o.env.themeOf(z),
          ChannelAsciiFrame(
            canvas: canvas,
            size: size,
            dark: o.dark,
            level: o.level,
            t: _heroBaseTime + o.t,
            scrollX: scrollX,
            scrollY: scrollY,
            seed: o.seed ^ (z * 2654435761),
            zoneAlpha: w,
            corridorCenterX: corridorCenterX,
            corridorHalfW: corridorHalfW,
            hasCorridor: false,
            pinboardScreen: pinScreen,
            stageCenterX: stageCenterX,
            thumb: false,
          ),
        );
      }
    }
    canvas.restore();
  }

  // 4. 随机模式下的段过渡分隔线与全局地图（世界坐标锚定）
  if (!o.env.fixed && (det > 0 || det < 1)) {
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(o.camera.offset.dx, o.camera.offset.dy)
      ..scale(s);
    if (det > 0) {
      _paintTransitions(canvas, o, vy0, vy1, s, det);
    }
    if (det < 1) {
      _paintMap(canvas, o, vy0, vy1, s, det);
    }
    canvas.restore();
  }
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
  final px = 1 / s;
  final al = 0.5 * det;
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
    final ta = o.env.themeOf(z - 1);
    final tb = o.env.themeOf(z);
    final a = ChannelPalette.of(ta);
    final b = ChannelPalette.of(tb);
    final dots = Paint()
      ..color = b.inkOf(o.dark).withValues(alpha: 0.22 * al)
      ..strokeWidth = px;
    for (final sd in const [-1.0, 1.0]) {
      for (var x = e + 40; x < ChannelGeo.b2; x += 8 * px) {
        canvas.drawLine(Offset(sd * x, y), Offset(sd * (x + 2 * px), y), dots);
      }
    }
    final ia = a.inkOf(o.dark);
    final ib = b.inkOf(o.dark);
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
  final u = 1 / s;
  final al = 1 - det;
  for (var z = ChannelGeo.zoneOf(vy0); z <= ChannelGeo.zoneOf(vy1); z++) {
    final theme = o.env.themeOf(z);
    final p = ChannelPalette.of(theme);
    final zs = ChannelGeo.zoneStart(z);
    final cy = zs + ChannelGeo.zone / 2;
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
    final x = -ChannelGeo.m0 - 48 * u;
    final ink = p.inkOf(o.dark);
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
