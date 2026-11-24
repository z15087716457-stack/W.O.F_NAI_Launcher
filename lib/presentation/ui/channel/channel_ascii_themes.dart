import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'channel_ascii_atlas.dart';
import 'channel_contract.dart';
import 'channel_paint.dart';

/// 一帧字符艺术背景的屏幕空间绘制参数（与世界相机解耦，保持 1:1 恒定精细字距与等比构图）。
class ChannelAsciiFrame {
  const ChannelAsciiFrame({
    required this.canvas,
    required this.size,
    required this.dark,
    required this.level,
    required this.t,
    required this.scrollX,
    required this.scrollY,
    required this.seed,
    required this.zoneAlpha,
    required this.corridorCenterX,
    required this.corridorHalfW,
    required this.hasCorridor,
    required this.pinboardScreen,
    required this.stageCenterX,
    required this.thumb,
  });

  final Canvas canvas;
  final Size size;
  final bool dark;
  final double level;

  /// 连续动画时间（秒），已叠加标志性初始英雄相位。
  final double t;

  /// 由世界相机推导的水平/垂直视差滚动量（像素量级）。
  final double scrollX;
  final double scrollY;
  final int seed;

  /// 当前主题段不透明度权重（0..1，用于随机段切换平滑淡入淡出和缩放到全局时隐退）。
  final double zoneAlpha;

  /// 画布中轴（世界 x = 0）在屏幕空间的 x 坐标，以及图列半宽。
  final double corridorCenterX;
  final double corridorHalfW;

  /// 有图态开启中央安静走廊压暗；空画布 welcome 与缩略图关闭压暗。
  final bool hasCorridor;

  /// 钉图板在屏幕空间的矩形（非空时对落入区域压暗）。
  final Rect? pinboardScreen;

  /// 视觉主舞台中心横坐标（全窗口统一背景时对齐中央画布中轴）。
  final double stageCenterX;

  /// 是否是设置面板缩略图。
  final bool thumb;

  /// 计算屏幕坐标 `(px, py)` 处的综合前景留白权重（分段权重与钉图板避让）。
  @pragma('vm:prefer-inline')
  double maskAt(double px, double py) {
    var m = zoneAlpha;
    final pin = pinboardScreen;
    if (pin != null && pin.contains(Offset(px, py))) {
      m *= 0.25;
    }
    return m;
  }
}

/// 分发到对应主题的字符艺术渲染器。
void paintAsciiTheme(ChannelTheme theme, ChannelAsciiFrame f) {
  if (f.size.isEmpty || f.zoneAlpha <= 0.005) return;
  switch (theme) {
    case ChannelTheme.pelagic:
      _paintPelagic(f);
    case ChannelTheme.nimbus:
      _paintCloudField(f, skyVariant: false);
    case ChannelTheme.cumulus:
      _paintCloudField(f, skyVariant: true);
    case ChannelTheme.aurora:
      _paintAurora(f);
    case ChannelTheme.strata:
      _paintStrata(f);
  }
}

// ============================================================================
// 共享快速数学、值噪声与预缓存字符索引
// ============================================================================

const List<int> _bayer4 = [
  0, 8, 2, 10,
  12, 4, 14, 6,
  3, 11, 1, 9,
  15, 7, 13, 5,
];

@pragma('vm:prefer-inline')
double _clamp(double v, double lo, double hi) =>
    v < lo ? lo : (v > hi ? hi : v);

@pragma('vm:prefer-inline')
double _lerp(double a, double b, double t) => a + (b - a) * t;

@pragma('vm:prefer-inline')
double _smoothstep(double a, double b, double x) {
  final u = _clamp((x - a) / (b - a), 0.0, 1.0);
  return u * u * (3.0 - 2.0 * u);
}

@pragma('vm:prefer-inline')
double _wrapCoord(double y, double height, double pad) {
  final span = height + pad * 2.0;
  return (((y + pad) % span) + span) % span - pad;
}

@pragma('vm:prefer-inline')
double _hash2(int x, int y) {
  var h = ((x * 374761393) + (y * 668265263)) & 0xFFFFFFFF;
  h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF;
  h ^= h >> 16;
  return (h & 0xFFFFFFFF) / 4294967296.0;
}

double _vnoise2(double x, double y) {
  final xi = x.floor();
  final yi = y.floor();
  final xf = x - xi;
  final yf = y - yi;
  final u = xf * xf * (3.0 - 2.0 * xf);
  final v = yf * yf * (3.0 - 2.0 * yf);
  return _lerp(
    _lerp(_hash2(xi, yi), _hash2(xi + 1, yi), u),
    _lerp(_hash2(xi, yi + 1), _hash2(xi + 1, yi + 1), u),
    v,
  );
}

@pragma('vm:prefer-inline')
double _fbm2(double x, double y) =>
    0.66 * _vnoise2(x, y) + 0.34 * _vnoise2(x * 2.07 + 13.7, y * 2.07 - 8.3);

double _fbm3(double x, double y) {
  var s = 0.0;
  var a = 0.54;
  s += a * _vnoise2(x, y);
  x = x * 2.04 + 17.1;
  y = y * 2.04 - 9.3;
  a *= 0.5;
  s += a * _vnoise2(x, y);
  x = x * 2.02 - 11.7;
  y = y * 2.02 + 13.4;
  a *= 0.5;
  s += a * _vnoise2(x, y);
  return s;
}

int _gi(String ch) => ChannelGlyphAtlas.indexOf[ch] ?? -1;

// 预解析各主题字形索引，渲染循环零字符串查找
final int _gDot = _gi('·');
final int _gBraille1 = _gi('⠁');
final int _gBraille2 = _gi('⠂');
final int _gBraille3 = _gi('⠃');
final int _gBraille4 = _gi('⠇');
final int _gPlus = _gi('+');
final int _gStar = _gi('*');
final int _gSparkle = _gi('✦');
final int _gSparkleSm = _gi('✧');
final int _gRingSm = _gi('∘');
final int _gShade1 = _gi('░');
final int _gShade2 = _gi('▒');
final int _gShade3 = _gi('▓');
final int _gBoldDash = _gi('━');
final int _gDblDash = _gi('═');
final int _gVert = _gi('│');
final int _gDblVert = _gi('║');
final int _gSlash = _gi('╱');
final int _gBackslash = _gi('╲');
final int _gTilde = _gi('~');
final int _gColon = _gi(':');
final int _gTri = _gi('▲');
final int _gDiamond = _gi('◈');

final List<List<int>> _pelagicTiers = [
  [-1],
  [_gi('⠂'), _gi('·')],
  [_gi('⠃'), _gi('.')],
  [_gi('⠇'), _gi(':')],
  [_gi(':'), _gi('-')],
  [_gi('-'), _gi('~')],
  [_gi(';'), _gi('=')],
  [_gi('+'), _gi('*')],
  [_gi('x'), _gi('o')],
  [_gi('0'), _gi('O')],
  [_gi('X'), _gi('K')],
  [_gi('◈'), _gi('%')],
  [_gi('◉'), _gi('#')],
  [_gi('✦'), _gi('@')],
];

/// 云海精细半色调阶梯：全程采用细腻微点与精密印刷网点，彻底消除粗重方块阶梯感。
final List<int> _nimbusRamp = [
  -1,
  _gi('⠁'),
  _gi('⠂'),
  _gi('·'),
  _gi(':'),
  _gi(';'),
  _gi('+'),
  _gi('*'),
  _gi('░'),
  _gi('░'),
  _gi('▒'),
  _gi('▒'),
  _gi('▓'),
  _gi('▓'),
];

final List<int> _strataBlocks = [
  _gi('·'),
  _gi('▁'),
  _gi('▂'),
  _gi('▃'),
  _gi('▄'),
  _gi('▅'),
  _gi('▆'),
  _gi('▇'),
];

/// 高精细度恒定物理字距：
/// 在 1080p / 2K / 4K 大屏下保持紧致锐利的微缩 ASCII 密度，避免旧版被撑成粗大砖块。
(double cw, double ch, double glyphScale) _fineGrid(
  Size size, {
  required double baseW,
  required double baseH,
  required bool thumb,
  int maxCells = 64000,
}) {
  if (thumb) {
    final cw = (size.width / 28.0).clamp(3.0, 4.4);
    final ch = cw * (baseH / baseW);
    return (cw, ch, cw / 7.2);
  }
  var cw = baseW;
  var ch = baseH;
  final area = size.width * size.height;
  final cellArea = cw * ch;
  if (area / cellArea > maxCells) {
    final boost = math.sqrt((area / cellArea) / maxCells);
    cw *= boost;
    ch *= boost;
  }
  return (cw, ch, (cw / 7.2).clamp(0.64, 1.06));
}

/// 计算局部矩形旋转并平移至 `(cx, cy)` 后的屏幕空间紧凑包围盒。
({double minX, double maxX, double minY, double maxY}) _rotatedBounds(
  double cx,
  double cy,
  double minLx,
  double maxLx,
  double minLy,
  double maxLy,
  double angle,
) {
  final ca = math.cos(angle);
  final sa = math.sin(angle);
  var minX = double.infinity;
  var maxX = double.negativeInfinity;
  var minY = double.infinity;
  var maxY = double.negativeInfinity;

  void include(double lx, double ly) {
    final wx = cx + lx * ca - ly * sa;
    final wy = cy + lx * sa + ly * ca;
    if (wx < minX) minX = wx;
    if (wx > maxX) maxX = wx;
    if (wy < minY) minY = wy;
    if (wy > maxY) maxY = wy;
  }

  include(minLx, minLy);
  include(maxLx, minLy);
  include(minLx, maxLy);
  include(maxLx, maxLy);
  return (minX: minX, maxX: maxX, minY: minY, maxY: maxY);
}

// ============================================================================
// 01 · PELAGIC（深海浮游 — 紧凑包围盒加速 + 全窗口等比精微海洋生物，无丁达尔光束）
// ============================================================================

class _SnowParticle {
  const _SnowParticle(this.x, this.y, this.speed, this.phase, this.glyph);
  final double x;
  final double y;
  final double speed;
  final double phase;
  final int glyph;
}

final List<_SnowParticle> _pelagicSnow = List.generate(96, (i) {
  final glyph = i % 6 == 0
      ? _gSparkleSm
      : (i % 3 == 0 ? _gPlus : _gBraille2);
  return _SnowParticle(
    _hash2(i, 11),
    _hash2(i, 29),
    0.007 + _hash2(i, 47) * 0.015,
    _hash2(i, 73) * math.pi * 2,
    glyph,
  );
});

class _JellySpec {
  const _JellySpec(
    this.x,
    this.y,
    this.rx,
    this.ry,
    this.tilt,
    this.phase,
    this.depth,
  );
  final double x, y, rx, ry, tilt, phase, depth;
}

class _CreatureHit {
  const _CreatureHit(this.lum, this.tone, this.isCore);
  final double lum;
  final double tone;
  final bool isCore;
}

// 深海生物包围盒稀疏累积缓冲（帧号戳记避免 O(W*H) 清空与扫描）
int _pelagicCap = 0;
int _pelagicFrameId = 0;
Uint32List _pelagicStamp = Uint32List(0);
Float32List _pelagicLum = Float32List(0);
Float32List _pelagicTone = Float32List(0);
Uint8List _pelagicFlags = Uint8List(0);
Int32List _pelagicActive = Int32List(0);
int _pelagicActiveCap = 0;

void _ensurePelagicBuffers(int gridCells) {
  if (gridCells > _pelagicCap) {
    _pelagicCap = math.max(gridCells, _pelagicCap == 0 ? 32768 : _pelagicCap * 2);
    _pelagicStamp = Uint32List(_pelagicCap);
    _pelagicLum = Float32List(_pelagicCap);
    _pelagicTone = Float32List(_pelagicCap);
    _pelagicFlags = Uint8List(_pelagicCap);
    _pelagicFrameId = 0;
  }
  if (_pelagicActiveCap < 16384) {
    _pelagicActiveCap = 16384;
    _pelagicActive = Int32List(_pelagicActiveCap);
  }
}

void _growPelagicActive(int needed) {
  final next = math.max(needed, _pelagicActiveCap * 2);
  final grown = Int32List(next)..setRange(0, _pelagicActiveCap, _pelagicActive);
  _pelagicActive = grown;
  _pelagicActiveCap = next;
}

