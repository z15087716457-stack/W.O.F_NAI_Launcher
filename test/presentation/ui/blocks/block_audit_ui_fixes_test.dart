import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_edit.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_instance.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_parts.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'blocks_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  // F61: a negative-only block is inserted on the UC side and draws its
  // negative atoms; the instance card must show and count those atoms.
  final negativeOnly = BlockData(
    id: 'negative-only',
    title: 'Negative only',
    color: const Color(0xFFDC2626),
    negativeAtoms: const ['lowres', 'blurry', 'bad_hands'],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Future<void> card(WidgetTester t, BlockInstanceViewData d) => pumpBlocks(
    t,
    Center(
      child: BlockInstanceCard(data: d, actions: RecordingBlocks().instance(d)),
    ),
  );

  testWidgets('F61 fixed negative-only instance shows its negative atoms', (
    t,
  ) async {
    await card(
      t,
      BlockInstanceViewData(
        block: negativeOnly,
        settings: const BlockRollSettings(),
        side: BlockScopeSide.negative,
        send: 'lowres, blurry, bad_hands',
      ),
    );
    expect(t.widget<BlockAtoms>(find.byType(BlockAtoms)).atoms, [
      'lowres',
      'blurry',
      'bad_hands',
    ]);
    // Nothing to switch to: there is no positive page.
    expect(find.byKey(const Key('block-card-content-pos')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('F61 sequential negative-only instance uses the negative pool', (
    t,
  ) async {
    await card(
      t,
      BlockInstanceViewData(
        block: negativeOnly,
        settings: const BlockRollSettings(mode: BlockMode.sequential),
        side: BlockScopeSide.negative,
        seqIndex: 1,
      ),
    );
    expect(find.text('blurry'), findsWidgets);
    expect(negativeOnly.primaryAtoms.length, 3);
    expect(t.takeException(), isNull);
  });

  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('F67 tag palette fits ($locale, x$scale)', (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(1600, 1000);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.view.resetPhysicalSize);
        await t.pumpWidget(
          blocksApp(
            MediaQuery.withClampedTextScaling(
              minScaleFactor: scale,
              maxScaleFactor: scale,
              child: Center(
                child: BlockEditDialog(
                  data: const BlockEditData(
                    blockId: 'fixture',
                    draft: BlockDraft(title: 'Fixture', atoms: ['blue_eyes']),
                  ),
                  actions: BlockEditActions(
                    onSave: (_) {},
                    onCancel: () {},
                    onPickThumbnail: () async => null,
                    onCaptureParams: () async => null,
                  ),
                ),
              ),
            ),
            locale: locale,
          ),
        );
        await t.pumpAndSettle();
        await tapKey(t, 'block-edit-add-tag');
        expect(t.takeException(), isNull);
        final picker = t.getRect(find.byKey(const Key('block-tag-picker')));
        for (final e
            in find
                .byWidgetPredicate(
                  (w) =>
                      w.key is ValueKey<String> &&
                      (w.key! as ValueKey<String>).value.startsWith(
                        'block-tag-color-',
                      ),
                )
                .evaluate()) {
          final r = t.getRect(find.byWidget(e.widget));
          expect(r.right, lessThanOrEqualTo(picker.right));
        }
        expect(
          t.getRect(find.byKey(const Key('block-tag-create'))).right,
          lessThanOrEqualTo(picker.right),
        );
      });
    }
  }
}
