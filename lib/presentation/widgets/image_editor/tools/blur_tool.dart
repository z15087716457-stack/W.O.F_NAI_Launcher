import 'dart:ui' as ui;

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/localization_extension.dart';
import '../core/editor_state.dart';
import '../core/history_manager.dart';
import '../core/edit_image_actions.dart';
import 'pressure_stroke.dart';
import '../layers/layer.dart';
import 'tool_base.dart';

/// Blur 工具 - 真正的像素级高斯模糊
///
/// 绘制路径作为模糊蒙版，松开后对蒙版区域应用高斯模糊。
class BlurTool extends EditorTool {
  double _intensity = 0.5;
  double get intensity => _intensity;

  double _size = 20.0;
  double get size => _size;

  void setIntensity(double value) {
    _intensity = value.clamp(0.0, 1.0);
  }

  void setSize(double value) {
    _size = value.clamp(1.0, double.infinity);
  }

  @override
  String get id => 'blur';

  @override
  String get name => 'Blur';

  @override
  IconData get icon => Icons.blur_on;

  @override
  bool get isPaintTool => true;
  @override
  LogicalKeyboardKey get shortcutKey => LogicalKeyboardKey.keyR;

  @override
  void onPointerDown(PointerDownEvent event, EditorState state) {
    state.startStroke(event.localPosition, pressure: state.pressureFor(event));
  }

  @override
  void onPointerMove(PointerMoveEvent event, EditorState state) {
    if (state.isDrawing) {
      state.updateStroke(
        event.localPosition,
        pressure: state.pressureFor(event),
      );
    }
  }

  @override
  void onPointerUp(PointerUpEvent event, EditorState state) {
    if (state.isDrawing && state.currentStrokePoints.isNotEmpty) {
      final points = List<Offset>.from(state.currentStrokePoints);
      final pressures = List<double>.from(state.strokeManager.pressures);
      state.endStroke();
      _applyBlur(state, points, pressures);
    } else {
      state.endStroke();
    }
  }

  void _applyBlur(
    EditorState state,
    List<Offset> points,
    List<double> pressures,
  ) {
    final layer = state.layerManager.activeLayer;
    if (layer == null || layer.locked) return;
    final size = state.canvasSize;
    final original = renderEditLayer(layer, size);
    final rec = ui.PictureRecorder();
    final c = Canvas(rec)..drawImage(original, Offset.zero, Paint());
    _drawBlur(c, original, size, points, pressures);
    final pic = rec.endRecording(),
        result = pic.toImageSync(size.width.round(), size.height.round());
    pic.dispose();
    original.dispose();
    state.historyManager.execute(
      ReplaceEditRasterAction(
        layerId: layer.id,
        image: result,
        description: 'Blur',
      ),
      state,
    );
  }

  void drawRealtimePreview(Canvas canvas, Layer layer, EditorState state) {
    final original = renderEditLayer(layer, state.canvasSize);
    _drawBlur(
      canvas,
      original,
      state.canvasSize,
      state.currentStrokePoints,
      state.strokeManager.pressures,
    );
    original.dispose();
  }

  void _drawBlur(
    Canvas c,
    ui.Image original,
    Size size,
    List<Offset> points,
    List<double> pressures,
  ) {
    final bounds = Offset.zero & size;
    c.saveLayer(bounds, Paint());
    c.drawImage(
      original,
      Offset.zero,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: _size * _intensity * .5,
          sigmaY: _size * _intensity * .5,
          tileMode: TileMode.clamp,
        ),
    );
    c.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
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
  }

  @override
  double getCursorRadius(EditorState state) => _size / 2;

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
                context.l10n.editor_toolBlur,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                    context.l10n.editor_intensity,
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '${(_intensity * 100).round()}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              Slider(
                value: _intensity,
                min: 0.0,
                max: 1.0,
                onChanged: (v) => setState(() => setIntensity(v)),
              ),
            ],
          ),
        );
      },
    );
  }
}
