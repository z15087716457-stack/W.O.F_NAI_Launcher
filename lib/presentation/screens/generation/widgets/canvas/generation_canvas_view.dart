import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/localization_extension.dart';
import '../../../../providers/generation/generation_models.dart';
import '../../../../providers/generation/preview_selection_provider.dart';
import 'canvas_feed_layout.dart';
import 'generated_image_card.dart';
import 'generation_canvas_controller.dart';

/// G11 NAI5 自由画布视图（V1）。
///
/// 接管生成页中央预览区：全部生成图按批分组竖向铺开（索引0=顶端=最新批，
/// 向下翻历史；2026-09-19 静拍板「新上旧下」，覆盖官网逆向「新图在下」），
/// 世界坐标自然像素尺寸摆放，相机手势全集对标官网：
///
/// - Ctrl+滚轮：以指针为锚离散缩放（×1.2/÷1.2，连滚复利）
/// - 裸滚轮：平移 (-dx,-dy)；Shift+滚轮：纵转横
/// - 中键 或 Shift+左键拖：平移（5px 死区），松手 <60ms 带速度进惯性甩动
/// - WASD：持续平移 1000px/s（对角归一）；f 飞聚焦组；q 飞最新组；
///   +/- 键盘缩放 ×1.3；1 回 100%；Esc 清选中
/// - 相机停稳 120ms：自动选中离视口中心最近 tile（预览选中态联动）
/// - 视野 2s 无内容：自动飞回最近组（防迷失）
/// - 新批落地：自动飞新组
/// - 剔除：只渲染可见世界矩形内的 tile
///
/// V1 未做：hover 工具条（SelectableImageCard 右键菜单兜底）、组展开、
/// Pins 钉板/探索货架、离屏跳针、无限滚动（history 只有内存 50 条）。
class GenerationCanvasView extends ConsumerStatefulWidget {
  const GenerationCanvasView({required this.images, super.key});

  /// feed 数据源：mergedPanelImages 顺序（当前批在前，history 新→旧），
  /// feed 顶部 = 最新批（索引0），向下滚动回到更早批次。
  final List<GeneratedImage> images;

  @override
  ConsumerState<GenerationCanvasView> createState() =>
      _GenerationCanvasViewState();
}

