import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/prompt_autocomplete_controller.dart';
import 'package:nai_launcher/presentation/widgets/prompt/prompt_autocomplete_binding.dart';
import '../../../core/autocomplete/prompt_autocomplete_controller_test.dart'
    show candidates;

void main() {
  for (final key in [LogicalKeyboardKey.tab, LogicalKeyboardKey.enter]) {
    testWidgets('visible completion handles $key without moving editor focus', (
      tester,
    ) async {
      final completion = PromptAutocompleteController(
        enabled: true,
        search: (_) async => candidates,
      );
      final text = TextEditingController();
      final focus = FocusNode();
      addTearDown(() {
        completion.dispose();
        text.dispose();
        focus.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PromptAutocompleteBinding(
              autocomplete: completion,
              controller: text,
              focusNode: focus,
              locale: 'en',
              autoInsertComma: true,
              onAccept: (value) => text.value = value,
              child: TextField(
                controller: text,
                focusNode: focus,
                maxLines: null,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'bl');
      await tester.pump(const Duration(milliseconds: 120));
      expect(completion.value.visible, true);
      expect(focus.hasPrimaryFocus, true);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(completion.value.selectedIndex, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(completion.value.selectedIndex, 0);
      await tester.sendKeyEvent(key);
      await tester.pump();
      expect(text.text, 'blue eyes, ');
      expect(focus.hasPrimaryFocus, true);
      expect(completion.value.visible, false);
      await tester.pump(const Duration(milliseconds: 150));
      expect(completion.value.visible, false);
      await tester.enterText(find.byType(TextField), 'bl');
      await tester.pump(const Duration(milliseconds: 120));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(completion.value.visible, false);
      expect(focus.hasPrimaryFocus, true);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'hidden autocomplete leaves Enter newline and Tab traversal intact',
    (tester) async {
      var calls = 0;
      final completion = PromptAutocompleteController(
        enabled: true,
        search: (_) async {
          calls++;
          return const [];
        },
      );
      final text = TextEditingController();
      final focus = FocusNode();
      final next = FocusNode();
      final unhandled = <LogicalKeyboardKey>[];
      addTearDown(() {
        completion.dispose();
        text.dispose();
        focus.dispose();
        next.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Focus(
              canRequestFocus: false,
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent) unhandled.add(event.logicalKey);
                return KeyEventResult.ignored;
              },
              child: Column(
                children: [
                  PromptAutocompleteBinding(
                    autocomplete: completion,
                    controller: text,
                    focusNode: focus,
                    locale: 'en',
                    autoInsertComma: true,
                    onAccept: (value) => text.value = value,
                    child: TextField(
                      controller: text,
                      focusNode: focus,
                      maxLines: null,
                    ),
                  ),
                  TextField(focusNode: next),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'bl');
      await tester.pump(const Duration(milliseconds: 120));
      expect(calls, 1);
      expect(completion.value.visible, false);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(unhandled, contains(LogicalKeyboardKey.enter));
      // The test IME delivers the newline after shortcut handling.
      await tester.testTextInput.receiveAction(TextInputAction.newline);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'bl\n',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();
      expect(text.text, 'bl\n');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(next.hasPrimaryFocus, true);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
