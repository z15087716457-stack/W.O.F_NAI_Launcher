import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_controls.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_glyph.dart';
import 'package:nai_launcher/presentation/ui/online/online_fixture.dart';
import 'package:nai_launcher/presentation/ui/online/online_page.dart';
import 'package:nai_launcher/presentation/ui/online/online_parts.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'online_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  late RecordingOnlineActions rec;
  setUp(() => rec = RecordingOnlineActions());

  Future<void> mount(
    WidgetTester t, {
    String selected = 'c03',
    bool loading = false,
  }) => pumpOnline(
    t,
    data: OnlineFixture.view(
      image: (_) => null,
      selectedKey: selected,
      detailLoading: loading,
    ),
    actions: rec.actions,
    window: 2000,
    height: 1200,
  );
  OnlineController ctrl(WidgetTester t) =>
      t.state(find.byType(OnlineGalleryPage)) as OnlineController;
  String position(WidgetTester t) =>
      t.widget<Text>(find.byKey(const Key('online-viewer-position'))).data!;
  Future<void> download(WidgetTester t) async {
    await t.tap(find.byKey(const Key('online-insp-download')).hitTestable());
    await t.pumpAndSettle();
    await t.tap(find.text('只下载这一张'));
    await t.pumpAndSettle();
  }

  Future<void> right(WidgetTester t, int count) async {
    for (var i = 0; i < count; i++) {
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    }
    await t.pumpAndSettle();
  }

  for (final index in [1, 2, 3]) {
    testWidgets('viewer keyboard media $index downloads that same image', (
      t,
    ) async {
      await mount(t);
      ctrl(t).openViewer('c03');
      await t.pumpAndSettle();
      await right(t, index);
      expect(position(t), startsWith('图 ${index + 1} / 4'));
      await download(t);
      expect(rec.downloads, hasLength(1));
      expect(rec.downloads.single.$1, ['c03']);
      expect(rec.downloads.single.$2, isFalse);
      expect(rec.downloads.single.$3, index);
    });
  }

  testWidgets('the third inspector preview opens the third viewer image', (
    t,
  ) async {
    await mount(t);
    final thumbs = find.descendant(
      of: find.byKey(const Key('online-insp-film')),
      matching: find.byType(UiPressable),
    );
    await t.tap(thumbs.at(2));
    await t.pumpAndSettle();
    final preview = find.byKey(const Key('online-insp-preview'));
    final badge = find.descendant(
      of: preview,
      matching: find.byType(OnlineBadge),
    );
    expect(t.widget<OnlineBadge>(badge).text, '3 / 4');
    final point = t.getTopLeft(preview) + const Offset(140, 100);
    await t.tapAt(point);
    await t.pump(const Duration(milliseconds: 60));
    await t.tapAt(point);
    await t.pumpAndSettle();
    expect(position(t), startsWith('图 3 / 4'));
    await download(t);
    expect(rec.downloads.single.$3, 2);
  });

  testWidgets('viewer film selection is also used by the download action', (
    t,
  ) async {
    await mount(t);
    ctrl(t).openViewer('c03');
    await t.pumpAndSettle();
    final film = find.descendant(
      of: find.byKey(const Key('online-viewer-strip')),
      matching: find.byType(UiPressable),
    );
    await t.tap(film.at(3));
    await t.pumpAndSettle();
    expect(position(t), startsWith('图 4 / 4'));
    await download(t);
    expect(rec.downloads.single.$3, 3);
  });

  testWidgets(
    'closing the viewer keeps the inspector on the image just viewed',
    (t) async {
      await mount(t);
      ctrl(t).openViewer('c03');
      await t.pumpAndSettle();
      await right(t, 2);
      await t.tap(find.byKey(const Key('online-viewer-close')));
      await t.pumpAndSettle();
      final badge = find.descendant(
        of: find.byKey(const Key('online-insp-preview')),
        matching: find.byType(OnlineBadge),
      );
      expect(t.widget<OnlineBadge>(badge).text, '3 / 4');
      await download(t);
      expect(rec.downloads.single.$3, 2);
    },
  );

  testWidgets('changing works resets media and selects the new work once', (
    t,
  ) async {
    await mount(t);
    ctrl(t).openViewer('c03');
    await t.pumpAndSettle();
    await right(t, 2);
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    try {
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    } finally {
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    }
    await t.pumpAndSettle();
    expect(rec.selects, ['t08']);
    await mount(t, selected: 't08');
    await mount(t);
    ctrl(t).openViewer('c03');
    await t.pumpAndSettle();
    expect(position(t), startsWith('图 1 / 4'));
  });

  testWidgets('refreshing the same work detail retains the current media', (
    t,
  ) async {
    await mount(t);
    ctrl(t).openViewer('c03');
    await t.pumpAndSettle();
    await right(t, 2);
    await mount(t, loading: true);
    await mount(t);
    expect(position(t), startsWith('图 3 / 4'));
    await download(t);
    expect(rec.downloads.single.$3, 2);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'viewer arrow buttons update the same media used for downloading',
    (t) async {
      await mount(t);
      ctrl(t).openViewer('c03');
      await t.pumpAndSettle();
      Future<void> arrow(String path) async {
        final glyph = find
            .descendant(
              of: find.byKey(const Key('online-viewer')),
              matching: find.byWidgetPredicate(
                (w) => w is UiGlyph && w.path == path,
              ),
            )
            .first;
        await t.tap(
          find.ancestor(of: glyph, matching: find.byType(UiPressable)).first,
        );
        await t.pumpAndSettle();
      }

      await arrow(UiGlyphs.chevronRight);
      await arrow(UiGlyphs.chevronRight);
      expect(position(t), startsWith('图 3 / 4'));
      await download(t);
      expect(rec.downloads.last.$3, 2);
      await arrow(UiGlyphs.chevronLeft);
      expect(position(t), startsWith('图 2 / 4'));
      await download(t);
      expect(rec.downloads.last.$3, 1);
    },
  );
}
