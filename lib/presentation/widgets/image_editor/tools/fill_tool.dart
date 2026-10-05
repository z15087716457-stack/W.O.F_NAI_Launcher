import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show compute;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/hard_edge_mask_exporter.dart';
import '../../../../core/utils/inpaint_mask_utils.dart';
import '../core/editor_state.dart';
import '../core/history_manager.dart';
import 'tool_base.dart';

class FillTool extends EditorTool {
  int _tolerance = 32;
  int get tolerance => _tolerance;

  void setTolerance(int value) {
    _tolerance = value.clamp(0, 255);
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
    final canvasSize = state.canvasSize;
    final width = canvasSize.width.toInt();
    final height = canvasSize.height.toInt();
    final startX = tapPosition.dx.round().clamp(0, width - 1);
    final startY = tapPosition.dy.round().clamp(0, height - 1);
    final fillColor = state.foregroundColor;

    final activeLayer = state.layerManager.activeLayer;
    if (activeLayer == null || activeLayer.locked) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    state.layerManager.renderAll(canvas, canvasSize);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData == null) return;
    final pixels = byteData.buffer.asUint8List();

    final targetIdx = (startY * width + startX) * 4;
    if (targetIdx + 3 >= pixels.length) return;

    final targetR = pixels[targetIdx];
    final targetG = pixels[targetIdx + 1];
    final targetB = pixels[targetIdx + 2];
    final targetA = pixels[targetIdx + 3];

    final fillR = (fillColor.r * 255.0).round().clamp(0, 255);
    final fillG = (fillColor.g * 255.0).round().clamp(0, 255);
    final fillB = (fillColor.b * 255.0).round().clamp(0, 255);
    final fillA = (fillColor.a * 255.0).round().clamp(0, 255);

    if (targetR == fillR &&
        targetG == fillG &&
        targetB == fillB &&
        targetA == fillA) {
      return;
    }

    final visited = Uint8List(width * height);
    final stack = <int>[];
    stack.add(startY * width + startX);
    visited[startY * width + startX] = 1;

    final fillPoints = <Offset>[];

    while (stack.isNotEmpty) {
      final idx = stack.removeLast();
      final px = idx % width;
      final py = idx ~/ width;
      fillPoints.add(Offset(px.toDouble(), py.toDouble()));

      for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
        final nx = px + dx;
        final ny = py + dy;
        if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
        final nIdx = ny * width + nx;
        if (visited[nIdx] == 1) continue;
        visited[nIdx] = 1;

        final pi = nIdx * 4;
        final dr = (pixels[pi] - targetR).abs();
        final dg = (pixels[pi + 1] - targetG).abs();
        final db = (pixels[pi + 2] - targetB).abs();
        final da = (pixels[pi + 3] - targetA).abs();

        if (dr <= _tolerance &&
            dg <= _tolerance &&
            db <= _tolerance &&
            da <= _tolerance) {
          stack.add(nIdx);
        }
      }
    }

    if (fillPoints.isEmpty) return;

    final stroke = StrokeData(
      points: fillPoints,
      size: 1,
      color: fillColor,
      opacity: fillColor.a,
      hardness: 1.0,
      isEraser: false,
    );

    state.historyManager.execute(
      AddStrokeAction(layerId: activeLayer.id, stroke: stroke),
      state,
    );
  }

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
