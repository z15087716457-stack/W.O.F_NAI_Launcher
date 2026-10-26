import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/numpad_editing_shortcuts.dart';

void main() {
  Future<void> onWindows(Future<void> Function() body) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  Future<TextEditingController> editor(WidgetTester tester) async {
    final controller = TextEditingController(text: 'Flutter');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => NumpadEditingShortcuts(child: child!),
        home: Scaffold(body: TextField(controller: controller, maxLines: 3)),
      ),
    );
    await tester.tap(find.byType(TextField));
    controller.selection = const TextSelection.collapsed(offset: 7);
    await tester.pump();
    expect(
      HardwareKeyboard.instance.lockModesEnabled,
      isNot(contains(KeyboardLockMode.numLock)),
    );
    return controller;
  }

  testWidgets(
    'NumLock off moves, collapses, extends and deletes in a TextField',
    (tester) => onWindows(() async {
      final controller = await editor(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad4);
      expect(controller.selection, const TextSelection.collapsed(offset: 6));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad4);
      expect(
        controller.selection,
        const TextSelection(baseOffset: 6, extentOffset: 5),
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad6);
      expect(controller.selection, const TextSelection.collapsed(offset: 6));
      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadDecimal);
      expect(controller.text, 'lutter');
    }),
  );

  testWidgets(
    'NumLock on passes number keys through to native text input',
    (tester) => onWindows(() async {
      final controller = await editor(tester);
      // Reproduce startup with NumLock on but absent from lockModesEnabled.
      expect(
        await tester.sendKeyEvent(LogicalKeyboardKey.numpad4, character: '4'),
        isFalse,
      );
      expect(controller.selection, const TextSelection.collapsed(offset: 7));
      // Windows sends text input separately from hardware key events.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Flutter4',
          selection: TextSelection.collapsed(offset: 8),
        ),
      );
      await tester.pump();
      expect(controller.text, 'Flutter4');
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad4);
      expect(controller.selection, const TextSelection.collapsed(offset: 7));
    }),
  );

  testWidgets(
    'all digit and decimal events pass even without lock state',
    (tester) => onWindows(() async {
      final controller = await editor(tester);
      for (final (key, character) in [
        (LogicalKeyboardKey.numpad0, '0'),
        (LogicalKeyboardKey.numpad1, '1'),
        (LogicalKeyboardKey.numpad2, '2'),
        (LogicalKeyboardKey.numpad3, '3'),
        (LogicalKeyboardKey.numpad4, '4'),
        (LogicalKeyboardKey.numpad5, '5'),
        (LogicalKeyboardKey.numpad6, '6'),
        (LogicalKeyboardKey.numpad7, '7'),
        (LogicalKeyboardKey.numpad8, '8'),
        (LogicalKeyboardKey.numpad9, '9'),
        (LogicalKeyboardKey.numpadDecimal, '.'),
      ]) {
        final before = controller.value;
        expect(await simulateKeyDownEvent(key, character: character), isFalse);
        await simulateKeyUpEvent(key);
        expect(controller.value, before);
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: before.text + character,
            selection: TextSelection.collapsed(offset: before.text.length + 1),
          ),
        );
        await tester.pump();
        expect(controller.text, before.text + character);
      }
    }),
  );

  testWidgets(
    'event beats stale locked state; Ctrl/Shift Home/End stay intact',
    (tester) => onWindows(() async {
      final controller = await editor(tester);
      controller.text = 'one two\nthree four';
      controller.selection = const TextSelection.collapsed(offset: 12);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.numLock);
      expect(
        HardwareKeyboard.instance.lockModesEnabled,
        contains(KeyboardLockMode.numLock),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad7);
      expect(controller.selection.extentOffset, 8);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad1);
      expect(controller.selection.extentOffset, 18);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad7);
      expect(
        controller.selection,
        const TextSelection(baseOffset: 18, extentOffset: 0),
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad1);
      expect(controller.selection.extentOffset, 18);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      final before = controller.selection;
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.numpad4), isFalse);
      expect(controller.selection, before);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.numLock);
    }),
  );

  testWidgets(
    'unlocked navigation intents (7/1 = Home/End), with Shift extensions',
    (tester) => onWindows(() async {
      const child = SizedBox();
      await tester.pumpWidget(const NumpadEditingShortcuts(child: child));
      final shortcuts = tester.widget<Shortcuts>(find.byType(Shortcuts));
      for (final shift in [false, true]) {
        for (final (key, type, forward) in [
          (LogicalKeyboardKey.numpad4, ExtendSelectionByCharacterIntent, false),
          (LogicalKeyboardKey.numpad6, ExtendSelectionByCharacterIntent, true),
          (
            LogicalKeyboardKey.numpad8,
            ExtendSelectionVerticallyToAdjacentLineIntent,
            false,
          ),
          (
            LogicalKeyboardKey.numpad2,
            ExtendSelectionVerticallyToAdjacentLineIntent,
            true,
          ),
          (LogicalKeyboardKey.numpad7, ExtendSelectionToLineBreakIntent, false),
          (LogicalKeyboardKey.numpad1, ExtendSelectionToLineBreakIntent, true),
          (
            LogicalKeyboardKey.numpad9,
            ExtendSelectionVerticallyToAdjacentPageIntent,
            false,
          ),
          (
            LogicalKeyboardKey.numpad3,
            ExtendSelectionVerticallyToAdjacentPageIntent,
            true,
          ),
        ]) {
          final intent = shortcuts.shortcuts.entries.singleWhere((entry) {
            final activator = entry.key as SingleActivator;
            return activator.trigger == key &&
                activator.shift == shift &&
                !activator.control;
          }).value;
          expect(intent.runtimeType, type);
          final directional = intent as DirectionalCaretMovementIntent;
          expect(directional.forward, forward);
          expect(directional.collapseSelection, !shift);
        }
      }
      expect(
        shortcuts.shortcuts.keys.cast<SingleActivator>().every(
          (a) =>
              a is NumpadNavigationActivator && a.numLock == LockState.ignored,
        ),
        isTrue,
      );
    }),
  );

  testWidgets('non-Windows platforms return the child without new shortcuts', (
    tester,
  ) async {
    try {
      for (final platform in TargetPlatform.values.where(
        (p) => p != TargetPlatform.windows,
      )) {
        debugDefaultTargetPlatformOverride = platform;
        const child = SizedBox();
        await tester.pumpWidget(const NumpadEditingShortcuts(child: child));
        expect(find.byType(Shortcuts), findsNothing);
        expect(find.byWidget(child), findsOneWidget);
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
