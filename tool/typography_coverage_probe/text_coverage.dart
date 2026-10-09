import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

/// Experimental wrapper for an isolated text-only layer with opaque ink.
/// Place intentional Opacity outside this wrapper. Do not wrap backgrounds,
/// images, mixed-alpha spans, selection highlights, or an entire application.
class TextCoverage extends StatefulWidget {
  const TextCoverage({
    super.key,
    required this.program,
    required this.exponent,
    required this.child,
    this.forceIdentityLayer = false,
  });

  final ui.FragmentProgram program;
  final double exponent;
  final Widget child;
  final bool forceIdentityLayer;

  @override
  State<TextCoverage> createState() => _TextCoverageState();
}

class _TextCoverageState extends State<TextCoverage> {
  ui.FragmentShader? _shader;

  @override
  Widget build(BuildContext context) {
    final enabled =
        ui.ImageFilter.isShaderFilterSupported &&
        (widget.exponent != 1 || widget.forceIdentityLayer);
    ui.ImageFilter filter = ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0);
    if (enabled) {
      final shader = _shader ??= widget.program.fragmentShader();
      shader.setFloat(2, widget.exponent);
      filter = ui.ImageFilter.shader(shader);
    }
    // Keep the same widget ancestry when the theme or backend changes, so
    // disabling the effect does not recreate an editable child's state.
    return ImageFiltered(
      enabled: enabled,
      imageFilter: filter,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }
}
