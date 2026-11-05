import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_instance.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'blocks_test_harness.dart';

final _block = BlockData(
  id: 'qa-layout',
  title: 'QA block',
  color: const Color(0xFF8E24AA),
  atoms: const ['red hair', 'blue eyes'],
  negativeAtoms: const ['lowres'],
  params: const BlockParams(steps: 24),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

BlockInstanceActions _actions(List<String> calls) => BlockInstanceActions(
  onReroll: () {},
  onLockChanged: (_) {},
  onModeChanged: (mode) => calls.add('mode:${mode.name}'),
  onStep: (_) {},
  onSideChanged: (side) => calls.add('side:${side.name}'),
  onEnabledChanged: (enabled) => calls.add('enabled:$enabled'),
  onEditBlock: () => calls.add('edit'),
  onRemove: () => calls.add('remove'),
  onApplyParams: () {},
  onSaveSettings: (_) {},
  sample: (_, _) => const [],
  onShowInLibrary: () {},
  onCopySend: () {},
  onRevertTemp: () async => calls.add('revert'),
  onEditTempContent: (_, _) async {},
  onSaveTempAsNewBlock: (_, _) async {},
  onEvolutionChanged: (_) {},
);

void _insideCard(WidgetTester tester, Iterable<String> keys) {
  final card = tester.getRect(find.byKey(const Key('qa-card-bounds')));
  for (final key in keys) {
    final control = find.byKey(Key(key));
    final rect = tester.getRect(control);
    expect(rect.left, greaterThanOrEqualTo(card.left), reason: key);
    expect(rect.right, lessThanOrEqualTo(card.right), reason: key);
    expect(rect.top, greaterThanOrEqualTo(card.top), reason: key);
    expect(rect.bottom, lessThanOrEqualTo(card.bottom), reason: key);
    expect(control.hitTestable(), findsOneWidget, reason: key);
  }
}

void main() {
  setUpAll(loadStudioCaptureFonts);

  for (final (locale, scale, width) in [
    for (final locale in ['en', 'zh', 'zh_TW', 'ja', 'ko'])
      for (final scale in [1.0, 1.3]) (locale, scale, 348.0),
    ('en', 1.3, 300.0),
    ('zh', 1.3, 300.0),
    ('en', 1.0, 560.0),
    ('zh', 1.0, 560.0),
  ]) {
    for (final kind in ['library', 'genetic', 'temporary']) {
      final temporary = kind == 'temporary';
      testWidgets('paired $kind block actions fit '
          '$locale at width $width and text scale $scale', (tester) async {
        final calls = <String>[];
        await pumpBlocks(
          tester,
          MediaQuery.withClampedTextScaling(
            minScaleFactor: scale,
            maxScaleFactor: scale,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: RepaintBoundary(
                  key: const Key('qa-card-bounds'),
                  child: SizedBox(
                    width: width,
                    child: BlockInstanceCard(
                      data: BlockInstanceViewData(
                        block: _block,
                        settings: const BlockRollSettings(),
                        side: BlockScopeSide.both,
                        temporary: temporary,
                        evolution: kind == 'genetic' ? false : null,
                        originalContent: 'red hair, blue eyes',
                        originalNegativeContent: 'lowres',
                        tempContent: 'silver hair, amber eyes',
                        tempNegativeContent: 'lowres, blurry',
                        editedAt: DateTime(2026, 11, 2),
                        editedBy: 'agent',
                      ),
                      actions: _actions(calls),
                    ),
                  ),
                ),
              ),
            ),
          ),
          locale: locale,
          dark: scale == 1.3,
          window: width + 52,
          height: 1400,
          rail: false,
        );
        expect(tester.takeException(), isNull);
        if (temporary) {
          _insideCard(tester, [
            'block-temp-face-pos',
            'block-temp-face-neg',
            'block-temp-edit',
            'block-temp-compare',
            'block-temp-revert',
            'block-temp-apply',
            'block-temp-save-as',
          ]);
          await tapKey(tester, 'block-temp-compare');
          expect(find.byKey(const Key('block-temp-diff')), findsOneWidget);
          await tapKey(tester, 'block-temp-face-neg');
          expect(
            find.textContaining('blurry', findRichText: true),
            findsWidgets,
          );
          await tapKey(tester, 'block-temp-revert');
          expect(calls, ['revert']);
        } else {
          _insideCard(tester, [
            if (kind == 'genetic') 'block-card-genetic',
            'block-card-mode-fixed',
            'block-card-mode-sequential',
            'block-card-mode-random',
            'block-card-side-positive',
            'block-card-side-negative',
            'block-card-toggle',
            'block-card-edit',
            'block-card-remove',
          ]);
          if (locale == 'zh' && scale == 1.0 && kind == 'library') {
            expect(
              tester.getCenter(find.text('抽取方式')).dy,
              tester.getCenter(find.byKey(const Key('block-card-modes'))).dy,
            );
            expect(
              tester
                  .getTopLeft(find.byKey(const Key('block-card-mode-fixed')))
                  .dy,
              tester
                  .getTopLeft(find.byKey(const Key('block-card-mode-random')))
                  .dy,
            );
            expect(
              tester
                  .getTopLeft(find.byKey(const Key('block-card-side-positive')))
                  .dy,
              tester
                  .getTopLeft(find.byKey(const Key('block-card-side-negative')))
                  .dy,
            );
          }
          await tapKey(tester, 'block-card-mode-sequential');
          await tapKey(tester, 'block-card-side-negative');
          await tapKey(tester, 'block-card-toggle');
          await tapKey(tester, 'block-card-edit');
          await tapKey(tester, 'block-card-remove');
          expect(calls, [
            'mode:sequential',
            'side:positive',
            'enabled:false',
            'edit',
            'remove',
          ]);
        }
        expect(tester.takeException(), isNull);
        final capture = Platform.environment['CAPTURE_BLOCK_LAYOUT'];
        if (capture != null && (locale == 'en' || locale == 'zh')) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('qa-card-bounds')),
            );
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            image.dispose();
            final file = File('$capture/$kind-$locale-$width-$scale.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
          });
        }
      });
    }
  }
}
