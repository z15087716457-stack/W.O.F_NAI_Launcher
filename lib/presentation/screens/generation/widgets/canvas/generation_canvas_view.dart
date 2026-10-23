import '../../../../widgets/navigation/window_chrome_layout.dart';
import '../../../../widgets/common/resize_decoration_cache.dart';
import '../../../../providers/layout_state_provider.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/canvas_settings_provider.dart';
import '../../../../providers/canvas_channel_provider.dart';
import '../../../../providers/canvas_channel_feed_provider.dart';
import '../../../../ui/channel/channel_contract.dart';
import '../../../../ui/channel/channel_layer.dart';
import '../../../../ui/channel/channel_overlay.dart';
import '../../../../providers/generation/generation_models.dart';
import '../../../../providers/generation/preview_selection_provider.dart';
import '../../../../providers/image_generation_provider.dart';
import '../../../../providers/tips_provider.dart';
import '../../../../widgets/common/image_detail/image_detail_data.dart';
import '../../services/generation_save_service.dart';
import 'canvas_feed_layout.dart';
import 'canvas_world_viewport.dart';
import 'canvas_pixel_background.dart';
import '../../../../widgets/common/selectable_image_card.dart';
import 'canvas_tile_toolbar.dart';
import 'canvas_image_background.dart';
import 'generated_image_card.dart';
import 'generation_canvas_controller.dart';
import '../../../../../core/utils/localization_extension.dart';

/// 生成画布（G11 V3）：对标 NAI5 官网无限画布，逐字对码模块 22099。
/// - 世界层使用同一变换绘制与命中，相机动画不重建图片子树
/// - 交互：中键/Shift+左键拖平移（5px 死区）+松手惯性（v 钳 4px/ms、摩擦 exp(-dt·5/1000)）；
///   Ctrl+滚轮缩放（离散 ×1.2 / 平滑 exp(-0.01·dy)）；裸滚轮平移 + Shift 纵转横；
///   点击 tile 夺焦飞行（指数趋近 speed 11）；相机停稳 120ms 自动选中心最近组；
///   q 跳组；Home/End 首尾；Ctrl+0 复位；Ctrl+S 保存焦点图；双击空处切放大填充
/// - 视觉：非焦点 tile scale(0.98)、悬停回 1（0.25s cubic-bezier(.22,1,.36,1)）；
///   非焦点悬停出底部迷你条；焦点组出 top/bottom 边缘工具条
/// - 归组：组 = 一次生成请求（generationRunId），连续单张各自成组（官网原样）
class GenerationCanvasView extends ConsumerStatefulWidget {
  const GenerationCanvasView({
    required this.generationState,
    this.tileBuilder,
    this.focusInsets,
    this.deferKeyEvent,
    this.visualChannel = false,
    super.key,
  });

  final ImageGenerationState generationState;

  /// 嵌入新页面时只提供相机和世界布局，图片与外围界面由宿主管理。
  final Widget Function(
    BuildContext,
    CanvasFeedItem,
    bool,
    VoidCallback,
    bool Function(),
  )?
  tileBuilder;
  final EdgeInsets? focusInsets;
  final bool Function(KeyEvent)? deferKeyEvent;

  /// The main generation host opts in. Generic embedded previews remain bare.
  /// `embedded` controls legacy chrome, not this separately supplied decoration.
  final bool visualChannel;

  bool get embedded => tileBuilder != null;

  @override
  ConsumerState<GenerationCanvasView> createState() =>
      _GenerationCanvasViewState();
}

