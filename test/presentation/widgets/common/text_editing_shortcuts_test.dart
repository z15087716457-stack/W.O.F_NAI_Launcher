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

/// 按住 [modifiers] 按一下 [key]。
Future<void> _press(
  WidgetTester t,
  List<LogicalKeyboardKey> modifiers,
  LogicalKeyboardKey key,
) async {
  for (final m in modifiers) {
    await t.sendKeyDownEvent(m);
  }
  await t.sendKeyEvent(key);
  for (final m in modifiers.reversed) {
    await t.sendKeyUpEvent(m);
  }
  await t.pump();
}

/// 输入框里先后输入「a」「ab」，留下两步撤销记录。
Future<TextEditingController> _editor(
  WidgetTester t, {
  FocusNode? elsewhere,
}) async {
  final controller = TextEditingController();
  addTearDown(controller.dispose);
  await t.pumpWidget(
    MaterialApp(
      builder: (_, child) => TextEditingShortcuts(child: child!),
      home: Scaffold(
        body: Column(
          children: [
            TextField(controller: controller),
            Focus(
              focusNode: elsewhere,
              child: const SizedBox(width: 10, height: 10),
            ),
          ],
        ),
      ),
    ),
  );
  await t.tap(find.byType(TextField));
  await t.pump();
  // 撤销记录会合并很短时间里的改动，两次输入之间等一会儿
  await t.enterText(find.byType(TextField), 'a');
  await t.pump(const Duration(seconds: 1));
  await t.enterText(find.byType(TextField), 'ab');
  await t.pump(const Duration(seconds: 1));
  return controller;
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

  testWidgets(
    'macOS: Cmd+Z undoes, Cmd+Y and Shift+Cmd+Z redo in a text field; '
    'Control+Y stays with the field',
    (t) async {
      final controller = await _editor(t);
      await _press(t, [LogicalKeyboardKey.metaLeft], LogicalKeyboardKey.keyZ);
      expect(controller.text, 'a');
      await _press(t, [
        LogicalKeyboardKey.controlLeft,
      ], LogicalKeyboardKey.keyY);
      expect(controller.text, 'a');
      await _press(t, [LogicalKeyboardKey.metaLeft], LogicalKeyboardKey.keyY);
      expect(controller.text, 'ab');
      await _press(t, [LogicalKeyboardKey.metaLeft], LogicalKeyboardKey.keyZ);
      expect(controller.text, 'a');
      await _press(t, [
        LogicalKeyboardKey.metaLeft,
        LogicalKeyboardKey.shiftLeft,
      ], LogicalKeyboardKey.keyZ);
      expect(controller.text, 'ab');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('macOS: the blurred prompt fallback answers Cmd, not Control', (
    t,
  ) async {
    final router = GlobalKey<TextEditingShortcutsState>();
    final owner = GlobalKey();
    final blank = FocusNode();
    addTearDown(blank.dispose);
    var undo = 0;
    var redo = 0;
    await t.pumpWidget(
      MaterialApp(
        builder: (_, child) => TextEditingShortcuts(key: router, child: child!),
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(key: owner),
              Focus(focusNode: blank, child: const Text('blank')),
            ],
          ),
        ),
      ),
    );
    router.currentState!.rememberPrompt(
      owner.currentContext!,
      undo: () => undo++,
      redo: () => redo++,
    );
    blank.requestFocus();
    await t.pump();
    await _press(t, [LogicalKeyboardKey.controlLeft], LogicalKeyboardKey.keyZ);
    await _press(t, [LogicalKeyboardKey.controlLeft], LogicalKeyboardKey.keyY);
    expect((undo, redo), (0, 0));
    await _press(t, [LogicalKeyboardKey.metaLeft], LogicalKeyboardKey.keyZ);
    expect(undo, 1);
    await _press(t, [
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.shiftLeft,
    ], LogicalKeyboardKey.keyZ);
    await _press(t, [LogicalKeyboardKey.metaLeft], LogicalKeyboardKey.keyY);
    expect(redo, 2);
    // ⌃⌘ 加字母是系统的组合键（⌃⌘F 全屏这类），不算撤销
    await _press(t, [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.metaLeft,
    ], LogicalKeyboardKey.keyZ);
    expect((undo, redo), (1, 2));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets(
    'macOS: Cmd+Y outside text passes on when no prompt is remembered '
    '(the gallery keeps its own Cmd+Y)',
    (t) async {
      final elsewhere = FocusNode();
      addTearDown(elsewhere.dispose);
      await _editor(t, elsewhere: elsewhere);
      elsewhere.requestFocus();
      await t.pump();
      await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      expect(await t.sendKeyEvent(LogicalKeyboardKey.keyY), isFalse);
      await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('Windows: Ctrl+Y redoes, Win+Y does not', (t) async {
    final controller = await _editor(t);
    await _press(t, [LogicalKeyboardKey.controlLeft], LogicalKeyboardKey.keyZ);
    expect(controller.text, 'a');
    await _press(t, [LogicalKeyboardKey.metaLeft], LogicalKeyboardKey.keyY);
    expect(controller.text, 'a');
    await _press(t, [LogicalKeyboardKey.controlLeft], LogicalKeyboardKey.keyY);
    expect(controller.text, 'ab');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
