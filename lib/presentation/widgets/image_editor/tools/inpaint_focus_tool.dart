import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/editor_state.dart';
import '../core/history_manager.dart';
import 'tool_base.dart';

/// Focused inpainting selects a crop with a protected context border. It is
/// separate from ordinary selections and never constrains brush input.
class InpaintFocusTool extends EditorTool {
  Offset? _start;
  Rect? _moving;
  Rect? _before;
  bool _resizing = false;
  @override
  String get id => 'inpaint_focus';
  @override
  String get name => 'Focused Area';
  @override
  IconData get icon => Icons.select_all;
  @override
  LogicalKeyboardKey get shortcutKey => LogicalKeyboardKey.keyS;
  @override
  bool get isPaintTool => false;
  @override
  void onPointerDown(PointerDownEvent event, EditorState state) {
    final bounds = Offset.zero & state.canvasSize;
    _start = Offset(
      event.localPosition.dx.clamp(0, bounds.right),
      event.localPosition.dy.clamp(0, bounds.bottom),
    );
    _before = state.inpaintFocusRegion;
    _resizing =
        _before != null &&
        (_before!.bottomRight - _start!).distance <=
            10 / state.canvasController.scale;

    _moving = !_resizing && state.inpaintFocusRegion?.contains(_start!) == true
        ? state.inpaintFocusRegion
        : null;
    if (_moving == null && !_resizing) {
      state.setInpaintFocusRegion(Rect.fromPoints(_start!, _start!));
    }
  }

  @override
  void onPointerMove(PointerMoveEvent event, EditorState state) {
    if (_start == null) return;
    final bounds = Offset.zero & state.canvasSize;
    final end = Offset(
      event.localPosition.dx.clamp(0, bounds.right),
      event.localPosition.dy.clamp(0, bounds.bottom),
    );
    if (_moving != null) {
      final delta = end - _start!;
      final rect = _moving!;
      state.setInpaintFocusRegion(
        rect.shift(
          Offset(
            delta.dx.clamp(-rect.left, bounds.right - rect.right),
            delta.dy.clamp(-rect.top, bounds.bottom - rect.bottom),
          ),
        ),
      );
    } else {
      final anchor = _resizing ? _before!.topLeft : _start!;
      var delta = end - anchor;
      if (_resizing) {
        delta = Offset(math.max(8, delta.dx), math.max(8, delta.dy));
      }
      final area = delta.dx.abs() * delta.dy.abs();
      if (area > 589824) delta *= math.sqrt(589824 / area);
      state.setInpaintFocusRegion(Rect.fromPoints(anchor, anchor + delta));
    }
  }

  @override
  void onPointerUp(PointerUpEvent event, EditorState state) {
    final region = state.inpaintFocusRegion;
    if (region != null && (region.width < 32 || region.height < 32)) {
      state.setInpaintFocusRegion(null);
    }
    final after = state.inpaintFocusRegion;
    if (_before != after) {
      state.historyManager.execute(
        SetInpaintFocusAction(before: _before, after: after),
        state,
      );
    }
    _start = null;
    _moving = null;
    _before = null;
    _resizing = false;
  }

  @override
  Widget buildSettingsPanel(BuildContext context, EditorState state) =>
      const SizedBox.shrink();
}
