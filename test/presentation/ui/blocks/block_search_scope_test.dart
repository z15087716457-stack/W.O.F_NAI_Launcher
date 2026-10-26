import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_page.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_inputs.dart';

import 'blocks_test_harness.dart';

void main() {
  final now = DateTime(2026, 10, 26);
  late RecordingBlocks rec;
  setUp(() => rec = RecordingBlocks());
  final blockSearch = find.descendant(
    of: find.byKey(const Key('blocks-search')),
    matching: find.byType(TextField),
  );
  Future<void> page(WidgetTester t, String query, BlocksScope scope) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1600, 1000);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(
      blocksApp(
        BlocksLibraryPage(
          data: BlocksLibraryViewData(
            now: now,
            query: query,
            scope: scope,
            counts: const BlocksCounts(all: 1, favorites: 1),
            blocks: [
              BlockData(
                id: 'b',
                title: 'Fixture',
                color: Colors.blue,
                atoms: const ['blue_eyes'],
                favorite: true,
                createdAt: now,
                updatedAt: now,
              ),
            ],
          ),
          actions: rec.library,
        ),
      ),
    );
    await t.pump();
  }

  for (final initial in ['', 'old']) {
    testWidgets(
      'changing scope cancels pending search from initial "$initial"',
      (t) async {
        await page(t, initial, const BlocksScope.all());
        await t.enterText(blockSearch, 'pending');
        await t.pump(const Duration(milliseconds: 50));
        await page(t, '', const BlocksScope.favorites());
        expect(t.widget<TextField>(blockSearch).controller!.text, '');
        expect(t.widget<TextField>(blockSearch).focusNode!.hasFocus, isTrue);
        await t.pump(const Duration(milliseconds: 400));
        expect(rec.calls, isEmpty);
      },
    );
  }

  testWidgets('changing between folders also cancels the old search', (
    t,
  ) async {
    await page(t, '', const BlocksScope.folder('one'));
    await t.enterText(blockSearch, 'pending');
    await t.pump(const Duration(milliseconds: 50));
    await page(t, '', const BlocksScope.folder('two'));
    await t.pump(const Duration(milliseconds: 400));
    expect(t.widget<TextField>(blockSearch).controller!.text, '');
    expect(rec.calls, isEmpty);
  });

  testWidgets(
    'rebuilding an equivalent scope preserves pending text and caret',
    (t) async {
      await page(t, 'old', const BlocksScope.all());
      await t.enterText(blockSearch, 'pending');
      final controller = t.widget<TextField>(blockSearch).controller!;
      controller.selection = const TextSelection.collapsed(offset: 3);
      await t.pump(const Duration(milliseconds: 50));
      await page(t, 'old', const BlocksScope.all());
      expect(t.widget<TextField>(blockSearch).controller, same(controller));
      expect(controller.selection.baseOffset, 3);
      expect(controller.text, 'pending');
      await t.pump(const Duration(milliseconds: 300));
      expect(rec.calls, ['query:pending']);
    },
  );

  final field = find.byType(TextField);
  final changes = <String>[];
  Future<void> search(WidgetTester t, String value) async {
    await t.pumpWidget(
      blocksApp(
        Center(
          child: SizedBox(
            width: 450,
            child: UiSearchField(
              value: value,
              hint: 'Search',
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    await t.pump();
  }

  setUp(changes.clear);

  testWidgets(
    'an external search value replaces pending text and cancels its timer',
    (t) async {
      await search(t, 'old');
      await t.enterText(field, 'pending');
      await t.pump(const Duration(milliseconds: 50));
      await search(t, 'replacement');
      expect(t.widget<TextField>(field).controller!.text, 'replacement');
      await t.pump(const Duration(milliseconds: 400));
      expect(changes, isEmpty);
    },
  );

  testWidgets(
    'acknowledging the last submission preserves a newer pending draft',
    (t) async {
      await search(t, '');
      await t.enterText(field, 'first');
      await t.pump(const Duration(milliseconds: 300));
      expect(changes, ['first']);
      await t.enterText(field, 'second');
      await search(t, 'first');
      expect(t.widget<TextField>(field).controller!.text, 'second');
      await t.pump(const Duration(milliseconds: 300));
      expect(changes, ['first', 'second']);
    },
  );

  testWidgets('Enter submits once and cancels the pending timer', (t) async {
    await search(t, '');
    await t.enterText(field, '  query  ');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump(const Duration(milliseconds: 400));
    expect(changes, ['query']);
  });

  testWidgets('Escape clears once without a later pending search', (t) async {
    await search(t, '');
    await t.enterText(field, 'pending');
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pump(const Duration(milliseconds: 400));
    expect(changes, ['']);
    expect(t.widget<TextField>(field).controller!.text, '');
  });

  testWidgets('disposing the search cancels its pending submission', (t) async {
    await search(t, '');
    await t.enterText(field, 'pending');
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(milliseconds: 400));
    expect(changes, isEmpty);
  });
}
