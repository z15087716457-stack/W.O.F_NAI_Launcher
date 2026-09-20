import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/canvas_settings_provider.dart';
import '../../../../providers/generation/generation_models.dart';
import '../../../../providers/generation/preview_selection_provider.dart';
import '../../../../providers/image_generation_provider.dart';
import '../../../../widgets/common/image_detail/image_detail_data.dart';
import '../../services/generation_save_service.dart';
import 'canvas_feed_layout.dart';
import 'canvas_tile_toolbar.dart';
import 'generated_image_card.dart';
import 'generation_canvas_controller.dart';
import '../../../../../core/utils/localization_extension.dart';

/// 生成画布（G11 V3）：对标 NAI5 官网无限画布，逐字对码模块 22099。
/// - 世界层 = Transform 包的 Stack，tile 按世界坐标 Positioned
/// - 交互：中键/左键拖平移（5px 死区）+松手惯性（v 钳 4px/ms、摩擦 exp(-dt·5/1000)）；
///   Ctrl+滚轮缩放（离散 ×1.2 / 平滑 exp(-0.01·dy)）；裸滚轮平移 + Shift 纵转横；
///   点击 tile 夺焦飞行（指数趋近 speed 11）；相机停稳 120ms 自动选中心最近组；
///   q 跳组；Home/End 首尾；Ctrl+0 复位；Ctrl+S 保存焦点图；双击空处切放大填充
/// - 视觉：非焦点 tile scale(0.98)、悬停回 1（0.25s cubic-bezier(.22,1,.36,1)）；
///   非焦点悬停出底部迷你条；焦点组出 top/bottom 边缘工具条
/// - 归组：组 = 一次生成请求（generationRunId），连续单张各自成组（官网原样）
class GenerationCanvasView extends ConsumerStatefulWidget {
  const GenerationCanvasView({required this.generationState, super.key});

  final ImageGenerationState generationState;

  @override
  ConsumerState<GenerationCanvasView> createState() =>
      _GenerationCanvasViewState();
}

