import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/utils/inpaint_outpaint_utils.dart';
import '../layers/layer.dart';
import '../layers/model3d_layer_data.dart';
import 'editor_state.dart';
import 'history_manager.dart';

class LayerRasterSnapshot {
  LayerRasterSnapshot(Layer layer)
    : image = layer.baseImage?.clone(),
      bytes = layer.baseImageBytes,
      offset = layer.baseImageOffset,
      model3d = layer.model3d,
      strokes = List.of(layer.strokes);
  final ui.Image? image;
  final ui.Offset offset;
  final List<StrokeData> strokes;
  final Uint8List? bytes;
  final Model3dLayerData? model3d;
  void restore(Layer layer) {
    layer.clearStrokes();
    layer.clearBaseImage();
    if (image != null) layer.setBaseImageSync(image!.clone(), bytes);
    layer.setBaseImageOffset(offset);
    layer.model3d = model3d;
    for (final s in strokes) {
      layer.addStroke(s);
    }
  }

  void dispose() => image?.dispose();
}

class ReplaceEditRasterAction extends EditorAction {
  ReplaceEditRasterAction({
    required this.layerId,
    required this.image,
    required this.description,
  });
  final String layerId;
  final ui.Image image;
  @override
  final String description;
  LayerRasterSnapshot? _before;
  @override
  void execute(EditorState state) {
    final layer = state.layerManager.getLayerById(layerId);
    if (layer == null) return;
    _before ??= LayerRasterSnapshot(layer);
    layer.clearStrokes();
    layer.setBaseImageSync(image.clone(), null);
    layer.setBaseImageOffset(Offset.zero);
    state.layerManager.notifyRasterChange();
    state.notifyCanvasPreview();
  }

  @override
  void undo(EditorState state) {
    final layer = state.layerManager.getLayerById(layerId);
    if (layer != null) {
      _before?.restore(layer);
      state.layerManager.notifyRasterChange();
      state.notifyCanvasPreview();
    }
  }

  @override
  void dispose() {
    image.dispose();
    _before?.dispose();
  }
}

/// Commit the edited scene and transparent pixels together in canvas history.
class ReplaceModel3dLayerAction extends EditorAction {
  ReplaceModel3dLayerAction({
    required this.layerId,
    required this.image,
    required this.bytes,
    required this.model3d,
  });
  final String layerId;
  final ui.Image image;
  final Uint8List bytes;
  final Model3dLayerData model3d;
  LayerRasterSnapshot? _before;
  @override
  void execute(EditorState state) {
    final layer = state.layerManager.getLayerById(layerId);
    if (layer == null) return;
    _before ??= LayerRasterSnapshot(layer);
    layer.clearStrokes();
    layer.setBaseImageSync(image.clone(), bytes);
    layer.setBaseImageOffset(Offset.zero);
    layer.model3d = model3d;
    state.layerManager.notifyRasterChange();
    state.notifyCanvasPreview();
  }

  @override
  void undo(EditorState state) {
    final layer = state.layerManager.getLayerById(layerId);
    if (layer == null) return;
    _before?.restore(layer);
    state.layerManager.notifyRasterChange();
    state.notifyCanvasPreview();
  }

  @override
  void dispose() {
    image.dispose();
    _before?.dispose();
  }

  @override
  String get description => 'Edit 3D Layer';
}

