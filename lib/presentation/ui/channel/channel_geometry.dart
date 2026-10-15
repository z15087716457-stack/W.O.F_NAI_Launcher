import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'channel_contract.dart';

/// 通道的几何与随机工具。
///
/// 装饰在“装饰坐标”里画：装饰坐标 = 世界坐标 ÷ [decorScale]。原型按每侧约 240px 留白设计；
/// 真实生图页（左栏 420、历史 210）竖图默认聚焦时缩放约 0.72、每侧只剩约 160px，
/// 所以整套装饰按 0.68 缩小，主带（图片边外 50–300 装饰单位）在默认聚焦时就看得见。
abstract final class ChannelGeo {
  static const decorScale = 0.68;

  /// 竖图半宽（世界 416）在装饰坐标里的位置 = 图片边。
  static const e = 416 / decorScale;

  /// 中间“安静走廊”半宽、主带外沿、次带外沿。
  static const m0 = e + 40;
  static const b1 = e + 360;
  static const b2 = e + 700;

  /// 每段主题长度、过渡层长度（装饰单位；约合世界 6400 / 1770）。
  static const zone = 9400.0;
  static const transition = 2600.0;

  /// 第 0 段起点：最新一批（世界 y≈0）落在第 0 段的主体里。
  static const origin = -3500.0;

  /// 过渡层两侧小字、日期分隔线的半宽（世界单位）。
  static const dayLineHalf = 416.0 + 340.0;

  static int zoneOf(double y) => ((y - origin) / zone).floor();
  static double zoneStart(int k) => origin + k * zone;

  /// 段内权重：过渡层中心为 0，进到主体后为 1。
  static double zoneWeight(int k, double y) {
    final l = y - zoneStart(k);
    return smooth(0, transition / 2, l) * smooth(0, transition / 2, zone - l);
  }

  /// 图片列安静、远处淡出。
  static double xfade(double x) {
    final ax = x.abs();
    return (0.22 + 0.78 * smooth(e - 60, e + 70, ax)) *
        (1 - smooth(2000, 2800, ax));
  }

  /// 浅色 / 深色的整体增益（原型 GAIN）。
  static double gain(bool dark) => dark ? 1.35 : 1.55;

  /// 缩到全局时的细节量：世界缩放 0.09 以下只剩地图，0.29 以上完整。
  static double detail(double worldScale) =>
      ((worldScale - 0.09) / 0.2).clamp(0.0, 1.0);
}

double smooth(double e0, double e1, double x) {
  final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double lerpD(double a, double b, double t) => a + (b - a) * t;

int modI(int a, int n) => ((a % n) + n) % n;
double modD(double a, double n) => ((a % n) + n) % n;

const _m32 = 0xFFFFFFFF;
int _imul(int a, int b) => (a * b) & _m32;

/// FNV-1a + 末端混合（原型 `hash`）：数字取整后分高低 16 位喂进去，字符串逐字。
int channelHash(List<Object> parts) {
  var h = 0x811c9dc5;
  for (final p in parts) {
    if (p is String) {
      for (final c in p.codeUnits) {
        h = _imul(h ^ c, 16777619);
      }
      continue;
    }
    final v = (p as num).floor() & _m32;
    h = _imul(h ^ (v & 0xffff), 16777619);
    h = _imul(h ^ (v >> 16), 16777619);
  }
  h ^= h >> 15;
  h = _imul(h, 0x85ebca6b);
  h ^= h >> 13;
  h = _imul(h, 0xc2b2ae35);
  h ^= h >> 16;
  return h & _m32;
}

/// mulberry32：同一组 key 永远给出同一串数。
class ChannelRng {
  ChannelRng(int seed) : _a = seed & _m32;
  int _a;

  double call() {
    _a = (_a + 0x6D2B79F5) & _m32;
    var t = _imul(_a ^ (_a >> 15), 1 | _a);
    t = ((t + _imul(t ^ (t >> 7), 61 | t)) & _m32) ^ t;
    return ((t ^ (t >> 14)) & _m32) / 4294967296;
  }

  int below(int n) => (call() * n).floor();
}

/// 平滑值噪声（0–1）。
double vnoise(double x, double y, int s) {
  final xi = x.floor(), yi = y.floor();
  final xf = x - xi, yf = y - yi;
  double r(int i, int j) => channelHash([i, j, s, 77]) / 4294967296;
  final u = xf * xf * (3 - 2 * xf), v = yf * yf * (3 - 2 * yf);
  return lerpD(
    lerpD(r(xi, yi), r(xi + 1, yi), u),
    lerpD(r(xi, yi + 1), r(xi + 1, yi + 1), u),
    v,
  );
}

/// 本次会话的主题安排：哪一段是哪个主题、权重多少。
class ChannelEnv {
  ChannelEnv._(this.order, {required this.fixed, required this.off});

  factory ChannelEnv.of(ChannelSettings s) {
    if (s.mode == ChannelMode.fixed) {
      return ChannelEnv._([s.fixed], fixed: true, off: false);
    }
    return ChannelEnv._(
      orderFor(s.pool, s.seed),
      fixed: false,
      off: s.mode == ChannelMode.off,
    );
  }

  /// 缩略图：整块只画一个主题。
  factory ChannelEnv.single(ChannelTheme t) =>
      ChannelEnv._([t], fixed: true, off: false);

  final List<ChannelTheme> order;
  final bool fixed;
  final bool off;

  ChannelTheme themeOf(int k) => order[modI(k, order.length)];
  double weight(int k, double y) => fixed ? 1 : ChannelGeo.zoneWeight(k, y);

  /// 种子洗牌（Fisher–Yates），按卡片顺序过滤后的池子；池子少于 2 个时用全部。
  static List<ChannelTheme> orderFor(Set<ChannelTheme> pool, int seed) {
    final ids = [
      for (final t in ChannelTheme.values)
        if (pool.length < 2 || pool.contains(t)) t,
    ];
    final r = ChannelRng(channelHash(['order', seed]));
    for (var i = ids.length - 1; i > 0; i--) {
      final j = (r() * (i + 1)).floor();
      final t = ids[i];
      ids[i] = ids[j];
      ids[j] = t;
    }
    return ids;
  }

  /// 从世界 y 所在段起往下的主题顺序（设置里“本次”、进入提示用）。
  List<ChannelTheme> sequenceFrom(double worldY, int count) {
    final k0 = ChannelGeo.zoneOf(worldY / ChannelGeo.decorScale);
    return [for (var i = 0; i < count; i++) themeOf(k0 + i)];
  }
}

Color lerpColor(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// 角度工具。
const tau = math.pi * 2;
