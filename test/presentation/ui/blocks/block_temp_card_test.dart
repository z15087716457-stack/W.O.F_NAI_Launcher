import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/translation_pill_view.dart';
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
  await t.pump();
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
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final (dark, whole) in [
      (false, true),
      (true, true),
      (false, false),
      (true, false),
    ]) {
      testWidgets(
        'nested temporary translations toggle without editing; footer actions $locale dark=$dark whole=$whole',
        (t) async {
          debugDisableShadows = false;
          final calls = <String>[];
          final data = BlockInstanceViewData(
            block: BlockData(
              id: '',
              title: '服装',
              color: const Color(0xFF1E88E5),
              atoms: const [],
              createdAt: DateTime(2026, 10, 28),
              updatedAt: DateTime(2026, 10, 28),
            ),
            settings: const BlockRollSettings(),
            temporary: true,
            standalone: true,
            editedBy: 'agent',
            editedAt: DateTime(2026, 10, 28, 19, 2),
            tempContent: whole
                ? 'She wears a brown hooded cloak with the hood down, fastened by a blue butterfly brooch, a white shirt under a brown vest, a belt with a small pouch, brown shorts, black pantyhose and brown lace-up boots.'
                : 'brown cloak, black boots',
            originalContent: '',
            tempTranslations: whole
                ? const [
                    TranslationPill(
                      source:
                          'She wears a brown hooded cloak with the hood down, fastened by a blue butterfly brooch, a white shirt under a brown vest, a belt with a small pouch, brown shorts, black pantyhose and brown lace-up boots.',
                      zh: '她穿着棕色连帽斗篷，兜帽放下，用蓝色蝴蝶胸针固定；内搭白色衬衫和棕色马甲，腰间系着带小袋的腰带，下穿棕色短裤、黑色连裤袜和棕色系带靴。',
                    ),
                  ]
                : const [
                    TranslationPill(source: 'brown cloak', zh: '棕色斗篷'),
                    TranslationPill(source: 'black boots', zh: '黑色靴子'),
                  ],
          );
          await pumpBlocks(
            t,
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: BlockInstanceCard(
                  data: data,
                  actions: BlockInstanceActions(
                    onReroll: () {},
                    onLockChanged: (_) {},
                    onModeChanged: (_) {},
                    onStep: (_) {},
                    onSideChanged: (_) {},
                    onEnabledChanged: (_) {},
                    onEditBlock: () {},
                    onRemove: () => calls.add('delete'),
                    onApplyParams: () {},
                    onSaveSettings: (_) {},
                    sample: (_, _) => const [],
                    onShowInLibrary: () {},
                    onCopySend: () {},
                    onExpand: () => calls.add('expand'),
                    onExpandTempContent: (content, negative) async =>
                        calls.add('expand:$content'),
                    onEditTempContent: (content, negative) async =>
                        calls.add('edit:$content'),
                    onSaveTempAsNewBlock: (title, folder) async =>
                        calls.add('save'),
                  ),
                ),
              ),
            ),
            window: 600,
            height: 600,
            rail: false,
            locale: locale,
            dark: dark,
          );
          expect(
            find.byType(TranslationPillView),
            findsNWidgets(whole ? 1 : 2),
          );
          expect(find.byKey(const Key('block-temp-editor')), findsNothing);
          await t.tap(find.byKey(const ValueKey('block-temp-translation-0')));
          await t.pump();
          expect(
            t
                .widget<TranslationPillView>(
                  find.byKey(const ValueKey('block-temp-translation-0')),
                )
                .pill
                .showOriginal,
            isTrue,
          );
          final gesture = await t.startGesture(
            t.getCenter(find.byKey(const ValueKey('block-temp-translation-0'))),
            kind: PointerDeviceKind.mouse,
            buttons: kMiddleMouseButton,
          );
          await gesture.up();
          await t.pump();
          expect(
            t
                .widget<TranslationPillView>(
                  find.byKey(const ValueKey('block-temp-translation-0')),
                )
                .pill
                .showOriginal,
            isFalse,
          );
          expect(calls, isEmpty);
          if (locale == 'zh') {
            await _capture(
              t,
              'temp-nested-${whole ? 'single' : 'multiple'}-${dark ? 'dark' : 'light'}',
            );
          }
          await t.tap(find.byKey(const Key('block-temp-expand')));
          await t.pump();
          await t.tap(find.byKey(const Key('block-temp-delete')));
          await t.pump();
          expect(calls, ['expand', 'delete']);
          await t.tap(find.byKey(const Key('block-temp-apply')));
          await t.pump();
          await t.enterText(
            find.byKey(const Key('block-temp-editor')),
            'brown cloak, red boots',
          );
          await t.pump();
          await t.tap(find.byKey(const Key('block-temp-expand')));
          await t.pump();
          expect(calls.last, 'expand:brown cloak, red boots');
          expect(t.takeException(), isNull);
          debugDisableShadows = true;
        },
      );
    }
  }
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
  testWidgets('standalone temporary card hides revert, compare and diff', (
    t,
  ) async {
    final calls = <String>[];
    final data = BlockInstanceViewData(
      block: BlockData(
        id: '',
        title: '服装',
        color: const Color(0xFF1E88E5),
        atoms: const ['white dress', 'straw hat'],
        createdAt: DateTime(2026, 10, 28),
        updatedAt: DateTime(2026, 10, 28),
      ),
      settings: const BlockRollSettings(),
      temporary: true,
      standalone: true,
      tempContent: 'white dress, straw hat',
      originalContent: '',
      editedAt: DateTime(2026, 10, 28, 9, 5),
      editedBy: 'agent',
    );
    await pumpBlocks(
      t,
      Padding(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topLeft,
          child: BlockInstanceCard(
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
              onEditTempContent: (content, negative) async =>
                  calls.add('edit:$content'),
              onSaveTempAsNewBlock: (title, folder) async =>
                  calls.add('save:$title:$folder'),
            ),
          ),
        ),
      ),
      window: 600,
      height: 520,
      rail: false,
    );
    expect(find.byKey(const Key('block-temp-card')), findsOneWidget);
    await _capture(t, 'temp-standalone');
    expect(find.text('服装'), findsWidgets);
    expect(find.textContaining('块已删除', findRichText: true), findsNothing);
    expect(
      find.textContaining('Agent 09:05 建了这个块', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('只存在于当前提示词中', findRichText: true),
      findsOneWidget,
    );
    expect(find.byKey(const Key('block-temp-revert')), findsNothing);
    expect(find.byKey(const Key('block-temp-compare')), findsNothing);
    expect(find.byKey(const Key('block-temp-diff')), findsNothing);
    expect(find.text('新增'), findsNothing);

    await t.tap(find.byKey(const Key('block-temp-more')));
    await t.pumpAndSettle();
    expect(find.text('在块库中查看原块'), findsNothing);
    await t.tapAt(const Offset(590, 510));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('block-temp-save-as')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('block-temp-save-confirm')));
    await t.pumpAndSettle();
    expect(calls.last, 'save:服装:null');
    expect(t.takeException(), isNull);
  });
}
