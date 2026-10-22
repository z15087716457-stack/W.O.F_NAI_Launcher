import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_page.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../gen/drag_preview_test_support.dart';
import 'explore_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  const key = 'explore-editor-resize';

  Future<(RecordingExploreActions, DragCounts)> pump(
    WidgetTester t, {
    bool dark = false,
    double width = 960,
  }) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = Size(width, 860);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final rec = RecordingExploreActions(), counts = DragCounts();
    await t.pumpWidget(
      exploreApp(
        StyleExplorePage(
          data: ExploreViewData(now: DateTime(2026)),
          actions: rec.actions,
          editor: (_, __) => DragCountProbe(counts, key: const Key('probe')),
        ),
        dark: dark,
      ),
    );
    await t.pumpAndSettle();
    return (rec, counts);
  }

  for (final dark in [false, true]) {
    testWidgets(
      'editor preview freezes layout, capped commit once dark=$dark',
      (t) async {
        final (rec, counts) = await pump(t, dark: dark);
        final old = t.getRect(find.byKey(const Key('explore-editor')));
        final element = find.byKey(const Key('probe')).evaluate().single;
        final before = counts.snapshot;
        final g = await beginDividerDrag(t, key);
        var total = 0.0;
        for (final dx in [40.0, 50.0, 400.0]) {
          total += dx;
          await g.moveBy(Offset(dx, 0));
          await t.pump();
          expect(
            previewPainter(t, key)!.position,
            (384 + total).clamp(352, 480),
          );
          expect(t.getRect(find.byKey(const Key('explore-editor'))), old);
          expect(counts.snapshot, before);
          expect(rec.calls, isEmpty);
        }
        await checkPreviewPaint(t, key);
        final line = previewPainter(t, key)!.position;
        await g.up();
        await t.pumpAndSettle();
        expect(previewPainter(t, key), isNull);
        expect(t.getRect(find.byKey(const Key('explore-editor'))).right, line);
        expect(rec.calls, ['editorWidth:480']);
        expect(counts.layouts, before.$2 + 1);
        expect(find.byKey(const Key('probe')).evaluate().single, same(element));
        expect(t.takeException(), isNull);
      },
    );
  }
  for (final escape in [false, true]) {
    testWidgets('editor ${escape ? 'Esc' : 'pointer cancel'} keeps width', (
      t,
    ) async {
      final (rec, counts) = await pump(t);
      final before = counts.snapshot;
      final g = await beginDividerDrag(t, key);
      await g.moveBy(const Offset(70, 0));
      await t.pump();
      await cancelDividerDrag(t, g, key, escape: escape);
      expect(rec.calls, isEmpty);
      expect(counts.snapshot, before);
      expect(t.getSize(find.byKey(const Key('explore-editor'))).width, 384);
    });
  }
  testWidgets('editor zero net movement does not persist or relayout', (
    t,
  ) async {
    final (rec, counts) = await pump(t);
    final before = counts.snapshot;
    final g = await beginDividerDrag(t, key);
    await g.moveBy(const Offset(60, 0));
    await t.pump();
    await g.moveBy(const Offset(-60, 0));
    await t.pump();
    await g.up();
    await t.pumpAndSettle();
    expect(counts.snapshot, before);
    expect(rec.calls, isEmpty);
    expect(t.getSize(find.byKey(const Key('explore-editor'))).width, 384);
  });
}
