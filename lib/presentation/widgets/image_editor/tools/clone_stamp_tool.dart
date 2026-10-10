import 'dart:ui' as ui;

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/localization_extension.dart';
import '../core/editor_state.dart';
import '../core/history_manager.dart';
import '../core/edit_image_actions.dart';
import 'pressure_stroke.dart';
import 'tool_base.dart';

/// Clone Stamp 工具 - 像素级仿制图章
///
/// Alt+Click 同步捕获画布快照并设置源点。
/// 绘制时实时显示克隆像素预览，松开后原子应用。
class CloneStampTool extends EditorTool {
  double _size = 20.0;
  double get size => _size;

  double _opacity = 1.0;
  double get opacity => _opacity;

  Offset? _sourcePoint;
  Offset? get sourcePoint => _sourcePoint;

  Offset? _sourceOffset;
  Offset? get sourceOffset => _sourceOffset;

  ui.Image? _canvasSnapshot;
  ui.Image? get canvasSnapshot => _canvasSnapshot;

  void setSize(double value) {
    _size = value.clamp(1.0, double.infinity);
  }

  void setOpacity(double value) {
    _opacity = value.clamp(0.0, 1.0);
  }

  @override
  String get id => 'clone_stamp';

  @override
  String get name => 'Clone Stamp';

  @override
  IconData get icon => Icons.copy_all;

  @override
  bool get isPaintTool => true;

  @override
  bool get handlesAltKey => true;
  @override
  LogicalKeyboardKey get shortcutKey => LogicalKeyboardKey.keyJ;

  @override
  void onPointerDown(PointerDownEvent event, EditorState state) {
    if (state.isAltPressed) {
      _setSourcePoint(event.localPosition, state);
      return;
    }

    if (_sourcePoint == null || _canvasSnapshot == null) return;

    _sourceOffset ??= event.localPosition - _sourcePoint!;
    state.startStroke(event.localPosition, pressure: state.pressureFor(event));
  }

  void _setSourcePoint(Offset position, EditorState state) {
    _sourcePoint = position;
    _sourceOffset = null;
    _captureSnapshotSync(state);
  }

  /// 同步捕获画布快照（保证 Alt+Click 后立即可用）
  void _captureSnapshotSync(EditorState state) {
    _canvasSnapshot?.dispose();
    _canvasSnapshot = null;

    final canvasSize = state.canvasSize;
    final w = canvasSize.width.toInt();
    final h = canvasSize.height.toInt();
    if (w <= 0 || h <= 0) return;

    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    state.layerManager.renderAll(c, canvasSize);
    final pic = rec.endRecording();
    _canvasSnapshot = pic.toImageSync(w, h);
    pic.dispose();
  }

  @override
  void onPointerMove(PointerMoveEvent event, EditorState state) {
    if (state.isAltPressed) return;
    if (_sourcePoint == null || _sourceOffset == null) return;

    if (state.isDrawing) {
      state.updateStroke(
        event.localPosition,
        pressure: state.pressureFor(event),
      );
    }
  }

  @override
  void onPointerUp(PointerUpEvent event, EditorState state) {
    if (state.isAltPressed) return;

    if (state.isDrawing && state.currentStrokePoints.isNotEmpty) {
      final points = List<Offset>.from(state.currentStrokePoints);
      final pressures = List<double>.from(state.strokeManager.pressures);
      state.endStroke();
      _applyClone(state, points, pressures);
    } else {
      state.endStroke();
    }
  }

  void _applyClone(
    EditorState state,
    List<Offset> points,
    List<double> pressures,
  ) {
    final layer = state.layerManager.activeLayer;
    if (layer == null ||
        layer.locked ||
        _canvasSnapshot == null ||
        _sourceOffset == null) {
      return;
    }
    final size = state.canvasSize, original = renderEditLayer(layer, size);
    final rec = ui.PictureRecorder();
    final c = Canvas(rec)..drawImage(original, Offset.zero, Paint());
    c.saveLayer(Offset.zero & size, Paint());
    c.drawImage(_canvasSnapshot!, _sourceOffset!, Paint());
    c.saveLayer(Offset.zero & size, Paint()..blendMode = BlendMode.dstIn);
    drawPressureStroke(
      c,
      StrokeData(
        points: points,
        size: _size,
        color: Colors.white,
        opacity: 1,
        hardness: 1,
        isEraser: false,
        pressures: pressures,
      ),
    );
    c.restore();
    c.restore();
    final pic = rec.endRecording(),
        result = pic.toImageSync(size.width.round(), size.height.round());
    pic.dispose();
    original.dispose();
    state.historyManager.execute(
      ReplaceEditRasterAction(
        layerId: layer.id,
        image: result,
        description: 'Clone Stamp',
      ),
      state,
    );
  }

  /// Paint sampled pixels with the same pressure mask used on release.
  void drawRealtimePreview(
    Canvas canvas,
    List<Offset> points, {
    List<double> pressures = const [],
  }) {
    if (_canvasSnapshot == null || _sourceOffset == null) return;
    canvas.saveLayer(null, Paint());
    canvas.drawImage(_canvasSnapshot!, _sourceOffset!, Paint());
    canvas.saveLayer(null, Paint()..blendMode = BlendMode.dstIn);
    drawPressureStroke(
      canvas,
      StrokeData(
        points: points,
        size: _size,
        color: Colors.white,
        opacity: _opacity,
        hardness: 1,
        isEraser: false,
        pressures: pressures,
      ),
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  void onDeactivateFast(EditorState state) {
    _sourcePoint = null;
    _sourceOffset = null;
    _canvasSnapshot?.dispose();
    _canvasSnapshot = null;
  }

  @override
  double getCursorRadius(EditorState state) => _size / 2;

  @override
  Widget? buildCursor(EditorState state, {Offset? screenCursorPosition}) {
    if (_sourcePoint == null || screenCursorPosition == null) return null;
    return const Icon(Icons.add, color: Colors.cyanAccent, size: 16);
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
                context.l10n.editor_toolCloneStamp,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.editor_sourcePoint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (_sourcePoint != null) ...[
                const SizedBox(height: 4),
                Text(
                  '(${_sourcePoint!.dx.round()}, ${_sourcePoint!.dy.round()})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.cyanAccent,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    context.l10n.editor_size,
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text('${_size.round()}', style: theme.textTheme.bodySmall),
                ],
              ),
              Slider(
                value: _size,
                min: 1,
                max: 200,
                onChanged: (v) => setState(() => setSize(v)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    context.l10n.editor_opacity,
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '${(_opacity * 100).round()}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              Slider(
                value: _opacity,
                min: 0.0,
                max: 1.0,
                onChanged: (v) => setState(() => setOpacity(v)),
              ),
            ],
          ),
        );
      },
    );
  }
}
