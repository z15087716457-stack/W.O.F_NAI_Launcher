import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 生成画布相机状态：{x, y, scale}，世界坐标 → 屏幕坐标
/// 变换为 `Transform` 的 `offset + scale`（transformOrigin 0,0）。
///
/// 对标 NAI5 官网 image-gen-canvas 的相机行为：
/// - 缩放钳制 [0.1, 8]
/// - 离散滚轮步进 ×1.2 / ÷1.2（×0.8333），平滑输入按指数增量
/// - 中键/Shift+左键拖平移，松手带速度进惯性甩动
/// - flyToRect 平滑飞行（距离过远直接瞬移）
@immutable
class CanvasCamera {
  const CanvasCamera({required this.offset, required this.scale});

  static const double minScale = 0.1;
  static const double maxScale = 8.0;
  static const double discreteZoomInFactor = 1.2;
  static const double discreteZoomOutFactor = 1 / 1.2;
  static const double keyboardZoomInFactor = 1.3;
  static const double keyboardZoomOutFactor = 1 / 1.3;

  final Offset offset;
  final double scale;

  CanvasCamera copyWith({Offset? offset, double? scale}) {
    return CanvasCamera(
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
    );
  }

  /// 屏幕点 → 世界点
  Offset screenToWorld(Offset screenPoint) {
    return (screenPoint - offset) / scale;
  }

  /// 世界点 → 屏幕点
  Offset worldToScreen(Offset worldPoint) {
    return worldPoint * scale + offset;
  }

  /// 以屏幕锚点为中心缩放
  CanvasCamera zoomAt(Offset screenAnchor, double newScale) {
    final clamped = newScale.clamp(minScale, maxScale);
    if (clamped == scale) return this;
    final worldAnchor = screenToWorld(screenAnchor);
    final newOffset = screenAnchor - worldAnchor * clamped;
    return copyWith(offset: newOffset, scale: clamped);
  }

  /// 平移（屏幕像素增量）
  CanvasCamera panBy(Offset delta) {
    return copyWith(offset: offset + delta);
  }

  /// 可见世界矩形
  Rect visibleWorldRect(Size viewportSize) {
    return Rect.fromLTWH(
      -offset.dx / scale,
      -offset.dy / scale,
      viewportSize.width / scale,
      viewportSize.height / scale,
    );
  }
}

