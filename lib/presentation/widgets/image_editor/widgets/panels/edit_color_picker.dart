import 'package:flutter/material.dart';
import '../../../../../core/utils/localization_extension.dart';
import '../../core/editor_state.dart';
import 'edit_image_controls.dart';
import 'inpaint_controls.dart';

class EditColorControl extends StatefulWidget {
  const EditColorControl({super.key, required this.state});
  final EditorState state;
  @override
  State<EditColorControl> createState() => _EditColorControlState();
}

class _EditColorControlState extends State<EditColorControl> {
  final _portal = OverlayPortalController();
  final _anchor = GlobalKey();
  Offset _position = Offset.zero;
  void _toggle() {
    if (_portal.isShowing) {
      _portal.hide();
      return;
    }
    final b = _anchor.currentContext!.findRenderObject()! as RenderBox;
    final root = Overlay.of(context).context.findRenderObject()! as RenderBox;
    _position = root.globalToLocal(b.localToGlobal(Offset(0, b.size.height)));
    _portal.show();
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    overlayChildBuilder: (context) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _portal.hide,
          ),
        ),
        Positioned(
          left: _position.dx.clamp(10, MediaQuery.sizeOf(context).width - 218),
          top: _position.dy + 8,
          child: InpaintPanel(
            width: 200,
            child: EditColorPicker(
              color: widget.state.foregroundColor,
              onChanged: (c) {
                widget.state.setForegroundColor(c);
                widget.state.setToolById(
                  widget.state.currentTool?.id == 'fill' ? 'fill' : 'brush',
                );
              },
            ),
          ),
        ),
      ],
    ),
    child: Tooltip(
      message: context.l10n.editor_colorPickerTitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: _anchor,
          onTap: _toggle,
          borderRadius: BorderRadius.circular(3),
          child: Container(
            key: const Key('edit_color_swatch'),
            width: 104,
            height: 40,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: widget.state.foregroundColor,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.centerRight,
            child: Container(
              key: const Key('edit_color_popup_icon'),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.center,
              child: const EditGlyph('picker'),
            ),
          ),
        ),
      ),
    ),
  );
}

class EditColorPicker extends StatefulWidget {
  const EditColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
  });
  final Color color;
  final ValueChanged<Color> onChanged;
  @override
  State<EditColorPicker> createState() => _EditColorPickerState();
}

class _EditColorPickerState extends State<EditColorPicker> {
  late HSVColor _hsv;
  late TextEditingController _hex;
  String _text(Color c) =>
      c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.color);
    _hex = TextEditingController(text: _text(widget.color));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _update(HSVColor c) {
    setState(() => _hsv = c);
    _hex.text = _text(c.toColor());
    widget.onChanged(c.toColor());
  }

  void _touch(Offset p, Size s) => _update(
    _hsv
        .withSaturation((p.dx / s.width).clamp(0, 1))
        .withValue((1 - p.dy / s.height).clamp(0, 1)),
  );
  @override
  Widget build(BuildContext context) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 140,
            child: LayoutBuilder(
              builder: (context, c) => GestureDetector(
                key: const Key('edit_color_sv'),
                onTapDown: (d) => _touch(d.localPosition, c.biggest),
                onPanStart: (d) => _touch(d.localPosition, c.biggest),
                onPanUpdate: (d) => _touch(d.localPosition, c.biggest),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _hsv.saturation * c.maxWidth - 7,
                      top: (1 - _hsv.value) * c.maxHeight - 7,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _bar(
            context.l10n.editor_hue,
            _hsv.hue / 360,
            (v) => _update(_hsv.withHue(v * 360)),
            const [
              Colors.red,
              Colors.yellow,
              Colors.green,
              Colors.cyan,
              Colors.blue,
              Colors.purpleAccent,
              Colors.red,
            ],
          ),
          _bar(
            context.l10n.editor_colorAlpha,
            _hsv.alpha,
            (v) => _update(_hsv.withAlpha(v)),
            [Colors.transparent, _hsv.withAlpha(1).toColor()],
            checker: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              key: const Key('edit_color_hex'),
              controller: _hex,
              maxLength: 6,
              style: const TextStyle(fontSize: 11),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                counterText: '',
                labelText: context.l10n.editor_colorHex,
              ),
              onChanged: (t) {
                final n = int.tryParse(t, radix: 16);
                if (t.length == 6 && n != null) {
                  final c = Color(0xff000000 | n).withValues(alpha: _hsv.alpha);
                  setState(() => _hsv = HSVColor.fromColor(c));
                  widget.onChanged(c);
                }
              },
            ),
          ),
        ],
      );
  Widget _bar(
    String label,
    double value,
    ValueChanged<double> change,
    List<Color> colors, {
    bool checker = false,
  }) => Semantics(
    label: label,
    slider: true,
    value: '${(value * 100).round()}%',
    child: SizedBox(
      height: 24,
      child: LayoutBuilder(
        builder: (context, c) => GestureDetector(
          onTapDown: (d) =>
              change((d.localPosition.dx / c.maxWidth).clamp(0, 1)),
          onPanStart: (d) =>
              change((d.localPosition.dx / c.maxWidth).clamp(0, 1)),
          onPanUpdate: (d) =>
              change((d.localPosition.dx / c.maxWidth).clamp(0, 1)),
          child: Stack(
            children: [
              if (checker)
                const Positioned.fill(
                  child: CustomPaint(painter: _ColorChecker()),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                  ),
                ),
              ),
              Positioned(
                left: value * c.maxWidth - 6,
                top: 0,
                child: Container(
                  width: 12,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ColorChecker extends CustomPainter {
  const _ColorChecker();
  @override
  void paint(Canvas canvas, Size size) {
    for (var y = 0; y < size.height; y += 6) {
      for (var x = 0; x < size.width; x += 6) {
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 6, 6),
          Paint()
            ..color = ((x ~/ 6 + y ~/ 6).isEven
                ? const Color(0xffdddddd)
                : Colors.white),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ColorChecker old) => false;
}
