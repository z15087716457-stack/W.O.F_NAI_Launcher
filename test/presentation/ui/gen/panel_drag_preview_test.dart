import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'drag_preview_test_support.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final key in ['gen-left-resize', 'gen-history-resize']) {
    final isLeft = key == 'gen-left-resize';
    final panel = isLeft ? 'gen-left' : 'gen-history';
    for (final dark in [false, true]) {
      testWidgets('$key freezes content, commits once, paint dark=$dark', (
        t,
      ) async {
        final rec = GenRecorder();
        final editor = DragCounts(), canvas = DragCounts();
        var rowBuilds = 0;
        await pumpGen(
          t,
          data: GenFixture.view(),
          actions: rec.actions,
          dark: dark,
          slots: GenSlots(
            editor: (_, __) => DragCountProbe(
              editor,
              key: const Key('count-editor'),
              child: const SizedBox(height: 50),
            ),
            canvas: (_, __) =>
                DragCountProbe(canvas, key: const Key('count-canvas')),
            panelBackdrop: (_, __) {
              rowBuilds++;
              return const SizedBox.expand();
            },
          ),
        );
        final old = t.getRect(find.byKey(Key(panel)));
        final oldCanvas = t.getSize(find.byKey(const Key('count-canvas')));
        final element = find.byKey(const Key('count-editor')).evaluate().first;
        final before = (editor.snapshot, canvas.snapshot, rowBuilds);
        final g = await beginDividerDrag(t, key);
        var distance = 0.0;
        for (final dx in [40.0, 50.0, 600.0]) {
          distance += dx;
          await g.moveBy(Offset(isLeft ? dx : -dx, 0));
          await t.pump();
          final position = previewPainter(t, key)!.position;
          expect(
            position,
            isLeft
                ? (old.width + distance).clamp(352, 560)
                : 1552 - (old.width + distance).clamp(200, 400),
          );
          expect(t.getRect(find.byKey(Key(panel))), old);
          expect(t.getSize(find.byKey(const Key('count-canvas'))), oldCanvas);
          expect((editor.snapshot, canvas.snapshot, rowBuilds), before);
          expect(rec.calls, isEmpty);
        }
        final position = previewPainter(t, key)!.position;
        await checkPreviewPaint(t, key);
        await g.up();
        await t.pumpAndSettle();
        expect(previewPainter(t, key), isNull);
        expect(t.getCenter(find.byKey(Key(key))).dx, position);
        expect(
          rec.calls.where((c) => c.startsWith('onLayoutChanged')),
          hasLength(1),
        );
        expect(
          rec.last('onLayoutChanged'),
          contains(isLeft ? 'leftWidth: 560.0' : 'historyWidth: 400.0'),
        );
        expect(canvas.layouts, before.$2.$2 + 1);
        expect(rowBuilds, before.$3 + 1);
        expect(
          find.byKey(const Key('count-editor')).evaluate().first,
          same(element),
        );
        expect(t.takeException(), isNull);
      });
    }

    for (final escape in [false, true]) {
      testWidgets(
        '$key ${escape ? 'Esc' : 'pointer cancel'} discards preview',
        (t) async {
          final rec = GenRecorder();
          await pumpGen(t, data: GenFixture.view(), actions: rec.actions);
          final old = t.getRect(find.byKey(Key(panel)));
          final g = await beginDividerDrag(t, key);
          await g.moveBy(const Offset(-65, 0));
          await t.pump();
          await cancelDividerDrag(t, g, key, escape: escape);
          expect(t.getRect(find.byKey(Key(panel))), old);
          expect(rec.calls, isEmpty);
        },
      );
    }

    testWidgets('$key zero net movement does not relayout or persist', (
      t,
    ) async {
      final rec = GenRecorder();
      var rowBuilds = 0;
      await pumpGen(
        t,
        data: GenFixture.view(),
        actions: rec.actions,
        slots: GenSlots(
          editor: (_, __) => const SizedBox(height: 50),
          panelBackdrop: (_, __) {
            rowBuilds++;
            return const SizedBox.expand();
          },
        ),
      );
      final old = t.getRect(find.byKey(Key(panel)));
      final builds = rowBuilds;
      final g = await beginDividerDrag(t, key);
      await g.moveBy(const Offset(-45, 0));
      await t.pump();
      await g.moveBy(const Offset(45, 0));
      await t.pump();
      await g.up();
      await t.pumpAndSettle();
      expect(rowBuilds, builds);
      expect(t.getRect(find.byKey(Key(panel))), old);
      expect(rec.calls, isEmpty);
    });
  }

  for (final keepHistory in [false, true]) {
    testWidgets(
      'left preview accounts for compressed width keepHistory=$keepHistory',
      (t) async {
        final rec = GenRecorder();
        await pumpGen(
          t,
          window: keepHistory ? 848 : 988,
          data: GenFixture.view(layout: const GenLayout(leftWidth: 352)),
          actions: rec.actions,
          slots: GenSlots(
            preserveHistory: keepHistory,
            editor: (_, __) => const SizedBox(height: 50),
          ),
        );
        const key = 'gen-left-resize';
        final old = t.getRect(find.byKey(const Key('gen-left')));
        final g = await beginDividerDrag(t, key);
        await g.moveBy(const Offset(300, 0));
        await t.pump();
        final line = previewPainter(t, key)!.position;
        expect(line, keepHistory ? 430 : 540);
        expect(t.getRect(find.byKey(const Key('gen-left'))), old);
        await g.up();
        await t.pumpAndSettle();
        expect(t.getRect(find.byKey(const Key('gen-left'))).right, line);
        expect(rec.last('onLayoutChanged'), contains('leftWidth: 560.0'));
      },
    );

    testWidgets(
      'preview includes responsive compaction keepHistory=$keepHistory',
      (t) async {
        final rec = GenRecorder();
        await pumpGen(
          t,
          window: keepHistory ? 612 : 1100,
          data: GenFixture.view(layout: const GenLayout(leftWidth: 352)),
          actions: rec.actions,
          slots: GenSlots(
            preserveHistory: keepHistory,
            editor: (_, __) => const SizedBox(height: 50),
          ),
        );
        const key = 'gen-history-resize';
        final g = await beginDividerDrag(t, key);
        await g.moveBy(const Offset(-190, 0));
        await t.pump();
        final line = previewPainter(t, key)!.position;
        await g.up();
        await t.pumpAndSettle();
        final actual = find.byKey(
          Key(keepHistory ? 'gen-history' : 'gen-history-strip'),
        );
        expect(t.getRect(actual).left, line);
        expect(
          rec.calls.where((c) => c.startsWith('onLayoutChanged')),
          hasLength(1),
        );
      },
    );
  }
}
