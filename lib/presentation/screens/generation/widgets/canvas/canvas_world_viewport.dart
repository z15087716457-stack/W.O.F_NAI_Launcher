import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'generation_canvas_controller.dart';

/// Lays out images at their native size and applies the camera during painting
/// and hit testing. The viewport bounds the interaction surface, not the world.
class CanvasWorldViewport extends MultiChildRenderObjectWidget {
  const CanvasWorldViewport({
    super.key,
    required this.camera,
    required super.children,
  });

  final CanvasCamera camera;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCanvasWorldViewport(camera);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _RenderCanvasWorldViewport).camera = camera;
  }
}

class CanvasWorldItem extends ParentDataWidget<_CanvasWorldParentData> {
  const CanvasWorldItem({super.key, required this.rect, required super.child});

  final Rect rect;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as _CanvasWorldParentData;
    if (data.rect == rect) return;
    data.rect = rect;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => CanvasWorldViewport;
}

class _CanvasWorldParentData extends ContainerBoxParentData<RenderBox> {
  Rect rect = Rect.zero;
}

class _RenderCanvasWorldViewport extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _CanvasWorldParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _CanvasWorldParentData> {
  _RenderCanvasWorldViewport(this._camera);

  CanvasCamera _camera;

  set camera(CanvasCamera value) {
    if (_camera.offset == value.offset && _camera.scale == value.scale) return;
    _camera = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _CanvasWorldParentData) {
      child.parentData = _CanvasWorldParentData();
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    size = constraints.biggest;
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _CanvasWorldParentData;
      child.layout(BoxConstraints.tight(data.rect.size));
      child = data.nextSibling;
    }
  }

  Matrix4 _transformFor(RenderBox child) {
    final data = child.parentData! as _CanvasWorldParentData;
    final origin = _camera.worldToScreen(data.rect.topLeft);
    return Matrix4.identity()
      ..translateByDouble(origin.dx, origin.dy, 0, 1)
      ..scaleByDouble(_camera.scale, _camera.scale, 1, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final visible = _camera.visibleWorldRect(size);
    var child = firstChild;
    while (child != null) {
      final current = child;
      final data = current.parentData! as _CanvasWorldParentData;
      if (data.rect.overlaps(visible)) {
        context.pushTransform(
          needsCompositing,
          offset,
          _transformFor(current),
          (context, offset) => context.paintChild(current, offset),
        );
      }
      child = data.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final current = child;
      if (result.addWithPaintTransform(
        transform: _transformFor(current),
        position: position,
        hitTest: (result, position) =>
            current.hitTest(result, position: position),
      )) {
        return true;
      }
      child = (current.parentData! as _CanvasWorldParentData).previousSibling;
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transformFor(child));
  }
}
