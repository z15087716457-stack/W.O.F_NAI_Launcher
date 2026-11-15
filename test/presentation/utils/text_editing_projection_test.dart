import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/utils/text_editing_projection.dart';

EditingTextProjection sample() =>
    EditingTextProjection('a😀, blue eyes', const [
      EditingProjectionPart(start: 0, end: 1, text: 'a\u2060'),
      EditingProjectionPart(start: 1, end: 3, text: '😀\u2060'),
      EditingProjectionPart(start: 3, end: 3, text: '\uFFFC', annotation: 0),
      EditingProjectionPart(start: 3, end: 5, text: ', '),
      EditingProjectionPart(start: 5, end: 5, text: '\n'),
      EditingProjectionPart(start: 5, end: 14, text: 'blue eyes'),
      EditingProjectionPart(
        start: 14,
        end: 14,
        text: '\u2060\uFFFC',
        annotation: 1,
      ),
    ]);

void main() {
  test(
    'zero-length IME ranges stay valid at annotation and line boundaries',
    () {
      final p = sample();
      for (final offset in [0, 3, 5, 14]) {
        final raw = TextEditingValue(
          text: p.source,
          selection: TextSelection.collapsed(offset: offset),
          composing: TextRange(start: offset, end: offset),
        );
        final displayed = p.toDisplayValue(raw);
        expect(displayed.isComposingRangeValid, isTrue);
        expect(displayed.composing.isValid, isTrue);
        expect(displayed.composing.isCollapsed, isTrue);
        final restored = p.sourceEdit(displayed, displayed);
        expect(restored.composing, raw.composing);
        expect(restored.text, raw.text);
      }
    },
  );
  test(
    'source boundaries and selections round-trip through annotation positions',
    () {
      final p = sample();
      for (final offset in [0, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]) {
        for (final affinity in TextAffinity.values) {
          final raw = TextEditingValue(
            text: p.source,
            selection: TextSelection.collapsed(
              offset: offset,
              affinity: affinity,
            ),
          );
          final projected = p.toDisplayValue(raw);
          expect(p.toSource(projected.selection.extentOffset), offset);
          expect(p.sourceSelection(projected.selection).extentOffset, offset);
        }
      }
      for (final selection in const [
        TextSelection(baseOffset: 1, extentOffset: 14),
        TextSelection(baseOffset: 14, extentOffset: 1, isDirectional: true),
      ]) {
        final displayed = p.toDisplayValue(
          TextEditingValue(text: p.source, selection: selection),
        );
        expect(p.sourceSelection(displayed.selection), selection);
      }
    },
  );

  test(
    'composing ranges contain source characters and preserve emoji UTF-16 offsets',
    () {
      final p = sample();
      final raw = TextEditingValue(
        text: p.source,
        selection: const TextSelection.collapsed(offset: 3),
        composing: const TextRange(start: 1, end: 3),
      );
      final view = p.toDisplayValue(raw);
      final result = p.sourceEdit(
        view,
        view.copyWith(composing: TextRange.empty),
      );
      expect(result.text, raw.text);
      expect(result.selection.extentOffset, 3);
      expect(result.composing, TextRange.empty);
      expect(p.toSource(view.composing.start), 1);
      expect(p.toSource(view.composing.end), 3);
    },
  );

  test(
    'replacing a selection across captions changes only the selected source',
    () {
      final p = sample();
      final before = p.toDisplayValue(
        TextEditingValue(
          text: p.source,
          selection: const TextSelection(baseOffset: 1, extentOffset: 12),
        ),
      );
      final start = before.selection.start;
      final after = before.copyWith(
        text: before.text.replaceRange(start, before.selection.end, '世界'),
        selection: TextSelection.collapsed(offset: start + 2),
      );
      final result = p.sourceEdit(before, after);
      expect(result.text, 'a世界es');
      expect(result.selection.extentOffset, 3);
      expect(result.text, isNot(contains('\u2060')));
      expect(result.text, isNot(contains('\uFFFC')));
    },
  );

  test('backspace and forward delete skip generated controls', () {
    final p = EditingTextProjection('abc', const [
      EditingProjectionPart(start: 0, end: 1, text: 'a\u2060'),
      EditingProjectionPart(start: 1, end: 1, text: '\uFFFC', annotation: 0),
      EditingProjectionPart(start: 1, end: 3, text: 'bc'),
    ]);
    final before = p.toDisplayValue(
      const TextEditingValue(
        text: 'abc',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    final at = before.selection.extentOffset;
    final back = p.sourceEdit(
      before,
      before.copyWith(
        text: before.text.replaceRange(at - 1, at, ''),
        selection: TextSelection.collapsed(offset: at - 1),
      ),
    );
    expect(back.text, 'bc');
    expect(back.selection.extentOffset, 0);
    final forward = p.toDisplayValue(
      const TextEditingValue(
        text: 'abc',
        selection: TextSelection.collapsed(
          offset: 1,
          affinity: TextAffinity.upstream,
        ),
      ),
    );
    final pos = forward.selection.extentOffset;
    final result = p.sourceEdit(
      forward,
      forward.copyWith(
        text: forward.text.replaceRange(pos, pos + 1, ''),
        selection: TextSelection.collapsed(offset: pos),
      ),
    );
    expect(result.text, 'ac');
    expect(result.selection.extentOffset, 1);
  });

  test(
    'manual newline beside a generated line break stays a real source newline',
    () {
      final p = EditingTextProjection('ab', const [
        EditingProjectionPart(start: 0, end: 1, text: 'a'),
        EditingProjectionPart(
          start: 1,
          end: 1,
          text: '\n\uFFFC',
          annotation: 0,
        ),
        EditingProjectionPart(start: 1, end: 2, text: 'b'),
      ]);
      final before = p.toDisplayValue(
        const TextEditingValue(
          text: 'ab',
          selection: TextSelection.collapsed(
            offset: 1,
            affinity: TextAffinity.upstream,
          ),
        ),
      );
      final at = before.selection.extentOffset;
      final after = before.copyWith(
        text: before.text.replaceRange(at, at, '\n'),
        selection: TextSelection.collapsed(offset: at + 1),
      );
      final result = p.sourceEdit(before, after);
      expect(result.text, 'a\nb');
      expect(result.selection.extentOffset, 2);
    },
  );

  test(
    'native undo snapshots retain their own mapping and never save view markers',
    () {
      final before = sample();
      final snapshot = before.toDisplayValue(
        TextEditingValue(
          text: before.source,
          selection: const TextSelection(baseOffset: 5, extentOffset: 14),
        ),
      );
      expect(
        snapshot.copyWith(composing: TextRange.empty),
        isA<ProjectedEditingValue>(),
      );
      final current = EditingTextProjection.identity('new raw source');
      final now = current.toDisplayValue(
        const TextEditingValue(
          text: 'new raw source',
          selection: TextSelection.collapsed(offset: 14),
        ),
      );
      final restored = current.sourceEdit(
        now,
        snapshot.copyWith(composing: TextRange.empty),
      );
      expect(restored.text, before.source);
      expect(
        restored.selection,
        const TextSelection(baseOffset: 5, extentOffset: 14),
      );
      expect(restored.text, isNot(contains('\uFFFC')));
      expect(
        snapshot.copyWith(text: 'typed value'),
        isNot(isA<ProjectedEditingValue>()),
      );
    },
  );

  test(
    'unchanged source newlines remain selectable, caption placeholders do not',
    () {
      final p = sample();
      for (final range in p.sourceRanges) {
        expect(
          p.text.substring(range.start, range.end),
          isNot(contains('\uFFFC')),
        );
      }
      final plain = EditingTextProjection.identity('a\nb');
      expect(plain.text, 'a\nb');
      expect(plain.toSource(2), 2);
    },
  );
}
