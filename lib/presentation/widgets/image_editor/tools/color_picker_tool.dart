import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/editor_state.dart';
import 'tool_base.dart';

/// Official editor picker: one composite pixel, then return to Draw.
class ColorPickerTool extends EditorTool {
  int _request = 0;

  static Future<Color?> pickColorAt(Offset point, EditorState state) async {
    final x = point.dx.floor(), y = point.dy.floor();
    if (x < 0 ||
        y < 0 ||
        x >= state.canvasSize.width ||
        y >= state.canvasSize.height) {
      return null;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..translate(-x.toDouble(), -y.toDouble());
    state.layerManager.renderAll(canvas, state.canvasSize);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(1, 1);
    picture.dispose();
    try {
      final bytes = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (bytes == null) return null;
      return Color.fromARGB(
        bytes.getUint8(3),
        bytes.getUint8(0),
        bytes.getUint8(1),
        bytes.getUint8(2),
      );
    } finally {
      image.dispose();
    }
  }

  @override
  String get id => 'color_picker';
  @override
  String get name => 'Color Picker';
  @override
  IconData get icon => Icons.colorize;
  @override
  LogicalKeyboardKey get shortcutKey => LogicalKeyboardKey.keyC;

  @override
  void onPointerDown(PointerDownEvent event, EditorState state) {}
  @override
  void onPointerMove(PointerMoveEvent event, EditorState state) {}
  @override
  void onPointerUp(PointerUpEvent event, EditorState state) {
    _pick(event.localPosition, state);
  }

  Future<void> _pick(Offset point, EditorState state) async {
    final request = ++_request, colorBefore = state.foregroundColor;
    final color = await pickColorAt(point, state);
    if (_request != request ||
        state.currentTool != this ||
        state.foregroundColor != colorBefore) {
      return;
    }
    if (color != null) {
      state.setForegroundColor(color.withValues(alpha: 1));
      state.setToolById('brush');
    }
  }

  @override
  void onDeactivateFast(EditorState state) {
    _request++;
  }

  @override
  Widget buildSettingsPanel(BuildContext context, EditorState state) =>
      const SizedBox.shrink();
}
