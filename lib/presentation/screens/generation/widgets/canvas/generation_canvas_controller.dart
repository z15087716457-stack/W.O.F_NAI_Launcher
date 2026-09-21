import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/canvas_settings_provider.dart';

/// 画布相机（G11 V3）：官网无限画布模型。
/// 官网真值（模块 22099 逐字核验）：
/// - 相机 = 世界→屏幕 平移+缩放，scale∈[0.1,8]，translate=x/y
/// - 焦点夺焦飞行 = 指数趋近 d += (t-d)·(1-exp(-dt·speed))，speed 默认 11
///   （官网 zoomBy 用 18；夺焦/居中用默认 11）
/// - 飞行目标距视口 >3×视口对角线 → 先把当前相机瞬移到目标近旁，
///   再飞向原目标（落点仍是精确目标）
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
    final next = math.min(maxScale, math.max(minScale, scale * factor));
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

  /// 停稳计时器：运动恢复即取消，避免飞行途中误触发 onIdle
  Timer? _idleTimer;
  Timer? _flyTimeout;

  @override
  CanvasCamera build() {
    ref.onDispose(() {
      _disposed = true;
      _idleTimer?.cancel();
      _flyTimeout?.cancel();
      _anim?.dispose();
      _anim = null;
    });
    return const CanvasCamera(offset: Offset(80, 40), scale: 1);
  }

  /// 供视图层注入 ticker
  void attachTicker(TickerProvider vsync) {
    _cancelMotion();
    _anim?.dispose();
    _anim = AnimationController(
      vsync: vsync,
      duration: const Duration(days: 1),
    );
  }

  /// 视图层销毁时释放 ticker（Notifier keepAlive 比 widget 命长）
  void disposeTicker() {
    _cancelMotion();
    _cancelIdle();
    _anim?.dispose();
    _anim = null;
  }

  void _notify() => onAnimationChanged?.call();

  /// 相机停稳调度（官网：停稳 120ms 后自动夺焦）；新运动重启计时
  void _settle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(milliseconds: 120), () {
      _idleTimer = null;
      if (_disposed) return;
      onIdle?.call();
    });
  }

  void _cancelIdle() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  /// 中止飞行：移除 tick、作废兜底超时与 onDone（取消不触发回调）
  void _cancelFly() {
    _flyTimeout?.cancel();
    _flyTimeout = null;
    _flyToken++;
    _anim?.removeListener(_flyTick);
    _flyStart = null;
    _flyTarget = null;
    _flyLast = null;
    _flyOnDone = null;
    _pendingZoomTarget = null;
  }

  /// 中止全部相机运动：手动输入（pan/jump/fling）优先于任何进行中的动画
  void _cancelMotion() {
    _cancelFly();
    _anim?.removeListener(_flingTick);
    _anim?.stop();
    _flingLast = null;
  }

  /// 指数趋近飞行（官网 z/flyToRect 内核）。
  ///
  /// [target] 目标相机；[speed] 每秒收敛速率（默认 11，zoomBy 用 18）；
  /// [duration] 建议上限（兜底截停，正常由收敛误差自然结束）。
  /// 减动效开启或 ticker 未挂载时立即落点（官网 canvasReducedMotion）。
  void flyTo(
    CanvasCamera target, {
    double speed = 11,
    Duration duration = const Duration(milliseconds: 500),
    VoidCallback? onDone,
  }) {
    if (_disposed) return;
    _cancelMotion();
    _cancelIdle();
    final bounded = CanvasCamera(
      offset: target.offset,
      scale: math.min(
        CanvasCamera.maxScale,
        math.max(CanvasCamera.minScale, target.scale),
      ),
    );
    final start = state;
    final anim = _anim;
    final reduced = ref.read(canvasReducedMotionNotifierProvider);
    final atTarget =
        (start.scale - bounded.scale).abs() < 1e-4 &&
        (start.offset - bounded.offset).distance < 0.5;
    if (reduced || atTarget || anim == null) {
      state = bounded;
      _notify();
      _settle();
      onDone?.call();
      return;
    }
    _notify();
    _flyStart = start;
    _flyTarget = bounded;
    _flySpeed = speed;
    _flyLast = null;
    _flyOnDone = onDone;
    anim
      ..reset()
      ..addListener(_flyTick)
      ..forward();
    final token = _flyToken;
    // 兜底截停：超时直接吸附到精确目标并收尾（回调只触发一次）
    _flyTimeout = Timer(duration + const Duration(milliseconds: 400), () {
      if (_disposed || token != _flyToken || _flyTarget == null) return;
      _finishFly();
    });
  }

  CanvasCamera? _flyStart;
  CanvasCamera? _flyTarget;
  double _flySpeed = 11;
  Duration? _flyLast;
  VoidCallback? _flyOnDone;
  int _flyToken = 0;

  /// 离散缩放累计基准：连续 zoomBy 以上一次尚未到达的目标为起点
  CanvasCamera? _pendingZoomTarget;

  void _flyTick() {
    final target = _flyTarget;
    if (_flyStart == null || target == null || _disposed) return;
    // 用 ticker 累计时长求 dt：fake time 下帧推进确定可测
    final elapsed = _anim?.lastElapsedDuration ?? Duration.zero;
    final last = _flyLast ?? elapsed;
    _flyLast = elapsed;
    final dt = (elapsed - last).inMicroseconds / 1e6;
    if (dt <= 0) return;
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
    final done =
        (target.offset.dx - next.offset.dx).abs() < 0.5 &&
        (target.offset.dy - next.offset.dy).abs() < 0.5 &&
        (target.scale - next.scale).abs() < 0.001;
    if (done) {
      _finishFly();
    } else {
      state = next;
    }
  }

  /// 飞行收尾：吸附到精确目标，通知+停稳+回调（自然收敛与兜底共用，只触发一次）
  void _finishFly() {
    final target = _flyTarget;
    if (target == null || _disposed) return;
    _flyTimeout?.cancel();
    _flyTimeout = null;
    _flyToken++;
    _anim?.stop();
    _anim?.removeListener(_flyTick);
    _flyStart = null;
    _flyTarget = null;
    _flyLast = null;
    _pendingZoomTarget = null;
    final cb = _flyOnDone;
    _flyOnDone = null;
    state = target;
    _notify();
    _settle();
    cb?.call();
  }

  /// 直接跳变（惯性每帧/拖拽）
  void jump(CanvasCamera next) {
    if (_disposed) return;
    _cancelMotion();
    state = next;
    _notify();
    _settle();
  }

  /// 官网 zoomBy：以屏幕锚点缩放，钳 [0.1,8]。
  ///
  /// [factor]>1 放大；[anchor] 视口内锚点（默认中心）；
  /// [smooth] 官网 Ctrl 平滑档：立即按锚点缩放不走飞行；
  /// 离散档走 flyTo 指数趋近（speed 18），连续触发累计到未完成的目标上。
  void zoomBy(double factor, {Offset? anchor, bool smooth = false}) {
    if (_disposed) return;
    final view = _viewportSize;
    if (view == null) return;
    final a = anchor ?? Offset(view.width / 2, view.height / 2);
    if (smooth) {
      _cancelMotion();
      final next = state.zoomAt(a, factor);
      if ((next.scale - state.scale).abs() < 1e-9) return;
      state = next;
      _notify();
      _settle();
      return;
    }
    final base = _pendingZoomTarget ?? state;
    final target = base.zoomAt(a, factor);
    if ((target.scale - base.scale).abs() < 1e-9) return;
    flyTo(target, speed: 18, duration: const Duration(milliseconds: 180));
    _pendingZoomTarget = target;
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

  /// 飞行前校正（官网快照语义：先算目标相机 s，远目标把当前相机瞬移到 s
  /// 近旁，再飞向 s）。
  ///
  /// 返回值始终是原始 [target]，保证 flyTo 落点精确；只有距离超过
  /// 3×视口对角线时才改写当前相机，且全程用「目标视口中心的世界点 →
  /// 当前相机屏幕位置」换算，两侧 scale 不同时坐标系仍一致。
  CanvasCamera adjustTargetForTeleport(CanvasCamera target, Size viewport) {
    if (_disposed) return target;
    final cur = state;
    final center = Offset(viewport.width / 2, viewport.height / 2);
    final targetScale = math.min(
      CanvasCamera.maxScale,
      math.max(CanvasCamera.minScale, target.scale),
    );
    final targetCenterWorld = (center - target.offset) / targetScale;
    final screenPos = cur.worldToScreen(targetCenterWorld);
    final gap = screenPos - center;
    final dist = gap.distance;
    final limit = 3 * Offset(viewport.width, viewport.height).distance;
    if (dist <= limit) return target;
    // 远目标：沿目标方向把当前相机瞬移到 limit 处（保持当前 scale），
    // 剩余路程交给 flyTo 指数趋近完成
    state = CanvasCamera(
      offset: cur.offset - gap * (1 - limit / dist),
      scale: cur.scale,
    );
    _notify();
    return target;
  }

  /// 惯性抛掷（中键拖拽松手）：官网 v 钳 4px/ms、摩擦 exp(-dt·5/1000)、<0.02 停
  void fling(Offset velocityPxPerMs, Size viewport) {
    if (_disposed) return;
    _cancelMotion();
    _cancelIdle();
    if (ref.read(canvasReducedMotionNotifierProvider) || _anim == null) {
      _notify();
      _settle();
      return;
    }
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
  Duration? _flingLast;

  void _flingTick() {
    if (_disposed) return;
    final elapsed = _anim?.lastElapsedDuration ?? Duration.zero;
    final last = _flingLast ?? elapsed;
    _flingLast = elapsed;
    final dt = (elapsed - last).inMilliseconds;
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
    if (_disposed) return;
    _cancelMotion();
    final cur = state;
    state = CanvasCamera(offset: cur.offset + delta, scale: cur.scale);
    _notify();
    _settle();
  }

  /// 世界 Y 轴整体偏移（官网 shiftWorldY）
  void shiftWorldY(double dy) {
    if (_disposed) return;
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
