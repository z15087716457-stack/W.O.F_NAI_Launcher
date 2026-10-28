import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/translation_pill_view.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_input.dart';

import '../../../core/settings/settings_preferences_service_test.dart'
    show MemoryStorage;
import '../../../helpers/studio_capture_fonts.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final brightness in Brightness.values) {
    for (final translation in [false, true]) {
      for (final width in [240.0, 500.0]) {
        testWidgets('Windows syntax caret can click, edit and move: '
            '$brightness, translation=$translation, width=$width', (
          tester,
        ) async {
          await tester.runAsync(loadStudioCaptureFonts);
          debugDefaultTargetPlatformOverride = TargetPlatform.windows;
          EditableText.debugDeterministicCursor = true;
          addTearDown(() {
            debugDefaultTargetPlatformOverride = null;
            EditableText.debugDeterministicCursor = false;
          });
          const text =
              'plain, 0.4::deaver::, 0.7::soft::, 1.5::warm::,\n'
              '2.5::sun::, -1::cool::, {eyes}';
          const cursorColor = Color(0xFFFF00FF);
          final external = TextEditingController(text: text);
          addTearDown(external.dispose);
          var changed = text;
          var pill = const TranslationPill(
            source: text,
            zh: '译文',
            showOriginal: true,
          );
          final boundaryKey = GlobalKey();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                localStorageServiceProvider.overrideWithValue(MemoryStorage()),
              ],
              child: MaterialApp(
                theme: AppTheme.getTheme(AppStyle.geist, brightness).copyWith(
                  textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: cursorColor,
                  ),
                ),
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: RepaintBoundary(
                      key: boundaryKey,
                      child: SizedBox(
                        width: width,
                        height: 360,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: StatefulBuilder(
                            builder: (context, setState) => translation
                                ? TranslationPillView(
                                    pill: pill,
                                    onToggle: () {},
                                    onEdit: (_) {},
                                    onSourceChanged: (value) => setState(() {
                                      changed = value;
                                      pill = pill.copyWith(source: value);
                                    }),
                                  )
                                : UnifiedPromptInput(
                                    controller: external,
                                    config: const UnifiedPromptConfig(
                                      enableAutoFormat: false,
                                      embedded: true,
                                    ),
                                    fitContent: true,
                                    onChanged: (value) => changed = value,
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
          final state = tester.state<EditableTextState>(
            find.byType(EditableText),
          );
          final controller = state.widget.controller;
          final editable = state.renderEditable;
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final counts = <String, int>{};
          for (final word in [
            'plain',
            'deaver',
            'soft',
            'warm',
            'sun',
            'cool',
            'eyes',
          ]) {
            await tester.pump(const Duration(milliseconds: 600));
            final offset = text.indexOf(word) + word.length ~/ 2;
            final rect = editable.getLocalRectForCaret(
              TextPosition(offset: offset),
            );
            await tester.tapAt(
              editable.localToGlobal(rect.center),
              kind: PointerDeviceKind.mouse,
            );
            await tester.pump();
            await tester.pump();
            expect(controller.selection.extentOffset, offset, reason: word);
            expect(controller.selection.isCollapsed, isTrue);
            counts[word] = await _cursorPixels(
              tester,
              editable,
              boundary,
              '${brightness.name}-${translation ? 'translation' : 'prompt'}'
              '-${width.toInt()}-$word',
            );
          }

          // Simulate the platform inserting at the clicked caret, then move
          // with Windows arrow keys. Both edits rebuild EditableText.
          final at = controller.selection.extentOffset;
          final edited = text.replaceRange(at, at, 'x');
          tester.testTextInput.updateEditingValue(
            TextEditingValue(
              text: edited,
              selection: TextSelection.collapsed(offset: at + 1),
            ),
          );
          await tester.pump();
          await tester.pump();
          expect(changed, edited);
          expect(controller.text, edited);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          await tester.pump();
          await tester.pump();
          expect(controller.selection.extentOffset, at);
          counts['after-edit-left'] = await _cursorPixels(
            tester,
            editable,
            boundary,
            '${brightness.name}-${translation ? 'translation' : 'prompt'}'
            '-${width.toInt()}-after-edit-left',
          );
          for (final entry in counts.entries) {
            expect(
              entry.value,
              greaterThan(4),
              reason: 'visible caret in ${entry.key}; all pixels: $counts',
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          debugDefaultTargetPlatformOverride = null;
          EditableText.debugDeterministicCursor = false;
        });
      }
    }
  }
}

Future<int> _cursorPixels(
  WidgetTester tester,
  RenderEditable editable,
  RenderRepaintBoundary boundary,
  String name,
) async {
  final rect = editable
      .getLocalRectForCaret(editable.selection!.extent)
      .shift(editable.localToGlobal(Offset.zero, ancestor: boundary));
  var pixels = 0;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++) {
      for (var x = rect.left.floor(); x < rect.right.ceil(); x++) {
        final offset = (y * image.width + x) * 4;
        if (bytes.getUint8(offset) > 240 &&
            bytes.getUint8(offset + 1) < 15 &&
            bytes.getUint8(offset + 2) > 240) {
          pixels++;
        }
      }
    }
    final capture = Platform.environment['PROMPT_CARET_CAPTURE_DIR'];
    if (capture != null) {
      final file = File('$capture/$name.png');
      await file.parent.create(recursive: true);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(png!.buffer.asUint8List());
    }
    image.dispose();
  });
  return pixels;
}