class _GenerationCanvasViewState extends ConsumerState<GenerationCanvasView>
    with TickerProviderStateMixin {
  Size _viewport = Size.zero;

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
      // 飞回距视口中心最近的组（inflight 组不算可选目标）
      final centerWorld = cam.screenToWorld(
        Offset(_viewport.width / 2, _viewport.height / 2),
      );
      String? bestKey;
      double best = double.infinity;
      for (final g in lo.groups) {
        if (g.tiles.isEmpty || g.deferFocus) continue;
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
    final pinned = ref.read(canvasPinnedNotifierProvider);
    String? bestKey;
    double best = double.infinity;
    for (final g in layout.groups) {
      if (g.tiles.isEmpty || g.deferFocus) continue;
      // 官网钉板：含钉住图的组不参与自动夺焦（钉板与 feed 分离）
      if (g.images.any((img) => pinned.contains(img.id))) continue;
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

  Rect _groupBounds(CanvasFeedLayoutResult layout, CanvasFeedGroup g) {
    var l = double.infinity, t = double.infinity, r = 0.0, b = 0.0;
    var found = false;
    for (final item in layout.items) {
      if (item.group.key != g.key) continue;
      found = true;
      final rect = item.worldRect;
      l = math.min(l, rect.left);
      t = math.min(t, rect.top);
      r = math.max(r, rect.right);
      b = math.max(b, rect.bottom);
    }
    return found ? Rect.fromLTRB(l, t, r, b) : Rect.zero;
  }

  void _syncSelectionToCamera() {
    final layout = ref.read(canvasFeedLayoutProvider);
    if (layout.groups.isEmpty) return;
    final focus = ref.read(generationCanvasGroupSelectionProvider);
    if (focus == null) {
      // 官网挂载态：默认夺焦最新组（groups[0]，mergedPanelImages 新→旧）
      final g = layout.groups.first;
      ref
          .read(generationCanvasGroupSelectionProvider.notifier)
          .selectGroup(g.key);
      _syncPreviewToGroup(layout, g.key);
      return;
    }
    final g = layout.groups
        .where((x) => x.key == focus.group)
        .firstOrNull;
    if (g == null) return;
    if (focus.subimage != null) {
      _flyToSubimage(layout, g, focus.subimage!);
    } else {
      _flyToGroup(layout, g);
    }
  }

  void _flyToGroup(CanvasFeedLayoutResult layout, CanvasFeedGroup g) {
    if (_viewport.isEmpty) return;
    final bounds = _groupBounds(layout, g);
    if (bounds.isEmpty) return;
    final target = _fitCameraForRect(bounds.inflate(10));
    _camera.flyTo(_camera.adjustTargetForTeleport(target, _viewport));
  }

  void _flyToSubimage(
    CanvasFeedLayoutResult layout,
    CanvasFeedGroup g,
    int index,
  ) {
    if (_viewport.isEmpty) return;
    final rect = layout.items
        .where(
          (it) => it.group.key == g.key && it.subimageIndex == index,
        )
        .map((it) => it.worldRect)
        .firstOrNull;
    if (rect == null || rect.isEmpty) return;
    final target = _fitCameraForRect(rect.inflate(10));
    _camera.flyTo(_camera.adjustTargetForTeleport(target, _viewport));
  }

  /// 官网 T() fitToRect：scale = min(fitMaxScale, 可用区/rect)，
  /// fitMaxScale = 放大填充开 ? maxScale : 1；可用区 = 视口 - 5%外边距 - chrome。
  CanvasCamera _fitCameraForRect(Rect rect) {
    final n = _viewport.width;
    final o = _viewport.height;
    const margin = 26.0; // 官网 5% + 6 + 20 近似
    final m = math.max(1.0, n - margin * 2);
    final f = math.max(1.0, o - margin * 2);
    final fitMax = ref.read(canvasZoomToFillNotifierProvider)
        ? CanvasCamera.maxScale
        : 1.0;
    final y = math.min(
      math.min(fitMax, CanvasCamera.maxScale),
      math.max(
        CanvasCamera.minScale,
        math.min(m / rect.width, f / rect.height),
      ),
    );
    final tx = margin + m / 2 - rect.center.dx * y;
    final ty = margin + f / 2 - rect.center.dy * y;
    return CanvasCamera(offset: Offset(tx, ty), scale: y);
  }

  /// 画布选中 → 历史预览联动（历史栏滚到该图）
  void _syncPreviewToGroup(CanvasFeedLayoutResult layout, String groupKey) {
    final g = layout.groups.where((x) => x.key == groupKey).firstOrNull;
    if (g == null || g.images.isEmpty) return;
    ref.read(generationPreviewSelectionProvider.notifier).select(
      g.images.first.id,
    );
  }

  void _syncPreviewToImage(GeneratedImage image) {
    ref.read(generationPreviewSelectionProvider.notifier).select(image.id);
  }

  /// 历史栏点选 → 画布夺焦联动
  void _focusImageById(String imageId) {
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
    final layout = ref.watch(canvasFeedLayoutProvider);
    final camera = ref.watch(generationCanvasCameraProvider);
    final focus = ref.watch(generationCanvasGroupSelectionProvider);

    // 新批置顶（groups[0] 变更）→ 官网「新批自动飞」：夺焦并飞过去。
    // deferFocus（官网）：含未完成槽位的组不夺焦不飞，等组内全部
    // finished 后由 deferFocus→false 的翻转补飞。
    ref.listen(canvasFeedLayoutProvider, (prev, next) {
      if (next.groups.isEmpty) return;
      final head = next.groups.first;
      // 同一组 deferFocus 翻转完成 → 补飞（官网等 all finished 才飞）
      if (prev != null &&
          prev.groups.firstOrNull?.key == head.key &&
          prev.groups.first.deferFocus &&
          !head.deferFocus) {
        if (!mounted || _viewport.isEmpty) return;
        ref
            .read(generationCanvasGroupSelectionProvider.notifier)
            .selectGroup(head.key);
        _syncPreviewToGroup(next, head.key);
        _flyToGroup(next, head);
        return;
      }
      if (prev?.groups.firstOrNull?.key == head.key) return;
      if (!mounted || _viewport.isEmpty) return;
      if (head.deferFocus) return; // 生成中占位组不夺焦
      ref
          .read(generationCanvasGroupSelectionProvider.notifier)
          .selectGroup(head.key);
      _syncPreviewToGroup(next, head.key);
      _flyToGroup(next, head);
    });

    // 历史栏点选 → 画布夺焦联动
    ref.listen(generationPreviewSelectionProvider, (prev, next) {
      if (next == null || next == prev) return;
      _focusImageById(next);
    });

    if (layout.groups.isEmpty) {
      return _CanvasEmptyState(
        theme: theme,
        isGenerating: widget.generationState.isGenerating,
      );
    }

    return Focus(
      focusNode: _canvasFocusNode,
      onFocusChange: (hasFocus) {
        if (!hasFocus) _stopWasd();
      },
      onKeyEvent: (node, event) => _onKey(event, layout),
      child: GestureDetector(
        onTapUp: _onCanvasTapUp,
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          onPointerSignal: _onPointerSignal,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _viewport = Size(constraints.maxWidth, constraints.maxHeight);
              _camera.setViewport(_viewport);
              final selectedImage = _resolveSelectedImage(layout, focus);
              final showEdgeBars = focus != null && selectedImage != null;

              return ClipRect(
                child: Stack(
                  children: [
                    // 网格底纹（对齐世界坐标倍数线）
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridPainter(camera: camera, theme: theme),
                      ),
                    ),
                    // 世界层：Transform 包静态子树，ref.watch(camera) 驱动重建
                    Positioned.fill(
                      child: Transform(
                        transform: Matrix4.identity()
                          ..translateByDouble(
                            camera.offset.dx,
                            camera.offset.dy,
                            0,
                            1,
                          )
                          ..scaleByDouble(
                            camera.scale,
                            camera.scale,
                            1,
                            1,
                          ),
                        alignment: Alignment.topLeft,
                        child: RepaintBoundary(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: _buildTiles(layout, focus, camera, theme),
                          ),
                        ),
                      ),
                    ),
                    // 屏幕空间覆盖层：焦点组 edge bars（顶中/底左/底右）
                    if (showEdgeBars)
                      _buildEdgeBars(context, layout, focus, camera, theme),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  GeneratedImage? _resolveSelectedImage(
    CanvasFeedLayoutResult layout,
    CanvasFocus? focus,
  ) {
    if (focus == null) return null;
    final g = layout.groups
        .where((x) => x.key == focus.group)
        .firstOrNull;
    if (g == null || g.images.isEmpty) return null;
    final idx = focus.subimage ?? 0;
    return idx < g.images.length ? g.images[idx] : g.images.first;
  }

  List<Widget> _buildTiles(
    CanvasFeedLayoutResult layout,
    CanvasFocus? focus,
    CanvasCamera camera,
    ThemeData theme,
  ) {
    final tiles = <Widget>[];
    final pinned = ref.watch(canvasPinnedNotifierProvider);
    final visible = camera.scale > 0
        ? camera.visibleWorldRect(_viewport).inflate(500)
        : null;

    // 组 ×N 徽标：每组一次，贴在组包围盒右下（世界坐标反缩放恒屏）
    final groupBadgeEmitted = <String>{};
    // 悬停放大到焦点同档（自研，官网只回到 1.0）：目标屏幕高度 = 焦点
    // tile 的屏幕高度，世界像素比即所求倍率。无焦点时回退 1.0。
    double? focusedWorldH;
    if (focus != null) {
      final fg = layout.groups
          .where((x) => x.key == focus.group)
          .firstOrNull;
      if (fg != null && fg.tiles.isNotEmpty) {
        final idx = (focus.subimage ?? 0).clamp(0, fg.tiles.length - 1);
        focusedWorldH = fg.tiles[idx].resolvedHeight;
      }
    }

    for (final item in layout.items) {
      final rect = item.worldRect;
      if (visible != null && !visible.overlaps(rect)) continue;
      final isFocusGroup = focus?.group == item.group.key;
      final isFocusSubimage =
          isFocusGroup && focus?.subimage == item.subimageIndex;
      final image = item.image;
      // 悬停倍率：非焦点子图且存在焦点 → 放大到焦点 tile 同档屏幕尺寸。
      final hoverScale = (!isFocusSubimage &&
              !item.isInFlight &&
              focusedWorldH != null &&
              item.tile.resolvedHeight > 0)
          ? (focusedWorldH / item.tile.resolvedHeight).clamp(1.0, 3.0)
          : 1.0;
      tiles.add(
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: _CanvasTile(
            group: item.group,
            tile: item.tile,
            subimageIndex: item.subimageIndex,
            isFocusGroup: isFocusGroup,
            isFocusSubimage: isFocusSubimage,
            isPinned: image != null && pinned.contains(image.id),
            cameraScale: camera.scale,
            uiPointers: _uiPointers,
            hoverScale: hoverScale,
            onSelect: () => _onTileTap(item),
          ),
        ),
      );
      // ×N 徽标（官网组张数徽标）：每组贴一次，组包围盒右下。
      final groupKey = item.group.key;
      if (!groupBadgeEmitted.contains(groupKey) &&
          item.group.tiles.length > 1) {
        groupBadgeEmitted.add(groupKey);
        final gr = item.groupRect;
        tiles.add(
          Positioned(
            left: gr.right - 60,
            top: gr.bottom - 30,
            width: 60,
            height: 30,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Transform.scale(
                scale: (1 / camera.scale).clamp(0.4, 2.5),
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '×${item.group.tiles.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return tiles;
  }

  void _onTileTap(CanvasFeedItem item) {
    // 生成中占位槽不参与选中/飞行（官网 inflight tile 无焦点语义）
    if (item.isInFlight || item.image == null) return;
    final layout = ref.read(canvasFeedLayoutProvider);
    final focus = ref.read(generationCanvasGroupSelectionProvider);
    final isFocused = focus?.group == item.group.key &&
        focus?.subimage == item.subimageIndex;
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
      _syncPreviewToImage(item.image!);
      _flyToSubimage(layout, item.group, item.subimageIndex);
    }
  }

  Widget _buildEdgeBars(
    BuildContext context,
    CanvasFeedLayoutResult layout,
    CanvasFocus? focus,
    CanvasCamera camera,
    ThemeData theme,
  ) {
    final g = layout.groups
        .where((x) => x.key == focus!.group)
        .firstOrNull;
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
        _consumedUiPointers.add(e.pointer);
      },
      child: child,
    );

    // 官网 edge bar 贴焦点 tile 四周（非钉屏幕三边）：
    // 顶条 = tile 顶边中心上方 76px，左条 = tile 左边中点左移 24px，
    // 底左/底右 = tile 底边两侧；全部按 --canvas-ui-scale=1/相机 反缩放，
    // 屏幕恒定大小并随焦点 tile 移动。
    final item = layout.items
        .where(
          (it) =>
              it.group.key == g.key &&
              it.subimageIndex == (focus!.subimage ?? 0),
        )
        .firstOrNull;
    if (item == null) return const SizedBox.shrink();
    final worldRect = item.worldRect;
    final s = camera.scale;
    final uiScale = (1 / s).clamp(0.4, 2.5);
    // 世界坐标 → 屏幕坐标（offset = 平移量，scale = 缩放）
    final tileLeft = worldRect.left * s + camera.offset.dx;
    final tileTop = worldRect.top * s + camera.offset.dy;
    final tileRight = worldRect.right * s + camera.offset.dx;
    final tileBottom = worldRect.bottom * s + camera.offset.dy;
    final tileCenterX = (tileLeft + tileRight) / 2;
    // CSS transform-origin 语义：锚点先在屏幕坐标定位，再整体按
    // uiScale 缩放自身大小（translate 分量含在 scale 内一起缩放）。
    Widget barAt(
      double anchorX,
      double anchorY,
      Alignment anchor,
      Widget child,
    ) {
      return Positioned(
        left: anchorX,
        top: anchorY,
        child: Transform.scale(
          scale: uiScale,
          alignment: anchor,
          child: FractionalTranslation(
            // Alignment(-1..+1) → 锚点平移系数：左=0、中=-0.5、右=-1
            translation: Offset(
              -(anchor.x + 1) / 2,
              -(anchor.y + 1) / 2,
            ),
            child: child,
          ),
        ),
      );
    }

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // top.center：enhance|variations|upscale ‖ set-init|edit|inpaint|send
          // 官网 translateY(-76px) → 条整体悬在 tile 上方 76px（屏幕系
          // 经 uiScale 折回世界偏移）。
          barAt(
            tileCenterX,
            tileTop - 76 * uiScale,
            Alignment.bottomCenter,
            guarded(
              CanvasEdgeToolbar(
                zone: CanvasToolbarZone.top,
                image: img,
                group: g,
                focus: focus,
              ),
            ),
          ),
          // bottom.start：宽×高 ‖ ⚙settings | 种子药丸
          // 贴 tile 左下角内侧。
          barAt(
            tileLeft + 12 * uiScale,
            tileBottom - 12 * uiScale,
            Alignment.bottomLeft,
            guarded(
              CanvasEdgeToolbar(
                zone: CanvasToolbarZone.bottomStart,
                image: img,
                group: g,
                focus: focus,
              ),
            ),
          ),
          // bottom.end：[contest|pin|copy|download] [info] [explore-upload]
          // 贴 tile 右下角内侧。
          barAt(
            tileRight - 12 * uiScale,
            tileBottom - 12 * uiScale,
            Alignment.bottomRight,
            guarded(
              CanvasEdgeToolbar(
                zone: CanvasToolbarZone.bottomEnd,
                image: img,
                group: g,
                focus: focus,
              ),
            ),
          ),
        ],
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
    final ctrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final groups = layout.groups;
    if (groups.isEmpty) return KeyEventResult.ignored;

    // 官网 WASD 平移：按住持续移动（键松开/失焦即停；锁相机/Ctrl 时不触发）
    if (_wasdKeysSet.contains(key) &&
        !ctrl &&
        !shift &&
        !_cameraLocked) {
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
        final g =
            groups.where((x) => x.key == focus.group).firstOrNull;
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
        final g =
            groups.where((x) => x.key == focus.group).firstOrNull;
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
    if (ctrl && key == LogicalKeyboardKey.digit0) {
      ref.read(generationCanvasGroupSelectionProvider.notifier).clear();
      _camera.flyTo(CanvasCamera.init);
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyS) {
      final img = _resolveSelectedImage(layout, focus);
      if (img != null && img.canSave) {
        unawaited(_saveFocusedImage(img));
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.numpadAdd) {
      _camera.zoomBy(
        1.3,
        anchor: Offset(_viewport.width / 2, _viewport.height / 2),
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _camera.zoomBy(
        1 / 1.3,
        anchor: Offset(_viewport.width / 2, _viewport.height / 2),
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit1 ||
        key == LogicalKeyboardKey.numpad1) {
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
      (e.buttons & (kPrimaryMouseButton | kMiddleMouseButton)) != 0;

  void _onPointerDown(PointerDownEvent e) {
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
      // 双指捏合：桌面端走触控板 PointerScrollEvent.scale 信号，
      // PointerMove 无 scale 增量，这里不处理。
      return;
    }
    if (_pointers.isEmpty || !_isPanButton(e)) return;

    // 官网 5px 死区：累计位移超过阈值才算拖拽（点击 tile 不触发平移）
    if (!_panActive) {
      _panAccum += e.localDelta;
      if (_panAccum.distance <= 5) return;
      _panActive = true;
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
        _inertiaVelocity = Offset(
          e.localDelta.dx / dt,
          e.localDelta.dy / dt,
        );
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

    if (ctrl) {
      // 官网：Ctrl+滚轮缩放；平滑档 exp(clamp(-0.01·dy,±0.25))，
      // 离散档 dy<0 ×1.2 / dy>0 ÷1.2，锚点=光标
      final smooth = ref.read(canvasSmoothZoomNotifierProvider);
      if (smooth) {
        final factor = math.exp((-0.01 * dy).clamp(-0.25, 0.25));
        _camera.zoomBy(factor, anchor: e.localPosition);
      } else {
        _camera.zoomBy(dy < 0 ? 1.2 : 1 / 1.2, anchor: e.localPosition);
      }
    } else {
      // 裸滚轮平移（无缩放、无翻页）；Shift 纵转横
      _camera.panBy(
        shift ? Offset(-(e.scrollDelta.dx + dy), 0) : Offset(-e.scrollDelta.dx, -dy),
      );
    }
  }

  /// 双击空处切「放大填充」；单击/双击落在 tile 或 UI 上不触发。
  void _onCanvasTapUp(TapUpDetails details) {
    // 用世界坐标命中检测：落在任一 tile 上 → 是 tile tap，不是画布 tap
    final layout = ref.read(canvasFeedLayoutProvider);
    final camera = ref.read(generationCanvasCameraProvider);
    final world = Offset(
      (details.localPosition.dx - camera.offset.dx) / camera.scale,
      (details.localPosition.dy - camera.offset.dy) / camera.scale,
    );
    final hitTile = layout.items.any(
      (it) => it.worldRect.contains(world),
    );
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
      // 官网：切放大填充同时按新 fitMax 重飞焦点组
      final focus = ref.read(generationCanvasGroupSelectionProvider);
      final layout = ref.read(canvasFeedLayoutProvider);
      final g = focus == null
          ? null
          : layout.groups
              .where((x) => x.key == focus.group)
              .firstOrNull;
      if (g != null) {
        if (focus!.subimage != null) {
          _flyToSubimage(layout, g, focus.subimage!);
        } else {
          _flyToGroup(layout, g);
        }
      }
    }
  }
}

/// 单 tile：非焦点 scale(0.98) + 悬停回 1 + hover 迷你条（官网 R.I3 condensed）
class _CanvasTile extends ConsumerStatefulWidget {
  const _CanvasTile({
    required this.group,
    required this.tile,
    required this.subimageIndex,
    required this.isFocusGroup,
    required this.isFocusSubimage,
    required this.isPinned,
    required this.cameraScale,
    required this.uiPointers,
    required this.hoverScale,
    required this.onSelect,
  });

  final CanvasFeedGroup group;
  final CanvasTileSpec tile;
  final int subimageIndex;
  final bool isFocusGroup;
  final bool isFocusSubimage;
  final bool isPinned;
  final double cameraScale;
  final Set<int> uiPointers;

  /// 自研悬停倍率：非焦点组悬停放大到焦点 tile 同档屏幕尺寸。
  /// 官网只有回 1.0；用户拍板超出官网，按焦点屏幕高度等比放大。
  final double hoverScale;
  final VoidCallback onSelect;

  @override
  ConsumerState<_CanvasTile> createState() => _CanvasTileState();
}

class _CanvasTileState extends ConsumerState<_CanvasTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final unfocused = !widget.isFocusSubimage;
    // 官网：非焦点 scale(0.98)；悬停回 1；0.25s cubic-bezier(0.22,1,0.36,1)。
    // 自研扩展：非焦点组悬停直接放大到 hoverScale（焦点同档屏幕尺寸）。
    final base = unfocused && !_hovering ? 0.98 : 1.0;
    final scale =
        _hovering && unfocused && widget.hoverScale > 1.0
            ? widget.hoverScale
            : base;

    // 生成中占位槽（官网 image-grid-generating）：批参数尺寸 + 三点
    // 弹跳动画，有流式帧时叠预览帧。
    if (widget.tile.isInFlight) {
      return _InflightSlotTile(slot: widget.tile.slot!);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 250),
        curve: const Cubic(0.22, 1, 0.36, 1),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: buildGeneratedImageCard(
                  context: context,
                  ref: ref,
                  image: widget.tile.image!,
                  showIndex: false,
                  canvasTile: true,
                  onTap: widget.onSelect,
                ),
              ),
            ),
            // 钉住角标（官网钉板标记）：实心 pin，右上反缩放恒屏大小
            if (widget.isPinned)
              Positioned(
                top: -30 / widget.cameraScale.clamp(0.5, 2.5),
                right: 0,
                child: Transform.scale(
                  scale: (1 / widget.cameraScale).clamp(0.4, 2.5),
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
            // 非焦点 hover 迷你条：pin|copy|download + 种子
            // （官网 --canvas-ui-scale 反缩放，屏幕恒定大小）
            if (unfocused && _hovering)
              Positioned(
                left: 0,
                right: 0,
                bottom: -46 / widget.cameraScale.clamp(0.5, 2.5),
                child: Transform.scale(
                  scale: (1 / widget.cameraScale).clamp(0.4, 2.5),
                  alignment: Alignment.bottomCenter,
                  child: Center(
                    child: Listener(
                      onPointerDown: (e) => widget.uiPointers.add(e.pointer),
                      onPointerUp: (e) => widget.uiPointers.remove(e.pointer),
                      onPointerCancel: (e) =>
                          widget.uiPointers.remove(e.pointer),
                      child: CanvasMiniToolbar(
                        image: widget.tile.image!,
                        group: widget.group,
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

/// 网格底纹：世界坐标 256px 倍数线（随相机平移缩放正确对齐）
class _GridPainter extends CustomPainter {
  _GridPainter({required this.camera, required this.theme});

  final CanvasCamera camera;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = theme.colorScheme.outlineVariant.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    const step = 256.0;
    final s = camera.scale;
    final off = camera.offset;
    final stepScreen = step * s;
    if (stepScreen < 4) return;
    // 世界线 k·256 → 屏幕 k·256·s + off；首条可见线 = off 取模步长
    final startX = off.dx - (off.dx / stepScreen).floor() * stepScreen;
    final startY = off.dy - (off.dy / stepScreen).floor() * stepScreen;
    for (var x = startX; x < size.width; x += stepScreen) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = startY; y < size.height; y += stepScreen) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.camera != camera || old.theme != theme;
}

/// 生成中占位 tile（官网 `image-grid-generating`）：批参数尺寸的卡面 +
/// 三点弹跳加载动画；有流式预览帧时盖一层进度图。
class _InflightSlotTile extends StatefulWidget {
  const _InflightSlotTile({required this.slot});

  final StreamPreviewSlot slot;

  @override
  State<_InflightSlotTile> createState() => _InflightSlotTileState();
}

class _InflightSlotTileState extends State<_InflightSlotTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = widget.slot.previewBytes;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: theme.colorScheme.surfaceContainerHigh,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (preview != null && preview.isNotEmpty)
              Image.memory(preview, fit: BoxFit.cover, gaplessPlayback: true),
            Container(
              color: theme.colorScheme.surface.withValues(
                alpha: preview != null && preview.isNotEmpty ? 0.35 : 0.0,
              ),
            ),
            Center(
              child: AnimatedBuilder(
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
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      dot(0),
                      const SizedBox(width: 8),
                      dot(1),
                      const SizedBox(width: 8),
                      dot(2),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