_CreatureHit? _evalJellyfish(
  double px,
  double py,
  _JellySpec j,
  double t,
) {
  final dx = px - j.x;
  final dy = py - j.y;
  final ct = math.cos(-j.tilt);
  final st = math.sin(-j.tilt);
  final lx = dx * ct - dy * st;
  final ly = dx * st + dy * ct;
  if (lx.abs() > j.rx * 1.65 || ly < -j.ry * 1.45 || ly > j.rx * 3.55) {
    return null;
  }

  final pulse = math.sin(t * 1.45 + j.phase);
  final contract = 0.5 + 0.5 * pulse;
  final rx = j.rx * (1.07 - 0.15 * contract);
  final ry = j.ry * (0.93 + 0.14 * contract);

  var lum = 0.0;
  var tone = 0.0;
  var isCore = false;

  if (ly <= ry * 0.44 && ly >= -ry * 1.12) {
    final nx = lx / rx;
    if (nx.abs() < 1.03) {
      final arch = math.sqrt(math.max(0.0, 1.0 - nx * nx * 0.96));
      final yTop = -ry * math.pow(arch, 1.05).toDouble();
      final rimWave =
          math.sin(nx * math.pi * 4.5 + t * 2.1 + j.phase) * ry * 0.072;
      final yBot = ry * (0.06 + 0.10 * nx * nx) + rimWave;
      if (ly >= yTop - 2.5 && ly <= yBot + 2.5) {
        final v = _clamp((ly - yTop) / math.max(1.0, yBot - yTop), 0.0, 1.0);
        final edgeMask =
            _smoothstep(1.03, 0.85, nx.abs()) *
            _smoothstep(yTop - 2.5, yTop + 4.2, ly) *
            _smoothstep(yBot + 2.5, yBot - 3.0, ly);
        final fresnel =
            math.pow(nx.abs(), 1.8).toDouble() * 0.52 +
            math.pow(1.0 - v, 2.2).toDouble() * 0.30;
        final rimBand = math.exp(-math.pow((v - 0.86) / 0.11, 2)) * 0.74;
        final gx = nx / 0.42;
        final gy = (ly + ry * 0.34) / (ry * 0.29);
        final lobe = 1.0 + 0.18 * math.cos(math.atan2(gy, gx) * 4.0 + t * 0.7);
        final gDist = math.sqrt(gx * gx + gy * gy) / lobe;
        final core = math.exp(-gDist * gDist * 1.58) * (0.88 + 0.18 * contract);
        final ribs =
            (0.5 + 0.5 * math.cos(nx * math.pi * 10.0)) * 0.18 * (1.0 - v * 0.32);

        lum = (0.17 + fresnel + rimBand + core + ribs) * edgeMask;
        tone = _clamp(
          core * 1.2 + rimBand * 0.58 - (1.0 - edgeMask) * 0.28,
          -0.45,
          1.0,
        );
        if (core > 0.56) isCore = true;
      }
    }
  }

  if (ly > -ry * 0.06) {
    final s = ly;
    final oralLen = j.rx * 2.30;
    if (s > 0 && s < oralLen) {
      final u = s / oralLen;
      for (var k = -1; k <= 1; k++) {
        final baseOffset = k * rx * 0.19 * (1.0 - u * 0.30);
        final sway =
            math.sin(s * 0.048 - t * 2.2 + j.phase + k * 1.15) *
                (4.2 + u * 16.5) +
            math.sin(s * 0.115 - t * 3.1 + k) * (1.7 + u * 3.0);
        final dist = (lx - (baseOffset + sway)).abs();
        final halfW =
            (5.2 - u * 2.8) * (0.76 + 0.24 * math.sin(s * 0.18 - t * 2.8 + k));
        if (dist < halfW + 2.5) {
          final val =
              math.exp(-math.pow(dist / math.max(1.1, halfW), 2)) *
              (1.0 - u * 0.68) *
              _smoothstep(0.0, 7.0, s) *
              0.94;
          if (val > lum) {
            lum = val;
            tone = 0.36 - u * 0.84;
          }
        }
      }
    }
    const tentCount = 11;
    for (var i = 0; i < tentCount; i++) {
      final frac = (i / (tentCount - 1)) * 2.0 - 1.0;
      final lenFactor = 2.25 + ((i * 29) % 5) * 0.28 - frac.abs() * 0.24;
      final tLen = j.rx * lenFactor;
      if (s <= 0 || s >= tLen) continue;
      final u = s / tLen;
      final attachX = frac * rx * 0.88;
      final wave =
          math.sin(s * 0.036 - t * 1.95 + j.phase + i * 0.85) *
              (2.6 + u * u * 22.0) +
          math.sin(s * 0.080 - t * 2.9 + i * 1.9) * (1.2 + u * 4.5);
      final tx = attachX * (1.0 - 0.14 * u) + wave;
      final dist = (lx - tx).abs();
      final w = 2.55 - u * 1.05;
      if (dist < w + 1.8) {
        final val =
            math.exp(-math.pow(dist / math.max(0.85, w), 2)) *
            math.pow(1.0 - u, 0.96).toDouble() *
            _smoothstep(0.0, 6.0, s) *
            0.80;
        if (val > lum) {
          lum = val;
          tone = -0.04 - u * 0.70;
        }
      }
    }
  }

  if (lum <= 0.035) return null;
  return _CreatureHit(lum * j.depth, tone, isCore);
}

_CreatureHit? _evalMantaRay(
  double px,
  double py,
  double cx,
  double cy,
  double wingSpan,
  double heading,
  double t,
) {
  final dx = px - cx;
  final dy = py - cy;
  final ch = math.cos(-heading);
  final sh = math.sin(-heading);
  final lx = dx * ch - dy * sh;
  final ly = dx * sh + dy * ch;
  if (lx.abs() > wingSpan * 1.18 ||
      ly < -wingSpan * 0.72 ||
      ly > wingSpan * 1.48) {
    return null;
  }

  final ax = lx.abs();
  final u = ax / wingSpan;
  final flapPhase = t * 1.95 - u * 2.35 - (ly / wingSpan) * 1.05;
  final flapZ = math.pow(u, 1.32).toDouble() * math.sin(flapPhase);
  final effSpan = wingSpan * (1.0 - 0.075 * flapZ.abs());
  final nu = ax / effSpan;
  var lum = 0.0;
  var tone = 0.0;

  if (nu <= 1.0) {
    final leadY =
        -wingSpan *
        (0.43 -
            0.56 * math.pow(nu, 1.14).toDouble() -
            0.08 * math.sin(nu * math.pi));
    final trailY =
        wingSpan *
        (0.41 -
            0.30 * math.pow(nu, 0.70).toDouble() -
            0.075 * math.sin(nu * math.pi));
    final flexY = flapZ * wingSpan * 0.08;
    final y0 = leadY + flexY;
    final y1 = trailY + flexY;
    if (ly >= y0 - 2.5 && ly <= y1 + 2.5 && y1 > y0) {
      final v = _clamp((ly - y0) / (y1 - y0), 0.0, 1.0);
      final edgeMask =
          _smoothstep(y0 - 2.5, y0 + 3.5, ly) *
          _smoothstep(y1 + 2.5, y1 - 3.5, ly) *
          _smoothstep(1.0, 0.93, nu);
      final dFlapDu =
          1.32 * math.pow(math.max(0.01, u), 0.32).toDouble() * math.sin(flapPhase) -
          2.35 * math.pow(u, 1.32).toDouble() * math.cos(flapPhase);
      final signedSlope = (lx >= 0 ? 1.0 : -1.0) * dFlapDu;
      final light = _clamp(
        0.68 + signedSlope * 0.29 + (1.0 - v) * 0.26,
        0.30,
        1.38,
      );
      final bodyRidge =
          math.exp(-math.pow(nu / 0.26, 2)) * math.sin(v * math.pi) * 0.58;
      final wingRibs =
          (0.5 + 0.5 * math.cos(v * math.pi * 7.0 + nu * 3.8)) *
          0.17 *
          (1.0 - nu * 0.3);
      final sd1 = (nu - 0.17) / 0.10;
      final sd2 = (v - 0.27) / 0.13;
      final shoulderMark = math.exp(-(sd1 * sd1 + sd2 * sd2) * 2.3) * 0.55;
      final rim =
          math.pow(1.0 - v, 3.6).toDouble() * 0.44 +
          math.pow(nu, 2.5).toDouble() * 0.34;
      lum = (0.38 + bodyRidge + wingRibs + shoulderMark + rim) * light * edgeMask;
      tone = _clamp(
        (light - 0.50) * 1.18 + shoulderMark * 0.94 + bodyRidge * 0.40,
        -0.76,
        1.0,
      );
    }
  }
  if (ly < -wingSpan * 0.30 && ly > -wingSpan * 0.65 && ax < wingSpan * 0.28) {
    final hornU = (-wingSpan * 0.30 - ly) / (wingSpan * 0.35);
    final hornX =
        wingSpan * (0.14 - hornU * 0.032 + math.sin(hornU * math.pi) * 0.022);
    final dist = (ax - hornX).abs();
    final hw = 3.6 * (1.0 - hornU * 0.42);
    if (dist < hw + 2.0) {
      final val =
          math.exp(-math.pow(dist / math.max(1.0, hw), 2)) *
          (1.0 - hornU * 0.28) *
          0.86;
      if (val > lum) {
        lum = val;
        tone = 0.52;
      }
    }
  }
  if (ly > wingSpan * 0.33 && ly < wingSpan * 1.44) {
    final tu = (ly - wingSpan * 0.33) / (wingSpan * 1.11);
    final tailX = math.sin(tu * 5.0 - t * 2.3) * wingSpan * 0.095 * tu * tu;
    final dist = (lx - tailX).abs();
    final tw = 2.8 * (1.0 - tu * 0.72);
    if (dist < tw + 1.8) {
      final val =
          math.exp(-math.pow(dist / math.max(0.75, tw), 2)) *
          (1.0 - tu * 0.74) *
          0.78;
      if (val > lum) {
        lum = val;
        tone = -0.16 - tu * 0.44;
      }
    }
  }
  if (lum <= 0.035) return null;
  return _CreatureHit(lum, tone, false);
}

const List<(int, int, int)> _pelagicDarkPal = [
  (88, 124, 236),
  (60, 162, 244),
  (50, 208, 248),
  (80, 240, 242),
  (158, 246, 252),
  (212, 250, 255),
  (248, 254, 255),
];

const List<(int, int, int)> _pelagicLightPal = [
  (58, 82, 148),
  (26, 76, 142),
  (16, 104, 140),
  (12, 122, 150),
  (12, 132, 142),
  (10, 74, 112),
  (6, 46, 78),
];

