import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/inpaint_outpaint_utils.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../themes/studio_typography.dart';
import '../core/canvas_controller.dart';

typedef OutpaintEdgeDragPreviewChanged = void Function(OutpaintEdges edges);
typedef OutpaintEdgeDragCommitted =
    Future<void> Function(
      OutpaintEdges edges, {
      required OutpaintHorizontalSnapTarget horizontalSnapTarget,
      required OutpaintVerticalSnapTarget verticalSnapTarget,
    });
typedef OutpaintFrameResizeCommitted =
    Future<void> Function(
      OutpaintFrameDelta delta, {
      required OutpaintHorizontalSnapTarget horizontalSnapTarget,
      required OutpaintVerticalSnapTarget verticalSnapTarget,
    });

/// Four thin edges and four transparent corners, with feedback only on hover
/// or drag. No floating knobs or automatic commit before pointer release.
class OutpaintEdgeDragOverlay extends StatefulWidget {
  static const double edgeHitSlop = 8;
  final Size canvasSize;
  final CanvasController controller;
  final OutpaintEdgeDragPreviewChanged? onPreviewChanged;
  final OutpaintEdgeDragCommitted onCommitted;
  final OutpaintFrameResizeCommitted? onFrameResizeCommitted;
  final bool enabled;
  const OutpaintEdgeDragOverlay({
    super.key,
    required this.canvasSize,
    required this.controller,
    required this.onCommitted,
    this.onFrameResizeCommitted,
    this.onPreviewChanged,
    this.enabled = true,
  });

  static Rect screenCanvasRect(CanvasController controller, Size canvasSize) =>
      Rect.fromPoints(
        controller.canvasToScreen(Offset.zero, canvasSize: canvasSize),
        controller.canvasToScreen(
          Offset(canvasSize.width, canvasSize.height),
          canvasSize: canvasSize,
        ),
      );

  static bool isResizeInteractionPoint({
    required Offset localPosition,
    required Size viewportSize,
    required Size canvasSize,
    required CanvasController controller,
  }) =>
      controller.rotation == 0 &&
      !controller.isMirroredHorizontally &&
      _zones(
        screenCanvasRect(controller, canvasSize),
        controller.scale,
        viewportSize,
      ).values.any((rect) => rect.contains(localPosition));

  static Map<_Handle, Rect> _zones(Rect r, double scale, Size viewport) {
    final edge = math.max(edgeHitSlop, 2 * scale),
        corner = math.max(12.0, 4 * scale);
    final half = corner / 2, bounds = Offset.zero & viewport;
    Rect point(Offset center) =>
        Rect.fromCenter(center: center, width: corner, height: corner);
    return {
      _Handle.left: Rect.fromLTRB(
        r.left - edge / 2,
        r.top + half,
        r.left + edge / 2,
        r.bottom - half,
      ),
      _Handle.right: Rect.fromLTRB(
        r.right - edge / 2,
        r.top + half,
        r.right + edge / 2,
        r.bottom - half,
      ),
      _Handle.top: Rect.fromLTRB(
        r.left + half,
        r.top - edge / 2,
        r.right - half,
        r.top + edge / 2,
      ),
      _Handle.bottom: Rect.fromLTRB(
        r.left + half,
        r.bottom - edge / 2,
        r.right - half,
        r.bottom + edge / 2,
      ),
      _Handle.topLeft: point(r.topLeft),
      _Handle.topRight: point(r.topRight),
      _Handle.bottomLeft: point(r.bottomLeft),
      _Handle.bottomRight: point(r.bottomRight),
    }.map((handle, rect) => MapEntry(handle, rect.intersect(bounds)));
  }

  @override
  State<OutpaintEdgeDragOverlay> createState() =>
      _OutpaintEdgeDragOverlayState();
}