class _GenerationCanvasViewState extends ConsumerState<GenerationCanvasView>
    with TickerProviderStateMixin {
  late final GenerationCanvasController _controller;
  final FocusNode _focusNode = FocusNode(debugLabel: 'generation-canvas');
  ProviderSubscription<String?>? _selectionSub;

  List<CanvasGroup> _groups = const [];
  List<CanvasPlacement> _placements = const [];
  Map<CanvasGroup, Rect> _groupRects = const {};

  Size _viewportSize = Size.zero;

  // ---- 停稳自动选择 / 防迷失 ----
  Timer? _settleTimer;
  Timer? _lostTimer;
  static const _settleDelay = Duration(milliseconds: 120);
  static const _lostDelay = Duration(seconds: 2);

  // ---- 新批检测 ----
  String? _lastGroupKey;
  bool _initialFlyDone = false;
  bool _pendingNewGroupFly = false;

  // ---- 指针拖平移 ----
  int? _panPointer;
  Offset _panLast = Offset.zero;
  Offset _panAccum = Offset.zero;
  bool _panActive = false;
  Duration? _lastMoveTime;
  Offset _emaVelocity = Offset.zero; // px/ms
  bool _panningCursor = false;
  static const _dragDeadzone = 5.0;
  static const _flingReleaseWindow = Duration(milliseconds: 60);

  // ---- 键盘 ----
  final Set<LogicalKeyboardKey> _heldKeys = {};

  @override
  void initState() {
    super.initState();
    _controller = GenerationCanvasController(vsync: this);
    _controller.addListener(_scheduleSettle);
    // 历史面板/快捷键等外部选中变化 → 画布联动飞到对应 tile（对标官网联动）。
    // 自身 120ms 自动选中触发时 tile 已在视口中心，flyToRect 距离≈0 近似空操作。
    _selectionSub = ref.listenManual(generationPreviewSelectionProvider, (
      _,
      selectedId,
    ) {
      if (selectedId != null) _flyToImage(selectedId);
    });
    _recomputeLayout();
  }

  @override
  void didUpdateWidget(GenerationCanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.images, widget.images)) {
      _recomputeLayout();
    }
  }

  @override
  void dispose() {
    _selectionSub?.close();
    _settleTimer?.cancel();
    _lostTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _recomputeLayout() {
    // images 是新→旧（当前批在前），feed 顶部=最新批（索引0），向下翻历史。
    _groups = groupCanvasImages(widget.images);
    final result = layoutCanvasFeed(_groups);
    _placements = result.placements;
    _groupRects = {for (final p in _placements) p.group: p.groupRect};
    if (_groups.isEmpty) {
      _lastGroupKey = null;
      return;
    }
    final key = _groups.first.key;
    if (!_initialFlyDone) {
      _initialFlyDone = true;
      _lastGroupKey = key;
      _pendingNewGroupFly = true;
    } else if (key != _lastGroupKey) {
      _lastGroupKey = key;
      _pendingNewGroupFly = true;
    }
  }

  // ============ 相机停稳自动选择 + 防迷失 ============

  void _scheduleSettle() {
    _settleTimer?.cancel();
    _settleTimer = Timer(_settleDelay, _onCameraSettled);
  }

  void _onCameraSettled() {
    if (!mounted) return;
    if (_controller.isAnimating || _panPointer != null) {
      _scheduleSettle();
      return;
    }
    _autoSelectNearest();
    _armLostRecovery();
  }

  void _autoSelectNearest() {
    if (_placements.isEmpty) return;
    final cam = _controller.camera;
    final centerWorld = cam.screenToWorld(_viewportSize.center(Offset.zero));
    CanvasPlacement? best;
    var bestDist = double.infinity;
    for (final p in _placements) {
      final d = (p.rect.center - centerWorld).distanceSquared;
      if (d < bestDist) {
        bestDist = d;
        best = p;
      }
    }
    if (best == null) return;
    final bestId = best.image.id;
    final current = ref.read(generationPreviewSelectionProvider);
    if (current != bestId) {
      ref.read(generationPreviewSelectionProvider.notifier).select(bestId);
    }
  }

  void _armLostRecovery() {
    _lostTimer?.cancel();
    if (_groups.isEmpty) return;
    final visible = _controller.camera.visibleWorldRect(_viewportSize);
    final anyVisible = _groups.any(
      (g) => _groupRects[g]?.overlaps(visible) ?? false,
    );
    if (anyVisible) return;
    _lostTimer = Timer(_lostDelay, _recoverFromLost);
  }

  void _recoverFromLost() {
    if (!mounted || _groups.isEmpty) return;
    final visible = _controller.camera.visibleWorldRect(_viewportSize);
    if (_groups.any((g) => _groupRects[g]?.overlaps(visible) ?? false)) {
      return;
    }
    // 飞回离视口中心最近的组
    final cam = _controller.camera;
    final centerWorld = cam.screenToWorld(_viewportSize.center(Offset.zero));
    var best = _groups.first;
    var bestDist = double.infinity;
    for (final g in _groups) {
      final rect = _groupRects[g];
      if (rect == null) continue;
      final d = (rect.center - centerWorld).distanceSquared;
      if (d < bestDist) {
        bestDist = d;
        best = g;
      }
    }
    final target = _groupRects[best];
    if (target != null) _controller.flyToRect(target, _viewportSize);
  }

  // ============ 指针手势 ============

  void _onPointerDown(PointerDownEvent e) {
    _focusNode.requestFocus();
    final isMiddle = e.buttons & kMiddleMouseButton != 0;
    final isShiftLeft =
        e.buttons & kPrimaryMouseButton != 0 &&
        HardwareKeyboard.instance.isShiftPressed;
    if (!isMiddle && !isShiftLeft) return;

    _panPointer = e.pointer;
    _panLast = e.localPosition;
    _panAccum = Offset.zero;
    _panActive = false;
    _emaVelocity = Offset.zero;
    _lastMoveTime = null;
    _controller.haltMotion();
    _lostTimer?.cancel();
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (e.pointer != _panPointer) return;
    final stillPanning =
        e.buttons & kMiddleMouseButton != 0 ||
        (e.buttons & kPrimaryMouseButton != 0 &&
            HardwareKeyboard.instance.isShiftPressed);
    if (!stillPanning) {
      _endPan(e);
      return;
    }

    final delta = e.localPosition - _panLast;
    _panLast = e.localPosition;

    // 速度 EMA（官网 alpha = 1-exp(-dt/50)）
    final last = _lastMoveTime;
    _lastMoveTime = e.timeStamp;
    if (last != null) {
      final dtMs = (e.timeStamp - last).inMicroseconds / 1000.0;
      if (dtMs > 0) {
        final alpha = 1 - math.exp(-dtMs / 50.0);
        _emaVelocity =
            _emaVelocity * (1 - alpha) + (delta / dtMs) * alpha;
      }
    }

    // 5px 死区
    if (!_panActive) {
      _panAccum += delta;
      if (_panAccum.distance < _dragDeadzone) return;
      _panActive = true;
      if (!_panningCursor) {
        setState(() => _panningCursor = true);
      }
    }
    _controller.panBy(delta);
  }

  void _onPointerUp(PointerEvent e) {
    if (e.pointer != _panPointer) return;
    _endPan(e);
  }

  void _endPan(PointerEvent e) {
    // 松手 <60ms 内带速度 → 惯性甩动
    final last = _lastMoveTime;
    final releaseDt = last == null ? null : e.timeStamp - last;
    if (_panActive &&
        releaseDt != null &&
        releaseDt < _flingReleaseWindow &&
        _emaVelocity.distance > 0) {
      _controller.fling(_emaVelocity);
    }
    _panPointer = null;
    _panActive = false;
    _emaVelocity = Offset.zero;
    _lastMoveTime = null;
    if (_panningCursor) {
      setState(() => _panningCursor = false);
    }
  }

  void _onPointerSignal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed) {
      _controller.discreteZoomAt(
        e.localPosition,
        zoomIn: e.scrollDelta.dy < 0,
      );
    } else if (keyboard.isShiftPressed) {
      // 纵 delta 转横向
      _controller.panBy(Offset(-e.scrollDelta.dy, 0));
    } else {
      _controller.panBy(Offset(-e.scrollDelta.dx, -e.scrollDelta.dy));
    }
    _lostTimer?.cancel();
  }

  // ============ 键盘 ============

  KeyEventResult _onKeyEvent(KeyEvent e) {
    final key = e.logicalKey;
    if (e is KeyDownEvent) {
      if (_isWasdKey(key)) {
        if (_heldKeys.add(key)) _syncWasd();
        return KeyEventResult.handled;
      }
      return _handleActionKey(key);
    }
    if (e is KeyUpEvent) {
      if (_heldKeys.remove(key)) {
        _syncWasd();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  bool _isWasdKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.keyD;
  }

  void _syncWasd() {
    // 方向语义：W=画面上移（看上方内容，offset +y）、A=左移（offset +x）。
    // 对角归一化。
    final dx =
        (_heldKeys.contains(LogicalKeyboardKey.keyA) ? 1 : 0) -
        (_heldKeys.contains(LogicalKeyboardKey.keyD) ? 1 : 0);
    final dy =
        (_heldKeys.contains(LogicalKeyboardKey.keyW) ? 1 : 0) -
        (_heldKeys.contains(LogicalKeyboardKey.keyS) ? 1 : 0);
    var dir = Offset(dx.toDouble(), dy.toDouble());
    if (dir != Offset.zero && dir.distance > 1) {
      dir = dir / dir.distance;
    }
    _controller.setPanDirection(dir);
  }

  KeyEventResult _handleActionKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.keyF) {
      _flyToFocusGroup();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyQ) {
      _flyToLatestGroup();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd) {
      _controller.keyboardZoom(_viewportSize, zoomIn: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _controller.keyboardZoom(_viewportSize, zoomIn: false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit1 ||
        key == LogicalKeyboardKey.numpad1) {
      _controller.resetZoom(_viewportSize);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      ref.read(generationPreviewSelectionProvider.notifier).clear();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _flyToFocusGroup() {
    if (_groups.isEmpty) return;
    final selectedId = ref.read(generationPreviewSelectionProvider);
    if (selectedId != null) {
      for (final g in _groups) {
        if (g.images.any((img) => img.id == selectedId)) {
          final rect = _groupRects[g];
          if (rect != null) {
            _controller.flyToRect(rect, _viewportSize);
            return;
          }
        }
      }
    }
    _flyToLatestGroup();
  }

  void _flyToLatestGroup() {
    if (_groups.isEmpty) return;
    // 最新批在 feed 顶端（索引0）。
    final rect = _groupRects[_groups.first];
    if (rect != null) _controller.flyToRect(rect, _viewportSize);
  }

  /// 外部选中联动：飞到包含该图的 tile（比整组更聚焦，大图组不易偏）。
  /// tile 不在当前 feed（被清理等）时静默忽略。
  void _flyToImage(String imageId) {
    for (final p in _placements) {
      if (p.image.id == imageId) {
        _controller.flyToRect(p.rect, _viewportSize);
        return;
      }
    }
  }

  // ============ tile ============

  /// 画布内点 tile 只更新预览选中态，不弹全屏详情（右键菜单仍兜底）。
  void _onTileTap(GeneratedImage image) {
    ref.read(generationPreviewSelectionProvider.notifier).select(image.id);
  }

  Widget _buildTile(CanvasPlacement placement) {
    final image = placement.image;
    final selected = ref.watch(generationPreviewSelectionProvider) == image.id;
    return buildGeneratedImageCard(
      context: context,
      ref: ref,
      image: image,
      showIndex: false,
      isSelected: selected,
      enableHoverScale: false,
      onTap: () => _onTileTap(image),
    );
  }

  // ============ HUD ============

  Widget _buildZoomHud(CanvasCamera cam) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: const Icon(Icons.remove),
            tooltip: l10n.generation_canvasZoomOut,
            onPressed: () =>
                _controller.keyboardZoom(_viewportSize, zoomIn: false),
          ),
          SizedBox(
            width: 46,
            child: Text(
              '${(cam.scale * 100).round()}%',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: const Icon(Icons.add),
            tooltip: l10n.generation_canvasZoomIn,
            onPressed: () =>
                _controller.keyboardZoom(_viewportSize, zoomIn: true),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: const Icon(Icons.fit_screen),
            tooltip: l10n.generation_canvasFlyToLatest,
            onPressed: _flyToLatestGroup,
          ),
        ],
      ),
    );
  }

  // ============ build ============

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) => _onKeyEvent(event),
      onFocusChange: (hasFocus) {
        if (!hasFocus && _heldKeys.isNotEmpty) {
          _heldKeys.clear();
          _syncWasd();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          _viewportSize = constraints.biggest;

          // 新批落地自动飞（post-frame，避免 build 期触发 notify）
          if (_pendingNewGroupFly && _groups.isNotEmpty) {
            _pendingNewGroupFly = false;
            final rect = _groupRects[_groups.first];
            if (rect != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _controller.flyToRect(rect, _viewportSize);
              });
            }
          }

          return MouseRegion(
            cursor: _panningCursor
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.grab,
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerUp,
              onPointerSignal: _onPointerSignal,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final cam = _controller.camera;
                    final visibleWorld = cam.visibleWorldRect(_viewportSize);
                    final visible = _placements.where(
                      (p) => p.rect.overlaps(visibleWorld),
                    );

                    return Stack(
                      children: [
                        // 世界层：相机变换 + 世界坐标 Positioned tile
                        Transform(
                          transform: Matrix4.identity()
                            ..translateByDouble(
                              cam.offset.dx,
                              cam.offset.dy,
                              0,
                              1,
                            )
                            ..scaleByDouble(cam.scale, cam.scale, 1, 1),
                          alignment: Alignment.topLeft,
                          // 世界层 Stack：尺寸 = 视口约束、原点在左上，而 tile
                          // 世界坐标以 x=0 居中（负 x 占一半）。默认 hardEdge 会
                          // 把局部坐标 <0 的部分裁掉（tile 被啃左半），必须
                          // Clip.none——视口裁剪由外层 ClipRect 负责。
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (final p in visible)
                                Positioned.fromRect(
                                  rect: p.rect,
                                  child: _buildTile(p),
                                ),
                            ],
                          ),
                        ),
                        // 屏幕空间 HUD：缩放百分比 + 快捷按钮
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: _buildZoomHud(cam),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
