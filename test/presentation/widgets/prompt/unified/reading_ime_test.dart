import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/data/models/prompt_reading.dart';
import '../../../../helpers/studio_capture_fonts.dart';
import 'inline_prompt_readings_test.dart' as fixture;

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final annotated in [false, true]) {
    testWidgets(
      'IME lifecycle preserves empty composition ranges annotated=$annotated',
      (t) async {
        final prefix = annotated ? 'silver hair, ' : '';
        final c = TextEditingController(text: prefix), focus = FocusNode();
        await fixture.pumpReadingEditor(t, c, [
          if (annotated)
            const PromptReading(
              start: 0,
              end: 11,
              source: 'silver hair',
              translation: '银发',
              perSegment: true,
            ),
        ], focusNode: focus);
        await t.showKeyboard(find.byType(TextField));
        c.selection = TextSelection.collapsed(offset: prefix.length);
        await t.pump();
        final state = t.state<EditableTextState>(find.byType(EditableText));
        final view = state.widget.controller;
        final start = view.selection.extentOffset;
        final displayPrefix = view.text;
        // Windows composition begins with a valid, zero-length composing
        // range before the IME sends any letters.
        final begin = TextEditingValue(
          text: displayPrefix,
          selection: TextSelection.collapsed(offset: start),
          composing: TextRange(start: start, end: start),
        );
        t.testTextInput.log.clear();
        t.testTextInput.updateEditingValue(begin);
        await t.pump();
        expect(view.value, begin);
        expect(
          c.value.composing,
          TextRange(start: prefix.length, end: prefix.length),
        );
        expect(
          t.testTextInput.log.where(
            (call) => call.method == 'TextInput.setEditingState',
          ),
          isEmpty,
          reason: 'Do not cancel the IME composing range on composition start',
        );
        for (final letters in ['k', 'ke', 'keq', "ke'qi", "ke'qing"]) {
          final next = TextEditingValue(
            text: displayPrefix + letters,
            selection: TextSelection.collapsed(offset: start + letters.length),
            composing: TextRange(start: start, end: start + letters.length),
          );
          t.testTextInput.updateEditingValue(next);
          await t.pump();
          expect(view.value, next);
          expect(c.text, prefix + letters);
        }
        const committed = '刻晴';
        final candidate = TextEditingValue(
          text: '$displayPrefix$committed',
          selection: TextSelection.collapsed(offset: start + 2),
          composing: TextRange(start: start, end: start + 2),
        );
        t.testTextInput.updateEditingValue(candidate);
        await t.pump();
        expect(view.value, candidate);
        expect(c.text, '$prefix$committed');
        final commit = TextEditingValue(
          text: '$displayPrefix$committed',
          selection: TextSelection.collapsed(offset: start + 2),
          composing: TextRange(start: start + 2, end: start + 2),
        );
        t.testTextInput.updateEditingValue(commit);
        await t.pump();
        expect(view.value, commit);
        expect(c.text, '$prefix$committed');
        expect(
          c.value.composing,
          TextRange(start: prefix.length + 2, end: prefix.length + 2),
        );
        for (var i = 0; i < 3; i++) {
          t.testTextInput.updateEditingValue(commit);
          await t.pump();
          expect(view.value, commit);
          expect(c.text, '$prefix$committed');
        }
        t.testTextInput.updateEditingValue(
          commit.copyWith(composing: TextRange.empty),
        );
        await t.pump();
        expect(view.value.composing, TextRange.empty);
        expect(c.text, '$prefix$committed');
        expect(
          t.state<EditableTextState>(find.byType(EditableText)),
          same(state),
        );
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        c.dispose();
        focus.dispose();
        await t.binding.setSurfaceSize(null);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.windows,
        TargetPlatform.macOS,
      }),
    );
  }
}