void _paintPelagic(ChannelAsciiFrame f) {
  final canvas = f.canvas;
  final w = f.size.width;
  final h = f.size.height;
  final dark = f.dark;
  final t = f.t;
  final za = f.zoneAlpha;
  final anchorX = f.thumb ? w * 0.5 : f.stageCenterX;

  // 1. 深海暗蓝 / 普鲁士蓝晒图底色（无丁达尔光束）
  final bgPaint = Paint()
    ..shader = dark
        ? ui.Gradient.radial(
            Offset(anchorX, h * 0.18),
            math.max(w, h) * 0.88,
            [
              Color.fromRGBO(7, 22, 37, za),
              Color.fromRGBO(4, 10, 20, za),
              Color.fromRGBO(2, 4, 10, za),
            ],
            const [0.0, 0.55, 1.0],
          )
        : ui.Gradient.linear(
            Offset.zero,
            Offset(0, h),
            [
              Color.fromRGBO(244, 248, 253, za),
              Color.fromRGBO(229, 239, 248, za),
            ],
          );
  canvas.drawRect(Offset.zero & f.size, bgPaint);

  // 2. 极细等距工程微米网格 + '+' 准星（缩略图省略过密线条）
  if (!f.thumb) {
    const g = 28.0;
    final gsy = ((-f.scrollY * 0.35) % g + g) % g;
    final gsx = ((-f.scrollX * 0.25) % g + g) % g;
    final gridPaint = Paint()
      ..color = dark
          ? Color.fromRGBO(128, 198, 238, 0.040 * za)
          : Color.fromRGBO(22, 62, 102, 0.048 * za)
      ..strokeWidth = 1.0;
    for (var x = gsx; x < w; x += g) {
      canvas.drawLine(Offset(x + 0.5, 0), Offset(x + 0.5, h), gridPaint);
    }
    for (var y = gsy; y < h; y += g) {
      canvas.drawLine(Offset(0, y + 0.5), Offset(w, y + 0.5), gridPaint);
    }
    final fidPaint = Paint()
      ..color = dark
          ? Color.fromRGBO(148, 216, 248, 0.15 * za)
          : Color.fromRGBO(22, 62, 102, 0.14 * za);
    for (var y = gsy; y < h; y += g * 4) {
      for (var x = gsx + g * 2; x < w; x += g * 4) {
        canvas.drawRect(Rect.fromLTWH(x - 2, y, 5, 1), fidPaint);
        canvas.drawRect(Rect.fromLTWH(x, y - 2, 1, 5), fidPaint);
      }
    }
  }

  final parallax = f.scrollY * 0.22;
  // 等比 Cover 尺度：窄窗自然裁切绝不压扁，大屏优雅舒展
  final u = f.thumb
      ? (w / 220.0)
      : math.max(w / 1460.0, h / 880.0).clamp(0.76, 1.55);

  final jellies = <_JellySpec>[
    // 主角大水母（主画布左翼）
    _JellySpec(
      f.thumb
          ? w * 0.28
          : anchorX - 310.0 * u + math.sin(t * 0.25) * 20.0 * u,
      _wrapCoord(
        h * 0.34 -
            (t - 3.4) * 4.2 * u -
            parallax * 0.72 +
            math.cos(t * 1.45 + 0.3) * 4.2 * u,
        h,
        175.0 * u,
      ),
      f.thumb ? w * 0.19 : 72.0 * u,
      f.thumb ? w * 0.14 : 52.0 * u,
      0.16 + math.sin(t * 0.38) * 0.08,
      0.3,
      1.06,
    ),
    if (!f.thumb)
      // 中上层浮游水母（窄窗居中亦完整优雅可见）
      _JellySpec(
        anchorX - 48.0 * u + math.cos(t * 0.20 + 1.2) * 22.0 * u,
        _wrapCoord(
          h * 0.24 -
              (t - 3.4) * 2.6 * u -
              parallax * 0.42 +
              math.cos(t * 1.45 + 2.4) * 2.8 * u,
          h,
          140.0 * u,
        ),
        46.0 * u,
        33.0 * u,
        -0.14 + math.cos(t * 0.34) * 0.07,
        2.4,
        0.84,
      ),
    if (!f.thumb)
      // 下层深海远景水母
      _JellySpec(
        anchorX + 108.0 * u + math.sin(t * 0.17 + 3.0) * 18.0 * u,
        _wrapCoord(
          h * 0.73 - (t - 3.4) * 2.1 * u - parallax * 0.30,
          h,
          125.0 * u,
        ),
        36.0 * u,
        26.0 * u,
        0.21,
        4.1,
        0.70,
      ),
    if (!f.thumb)
      // 远左玻璃翼漫游水母（全窗口模式下透过左侧透明玻璃柔和游动）
      _JellySpec(
        anchorX - 635.0 * u + math.sin(t * 0.19 + 4.7) * 20.0 * u,
        _wrapCoord(
          h * 0.62 -
              (t - 3.4) * 2.8 * u -
              parallax * 0.50 +
              math.cos(t * 1.45 + 5.1) * 3.0 * u,
          h,
          140.0 * u,
        ),
        48.0 * u,
        35.0 * u,
        -0.12 + math.sin(t * 0.31 + 1.1) * 0.07,
        5.1,
        0.88,
      ),
  ];

  final mantaX = f.thumb
      ? w * 0.74
      : anchorX + 355.0 * u + math.cos(t * 0.22) * 24.0 * u;
  final mantaY = _wrapCoord(
    h * 0.49 + math.sin(t * 0.34) * 19.0 * u - parallax * 0.85,
    h,
    170.0 * u,
  );
  final mantaSpan = f.thumb ? w * 0.28 : 134.0 * u;
  final mantaHeading = -0.58 + math.sin(t * 0.26) * 0.14;

  // 3. 柔和生物荧光底光
  for (final j in jellies) {
    final rad = j.rx * 2.85;
    if (j.x + rad < 0 || j.x - rad > w) continue;
    final m = f.maskAt(j.x, j.y);
    final a = _clamp((dark ? 0.21 : 0.085) * j.depth * f.level * m, 0.0, 0.42);
    if (a <= 0.005) continue;
    final glow = Paint()
      ..blendMode = dark ? BlendMode.plus : BlendMode.srcOver
      ..shader = ui.Gradient.radial(
        Offset(j.x, j.y + j.ry * 0.15),
        rad,
        dark
            ? [
                Color.fromRGBO(74, 236, 250, a),
                Color.fromRGBO(48, 138, 240, a * 0.48),
                const Color.fromRGBO(4, 14, 32, 0),
              ]
            : [
                Color.fromRGBO(12, 118, 148, a),
                Color.fromRGBO(28, 66, 142, a * 0.35),
                const Color.fromRGBO(244, 248, 253, 0),
              ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawCircle(Offset(j.x, j.y + j.ry * 0.15), rad, glow);
  }
  {
    final rad = mantaSpan * 1.55;
    if (mantaX + rad >= 0 && mantaX - rad <= w) {
      final m = f.maskAt(mantaX, mantaY);
      final a = _clamp((dark ? 0.19 : 0.075) * f.level * m, 0.0, 0.38);
      if (a > 0.005) {
        final glow = Paint()
          ..blendMode = dark ? BlendMode.plus : BlendMode.srcOver
          ..shader = ui.Gradient.radial(
            Offset(mantaX, mantaY),
            rad,
            dark
                ? [
                    Color.fromRGBO(96, 212, 255, a),
                    Color.fromRGBO(74, 114, 242, a * 0.46),
                    const Color.fromRGBO(4, 12, 32, 0),
                  ]
                : [
                    Color.fromRGBO(24, 76, 142, a),
                    const Color.fromRGBO(244, 248, 253, 0),
                  ],
            dark ? const [0.0, 0.48, 1.0] : const [0.0, 1.0],
          );
        canvas.drawCircle(Offset(mantaX, mantaY), rad, glow);
      }
    }
  }

  // 4. 紧凑包围盒稀疏采样（零空白深海循环开销），大屏始终保持超精细 5.2×7.2 字距
  final (cw, ch, glyphScale) = _fineGrid(
    f.size,
    baseW: 5.2,
    baseH: 7.2,
    thumb: f.thumb,
    maxCells: 96000,
  );
  final cols = math.max(1, (w / cw).floor());
  final rows = math.max(1, (h / ch).floor());
  final ox = ((w - cols * cw) * 0.5).floorToDouble();
  final oy = ((h - rows * ch) * 0.5).floorToDouble();
  final tickStep = (t * 4.5).floor();
  final pal = dark ? _pelagicDarkPal : _pelagicLightPal;

  _ensurePelagicBuffers(cols * rows);
  _pelagicFrameId++;
  if (_pelagicFrameId >= 0x7FFFFFF0) {
    _pelagicStamp.fillRange(0, _pelagicCap, 0);
    _pelagicFrameId = 1;
  }
  final frameId = _pelagicFrameId;
  var activeCount = 0;

  void stampCell(int idx, double lum, double tone, bool isCore) {
    if (_pelagicStamp[idx] != frameId) {
      _pelagicStamp[idx] = frameId;
      _pelagicLum[idx] = lum;
      _pelagicTone[idx] = tone;
      _pelagicFlags[idx] = isCore ? 1 : 0;
      if (activeCount >= _pelagicActiveCap) {
        _growPelagicActive(activeCount + 4096);
      }
      _pelagicActive[activeCount++] = idx;
    } else if (lum > _pelagicLum[idx]) {
      _pelagicLum[idx] = lum;
      _pelagicTone[idx] = tone;
      _pelagicFlags[idx] = isCore ? 1 : 0;
    }
  }

  for (var ji = 0; ji < jellies.length; ji++) {
    final j = jellies[ji];
    final box = _rotatedBounds(
      j.x,
      j.y,
      -j.rx * 1.68,
      j.rx * 1.68,
      -j.ry * 1.48,
      j.rx * 3.58,
      j.tilt,
    );
    final c0 = ((box.minX - ox) / cw).floor().clamp(0, cols - 1);
    final c1 = ((box.maxX - ox) / cw).ceil().clamp(0, cols - 1);
    final r0 = ((box.minY - oy) / ch).floor().clamp(0, rows - 1);
    final r1 = ((box.maxY - oy) / ch).ceil().clamp(0, rows - 1);
    if (box.maxX < 0 || box.minX > w || box.maxY < 0 || box.minY > h) continue;
    for (var r = r0; r <= r1; r++) {
      final py = oy + r * ch + ch * 0.5;
      final rowOff = r * cols;
      for (var c = c0; c <= c1; c++) {
        final px = ox + c * cw + cw * 0.5;
        final hit = _evalJellyfish(px, py, j, t);
        if (hit != null) {
          stampCell(rowOff + c, hit.lum, hit.tone, hit.isCore);
        }
      }
    }
  }

  {
    final box = _rotatedBounds(
      mantaX,
      mantaY,
      -mantaSpan * 1.20,
      mantaSpan * 1.20,
      -mantaSpan * 0.74,
      mantaSpan * 1.50,
      mantaHeading,
    );
    if (box.maxX >= 0 && box.minX <= w && box.maxY >= 0 && box.minY <= h) {
      final c0 = ((box.minX - ox) / cw).floor().clamp(0, cols - 1);
      final c1 = ((box.maxX - ox) / cw).ceil().clamp(0, cols - 1);
      final r0 = ((box.minY - oy) / ch).floor().clamp(0, rows - 1);
      final r1 = ((box.maxY - oy) / ch).ceil().clamp(0, rows - 1);
      for (var r = r0; r <= r1; r++) {
        final py = oy + r * ch + ch * 0.5;
        final rowOff = r * cols;
        for (var c = c0; c <= c1; c++) {
          final px = ox + c * cw + cw * 0.5;
          final hit = _evalMantaRay(
            px,
            py,
            mantaX,
            mantaY,
            mantaSpan,
            mantaHeading,
            t,
          );
          if (hit != null) {
            stampCell(rowOff + c, hit.lum, hit.tone * 0.85 - 0.08, false);
          }
        }
      }
    }
  }

  final batch = ChannelGlyphBatch.shared..begin(activeCount + 128);

  for (var i = 0; i < activeCount; i++) {
    final idx = _pelagicActive[i];
    final bestLum = _pelagicLum[idx];
    if (bestLum <= 0.036) continue;
    final r = idx ~/ cols;
    final c = idx - r * cols;
    final px = ox + c * cw + cw * 0.5;
    final py = oy + r * ch + ch * 0.5;

    final mask = f.maskAt(px, py);
    final effLum = _clamp(bestLum * f.level * mask, 0.0, 1.28);
    if (effLum <= 0.036) continue;

    final bestTone = _pelagicTone[idx];
    final coreHit = _pelagicFlags[idx] != 0;
    final shimmer = (_hash2(c + tickStep, r) - 0.5) * 0.07;
    final tierIdx = _clamp(
      ((effLum * 0.88 + shimmer) * (_pelagicTiers.length - 1)),
      1.0,
      (_pelagicTiers.length - 1).toDouble(),
    ).floor();
    final tier = _pelagicTiers[tierIdx];
    var gIdx = tier.length > 1
        ? tier[(_hash2(c + (tickStep >> 1), r * 3) * tier.length).floor()]
        : tier[0];
    if (coreHit && effLum > 0.90 && ((c + r + tickStep) % 4 == 0)) {
      gIdx = _gSparkle;
    }

    final toneBin = ((bestTone + 1.0) * 3.0).round().clamp(0, 6);
    final (cr, cg, cb) = pal[toneBin];
    final alpha = _clamp(
      (0.22 + effLum * 0.72) * (dark ? 1.0 : 0.94),
      0.14,
      0.99,
    );
    batch.add(gIdx, px, py, glyphScale, cr, cg, cb, (alpha * 255).round());
  }

  // 漂浮海洋雪微尘（全窗口等比舒展漂移）
  final snowBaseA = _clamp((dark ? 0.34 : 0.28) * f.level, 0.12, 0.66);
  final snowCount = f.thumb ? 22 : _pelagicSnow.length;
  for (var i = 0; i < snowCount; i++) {
    final s = _pelagicSnow[i];
    final sx = s.x * w + math.sin(t * 0.38 + s.phase) * 14.0 * u;
    final sy = _wrapCoord(
      s.y * h + t * s.speed * h - f.scrollY * 0.14,
      h,
      10.0,
    );
    final tw = 0.5 + 0.5 * math.sin(t * 1.5 + s.phase);
    final mask = f.maskAt(sx, sy);
    if (tw * mask < 0.24) continue;
    final a = (snowBaseA * tw * mask * 255).round();
    batch.add(
      s.glyph,
      sx,
      sy,
      glyphScale,
      dark ? 156 : 22,
      dark ? 228 : 74,
      dark ? 252 : 118,
      a,
    );
  }

  batch.flush(canvas);

  // 左侧动态深度标尺刻线
  if (!f.thumb) {
    final tickPaint = Paint()
      ..color = dark
          ? Color.fromRGBO(130, 204, 242, 0.26 * za)
          : Color.fromRGBO(24, 65, 105, 0.26 * za);
    const ts = 48.0;
    final to = ((-f.scrollY * 0.45) % ts + ts) % ts;
    for (var y = 38.0 + to; y < h - 26.0; y += ts) {
      canvas.drawRect(
        Rect.fromLTWH(10.0, y.roundToDouble(), 6.0, 1.0),
        tickPaint,
      );
    }
  }
}

// ============================================================================
// 02 · NIMBUS（暮光云海） & 03 · CUMULUS（晴空云海 · 蓝天版本）
// 采用等比 Cover 天空坐标（窄窗绝不压扁）+ 粗场光追双线性超采样（大屏超精细且丝滑）
// ============================================================================

class _SkyStar {
  const _SkyStar(this.x, this.y, this.ph, this.glyph);
  final double x, y, ph;
  final int glyph;
}

final List<_SkyStar> _nimbusStars = List.generate(72, (i) {
  final glyph = i % 6 == 0
      ? _gSparkle
      : (i % 3 == 0 ? _gSparkleSm : _gDot);
  return _SkyStar(
    _hash2(i, 201),
    _hash2(i, 202) * 0.54,
    _hash2(i, 203) * 6.28,
    glyph,
  );
});

class _CloudPuff {
  const _CloudPuff(this.cx, this.cy, this.rx, this.ry, this.h);
  final double cx, cy, rx, ry, h;
}

/// 暮光云海积云塔群：覆及左右宽翼（-0.06..1.06）与中低云谷，窄窗/超宽屏皆饱满且居中自然留出呼吸带。
const List<_CloudPuff> _duskPuffs = [
  _CloudPuff(-0.04, 0.62, 0.16, 0.36, 1.06),
  _CloudPuff(0.11, 0.60, 0.17, 0.40, 1.12),
  _CloudPuff(0.24, 0.52, 0.14, 0.33, 1.06),
  _CloudPuff(0.35, 0.76, 0.16, 0.27, 0.94),
  _CloudPuff(0.47, 0.76, 0.14, 0.21, 0.86),
  _CloudPuff(0.56, 0.87, 0.22, 0.20, 0.86),
  _CloudPuff(0.68, 0.67, 0.17, 0.35, 1.08),
  _CloudPuff(0.80, 0.42, 0.15, 0.36, 1.14),
  _CloudPuff(0.92, 0.56, 0.19, 0.42, 1.16),
  _CloudPuff(1.04, 0.66, 0.16, 0.34, 1.02),
  _CloudPuff(0.84, 0.24, 0.10, 0.20, 0.86),
];

/// 晴空蓝天版夏日积云塔群：双翼宏阔蓬松，中央呈舒展云谷，不闷挡中央文字。
const List<_CloudPuff> _skyPuffs = [
  _CloudPuff(-0.03, 0.56, 0.15, 0.34, 1.06),
  _CloudPuff(0.11, 0.48, 0.16, 0.36, 1.14),
  _CloudPuff(0.22, 0.34, 0.11, 0.24, 0.92),
  _CloudPuff(0.29, 0.71, 0.18, 0.30, 1.04),
  _CloudPuff(0.45, 0.73, 0.14, 0.21, 0.88),
  _CloudPuff(0.53, 0.84, 0.22, 0.20, 0.88),
  _CloudPuff(0.67, 0.74, 0.17, 0.32, 1.04),
  _CloudPuff(0.81, 0.50, 0.17, 0.38, 1.16),
  _CloudPuff(0.93, 0.38, 0.14, 0.32, 1.08),
  _CloudPuff(1.05, 0.54, 0.16, 0.34, 1.02),
  _CloudPuff(0.75, 0.34, 0.10, 0.21, 0.88),
];

// 云海半分辨率标量场复用缓冲（零逐帧分配）
int _cloudBufCap = 0;
Float32List _cloudBufD = Float32List(0);
Float32List _cloudBufLit = Float32List(0);
Float32List _cloudBufRim = Float32List(0);

void _ensureCloudBuffers(int needed) {
  if (needed <= _cloudBufCap) return;
  _cloudBufCap = math.max(needed, _cloudBufCap == 0 ? 8192 : _cloudBufCap * 2);
  _cloudBufD = Float32List(_cloudBufCap);
  _cloudBufLit = Float32List(_cloudBufCap);
  _cloudBufRim = Float32List(_cloudBufCap);
}

double _sampleCloudDensity(
  double nx,
  double ny,
  double t,
  double driftX,
  List<_CloudPuff> puffs,
  bool skyVariant,
) {
  final seedShift = skyVariant ? 7.4 : 0.0;
  final wx =
      (_fbm3(nx * 2.9 - driftX * 0.85 + seedShift, ny * 2.5 + 3.1) - 0.5) * 0.24;
  final wy =
      (_fbm3(nx * 2.7 - driftX * 0.65 + 5.2 + seedShift, ny * 2.9 - 1.7) - 0.5) *
      0.16;
  final x = nx + wx;
  final y = ny + wy;

  var baseShape = 0.0;
  for (var i = 0; i < puffs.length; i++) {
    final p = puffs[i];
    final pcx = p.cx + math.sin(t * 0.09 + i * 1.3) * 0.024;
    final dx = (x - pcx) / p.rx;
    final dy = (y - p.cy) / p.ry;
    final d2 = dx * dx + (dy > 0 ? dy * dy * 2.1 : dy * dy);
    if (d2 < 1.32) {
      final val = math.max(0.0, 1.0 - d2 * 0.76) * p.h;
      if (val > baseShape) baseShape = val;
    }
  }

  final cirrus =
      math.exp(-math.pow((ny - 0.18 - nx * 0.08) / 0.09, 2)) *
      _smoothstep(
        0.56,
        0.82,
        _fbm3(nx * 5.2 - driftX * 1.8 + seedShift, ny * 9.5 + 8.4),
      ) *
      0.30;

  final detail = _fbm3(x * 5.6 - driftX * 1.25 + seedShift, y * 4.8 + 1.4);
  final fine = _vnoise2(x * 12.0 - driftX * 2.0 + seedShift, y * 10.0 - 2.3);
  final dens = math.max(
    baseShape * (0.46 + detail * 0.80 + fine * 0.24) - 0.28,
    cirrus,
  );
  return _clamp(dens, 0.0, 1.18);
}

void _paintCloudField(ChannelAsciiFrame f, {required bool skyVariant}) {
  final canvas = f.canvas;
  final w = f.size.width;
  final h = f.size.height;
  final dark = f.dark;
  final t = f.t;
  final za = f.zoneAlpha;
  final driftX = t * 0.036 + f.scrollY * 0.00028 + f.scrollX * 0.00035;
  final puffs = skyVariant ? _skyPuffs : _duskPuffs;

  final sunNx = (skyVariant ? 0.32 : 0.68) + math.sin(t * 0.14) * 0.05;
  const sunNy = 0.22;

  // 等比 Cover 投影：确保 1.58:1 基准天穹在窄竖窗与超宽屏上都完全等比不压扁
  const aspectRef = 1.58;
  final anchorX = f.thumb ? w * 0.5 : f.stageCenterX;
  final spanW = f.thumb ? w : math.max(w, h * aspectRef);
  final spanH = f.thumb ? h : spanW / aspectRef;
  final invSpanW = 1.0 / math.max(1.0, spanW);
  final invSpanH = 1.0 / math.max(1.0, spanH);
  final centerY = h * 0.5;

  // 1. 天穹大气渐变
  final List<Color> skyColors;
  if (skyVariant) {
    skyColors = dark
        ? [
            Color.fromRGBO(11, 34, 96, za),
            Color.fromRGBO(24, 68, 168, za),
            Color.fromRGBO(48, 108, 210, za),
            Color.fromRGBO(92, 152, 232, za),
          ]
        : [
            Color.fromRGBO(24, 71, 200, za),
            Color.fromRGBO(52, 118, 234, za),
            Color.fromRGBO(121, 176, 250, za),
            Color.fromRGBO(202, 226, 253, za),
          ];
  } else {
    skyColors = dark
        ? [
            Color.fromRGBO(7, 10, 24, za),
            Color.fromRGBO(20, 23, 53, za),
            Color.fromRGBO(46, 29, 64, za),
            Color.fromRGBO(68, 38, 63, za),
          ]
        : [
            Color.fromRGBO(216, 212, 234, za),
            Color.fromRGBO(234, 218, 232, za),
            Color.fromRGBO(248, 228, 224, za),
            Color.fromRGBO(253, 242, 230, za),
          ];
  }
  canvas.drawRect(
    Offset.zero & f.size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, h),
        skyColors,
        const [0.0, 0.46, 0.80, 1.0],
      ),
  );

  // 2. 太阳 / 暮光大气辉光盘（与等比云海光照方向严格同轴）
  final sx = anchorX + (sunNx - 0.5) * spanW;
  final sy = centerY + (sunNy - 0.5) * spanH;
  final sunRad = math.max(spanW, spanH) * 0.44;
  final sunPaint = Paint()
    ..blendMode = (dark && !skyVariant) ? BlendMode.plus : BlendMode.srcOver
    ..shader = ui.Gradient.radial(
      Offset(sx, sy),
      sunRad,
      skyVariant
          ? [
              Color.fromRGBO(
                255,
                251,
                235,
                _clamp((dark ? 0.36 : 0.48) * f.level * za, 0.14, 0.64),
              ),
              Color.fromRGBO(
                255,
                238,
                200,
                _clamp((dark ? 0.14 : 0.20) * f.level * za, 0.06, 0.28),
              ),
              const Color.fromRGBO(255, 255, 255, 0),
            ]
          : (dark
                ? [
                    Color.fromRGBO(
                      255,
                      228,
                      174,
                      _clamp(0.34 * f.level * za, 0.14, 0.48),
                    ),
                    Color.fromRGBO(
                      244,
                      132,
                      170,
                      _clamp(0.18 * f.level * za, 0.08, 0.30),
                    ),
                    Color.fromRGBO(
                      98,
                      72,
                      186,
                      _clamp(0.09 * f.level * za, 0.04, 0.16),
                    ),
                    const Color.fromRGBO(0, 0, 0, 0),
                  ]
                : [
                    Color.fromRGBO(
                      255,
                      232,
                      196,
                      _clamp(0.45 * f.level * za, 0.18, 0.62),
                    ),
                    Color.fromRGBO(
                      244,
                      170,
                      184,
                      _clamp(0.18 * f.level * za, 0.08, 0.26),
                    ),
                    const Color.fromRGBO(255, 255, 255, 0),
                  ]),
      (!skyVariant && dark)
          ? const [0.0, 0.28, 0.65, 1.0]
          : const [0.0, 0.45, 1.0],
    );
  canvas.drawRect(Offset.zero & f.size, sunPaint);

  // 3. 高密度精细网格 + 粗场光追双线性超采样
  final (cw, ch, glyphScale) = _fineGrid(
    f.size,
    baseW: 5.6,
    baseH: 7.8,
    thumb: f.thumb,
    maxCells: 54000,
  );
  final cols = math.max(1, (w / cw).floor());
  final rows = math.max(1, (h / ch).floor());
  final ox = ((w - cols * cw) * 0.5).floorToDouble();
  final oy = ((h - rows * ch) * 0.5).floorToDouble();
  final tickSky = (t * 1.4).floor();

  final totalFine = cols * rows;
  final stride = f.thumb ? 1 : 2;
  final cCols = (cols - 1) ~/ stride + 2;
  final cRows = (rows - 1) ~/ stride + 2;
  _ensureCloudBuffers(cCols * cRows);

  const aspectInv = 1.0 / aspectRef;
  for (var cr = 0; cr < cRows; cr++) {
    final fr = cr * stride;
    final py = oy + fr * ch + ch * 0.5;
    final ny = 0.5 + (py - centerY) * invSpanH;
    final rowOff = cr * cCols;
    for (var cc = 0; cc < cCols; cc++) {
      final fc = cc * stride;
      final px = ox + fc * cw + cw * 0.5;
      final nx = 0.5 + (px - anchorX) * invSpanW;
      final d = _sampleCloudDensity(nx, ny, t, driftX, puffs, skyVariant);
      final idx = rowOff + cc;
      _cloudBufD[idx] = d;
      if (d <= 0.015) {
        _cloudBufLit[idx] = 0.5;
        _cloudBufRim[idx] = 0.0;
        continue;
      }

      var ldx = sunNx - nx;
      var ldy = (sunNy - ny) * aspectInv;
      final lLen = math.sqrt(ldx * ldx + ldy * ldy);
      if (lLen > 1e-5) {
        ldx /= lLen;
        ldy /= lLen;
      }

      final dStep1 = _sampleCloudDensity(
        nx + ldx * 0.032,
        ny + ldy * 0.046,
        t,
        driftX,
        puffs,
        skyVariant,
      );
      final dStep2 = _sampleCloudDensity(
        nx + ldx * 0.072,
        ny + ldy * 0.102,
        t,
        driftX,
        puffs,
        skyVariant,
      );
      final shadowOcc = _clamp(dStep1 * 0.68 + dStep2 * 0.52, 0.0, 1.38);
      final directLight = math.exp(-shadowOcc * 2.05);
      final sdx = (nx - sunNx) * 1.25;
      final sdy = (ny - sunNy) * 1.65;
      final sunProx = math.exp(-math.sqrt(sdx * sdx + sdy * sdy) * 2.0);
      final silverLining =
          _smoothstep(0.05, 0.30, d) *
          (1.0 - _smoothstep(0.30, 0.68, d)) *
          (0.45 + sunProx) *
          (0.38 + directLight * 0.85);
      final topLift = (1.0 - ny) * 0.36;
      final lit = _clamp(
        directLight * 0.80 + silverLining * 0.72 + topLift - d * 0.22,
        0.0,
        1.25,
      );
      _cloudBufLit[idx] = lit;
      _cloudBufRim[idx] = silverLining;
    }
  }

  final batch = ChannelGlyphBatch.shared..begin((totalFine * 0.65).ceil() + 96);

  // 暮光深色夜空点缀稀疏星辉
  if (!skyVariant && dark) {
    final starCount = f.thumb ? 16 : _nimbusStars.length;
    final baseStarA = _clamp(0.58 * f.level, 0.25, 0.88);
    for (var i = 0; i < starCount; i++) {
      final s = _nimbusStars[i];
      final tw = 0.45 + 0.55 * math.sin(t * 1.8 + s.ph);
      if (tw < 0.42) continue;
      final px = s.x * w;
      final py = s.y * h;
      final mask = f.maskAt(px, py);
      batch.add(
        s.glyph,
        px,
        py,
        glyphScale,
        255,
        242,
        214,
        (baseStarA * tw * mask * 255).round(),
      );
    }
  }

  final invStride = 1.0 / stride;
  final rampMax = _nimbusRamp.length - 1;

  for (var r = 0; r < rows; r++) {
    final py = oy + r * ch + ch * 0.5;
    final gy = r ~/ stride;
    final ty = (r - gy * stride) * invStride;
    final omtY = 1.0 - ty;
    final r0Off = gy * cCols;
    final r1Off = (gy + 1) * cCols;
    final bayerRow = (r & 3) * 4;

    for (var c = 0; c < cols; c++) {
      final px = ox + c * cw + cw * 0.5;
      double d, lit, silverLining;
      if (stride == 1) {
        final idx = r0Off + c;
        d = _cloudBufD[idx];
        lit = _cloudBufLit[idx];
        silverLining = _cloudBufRim[idx];
      } else {
        final gx = c ~/ stride;
        final tx = (c - gx * stride) * invStride;
        final omtX = 1.0 - tx;
        final w00 = omtX * omtY;
        final w10 = tx * omtY;
        final w01 = omtX * ty;
        final w11 = tx * ty;
        final i00 = r0Off + gx;
        final i10 = i00 + 1;
        final i01 = r1Off + gx;
        final i11 = i01 + 1;
        d =
            _cloudBufD[i00] * w00 +
            _cloudBufD[i10] * w10 +
            _cloudBufD[i01] * w01 +
            _cloudBufD[i11] * w11;
        if (d <= 0.025) {
          final mask = f.maskAt(px, py);
          if (!f.thumb &&
              (r + c) % 5 == 0 &&
              _hash2(c, r + tickSky) > 0.90 &&
              mask > 0.15) {
            final gSky = (c + r).isEven ? _gDot : _gBraille1;
            if (skyVariant) {
              batch.add(
                gSky,
                px,
                py,
                glyphScale,
                255,
                255,
                255,
                ((dark ? 0.16 : 0.22) * mask * 255).round(),
              );
            } else {
              batch.add(
                gSky,
                px,
                py,
                glyphScale,
                dark ? 175 : 138,
                dark ? 195 : 112,
                dark ? 245 : 156,
                (0.15 * mask * 255).round(),
              );
            }
          }
          continue;
        }
        lit =
            _cloudBufLit[i00] * w00 +
            _cloudBufLit[i10] * w10 +
            _cloudBufLit[i01] * w01 +
            _cloudBufLit[i11] * w11;
        silverLining =
            _cloudBufRim[i00] * w00 +
            _cloudBufRim[i10] * w10 +
            _cloudBufRim[i01] * w01 +
            _cloudBufRim[i11] * w11;
      }

      if (d <= 0.028) continue;
      final mask = f.maskAt(px, py);
      final nxFine = 0.5 + (px - anchorX) * invSpanW;
      final nyFine = 0.5 + (py - centerY) * invSpanH;
      final fineWisp =
          (_vnoise2(nxFine * 24.0 - driftX * 2.8, nyFine * 22.0 + 4.1) - 0.5) *
          0.16;
      final visualDensity = _clamp(
        (d * 0.90 + silverLining * 0.28 + fineWisp * d) * f.level * mask,
        0.0,
        1.14,
      );
      if (visualDensity <= 0.042) continue;

      final bayer = (_bayer4[bayerRow + (c & 3)] / 16.0 - 0.5) * 0.13;
      final microGrain = (_hash2(c * 3, r * 5) - 0.5) * 0.04;

      int gIdx;
      if (silverLining > 0.42 && lit > 0.84 && ((c * 5 + r * 3) % 7 == 0)) {
        gIdx = _gSparkleSm;
      } else {
        final shaped = math
            .pow(_clamp(visualDensity + bayer + microGrain, 0.0, 1.0), 0.98)
            .toDouble();
        final idx = (shaped * rampMax).floor().clamp(1, rampMax);
        gIdx = _nimbusRamp[idx];
      }

      double cr, cg, cb;
      final tCol = _clamp(lit, 0.0, 1.0);
      if (skyVariant) {
        if (dark) {
          if (tCol < 0.38) {
            final u = tCol / 0.38;
            cr = _lerp(66, 146, u);
            cg = _lerp(106, 186, u);
            cb = _lerp(178, 232, u);
          } else if (tCol < 0.72) {
            final u = (tCol - 0.38) / 0.34;
            cr = _lerp(146, 234, u);
            cg = _lerp(186, 244, u);
            cb = _lerp(232, 255, u);
          } else {
            final u = (tCol - 0.72) / 0.28;
            cr = _lerp(234, 255, u);
            cg = _lerp(244, 252, u);
            cb = _lerp(255, 242, u);
          }
        } else {
          if (tCol < 0.38) {
            final u = tCol / 0.38;
            cr = _lerp(98, 168, u);
            cg = _lerp(132, 196, u);
            cb = _lerp(194, 236, u);
          } else if (tCol < 0.72) {
            final u = (tCol - 0.38) / 0.34;
            cr = _lerp(168, 242, u);
            cg = _lerp(196, 247, u);
            cb = _lerp(236, 255, u);
          } else {
            final u = (tCol - 0.72) / 0.28;
            cr = _lerp(242, 255, u);
            cg = _lerp(247, 254, u);
            cb = _lerp(255, 246, u);
          }
        }
      } else if (dark) {
        if (tCol < 0.36) {
          final u = tCol / 0.36;
          cr = _lerp(40, 108, u);
          cg = _lerp(44, 72, u);
          cb = _lerp(102, 162, u);
        } else if (tCol < 0.70) {
          final u = (tCol - 0.36) / 0.34;
          cr = _lerp(108, 244, u);
          cg = _lerp(72, 138, u);
          cb = _lerp(162, 174, u);
        } else {
          final u = (tCol - 0.70) / 0.30;
          cr = _lerp(244, 255, u);
          cg = _lerp(138, 242, u);
          cb = _lerp(174, 212, u);
        }
      } else {
        if (tCol < 0.38) {
          final u = tCol / 0.38;
          cr = _lerp(116, 168, u);
          cg = _lerp(96, 114, u);
          cb = _lerp(154, 158, u);
        } else if (tCol < 0.72) {
          final u = (tCol - 0.38) / 0.34;
          cr = _lerp(168, 224, u);
          cg = _lerp(114, 146, u);
          cb = _lerp(158, 138, u);
        } else {
          final u = (tCol - 0.72) / 0.28;
          cr = _lerp(224, 255, u);
          cg = _lerp(146, 238, u);
          cb = _lerp(138, 210, u);
        }
      }

      final alpha = _clamp(0.26 + visualDensity * 0.78, 0.20, 1.0);
      batch.add(
        gIdx,
        px,
        py,
        glyphScale,
        cr.round(),
        cg.round(),
        cb.round(),
        (alpha * 255).round(),
      );
    }
  }

  batch.flush(canvas);
}