/// 画布相机控制器。
///
/// 持有一个 AnimationController 供飞行/缩放动画与惯性共用；
/// WASD 持续平移用 Ticker。
class GenerationCanvasController extends ChangeNotifier {
  GenerationCanvasController({required TickerProvider vsync})
    : _camera = const CanvasCamera(offset: Offset.zero, scale: 1.0) {
    _flyController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );
    _flyController.addListener(_onFlyTick);
    _inertiaTicker = vsync.createTicker(_onInertiaTick);
    _panTicker = vsync.createTicker(_onPanTick);
  }

  late final AnimationController _flyController;
  late final Ticker _inertiaTicker;
  late final Ticker _panTicker;

  CanvasCamera _camera;
  CanvasCamera get camera => _camera;

  /// 减动效（官网 `canvasReducedMotion`）：true 时飞行/缩放动画与
  /// 惯性全部改为瞬移。视图层 watch 门控 provider 并写入此字段。
  bool reducedMotion = false;

  // 飞行/缩放动画
  Offset _flyFromOffset = Offset.zero;
  Offset _flyToOffset = Offset.zero;
  double _flyFromScale = 1.0;
  double _flyToScale = 1.0;
  bool _flying = false;
  Curve _flyCurve = Curves.easeInOutCubic;

  // 滚轮动画目标（连滚复利基值）
  double? _pendingZoomTarget;

  // 惯性
  Offset _inertiaVelocity = Offset.zero; // 屏幕 px / 秒
  Duration? _lastInertiaTime;

  // WASD 持续平移
  Offset _panDirection = Offset.zero; // 归一化方向（屏幕坐标系，每秒1000px）
  Duration? _lastPanTime;

  static const double inertiaMaxSpeed = 4000.0; // px/s（官网钳 4px/ms）
  static const double inertiaDecay = 5.0; // exp(-dt*5/1000) 等价每秒衰减
  static const double inertiaStopSpeed = 20.0; // px/s（官网 <0.02px/ms）
  static const double wasdSpeed = 1000.0; // px/s

  bool get isAnimating => _flying || _inertiaTicker.isActive;

  void _setCamera(CanvasCamera next) {
    if (next.offset == _camera.offset && next.scale == _camera.scale) return;
    _camera = next;
    notifyListeners();
  }

  /// 立即停止所有相机运动（拖动开始时调用）。
  void haltMotion() {
    _flyController.stop();
    _flying = false;
    _pendingZoomTarget = null;
    _inertiaTicker.stop();
    _inertiaVelocity = Offset.zero;
    _lastInertiaTime = null;
  }

  /// 平移（屏幕像素增量），同时打断动画与惯性。
  void panBy(Offset delta) {
    haltMotion();
    _setCamera(_camera.panBy(delta));
  }

  /// 惯性甩动：松手时调用。velocity 为屏幕 px/ms。
  /// 减动效下不产生惯性。
  void fling(Offset velocityPxPerMs) {
    if (reducedMotion) return;
    var speed = velocityPxPerMs.distance * 1000;
    if (speed <= 0 || speed < inertiaStopSpeed) return;
    speed = math.min(speed, inertiaMaxSpeed);
    _inertiaVelocity = velocityPxPerMs / velocityPxPerMs.distance * speed;
    _lastInertiaTime = null;
    _inertiaTicker.start();
  }

  void _onInertiaTick(Duration elapsed) {
    final last = _lastInertiaTime;
    _lastInertiaTime = elapsed;
    if (last == null) return;
    final dt = (elapsed - last).inMicroseconds / 1000.0; // ms
    if (dt <= 0) return;
    // 衰减：exp(-dt*5/1000)
    final decay = math.exp(-dt * inertiaDecay / 1000.0);
    _inertiaVelocity = _inertiaVelocity * decay;
    final speed = _inertiaVelocity.distance;
    if (speed < inertiaStopSpeed) {
      _inertiaTicker.stop();
      _inertiaVelocity = Offset.zero;
      return;
    }
    _setCamera(_camera.panBy(_inertiaVelocity * (dt / 1000.0)));
  }

  /// WASD 持续平移方向（-1..1 分量），零向量停 tick。
  void setPanDirection(Offset direction) {
    _panDirection = direction;
    if (direction == Offset.zero) {
      _panTicker.stop();
      _lastPanTime = null;
    } else {
      _lastPanTime = null;
      if (!_panTicker.isActive) _panTicker.start();
    }
  }

  void _onPanTick(Duration elapsed) {
    final last = _lastPanTime;
    _lastPanTime = elapsed;
    if (last == null) return;
    final dt = (elapsed - last).inMicroseconds / 1000000.0; // s
    if (dt <= 0) return;
    _setCamera(_camera.panBy(_panDirection * (wasdSpeed * dt)));
  }

  /// 离散滚轮缩放（步进复利），走 ~180ms 动画。
  /// [screenAnchor] 为指针当前屏幕坐标。
  void discreteZoomAt(Offset screenAnchor, {required bool zoomIn}) {
    final base = _pendingZoomTarget ?? _camera.scale;
    final target =
        (base *
                (zoomIn
                    ? CanvasCamera.discreteZoomInFactor
                    : CanvasCamera.discreteZoomOutFactor))
            .clamp(CanvasCamera.minScale, CanvasCamera.maxScale);
    _pendingZoomTarget = target;
    _animateTo(
      _camera.zoomAt(screenAnchor, target),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  /// 平滑滚轮/触控板缩放增量（throttled 直写）。
  void smoothZoomAt(Offset screenAnchor, double factor) {
    _flyController.stop();
    _flying = false;
    _pendingZoomTarget = null;
    _setCamera(_camera.zoomAt(screenAnchor, _camera.scale * factor));
  }

  /// 键盘缩放（视口中心为锚）。
  void keyboardZoom(Size viewportSize, {required bool zoomIn}) {
    final target =
        (_camera.scale *
                (zoomIn
                    ? CanvasCamera.keyboardZoomInFactor
                    : CanvasCamera.keyboardZoomOutFactor))
            .clamp(CanvasCamera.minScale, CanvasCamera.maxScale);
    _animateTo(
      _camera.zoomAt(viewportSize.center(Offset.zero), target),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  /// 回到 100%（视口中心为锚）。
  void resetZoom(Size viewportSize) {
    _animateTo(
      _camera.zoomAt(viewportSize.center(Offset.zero), 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  /// 飞到世界矩形：margin 边距、fitMaxScale 封顶放大倍率。
  /// 距离超 ~3×视口/scale 直接瞬移（官网同款）。
  void flyToRect(
    Rect worldRect,
    Size viewportSize, {
    double margin = 10,
    double fitMaxScale = 1.0,
    bool instant = false,
  }) {
    if (worldRect.isEmpty) return;
    final targetScale =
        math
            .min(
              (viewportSize.width - margin * 2) / worldRect.width,
              (viewportSize.height - margin * 2) / worldRect.height,
            )
            .clamp(CanvasCamera.minScale, fitMaxScale);
    final targetOffset =
        viewportSize.center(Offset.zero) - worldRect.center * targetScale;
    final target = CanvasCamera(offset: targetOffset, scale: targetScale);

    final distance = (targetOffset - _camera.offset).distance;
    final teleportThreshold =
        3.0 * (viewportSize.shortestSide) / _camera.scale.clamp(0.05, 8.0);
    if (instant || distance > teleportThreshold) {
      haltMotion();
      _setCamera(target);
      return;
    }
    _animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _animateTo(
    CanvasCamera target, {
    required Duration duration,
    required Curve curve,
  }) {
    if (reducedMotion) {
      haltMotion();
      _setCamera(target);
      return;
    }
    _inertiaTicker.stop();
    _inertiaVelocity = Offset.zero;
    _flyFromOffset = _camera.offset;
    _flyToOffset = target.offset;
    _flyFromScale = _camera.scale;
    _flyToScale = target.scale;
    _flyController
      ..stop()
      ..duration = duration;
    _flyCurve = curve;
    _flying = true;
    _flyController.forward(from: 0);
  }

  void _onFlyTick() {
    if (!_flying) return;
    final t = _flyCurve.transform(_flyController.value);
    _setCamera(
      CanvasCamera(
        offset: Offset.lerp(_flyFromOffset, _flyToOffset, t)!,
        scale: lerpDouble(_flyFromScale, _flyToScale, t)!,
      ),
    );
    if (_flyController.isCompleted) {
      _flying = false;
      _pendingZoomTarget = null;
    }
  }

  @override
  void dispose() {
    _flyController.removeListener(_onFlyTick);
    _flyController.dispose();
    _inertiaTicker.dispose();
    _panTicker.dispose();
    super.dispose();
  }
}
