import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/text_editing_shortcuts.dart';

Future<void> _key(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await t.sendKeyEvent(key);
  await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await t.pump();
}

void main() {
  testWidgets(
    'fallback only uses the latest live owner on the current route; text and boundaries win',
    (t) async {
      final router = GlobalKey<TextEditingShortcutsState>();
      final nav = GlobalKey<NavigatorState>();
      final first = GlobalKey();
      final second = GlobalKey();
      final blank = FocusNode();
      final ownUndo = FocusNode();
      final boundaryBlank = FocusNode();
      final field = TextEditingController();
      addTearDown(boundaryBlank.dispose);
      addTearDown(blank.dispose);
      addTearDown(ownUndo.dispose);
      addTearDown(field.dispose);
      var a = 0;
      var b = 0;
      var redo = 0;
      var pageUndo = 0;
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          builder: (_, child) =>
              TextEditingShortcuts(key: router, child: child!),
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(key: first),
                SizedBox(key: second),
                Focus(focusNode: blank, child: const Text('blank')),
                PromptUndoBoundary(
                  child: Focus(
                    focusNode: ownUndo,
                    onKeyEvent: (_, e) {
                      if (e is KeyDownEvent &&
                          e.logicalKey == LogicalKeyboardKey.keyZ &&
                          HardwareKeyboard.instance.isControlPressed) {
                        pageUndo++;
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: const Text('own undo'),
                  ),
                ),
                PromptUndoBoundary(
                  child: Focus(
                    focusNode: boundaryBlank,
                    child: const Text('boundary without action'),
                  ),
                ),
                TextField(controller: field),
              ],
            ),
          ),
        ),
      );
      router.currentState!.rememberPrompt(
        first.currentContext!,
        undo: () => a++,
        redo: () => redo++,
      );
      router.currentState!.rememberPrompt(
        second.currentContext!,
        undo: () => b++,
        redo: () => redo++,
      );
      blank.requestFocus();
      await t.pump();
      await _key(t, LogicalKeyboardKey.keyZ);
      await _key(t, LogicalKeyboardKey.keyY);
      expect((a, b, redo), (0, 1, 1));
      router.currentState!.forgetPrompt(first.currentContext!);
      await _key(t, LogicalKeyboardKey.keyZ);
      expect(
        b,
        2,
        reason: 'disposing an older editor must not clear the latest target',
      );

      await t.tap(find.byType(TextField));
      await t.pump();
      for (final text in ['one', 'two']) {
        t.testTextInput.updateEditingValue(
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );
        await t.pump(const Duration(milliseconds: 550));
      }
      expect(hasEditableTextFocus, isTrue);
      await _key(t, LogicalKeyboardKey.keyZ);
      expect(field.text, 'one');
      await _key(t, LogicalKeyboardKey.keyY);
      expect(field.text, 'two');
      expect((a, b, redo), (0, 2, 1));

      ownUndo.requestFocus();
      await t.pump();
      await _key(t, LogicalKeyboardKey.keyZ);
      await _key(t, LogicalKeyboardKey.keyY);
      expect(pageUndo, 1);
      expect(
        (b, redo),
        (2, 1),
        reason: 'even an unhandled boundary redo cannot leak into a prompt',
      );
      boundaryBlank.requestFocus();
      await t.pump();
      await _key(t, LogicalKeyboardKey.keyZ);
      await _key(t, LogicalKeyboardKey.keyY);
      expect(
        (b, redo),
        (2, 1),
        reason: 'a boundary blocks fallback even without a local handler',
      );

      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: Focus(autofocus: true, child: Text('viewer')),
          ),
        ),
      );
      await t.pumpAndSettle();
      await _key(t, LogicalKeyboardKey.keyZ);
      expect(b, 2);
      nav.currentState!.pop();
      await t.pumpAndSettle();
      blank.requestFocus();
      await t.pump();
      await _key(t, LogicalKeyboardKey.keyZ);
      expect(b, 3);
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await _key(t, LogicalKeyboardKey.keyZ);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(redo, 2);
      await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await _key(t, LogicalKeyboardKey.keyZ);
      await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      expect(b, 3, reason: 'Ctrl+Alt+Z is not prompt undo');
      router.currentState!.forgetPrompt(second.currentContext!);
      await _key(t, LogicalKeyboardKey.keyZ);
      expect(b, 3);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets('unmounted prompt target is ignored', (t) async {
    final router = GlobalKey<TextEditingShortcutsState>();
    final owner = GlobalKey();
    final blank = FocusNode();
    addTearDown(blank.dispose);
    var visible = true;
    var count = 0;
    late StateSetter update;
    await t.pumpWidget(
      MaterialApp(
        builder: (_, child) => TextEditingShortcuts(key: router, child: child!),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, setState) {
              update = setState;
              return Column(
                children: [
                  if (visible) SizedBox(key: owner),
                  Focus(focusNode: blank, child: const Text('blank')),
                ],
              );
            },
          ),
        ),
      ),
    );
    router.currentState!.rememberPrompt(
      owner.currentContext!,
      undo: () => count++,
      redo: () => count++,
    );
    update(() => visible = false);
    await t.pump();
    blank.requestFocus();
    await t.pump();
    await _key(t, LogicalKeyboardKey.keyZ);
    expect(count, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
