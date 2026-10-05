import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/localization_extension.dart';
import '../../core/edit_image_actions.dart';
import '../../core/editor_state.dart';
import 'edit_image_controls.dart';
import 'inpaint_controls.dart';

/// Same HSV operation as the public editor: hue offset, saturation/value gains,
/// clamped to [0,1], with the alpha channel untouched.
Uint8List adjustEditHsv(Map<String, dynamic> job) {
  final bytes = Uint8List.fromList(job['bytes'] as Uint8List);
  final hue = job['hue'] as double,
      sg = 1 + (job['saturation'] as double) / 100,
      vg = 1 + (job['brightness'] as double) / 100;
  for (var i = 0; i < bytes.length; i += 4) {
    if (bytes[i + 3] == 0) continue;
    final hsv = HSVColor.fromColor(
      Color.fromARGB(255, bytes[i], bytes[i + 1], bytes[i + 2]),
    );
    final rgb = HSVColor.fromAHSV(
      1,
      (hsv.hue + hue + 360) % 360,
      (hsv.saturation * sg).clamp(0, 1),
      (hsv.value * vg).clamp(0, 1),
    ).toColor();
    bytes[i] = (rgb.r * 255).round();
    bytes[i + 1] = (rgb.g * 255).round();
    bytes[i + 2] = (rgb.b * 255).round();
  }
  return bytes;
}

class EditHsvPanel extends StatefulWidget {
  const EditHsvPanel({super.key, required this.state, required this.onClose});
  final EditorState state;
  final VoidCallback onClose;
  @override
  State<EditHsvPanel> createState() => _EditHsvPanelState();
}

class _EditHsvPanelState extends State<EditHsvPanel> {
  ui.Image? _original, _preview;
  Uint8List? _bytes;
  String? _layerId;
  double hue = 0, saturation = 0, brightness = 0;
  int _version = 0;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    final layer = widget.state.layerManager.activeLayer;
    if (layer == null || layer.locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onClose());
      return;
    }
    _layerId = layer.id;
    _original = renderEditLayer(layer, widget.state.canvasSize);
    final data = await _original!.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (!mounted) return;
    _bytes = data?.buffer.asUint8List();
    setState(() {});
  }

  Future<void> _refresh() async {
    if (_bytes == null) return;
    final version = ++_version;
    setState(() => _busy = true);
    final result = await compute(adjustEditHsv, {
      'bytes': _bytes!,
      'hue': hue,
      'saturation': saturation,
      'brightness': brightness,
    });
    if (!mounted || version != _version) return;
    final image = await _decode(result, _original!.width, _original!.height);
    if (!mounted || version != _version) {
      image.dispose();
      return;
    }
    _preview?.dispose();
    _preview = image;
    widget.state.rasterPreviewLayerId = _layerId;
    widget.state.rasterPreview = image;
    widget.state.notifyCanvasPreview();
    setState(() => _busy = false);
  }

  static Future<ui.Image> _decode(
    Uint8List bytes,
    int width,
    int height,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  }

  void _apply() {
    if (_preview != null && (hue != 0 || saturation != 0 || brightness != 0)) {
      widget.state.historyManager.execute(
        ReplaceEditRasterAction(
          layerId: _layerId!,
          image: _preview!.clone(),
          description: 'HSV Adjustment',
        ),
        widget.state,
      );
    }
    widget.onClose();
  }

  @override
  void dispose() {
    ++_version;
    widget.state.rasterPreviewLayerId = null;
    widget.state.rasterPreview = null;
    _original?.dispose();
    _preview?.dispose();
    if (!widget.state.isDisposed) widget.state.notifyCanvasPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return InpaintPanel(
      width: 260,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.editor_hsvAdjustment,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            EditNumberSlider(
              label: l.editor_hue,
              value: hue,
              min: -180,
              max: 180,
              width: 240,
              onChanged: (v) {
                hue = v;
                _refresh();
              },
            ),
            const SizedBox(height: 8),
            EditNumberSlider(
              label: l.editor_effectSaturation,
              value: saturation,
              min: -100,
              max: 100,
              width: 240,
              onChanged: (v) {
                saturation = v;
                _refresh();
              },
            ),
            const SizedBox(height: 8),
            EditNumberSlider(
              label: l.editor_effectBrightness,
              value: brightness,
              min: -100,
              max: 100,
              width: 240,
              onChanged: (v) {
                brightness = v;
                _refresh();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    hue = saturation = brightness = 0;
                    _refresh();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 32),
                  ),
                  child: Text(
                    l.common_reset,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onClose,
                  child: Text(
                    l.common_cancel,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                FilledButton(
                  onPressed: _busy || _bytes == null ? null : _apply,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(40, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  child: Text(
                    l.common_apply,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
