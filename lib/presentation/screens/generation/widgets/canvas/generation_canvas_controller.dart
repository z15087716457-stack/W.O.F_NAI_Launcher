import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/canvas_settings_provider.dart';

/// 画布相机（G11 V3）：官网无限画布模型。
/// 官网真值（模块 22099 逐字核验）：
/// - 相机 = 世界→屏幕 平移+缩放，scale∈[0.1,8]，translate=x/y
/// - 焦点夺焦飞行 = 指数趋近 d += (t-d)·(1-exp(-dt·speed))，speed 默认 11
///   （官网 zoomBy 用 18；夺焦/居中用默认 11）
/// - 飞行目标距视口 >3×视口对角线 → 瞬移（官网把远目标直接拉进邻近象限）
/// - fitToRect：scale = min(fitMaxScale, 视口/rect)，fitMaxScale=放大填充开?∞:1
/// - 滚轮平移 → 停稳 120ms → 自动选中心距视口中心最近的组（没有"翻页"）
class CanvasCamera {
  const CanvasCamera({required this.offset, required this.scale});

  final Offset offset;
  final double scale;

  static const minScale = 0.1;
  static const maxScale = 8.0;
  static const init = CanvasCamera(offset: Offset.zero, scale: 1);

  /// 世界 → 屏幕：p·scale + offset
  Offset worldToScreen(Offset world) => world * scale + offset;

  /// 屏幕 → 世界：(p - offset) / scale
  Offset screenToWorld(Offset screen) => (screen - offset) / scale;

  /// 以屏幕锚点缩放（纯函数版本，官网 zoomBy 内核）
  CanvasCamera zoomAt(Offset anchor, double factor) {
    final next =
        math.min(maxScale, math.max(minScale, scale * factor));
    final wa = screenToWorld(anchor);
    return CanvasCamera(offset: anchor - wa * next, scale: next);
  }

  /// 可见世界矩形（剔除用）：视口四角屏幕→世界
  Rect visibleWorldRect(Size viewport) {
    final left = -offset.dx / scale;
    final top = -offset.dy / scale;
    return Rect.fromLTWH(
      left,
      top,
      viewport.width / scale,
      viewport.height / scale,
    );
  }
}

class GenerationCanvasCameraNotifier extends Notifier<CanvasCamera> {
  AnimationController? _anim;
  bool _disposed = false;

  /// 相机运动状态变更通知（惯性/飞行/缩放进行中）
  void Function()? onAnimationChanged;

  /// 相机停稳回调（官网：自动选最近组）
  void Function()? onIdle;

  DateTime _lastSettle = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  CanvasCamera build() {
    ref.onDispose(() {
      _disposed = true;
      _anim?.dispose();
    });
    return const CanvasCamera(offset: Offset(80, 40), scale: 1);
  }

  /// 供视图层注入 ticker
  void attachTicker(TickerProvider vsync) {
    _anim?.dispose();
    _anim = AnimationController(
      vsync: vsync,
      duration: const Duration(days: 1),
    );
  }

  /// 视图层销毁时释放 ticker（Notifier keepAlive 比 widget 命长）
  void disposeTicker() {
    _anim?.dispose();
    _anim = null;
  }

  void _notify() => onAnimationChanged?.call();

