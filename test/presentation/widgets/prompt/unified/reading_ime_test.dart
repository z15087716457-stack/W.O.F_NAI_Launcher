import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/data/models/prompt_reading.dart';
import '../../../../helpers/studio_capture_fonts.dart';
import 'inline_prompt_readings_test.dart' as fixture;

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final caret in [0, 5, 11]) {
    testWidgets(
      'IME inside a translated fragment keeps its buffer caret=$caret',
      (t) async {
        final c = TextEditingController(text: 'silver hair, ');
        final focus = FocusNode();
        await fixture.pumpReadingEditor(t, c, [
          const PromptReading(
            start: 0,
            end: 11,
            source: 'silver hair',
            translation: '银发',
            perSegment: true,
          ),
        ], focusNode: focus);
        await t.showKeyboard(find.byType(TextField));
        c.selection = TextSelection.collapsed(offset: caret);
        await t.pump();
        final view = t
            .widget<EditableText>(find.byType(EditableText))
            .controller;
        final original = view.text;
        final start = view.selection.extentOffset;
        t.testTextInput.log.clear();
        for (final letters in [
          '',
          'a',
          'as',
          "a's",
          "a's'd",
          "a's",
          "a's'd",
          '阿斯顿',
        ]) {
          final value = TextEditingValue(
            text: original.replaceRange(start, start, letters),
            selection: TextSelection.collapsed(offset: start + letters.length),
            composing: TextRange(start: start, end: start + letters.length),
          );
          t.testTextInput.updateEditingValue(value);
          await t.pump();
          expect(view.value, value);
          expect(c.text, 'silver hair, '.replaceRange(caret, caret, letters));
          expect(
            t.testTextInput.log.where(
              (call) => call.method == 'TextInput.setEditingState',
            ),
            isEmpty,
          );
        }
        final commit = view.value.copyWith(
          composing: TextRange(start: start + 3, end: start + 3),
        );
        t.testTextInput.updateEditingValue(commit);
        await t.pump();
        expect(view.value, commit);
        expect(
          t.testTextInput.log.where(
            (call) => call.method == 'TextInput.setEditingState',
          ),
          isEmpty,
        );
        t.testTextInput.updateEditingValue(
          commit.copyWith(composing: TextRange.empty),
        );
        await t.pump();
        expect(c.text, 'silver hair, '.replaceRange(caret, caret, '阿斯顿'));
        expect(c.value.composing, TextRange.empty);
        expect(view.value.composing, TextRange.empty);
        expect(fixture.readingLabels(), findsWidgets);
        await t.pumpWidget(const SizedBox());
        c.dispose();
        focus.dispose();
        await t.binding.setSurfaceSize(null);
      },
      variant: const TargetPlatformVariant({TargetPlatform.windows}),
    );
  }
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
