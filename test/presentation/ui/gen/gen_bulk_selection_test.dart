import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_glyph.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final (locale, dark, width) in [
    ('zh', true, 1600.0),
    ('en', false, 1200.0),
    ('ja', false, 1600.0),
  ]) {
    testWidgets('$locale simple viewer and history share partial selection', (
      tester,
    ) async {
      final base = GenFixture.view();
      final batch = base.history.batches[1];
      final data = base.copyWith(
        canvas: GenCanvasData(
          focus: GenGroup(
            id: batch.id,
            tiles: [
              for (final image in batch.images)
                GenTile(
                  id: image.id,
                  width: image.width,
                  height: image.height,
                  image: image.thumb,
                ),
            ],
          ),
          info: const GenFocusInfo(tileId: 'i2', width: 832, height: 1216),
        ),
      );
      final recorder = GenRecorder();
      await pumpGen(
        tester,
        data: data,
        actions: recorder.actions,
        locale: locale,
        dark: dark,
        window: width,
      );
      Finder border(Finder target) => find.descendant(
        of: target,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container && widget.foregroundDecoration != null,
        ),
      );
      final first = find.byKey(const Key('gen-tile-i2'));
      final second = find.byKey(const Key('gen-tile-i3'));
      final history = find.byKey(const Key('gen-batch-tile-b2'));
      final focusedHistory = find.byKey(const Key('gen-batch-tile-b1'));
      expect(border(focusedHistory), findsOneWidget);
      expect(border(first), findsNothing);
      expect(border(second), findsNothing);
      expect(border(history), findsNothing);
      await captureUiuxRegion(
        tester,
        find.byKey(const Key('gen-capture')),
        '$locale-normal',
        tester.getRect(find.byKey(const Key('gen-capture'))),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tapKey(tester, 'gen-tile-i2');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(border(first), findsOneWidget);
      expect(border(second), findsNothing);
      expect(border(history), findsOneWidget);
      expect(border(focusedHistory), findsNothing);
      expect(
        find.descendant(
          of: history,
          matching: find.byWidgetPredicate(
            (widget) => widget is UiGlyph && widget.path == UiGlyphs.minus,
          ),
        ),
        findsOneWidget,
      );
      expect(recorder.called('onFocusTile'), isFalse);
      expect(recorder.called('onOpenViewer'), isFalse);
      await tapKey(tester, 'gen-history-save-selected');
      expect(recorder.last('onSaveImages'), 'onSaveImages([i2])');
      await captureUiuxRegion(
        tester,
        find.byKey(const Key('gen-capture')),
        '$locale-partial',
        tester.getRect(find.byKey(const Key('gen-capture'))),
      );
      await tapKey(tester, 'gen-batch-tile-b2');
      expect(border(first), findsOneWidget);
      expect(border(second), findsOneWidget);
      await tapKey(tester, 'gen-history-save-selected');
      expect(recorder.last('onSaveImages'), 'onSaveImages([i2, i3])');
      await tapKey(tester, 'gen-history-select');
      expect(border(first), findsNothing);
      expect(border(second), findsNothing);
      expect(border(history), findsNothing);
      expect(border(focusedHistory), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets('$locale pending history keeps the browsing focus frame', (
      tester,
    ) async {
      final base = GenFixture.view();
      final pending = GenBatch(
        id: 'pending',
        time: base.now!,
        images: const [],
        pending: 2,
        pendingWidth: 832,
        pendingHeight: 1216,
      );
      await pumpGen(
        tester,
        data: base.copyWith(
          history: GenHistoryData(
            selected: pending.id,
            batches: [pending, ...base.history.batches],
          ),
        ),
        locale: locale,
        dark: dark,
        window: width,
      );
      final focus = tester.widget<Container>(
        find.byKey(const Key('gen-batch-focused')),
      );
      final decoration = focus.foregroundDecoration! as BoxDecoration;
      expect(decoration.border!.top.width, 2);
      expect(
        find.descendant(
          of: find.byKey(const Key('gen-batch-tile-b1')),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.foregroundDecoration != null,
          ),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
