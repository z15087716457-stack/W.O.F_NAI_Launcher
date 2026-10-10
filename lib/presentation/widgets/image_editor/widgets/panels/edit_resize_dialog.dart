import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/utils/inpaint_outpaint_utils.dart';
import '../../../../../core/utils/localization_extension.dart';
import 'edit_image_controls.dart';

class EditResizeDialog extends StatefulWidget {
  const EditResizeDialog({super.key, required this.size});
  final Size size;
  @override
  State<EditResizeDialog> createState() => _EditResizeDialogState();
}

class _EditResizeDialogState extends State<EditResizeDialog> {
  late final width = TextEditingController(
        text: '${widget.size.width.round()}',
      ),
      height = TextEditingController(text: '${widget.size.height.round()}');
  final edges = List.generate(4, (_) => TextEditingController(text: '0'));
  List<int> get values => edges.map((e) => int.tryParse(e.text) ?? 0).toList();
  Size get result => Size(
    widget.size.width + values[1] + values[3],
    widget.size.height + values[0] + values[2],
  );
  bool get valid =>
      result.width >= 64 &&
      result.height >= 64 &&
      result.width <= 4096 &&
      result.height <= 4096;
  void _dimensions() {
    edges[0].text = edges[3].text = '0';
    edges[1].text =
        '${(int.tryParse(width.text) ?? widget.size.width.round()) - widget.size.width.round()}';
    edges[2].text =
        '${(int.tryParse(height.text) ?? widget.size.height.round()) - widget.size.height.round()}';
    setState(() {});
  }

  void _edges() {
    width.text = '${result.width.round()}';
    height.text = '${result.height.round()}';
    setState(() {});
  }

  void _closest() {
    final w = math.max(64, (widget.size.width ~/ 64) * 64),
        h = math.max(64, (widget.size.height ~/ 64) * 64),
        dx = w - widget.size.width.round(),
        dy = h - widget.size.height.round();
    edges[3].text = '${(dx / 2).floor()}';
    edges[1].text = '${(dx / 2).ceil()}';
    edges[0].text = '${(dy / 2).floor()}';
    edges[2].text = '${(dy / 2).ceil()}';
    _edges();
  }

  void _confirm() {
    if (valid) {
      final v = values;
      Navigator.pop(
        context,
        OutpaintFrameDelta(top: v[0], right: v[1], bottom: v[2], left: v[3]),
      );
    }
  }

  @override
  void dispose() {
    width.dispose();
    height.dispose();
    for (final e in edges) {
      e.dispose();
    }
    super.dispose();
  }

  Widget _number(TextEditingController c, VoidCallback update) => SizedBox(
    width: 80,
    child: TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      textAlign: TextAlign.center,
      decoration: const InputDecoration(isDense: true),
      onChanged: (_) => update(),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _confirm();
              return null;
            },
          ),
        },
        child: Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.editor_changeCanvasSize,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        EditButton(
                          tooltip: l.common_close,
                          glyph: 'close',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Text(l.editor_canvasSizeTitle)),
                        Flexible(
                          child: TextButton(
                            onPressed: _closest,
                            child: Text(
                              l.editor_closestValidSize,
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _number(width, _dimensions),
                        EditButton(
                          tooltip: l.common_swap,
                          glyph: 'close',
                          size: 51,
                          onPressed: () {
                            final old = width.text;
                            width.text = height.text;
                            height.text = old;
                            _dimensions();
                          },
                        ),
                        _number(height, _dimensions),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'or',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(l.editor_shiftEdges),
                    const SizedBox(height: 12),
                    Center(child: _number(edges[0], _edges)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _number(edges[3], _edges),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 120,
                          height: 86,
                          child: CustomPaint(
                            painter: _ResizePreview(widget.size, values),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _number(edges[1], _edges),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(child: _number(edges[2], _edges)),
                    const SizedBox(height: 12),
                    Text(
                      '${result.width.round()} × ${result.height.round()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: valid
                            ? null
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: valid ? _confirm : null,
                        child: Text(l.editor_resize),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResizePreview extends CustomPainter {
  _ResizePreview(this.size, this.edges);
  final Size size;
  final List<int> edges;
  @override
  void paint(Canvas canvas, Size area) {
    final rect = Rect.fromLTWH(
      -edges[3].toDouble(),
      -edges[0].toDouble(),
      math.max(1, size.width + edges[1] + edges[3]),
      math.max(1, size.height + edges[0] + edges[2]),
    );
    final union = (Offset.zero & size).expandToInclude(rect);
    final s = math.min(
      (area.width - 10) / union.width,
      (area.height - 10) / union.height,
    );
    canvas.translate(
      (area.width - union.width * s) / 2 - union.left * s,
      (area.height - union.height * s) / 2 - union.top * s,
    );
    canvas.scale(s);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0x33666666),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xff55aaff)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 / s,
    );
  }

  @override
  bool shouldRepaint(covariant _ResizePreview old) => true;
}
