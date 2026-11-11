import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_text.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_input.dart';

import '../../../helpers/studio_capture_fonts.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  for (final scale in [1.0, 1.25, 1.5]) {
    testWidgets('multiline drag selection has no seams at ${scale}x', (
      tester,
    ) async {
      const text =
          "      d'd'd'd'd'd'd'd'd'd'd'd'\n"
          "      d'd'd'd'd'd'd'd'd'd'd'd'\n"
          '      項項項項項項項項項項項項\n'
          '      項項項項項項項項項項項項';
      final controller = TextEditingController(text: text);
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      tester.view.devicePixelRatio = scale;
      tester.view.physicalSize = Size(800 * scale, 600 * scale);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const boundaryKey = Key('selection-raster');
      await tester.pumpWidget(
        MaterialApp(
          theme: GeistTheme.dark,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 13.25),
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: ColoredBox(
                    color: const Color(0xff111111),
                    child: SizedBox(
                      width: 500,
                      child: ThemedInput(
                        embedded: true,
                        controller: controller,
                        focusNode: focus,
                        maxLines: null,
                        showCursor: false,
                        style: UiText.sans(13, height: 1.5),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      final editable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final start = editable.localToGlobal(
        editable.getLocalRectForCaret(const TextPosition(offset: 0)).centerLeft,
      );
      final end = editable.localToGlobal(
        editable
            .getLocalRectForCaret(const TextPosition(offset: text.length))
            .centerRight,
      );
      await tester.dragFrom(start, end - start, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(controller.selection.start, 0);
      expect(controller.selection.end, text.length);

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      final pixels = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: scale);
        final rgba = (await image.toByteData())!;
        final x = (6 * scale).round(); // Inside the selected leading spaces.
        final margin = (8 * scale).ceil();
        final blue = [
          for (var y = margin; y < image.height - margin; y++)
            rgba.getUint8((y * image.width + x) * 4 + 2),
        ];
        image.dispose();
        return blue;
      });
      expect(pixels!.first, greaterThan(60));
      expect(pixels, everyElement(pixels.first));
    });
  }

  group('ThemedInput 清空按钮', () {
    testWidgets('文本在空/非空间切换时输入框不重建、焦点不丢失', (tester) async {
      final controller = TextEditingController(text: 'girl');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemedInput(
              controller: controller,
              focusNode: focusNode,
              showClearButton: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      final stateBefore = tester.state(find.byType(EditableText));

      // 删光文本：清空按钮隐藏，但输入框的 Element 必须存活，
      // 否则键盘输入连接被打断、光标消失（回归：Stack 层按内容增删）
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      final stateAfterClear = tester.state(find.byType(EditableText));
      expect(
        identical(stateBefore, stateAfterClear),
        isTrue,
        reason: '删空后 EditableText 不应重建',
      );
      expect(focusNode.hasFocus, isTrue);

      // 再输入首字母：清空按钮出现，同样不能触发重建
      await tester.enterText(find.byType(TextField), 'g');
      await tester.pump();

      final stateAfterType = tester.state(find.byType(EditableText));
      expect(
        identical(stateBefore, stateAfterType),
        isTrue,
        reason: '重新输入后 EditableText 不应重建',
      );
      expect(focusNode.hasFocus, isTrue);
      expect(controller.text, 'g');
    });
  });
}
