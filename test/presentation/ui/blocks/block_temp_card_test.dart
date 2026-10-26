import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_instance.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_block_pill.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'blocks_test_harness.dart';

final _block = BlockData(
  id: 'dress',
  title: '白裙蓝花',
  color: const Color(0xFF8E24AA),
  atoms: const ['white dress', 'frilled dress', 'sunflower', 'straw hat'],
  folderId: 'f-wardrobe',
  folderName: '衣柜',
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
);

BlockInstanceViewData _data({String? content}) => BlockInstanceViewData(
  block: _block,
  settings: const BlockRollSettings(),
  temporary: true,
  tempContent:
      content ??
      'white dress, frilled dress, sunflower, straw hat, puffy short sleeves, holding flower',
  originalContent:
      'white dress, frilled dress, blue flower, puffy short sleeves, holding flower',
  editedAt: DateTime(2026, 10, 26, 14, 32),
  editedBy: 'agent',
  folders: const [
    BlocksFolder(id: 'f-wardrobe', name: '衣柜', count: 12),
    BlocksFolder(id: 'f-style', name: '画风', count: 4),
  ],
);

Future<void> _capture(WidgetTester t, String name) async {
  final dir = Platform.environment['CAPTURE_TEMP_BLOCK'];
  if (dir == null) return;
  await t.runAsync(() async {
    final boundary = t.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('blocks-capture')),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await Directory(dir).create(recursive: true);
    await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final dark in [false, true]) {
    testWidgets('temporary card edits, compares, reverts and saves as new '
        'dark=$dark', (t) async {
      final calls = <String>[];
      var data = _data();
      debugDisableShadows = false;
      await pumpBlocks(
        t,
        StatefulBuilder(
          builder: (context, update) => Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 24,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    for (final large in [false, true])
                      UiBlockPill(
                        label: '白裙蓝花',
                        color: const Color(0xFF8E24AA),
                        temporary: true,
                        large: large,
                      ),
                    const UiBlockPill(label: '黄昏暖光', color: Color(0xFFFB8C00)),
                  ],
                ),
                BlockInstanceCard(
                  data: data,
                  actions: BlockInstanceActions(
                    onReroll: () {},
                    onLockChanged: (_) {},
                    onModeChanged: (_) {},
                    onStep: (_) {},
                    onSideChanged: (_) {},
                    onEnabledChanged: (_) {},
                    onEditBlock: () {},
                    onRemove: () {},
                    onApplyParams: () {},
                    onSaveSettings: (_) {},
                    sample: (_, _) => const [],
                    onShowInLibrary: () {},
                    onCopySend: () {},
                    onEditTempContent: (content, negative) async {
                      calls.add('edit:$content');
                      update(() => data = _data(content: content));
                    },
                    onRevertTemp: () async => calls.add('revert'),
                    onSaveTempAsNewBlock: (title, folder) async =>
                        calls.add('save:$title:$folder'),
                  ),
                ),
              ],
            ),
          ),
        ),
        window: 900,
        height: 640,
        rail: false,
        dark: dark,
      );
      expect(find.byKey(const Key('block-temp-card')), findsOneWidget);
      expect(find.byKey(const Key('block-pill-temporary')), findsWidgets);
      expect(find.text('Agent 14:32 改过这里。', findRichText: true), findsNothing);
      expect(
        find.textContaining('Agent 14:32 改过这里', findRichText: true),
        findsOneWidget,
      );
      await _capture(t, 'temp-${dark ? 'dark' : 'light'}');

      await t.tap(find.byKey(const Key('block-temp-compare')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('block-temp-diff')), findsOneWidget);
      await _capture(t, 'temp-compare-${dark ? 'dark' : 'light'}');

      await t.tap(find.byKey(const Key('block-temp-edit')));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const Key('block-temp-editor')),
        'white dress, sunflower',
      );
      await t.pump();
      expect(find.text('应用修改'), findsOneWidget);
      await t.tap(find.byKey(const Key('block-temp-apply')));
      await t.pumpAndSettle();
      expect(calls.last, 'edit:white dress, sunflower');
      expect(find.text('继续编辑'), findsOneWidget);

      await t.tap(find.byKey(const Key('block-temp-save-as')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('block-temp-save-row')), findsOneWidget);
      await _capture(t, 'temp-save-${dark ? 'dark' : 'light'}');
      await t.tap(find.byKey(const Key('block-temp-save-folder')));
      await t.pumpAndSettle();
      await t.tap(find.text('画风').last);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('block-temp-save-confirm')));
      await t.pumpAndSettle();
      expect(calls.last, 'save:白裙蓝花:f-style');

      await t.tap(find.byKey(const Key('block-temp-revert')));
      await t.pumpAndSettle();
      expect(calls.last, 'revert');
      expect(t.takeException(), isNull);
      debugDisableShadows = true;
    });
  }
}
