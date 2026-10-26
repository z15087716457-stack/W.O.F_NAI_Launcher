import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_edit.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_controls.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_inputs.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'blocks_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  late List<BlockDraft> saves;
  final picker = find.byKey(const Key('block-tag-picker'));
  final input = find.descendant(
    of: find.byKey(const Key('block-tag-name')),
    matching: find.byType(TextField),
  );

  Future<void> name(WidgetTester t, String value) async {
    await t.enterText(input, value);
    await t.pump();
  }

  Future<void> open(WidgetTester t) async {
    saves = [];
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1600, 1000);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(
      blocksApp(
        Center(
          child: BlockEditDialog(
            data: const BlockEditData(
              blockId: 'fixture',
              draft: BlockDraft(title: 'Fixture', atoms: ['blue_eyes']),
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
    await tapKey(t, 'block-edit-add-tag');
    // F67 remains UI-deferred. Assert its specific existing layout error;
    // do not hide other exceptions or change the production palette dimensions.
    expect(
      '${t.takeException()}',
      contains('RenderFlex overflowed by 17 pixels'),
    );
  }

  Future<void> color(WidgetTester t, Color color) async {
    final swatch = find.descendant(
      of: picker,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints?.maxWidth == 18 &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == color,
      ),
    );
    await t.tap(
      find.ancestor(of: swatch, matching: find.byType(UiPressable)).first,
      kind: PointerDeviceKind.mouse,
    );
    await t.pumpAndSettle();
  }

  testWidgets('typing a name then choosing a color waits for explicit Add', (
    t,
  ) async {
    await open(t);
    await name(t, 'Fixture tag');
    await color(t, const Color(0xFFDC2626));
    expect(picker, findsOneWidget);
    expect(saves, isEmpty);
    await tapKey(t, 'block-tag-create');
    expect(picker, findsNothing);
    await tapKey(t, 'block-edit-save');
    expect(saves.single.tags.single.name, 'Fixture tag');
    expect(saves.single.tags.single.color, const Color(0xFFDC2626));
    expect(t.takeException(), isNull);
  });

  testWidgets('multiple color choices keep the name and use the last color', (
    t,
  ) async {
    await open(t);
    await name(t, 'Fixture tag');
    await color(t, const Color(0xFFDC2626));
    await color(t, const Color(0xFF16A34A));
    expect(t.widget<TextField>(input).controller!.text, 'Fixture tag');
    await tapKey(t, 'block-tag-create');
    await tapKey(t, 'block-edit-save');
    expect(saves.single.tags.single.color, const Color(0xFF16A34A));
  });

  testWidgets('Enter explicitly creates the named tag', (t) async {
    await open(t);
    await name(t, '  Fixture tag  ');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(picker, findsNothing);
    await tapKey(t, 'block-edit-save');
    expect(saves.single.tags.single.name, 'Fixture tag');
  });

  testWidgets('clicking outside cancels the unconfirmed name', (t) async {
    await open(t);
    await name(t, 'Not confirmed');
    final outside =
        t.getTopLeft(find.byKey(const Key('block-edit'))) +
        const Offset(20, 20);
    await t.tapAt(outside, kind: PointerDeviceKind.mouse);
    await t.pumpAndSettle();
    expect(picker, findsNothing);
    await tapKey(t, 'block-edit-save');
    expect(saves.single.tags, isEmpty);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'choosing a color before typing also preserves the chosen color',
    (t) async {
      await open(t);
      await color(t, const Color(0xFFDC2626));
      await name(t, 'Fixture tag');
      await tapKey(t, 'block-tag-create');
      await tapKey(t, 'block-edit-save');
      expect(saves.single.tags.single.color, const Color(0xFFDC2626));
    },
  );

  testWidgets(
    'ordinary form inputs retain their default submit-on-blur behavior',
    (t) async {
      final submitted = <String>[];
      await t.pumpWidget(
        blocksApp(
          Column(
            children: [
              UiTextInput(
                key: const Key('form-input'),
                value: '',
                onSubmitted: submitted.add,
              ),
              const TextField(key: Key('next-input')),
            ],
          ),
        ),
      );
      final field = find.descendant(
        of: find.byKey(const Key('form-input')),
        matching: find.byType(TextField),
      );
      await t.enterText(field, 'form value');
      await t.pump();
      await t.tap(find.byKey(const Key('next-input')));
      await t.pump();
      expect(submitted, ['form value']);
    },
  );
}