  void _settle() {
    _lastSettle = DateTime.now();
    // 官网：停稳 120ms 后自动夺焦
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_disposed) return;
      if (DateTime.now().difference(_lastSettle).inMilliseconds >= 120) {
        onIdle?.call();
      }
    });
  }

  /// 指数趋近飞行（官网 z/flyToRect 内核）。
  ///
  /// [target] 目标相机；[speed] 每秒收敛速率（默认 11，zoomBy 用 18）；
  /// [duration] 建议上限（兜底截停，正常由收敛误差自然结束）。
  /// 减动效开启时直接瞬移（官网 canvasReducedMotion）。
  void flyTo(
    CanvasCamera target, {
    double speed = 11,
    Duration duration = const Duration(milliseconds: 500),
    VoidCallback? onDone,
  }) {
    if (_disposed) return;
    _anim?.stop();
    _anim?.removeListener(_flingTick);
    final start = state;
    if ((start.scale - target.scale).abs() < 1e-4 &&
        (start.offset - target.offset).distance < 0.5) {
      state = target;
      onDone?.call();
      return;
    }
    if (ref.read(canvasReducedMotionNotifierProvider)) {
      state = target;
      _notify();
      _settle();
      onDone?.call();
      return;
    }
    _notify();
    _anim?.removeListener(_flyTick);
    _flyStart = start;
    _flyTarget = target;
    _flySpeed = speed;
    _flyLast = null;
    _flyOnDone = onDone;
    _anim
      ?..reset()
      ..addListener(_flyTick)
      ..forward();
    // 兜底截停
    Future.delayed(duration + const Duration(milliseconds: 400), () {
      if (_disposed || _flyTarget != target) return;
      if (state == target || _anim == null || !_anim!.isAnimating) return;
      _anim?.stop();
      _flyTick();
    });
  }

  CanvasCamera? _flyStart;
  CanvasCamera? _flyTarget;
  double _flySpeed = 11;
  DateTime? _flyLast;
  VoidCallback? _flyOnDone;

  void _flyTick() {
    final start = _flyStart;
    final target = _flyTarget;
    if (start == null || target == null || _disposed) return;
    final now = DateTime.now();
    final last = _flyLast ?? now;
    _flyLast = now;
    final dt = now.difference(last).inMicroseconds / 1e6;
    // 官网：i = 1 - exp(-r * speed)，r 钳 ≤0.034s
    final r = math.min(0.034, dt);
    final i = 1 - math.exp(-r * _flySpeed);
    final cur = state;
    final next = CanvasCamera(
      offset: Offset(
        cur.offset.dx + (target.offset.dx - cur.offset.dx) * i,
        cur.offset.dy + (target.offset.dy - cur.offset.dy) * i,
      ),
      scale: cur.scale + (target.scale - cur.scale) * i,
    );
    final done = (target.offset.dx - next.offset.dx).abs() < 0.5 &&
        (target.offset.dy - next.offset.dy).abs() < 0.5 &&
        (target.scale - next.scale).abs() < 0.001;
    state = done ? target : next;
    if (done) {
      _anim?.stop();
      _anim?.removeListener(_flyTick);
      _flyLast = null;
      final cb = _flyOnDone;
      _flyOnDone = null;
      _notify();
      _settle();
      cb?.call();
    }
  }

  /// 直接跳变（惯性每帧/拖拽）
  void jump(CanvasCamera next) {
    if (_disposed) return;
    _anim?.stop();
    _anim?.removeListener(_flyTick);
    _anim?.removeListener(_flingTick);
    state = next;
    _notify();
    _settle();
  }

  /// 官网 zoomBy：以屏幕锚点缩放，钳 [0.1,8]，指数趋近 speed=18。
  ///
  /// [factor]>1 放大；[anchor] 视口内锚点（默认中心）；[smooth] 官网 Ctrl 平滑档
  /// 用 rAF 每帧趋近（speed 18），离散档走 flyTo。
  void zoomBy(double factor, {Offset? anchor, bool smooth = false}) {
    final view = _viewportSize;
    if (view == null) return;
    final a = anchor ?? Offset(view.width / 2, view.height / 2);
    final cur = state;
    final next = math.min(
      CanvasCamera.maxScale,
      math.max(CanvasCamera.minScale, cur.scale * factor),
    );
    if ((next - cur.scale).abs() < 1e-9) return;
    final target = cur.zoomAt(a, factor);
    // 官网：平滑档与离散档都走指数趋近 speed 18；减动效由 flyTo 内部瞬移
    flyTo(
      target,
      speed: 18,
      duration: Duration(milliseconds: smooth ? 220 : 180),
    );
  }

  /// 官网 T()：fitToRect——rect 适配视口，留 5% 外边距 + UI chrome 扣减，
  /// 结果偏向「距当前视口中心最近」的放置。scale = min(fitMaxScale, m/w, f/h)。
  void fitToRect(
    Rect rect, {
    double fitMaxScale = 1.0,
    double margin = 20,
    Rect? chromeInset,
  }) {
    final view = _viewportSize;
    if (view == null) return;
    final n = view.width;
    final o = view.height;
    // 官网 5% 外边距 + chrome 扣减（此处近似：四边各 6 + 20 = 26）
    final chrome = chromeInset ?? Rect.zero;
    double side(double base, double extra) =>
        math.min(base + 6 + 20, math.max(base + 6, extra));
    final h = side(0.05 * n, chrome.left);
    final u = side(0.05 * n, chrome.right);
    final p = side(0.05 * o, chrome.top);
    final g = side(0.05 * o, chrome.bottom);
    final m = math.max(1.0, n - h - u);
    final f = math.max(1.0, o - p - g);
    final y = math.min(
      math.min(fitMaxScale, CanvasCamera.maxScale),
      math.max(
        CanvasCamera.minScale,
        math.min(m / rect.width, f / rect.height),
      ),
    );
    // 目标相机：rect 中心落在可用区中心（h + m/2, p + f/2）
    final tx = h + m / 2 - (rect.center.dx) * y;
    final ty = p + f / 2 - (rect.center.dy) * y;
    flyTo(CanvasCamera(offset: Offset(tx, ty), scale: y));
  }

  /// 飞行前校正：目标中心距视口中心 >3×视口 → 把目标拉回邻近象限（官网实锤）
  CanvasCamera adjustTargetForTeleport(
    CanvasCamera target,
    Size viewport,
  ) {
    final cur = state;
    final viewW = viewport.width;
    final viewH = viewport.height;
    // 当前相机下的目标屏幕中心 vs 目标相机下的目标屏幕中心
    final curMid = cur.offset + Offset(viewW / 2, viewH / 2);
    final tgtMid = target.offset + Offset(viewW / 2, viewH / 2);
    final dist = (tgtMid - curMid).distance;
    final limit = 3 * math.max(viewW, viewH);
    if (dist <= limit) return target;
    final t = limit / dist;
    final adjusted = Offset(
      tgtMid.dx - (tgtMid.dx - curMid.dx) * t,
      tgtMid.dy - (tgtMid.dy - curMid.dy) * t,
    );
    // 保持目标 scale，只把 offset 平移：世界锚点 = (adjustedCenter)/scale
    // 这里近似：按屏幕空间把 offset 差值缩回
    final adjOffset = Offset(
      target.offset.dx - (tgtMid.dx - adjusted.dx) * target.scale / cur.scale,
      target.offset.dy - (tgtMid.dy - adjusted.dy) * target.scale / cur.scale,
    );
    return CanvasCamera(offset: adjOffset, scale: target.scale);
  }

  /// 惯性抛掷（中键拖拽松手）：官网 v 钳 4px/ms、摩擦 exp(-dt·5/1000)、<0.02 停
  void fling(Offset velocityPxPerMs, Size viewport) {
    if (_disposed) return;
    if (ref.read(canvasReducedMotionNotifierProvider)) {
      _notify();
      _settle();
      return;
    }
    _anim?.stop();
    _anim?.removeListener(_flyTick);
    _anim?.removeListener(_flingTick);
    _notify();
    _flingLast = null;
    _flingVx = velocityPxPerMs.dx.clamp(-4.0, 4.0);
    _flingVy = velocityPxPerMs.dy.clamp(-4.0, 4.0);
    _anim
      ?..reset()
      ..addListener(_flingTick)
      ..forward();
  }

  double _flingVx = 0;
  double _flingVy = 0;
  DateTime? _flingLast;

  void _flingTick() {
    if (_disposed) return;
    final now = DateTime.now();
    final last = _flingLast ?? now;
    _flingLast = now;
    final dt = now.difference(last).inMilliseconds;
    if (dt <= 0) return;
    final cur = state;
    state = CanvasCamera(
      offset: cur.offset + Offset(_flingVx * dt, _flingVy * dt),
      scale: cur.scale,
    );
    // 摩擦 exp(-dt * 5 / 1000)
    final damp = math.exp(-dt * 5 / 1000);
    _flingVx *= damp;
    _flingVy *= damp;
    if (_flingVx.abs() < 0.02 && _flingVy.abs() < 0.02) {
      _anim?.stop();
      _anim?.removeListener(_flingTick);
      _flingLast = null;
      _notify();
      _settle();
    }
  }

  /// 平移增量（拖拽/滚轮平移），throttled 即 rAF 合并——Flutter 侧直接 setState 即可
  void panBy(Offset delta) {
    final cur = state;
    state = CanvasCamera(offset: cur.offset + delta, scale: cur.scale);
    _notify();
    _settle();
  }

  /// 世界 Y 轴整体偏移（官网 shiftWorldY）
  void shiftWorldY(double dy) {
    final cur = state;
    state = CanvasCamera(
      offset: Offset(cur.offset.dx, cur.offset.dy - dy * cur.scale),
      scale: cur.scale,
    );
    _notify();
  }

  Size? _viewportSize;
  void setViewport(Size size) => _viewportSize = size;

  /// 当前相机下的可见世界矩形（剔除用，委托 CanvasCamera）
  Rect visibleWorldRect(Size viewport) => state.visibleWorldRect(viewport);
}