class _OutpaintEdgeDragOverlayState extends State<OutpaintEdgeDragOverlay> {
  _Handle? _active, _hover;
  int? _pointer;
  Offset? _startPosition;
  Offset _drag = Offset.zero;
  double _startScale = 1;
  Size? _startCanvasSize;
  Rect? _startCanvasRect;
  bool _committing = false;
  bool get _available =>
      widget.enabled &&
      !_committing &&
      widget.controller.rotation == 0 &&
      !widget.controller.isMirroredHorizontally;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewport = constraints.biggest;
      return ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final currentCanvas = OutpaintEdgeDragOverlay.screenCanvasRect(
            widget.controller,
            widget.canvasSize,
          );
          final canvas = _active == null ? currentCanvas : _startCanvasRect!;
          final resolved = _resolve(), preview = resolved?.geometry;
          final color = Theme.of(context).colorScheme.primary;
          return Stack(
            children: [
              if (preview != null && preview.hasAppliedChange) ...[
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _PreviewPainter(
                        _previewRect(canvas, preview),
                        color,
                      ),
                    ),
                  ),
                ),
                ..._labels(context, viewport, canvas, resolved!),
              ],
              if (_available)
                for (final entry in OutpaintEdgeDragOverlay._zones(
                  currentCanvas,
                  widget.controller.scale,
                  viewport,
                ).entries)
                  if (!entry.value.isEmpty)
                    Positioned.fromRect(
                      rect: entry.value,
                      child: MouseRegion(
                        key: Key('outpaint_edge_${entry.key.suffix}'),
                        cursor: entry.key.cursor,
                        opaque: true,
                        onEnter: (_) {
                          if (_active == null) {
                            setState(() => _hover = entry.key);
                          }
                        },
                        onExit: (_) {
                          if (_active == null) setState(() => _hover = null);
                        },
                        child: Listener(
                          key: Key('outpaint_handle_${entry.key.suffix}'),
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (event) => _down(event, entry.key),
                          child: DecoratedBox(
                            key: _active == entry.key || _hover == entry.key
                                ? Key('outpaint_highlight_${entry.key.suffix}')
                                : null,
                            decoration: BoxDecoration(
                              color: color.withValues(
                                alpha: _active == entry.key
                                    ? .3
                                    : _hover == entry.key
                                    ? .15
                                    : 0,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          );
        },
      );
    },
  );

  List<Widget> _labels(
    BuildContext context,
    Size viewport,
    Rect canvas,
    _Resize resolved,
  ) {
    final r = _previewRect(canvas, resolved.geometry),
        d = resolved.delta,
        l10n = context.l10n;
    String amount(int n) => '${n > 0 ? '+' : ''}${n}px';
    final labels = [
      if (d.left != 0) '${l10n.editor_edgeLeft}: ${amount(d.left)}',
      if (d.right != 0) '${l10n.editor_edgeRight}: ${amount(d.right)}',
      if (d.top != 0) '${l10n.editor_edgeTop}: ${amount(d.top)}',
      if (d.bottom != 0) '${l10n.editor_edgeBottom}: ${amount(d.bottom)}',
    ];
    Widget text(String value, double y, String key, double opacity) {
      final width = math.min(
        math.max(0.0, viewport.width - 16),
        math.max(r.width, 160.0),
      );
      final left = (r.center.dx - width / 2).clamp(
        8.0,
        math.max(8.0, viewport.width - width - 8),
      );
      return Positioned(
        left: left.toDouble(),
        top: y.clamp(0.0, math.max(0.0, viewport.height - 20)),
        width: width,
        height: 20,
        child: IgnorePointer(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .88),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  value,
                  key: Key(key),
                  style: TextStyle(
                    fontFamily: StudioTypography.mono,
                    fontFamilyFallback: StudioTypography.fallback,
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: opacity),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return [
      text(labels.join('  '), r.top - 24, 'outpaint_drag_delta', .6),
      text(
        '${resolved.geometry.width} × ${resolved.geometry.height}',
        math.min(r.bottom + 8, viewport.height - 80),
        'outpaint_drag_size',
        1,
      ),
    ];
  }

  Rect _previewRect(Rect canvas, OutpaintFrameResolvedGeometry geometry) {
    final sx = canvas.width / geometry.sourceWidth,
        sy = canvas.height / geometry.sourceHeight;
    return Rect.fromLTRB(
      canvas.left + geometry.appliedFrameLeft * sx,
      canvas.top + geometry.appliedFrameTop * sy,
      canvas.left + geometry.appliedFrameRight * sx,
      canvas.top + geometry.appliedFrameBottom * sy,
    );
  }

  void _down(PointerDownEvent event, _Handle handle) {
    if (!_available || _pointer != null || event.buttons != kPrimaryButton) {
      return;
    }
    _pointer = event.pointer;
    _startPosition = event.position;
    _startScale = widget.controller.scale;
    _startCanvasSize = widget.canvasSize;
    _startCanvasRect = OutpaintEdgeDragOverlay.screenCanvasRect(
      widget.controller,
      widget.canvasSize,
    );
    GestureBinding.instance.pointerRouter.addRoute(event.pointer, _route);
    setState(() {
      _active = handle;
      _hover = null;
      _drag = Offset.zero;
    });
  }

  void _route(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      final before = _resolve()?.delta;
      setState(() => _drag = event.position - _startPosition!);
      final after = _resolve()?.delta;
      if (after != null &&
          (after.left, after.right, after.top, after.bottom) !=
              (before?.left, before?.right, before?.top, before?.bottom) &&
          !after.expansionEdges.isEmpty) {
        widget.onPreviewChanged?.call(after.expansionEdges);
      }
    } else if (event is PointerUpEvent) {
      _stopRoute();
      unawaited(_commit());
    } else if (event is PointerCancelEvent) {
      _reset();
    }
  }

  _Resize? _resolve() {
    final handle = _active;
    if (handle == null) return null;
    final source = _startCanvasSize!;
    // Mask editor uses the official 64px increment, including JS half ties.
    // Preview and commit receive precisely the same snapped frame.
    int snap(double value) => ((value / 64) + .5).floor() * 64;
    final x = snap(
      _drag.dx / _startScale * (handle.affectsLeft ? -1 : 1),
    ).clamp(64 - source.width.round(), 4096 - source.width.round()).toInt();
    final y = snap(
      _drag.dy / _startScale * (handle.affectsTop ? -1 : 1),
    ).clamp(64 - source.height.round(), 4096 - source.height.round()).toInt();
    final delta = OutpaintFrameDelta(
      left: handle.affectsLeft ? x : 0,
      right: handle.affectsRight ? x : 0,
      top: handle.affectsTop ? y : 0,
      bottom: handle.affectsBottom ? y : 0,
    );
    if (delta.isEmpty) return null;
    final geometry = InpaintOutpaintUtils.tryResolveFrameGeometry(
      sourceWidth: source.width.round(),
      sourceHeight: source.height.round(),
      delta: delta,
      horizontalSnapTarget: handle.horizontalTarget,
      verticalSnapTarget: handle.verticalTarget,
    );
    return geometry == null || !geometry.hasAppliedChange
        ? null
        : _Resize(delta, geometry);
  }

  Future<void> _commit() async {
    final resolved = _resolve(), handle = _active;
    if (resolved == null || handle == null) {
      _reset();
      return;
    }
    setState(() => _committing = true);
    try {
      if (widget.onFrameResizeCommitted != null) {
        await widget.onFrameResizeCommitted!(
          resolved.delta,
          horizontalSnapTarget: handle.horizontalTarget,
          verticalSnapTarget: handle.verticalTarget,
        );
      } else if (resolved.delta.cropEdges.isEmpty) {
        await widget.onCommitted(
          resolved.delta.expansionEdges,
          horizontalSnapTarget: handle.horizontalTarget,
          verticalSnapTarget: handle.verticalTarget,
        );
      }
    } finally {
      if (mounted) _reset();
    }
  }

  void _stopRoute() {
    if (_pointer != null) {
      GestureBinding.instance.pointerRouter.removeRoute(_pointer!, _route);
    }
    _pointer = null;
  }

  void _reset() {
    _stopRoute();
    setState(() {
      _active = null;
      _hover = null;
      _committing = false;
      _drag = Offset.zero;
      _startCanvasSize = null;
      _startCanvasRect = null;
    });
  }

  @override
  void dispose() {
    _stopRoute();
    super.dispose();
  }
}

class _Resize {
  final OutpaintFrameDelta delta;
  final OutpaintFrameResolvedGeometry geometry;
  _Resize(this.delta, this.geometry);
}

enum _Handle {
  left,
  right,
  top,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  String get suffix => switch (this) {
    topLeft => 'top_left',
    topRight => 'top_right',
    bottomLeft => 'bottom_left',
    bottomRight => 'bottom_right',
    _ => name,
  };
  bool get affectsLeft => this == left || this == topLeft || this == bottomLeft;
  bool get affectsRight =>
      this == right || this == topRight || this == bottomRight;
  bool get affectsTop => this == top || this == topLeft || this == topRight;
  bool get affectsBottom =>
      this == bottom || this == bottomLeft || this == bottomRight;
  OutpaintHorizontalSnapTarget get horizontalTarget => affectsLeft
      ? OutpaintHorizontalSnapTarget.left
      : OutpaintHorizontalSnapTarget.right;
  OutpaintVerticalSnapTarget get verticalTarget => affectsTop
      ? OutpaintVerticalSnapTarget.top
      : OutpaintVerticalSnapTarget.bottom;
  MouseCursor get cursor => switch (this) {
    left || right => SystemMouseCursors.resizeLeftRight,
    top || bottom => SystemMouseCursors.resizeUpDown,
    topLeft || bottomRight => SystemMouseCursors.resizeUpLeftDownRight,
    topRight || bottomLeft => SystemMouseCursors.resizeUpRightDownLeft,
  };
}

class _PreviewPainter extends CustomPainter {
  final Rect rect;
  final Color color;
  _PreviewPainter(this.rect, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in (Path()..addRect(rect)).computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 10) {
        canvas.drawPath(
          metric.extractPath(start, math.min(start + 6, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) =>
      old.rect != rect || old.color != color;
}
