import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../navigation/window_resize_scope.dart';

/// Cache an expensive, noninteractive decoration during native window resizing.
/// Place controls and content outside this widget so they keep their live layout.
class ResizeDecorationCache extends StatefulWidget {
  const ResizeDecorationCache({super.key, required this.child});

  final Widget child;

  @override
  State<ResizeDecorationCache> createState() => _ResizeDecorationCacheState();
}

class _ResizeDecorationCacheState extends State<ResizeDecorationCache> {
  Widget? _decoration;

  @override
  Widget build(BuildContext context) {
    final active = WindowResizeScope.activeOf(context);
    if (!active || _decoration == null) _decoration = widget.child;
    return _DecorationBitmap(
      active: active,
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
      child: TickerMode(
        enabled: !active,
        child: RepaintBoundary(child: _decoration),
      ),
    );
  }
}

class _DecorationBitmap extends SingleChildRenderObjectWidget {
  const _DecorationBitmap({
    required this.active,
    required this.pixelRatio,
    required super.child,
  });

  final bool active;
  final double pixelRatio;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDecorationBitmap(active: active, pixelRatio: pixelRatio);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderDecorationBitmap renderObject,
  ) {
    renderObject
      ..pixelRatio = pixelRatio
      ..active = active;
  }
}

class _RenderDecorationBitmap extends RenderProxyBox {
  _RenderDecorationBitmap({required bool active, required this.pixelRatio})
    : _active = active;

  double pixelRatio;
  bool _active;
  BoxConstraints? _decorationConstraints;
  ui.Image? _bitmap;

  set active(bool value) {
    if (_active == value) return;
    _active = value;
    _bitmap?.dispose();
    _bitmap = null;
    markNeedsLayout();
    markNeedsPaint();
  }

  @override
  void performLayout() {
    if (!_active || _decorationConstraints == null) {
      _decorationConstraints = constraints;
    }
    child!.layout(_decorationConstraints!, parentUsesSize: true);
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_active) {
      super.paint(context, offset);
      return;
    }
    if (_bitmap == null) {
      // Capture only after this visible decoration has actually painted. Hidden
      // routes never allocate a snapshot, and no asynchronous capture outlives it.
      final scale = math.max(
        size.width / child!.size.width,
        size.height / child!.size.height,
      );
      final translation = Offset(
        (size.width - child!.size.width * scale) / 2,
        (size.height - child!.size.height * scale) / 2,
      );
      context.pushClipRect(needsCompositing, offset, Offset.zero & size, (
        context,
        offset,
      ) {
        context.pushTransform(
          needsCompositing,
          offset,
          Matrix4.translationValues(translation.dx, translation.dy, 0)
            ..scaleByDouble(scale, scale, 1, 1),
          super.paint,
        );
      });
      _bitmap = (child! as RenderRepaintBoundary).toImageSync(
        pixelRatio: pixelRatio,
      );
      return;
    }
    paintImage(
      canvas: context.canvas,
      rect: offset & size,
      image: _bitmap!,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
    );
  }

  @override
  void dispose() {
    _bitmap?.dispose();
    super.dispose();
  }
}
