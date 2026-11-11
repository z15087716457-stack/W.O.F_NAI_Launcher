import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'nav_test_harness.dart';

Finder key(String value) => find.byKey(Key(value));

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets('no update leaves the existing bottom controls in place', (
    tester,
  ) async {
    await pumpNav(tester, data: NavFixture.view(), size: const Size(640, 760));
    expect(key('main-nav-update'), findsNothing);
    expect(tester.getRect(key('main-nav-settings')).bottom, 752);
    expect(tester.getRect(key('main-nav-toggle')).bottom, 712);
  });

  testWidgets(
    'rail update opens details only, stays above fold, and is keyboard accessible',
    (tester) async {
      final actions = RecordingNavActions();
      await pumpNav(
        tester,
        data: NavFixture.view(
          update: const NavUpdateData(
            status: NavUpdateStatus.available,
            version: '2.3.3',
          ),
        ),
        actions: actions.actions,
        size: const Size(640, 760),
      );
      final update = key('main-nav-update');
      final r = tester.getRect(update);
      expect(r.size, const Size(47, 40));
      expect(tester.getRect(key('main-nav-toggle')).top - r.bottom, 6);
      expect(tester.getSize(key('main-nav-update-glyph')), const Size(26, 26));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.descendant(
                of: update,
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .opacity,
        0,
      );
      await hoverOver(tester, update);
      expect(find.text('发现新版本 · 2.3.3'), findsOneWidget);
      await tester.tap(update);
      await tester.pump();
      expect(actions.updates, 1);
      expect(actions.pages, isEmpty);
      final gesture = find.descendant(
        of: update,
        matching: find.byType(GestureDetector),
      );
      Focus.of(tester.element(gesture)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(actions.updates, 2);
    },
  );

  testWidgets(
    'opening update details closes transient navigation and preserves pinned navigation',
    (tester) async {
      final actions = RecordingNavActions();
      const update = NavUpdateData(
        status: NavUpdateStatus.downloaded,
        version: '2.3.3',
      );
      await pumpNav(
        tester,
        data: NavFixture.view(update: update),
        actions: actions.actions,
      );
      await tester.tap(key('main-nav-toggle'));
      await tester.pumpAndSettle();
      await tester.tap(key('main-nav-panel-update'));
      await tester.pumpAndSettle();
      expect(key('main-nav-panel-update'), findsNothing);
      expect(actions.updates, 1);
      await pumpNav(
        tester,
        data: NavFixture.view(update: update, pinned: true),
        actions: actions.actions,
      );
      await tester.tap(key('main-nav-panel-update'));
      await tester.pumpAndSettle();
      expect(key('main-nav-panel-update'), findsOneWidget);
      expect(actions.updates, 2);
      expect(actions.pinned, isEmpty);
    },
  );

  testWidgets('download progress changes without moving the entry or page', (
    tester,
  ) async {
    NavViewData data(double progress) => NavFixture.view(
      update: NavUpdateData(
        status: NavUpdateStatus.downloading,
        version: '2.3.3',
        progress: progress,
      ),
    );
    await pumpNav(tester, data: data(.12));
    final before = tester.getRect(key('main-nav-update'));
    final content = tester.getRect(key('nav-content'));
    await tester.pumpWidget(navApp(data(.87), null));
    await tester.pumpAndSettle();
    expect(tester.getRect(key('main-nav-update')), before);
    expect(tester.getRect(key('nav-content')), content);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      .87,
    );
    expect(tester.takeException(), isNull);
  });

  final capture = Platform.environment['NAV_UPDATE_CAPTURES'];
  final rects = <String, Object>{};
  for (final dark in [false, true]) {
    for (final locale in ['zh', 'zh-TW', 'en', 'ja', 'ko']) {
      testWidgets(
        'all update states fit both navigation modes: $locale dark=$dark',
        (tester) async {
          for (final status in NavUpdateStatus.values) {
            for (final pinned in [false, true]) {
              final update = NavUpdateData(
                status: status,
                version: '2.3.3',
                progress: .46,
              );
              await pumpNav(
                tester,
                data: NavFixture.view(update: update, pinned: pinned),
                size: const Size(640, 760),
                dark: dark,
                locale: locale,
              );
              final entry = key(
                pinned ? 'main-nav-panel-update' : 'main-nav-update',
              );
              expect(entry.hitTestable(), findsOneWidget);
              expect(
                tester.takeException(),
                isNull,
                reason: '$status pinned=$pinned',
              );
              if (capture != null && locale == 'zh') {
                final name =
                    '${status.name}-${pinned ? 'panel' : 'rail'}-${dark ? 'dark' : 'light'}';
                final r = tester.getRect(entry);
                final glyph = tester.getRect(key('main-nav-update-glyph'));
                rects[name] = {
                  'button': [r.left, r.top, r.width, r.height],
                  'glyph': [glyph.left, glyph.top, glyph.width, glyph.height],
                };
                await tester.runAsync(() async {
                  final image = await tester
                      .renderObject<RenderRepaintBoundary>(key('nav-capture'))
                      .toImage();
                  final bytes = (await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  ))!;
                  final file = File('$capture/$name.png');
                  await file.parent.create(recursive: true);
                  await file.writeAsBytes(bytes.buffer.asUint8List());
                  image.dispose();
                });
              }
            }
          }
        },
      );
    }
  }
  testWidgets(
    'short window scrolls pages, keeps bottom controls, and handles manual replacement',
    (tester) async {
      await pumpNav(
        tester,
        data: NavFixture.view(
          pinned: true,
          update: const NavUpdateData(
            status: NavUpdateStatus.downloaded,
            version: '2.3.3',
            manualReplace: true,
          ),
        ),
        size: const Size(320, 360),
      );
      expect(find.text('在访达中显示'), findsOneWidget);
      expect(key('main-nav-panel-update').hitTestable(), findsOneWidget);
      expect(key('main-nav-panel-collapse').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  tearDownAll(() async {
    if (capture != null) {
      await File(
        '$capture/rects.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(rects));
    }
  });
}
