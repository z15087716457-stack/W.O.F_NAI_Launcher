import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_edit.dart';

import 'blocks_test_harness.dart';

void main() {
  const original = ['red_hair', 'blue_eyes', 'white_dress'];
  late List<BlockDraft> saves;
  TestGesture? mouse;

  Future<void> open(
    WidgetTester t, {
    bool empty = false,
    bool negative = false,
  }) async {
    saves = [];
    mouse = null;
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1600, 1000);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      blocksApp(
        Center(
          child: BlockEditDialog(
            data: BlockEditData(
              blockId: 'fixture',
              draft: BlockDraft(
                title: 'Fixture',
                atoms: empty || negative ? [] : original,
                negativeAtoms: empty || !negative ? [] : original,
              ),
            ),
            actions: BlockEditActions(
              onSave: saves.add,
              onCancel: () {},
              onPickThumbnail: () async => null,
              onCaptureParams: () async => null,
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    if (negative) await tapKey(t, 'block-edit-tab-negative');
  }

  Future<void> enter(WidgetTester t, String text) =>
      t.enterText(find.byKey(const Key('block-atom-input')), text);

  Future<void> remove(WidgetTester t, int index) async {
    if (mouse == null) {
      mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse!.addPointer(location: Offset.zero);
      addTearDown(mouse!.removePointer);
    }
    await mouse!.moveTo(t.getCenter(find.byKey(Key('block-atom-$index'))));
    await t.pumpAndSettle();
    await tapKey(t, 'block-atom-remove-$index');
    await mouse!.moveTo(Offset.zero);
    await t.pumpAndSettle();
  }

  group('Atom deletion', () {
    for (final (editing, removed, expected) in [
      (2, [0], ['blue_eyes', 'replacement']),
      (1, [0], ['replacement', 'white_dress']),
      (0, [2], ['replacement', 'blue_eyes']),
      (2, [0, 0], ['replacement']),
    ]) {
      testWidgets('editing $editing survives deleting $removed', (t) async {
        await open(t);
        await tapKey(t, 'block-atom-$editing');
        for (final index in removed) {
          await remove(t, index);
        }
        await enter(t, 'replacement');
        await t.testTextInput.receiveAction(TextInputAction.done);
        await t.pump();
        expect(t.takeException(), isNull);
        await tapKey(t, 'block-edit-save');
        expect(saves.single.atoms, expected);
      });
    }
    testWidgets('negative editing also follows a deletion before it', (
      t,
    ) async {
      await open(t, negative: true);
      await tapKey(t, 'block-atom-2');
      await remove(t, 0);
      await enter(t, 'replacement');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(t.takeException(), isNull);
      await tapKey(t, 'block-edit-save');
      expect(saves.single.negativeAtoms, ['blue_eyes', 'replacement']);
    });
  });

  group('Pending atom save', () {
    for (final negative in [false, true]) {
      for (final editing in [false, true]) {
        for (final keyboard in [false, true]) {
          testWidgets(
            'negative=$negative editing=$editing keyboard=$keyboard',
            (t) async {
              await open(t, negative: negative);
              if (editing) await tapKey(t, 'block-atom-1');
              await enter(t, 'new_tag');
              await t.pump();
              if (keyboard) {
                await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
                try {
                  await t.sendKeyEvent(LogicalKeyboardKey.enter);
                } finally {
                  await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
                }
                await t.pumpAndSettle();
              } else {
                await tapKey(t, 'block-edit-save');
              }
              final expected = editing
                  ? ['red_hair', 'new_tag', 'white_dress']
                  : [...original, 'new_tag'];
              expect(
                negative ? saves.single.negativeAtoms : saves.single.atoms,
                expected,
              );
              expect(t.takeException(), isNull);
            },
          );
        }
      }

      testWidgets(
        'an initially empty ${negative ? 'negative' : 'positive'} draft can be saved directly',
        (t) async {
          await open(t, empty: true, negative: negative);
          await enter(t, 'first_tag');
          await t.pump();
          await tapKey(t, 'block-edit-save');
          expect(negative ? saves.single.negativeAtoms : saves.single.atoms, [
            'first_tag',
          ]);
        },
      );
    }

    testWidgets('switching atom lanes commits each pending edit once', (
      t,
    ) async {
      await open(t);
      await enter(t, 'positive_pending');
      await tapKey(t, 'block-edit-tab-negative');
      await enter(t, 'negative_pending');
      await tapKey(t, 'block-edit-tab-positive');
      await tapKey(t, 'block-edit-save');
      expect(saves.single.atoms, [...original, 'positive_pending']);
      expect(saves.single.negativeAtoms, ['negative_pending']);
    });

    testWidgets('switching to plain text includes a pending replacement', (
      t,
    ) async {
      await open(t);
      await tapKey(t, 'block-atom-1');
      await enter(t, 'replacement');
      await tapKey(t, 'block-edit-tab-text');
      await tapKey(t, 'block-edit-save');
      expect(saves.single.text, 'red_hair, replacement, white_dress');
    });

    testWidgets('an empty edit keeps the original atom on save', (t) async {
      await open(t);
      await tapKey(t, 'block-atom-1');
      await enter(t, '   ');
      await tapKey(t, 'block-edit-save');
      expect(saves.single.atoms, original);
    });

    testWidgets('cancel does not submit pending input', (t) async {
      await open(t);
      await enter(t, 'not_saved');
      await tapKey(t, 'block-edit-cancel');
      expect(saves, isEmpty);
    });
  });
}
