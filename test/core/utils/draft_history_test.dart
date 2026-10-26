import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/draft_history.dart';

void main() {
  testWidgets('typing groups immediately and idle starts a new undo step', (
    t,
  ) async {
    final history = DraftHistory('');
    addTearDown(history.dispose);
    history.record('a', merge: true);
    history.record('ab', merge: true);
    expect(history.undo(), '');
    expect(history.redo(), 'ab');
    history.record('abc', merge: true);
    await t.pump(const Duration(milliseconds: 501));
    history.record('abcd', merge: true);
    expect(history.undo(), 'abc');
    expect(history.undo(), 'ab');
  });

  test('program replacements split typing groups and branch discards redo', () {
    final history = DraftHistory('initial');
    addTearDown(history.dispose);
    history.record('typed', merge: true);
    history.record('import');
    history.record('import typed', merge: true);
    expect(history.undo(), 'import');
    expect(history.undo(), 'typed');
    expect(history.undo(), 'initial');
    expect(history.undo(), isNull);
    expect(history.redo(), 'typed');
    history.record('branch');
    expect(history.canRedo, isFalse);
    expect(history.redo(), isNull);
  });

  test('equivalent snapshots do not create steps or erase redo', () {
    final history = DraftHistory('initial');
    addTearDown(history.dispose);
    history.record('first');
    history.record('second');
    expect(history.undo(), 'first');
    history.record('first');
    expect(history.canRedo, isTrue);
    expect(history.redo(), 'second');
  });

  test(
    'translation controller replacements support immediate undo and redo',
    () {
      final controller = TextEditingController(text: 'original');
      final history = TextDraftHistory(controller);
      addTearDown(() {
        history.dispose();
        controller.dispose();
      });
      controller.value = const TextEditingValue(
        text: 'typed',
        selection: TextSelection.collapsed(offset: 3),
      );
      history.replace(
        const TextEditingValue(
          text: 'model',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      history.undo();
      expect(controller.text, 'typed');
      expect(controller.selection.extentOffset, 3);
      history.redo();
      expect(controller.text, 'model');
      history.undo();
      history.undo();
      expect(controller.text, 'original');
      expect(controller.selection.extentOffset, 8);
    },
  );

  test(
    'translation IME preedit is skipped, committed selection is restored',
    () {
      final controller = TextEditingController();
      final history = TextDraftHistory(controller);
      addTearDown(() {
        history.dispose();
        controller.dispose();
      });
      controller.value = const TextEditingValue(
        text: 'ni',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      );
      controller.value = const TextEditingValue(
        text: '你',
        selection: TextSelection.collapsed(offset: 1),
      );
      history.undo();
      expect(controller.text, isEmpty);
      history.redo();
      expect(controller.text, '你');
      expect(controller.value.composing, TextRange.empty);
    },
  );
}