/// Crops actual pixels and pads with transparency, while retaining full old
/// rasters for undo. Reversing a crop mathematically cannot restore lost pixels.
class ShiftEditCanvasAction extends EditorAction {
  ShiftEditCanvasAction({required this.delta, this.preserveViewport = true});
  final OutpaintFrameDelta delta;
  final bool preserveViewport;
  Size? _beforeSize, _afterSize;
  Offset? _beforeOffset, _afterOffset;
  double? _beforeScale, _afterScale;
  final Map<String, LayerRasterSnapshot> _before = {};
  final Map<String, ui.Image> _after = {};
  @override
  void execute(EditorState state) {
    _beforeSize ??= state.canvasSize;
    _afterSize ??= Size(
      _beforeSize!.width + delta.left + delta.right,
      _beforeSize!.height + delta.top + delta.bottom,
    );
    if (_afterSize!.width < 64 ||
        _afterSize!.height < 64 ||
        _afterSize!.width > 4096 ||
        _afterSize!.height > 4096) {
      throw ArgumentError('Invalid canvas bounds');
    }
    _beforeOffset ??= state.canvasController.offset;
    _beforeScale ??= state.canvasController.scale;
    for (final layer in state.layerManager.layers) {
      if (!_before.containsKey(layer.id)) {
        _before[layer.id] = LayerRasterSnapshot(layer);
        final rec = ui.PictureRecorder();
        final c = Canvas(rec)
          ..translate(delta.left.toDouble(), delta.top.toDouble());
        final raster = renderEditLayer(layer, _beforeSize!);
        c.drawImage(raster, Offset.zero, Paint());
        raster.dispose();
        final pic = rec.endRecording();
        _after[layer.id] = pic.toImageSync(
          _afterSize!.width.round(),
          _afterSize!.height.round(),
        );
        pic.dispose();
      }
      layer.clearStrokes();
      layer.setBaseImageSync(_after[layer.id]!.clone(), null);
      layer.setBaseImageOffset(Offset.zero);
    }
    state.setCanvasSize(_afterSize!);
    if (_afterOffset == null) {
      if (preserveViewport) {
        _afterOffset =
            _beforeOffset! -
            Offset(delta.left.toDouble(), delta.top.toDouble()) *
                state.canvasController.scale;
      } else {
        state.canvasController.fitToViewport(
          _afterSize!,
          insets: const EdgeInsets.fromLTRB(10, 86, 10, 70),
        );
        _afterOffset = state.canvasController.offset;
      }
    }
    _afterScale ??= state.canvasController.scale;
    state.canvasController.setScale(_afterScale!);
    state.canvasController.setOffset(_afterOffset!);
    state.layerManager.notifyRasterChange();
    state.notifyCanvasPreview();
  }

  @override
  void undo(EditorState state) {
    for (final layer in state.layerManager.layers) {
      _before[layer.id]?.restore(layer);
    }
    if (_beforeSize != null) state.setCanvasSize(_beforeSize!);
    if (_beforeScale != null) state.canvasController.setScale(_beforeScale!);
    if (_beforeOffset != null) state.canvasController.setOffset(_beforeOffset!);
    state.layerManager.notifyRasterChange();
    state.notifyCanvasPreview();
  }

  @override
  void dispose() {
    for (final s in _before.values) {
      s.dispose();
    }
    for (final i in _after.values) {
      i.dispose();
    }
  }

  @override
  String get description => 'Resize Canvas';
}

/// Rasterize intrinsic pixels without baking layer opacity/blending twice.
ui.Image renderEditLayer(Layer layer, Size size) {
  final opacity = layer.opacity, blend = layer.blendMode;
  final rec = ui.PictureRecorder();
  try {
    layer.opacity = 1;
    layer.blendMode = LayerBlendMode.normal;
    layer.render(Canvas(rec), size);
  } finally {
    layer.opacity = opacity;
    layer.blendMode = blend;
  }
  final pic = rec.endRecording();
  final image = pic.toImageSync(size.width.round(), size.height.round());
  pic.dispose();
  return image;
}

class CopyEditSelectionAction extends EditorAction {
  CopyEditSelectionAction({
    required this.sourceId,
    required this.image,
    required this.name,
    this.remaining,
  });
  final String sourceId, name;
  final ui.Image image;
  final ui.Image? remaining;
  LayerData? _added;
  LayerRasterSnapshot? _before;
  @override
  void execute(EditorState state) {
    final source = state.layerManager.getLayerById(sourceId);
    if (source == null) return;
    if (remaining != null) {
      _before ??= LayerRasterSnapshot(source);
      source.clearStrokes();
      source.setBaseImageSync(remaining!.clone(), null);
    }
    final layer = _added == null
        ? state.layerManager.addLayer(name: name)
        : state.layerManager.insertLayerFromData(
            _added!,
            state.layerManager.layerCount,
            setActive: true,
          );
    _added ??= layer.toData();
    layer.setBaseImageSync(image.clone(), null);
    state.layerManager.notifyRasterChange();
    state.notifyCanvasPreview();
  }

  @override
  void undo(EditorState state) {
    if (_added != null) state.layerManager.removeLayer(_added!.id);
    final source = state.layerManager.getLayerById(sourceId);
    if (source != null) {
      _before?.restore(source);
      state.layerManager.setActiveLayer(sourceId);
    }
    state.layerManager.notifyRasterChange();
    state.notifyCanvasPreview();
  }

  @override
  void dispose() {
    image.dispose();
    remaining?.dispose();
    _before?.dispose();
  }

  @override
  String get description =>
      remaining == null ? 'Copy Selection to Layer' : 'Cut Selection to Layer';
}
