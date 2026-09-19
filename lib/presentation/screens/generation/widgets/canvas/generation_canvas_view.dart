import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/canvas_settings_provider.dart';
import '../../../../providers/generation/generation_models.dart';
import '../../../../providers/image_generation_provider.dart';
import '../../../../providers/generation/preview_selection_provider.dart';
import '../../../../widgets/common/selectable_image_card.dart';
import 'canvas_feed_layout.dart';
import 'canvas_tile_toolbar.dart';
import 'generated_image_card.dart';
import 'generation_canvas_controller.dart';

/// NAI5 自由画布视图（V2 重写版）。
///
/// 接管生成页中央预览区（含生成期）：全部生成图按批分组竖向铺开
/// （索引0=顶端=最新批，向下翻历史），生成中的批次以占位 tile 置顶渲染，
/// 响应后流式帧、完成落成新组，画布全程在位不卸载。
/// 世界坐标自然像素尺寸摆放，相机手势全集对标官网：
/// Ctrl+滚轮缩放 / 裸滚轮平移 / Shift+滚轮横移 / 中键或 Shift+左键拖 / 惯性 /
/// WASD 平移 / f 聚焦 / q 跳最新组 / +- 缩放 / 1=100% / Esc 清空。
///
/// 相机/布局纯函数分别见 generation_canvas_controller.dart /
/// canvas_feed_layout.dart，可 widget test。
class GenerationCanvasView extends ConsumerStatefulWidget {
  /// 完整生成状态：画布自行取 history/streamPreviewSlots/isGenerating 等。
  final ImageGenerationState generationState;

  const GenerationCanvasView({
    super.key,
    required this.generationState,
  });

  @override
  ConsumerState<GenerationCanvasView> createState() =>
      _GenerationCanvasViewState();
}

