import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/foundation.dart' show compute, listEquals;

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/hard_edge_mask_exporter.dart';
import '../../../../core/utils/inpaint_mask_utils.dart';
import '../core/editor_state.dart';
import '../core/edit_image_actions.dart';
import '../core/history_manager.dart';
import 'tool_base.dart';

class FillTool extends EditorTool {
  int _tolerance = 15;
  int get tolerance => _tolerance;

  void setTolerance(int value) {
    _tolerance = value.clamp(0, 100);
  }

  @override
  String get id => 'fill';

  @override
  String get name => 'Fill';

  @override
  IconData get icon => Icons.format_color_fill;

  @override
  LogicalKeyboardKey? get shortcutKey => LogicalKeyboardKey.keyG;

  @override
  bool get isPaintTool => true;

  @override
  void onPointerDown(PointerDownEvent event, EditorState state) {
    _performFill(state, event.localPosition);
  }

  @override
  void onPointerMove(PointerMoveEvent event, EditorState state) {}

  @override
  void onPointerUp(PointerUpEvent event, EditorState state) {}

  Future<void> _performFill(EditorState state, Offset tapPosition) async {
    if (state.inpaint) {
      await _fillMask(state, tapPosition);
      return;
    }
    final canvasSize = state.canvasSize, layer = state.layerManager.activeLayer;
    if (_fillingNormal ||
        layer == null ||
        layer.locked ||
        !(Offset.zero & canvasSize).contains(tapPosition)) {
      return;
    }
    _fillingNormal = true;
    final fillColor = state.foregroundColor.toARGB32();
    final beforeImage = layer.baseImage,
        beforeStrokes = layer.strokes,
        history = (
          state.historyManager.undoStackSize,
          state.historyManager.redoStackSize,
        );
    final raster = renderEditLayer(layer, canvasSize);
    try {
      final data = await raster.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (data == null || state.isDisposed) return;
      final bytes = await compute(_fillEditPixels, {
        'bytes': data.buffer.asUint8List(),
        'width': raster.width,
        'height': raster.height,
        'x': tapPosition.dx.floor(),
        'y': tapPosition.dy.floor(),
        'tolerance': _tolerance,
        'color': fillColor,
      });
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        bytes,
        raster.width,
        raster.height,
        ui.PixelFormat.rgba8888,
        completer.complete,
      );
      final result = await completer.future;
      if (state.isDisposed ||
          state.canvasSize != canvasSize ||
          state.layerManager.activeLayerId != layer.id ||
          layer.baseImage != beforeImage ||
          !listEquals(layer.strokes, beforeStrokes) ||
          history !=
              (
                state.historyManager.undoStackSize,
                state.historyManager.redoStackSize,
              )) {
        result.dispose();
        return;
      }
      state.historyManager.execute(
        ReplaceEditRasterAction(
          layerId: layer.id,
          image: result,
          description: 'Fill',
        ),
        state,
      );
    } finally {
      raster.dispose();
      _fillingNormal = false;
    }
  }

  bool _fillingNormal = false;

  bool _fillingMask = false;
  Future<void> _fillMask(EditorState state, Offset point) async {
    state.ensureInpaintMaskLayer();
    final layer = state.layerManager.activeLayer;
    if (_fillingMask || layer == null || !layer.inpaintMask || layer.locked) {
      return;
    }
    final width = state.canvasSize.width.round();
    final height = state.canvasSize.height.round();
    final x = point.dx.floor(), y = point.dy.floor();
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    _fillingMask = true;
    final beforeStrokes = layer.strokes;
    final beforeImage = layer.baseImageBytes;
    final beforeOffset = layer.baseImageOffset;
    final beforeSize = state.canvasSize;
    final beforeHistory = (
      state.historyManager.undoStackSize,
      state.historyManager.redoStackSize,
    );
    try {
      final raster = await HardEdgeMaskExporter.exportRasterAsync(
        HardEdgeMaskExportInput(
          width: width,
          height: height,
          strokes: const [],
          baseMasks: const [],
          additionalRects: const [],
          orderedOperations: layer.toHardEdgeMaskOperations(),
        ),
      );
      if (state.isDisposed || raster.mask[y * width + x] != 0) return;
      final mask = await compute(_floodFillMask, (
        raster.mask,
        width,
        height,
        x,
        y,
      ));
      if (state.isDisposed) return;
      final bytes =
          await InpaintMaskUtils.encodeEditorOverlayFromBinaryMaskAsync(
            mask,
            width: width,
            height: height,
            overlayAlpha: 255,
          );
      if (state.isDisposed) return;
      final codec = await ui.instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      if (state.isDisposed) {
        image.dispose();
        return;
      }
      final currentStrokes = layer.strokes;
      final unchanged =
          state.canvasSize == beforeSize &&
          layer.baseImageOffset == beforeOffset &&
          (
                state.historyManager.undoStackSize,
                state.historyManager.redoStackSize,
              ) ==
              beforeHistory &&
          identical(beforeImage, layer.baseImageBytes) &&
          currentStrokes.length == beforeStrokes.length &&
          List.generate(
            currentStrokes.length,
            (i) => identical(currentStrokes[i], beforeStrokes[i]),
          ).every((v) => v);
      if (state.layerManager.getLayerById(layer.id) != layer || !unchanged) {
        image.dispose();
        return;
      }
      state.historyManager.execute(
        ReplaceLayerImageAction(
          layerId: layer.id,
          newImageBytes: bytes,
          newImage: image,
          actionDescription: 'Fill Mask',
        ),
        state,
      );
      state.requestUiUpdate();
    } finally {
      _fillingMask = false;
    }
  }

  @override
  Widget buildSettingsPanel(BuildContext context, EditorState state) {
    return StatefulBuilder(
      builder: (context, setState) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.editor_toolFill,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    context.l10n.editor_tolerance,
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text('$_tolerance', style: theme.textTheme.bodySmall),
                ],
              ),
              Slider(
                value: _tolerance.toDouble(),
                min: 0,
                max: 255,
                divisions: 255,
                onChanged: (v) {
                  setState(() => setTolerance(v.round()));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Uint8List _floodFillMask((Uint8List, int, int, int, int) input) {
  final (mask, width, height, startX, startY) = input;
  final pending = <int>[startY * width + startX];
  while (pending.isNotEmpty) {
    final index = pending.removeLast();
    if (mask[index] != 0) continue;
    final y = index ~/ width;
    var left = index % width;
    var right = left;
    while (left > 0 && mask[y * width + left - 1] == 0) {
      left--;
    }
    while (right + 1 < width && mask[y * width + right + 1] == 0) {
      right++;
    }
    var above = false, below = false;
    for (var x = left; x <= right; x++) {
      mask[y * width + x] = 1;
      final hasAbove = y > 0 && mask[(y - 1) * width + x] == 0;
      final hasBelow = y + 1 < height && mask[(y + 1) * width + x] == 0;
      if (hasAbove && !above) pending.add((y - 1) * width + x);
      if (hasBelow && !below) pending.add((y + 1) * width + x);
      above = hasAbove;
      below = hasBelow;
    }
  }
  return mask;
}

Uint8List _fillEditPixels(Map<String, dynamic> job) {
  final bytes = Uint8List.fromList(job['bytes'] as Uint8List),
      w = job['width'] as int,
      h = job['height'] as int,
      x = job['x'] as int,
      y = job['y'] as int,
      t = job['tolerance'] as int,
      c = job['color'] as int;
  final start = y * w + x,
      rgba = List.generate(4, (i) => bytes[start * 4 + i]),
      target = [(c >> 16) & 255, (c >> 8) & 255, c & 255, (c >> 24) & 255];
  final visited = Uint8List(w * h), stack = <int>[start];
  visited[start] = 1;
  bool matches(int i) {
    var d = 0;
    for (var n = 0; n < 4; n++) {
      final diff = bytes[i * 4 + n] - rgba[n];
      d += diff * diff;
    }
    return d <= t * t;
  }

  while (stack.isNotEmpty) {
    final p = stack.removeLast();
    if (!matches(p)) continue;
    for (var n = 0; n < 4; n++) {
      bytes[p * 4 + n] = target[n];
    }
    final px = p % w, py = p ~/ w;
    for (final next in [
      if (px > 0) p - 1,
      if (px < w - 1) p + 1,
      if (py > 0) p - w,
      if (py < h - 1) p + w,
    ]) {
      if (visited[next] == 0) {
        visited[next] = 1;
        stack.add(next);
      }
    }
  }
  return bytes;
}
