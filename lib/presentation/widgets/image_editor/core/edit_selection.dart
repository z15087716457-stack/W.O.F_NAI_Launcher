import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'edit_image_actions.dart';
import 'editor_state.dart';
import '../../../../core/utils/localization_extension.dart';

/// A selection is a preview over the original raster until explicitly committed.
/// Cancelling never destroys source pixels, and each committed transform is undoable.
class EditSelection {
  EditSelection(this.state);
  final EditorState state;
  String? layerId;
  ui.Image? _outside, _content, _preview;
  Rect? _source, target;
  double angle = 0;
  int? _handle;
  Offset? _pointer;
  Rect? _dragRect;
  double _dragAngle = 0;
  bool get active => _content != null;
  bool get dragging => _pointer != null;
  bool get changed => active && (target != _source || angle != 0);
  ui.Image? get preview => _preview;

  void begin(Path path) {
    commit();
    final layer = state.layerManager.activeLayer;
    final bounds = path.getBounds().intersect(Offset.zero & state.canvasSize);
    if (layer == null || layer.locked || bounds.isEmpty) return;
    layerId = layer.id;
    _source = target = Rect.fromLTRB(
      bounds.left.floorToDouble(),
      bounds.top.floorToDouble(),
      bounds.right.ceilToDouble(),
      bounds.bottom.ceilToDouble(),
    );
    final raster = renderEditLayer(layer, state.canvasSize);
    _outside = _record(state.canvasSize, (canvas) {
      canvas.drawImage(raster, Offset.zero, Paint());
      canvas.drawPath(path, Paint()..blendMode = BlendMode.clear);
    });
    _content = _record(_source!.size, (canvas) {
      canvas.translate(-_source!.left, -_source!.top);
      canvas.clipPath(path);
      canvas.drawImage(raster, Offset.zero, Paint());
    });
    raster.dispose();
    state.selectionManager.setSelection(path, saveHistory: false);
    _refresh();
  }

  static ui.Image _record(Size size, void Function(Canvas) draw) {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(size.width.ceil(), size.height.ceil());
    picture.dispose();
    return image;
  }

  List<Offset> get handles => target == null
      ? []
      : [
          target!.topLeft,
          target!.topCenter,
          target!.topRight,
          target!.centerLeft,
          target!.centerRight,
          target!.bottomLeft,
          target!.bottomCenter,
          target!.bottomRight,
        ];
  Offset _rotate(Offset p, {bool inverse = false}) {
    final a = inverse ? -angle : angle, c = target!.center, d = p - c;
    return c +
        Offset(
          d.dx * math.cos(a) - d.dy * math.sin(a),
          d.dx * math.sin(a) + d.dy * math.cos(a),
        );
  }

  Offset get rotationHandle =>
      _rotate(target!.topCenter - Offset(0, 20 / state.canvasController.scale));
  bool pointerDown(Offset point) {
    if (!active) return false;
    final radius = 10 / state.canvasController.scale;
    _handle = null;
    if ((point - rotationHandle).distance <= radius) {
      _handle = 8;
    } else {
      for (var i = 0; i < handles.length; i++) {
        if ((point - _rotate(handles[i])).distance <= radius) {
          _handle = i;
          break;
        }
      }
      if (_handle == null && !target!.contains(_rotate(point, inverse: true))) {
        commit();
        return false;
      }
      _handle ??= -1;
    }
    _pointer = point;
    _dragRect = target;
    _dragAngle = angle;
    return true;
  }

  void pointerMove(Offset point) {
    if (!dragging) return;
    final delta = point - _pointer!;
    if (_handle == -1) {
      target = _dragRect!.shift(delta);
    } else if (_handle == 8) {
      final c = _dragRect!.center;
      angle =
          _dragAngle +
          math.atan2(point.dy - c.dy, point.dx - c.dx) -
          math.atan2(_pointer!.dy - c.dy, _pointer!.dx - c.dx);
    } else {
      final dx =
              delta.dx * math.cos(_dragAngle) + delta.dy * math.sin(_dragAngle),
          dy =
              -delta.dx * math.sin(_dragAngle) +
              delta.dy * math.cos(_dragAngle);
      final r = _dragRect!;
      var left = r.left, top = r.top, right = r.right, bottom = r.bottom;
      if ([0, 3, 5].contains(_handle)) {
        left = math.min(r.right - 1, r.left + dx);
      }
      if ([2, 4, 7].contains(_handle)) {
        right = math.max(r.left + 1, r.right + dx);
      }
      if ([0, 1, 2].contains(_handle)) top = math.min(r.bottom - 1, r.top + dy);
      if ([5, 6, 7].contains(_handle)) {
        bottom = math.max(r.top + 1, r.bottom + dy);
      }
      target = Rect.fromLTRB(left, top, right, bottom);
    }
    _refresh();
  }