class _GenerationCanvasViewState extends ConsumerState<GenerationCanvasView>
    with TickerProviderStateMixin {
  Size _viewport = Size.zero;
  final _viewportKey = GlobalKey();
  final _topToolbarKey = GlobalKey();
  final _bottomStartToolbarKey = GlobalKey();
  final _bottomEndToolbarKey = GlobalKey();
  Rect _focusViewport = Rect.zero;
  bool _measureFocusPending = false;
  bool _focusFitActive = false;
  bool _syncingPreviewSelection = false;
  bool _manualOverview = false;

  // 官网 WASD 平移：1000px/s、对角归一、blur 清键
  final Set<LogicalKeyboardKey> _wasdKeys = {};
  Ticker? _wasdTicker;
  Duration _wasdLast = Duration.zero;

  // 防迷失：视口闲置且看不到内容 → 2s 后自动飞回最近组
  Timer? _lostTimer;

  /// 正在画布上按压的指针集合（平移/捏合判定）
  final Set<int> _pointers = {};

  /// 落在屏幕空间 UI（edge bars / 迷你条）上的指针集合——这些指针
  /// 不参与画布平移，松手后产生的 tap 也不进双击判定。
  final Set<int> _uiPointers = {};

  /// 本次按压中曾被 UI 消耗的指针（up 后保留到 tap 派发完毕）
  final Set<int> _consumedUiPointers = {};

  // 拖拽平移状态（官网 5px 死区 + 松手 <60ms 有速度则抛掷）
  Offset _panAccum = Offset.zero;
  bool _panActive = false;
  bool _suppressTileTap = false;
  DateTime? _lastPanAt;
  Offset _inertiaVelocity = Offset.zero;

  // 双击空处切放大填充（官网 dblclick 时序）
  Timer? _clickTimer;
  int _clickCount = 0;

  // dispose() 里 ref 已失效，相机 notifier 必须在 initState 缓存
  late final GenerationCanvasCameraNotifier _camera;

  // 画布独占焦点节点：不能复用 generationPreviewFocusNodeProvider——
  // 外层 PreviewNavShortcuts 已把它挂成 Focus，画布再嵌套使用会导致
  // "Tried to make a child into a parent of itself"（红屏断言）。
  late final FocusNode _canvasFocusNode;

  bool get _cameraLocked => ref.read(canvasLockCameraNotifierProvider);

  @override
  void initState() {
    super.initState();
    _camera = ref.read(generationCanvasCameraProvider.notifier);
    _canvasFocusNode = FocusNode(debugLabel: 'generation-canvas');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _camera.attachTicker(this);
      _camera.onIdle = _onCameraIdle;
      _camera.setViewport(_viewport);
      _syncSelectionToCamera();
    });
  }

  @override
  void dispose() {
    _clickTimer?.cancel();
    _lostTimer?.cancel();
    _wasdTicker?.dispose();
    _camera.onIdle = null;
    _camera.disposeTicker();
    _canvasFocusNode.dispose();
    super.dispose();
  }

  // ── 相机停稳 → 官网：自动选中心距视口中心最近的组（120ms 由控制器节流）──

  void _onCameraIdle() {
    if (_manualOverview) return;
    _autoSelectNearestGroup();
    _checkLostAndFlyBack();
  }

  /// 官网防迷失：视口闲置且看不到任何内容 → 2s 后自动飞回最近组。
  void _checkLostAndFlyBack() {
    _lostTimer?.cancel();
    if (_viewport.isEmpty) return;
    final layout = ref.read(canvasFeedLayoutProvider);
    if (layout.groups.isEmpty) return;
    final camera = ref.read(generationCanvasCameraProvider);
    final visible = camera.visibleWorldRect(_viewport);
    final anyVisible = layout.groups.any((g) {
      if (g.tiles.isEmpty) return false;
      final b = _groupBounds(layout, g);
      return !b.isEmpty && b.overlaps(visible);
    });
    if (anyVisible) return;
    _lostTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _viewport.isEmpty) return;
      final lo = ref.read(canvasFeedLayoutProvider);
      if (lo.groups.isEmpty) return;
      final cam = ref.read(generationCanvasCameraProvider);
      final vis = cam.visibleWorldRect(_viewport);
      final stillEmpty = lo.groups.every((g) {
        if (g.tiles.isEmpty) return true;
        final b = _groupBounds(lo, g);
        return b.isEmpty || !b.overlaps(vis);
      });
      if (!stillEmpty) return;
      // 飞回距视口中心最近的组（包括正在生成的占位组）
      final centerWorld = cam.screenToWorld(
        Offset(_viewport.width / 2, _viewport.height / 2),
      );
      String? bestKey;
      double best = double.infinity;
      for (final g in lo.groups) {
        if (g.tiles.isEmpty) continue;
        final b = _groupBounds(lo, g);
        if (b.isEmpty) continue;
        final d = (b.center - centerWorld).distance;
        if (d < best) {
          best = d;
          bestKey = g.key;
        }
      }
      if (bestKey == null) return;
      final g = lo.groups.firstWhere((x) => x.key == bestKey);
      ref
          .read(generationCanvasGroupSelectionProvider.notifier)
          .selectGroup(g.key);
      _syncPreviewToGroup(lo, g.key);
      _flyToGroup(lo, g);
    });
  }

  void _autoSelectNearestGroup() {
    if (_viewport.isEmpty) return;
    final layout = ref.read(canvasFeedLayoutProvider);
    if (layout.groups.isEmpty) return;
    final camera = ref.read(generationCanvasCameraProvider);
    final centerWorld = Offset(
      (_viewport.width / 2 - camera.offset.dx) / camera.scale,
      (_viewport.height / 2 - camera.offset.dy) / camera.scale,
    );
    String? bestKey;
    double best = double.infinity;
    for (final g in layout.groups) {
      if (g.tiles.isEmpty) continue;
      final bounds = _groupBounds(layout, g);
      if (bounds.isEmpty) continue;
      final d = (bounds.center - centerWorld).distance;
      if (d < best) {
        best = d;
        bestKey = g.key;
      }
    }
    if (bestKey == null) return;
    final cur = ref.read(generationCanvasGroupSelectionProvider);
    if (cur?.group != bestKey) {
      ref
          .read(generationCanvasGroupSelectionProvider.notifier)
          .selectGroup(bestKey);
      _syncPreviewToGroup(layout, bestKey);
    }
  }

  final _groupBoundsIndex = CanvasGroupBoundsIndex();

  Rect _groupBounds(CanvasFeedLayoutResult layout, CanvasFeedGroup g) =>
      _groupBoundsIndex.boundsOf(layout, g.key);

  void _syncSelectionToCamera() {
    final layout = ref.read(canvasFeedLayoutProvider);
    if (layout.groups.isEmpty) return;
    final focus = ref.read(generationCanvasGroupSelectionProvider);
    final g =
        layout.groups.where((x) => x.key == focus?.group).firstOrNull ??
        layout.groups.first;
    if (focus?.group != g.key) {
      ref
          .read(generationCanvasGroupSelectionProvider.notifier)
          .selectGroup(g.key);
      _syncPreviewToGroup(layout, g.key);
    }
    if (focus?.group == g.key && focus?.subimage != null) {
      _flyToSubimage(layout, g, focus!.subimage!);
    } else {
      _flyToGroup(layout, g);
    }
  }

  void _flyToGroup(CanvasFeedLayoutResult layout, CanvasFeedGroup g) {
    if (_viewport.isEmpty) return;
    final bounds = _groupBounds(layout, g);
    if (bounds.isEmpty) return;
    _focusFitActive = true;
    final target = _fitCameraForRect(bounds.inflate(10));
    _camera.flyTo(
      _camera.adjustTargetForTeleport(
        target,
        _viewport,
        fitInsideViewport: true,
      ),
      fitInsideViewport: true,
    );
  }

  void _flyToSubimage(
    CanvasFeedLayoutResult layout,
    CanvasFeedGroup g,
    int index,
  ) {
    if (_viewport.isEmpty) return;
    final rect = layout.items
        .where((it) => it.group.key == g.key && it.subimageIndex == index)
        .map((it) => it.worldRect)
        .firstOrNull;
    if (rect == null || rect.isEmpty) return;
    _focusFitActive = true;
    final target = _fitCameraForRect(rect.inflate(10));
    _camera.flyTo(
      _camera.adjustTargetForTeleport(
        target,
        _viewport,
        fitInsideViewport: true,
      ),
      fitInsideViewport: true,
    );
  }

  /// Fit inside the measured space between the three floating toolbars.
  CanvasCamera _fitCameraForRect(Rect rect) {
    final available = widget.focusInsets != null
        ? _insetViewport()
        : _focusViewport.isEmpty
        ? Rect.fromLTWH(
            20,
            56,
            math.max(1.0, _viewport.width - 40),
            math.max(1.0, _viewport.height - 112),
          )
        : _focusViewport;
    final fitMax = ref.read(canvasZoomToFillNotifierProvider)
        ? CanvasCamera.maxScale
        : 1.0;
    final y = math.min(
      math.min(fitMax, CanvasCamera.maxScale),
      math.max(
        CanvasCamera.minFitScale,
        math.min(available.width / rect.width, available.height / rect.height),
      ),
    );
    final tx = available.center.dx - rect.center.dx * y;
    final ty = available.center.dy - rect.center.dy * y;
    return CanvasCamera(offset: Offset(tx, ty), scale: y);
  }

  Rect _insetViewport() {
    final insets = widget.focusInsets!;
    final left = math.min(insets.left, math.max(0.0, _viewport.width - 1));
    final top = math.min(insets.top, math.max(0.0, _viewport.height - 1));
    return Rect.fromLTRB(
      left,
      top,
      math.max(left + 1, _viewport.width - insets.right),
      math.max(top + 1, _viewport.height - insets.bottom),
    );
  }

  // The welcome layout is in viewport space. Keep the background's quiet
  // world-x=0 corridor on that same centre, regardless of a retained camera.
  CanvasCamera _welcomeCamera() =>
      CanvasCamera(offset: _viewport.center(Offset.zero), scale: 1);

  void _setViewport(Size size) {
    final changed = _viewport != size;
    _viewport = size;
    _camera.setViewport(size);
    if (changed && widget.embedded && _focusFitActive && !_manualOverview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refitCurrentFocus(immediate: true);
      });
    }
  }

  void _measureFocusViewport() {
    if (_measureFocusPending) return;
    _measureFocusPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureFocusPending = false;
      if (!mounted) return;
      final viewport = _viewportKey.currentContext?.findRenderObject();
      if (viewport is! RenderBox ||
          !viewport.hasSize ||
          viewport.size.isEmpty) {
        return;
      }
      Rect? toolbarRect(GlobalKey key) {
        final box = key.currentContext?.findRenderObject();
        if (box is! RenderBox || !box.hasSize) return null;
        return viewport.globalToLocal(box.localToGlobal(Offset.zero)) &
            box.size;
      }

      final top = toolbarRect(_topToolbarKey);
      final bottomStart = toolbarRect(_bottomStartToolbarKey);
      final bottomEnd = toolbarRect(_bottomEndToolbarKey);
      if (top == null || bottomStart == null || bottomEnd == null) return;
      final topEdge = (top.bottom + 8)
          .clamp(0.0, viewport.size.height - 1)
          .toDouble();
      final bottomEdge = (math.min(bottomStart.top, bottomEnd.top) - 8)
          .clamp(topEdge + 1, viewport.size.height)
          .toDouble();
      final available = Rect.fromLTRB(
        20,
        topEdge,
        math.max(21.0, viewport.size.width - 20),
        bottomEdge,
      );
      if (_focusViewport == available) return;
      _focusViewport = available;
      if (_focusFitActive && !_manualOverview) {
        _refitCurrentFocus(immediate: true);
      }
    });
  }

  void _refitCurrentFocus({bool immediate = false}) {
    final focus = ref.read(generationCanvasGroupSelectionProvider);
    if (focus == null) return;
    final layout = ref.read(canvasFeedLayoutProvider);
    final group = layout.groups.where((g) => g.key == focus.group).firstOrNull;
    if (group == null) return;
    if (immediate) {
      final rect = focus.subimage == null
          ? _groupBounds(layout, group)
          : layout.items
                .where(
                  (item) =>
                      item.group.key == group.key &&
                      item.subimageIndex == focus.subimage,
                )
                .firstOrNull
                ?.worldRect;
      if (rect != null && !rect.isEmpty) {
        _camera.jump(_fitCameraForRect(rect.inflate(10)));
      }
      return;
    }
    if (focus.subimage != null) {
      _flyToSubimage(layout, group, focus.subimage!);
    } else {
      _flyToGroup(layout, group);
    }
  }

  /// 画布更新共享选中时，不把自身的通知再次当成历史栏点击来飞行。
  void _syncPreviewSelection(String? imageId) {
    if (ref.read(generationPreviewSelectionProvider) == imageId) return;
    _syncingPreviewSelection = true;
    try {
      final selection = ref.read(generationPreviewSelectionProvider.notifier);
      imageId == null ? selection.clear() : selection.select(imageId);
    } finally {
      _syncingPreviewSelection = false;
    }
  }

  void _syncPreviewToGroup(CanvasFeedLayoutResult layout, String groupKey) {
    final g = layout.groups.where((x) => x.key == groupKey).firstOrNull;
    _syncPreviewSelection(g?.images.firstOrNull?.id);
  }

  void _syncPreviewToImage(GeneratedImage image) =>
      _syncPreviewSelection(image.id);

  /// 历史栏点选 → 画布夺焦联动
  void _focusImageById(String imageId) {
    _manualOverview = false;
    final layout = ref.read(canvasFeedLayoutProvider);
    final item = layout.items
        .where((it) => it.image?.id == imageId)
        .firstOrNull;
    if (item == null) return;
    final focus = ref.read(generationCanvasGroupSelectionProvider);
    if (focus?.group == item.group.key &&
        focus?.subimage == item.subimageIndex) {
      return;
    }
    ref
        .read(generationCanvasGroupSelectionProvider.notifier)
        .selectTile(item.group.key, item.subimageIndex);
    _flyToSubimage(layout, item.group, item.subimageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    MediaQuery.textScalerOf(context);
    final layout = ref.watch(canvasFeedLayoutProvider);
    final focus = ref.watch(generationCanvasGroupSelectionProvider);
    final channelSettings = widget.visualChannel
        ? ref.watch(canvasChannelNotifierProvider)
        : null;
    final channelActive =
        channelSettings != null && channelSettings.mode != ChannelMode.off;
    final channelFeed = channelActive
        ? ref.watch(canvasChannelFeedProvider)
        : null;
    final reducedChannelMotion =
        channelActive && ref.watch(canvasReducedMotionNotifierProvider);

    // 新批占位出现时立即飞过去；流式帧和最终图更新使用同一组身份。
    ref.listen(canvasFeedLayoutProvider, (prev, next) {
      if (!mounted || _viewport.isEmpty) return;
      if (next.groups.isEmpty) {
        ref.read(generationCanvasGroupSelectionProvider.notifier).clear();
        ref.read(generationPreviewSelectionProvider.notifier).clear();
        return;
      }
      final head = next.groups.first;
      final selected = ref.read(generationCanvasGroupSelectionProvider);
      final selectionMissing =
          selected != null &&
          !next.groups.any((group) => group.key == selected.group);
      if (prev?.groups.firstOrNull?.key != head.key || selectionMissing) {
        if (widget.visualChannel && prev?.groups.isEmpty == true) {
          // Start the first focus flight from what was actually on screen,
          // rather than a camera left behind by an earlier canvas visit.
          _camera.jump(_welcomeCamera(), notifyIdle: false);
        }
        _manualOverview = false;
        ref
            .read(generationCanvasGroupSelectionProvider.notifier)
            .selectGroup(head.key);
        _syncPreviewToGroup(next, head.key);
        _flyToGroup(next, head);
        return;
      }
      // Batch deletion changes positional indices. Keep focus on the same
      // surviving image; if it was deleted, focus a remaining neighbour.
      final previousImage = prev == null
          ? null
          : _resolveSelectedImage(prev, selected);
      if (selected?.subimage != null && previousImage != null) {
        final group = next.groups
            .where((group) => group.key == selected!.group)
            .first;
        final retainedIndex = group.tiles.indexWhere(
          (tile) => tile.image?.id == previousImage.id,
        );
        final index = retainedIndex >= 0
            ? retainedIndex
            : selected!.subimage!.clamp(0, group.tiles.length - 1);
        if (index != selected!.subimage) {
          ref
              .read(generationCanvasGroupSelectionProvider.notifier)
              .selectTile(group.key, index);
        }
        final image = group.tiles[index].image;
        if (image != null) _syncPreviewToImage(image);
        if (retainedIndex < 0) _flyToSubimage(next, group, index);
        return;
      }
      // 完成图接管占位后只同步共享选中，不再次飞行或抢回用户移开的焦点。
      final image = _resolveSelectedImage(next, selected);
      if (image != null) _syncPreviewToImage(image);
    });

    // 历史栏点选 → 画布夺焦联动
    ref.listen(generationPreviewSelectionProvider, (prev, next) {
      if (_syncingPreviewSelection || next == null || next == prev) return;
      _focusImageById(next);
    });

    ref.listen(generationCanvasCameraProvider, (prev, next) {
      _lostTimer?.cancel();
    });

    ref.listen(canvasPinboardFocusRequestProvider, (prev, next) {
      final pins = ref.read(canvasFeedLayoutProvider);
      final board = pins.groups.where((g) => g.isPinnedGroup).firstOrNull;
      if (board == null) return;
      _manualOverview = false;
      ref
          .read(generationCanvasGroupSelectionProvider.notifier)
          .selectGroup(board.key);
      _syncPreviewToGroup(pins, board.key);
      _flyToGroup(pins, board);
    });

    ref.listen(canvasHistoryFocusRequestProvider, (previous, request) {
      if (request == null) return;
      final layout = ref.read(canvasFeedLayoutProvider);
      final group = layout.groups
          .where(
            (group) =>
                group.key == request.group ||
                (!group.isPinnedGroup &&
                    group.images.any((image) => image.id == request.imageId)),
          )
          .firstOrNull;
      if (group == null) return;
      _manualOverview = false;
      ref
          .read(generationCanvasGroupSelectionProvider.notifier)
          .selectGroup(group.key);
      _syncPreviewSelection(request.imageId ?? group.images.firstOrNull?.id);
      _flyToGroup(layout, group);
    });

    ref.listen(canvasTileFocusRequestProvider, (previous, request) {
      if (request == null) return;
      final layout = ref.read(canvasFeedLayoutProvider);
      final group = layout.groups
          .where((group) => group.key == request.group)
          .firstOrNull;
      if (group == null ||
          request.subimage < 0 ||
          request.subimage >= group.tiles.length) {
        return;
      }
      _manualOverview = false;
      _flyToSubimage(layout, group, request.subimage);
    });

    ref.listen(canvasLockCameraNotifierProvider, (prev, locked) {
      if (!locked) return;
      _stopWasd();
      _panActive = false;
      _camera.jump(ref.read(generationCanvasCameraProvider));
    });

    ref.listen(canvasZoomToFillNotifierProvider, (previous, next) {
      if (previous != next) _refitCurrentFocus();
    });

    final tiles = _buildTiles(layout, focus);
    if (layout.groups.isEmpty && !widget.visualChannel) {
      return LayoutBuilder(
        builder: (context, constraints) {
          _setViewport(Size(constraints.maxWidth, constraints.maxHeight));
          if (widget.embedded) return const SizedBox.expand();
          return Stack(
            children: [
              Positioned.fill(
                child: _CanvasEmptyState(
                  theme: theme,
                  isGenerating: widget.generationState.isGenerating,
                ),
              ),
              if (WindowChromeScope.dragOf(context)) _buildWindowDragStrip(),
            ],
          );
        },
      );
    }

    return Focus(
      focusNode: _canvasFocusNode,
      onFocusChange: (hasFocus) {
        if (!hasFocus) _stopWasd();
      },
      onKeyEvent: (node, event) => _onKey(event, layout),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _onCanvasTapUp,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          onPointerSignal: _onPointerSignal,
          onPointerPanZoomStart: _onPanZoomStart,
          onPointerPanZoomUpdate: _onPanZoomUpdate,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _setViewport(Size(constraints.maxWidth, constraints.maxHeight));
              final selectedImage = _resolveSelectedImage(layout, focus);
              final showEdgeBars = focus != null && selectedImage != null;
              if (showEdgeBars && !widget.embedded) _measureFocusViewport();

              return ClipRect(
                key: _viewportKey,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final retainedCamera = ref.watch(
                            generationCanvasCameraProvider,
                          );
                          final camera =
                              widget.visualChannel && layout.groups.isEmpty
                              ? _welcomeCamera()
                              : retainedCamera;
                          final channel = channelFeed == null
                              ? null
                              : ChannelViewData(
                                  settings: reducedChannelMotion
                                      ? channelSettings.copyWith(motion: false)
                                      : channelSettings!,
                                  camera: ChannelCamera(
                                    offset: camera.offset,
                                    scale: camera.scale,
                                  ),
                                  batches: channelFeed.batches,
                                  pinboard: channelFeed.pinboard,
                                  now: channelFeed.now,
                                  generating: channelFeed.generating,
                                );
                          return Stack(
                            children: [
                              if (channel != null)
                                Positioned.fill(
                                  child: ResizeDecorationCache(
                                    child: ChannelBackdrop(data: channel),
                                  ),
                                )
                              else if (!widget.embedded)
                                Positioned.fill(
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      key: const ValueKey(
                                        'canvas-pixel-background',
                                      ),
                                      painter: CanvasPixelBackgroundPainter(
                                        camera: camera,
                                        theme: theme,
                                        devicePixelRatio:
                                            MediaQuery.devicePixelRatioOf(
                                              context,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned.fill(
                                key: const ValueKey('canvas-world-viewport'),
                                child: CanvasWorldViewport(
                                  camera: camera,
                                  children: tiles
                                      .where(
                                        (tile) => tile.rect.overlaps(
                                          camera
                                              .visibleWorldRect(_viewport)
                                              .inflate(500),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              ..._buildGroupBadges(layout, camera),
                              if (channel != null)
                                Positioned.fill(
                                  key: const ValueKey('canvas-channel-overlay'),
                                  child: Listener(
                                    onPointerDown: (event) =>
                                        _uiPointers.add(event.pointer),
                                    onPointerUp: (event) {
                                      _uiPointers.remove(event.pointer);
                                      _consumedUiPointers.add(event.pointer);
                                    },
                                    onPointerCancel: (event) {
                                      _uiPointers.remove(event.pointer);
                                      _consumedUiPointers.remove(event.pointer);
                                    },
                                    child: ChannelOverlay(
                                      data: channel,
                                      claimEntryToast: () => ref
                                          .read(
                                            canvasChannelEntryNoticeProvider,
                                          )
                                          .claim(),
                                      actions: ChannelActions(
                                        onSettingsChanged: (value) => ref
                                            .read(
                                              canvasChannelNotifierProvider
                                                  .notifier,
                                            )
                                            .set(value),
                                        onJumpTo: _jumpChannel,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (!widget.embedded && WindowChromeScope.dragOf(context))
                      _buildWindowDragStrip(),
                    // 屏幕空间覆盖层：焦点组 edge bars（顶中/底左/底右）
                    if (showEdgeBars && !widget.embedded)
                      _buildEdgeBars(layout, focus),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _jumpChannel(double worldY) {
    if (_cameraLocked || _viewport.isEmpty || !worldY.isFinite) return;
    _stopWasd();
    _lostTimer?.cancel();
    _panActive = false;
    _panAccum = Offset.zero;
    _inertiaVelocity = Offset.zero;
    _manualOverview = true;
    _focusFitActive = false;
    final camera = _cameraState();
    _camera.jump(
      CanvasCamera(
        offset:
            _viewport.center(Offset.zero) - Offset(0, worldY) * camera.scale,
        scale: camera.scale,
      ),
      notifyIdle: false,
    );
  }

  Widget _buildWindowDragStrip() => Positioned(
    top: 0,
    left: 0,
    right: 0,
    height: WindowChromeScope.heightOf(context),
    child: Listener(
      onPointerDown: (event) => _uiPointers.add(event.pointer),
      onPointerUp: (event) {
        _uiPointers.remove(event.pointer);
        _consumedUiPointers.add(event.pointer);
      },
      onPointerCancel: (event) {
        _uiPointers.remove(event.pointer);
        _consumedUiPointers.remove(event.pointer);
      },
      child: const WindowDragArea(),
    ),
  );

  GeneratedImage? _resolveSelectedImage(
    CanvasFeedLayoutResult layout,
    CanvasFocus? focus,
  ) {
    if (focus == null) return null;
    final g = layout.groups.where((x) => x.key == focus.group).firstOrNull;
    if (g == null) return null;
    final index = focus.subimage;
    if (index == null) return g.images.firstOrNull;
    return index >= 0 && index < g.tiles.length ? g.tiles[index].image : null;
  }

  final _embeddedTiles = <Object, CanvasWorldItem>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _embeddedTiles.clear();
  }

  List<CanvasWorldItem> _buildTiles(
    CanvasFeedLayoutResult layout,
    CanvasFocus? focus,
  ) {
    final pinned = ref.watch(canvasPinnedNotifierProvider);
    final retained = <Object>{};
    final result = <CanvasWorldItem>[];
    for (final item in layout.items) {
      final key = (
        item,
        focus?.group == item.group.key,
        focus?.group == item.group.key && focus?.subimage == item.subimageIndex,
        item.image != null && pinned.contains(item.image!.id),
        widget.tileBuilder,
      );
      retained.add(key);
      final cached = widget.embedded ? _embeddedTiles[key] : null;
      final tile =
          cached ??
          CanvasWorldItem(
            key: ValueKey(
              'canvas-tile:${item.group.key}:${item.subimageIndex}',
            ),
            rect: item.worldRect,
            child: RepaintBoundary(
              child: widget.tileBuilder != null
                  ? widget.tileBuilder!(
                      context,
                      item,
                      focus?.group == item.group.key &&
                          focus?.subimage == item.subimageIndex,
                      () => _selectEmbeddedTile(item),
                      () =>
                          !_suppressTileTap &&
                          !HardwareKeyboard.instance.isShiftPressed,
                    )
                  : _CanvasTile(
                      group: item.group,
                      tile: item.tile,
                      subimageIndex: item.subimageIndex,
                      isFocusGroup: focus?.group == item.group.key,
                      isFocusSubimage:
                          focus?.group == item.group.key &&
                          focus?.subimage == item.subimageIndex,
                      isPinned:
                          item.image != null && pinned.contains(item.image!.id),
                      onSelect: () => _onTileTap(item),
                      imageChild: item.image == null
                          ? null
                          : buildGeneratedImageCard(
                              context: context,
                              ref: ref,
                              image: item.image!,
                              showIndex: false,
                              canvasTile: true,
                              onTap: () => _onTileTap(item),
                            ),
                    ),
            ),
          );
      if (widget.embedded) _embeddedTiles[key] = tile;
      result.add(tile);
    }
    _embeddedTiles.removeWhere((key, _) => !retained.contains(key));
    return result;
  }

  List<Widget> _buildGroupBadges(
    CanvasFeedLayoutResult layout,
    CanvasCamera camera,
  ) {
    final visible = camera.visibleWorldRect(_viewport);
    return [
      for (final group in layout.groups)
        if (group.tiles.length > 1 &&
            _groupBounds(layout, group).overlaps(visible))
          Positioned(
            right:
                _viewport.width -
                camera
                    .worldToScreen(_groupBounds(layout, group).bottomRight)
                    .dx +
                6,
            bottom:
                _viewport.height -
                camera
                    .worldToScreen(_groupBounds(layout, group).bottomRight)
                    .dy +
                6,
            child: IgnorePointer(
              key: ValueKey('canvas-batch-count:${group.key}'),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  child: Text(
                    '×${group.tiles.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
    ];
  }

  void _onTileTap(CanvasFeedItem item) {
    _manualOverview = false;
    // 占位卡与成图使用同样的选中/飞行路径。
    final layout = ref.read(canvasFeedLayoutProvider);
    final focus = ref.read(generationCanvasGroupSelectionProvider);
    final isFocused =
        focus?.group == item.group.key && focus?.subimage == item.subimageIndex;
    if (isFocused) {
      // 官网：再点已焦点图 → 飞出到整组边界（subimage=null = 整组展开态）
      ref
          .read(generationCanvasGroupSelectionProvider.notifier)
          .selectGroup(item.group.key);
      _syncPreviewToGroup(layout, item.group.key);
      _flyToGroup(layout, item.group);
    } else {
      ref
          .read(generationCanvasGroupSelectionProvider.notifier)
          .selectTile(item.group.key, item.subimageIndex);
      _syncPreviewSelection(item.image?.id);
      _flyToSubimage(layout, item.group, item.subimageIndex);
    }
  }

  void _selectEmbeddedTile(CanvasFeedItem item) {
    if (_suppressTileTap || HardwareKeyboard.instance.isShiftPressed) return;
    final layout = ref.read(canvasFeedLayoutProvider);
    final target = layout.items
        .where(
          (candidate) =>
              candidate.group.key == item.group.key &&
              (item.image == null
                  ? candidate.subimageIndex == item.subimageIndex
                  : candidate.image?.id == item.image!.id),
        )
        .firstOrNull;
    if (target == null) return;
    _manualOverview = false;
    ref
        .read(generationCanvasGroupSelectionProvider.notifier)
        .selectTile(target.group.key, target.subimageIndex);
    _syncPreviewSelection(target.image?.id);
    _flyToSubimage(layout, target.group, target.subimageIndex);
  }

  Widget _buildEdgeBars(CanvasFeedLayoutResult layout, CanvasFocus? focus) {
    final g = layout.groups.where((x) => x.key == focus!.group).firstOrNull;
    final img = _resolveSelectedImage(layout, focus);
    if (g == null || img == null) return const SizedBox.shrink();

    // edge bars 上的指针不喂画布平移/双击判定
    Widget guarded(Widget child) => Listener(
      onPointerDown: (e) => _uiPointers.add(e.pointer),
      onPointerUp: (e) {
        _uiPointers.remove(e.pointer);
        _consumedUiPointers.add(e.pointer);
      },
      onPointerCancel: (e) {
        _uiPointers.remove(e.pointer);
        _consumedUiPointers.remove(e.pointer);
      },
      child: child,
    );

    final panes = ref.watch(layoutStateNotifierProvider);
    final rightPaneWidth = panes.rightPanelExpanded
        ? panes.rightPanelWidth
        : 40.0;
    // 三个主工具条固定在中央画布视口边缘，位置与尺寸均不经过相机变换。
    // 操作对象仍是当前焦点图；图片移出视口时工具条也保持可见。
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            WindowSafeTopToolbar(
              outsideRightWidth: rightPaneWidth + 16,
              child: guarded(
                CanvasEdgeToolbar(
                  key: _topToolbarKey,
                  zone: CanvasToolbarZone.top,
                  image: img,
                  group: g,
                  focus: focus,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: guarded(
                CanvasEdgeToolbar(
                  key: _bottomStartToolbarKey,
                  zone: CanvasToolbarZone.bottomStart,
                  image: img,
                  group: g,
                  focus: focus,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: guarded(
                CanvasEdgeToolbar(
                  key: _bottomEndToolbarKey,
                  zone: CanvasToolbarZone.bottomEnd,
                  image: img,
                  group: g,
                  focus: focus,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final Set<LogicalKeyboardKey> _wasdKeysSet = {
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyD,
  };

  void _startWasd() {
    if (_wasdTicker != null) return;
    _focusFitActive = false;
    _wasdLast = Duration.zero;
    _wasdTicker = createTicker((elapsed) {
      final dt = elapsed - _wasdLast;
      _wasdLast = elapsed;
      if (dt <= Duration.zero || dt.inMilliseconds > 100) return;
      var dx = 0.0, dy = 0.0;
      if (_wasdKeys.contains(LogicalKeyboardKey.keyA)) dx -= 1;
      if (_wasdKeys.contains(LogicalKeyboardKey.keyD)) dx += 1;
      if (_wasdKeys.contains(LogicalKeyboardKey.keyW)) dy -= 1;
      if (_wasdKeys.contains(LogicalKeyboardKey.keyS)) dy += 1;
      if (dx == 0 && dy == 0) {
        _stopWasd();
        return;
      }
      // 对角归一 + 官网 1000px/s（屏幕系位移即世界系 offset 增量）
      final len = math.sqrt(dx * dx + dy * dy);
      const speed = 1000.0; // px/s（官网 WASD 1000px/s）
      final secs = dt.inMicroseconds / 1e6;
      _camera.panBy(Offset(dx / len * speed * secs, dy / len * speed * secs));
    })..start();
  }

  void _stopWasd() {
    _wasdKeys.clear();
    _wasdTicker?.dispose();
    _wasdTicker = null;
  }

  KeyEventResult _onKey(KeyEvent event, CanvasFeedLayoutResult layout) {
    final key = event.logicalKey;
    final ctrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    // Release movement even when modifiers or camera lock changed meanwhile.
    if (event is KeyUpEvent && _wasdKeys.remove(key)) {
      if (_wasdKeys.isEmpty) _stopWasd();
      return KeyEventResult.handled;
    }
    if (widget.deferKeyEvent?.call(event) == true) {
      return KeyEventResult.ignored;
    }
    final groups = layout.groups;
    if (groups.isEmpty) return KeyEventResult.ignored;

    // 官网 WASD 平移：按住持续移动（键松开/失焦即停；锁相机/Ctrl 时不触发）
    if (_wasdKeysSet.contains(key) && !ctrl && !shift && !_cameraLocked) {
      if (event is KeyDownEvent) {
        _wasdKeys.add(key);
        _startWasd();
        return KeyEventResult.handled;
      }
      if (event is KeyUpEvent) {
        _wasdKeys.remove(key);
        if (_wasdKeys.isEmpty) _stopWasd();
        return KeyEventResult.handled;
      }
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final focus = ref.read(generationCanvasGroupSelectionProvider);
    final idx = focus == null
        ? -1
        : groups.indexWhere((g) => g.key == focus.group);

    if (key == LogicalKeyboardKey.keyQ) {
      // q 跳组：Shift+q 前 / 裸 q 后
      final next = shift
          ? (idx <= 0 ? groups.length - 1 : idx - 1)
          : (idx < 0 || idx >= groups.length - 1 ? 0 : idx + 1);
      final g = groups[next];
      ref
          .read(generationCanvasGroupSelectionProvider.notifier)
          .selectGroup(g.key);
      _syncPreviewToGroup(layout, g.key);
      _flyToGroup(layout, g);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyF) {
      // f 飞回焦点组（无焦点则飞最近组）
      if (focus != null) {
        final g = groups.where((x) => x.key == focus.group).firstOrNull;
        if (g != null) {
          if (focus.subimage != null) {
            _flyToSubimage(layout, g, focus.subimage!);
          } else {
            _flyToGroup(layout, g);
          }
        }
      } else {
        _checkLostAndFlyBack();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      // Esc 退子图态 → 整组边界（官网逐字）
      if (focus?.subimage != null) {
        ref
            .read(generationCanvasGroupSelectionProvider.notifier)
            .selectGroup(focus!.group);
        final g = groups.where((x) => x.key == focus.group).firstOrNull;
        if (g != null) {
          _syncPreviewToGroup(layout, g.key);
          _flyToGroup(layout, g);
        }
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      final g = groups.first;
      ref
          .read(generationCanvasGroupSelectionProvider.notifier)
          .selectGroup(g.key);
      _syncPreviewToGroup(layout, g.key);
      _flyToGroup(layout, g);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      final g = groups.last;
      ref
          .read(generationCanvasGroupSelectionProvider.notifier)
          .selectGroup(g.key);
      _syncPreviewToGroup(layout, g.key);
      _flyToGroup(layout, g);
      return KeyEventResult.handled;
    }
    if (!_cameraLocked && ctrl && key == LogicalKeyboardKey.digit0) {
      _focusFitActive = false;
      _manualOverview = true;
      ref.read(generationCanvasGroupSelectionProvider.notifier).clear();
      _camera.flyTo(CanvasCamera.init);
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyS) {
      if (widget.embedded) return KeyEventResult.ignored;
      final img = _resolveSelectedImage(layout, focus);
      if (img != null && img.canSave) {
        unawaited(_saveFocusedImage(img));
      }
      return KeyEventResult.handled;
    }
    if (!_cameraLocked &&
        (key == LogicalKeyboardKey.equal ||
            key == LogicalKeyboardKey.numpadAdd)) {
      _focusFitActive = false;
      _camera.zoomBy(
        1.3,
        anchor: Offset(_viewport.width / 2, _viewport.height / 2),
      );
      return KeyEventResult.handled;
    }
    if (!_cameraLocked &&
        (key == LogicalKeyboardKey.minus ||
            key == LogicalKeyboardKey.numpadSubtract)) {
      _focusFitActive = false;
      _camera.zoomBy(
        1 / 1.3,
        anchor: Offset(_viewport.width / 2, _viewport.height / 2),
      );
      return KeyEventResult.handled;
    }
    if (!_cameraLocked &&
        (key == LogicalKeyboardKey.digit1 ||
            key == LogicalKeyboardKey.numpad1)) {
      _focusFitActive = false;
      // 回 100%：锚定视口中心
      final center = Offset(_viewport.width / 2, _viewport.height / 2);
      _camera.zoomBy(1 / _cameraState().scale, anchor: center);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  CanvasCamera _cameraState() => ref.read(generationCanvasCameraProvider);

  Future<void> _saveFocusedImage(GeneratedImage img) async {
    final detail = GeneratedImageDetailData(
      imageBytes: img.bytes,
      metadata: img.metadata,
      id: img.id,
      showSaveButton: img.canSave,
      showCopyButton: img.canSave,
    );
    await GenerationSaveService.saveImageFromDetail(context, ref, detail);
  }

  // ── 指针交互（官网逐字：5px 死区 / 惯性抛掷 / Ctrl 缩放 / 裸滚轮平移）──

  bool _isPanButton(PointerEvent e) =>
      (e.buttons & kMiddleMouseButton) != 0 ||
      ((e.buttons & kPrimaryMouseButton) != 0 &&
          (e.kind != PointerDeviceKind.mouse ||
              HardwareKeyboard.instance.isShiftPressed));

  void _onPointerDown(PointerDownEvent e) {
    _suppressTileTap = false;
    _pointers.add(e.pointer);
    _consumedUiPointers.remove(e.pointer);
    _canvasFocusNode.requestFocus();
    if (_uiPointers.contains(e.pointer)) return;
    _panAccum = Offset.zero;
    _panActive = false;
    _lastPanAt = DateTime.now();
    _inertiaVelocity = Offset.zero;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_uiPointers.contains(e.pointer)) return;
    if (_cameraLocked) return;
    if (_pointers.length == 2) {
      // Desktop trackpad gestures use PointerPanZoom events below.
      return;
    }
    if (_pointers.isEmpty || !_isPanButton(e)) return;

    // 官网 5px 死区：累计位移超过阈值才算拖拽（点击 tile 不触发平移）
    if (!_panActive) {
      _panAccum += e.localDelta;
      if (_panAccum.distance <= 5) return;
      _panActive = true;
      _suppressTileTap = true;
      _manualOverview = false;
      _focusFitActive = false;
      _camera.panBy(_panAccum);
    } else {
      _camera.panBy(e.localDelta);
    }

    // 速度估计（惯性用）：官网每帧记录 velocity，松手 <60ms 且有速度 → 抛掷
    final now = DateTime.now();
    final last = _lastPanAt;
    if (last != null) {
      final dt = now.difference(last).inMilliseconds;
      if (dt > 0) {
        _inertiaVelocity = Offset(e.localDelta.dx / dt, e.localDelta.dy / dt);
      }
    }
    _lastPanAt = now;
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    if (_uiPointers.contains(e.pointer)) return;
    if (_pointers.isEmpty) {
      // 惯性：松手 <60ms 且速度 >0.02px/ms → 抛掷（官网逐字）
      if (!_cameraLocked &&
          _panActive &&
          _lastPanAt != null &&
          DateTime.now().difference(_lastPanAt!).inMilliseconds < 60 &&
          _inertiaVelocity.distance > 0.02) {
        _camera.fling(_inertiaVelocity, _viewport);
      }
      _panActive = false;
      _panAccum = Offset.zero;
      _inertiaVelocity = Offset.zero;
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    _uiPointers.remove(e.pointer);
    _consumedUiPointers.remove(e.pointer);
    if (_pointers.isEmpty) {
      _panActive = false;
      _panAccum = Offset.zero;
      _inertiaVelocity = Offset.zero;
    }
  }

  void _onPointerSignal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    if (_cameraLocked) return;
    final kb = HardwareKeyboard.instance;
    final ctrl = kb.isControlPressed || kb.isMetaPressed;
    final shift = kb.isShiftPressed;
    final dy = e.scrollDelta.dy;
    _focusFitActive = false;
    _manualOverview = false;

    if (ctrl) {
      if (dy == 0) return;
      // 官网：Ctrl+滚轮缩放；平滑档 exp(clamp(-0.01·dy,±0.25))，
      // 离散档 dy<0 ×1.2 / dy>0 ÷1.2，锚点=光标
      final smooth = ref.read(canvasSmoothZoomNotifierProvider);
      if (smooth) {
        final factor = math.exp((-0.01 * dy).clamp(-0.25, 0.25));
        _camera.zoomBy(factor, anchor: e.localPosition, smooth: true);
      } else {
        _camera.zoomBy(dy < 0 ? 1.2 : 1 / 1.2, anchor: e.localPosition);
      }
    } else {
      // 裸滚轮平移（无缩放、无翻页）；Shift 纵转横
      _camera.panBy(
        shift
            ? Offset(-(e.scrollDelta.dx + dy), 0)
            : Offset(-e.scrollDelta.dx, -dy),
      );
    }
  }

  double _panZoomScale = 1;

  void _onPanZoomStart(PointerPanZoomStartEvent event) {
    _focusFitActive = false;
    _panZoomScale = 1;
    _canvasFocusNode.requestFocus();
  }

  void _onPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    final factor = event.scale / _panZoomScale;
    _panZoomScale = event.scale;
    if (_cameraLocked) return;
    _camera.panBy(event.panDelta);
    _camera.zoomBy(factor, anchor: event.localPosition, smooth: true);
  }

  /// 双击空处切「放大填充」；单击/双击落在 tile 或 UI 上不触发。
  void _onCanvasTapUp(TapUpDetails details) {
    if (_cameraLocked) return;
    // 用世界坐标命中检测：落在任一 tile 上 → 是 tile tap，不是画布 tap
    final layout = ref.read(canvasFeedLayoutProvider);
    final camera = ref.read(generationCanvasCameraProvider);
    final world = Offset(
      (details.localPosition.dx - camera.offset.dx) / camera.scale,
      (details.localPosition.dy - camera.offset.dy) / camera.scale,
    );
    final hitTile = layout.items.any((it) => it.worldRect.contains(world));
    if (hitTile) return;
    // edge bars 命中（屏幕坐标近似区）
    if (_consumedUiPointers.isNotEmpty) {
      _consumedUiPointers.clear();
      return;
    }

    _clickCount++;
    _clickTimer?.cancel();
    _clickTimer = Timer(const Duration(milliseconds: 260), () {
      _clickCount = 0;
    });
    if (_clickCount >= 2) {
      _clickCount = 0;
      _clickTimer?.cancel();
      ref.read(canvasZoomToFillNotifierProvider.notifier).toggle();
    }
  }
}

/// 单 tile：非焦点 scale(0.98) + 悬停回 1
Widget buildCanvasTilePresentation({
  required CanvasFeedItem item,
  required bool focused,
  required bool pinned,
  required VoidCallback onSelect,
  required Widget child,
}) => _CanvasTile(
  group: item.group,
  tile: item.tile,
  subimageIndex: item.subimageIndex,
  isFocusGroup: focused,
  isFocusSubimage: focused,
  isPinned: pinned,
  onSelect: onSelect,
  imageChild: child,
  embedded: true,
);

class _CanvasTile extends ConsumerStatefulWidget {
  const _CanvasTile({
    required this.group,
    required this.tile,
    required this.subimageIndex,
    required this.isFocusGroup,
    required this.isFocusSubimage,
    required this.isPinned,
    required this.onSelect,
    required this.imageChild,
    this.embedded = false,
  });

  final CanvasFeedGroup group;
  final CanvasTileSpec tile;
  final int subimageIndex;
  final bool isFocusGroup;
  final bool isFocusSubimage;
  final bool isPinned;
  final VoidCallback onSelect;
  final Widget? imageChild;
  final bool embedded;

  @override
  ConsumerState<_CanvasTile> createState() => _CanvasTileState();
}

class _CanvasTileState extends ConsumerState<_CanvasTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final unfocused = !widget.isFocusSubimage;
    final cameraScale = ref.watch(
      generationCanvasCameraProvider.select((c) => c.scale),
    );
    // 官网：非焦点 scale(0.98)；悬停回 1；0.25s cubic-bezier(0.22,1,0.36,1)
    final scale = unfocused && !_hovering ? 0.98 : 1.0;

    // 生成中占位槽（官网 image-grid-generating）：批参数尺寸 + 三点
    // 弹跳动画，有流式帧时叠预览帧。
    if (widget.tile.isInFlight) {
      if (widget.embedded) return widget.imageChild!;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelect,
        child: _InflightSlotTile(slot: widget.tile.slot!),
      );
    }

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovering = true);
      },
      onExit: (_) {
        setState(() => _hovering = false);
      },
      child: AnimatedScale(
        key: ValueKey(
          'canvas-tile-scale:${widget.group.key}:${widget.subimageIndex}',
        ),
        scale: scale,
        duration: const Duration(milliseconds: 250),
        curve: const Cubic(0.22, 1, 0.36, 1),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: widget.embedded
                  ? RepaintBoundary(child: widget.imageChild!)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CanvasImageBackground(
                        child: RepaintBoundary(child: widget.imageChild!),
                      ),
                    ),
            ),
            // 钉住角标（官网钉板标记）：实心 pin，右上反缩放恒屏大小
            if (widget.tile.image?.isVariationOriginal == true)
              Positioned(
                key: ValueKey(
                  'canvas-variation-original:${widget.tile.image!.id}',
                ),
                top: 0,
                left: 0,
                child: Transform.scale(
                  scale: 1 / cameraScale,
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      context.l10n.generation_variationOriginal,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.isPinned)
              Positioned(
                key: ValueKey('canvas-pin:${widget.tile.image!.id}'),
                top: -30 / cameraScale.clamp(0.5, 2.5),
                right: 0,
                child: Transform.scale(
                  scale: (1 / cameraScale).clamp(0.4, 2.5),
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      Icons.push_pin,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ),
            if (widget.embedded &&
                widget.tile.image?.isFailedStreamSnapshot == true)
              Positioned(
                left: 6,
                bottom: 6,
                child: IgnorePointer(
                  child: Tooltip(
                    message: context.l10n.generation_failedStreamSnapshotHint,
                    child: Container(
                      key: ValueKey(
                        'canvas-failed-snapshot:${widget.tile.image!.id}',
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.l10n.generation_failedStreamSnapshot,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 生成中占位 tile（官网 `image-grid-generating`）：批参数尺寸的卡面 +
/// 三点弹跳加载动画 + 一句等待小贴士；有流式预览帧时盖一层进度图。
class _InflightSlotTile extends StatelessWidget {
  const _InflightSlotTile({required this.slot});
  final StreamPreviewSlot slot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = slot.previewBytes;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CanvasImageBackground(
        child: ColoredBox(
          color: preview != null && preview.isNotEmpty
              ? Colors.transparent
              : theme.colorScheme.surfaceContainerHigh,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (preview != null && preview.isNotEmpty)
                buildStreamPreviewImage(
                  bytes: preview,
                  placement: slot.inpaintPreviewPlacement,
                ),
              ColoredBox(
                color: theme.colorScheme.surface.withValues(
                  alpha: preview != null && preview.isNotEmpty ? 0.35 : 0.0,
                ),
              ),
              const Center(child: CanvasGeneratingContent()),
            ],
          ),
        ),
      ),
    );
  }
}

/// 旧画布与新图块共享同一套生成动效和小贴士。
class CanvasGeneratingContent extends ConsumerStatefulWidget {
  const CanvasGeneratingContent({super.key, this.tip});
  final Tip? tip;
  @override
  ConsumerState<CanvasGeneratingContent> createState() =>
      _CanvasGeneratingContentState();
}

class _CanvasGeneratingContentState
    extends ConsumerState<CanvasGeneratingContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Tip _tip =
      widget.tip ?? ref.read(tipDeckProvider).draw(TipSurface.generating);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  void _updateMotion() {
    if (ref.read(canvasReducedMotionNotifierProvider) ||
        MediaQuery.disableAnimationsOf(context)) {
      _dots.stop();
    } else if (!_dots.isAnimating) {
      _dots.repeat();
    }
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(canvasReducedMotionNotifierProvider, (_, _) => _updateMotion());
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _dots,
      builder: (context, _) {
        // 官网三点弹跳：三圆依次起落的 loading 节奏
        Widget dot(int i) {
          final phase = (_dots.value * 3 - i).clamp(0.0, 1.0);
          final bump = math.sin(phase * math.pi);
          return Transform.translate(
            offset: Offset(0, -6 * bump),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onSurface.withValues(
                  alpha: 0.55 + 0.35 * bump,
                ),
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                dot(0),
                const SizedBox(width: 8),
                dot(1),
                const SizedBox(width: 8),
                dot(2),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _tip.text(context.l10n),
                key: const Key('canvas-inflight-tip'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CanvasEmptyState extends StatelessWidget {
  const _CanvasEmptyState({required this.theme, required this.isGenerating});

  final ThemeData theme;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            isGenerating
                ? context.l10n.generation_generating
                : context.l10n.generation_canvasEmpty,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
