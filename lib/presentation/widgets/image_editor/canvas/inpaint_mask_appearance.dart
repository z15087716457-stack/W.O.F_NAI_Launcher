import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/editor_state.dart';

/// Display styling is applied after mask coverage, never to stored mask pixels.
void drawInpaintMaskAppearance(
  Canvas canvas,
  Rect bounds,
  Rect visibleBounds,
  EditorState state,
  void Function(Canvas canvas) drawCoverage,
) {
  if (state.maskDisplayBorder) {
    canvas.saveLayer(
      bounds,
      Paint()
        ..colorFilter = const ColorFilter.mode(
          Color(0xCC000000),
          BlendMode.srcIn,
        ),
    );
    canvas.saveLayer(
      bounds,
      Paint()
        ..imageFilter = ui.ImageFilter.dilate(
          radiusX: 1 / state.canvasController.scale,
          radiusY: 1 / state.canvasController.scale,
        ),
    );
    drawCoverage(canvas);
    canvas.restore();
    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstOut);
    drawCoverage(canvas);
    canvas.restore();
    canvas.restore();
  }
  canvas.saveLayer(
    bounds,
    Paint()
      ..colorFilter = ColorFilter.mode(
        state.maskDisplayColor.withValues(alpha: state.maskDisplayOpacity),
        BlendMode.srcIn,
      ),
  );
  drawCoverage(canvas);
  if (state.maskDisplayPattern != MaskDisplayPattern.solid) {
    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
    _drawPattern(
      canvas,
      bounds.intersect(visibleBounds),
      state.maskDisplayPattern,
      state.canvasController.scale,
    );
    canvas.restore();
  }
  canvas.restore();
}

void _drawPattern(
  Canvas canvas,
  Rect bounds,
  MaskDisplayPattern pattern,
  double scale,
) {
  final pitch = 8 / scale;
  final paint = Paint()
    ..color = Colors.white
    ..strokeWidth = 1.5 / scale;
  final left = (bounds.left / pitch).floor() * pitch;
  final top = (bounds.top / pitch).floor() * pitch;
  if (pattern == MaskDisplayPattern.lines ||
      pattern == MaskDisplayPattern.crosshatch) {
    for (var d = left - bounds.bottom; d < bounds.right - top; d += pitch) {
      canvas.drawLine(
        Offset(d + top, top),
        Offset(d + bounds.bottom, bounds.bottom),
        paint,
      );
    }
    if (pattern == MaskDisplayPattern.crosshatch) {
      for (var d = left + top; d < bounds.right + bounds.bottom; d += pitch) {
        canvas.drawLine(
          Offset(d - top, top),
          Offset(d - bounds.bottom, bounds.bottom),
          paint,
        );
      }
    }
    return;
  }
  if (pattern == MaskDisplayPattern.grid) {
    for (var x = left; x <= bounds.right; x += pitch) {
      canvas.drawLine(Offset(x, bounds.top), Offset(x, bounds.bottom), paint);
    }
    for (var y = top; y <= bounds.bottom; y += pitch) {
      canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), paint);
    }
    return;
  }
  for (var y = top; y <= bounds.bottom; y += pitch) {
    for (var x = left; x <= bounds.right; x += pitch) {
      if (pattern == MaskDisplayPattern.dots) {
        canvas.drawCircle(
          Offset(x + pitch / 2, y + pitch / 2),
          pitch / 5,
          paint,
        );
      } else if (pattern == MaskDisplayPattern.checker) {
        if (((x / pitch).round() + (y / pitch).round()).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, pitch, pitch), paint);
        }
      } else {
        final heart = Path()
          ..moveTo(x + pitch / 2, y + pitch * .8)
          ..cubicTo(
            x,
            y + pitch * .45,
            x + pitch * .2,
            y + pitch * .1,
            x + pitch / 2,
            y + pitch * .35,
          )
          ..cubicTo(
            x + pitch * .8,
            y + pitch * .1,
            x + pitch,
            y + pitch * .45,
            x + pitch / 2,
            y + pitch * .8,
          )
          ..close();
        canvas.drawPath(heart, paint);
      }
    }
  }
}