  void pointerUp() {
    _pointer = null;
    _handle = null;
  }

  void copyToLayer({bool cut = false}) {
    if (!active) return;
    final image = _record(state.canvasSize, (canvas) {
      canvas.translate(target!.center.dx, target!.center.dy);
      canvas.rotate(angle);
      canvas.drawImageRect(
        _content!,
        Offset.zero & _contentSize,
        Rect.fromCenter(
          center: Offset.zero,
          width: target!.width,
          height: target!.height,
        ),
        Paint(),
      );
    });
    state.historyManager.execute(
      CopyEditSelectionAction(
        sourceId: layerId!,
        image: image,
        remaining: cut ? _outside!.clone() : null,
        name: currentL10n.editor_layerName(state.layerManager.layerCount + 1),
      ),
      state,
    );
    cancel();
  }

  void _refresh() {
    _preview?.dispose();
    _preview = _record(state.canvasSize, (canvas) {
      canvas.drawImage(_outside!, Offset.zero, Paint());
      canvas.translate(target!.center.dx, target!.center.dy);
      canvas.rotate(angle);
      canvas.drawImageRect(
        _content!,
        Offset.zero & _contentSize,
        Rect.fromCenter(
          center: Offset.zero,
          width: target!.width,
          height: target!.height,
        ),
        Paint()..filterQuality = FilterQuality.medium,
      );
    });
    state.notifyCanvasPreview();
  }

  Size get _contentSize =>
      Size(_content!.width.toDouble(), _content!.height.toDouble());
  void commit() {
    if (changed && state.layerManager.getLayerById(layerId!) != null) {
      state.historyManager.execute(
        ReplaceEditRasterAction(
          layerId: layerId!,
          image: _preview!.clone(),
          description: 'Transform Selection',
        ),
        state,
      );
    }
    cancel();
  }

  void delete() {
    if (!active) return;
    state.historyManager.execute(
      ReplaceEditRasterAction(
        layerId: layerId!,
        image: _outside!.clone(),
        description: 'Delete Selection',
      ),
      state,
    );
    cancel();
  }

  void cancel() {
    _outside?.dispose();
    _content?.dispose();
    _preview?.dispose();
    _outside = _content = _preview = null;
    layerId = null;
    target = _source = null;
    angle = 0;
    _pointer = null;
    _handle = null;
    state.selectionManager.clearSelection(saveHistory: false);
    if (!state.isDisposed) state.notifyCanvasPreview();
  }

  void paintHandles(Canvas canvas) {
    if (!active) return;
    final scale = state.canvasController.scale;
    canvas.save();
    canvas.translate(target!.center.dx, target!.center.dy);
    canvas.rotate(angle);
    canvas.translate(-target!.center.dx, -target!.center.dy);
    final pen = Paint()
      ..color = const Color(0xff55aaff)
      ..strokeWidth = 1 / scale
      ..style = PaintingStyle.stroke;
    canvas.drawRect(target!, pen);
    for (final p in handles) {
      final box = Rect.fromCenter(
        center: p,
        width: 6 / scale,
        height: 6 / scale,
      );
      canvas.drawRect(box, Paint()..color = Colors.white);
      canvas.drawRect(box, pen);
    }
    canvas.drawLine(
      target!.topCenter,
      target!.topCenter - Offset(0, 20 / scale),
      pen,
    );
    canvas.drawCircle(
      target!.topCenter - Offset(0, 20 / scale),
      3 / scale,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      target!.topCenter - Offset(0, 20 / scale),
      3 / scale,
      pen,
    );
    canvas.restore();
  }
}