// ============================================================================
// 04 · AURORA（极光雪原 · 双幕丝绸极光 + 雕塑感雪山谷 + 侧翼冷杉林 + 视差斜雪）
// ============================================================================

const List<double> _auroraPineOffsets = [
  -0.78, -0.73, -0.68, -0.64, -0.60, -0.55, -0.51, -0.47, -0.43, -0.39, -0.35,
  -0.31, -0.27, -0.23,
  0.24, 0.28, 0.32, 0.36, 0.40, 0.44, 0.48, 0.53, 0.57, 0.62, 0.66, 0.70, 0.75,
  0.80,
];

void _paintAurora(ChannelAsciiFrame f) {
  final canvas = f.canvas;
  final w = f.size.width;
  final h = f.size.height;
  final dark = f.dark;
  final t = f.t;
  final za = f.zoneAlpha;
  final anchorX = f.thumb ? w * 0.5 : f.stageCenterX;

  // 1. 极夜冰幕 / 冬晨霜雪天幕渐变
  canvas.drawRect(
    Offset.zero & f.size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, h),
        dark
            ? [
                Color.fromRGBO(4, 11, 23, za),
                Color.fromRGBO(7, 23, 40, za),
                Color.fromRGBO(9, 26, 46, za),
                Color.fromRGBO(16, 38, 63, za),
              ]
            : [
                Color.fromRGBO(188, 216, 243, za),
                Color.fromRGBO(220, 236, 249, za),
                Color.fromRGBO(238, 245, 252, za),
                Color.fromRGBO(215, 231, 247, za),
              ],
        const [0.0, 0.32, 0.70, 1.0],
      ),
  );

  // 等比舞台归一横坐标（大屏/宽屏/窄窗等比自适应，绝不压扁）
  final refSpan = f.thumb
      ? math.max(w * 0.85, h * 1.18)
      : math.max(h * 1.48, w * 0.70);
  final invRefSpan = 1.0 / math.max(1.0, refSpan);
  final scrollU = f.thumb ? 0.0 : (f.scrollX * 0.00008).clamp(-0.35, 0.35);
  final scrollPhase = f.thumb ? 0.0 : f.scrollY * 0.00018;
  final tt = t + scrollPhase;

  double band0Y(double u) {
    final arch = math.exp(-u * u * 2.8);
    return h *
        (0.345 -
            0.072 * arch +
            0.056 * math.sin(u * 2.9 + tt * 0.19 + 0.65) +
            0.024 * math.cos(u * 5.8 - tt * 0.25 + 0.4) +
            0.011 * math.sin(u * 10.4 + tt * 0.34));
  }

  double band1Y(double u) {
    final arch = math.exp(-u * u * 2.2);
    return h *
        (0.255 -
            0.045 * arch +
            0.048 * math.sin(u * 2.5 - tt * 0.15 + 2.4) +
            0.020 * math.cos(u * 5.2 + tt * 0.21));
  }

  double farPeakY(double u) {
    final valley = 1.0 - math.exp(-u * u * 3.4);
    final peakA = math.exp(-math.pow((u + 0.43) / 0.22, 2)) * 0.125;
    final peakB = math.exp(-math.pow((u - 0.46) / 0.24, 2)) * 0.135;
    final peakC = math.exp(-math.pow((u + 0.17) / 0.13, 2)) * 0.042;
    final peakD = math.exp(-math.pow((u - 0.21) / 0.14, 2)) * 0.048;
    final micro =
        0.011 * math.sin(u * 13.0 + 0.8) + 0.006 * math.cos(u * 23.0 - 0.4);
    return h * (0.835 - 0.050 * valley - peakA - peakB - peakC - peakD + micro);
  }

  double midDriftY(double u) {
    final leftBank = math.exp(-math.pow((u + 0.32) / 0.36, 2)) * 0.088;
    final rightBank = math.exp(-math.pow((u - 0.52) / 0.30, 2)) * 0.072;
    return h *
        (0.905 - leftBank - rightBank + 0.016 * math.sin(u * 4.8 + 0.4));
  }

  double nearDriftY(double u) {
    final rightSlope = math.exp(-math.pow((u - 0.24) / 0.42, 2)) * 0.068;
    final leftCorner = math.exp(-math.pow((u + 0.60) / 0.26, 2)) * 0.055;
    return h *
        (0.962 - rightSlope - leftCorner + 0.012 * math.cos(u * 5.2 - 0.7));
  }

  final strength = _clamp(f.level * (f.thumb ? 1.18 : 1.05), 0.35, 1.85);
  const violetBias = 0.45;
  final vStart = _lerp(0.56, 0.24, violetBias);

  // 2. 沿主极光曲线铺设柔和大气漫射晕
  final glowSteps = f.thumb ? 5 : 12;
  final glowGain = math.min(1.4, strength) * za;
  for (var i = 0; i <= glowSteps; i++) {
    final gx = (i / glowSteps) * w;
    final u = (gx - anchorX) * invRefSpan + scrollU * 0.45;
    final gy = band0Y(u) - h * 0.075;
    final rad = h * 0.29;
    final hueShift = 0.5 + 0.5 * math.sin(u * 3.1 + tt * 0.12 + 0.6);
    const vMix = violetBias * 0.95;
    final cCoreT = _clamp(hueShift * 0.48 + vMix * 0.22, 0.0, 1.0);
    final cOutT = _clamp(0.20 + hueShift * 0.45 + vMix * 0.45, 0.0, 1.0);

    final int r0, g0, b0, r1, g1, b1;
    final double a0, a1;
    if (dark) {
      r0 = _lerp(42, 116, cCoreT).round();
      g0 = _lerp(245, 168, cCoreT).round();
      b0 = _lerp(190, 255, cCoreT).round();
      r1 = _lerp(20, 176, cOutT).round();
      g1 = _lerp(168, 92, cOutT).round();
      b1 = _lerp(158, 250, cOutT).round();
      a0 = 0.145 * glowGain;
      a1 = 0.075 * glowGain;
    } else {
      r0 = _lerp(10, 37, cCoreT).round();
      g0 = _lerp(148, 99, cCoreT).round();
      b0 = _lerp(132, 235, cCoreT).round();
      r1 = _lerp(14, 124, cOutT).round();
      g1 = _lerp(116, 58, cOutT).round();
      b1 = _lerp(144, 237, cOutT).round();
      a0 = 0.125 * glowGain;
      a1 = 0.058 * glowGain;
    }
    canvas.drawRect(
      Rect.fromCircle(center: Offset(gx, gy), radius: rad),
      Paint()
        ..blendMode = dark ? BlendMode.plus : BlendMode.srcOver
        ..shader = ui.Gradient.radial(
          Offset(gx, gy),
          rad,
          [
            Color.fromRGBO(r0, g0, b0, a0),
            Color.fromRGBO(r1, g1, b1, a1),
            Color.fromRGBO(r1, g1, b1, 0.0),
          ],
          const [0.0, 0.48, 1.0],
        ),
    );
  }

  final (cw, ch, glyphScale) = _fineGrid(
    f.size,
    baseW: 5.4,
    baseH: 7.6,
    thumb: f.thumb,
    maxCells: 96000,
  );
  final cols = math.max(1, (w / cw).floor());
  final rows = math.max(1, (h / ch).floor());
  final ox = ((w - cols * cw) * 0.5).floorToDouble();
  final oy = ((h - rows * ch) * 0.5).floorToDouble();

  final batch = ChannelGlyphBatch.shared..begin(cols * (rows ~/ 2 + 24));

  // 配色常量
  final aRimR = dark ? 128.0 : 6.0;
  final aRimG = dark ? 255.0 : 140.0;
  final aRimB = dark ? 206.0 : 118.0;
  final aMidR = dark ? 45.0 : 11.0;
  final aMidG = dark ? 224.0 : 116.0;
  final aMidB = dark ? 204.0 : 148.0;
  final aCyanR = dark ? 72.0 : 37.0;
  final aCyanG = dark ? 186.0 : 99.0;
  final aCyanB = dark ? 255.0 : 235.0;
  final aVioR = dark ? 180.0 : 116.0;
  final aVioG = dark ? 132.0 : 46.0;
  final aVioB = dark ? 255.0 : 222.0;
  final aMagR = dark ? 240.0 : 168.0;
  final aMagG = dark ? 132.0 : 36.0;
  final aMagB = dark ? 250.0 : 182.0;

  // 3. 连续丝绸双幕极光（按列计算活跃行区间，跳过空天幕零浪费）
  final maxAuroraRow = math.min(rows, ((h * 0.58) / ch).ceil());
  for (var c = 0; c < cols; c++) {
    final px = ox + c * cw + cw * 0.5;
    final u = (px - anchorX) * invRefSpan + scrollU * 0.45;

    final y0 = band0Y(u);
    final y1 = band1Y(u);

    final curl0 = _fbm2(u * 2.4 + tt * 0.07, 1.4);
    final wave0 = math.sin(u * 7.2 + tt * 0.30 + 2.2 * curl0);
    final fold0 = 0.58 + 0.42 * (0.5 + 0.5 * wave0);
    final ray0 = 0.78 + 0.22 * _vnoise2(u * 13.0 + tt * 0.42, 3.1);
    final curtainH0 = h * (0.21 + 0.12 * (0.5 + 0.5 * wave0));

    final curl1 = _fbm2(u * 2.0 - tt * 0.055, 6.2);
    final wave1 = math.sin(u * 6.0 - tt * 0.24 + 2.0 * curl1);
    final fold1 = 0.54 + 0.46 * (0.5 + 0.5 * wave1);
    final ray1 = 0.76 + 0.24 * _vnoise2(u * 11.0 - tt * 0.34, 9.7);
    final curtainH1 = h * (0.20 + 0.09 * (0.5 + 0.5 * wave1));

    final topY = math.min(y0 - curtainH0 * 1.08, y1 - curtainH1 * 1.05);
    final botY = math.max(y0 + curtainH0 * 0.18, y1 + curtainH1 * 0.16);
    final rMin = ((topY - oy) / ch).floor().clamp(0, maxAuroraRow);
    final rMax = ((botY - oy) / ch).ceil().clamp(0, maxAuroraRow);

    for (var r = rMin; r < rMax; r++) {
      final py = oy + r * ch + ch * 0.5;

      var best = 0.0;
      var alt = 0.0;
      var isRim = false;
      var primary = true;

      final d0 = (y0 - py) / curtainH0;
      if (d0 > -0.18 && d0 < 1.08) {
        final lowerCut = _smoothstep(-0.16, 0.10, d0);
        final upperFade = math.pow(_clamp(1.06 - d0, 0.0, 1.0), 1.20).toDouble();
        final rimBoost =
            1.0 + 0.42 * math.exp(-math.pow((d0 - 0.09) / 0.14, 2));
        final flute =
            0.82 + 0.18 * math.sin(u * 21.0 + d0 * 2.4 + tt * 0.55);
        final v0 =
            lowerCut * upperFade * fold0 * ray0 * flute * rimBoost * strength;
        if (v0 > best) {
          best = v0;
          alt = _clamp(d0, 0.0, 1.0);
          isRim = d0 > 0.0 && d0 < 0.19;
          primary = true;
        }
      }

      final d1 = (y1 - py) / curtainH1;
      if (d1 > -0.16 && d1 < 1.05) {
        final lowerCut = _smoothstep(-0.14, 0.11, d1);
        final upperFade = math.pow(_clamp(1.04 - d1, 0.0, 1.0), 1.28).toDouble();
        final v1 = lowerCut * upperFade * fold1 * ray1 * 0.86 * strength;
        if (v1 > best) {
          best = v1;
          alt = _clamp(d1 * 0.65 + 0.36, 0.0, 1.0);
          isRim = false;
          primary = false;
        }
      }

      if (best < 0.09) continue;
      final mask = f.maskAt(px, py);
      final dither = (_bayer4[(r & 3) * 4 + (c & 3)] / 16.0 - 0.5) * 0.08;
      final lv = best * mask + dither;
      if (lv < 0.09) continue;

      final int gIdx;
      if (lv > 0.96 && isRim) {
        gIdx = _gDblVert;
      } else if (lv > 0.68) {
        gIdx = _gVert;
      } else if (lv > 0.48) {
        gIdx = alt > 0.48 ? _gShade2 : _gBraille4;
      } else if (lv > 0.33) {
        gIdx = alt > 0.42 ? _gShade1 : _gColon;
      } else if (lv > 0.21) {
        gIdx = (c + r).isEven ? _gShade1 : _gBraille3;
      } else if (lv > 0.13) {
        gIdx = _gBraille2;
      } else {
        gIdx = _gBraille1;
      }

      final double cr, cg, cb;
      final midHiR = primary ? aCyanR : aVioR;
      final midHiG = primary ? aCyanG : aVioG;
      final midHiB = primary ? aCyanB : aVioB;
      final vSplit = vStart + (1.0 - vStart) * 0.55;
      if (alt < vStart * 0.48) {
        final k = alt / (vStart * 0.48);
        cr = _lerp(aRimR, aMidR, k);
        cg = _lerp(aRimG, aMidG, k);
        cb = _lerp(aRimB, aMidB, k);
      } else if (alt < vStart) {
        final k = (alt - vStart * 0.48) / (vStart * 0.52);
        cr = _lerp(aMidR, midHiR, k);
        cg = _lerp(aMidG, midHiG, k);
        cb = _lerp(aMidB, midHiB, k);
      } else if (alt < vSplit) {
        final k = (alt - vStart) / (vSplit - vStart);
        cr = _lerp(midHiR, aVioR, k);
        cg = _lerp(midHiG, aVioG, k);
        cb = _lerp(midHiB, aVioB, k);
      } else {
        final k = (alt - vSplit) / (1.0 - vSplit);
        cr = _lerp(aVioR, aMagR, k);
        cg = _lerp(aVioG, aMagG, k);
        cb = _lerp(aVioB, aMagB, k);
      }

      final alpha = _clamp(lv * (dark ? 0.86 : 0.72), 0.0, 0.94);
      batch.add(
        gIdx,
        px,
        py,
        glyphScale,
        cr.round(),
        cg.round(),
        cb.round(),
        (alpha * 255).round(),
      );
    }
  }

  // 4. 极地高空微星
  final starCount = f.thumb ? 16 : ((w * h) / 14500.0).round().clamp(48, 120);
  final starR = dark ? 228 : 46;
  final starG = dark ? 244 : 94;
  final starB = dark ? 255 : 146;
  for (var i = 0; i < starCount; i++) {
    final sx = _hash2(i * 19 + 3, 71) * w;
    final sy = _hash2(i * 31 + 11, 137) * h * 0.68;
    final mask = f.maskAt(sx, sy);
    final tw =
        0.48 + 0.52 * math.sin(t * (1.1 + _hash2(i, 9) * 1.9) + i * 2.1);
    final bright = _hash2(i * 7, 53);
    final gIdx = bright > 0.92
        ? _gSparkle
        : (bright > 0.78 ? _gSparkleSm : (bright > 0.58 ? _gPlus : _gDot));
    final a = _clamp(
      (dark ? 0.28 + 0.54 * bright : 0.18 + 0.34 * bright) * tw * mask,
      0.04,
      0.88,
    );
    batch.add(
      gIdx,
      sx,
      sy,
      glyphScale * 1.05,
      starR,
      starG,
      starB,
      (a * 255).round(),
    );
  }

  // 5. 雕塑感雪原山谷（交错不对称雪坡 + 2D 坡面法线光影）
  final hillBoost = _clamp(0.75 + f.level * 0.25, 0.70, 1.25);
  final hillLitR = dark ? 214.0 : 255.0;
  final hillLitG = dark ? 244.0 : 255.0;
  final hillLitB = dark ? 255.0 : 255.0;
  final hillMidR = dark ? 96.0 : 96.0;
  final hillMidG = dark ? 158.0 : 144.0;
  final hillMidB = dark ? 210.0 : 194.0;
  final hillShR = dark ? 28.0 : 52.0;
  final hillShG = dark ? 58.0 : 94.0;
  final hillShB = dark ? 96.0 : 144.0;
  const du = 0.012;

  for (var c = 0; c < cols; c++) {
    final px = ox + c * cw + cw * 0.5;
    final uFar = (px - anchorX) * invRefSpan + scrollU * 0.28;
    final uMid = (px - anchorX) * invRefSpan + scrollU * 0.55;
    final uNear = (px - anchorX) * invRefSpan + scrollU * 0.85;

    final yFar = farPeakY(uFar);
    final yMid = midDriftY(uMid);
    final yNear = nearDriftY(uNear);

    final slopeFar = (farPeakY(uFar + du) - farPeakY(uFar - du)) / (2 * du * h);
    final slopeMid = (midDriftY(uMid + du) - midDriftY(uMid - du)) / (2 * du * h);
    final slopeNear =
        (nearDriftY(uNear + du) - nearDriftY(uNear - du)) / (2 * du * h);

    final startRow = ((yFar - ch * 0.5 - oy) / ch).floor().clamp(0, rows);
    for (var r = startRow; r < rows; r++) {
      final py = oy + r * ch + ch * 0.5;
      if (py < yFar - ch * 0.45) continue;

      final int layer;
      final double dist;
      final double slope;
      final double uTex;
      if (py >= yNear - ch * 0.35) {
        layer = 2;
        dist = py - yNear;
        slope = slopeNear;
        uTex = uNear;
      } else if (py >= yMid - ch * 0.35) {
        layer = 1;
        dist = py - yMid;
        slope = slopeMid;
        uTex = uMid;
      } else {
        layer = 0;
        dist = py - yFar;
        slope = slopeFar;
        uTex = uFar;
      }

      final mask = f.maskAt(px, py);
      final isCrest = dist >= -ch * 0.45 && dist < ch * 0.80;
      final pyNorm = py / h;
      final snowTex = _fbm2(uTex * 7.2 + pyNorm * 3.4 - t * 0.025, pyNorm * 8.4);
      final dither = (_bayer4[(r & 3) * 4 + (c & 3)] / 16.0 - 0.5) * 0.14;
      final lightFacing = _clamp(0.56 - slope * 1.05, 0.10, 1.0);
      final depthFade = _clamp(dist / (h * (layer == 0 ? 0.15 : 0.11)), 0.0, 1.0);

      final int gIdx;
      double cr, cg, cb, alpha;
      if (isCrest) {
        if (slope < -0.18) {
          gIdx = _gSlash;
        } else if (slope > 0.18) {
          gIdx = _gBackslash;
        } else {
          gIdx = snowTex > 0.54 ? _gTilde : _gDot;
        }
        final rimMix = layer == 0 ? (dark ? 0.28 : 0.36) : (dark ? 0.14 : 0.18);
        if (dark) {
          cr = _lerp(hillLitR, aRimR, rimMix);
          cg = _lerp(hillLitG, aRimG, rimMix);
          cb = _lerp(hillLitB, aRimB, rimMix);
          alpha = (0.48 + layer * 0.12) * hillBoost * mask;
        } else {
          cr = _lerp(hillShR, aMidR, rimMix);
          cg = _lerp(hillShG, aMidG, rimMix);
          cb = _lerp(hillShB, aMidB, rimMix);
          alpha = (0.44 + layer * 0.10) * hillBoost * mask;
        }
      } else {
        final lit = _clamp(
          (1.0 - depthFade * 0.56) * (0.40 + 0.60 * lightFacing) +
              (snowTex - 0.5) * 0.26 +
              dither,
          0.0,
          1.0,
        );
        if (lit > 0.74) {
          gIdx = _gShade3;
        } else if (lit > 0.54) {
          gIdx = _gShade2;
        } else if (lit > 0.36) {
          gIdx = _gShade1;
        } else if (lit > 0.22) {
          gIdx = _gColon;
        } else {
          gIdx = _gDot;
        }
        if (dark) {
          if (lit > 0.52) {
            final k = (lit - 0.52) / 0.48;
            cr = _lerp(hillMidR, hillLitR, k);
            cg = _lerp(hillMidG, hillLitG, k);
            cb = _lerp(hillMidB, hillLitB, k);
          } else {
            final k = lit / 0.52;
            cr = _lerp(hillShR, hillMidR, k);
            cg = _lerp(hillShG, hillMidG, k);
            cb = _lerp(hillShB, hillMidB, k);
          }
          if (lit > 0.66) {
            cr = _lerp(cr, aRimR, 0.16);
            cg = _lerp(cg, aRimG, 0.16);
            cb = _lerp(cb, aRimB, 0.16);
          }
          alpha = _lerp(0.22, 0.60, lit) * (0.76 + layer * 0.12) * hillBoost * mask;
        } else {
          final shadowWeight = _clamp((1.0 - lit) * 1.15, 0.0, 1.0);
          cr = _lerp(hillMidR, hillShR, shadowWeight);
          cg = _lerp(hillMidG, hillShG, shadowWeight);
          cb = _lerp(hillMidB, hillShB, shadowWeight);
          alpha =
              _lerp(0.16, 0.48, (1.0 - lit) * 0.68 + (1.0 - depthFade) * 0.32) *
              (0.78 + layer * 0.11) *
              hillBoost *
              mask;
        }
      }

      batch.add(
        gIdx,
        px,
        py,
        glyphScale,
        cr.round(),
        cg.round(),
        cb.round(),
        (_clamp(alpha, 0.0, 0.94) * 255).round(),
      );
    }
  }

  // 5b. 左右翼错落北极冷杉松林（中央雪谷开阔通透）
  final pineR = dark ? 112.0 : 30.0;
  final pineG = dark ? 178.0 : 68.0;
  final pineB = dark ? 218.0 : 108.0;
  final pineRimR = dark ? 158.0 : 14.0;
  final pineRimG = dark ? 248.0 : 136.0;
  final pineRimB = dark ? 226.0 : 132.0;

  for (var i = 0; i < _auroraPineOffsets.length; i++) {
    if (f.thumb && i.isOdd) continue;
    final jitter = (_hash2(i * 17, 29) - 0.5) * 0.024;
    final u = _auroraPineOffsets[i] + jitter;
    final onNear = i % 3 == 0;
    final px = anchorX + (u - scrollU * (onNear ? 0.55 : 0.28)) * refSpan;
    if (px < -20 || px > w + 20) continue;
    final baseY = onNear ? midDriftY(u) + 3.0 : farPeakY(u) + 4.0;
    final tiers = _hash2(i, 73) > 0.30 ? 3 : 2;
    final sc =
        (f.thumb ? 0.85 : 1.18) *
        (onNear ? 1.24 : 0.90) *
        (0.85 + _hash2(i, 41) * 0.38);
    final mask = f.maskAt(px, baseY);

    for (var k = 0; k < tiers; k++) {
      final ty = baseY - (k * 5.6 + 3.8) * sc;
      final sizeMul = (1.35 - k * 0.28) * sc;
      final topMix = k == tiers - 1 ? 0.34 : 0.0;
      final cr = _lerp(pineR, pineRimR, topMix);
      final cg = _lerp(pineG, pineRimG, topMix);
      final cb = _lerp(pineB, pineRimB, topMix);
      final a =
          ((onNear ? (dark ? 0.68 : 0.64) : (dark ? 0.46 : 0.44)) - k * 0.04) *
          mask;
      batch.add(
        _gTri,
        px,
        ty,
        glyphScale * sizeMul,
        cr.round(),
        cg.round(),
        cb.round(),
        (_clamp(a, 0.0, 0.92) * 255).round(),
      );
    }
  }

  // 5c. 贴地风吹雪烟（spindrift）
  final snowNearR = dark ? 240 : 255;
  final snowNearG = dark ? 249 : 255;
  final snowNearB = dark ? 255 : 255;
  final snowFarR = dark ? 145 : 98;
  final snowFarG = dark ? 198 : 146;
  final snowFarB = dark ? 238 : 194;

  final driftCount = f.thumb ? 8 : 30;
  for (var i = 0; i < driftCount; i++) {
    final sp = 24.0 + _hash2(i, 61) * 30.0;
    final sx = _wrapCoord(_hash2(i * 13, 19) * w + t * sp, w, 20.0);
    final u = (sx - anchorX) * invRefSpan + scrollU * 0.55;
    final sy =
        (i.isEven ? midDriftY(u) : nearDriftY(u)) -
        2.0 -
        _hash2(i, 37) * 10.0;
    final a =
        (dark ? 0.38 : 0.48) *
        (0.5 + 0.5 * math.sin(t * 2.0 + i)) *
        f.maskAt(sx, sy);
    batch.add(
      i % 3 == 0 ? _gTilde : _gDot,
      sx,
      sy,
      glyphScale,
      snowNearR,
      snowNearG,
      snowNearB,
      (_clamp(a, 0.0, 0.9) * 255).round(),
    );
  }

  // 6. 三层视差斜吹雪花
  final flakeCount = f.thumb ? 28 : ((w * h) / 9200.0).round().clamp(88, 220);
  for (var i = 0; i < flakeCount; i++) {
    final layer = i % 3;
    final seedX = _hash2(i * 41 + 7, 101);
    final seedY = _hash2(i * 59 + 13, 211);
    final fallSpeed = layer == 0 ? 15.0 : (layer == 1 ? 28.0 : 44.0);
    final windSpeed = layer == 0 ? 10.0 : (layer == 1 ? 20.0 : 32.0);
    final sway =
        math.sin(t * (1.0 + layer * 0.35) + i * 1.7) * (5.0 + layer * 6.0);

    final x = _wrapCoord(seedX * w + t * windSpeed + sway, w, 15.0);
    final y = _wrapCoord(seedY * h + t * fallSpeed, h, 15.0);

    final int gIdx;
    if (layer == 0) {
      gIdx = i.isEven ? _gDot : _gBraille2;
    } else if (layer == 1) {
      gIdx = i % 4 == 0 ? _gRingSm : (i.isEven ? _gPlus : _gDot);
    } else {
      gIdx = i % 5 == 0 ? _gSparkle : (i % 3 == 0 ? _gStar : _gSparkleSm);
    }
    final scale = layer == 0 ? 0.88 : (layer == 1 ? 1.05 : 1.22);
    final baseAlpha = dark
        ? (layer == 0 ? 0.30 : (layer == 1 ? 0.52 : 0.78))
        : (layer == 0 ? 0.40 : (layer == 1 ? 0.68 : 0.90));
    final twinkle = 0.72 + 0.28 * math.sin(t * 2.3 + i);
    final a = _clamp(baseAlpha * twinkle * f.maskAt(x, y), 0.0, 0.94);

    batch.add(
      gIdx,
      x,
      y,
      glyphScale * scale,
      layer == 0 ? snowFarR : snowNearR,
      layer == 0 ? snowFarG : snowNearG,
      layer == 0 ? snowFarB : snowNearB,
      (a * 255).round(),
    );
  }

  batch.flush(canvas);
}

