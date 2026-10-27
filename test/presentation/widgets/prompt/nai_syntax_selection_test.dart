import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/prompt/nai_syntax_controller.dart';

import '../../../helpers/studio_capture_fonts.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'selection stays visible over syntax backgrounds: $brightness',
      (tester) async {
        await tester.runAsync(loadStudioCaptureFonts);
        const text = '2::warm light::, plain, -1::cool shade::';
        const selectionColor = Color(0xFF487BFF);
        final controller = NaiSyntaxController(text: text);
        final focus = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focus.dispose);
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getTheme(AppStyle.geist, brightness).copyWith(
              textSelectionTheme: const TextSelectionThemeData(
                selectionColor: selectionColor,
              ),
            ),
            home: Scaffold(
              body: RepaintBoundary(
                key: boundaryKey,
                child: SizedBox(
                  width: 500,
                  height: 120,
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    showCursor: false,
                    maxLines: null,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        );
        focus.requestFocus();
        controller.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: text.length,
        );
        await tester.pump();
        final editable = tester
            .state<EditableTextState>(find.byType(EditableText))
            .renderEditable;
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final origin = editable.localToGlobal(Offset.zero, ancestor: boundary);
        final selectedCounts = <String, int>{};
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          for (final word in ['warm light', 'plain', 'cool shade']) {
            final start = text.indexOf(word);
            final boxes = editable.getBoxesForSelection(
              TextSelection(
                baseOffset: start,
                extentOffset: start + word.length,
              ),
            );
            var selectedPixels = 0;
            for (final box in boxes) {
              final rect = box.toRect().shift(origin).deflate(1);
              for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++) {
                for (var x = rect.left.ceil(); x < rect.right.floor(); x++) {
                  final offset = (y * image.width + x) * 4;
                  if (bytes.getUint8(offset) == 0x48 &&
                      bytes.getUint8(offset + 1) == 0x7B &&
                      bytes.getUint8(offset + 2) == 0xFF) {
                    selectedPixels++;
                  }
                }
              }
            }
            selectedCounts[word] = selectedPixels;
          }
          final capture = Platform.environment['PROMPT_SELECTION_CAPTURE_DIR'];
          if (capture != null) {
            final file = File('$capture/${brightness.name}.png');
            await file.parent.create(recursive: true);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            await file.writeAsBytes(png!.buffer.asUint8List());
          }
          image.dispose();
        });
        for (final entry in selectedCounts.entries) {
          expect(
            entry.value,
            greaterThan(0),
            reason: '${entry.key} in $brightness',
          );
        }
        focus.unfocus();
        await tester.pump();
        final unfocused = editable.text as TextSpan;
        expect(
          unfocused.children!.whereType<TextSpan>().any(
            (span) => span.style?.backgroundColor?.a == 1,
          ),
          isTrue,
          reason: 'restore syntax when the field hides its selection on blur',
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'selection changes preserve cached syntax and restore backgrounds',
    (tester) async {
      const text = '2::warm light::,\n<room> 🌤️, plain';
      final controller = NaiSyntaxController(text: text);
      addTearDown(controller.dispose);
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      TextSpan build() => controller.buildTextSpan(
        context: context,
        style: const TextStyle(fontSize: 14),
        withComposing: false,
      );
      controller.updateSearchHighlights(
        matches: [
          const TextRange(start: 3, end: 7),
          TextRange(start: text.indexOf('room'), end: text.indexOf('room') + 4),
        ],
        activeMatchIndex: 1,
      );
      final original = build();
      final originalBackgrounds = [
        for (final span in original.children!.cast<TextSpan>())
          ...List<Color?>.filled(
            span.text!.length,
            span.style?.backgroundColor,
          ),
      ];
      final start = text.indexOf('light');
      final end = text.indexOf('plain');
      for (final range in [
        TextSelection(baseOffset: start, extentOffset: end),
        TextSelection(baseOffset: end, extentOffset: start),
        const TextSelection(baseOffset: 0, extentOffset: text.length),
      ]) {
        controller.selection = range;
        final selected = build();
        expect(selected.toPlainText(), text);
        var offset = 0;
        for (final span in selected.children!.cast<TextSpan>()) {
          final next = offset + span.text!.length;
          for (var position = offset; position < next; position++) {
            if (position >= range.start && position < range.end) {
              expect(span.style?.backgroundColor?.a ?? 0, 0);
            } else {
              expect(
                span.style?.backgroundColor,
                originalBackgrounds[position],
              );
            }
          }
          offset = next;
        }
      }
      controller.selection = const TextSelection.collapsed(offset: 0);
      expect(build().children, same(original.children));
    },
  );
}