class _GenerationCanvasViewState extends ConsumerState<GenerationCanvasView>
    with TickerProviderStateMixin {
  late final GenerationCanvasController _controller;
  final FocusNode _focusNode = FocusNode(debugLabel: 'generation-canvas');
  ProviderSubscription<String?>? _selectionSub;

  /// 完整组序列（新→旧，索引 0 = 最新批/置顶 inflight）。
  List<CanvasGroup> _allGroups = [];

  /// 已露出布局的组（懒露出窗口尾部，新→旧）。
  List<CanvasGroup> _groups = [];
  List<CanvasPlacement> _placements = [];
  Map<CanvasGroup, Rect> _groupRects = {};
  Size _viewportSize = Size.zero;

  /// 上一次 feed 首组 key（用于新批/在飞组落地自动飞）
  String? _lastHeadGroupKey;
  bool _initialFlyDone = false;
  bool _pendingHeadGroupFly = false;

  // 120ms 停稳自动选中
  Timer? _settleTimer;
  static const _settleDelay = Duration(milliseconds: 120);

  // 迷失恢复：视口内无可见 tile 且相机停稳 2s → 飞回内容
  Timer? _lostTimer;
  static const _lostDelay = Duration(seconds: 2);

  // 中键/Shift+左键拖拽
  Offset? _lastPanPosition;
  int? _panPointer;
  final List<(Offset, DateTime)> _panTrail = [];

  // 当前布局使用的展开组 key（用于 build 期检测组选中变化重排）
  String? _layoutExpandedKey;

  // 组覆盖层工具条 items 缓存：buildCanvasToolbarItems 逐帧重建会让
  // 每个相机 tick 都重跑注册表；数据变化（recomputeLayout）时统一失效。
  final Map<String, List<CanvasToolbarItem>> _toolbarItemsCache = {};

  // 懒露出窗口：初渲只布局前 N 组，视口底接近内容底（<800px）时增量露出
  // 更老的组（对标官网无限滚动触底翻页；我方历史为内存态 take(50)，
  // 此窗口等价提供「触底再露出」的浏览手感与初始布局成本控制）。
  int _visibleGroupCount = 12;
  static const int _initialVisibleGroups = 12;
  static const int _visibleGroupsGrowBy = 8;
  static const double _bottomRevealThreshold = 800.0;

  // WASD 按住键集合（screen 方向）
  final Set<LogicalKeyboardKey> _heldKeys = {};

  @override
  void initState() {
    super.initState();
    _controller = GenerationCanvasController(vsync: this);
    _controller.addListener(_scheduleSettle);
    // 外部选中变化（历史面板点击/方向键/详情返回）→ 画布联动飞到对应 tile。
    // 选中值是 tile 级 image.id（画布内部再转成组级）。
    _selectionSub = ref.listenManual(generationPreviewSelectionProvider, (
      _,
      selectedId,
    ) {
      if (selectedId != null) _flyToImage(selectedId);
    });
    _layoutExpandedKey = ref.read(generationCanvasGroupSelectionProvider);
    _controller.reducedMotion = ref.read(canvasReducedMotionNotifierProvider);
    _recomputeLayout();
  }

  @override
  void didUpdateWidget(GenerationCanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.generationState, widget.generationState)) {
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

  // ============================ 布局与数据 ============================

  /// feed 数据源：current+history 去重（新→旧），顶部=最新批。
  /// 生成中批次以占位槽组成 inflight 组置顶。
  List<GeneratedImage> get _feedImages =>
      widget.generationState.mergedPanelImages;

  void _recomputeLayout() {
    final state = widget.generationState;
    final feed = _feedImages;

    // 懒露出窗口保持：先按 key 集增量露出已存在的窗口，再覆盖当前数据。
    _allGroups = groupCanvasImages(feed);
    // 生成期：inflight 组置顶（新批在 feed 顶部）
    if (state.isGenerating) {
      final bw = state.batchWidth;
      final bh = state.batchHeight;
      if (bw != null && bh != null && bw > 0 && bh > 0) {
        final tileW = bw.toDouble();
        final tileH = bh.toDouble();
        final slots = state.streamPreviewSlots.isNotEmpty
            ? state.streamPreviewSlots
            : [
                // 响应未回：按 totalImages 合成纯占位槽（加载图标）
                for (var i = 1; i <= state.totalImages; i++)
                  StreamPreviewSlot(
                    imageNumber: i,
                    totalImages: state.totalImages,
                    progress: 0.0,
                  ),
              ];
        if (slots.isNotEmpty) {
          _allGroups.insert(
            0,
            inflightGroup(
              slots: slots,
              tileWidth: tileW,
              tileHeight: tileH,
            ),
          );
        }
      }
    }

    // 懒露出：上次已露出的组（按 key）+ 头部补足到 _visibleGroupCount。
    // 换批后组对象重建，用 key 集判定哪些历史组已露出过。
    final previousKeys = {for (final g in _groups) g.key};
    final visible = <CanvasGroup>[];
    for (final g in _allGroups) {
      if (visible.length < _visibleGroupCount || previousKeys.contains(g.key)) {
        visible.add(g);
      }
    }
    _visibleGroupCount = math.max(
      _visibleGroupCount,
      previousKeys.isEmpty ? _initialVisibleGroups : visible.length,
    );
    _groups = visible;
    // 组数据可能变化（filePath 回写等），工具条注册项按新数据重建。
    _toolbarItemsCache.clear();

    // 组级选中 → 该组进展开态（组内 tile 单行横排）。
    final result = layoutCanvasFeed(
      _groups,
      expandedGroupKey: _layoutExpandedKey,
    );
    _placements = result.placements;
    _groupRects = {for (final p in _placements) p.group: p.groupRect};
    if (_groups.isEmpty) {
      _lastHeadGroupKey = null;
      return;
    }
    final key = _groups.first.key;
    if (!_initialFlyDone) {
      _initialFlyDone = true;
      _lastHeadGroupKey = key;
      _pendingHeadGroupFly = true;
    } else if (key != _lastHeadGroupKey) {
      // 首组变化（含 inflight→run:X 无缝切换）：仅当首组尺寸变化或
      // 当前相机不在首组附近时才重飞，避免完成瞬间无意义抖动。
      _lastHeadGroupKey = key;
      _pendingHeadGroupFly = true;
    }
  }

  /// 选中联动：外部 tile 级选中 → 同步组级（官网语义=选中 tile 所属组），
  /// 再飞到该 tile。tile 不在 feed（被清理等）静默忽略。
  void _flyToImage(String imageId) {
    for (final p in _placements) {
      final image = p.tile.image;
      if (image != null && image.id == imageId) {
        if (ref.read(generationCanvasGroupSelectionProvider) != p.group.key) {
          ref
              .read(generationCanvasGroupSelectionProvider.notifier)
              .select(p.group.key);
        }
        _controller.flyToRect(p.rect, _viewportSize, instant: false);
        return;
      }
    }
  }

  // ============================ 相机停稳后处理 ============================

  void _scheduleSettle() {
    _settleTimer?.cancel();
    _settleTimer = Timer(_settleDelay, _onCameraSettled);
    _lostTimer?.cancel();
  }

  void _onCameraSettled() {
    _armLostRecovery();
    _autoSelectNearest();
    _maybeRevealMore();
  }

  /// 无限滚动等价物：视口底距内容底 <800px → 露出更老的组。
  /// 历史为内存态 take(50) 无分页源，此窗口提供同语义的触底增量露出。
  void _maybeRevealMore() {
    if (_groups.length >= _allGroups.length) return;
    if (_viewportSize.isEmpty || _groups.isEmpty) return;
    final lastRect = _groupRects[_groups.last];
    if (lastRect == null) return;
    final visible = _controller.camera.visibleWorldRect(_viewportSize);
    if (visible.bottom > lastRect.bottom - _bottomRevealThreshold) {
      _visibleGroupCount += _visibleGroupsGrowBy;
      setState(_recomputeLayout);
    }
  }

  /// 相机停稳后自动选中离视口中心最近的 tile（跳过在飞槽位）。
  void _autoSelectNearest() {
    if (_placements.isEmpty || _viewportSize.isEmpty) return;
    final cam = _controller.camera;
    final centerWorld = cam.screenToWorld(_viewportSize.center(Offset.zero));
    final visible = cam.visibleWorldRect(_viewportSize).inflate(80);

    CanvasPlacement? best;
    var bestDist = double.infinity;
    for (final p in _placements) {
      if (p.isInFlight) continue; // 生成中占位不参与选中
      if (!p.rect.overlaps(visible)) continue;
      final d = (p.rect.center - centerWorld).distance;
      if (d < bestDist) {
        bestDist = d;
        best = p;
      }
    }
    if (best != null) {
      // 组级选中：官网语义是选中 tile 所属组，工具条跟组走。
      final groupKey = best.group.key;
      if (ref.read(generationCanvasGroupSelectionProvider) != groupKey) {
        ref.read(generationCanvasGroupSelectionProvider.notifier).select(groupKey);
      }
      // tile 级 provider 同步成组内首图，保持历史面板/详情等外部联动一致。
      final firstImage = best.group.tiles
          .map((t) => t.image)
          .whereType<GeneratedImage>()
          .firstOrNull;
      if (firstImage != null &&
          ref.read(generationPreviewSelectionProvider) != firstImage.id) {
        ref
            .read(generationPreviewSelectionProvider.notifier)
            .select(firstImage.id);
      }
    }
  }

  /// 视口内无任何可见 tile → 2s 后飞回离中心最近的组。
  void _armLostRecovery() {
    _lostTimer?.cancel();
    if (_placements.isEmpty || _viewportSize.isEmpty) return;
    final visible = _controller.camera.visibleWorldRect(_viewportSize);
    final anyVisible = _groupRects.values.any((r) => r.overlaps(visible));
    if (anyVisible) return;
    _lostTimer = Timer(_lostDelay, _recoverFromLost);
  }

  void _recoverFromLost() {
    if (!mounted || _groups.isEmpty || _viewportSize.isEmpty) return;
    final cam = _controller.camera;
    final centerWorld = cam.screenToWorld(_viewportSize.center(Offset.zero));
    var best = _groups.first;
    var bestDist = double.infinity;
    for (final g in _groups) {
      final r = _groupRects[g];
      if (r == null) continue;
      final d = (r.center - centerWorld).distance;
      if (d < bestDist) {
        bestDist = d;
        best = g;
      }
    }
    final rect = _groupRects[best];
    if (rect != null) {
      _controller.flyToRect(rect, _viewportSize);
    }
  }

  void _flyToHeadGroup() {
    if (_groups.isEmpty) return;
    final rect = _groupRects[_groups.first];
    if (rect != null) {
      _controller.flyToRect(rect, _viewportSize, instant: false);
    }
  }

  // ============================ 手势 ============================

  /// 锁相机（官网 `canvasLockCamera`）：禁用一切手动相机输入。
  /// 程序化飞行（f/q/选中联动/防迷失/新批自动飞）不在此列。
  bool get _cameraLocked => ref.read(canvasLockCameraNotifierProvider);

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (_cameraLocked) return;
      final pos = event.localPosition;
      if (HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed) {
        // 触控板捏合/平滑滚动（|deltaY|<50）走增量缩放，鼠标离散步进
        final dy = event.scrollDelta.dy.abs();
        if (dy < 50 && dy > 0.01) {
          // 平滑：官网 exp(clamp(-0.01·deltaY, ±0.25)) 增量直写
          final factor = math.exp(
            (-0.01 * event.scrollDelta.dy).clamp(-0.25, 0.25),
          );
          _controller.smoothZoomAt(pos, factor);
        } else {
          _controller.discreteZoomAt(pos, zoomIn: event.scrollDelta.dy < 0);
        }
      } else if (HardwareKeyboard.instance.isShiftPressed) {
        _controller.haltMotion();
        _controller.panBy(Offset(-event.scrollDelta.dy, 0));
      } else {
        _controller.haltMotion();
        _controller.panBy(
          Offset(-event.scrollDelta.dx, -event.scrollDelta.dy),
        );
      }
    }
  }

  bool _isPanPointer(PointerDownEvent e) {
    if (e.buttons & kMiddleMouseButton != 0) return true;
    if (e.buttons & kPrimaryMouseButton != 0 &&
        HardwareKeyboard.instance.isShiftPressed) {
      return true;
    }
    return false;
  }

  void _onPointerDown(PointerDownEvent e) {
    _focusNode.requestFocus();
        if (!_cameraLocked && _isPanPointer(e)) {
      _panPointer = e.pointer;
      _lastPanPosition = e.position;
      _panTrail.clear();
      _panTrail.add((e.position, DateTime.now()));
      _controller.haltMotion();
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_panPointer != e.pointer || _lastPanPosition == null) return;
    final delta = e.position - _lastPanPosition!;
    _lastPanPosition = e.position;
    _panTrail.add((e.position, DateTime.now()));
    if (_panTrail.length > 8) _panTrail.removeAt(0);
    _controller.panBy(delta);
  }

  void _onPointerUp(PointerUpEvent e) {
        if (_panPointer == e.pointer) {
      _panPointer = null;
      _lastPanPosition = null;
      _flingFromTrail();
      _panTrail.clear();
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
        if (_panPointer == e.pointer) {
      _panPointer = null;
      _lastPanPosition = null;
      _panTrail.clear();
    }
  }

  void _flingFromTrail() {
    if (_panTrail.length < 2) return;
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(milliseconds: 100));
    final samples = _panTrail.where((s) => s.$2.isAfter(cutoff)).toList();
    if (samples.length < 2) return;
    final dt = samples.last.$2.difference(samples.first.$2).inMilliseconds;
    if (dt <= 0) return;
    final v = (samples.last.$1 - samples.first.$1) / dt.toDouble();
    _controller.fling(v);
  }

  // ============================ 键盘 ============================

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyDownEvent) {
      if (key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight) {
        return KeyEventResult.ignored;
      }
      switch (key) {
        case LogicalKeyboardKey.keyW:
        case LogicalKeyboardKey.keyA:
        case LogicalKeyboardKey.keyS:
        case LogicalKeyboardKey.keyD:
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.arrowDown:
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.arrowRight:
          if (_cameraLocked) return KeyEventResult.ignored;
          _heldKeys.add(key);
          _updatePanTicker();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyF:
          _flyToFocusGroup();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyQ:
          _flyToHeadGroup();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.equal:
        case LogicalKeyboardKey.numpadAdd:
          if (_cameraLocked) return KeyEventResult.ignored;
          _controller.keyboardZoom(_viewportSize, zoomIn: true);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.minus:
        case LogicalKeyboardKey.numpadSubtract:
          if (_cameraLocked) return KeyEventResult.ignored;
          _controller.keyboardZoom(_viewportSize, zoomIn: false);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.digit1:
        case LogicalKeyboardKey.numpad1:
          if (_cameraLocked) return KeyEventResult.ignored;
          _controller.resetZoom(_viewportSize);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.escape:
          // 组级选中态清空（画布内部），tile 级同步清空
          ref.read(generationCanvasGroupSelectionProvider.notifier).clear();
          ref.read(generationPreviewSelectionProvider.notifier).clear();
          return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (event is KeyUpEvent) {
      if (key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight) {
        return KeyEventResult.ignored;
      }
      if (_heldKeys.remove(key)) {
        _updatePanTicker();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _updatePanTicker() {
    
    var dx = 0.0, dy = 0.0;
    for (final k in _heldKeys) {
      switch (k) {
        case LogicalKeyboardKey.keyW:
        case LogicalKeyboardKey.arrowUp:
          dy += 1; // W = 看上方内容 = 视口下移 = offset +y
          break;
        case LogicalKeyboardKey.keyS:
        case LogicalKeyboardKey.arrowDown:
          dy -= 1;
          break;
        case LogicalKeyboardKey.keyA:
        case LogicalKeyboardKey.arrowLeft:
          dx += 1;
          break;
        case LogicalKeyboardKey.keyD:
        case LogicalKeyboardKey.arrowRight:
          dx -= 1;
          break;
        default:
          break;
      }
    }
    _controller.setPanDirection(Offset(dx, dy));
  }

  void _flyToFocusGroup() {
    // f = 飞到当前选中组；组级选中优先，无选中回退 tile 级 → 首组
    final groupKey = ref.read(generationCanvasGroupSelectionProvider);
    final selectedId = ref.read(generationPreviewSelectionProvider);
    CanvasGroup? target;
    if (groupKey != null) {
      for (final g in _groups) {
        if (g.key == groupKey) {
          target = g;
          break;
        }
      }
    }
    if (target == null && selectedId != null) {
      for (final p in _placements) {
        final image = p.tile.image;
        if (image != null && image.id == selectedId) {
          target = p.group;
          break;
        }
      }
    }
    target ??= _groups.isNotEmpty ? _groups.first : null;
    if (target == null) return;
    final rect = _groupRects[target];
    if (rect != null) {
      _controller.flyToRect(rect, _viewportSize);
    }
  }

  // ============================ 构建 ============================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 减动效（canvasReducedMotion）：即时写入控制器，飞行/缩放/惯性瞬移。
    _controller.reducedMotion = ref.watch(canvasReducedMotionNotifierProvider);
    // 组选中变化 → 重排（展开态切换）。选中值本身 tile 渲染里再 watch。
    final groupSel = ref.watch(generationCanvasGroupSelectionProvider);
    if (groupSel != _layoutExpandedKey) {
      _layoutExpandedKey = groupSel;
      _recomputeLayout();
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _viewportSize = constraints.biggest;

          // 首组变化自动飞（post-frame，避免 build 期触发 notify）
          if (_pendingHeadGroupFly && _groups.isNotEmpty) {
            _pendingHeadGroupFly = false;
            final rect = _groupRects[_groups.first];
            if (rect != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _controller.flyToRect(
                  rect,
                  _viewportSize,
                  instant: false,
                );
              });
            }
          }

          return ClipRect(
            child: MouseRegion(
              cursor: _panPointer != null
                  ? SystemMouseCursors.grabbing
                  : SystemMouseCursors.grab,
              child: Listener(
                onPointerSignal: _onPointerSignal,
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: Container(
                  color: theme.colorScheme.surfaceContainerLowest,
                  child: Stack(
                    children: [
                      // 世界层：Transform(offset+scale) 承载全部 tile。
                      // 关键性能结构：tile Stack 挂在 AnimatedBuilder.child——
                      // 相机每个 tick 只更新 Transform 的 RenderObject 矩阵，
                      // 子树 widget 实例不变 → element 零重建（对标官网
                      // 「相机直写 style.transform 不走 React 渲染」）。
                      // tile 列表只在 setState（布局/选中变化）时重建。
                      AnimatedBuilder(
                        animation: _controller,
                        // 世界层 Stack 尺寸=视口、原点在左上，tile 世界坐标
                        // 以 x=0 居中（负 x 占半幅）——默认 hardEdge 会把
                        // 负 x 部分裁掉，必须 Clip.none；视口裁剪交给外层。
                        // 不再按相机可见性剔除：child 不逐帧重建，剔除失去
                        // 意义；Flutter paint 阶段天然跳过屏外元素。
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final p in _placements)
                              Positioned.fromRect(
                                rect: p.rect,
                                child: _buildTile(p),
                              ),
                          ],
                        ),
                        builder: (context, world) {
                          final cam = _controller.camera;
                          return Transform(
                            transform: Matrix4.identity()
                              ..translateByDouble(
                                cam.offset.dx,
                                cam.offset.dy,
                                0,
                                1,
                              )
                              ..scaleByDouble(cam.scale, cam.scale, 1, 1),
                            alignment: Alignment.topLeft,
                            child: world,
                          );
                        },
                      ),
                      // 组展开态覆盖层：屏幕空间 UI（头部条+工具条），
                      // 不随 Transform——屏幕恒定尺寸天然成立，无需反缩放。
                      // 每帧只重建这俩轻量条的位置，不碰 tile 树。
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => _buildScreenSpaceOverlays(),
                      ),
                      // 空态
                      if (_placements.isEmpty)
                        Center(
                          child: Text(
                            '暂无生成记录',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      // 官网画布无缩放控制条，HUD 去除
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 组展开态覆盖层（屏幕空间）：选中组的头部条挂组上方、工具条挂组下方。
  /// 不随世界 Transform——屏幕恒定尺寸天然成立；每帧只按相机投影重算
  /// 两个条的位置，tile 树完全不参与。
  Widget _buildScreenSpaceOverlays() {
    if (_viewportSize.isEmpty) return const SizedBox.shrink();
    final cam = _controller.camera;
    CanvasGroup? group;
    for (final g in _groups) {
      if (_layoutExpandedKey == g.key && !g.isInFlight) {
        group = g;
        break;
      }
    }
    if (group == null) return const SizedBox.shrink();
    final worldRect = _groupRects[group];
    if (worldRect == null) return const SizedBox.shrink();

    // 世界 rect → 屏幕 rect（相机 offset+scale 投影）
    final topLeft = cam.worldToScreen(worldRect.topLeft);
    final bottomRight = cam.worldToScreen(worldRect.bottomRight);
    final screenRect = Rect.fromPoints(topLeft, bottomRight);
    // 完全在视口外就不画（屏幕空间下可直接用视口 rect 判）
    if (!screenRect.overlaps(Offset.zero & _viewportSize)) {
      return const SizedBox.shrink();
    }

    final firstImage = group.tiles
        .map((t) => t.image)
        .whereType<GeneratedImage>()
        .firstOrNull;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 底部工具条：作用于组内首图，屏幕恒定尺寸（位置随相机每帧刷新）。
        // 官网组顶无 run/张数头部条（顶部栏为工具条与展开态 chips，R3/A2 再补）。
        if (firstImage != null)
          Positioned(
            left: screenRect.center.dx,
            top: screenRect.bottom + 10,
            child: FractionalTranslation(
              translation: const Offset(-0.5, 0),
              child: CanvasTileToolbar(
                items: _toolbarItemsCache.putIfAbsent(
                  group.key,
                  () => buildCanvasToolbarItems(
                    context: context,
                    ref: ref,
                    image: firstImage,
                  ),
                ),
                // 可用屏宽 = 组投影宽度（屏幕空间下无需反缩放换算）。
                maxWidth: math.max(120.0, screenRect.width - 24),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTile(CanvasPlacement p) {
    final tile = p.tile;
    final slot = tile.slot;
    if (slot != null) {
      // 生成中 tile：批参数尺寸 + 流式帧/加载占位
      return SelectableImageCard(
        isGenerating: true,
        progress: slot.progress,
        currentImage: slot.imageNumber,
        totalImages: widget.generationState.totalImages,
        streamPreview: slot.previewBytes,
        imageWidth: widget.generationState.batchWidth,
        imageHeight: widget.generationState.batchHeight,
        showIndex: false,
        enableContextMenu: false,
        enableHoverScale: false,
        enableGlossEffect: false,
        enableSelection: false,
        enableSaveAction: false,
        enableCopyAction: false,
        hoverEffectsEnabled: false,
        shareWarmupEnabled: false,
        hideSelectionDecoration: true,
      );
    }
    final image = tile.image!;
    final selectedGroupKey = ref.watch(generationCanvasGroupSelectionProvider);
    final selectedImageId = ref.watch(generationPreviewSelectionProvider);
    return RepaintBoundary(
      child: buildGeneratedImageCard(
        context: context,
        ref: ref,
        image: image,
        showIndex: false,
        canvasTile: true, // 轻量模式：关 hover/gloss/预热/拖拽包装
        enableHoverScale: false, // 世界空间内 hover 放大等于挪世界，禁用
        // 组级选中态：组内任一 tile 命中即整组高亮（卡片描边仍按 tile 级）
        isSelected:
            p.group.key == selectedGroupKey || image.id == selectedImageId,
        onTap: () => _onTileTap(p),
      ),
    );
  }

  /// 画布内点 tile：选中所属组（组级），tile 级 provider 同步为该图。
  /// 不弹全屏详情（右键菜单仍兜底）。
  void _onTileTap(CanvasPlacement p) {
    ref
        .read(generationCanvasGroupSelectionProvider.notifier)
        .select(p.group.key);
    final image = p.tile.image;
    if (image != null) {
      ref.read(generationPreviewSelectionProvider.notifier).select(image.id);
    }
  }

}