// ============================================================================
// 05 · STRATA（声纹潮汐 · 恒定波长全景 3D 隐藏面山脊 + 44 层精密等高线）
// ============================================================================

Float32List _strataHorizon = Float32List(0);

double _evalTerrainHeight(double u, double v, double t, double scrollShift) {
  final vz = v * 3.4 - scrollShift;
  final ux = u * 2.55;
  final ridgeEnv =
      0.46 + 0.54 * math.exp(-math.pow((u.abs() - 0.38) / 0.68, 2));
  final w1 = math.sin(
    ux * 1.85 + math.cos(vz * 1.15 - t * 0.55) * 1.25 + t * 0.42,
  );
  final w2 = math.cos(ux * 3.2 - vz * 2.25 + t * 0.72) * 0.52;
  final w3 = math.sin((ux + vz * 0.9) * 4.6 - t * 1.05) * 0.26;
  final valley = math.sin(vz * 1.65 + t * 0.35) * 0.35;
  return 0.48 + (w1 * 0.46 + w2 * 0.38 + w3 * 0.24 + valley * 0.28) * ridgeEnv;
}

class _PeakCallout {
  const _PeakCallout(this.h, this.x, this.y);
  final double h, x, y;
}

void _paintStrata(ChannelAsciiFrame f) {
  final canvas = f.canvas;
  final w = f.size.width;
  final h = f.size.height;
  final dark = f.dark;
  final t = f.t;
  final za = f.zoneAlpha;
  final anchorX = f.thumb ? w * 0.5 : f.stageCenterX;

  // 1. 深墨玉声呐底 / 瑞士测绘米白纸
  canvas.drawRect(
    Offset.zero & f.size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, h),
        dark
            ? [
                Color.fromRGBO(4, 9, 12, za),
                Color.fromRGBO(5, 16, 21, za),
                Color.fromRGBO(3, 8, 11, za),
              ]
            : [
                Color.fromRGBO(244, 246, 241, za),
                Color.fromRGBO(231, 236, 226, za),
              ],
        dark ? const [0.0, 0.5, 1.0] : const [0.0, 1.0],
      ),
  );

  // 地平线声呐辉光
  final ha = _clamp((dark ? 0.14 : 0.05) * f.level * za, 0.0, 0.28);
  if (ha > 0.005) {
    canvas.drawRect(
      Offset.zero & f.size,
      Paint()
        ..blendMode = dark ? BlendMode.plus : BlendMode.srcOver
        ..shader = ui.Gradient.radial(
          Offset(anchorX, h * 0.38),
          math.max(w, h) * 0.60,
          dark
              ? [
                  Color.fromRGBO(45, 212, 191, ha),
                  Color.fromRGBO(14, 116, 144, ha * 0.38),
                  const Color.fromRGBO(0, 0, 0, 0),
                ]
              : [
                  Color.fromRGBO(15, 118, 110, ha),
                  Color.fromRGBO(20, 83, 45, ha * 0.20),
                  const Color.fromRGBO(0, 0, 0, 0),
                ],
          const [0.0, 0.6, 1.0],
        ),
    );
  }

  final (cw, ch, glyphScale) = _fineGrid(
    f.size,
    baseW: 5.6,
    baseH: 7.8,
    thumb: f.thumb,
    maxCells: 80000,
  );
  final cols = math.max(8, (w / cw).floor());
  if (_strataHorizon.length < cols) {
    _strataHorizon = Float32List(cols);
  }
  _strataHorizon.fillRange(0, cols, h + 20.0);

  final ox = ((w - cols * cw) * 0.5).floorToDouble();
  final numSlices = f.thumb ? 16 : 44;
  final scrollShift = f.scrollY * 0.0018;
  // 恒定横向参考波长：窄窗自然取中央山脊不挤压尖刺，大屏左右延展壮阔山脉
  final refHalfW = f.thumb ? math.max(20.0, w * 0.5) : math.max(520.0, h * 0.68);
  final invRefHalfW = 1.0 / refHalfW;

  final batch = ChannelGlyphBatch.shared..begin(cols * numSlices);
  final peakCandidates = <_PeakCallout>[];

  for (var si = 0; si < numSlices; si++) {
    final v = si / (numSlices - 1);
    final depthFade = 1.0 - v * 0.60;
    final baseScreenY = h * _lerp(0.96, 0.24, math.pow(v, 0.86).toDouble());
    final perspX = _lerp(1.06, 0.78, v);
    final invPerspX = 1.0 / perspX;
    final elevScale = h * _lerp(0.32, 0.17, v);

    var sliceBestH = -9.0;
    var sliceBestX = 0.0;
    var sliceBestY = 0.0;

    for (var c = 0; c < cols; c++) {
      final px = ox + c * cw + cw * 0.5;
      final u = ((px - anchorX) * invRefHalfW) * invPerspX;

      final elev = _evalTerrainHeight(u, v, t, scrollShift);
      final sy = baseScreenY - elev * elevScale;
      if (sy >= _strataHorizon[c]) continue;

      final prevHorizon = _strataHorizon[c];
      _strataHorizon[c] = sy;

      final mask = f.maskAt(px, sy);
      final hNorm = _clamp((elev - 0.05) / 1.15, 0.0, 1.0);

      if (!f.thumb &&
          si % 7 == 3 &&
          elev > sliceBestH &&
          px > 90.0 &&
          px < w - 90.0) {
        sliceBestH = elev;
        sliceBestX = px;
        sliceBestY = sy;
      }

      final hR = _evalTerrainHeight(u + 0.04, v, t, scrollShift);
      final slope = (hR - elev) * 14.0;
      final isoPhase = ((elev * 5.0) % 1.0 + 1.0) % 1.0;
      final isIso = isoPhase < 0.15 || isoPhase > 0.89;

      int ridgeGlyph;
      if (hNorm > 0.84) {
        ridgeGlyph = (c + si) % 3 == 0 ? _gTri : _gDiamond;
      } else if (isIso && hNorm > 0.34) {
        if (slope > 0.45) {
          ridgeGlyph = _gSlash;
        } else if (slope < -0.45) {
          ridgeGlyph = _gBackslash;
        } else {
          ridgeGlyph = hNorm > 0.62 ? _gDblDash : _gBoldDash;
        }
      } else if (slope.abs() > 0.65) {
        ridgeGlyph = slope > 0 ? _gSlash : _gBackslash;
      } else {
        final bi = (hNorm * (_strataBlocks.length - 1))
            .floor()
            .clamp(1, _strataBlocks.length - 1);
        ridgeGlyph = _strataBlocks[bi];
      }

      double cr, cg, cb;
      if (dark) {
        if (hNorm < 0.36) {
          final k = hNorm / 0.36;
          cr = _lerp(16, 20, k);
          cg = _lerp(74, 152, k);
          cb = _lerp(96, 156, k);
        } else if (hNorm < 0.74) {
          final k = (hNorm - 0.36) / 0.38;
          cr = _lerp(20, 74, k);
          cg = _lerp(152, 236, k);
          cb = _lerp(156, 206, k);
        } else {
          final k = (hNorm - 0.74) / 0.26;
          cr = _lerp(74, 254, k);
          cg = _lerp(236, 244, k);
          cb = _lerp(206, 158, k);
        }
        if (isIso) {
          cr = _lerp(cr, 235, 0.35);
          cg = _lerp(cg, 255, 0.35);
          cb = _lerp(cb, 245, 0.35);
        }
      } else {
        if (hNorm < 0.40) {
          final k = hNorm / 0.40;
          cr = _lerp(58, 18, k);
          cg = _lerp(94, 110, k);
          cb = _lerp(98, 104, k);
        } else if (hNorm < 0.76) {
          final k = (hNorm - 0.40) / 0.36;
          cr = _lerp(18, 156, k);
          cg = _lerp(110, 92, k);
          cb = _lerp(104, 48, k);
        } else {
          final k = (hNorm - 0.76) / 0.24;
          cr = _lerp(156, 194, k);
          cg = _lerp(92, 65, k);
          cb = _lerp(48, 12, k);
        }
      }

      final alpha = _clamp(
        (0.28 + hNorm * 0.62 + (isIso ? 0.22 : 0.0)) * depthFade * f.level * mask,
        0.09,
        0.98,
      );
      final rInt = cr.round();
      final gInt = cg.round();
      final bInt = cb.round();
      batch.add(
        ridgeGlyph,
        px,
        sy,
        glyphScale,
        rInt,
        gInt,
        bInt,
        (alpha * 255).round(),
      );

      // 山坡微光垂帘增强 3D 实体感
      final fillGap = math.min(prevHorizon - sy, ch * 2.2);
      if (fillGap > ch * 0.88 && si < numSlices - 2) {
        final fa = _clamp(alpha * 0.36, 0.06, 0.52);
        batch.add(
          hNorm > 0.55 ? _gShade1 : _gBraille2,
          px,
          sy + ch * 0.92,
          glyphScale,
          rInt,
          gInt,
          bInt,
          (fa * 255).round(),
        );
      }
    }

    if (sliceBestH > 0.86 && sliceBestY > 44.0 && sliceBestY < h - 34.0) {
      peakCandidates.add(_PeakCallout(sliceBestH, sliceBestX, sliceBestY));
    }
  }

  batch.flush(canvas);

  // 防碰撞最高孤峰测绘标高胶囊（至多 2 处，清晰克制）
  if (!f.thumb && peakCandidates.isNotEmpty) {
    peakCandidates.sort((a, b) => b.h.compareTo(a.h));
    final chosen = <_PeakCallout>[];
    for (final pk in peakCandidates) {
      if (f.maskAt(pk.x, pk.y) < 0.45) continue;
      final clash = chosen.any(
        (o) => (o.x - pk.x).abs() < 130.0 && (o.y - pk.y).abs() < 55.0,
      );
      if (clash) continue;
      chosen.add(pk);
      if (chosen.length >= 2) break;
    }

    final pillBg = Paint()
      ..color = dark
          ? Color.fromRGBO(4, 12, 16, 0.74 * za)
          : Color.fromRGBO(244, 246, 241, 0.86 * za);
    final stemPaint = Paint()
      ..color = dark
          ? Color.fromRGBO(254, 240, 138, 0.44 * za)
          : Color.fromRGBO(154, 52, 18, 0.46 * za)
      ..strokeWidth = 1.0;
    final labelColor = dark
        ? Color.fromRGBO(254, 240, 138, 0.92 * za)
        : Color.fromRGBO(154, 52, 18, 0.92 * za);

    for (final pk in chosen) {
      final label = '+${(pk.h * 640).round()}m';
      final ly = pk.y - 15.0;
      const boxW = 38.0;
      const boxH = 14.0;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(pk.x, ly), width: boxW, height: boxH),
        pillBg,
      );
      canvas.drawLine(
        Offset(pk.x, ly + boxH * 0.5),
        Offset(pk.x, pk.y - 3.0),
        stemPaint,
      );
      ChannelText.paint(
        canvas,
        label,
        Offset(pk.x, ly + 3.2),
        9.0,
        ChannelFont.mono,
        labelColor,
        align: TextAlign.center,
        weight: FontWeight.w600,
      );
    }
  }
}
