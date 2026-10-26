import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_params.dart';

import 'gen_test_harness.dart';

void main() {
  late List<String> calls;
  Future<void> mount(
    WidgetTester t, {
    bool pinned = false,
    int? seed = 123456,
  }) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1000, 900);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(
      genApp(
        Center(
          child: SizedBox(
            width: 450,
            height: 700,
            child: GenHost(
              data: GenViewData(
                model: 'nai-diffusion-4-5-full',
                models: const [],
                params: GenParamsData(seed: seed, seedPinned: pinned),
              ),
              actions: GenActions.logging(calls.add),
              slots: const GenSlots(editor: _editor),
              child: const Column(
                children: [
                  Expanded(child: GenParamDrawerHost(child: SizedBox.expand())),
                  GenParamStrip(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  final field = find.byKey(const Key('gen-drawer-seed'));
  Future<void> open(
    WidgetTester t, {
    bool pinned = false,
    int? seed = 123456,
  }) async {
    calls = [];
    await mount(t, pinned: pinned, seed: seed);
    await tapKey(t, 'gen-params-toggle');
    await t.tap(field, kind: PointerDeviceKind.mouse);
    await t.pump();
    expect(t.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    expect(calls, isEmpty);
  }

  Future<void> close(WidgetTester t) async {
    await t.tap(
      find.byKey(const Key('gen-params-close')),
      kind: PointerDeviceKind.mouse,
    );
    await t.pumpAndSettle();
  }

  for (final pinned in [false, true]) {
    testWidgets('viewing an unchanged seed preserves pinned=$pinned', (
      t,
    ) async {
      await open(t, pinned: pinned);
      await close(t);
      expect(calls, isEmpty);
    });
  }

  testWidgets('seed text supports Ctrl+Z, Ctrl+Y and Ctrl+Shift+Z', (t) async {
    await open(t);
    Future<void> type(String text) async {
      t.testTextInput.updateEditingValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
      await t.pump(const Duration(milliseconds: 550));
    }

    Future<void> key(LogicalKeyboardKey key, {bool shift = false}) async {
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyEvent(key);
      if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pump();
    }

    await type('321');
    await type('321456');
    final controller = t.widget<TextField>(field).controller!;
    await key(LogicalKeyboardKey.keyZ);
    expect(controller.text, '321');
    await key(LogicalKeyboardKey.keyY);
    expect(controller.text, '321456');
    await key(LogicalKeyboardKey.keyZ);
    await key(LogicalKeyboardKey.keyZ, shift: true);
    expect(controller.text, '321456');
    await close(t);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('submitting an unchanged displayed random seed does not pin it', (
    t,
  ) async {
    await open(t);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(calls, isEmpty);
  });

  for (final submit in [false, true]) {
    testWidgets('an edited seed commits once with submit=$submit', (t) async {
      await open(t);
      await t.enterText(field, '654321');
      if (submit) {
        await t.testTextInput.receiveAction(TextInputAction.done);
        await t.pumpAndSettle();
      }
      await close(t);
      expect(calls, ['onSeedChanged(654321)']);
    });
  }

  testWidgets('changing then restoring the displayed value does not pin it', (
    t,
  ) async {
    await open(t);
    await t.enterText(field, '654321');
    await t.enterText(field, '123456');
    await close(t);
    expect(calls, isEmpty);
  });

  testWidgets(
    'an external update during inspection is not overwritten on blur',
    (t) async {
      await open(t);
      await mount(t, seed: 777);
      expect(t.widget<TextField>(field).controller!.text, '123456');
      await close(t);
      expect(calls, isEmpty);
    },
  );

  testWidgets('randomize after inspection only unpins the seed', (t) async {
    await open(t);
    await t.tap(
      find.byKey(const Key('gen-seed-random')),
      kind: PointerDeviceKind.mouse,
    );
    await t.pumpAndSettle();
    expect(calls, ['onSeedPinned(false)']);
  });

  testWidgets('clearing the value does not submit an invalid seed', (t) async {
    await open(t);
    await t.enterText(field, '');
    await close(t);
    expect(calls, isEmpty);
  });
}

Widget _editor(BuildContext context, GenEditorTarget target) =>
    const SizedBox.shrink();
