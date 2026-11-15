import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/continuous_text_selection.dart';

class _HighlightController extends TextEditingController {
  _HighlightController() : super(text: 'a a');
  Color color = const Color(0xFFCC3300);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) => TextSpan(
    style: style,
    children: [
      TextLineBackgroundSpan(text: text, style: style, backgroundColor: color),
    ],
  );
}

void main() {
  testWidgets('changing only a source background repaints the mounted editor', (
    t,
  ) async {
    final controller = _HighlightController(), boundaryKey = GlobalKey();
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: boundaryKey,
            child: ContinuousTextSelection(
              child: TextField(
                controller: controller,
                maxLines: null,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
    final state = t.state<EditableTextState>(find.byType(EditableText));
    Future<Color> painted() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final box = state.renderEditable
          .getBoxesForSelection(
            const TextSelection(baseOffset: 1, extentOffset: 2),
          )
          .first
          .toRect();
      final point = MatrixUtils.transformPoint(
        state.renderEditable.getTransformTo(boundary),
        box.center,
      );
      return (await t.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final at = (point.dy.floor() * image.width + point.dx.floor()) * 4;
        final color = Color.fromARGB(
          bytes.getUint8(at + 3),
          bytes.getUint8(at),
          bytes.getUint8(at + 1),
          bytes.getUint8(at + 2),
        );
        image.dispose();
        return color;
      }))!;
    }

    expect(await painted(), controller.color);
    controller.color = const Color(0xFF2255CC);
    controller.notifyListeners();
    await t.pump();
    expect(t.state<EditableTextState>(find.byType(EditableText)), same(state));
    expect(await painted(), controller.color);
    expect(controller.text, 'a a');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
