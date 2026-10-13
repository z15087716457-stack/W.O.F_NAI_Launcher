import 'dart:ui' as ui;
import 'dart:typed_data';

import '../widgets/image_editor/core/editor_state.dart';
import '../widgets/image_editor/core/history_manager.dart';
import '../widgets/image_editor/core/edit_image_actions.dart';
import '../widgets/image_editor/layers/layer.dart';
import '../widgets/image_editor/layers/model3d_layer_data.dart';

class _ToolsLayerSnapshot {
  _ToolsLayerSnapshot(Layer layer)
    : data = layer.toData(),
      image = layer.baseImage?.clone(),
      bytes = layer.baseImageBytes,
      offset = layer.baseImageOffset,
      model = layer.model3d;
  final LayerData data;
  final ui.Image? image;
  final Uint8List? bytes;
  final ui.Offset offset;
  final Model3dLayerData? model;
  void dispose() => image?.dispose();
}

/// Menu operations retain raster pixels and 3D scene data as well as strokes.
class ToolsEditorLayerAction extends EditorAction {
  ToolsEditorLayerAction(this.change, {required this.description});
  final void Function(EditorState) change;
  @override
  final String description;
  List<_ToolsLayerSnapshot>? _before;
  String? active;
  @override
  void execute(EditorState state) {
    _before ??= state.layerManager.layers.map(_ToolsLayerSnapshot.new).toList();
    active ??= state.layerManager.activeLayerId;
    change(state);
    state.requestUiUpdate();
  }

  @override
  void undo(EditorState state) {
    final layers = _before;
    if (layers == null) return;
    state.layerManager.runBatch(() {
      state.layerManager.clear();
      for (var i = 0; i < layers.length; i++) {
        final saved = layers[i];
        final layer = state.layerManager.insertLayerFromData(saved.data, i);
        if (saved.image != null) {
          layer.setBaseImageSync(saved.image!.clone(), saved.bytes);
          layer.setBaseImageOffset(saved.offset);
        }
        layer.model3d = saved.model;
      }
      if (active != null) state.layerManager.setActiveLayer(active!);
      state.layerManager.notifyRasterChange();
    });
    state.requestUiUpdate();
  }

  @override
  void dispose() {
    for (final layer in _before ?? <_ToolsLayerSnapshot>[]) {
      layer.dispose();
    }
  }
}

void toolsDuplicateLayer(EditorState state, Layer layer) {
  final copy = state.layerManager.duplicateLayer(layer.id);
  if (copy == null) return;
  if (layer.baseImage != null) {
    copy.setBaseImageSync(layer.baseImage!.clone(), layer.baseImageBytes);
    copy.setBaseImageOffset(layer.baseImageOffset);
  }
  copy.model3d = layer.model3d;
  state.layerManager.notifyRasterChange();
}

void toolsMergeLayers(EditorState state, Layer top, Layer bottom) {
  final size = state.canvasSize;
  final topImage = renderEditLayer(top, size);
  final bottomImage = renderEditLayer(bottom, size);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImage(bottomImage, ui.Offset.zero, ui.Paint());
  canvas.drawImage(topImage, ui.Offset.zero, ui.Paint());
  final picture = recorder.endRecording();
  final merged = picture.toImageSync(size.width.round(), size.height.round());
  picture.dispose();
  topImage.dispose();
  bottomImage.dispose();
  bottom.clearStrokes();
  bottom.setBaseImageSync(merged, null);
  bottom.setBaseImageOffset(ui.Offset.zero);
  bottom.model3d = null;
  state.layerManager.removeLayer(top.id);
  state.layerManager.setActiveLayer(bottom.id);
  state.layerManager.notifyRasterChange();
}
