import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_canvas_notice.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_canvas.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('canvas notice avoids real toolbars $locale dark=$dark', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final capture = GlobalKey();
        var views = 0;
        for (final width in [1200.0, 700.0, 450.0, 320.0, 200.0]) {
          tester.view.physicalSize = Size(width, 360);
          final data = GenFixture.view();
          final calls = <String>[];
          await tester.pumpWidget(
            genApp(
              RepaintBoundary(
                key: capture,
                child: GenHost(
                  data: data,
                  actions: GenActions.logging(calls.add),
                  slots: GenSlots(
                    editor: GenFixtureEditor.builder,
                    canvas: (_, _) =>
                        const ColoredBox(color: Color(0xff10131d)),
                    canvasNotice: AgentCanvasNotice(
                      id: '$width',
                      at: DateTime.now(),
                      client: 'Codex',
                      title: '雨夜咖啡馆 · 光影与人物表情分镜',
                      onView: () => views++,
                    ),
                  ),
                  child: const GenCanvas(),
                ),
              ),
              locale: locale,
              dark: dark,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          final notice = tester.getRect(
            find.byKey(const Key('agent-canvas-notice')),
          );
          final info = tester.getRect(find.byKey(const Key('gen-bar-info')));
          final actions = tester.getRect(
            find.byKey(const Key('gen-bar-actions')),
          );
          expect(notice.overlaps(info), isFalse);
          expect(notice.overlaps(actions), isFalse);
          expect(notice.center.dx, closeTo(width / 2, 0.1));
          expect(notice.left, greaterThanOrEqualTo(0));
          expect(notice.right, lessThanOrEqualTo(width));
          if (width == 1200) {
            expect(notice.bottom, closeTo(actions.bottom, 0.1));
          }
          if (width <= 450) {
            expect(notice.bottom, lessThanOrEqualTo(info.top - 7));
          }
          await tester.tap(find.byKey(const Key('agent-canvas-notice-view')));
          expect(views, greaterThan(0));
          await tester.tap(find.byKey(const Key('gen-save')));
          expect(calls.any((c) => c.startsWith('onSaveImage')), isTrue);
          if (width == 1200 || width == 320) {
            await tester.runAsync(() async {
              final image =
                  await (capture.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              final file = File(
                '.dart_tool/external-notice-20261113/captures/$locale-${dark ? 'dark' : 'light'}-${width.toInt()}.png',
              );
              file.parent.createSync(recursive: true);
              file.writeAsBytesSync(bytes!.buffer.asUint8List());
            });
          }
        }
      });
    }
  }
  testWidgets(
    'five-second fade ignores rebuilds and then passes clicks through',
    (tester) async {
      var views = 0, canvas = 0;
      final at = DateTime.now();
      Future<void> pump(String id, DateTime at) => tester.pumpWidget(
        genApp(
          Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => canvas++,
                  child: const SizedBox.expand(),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 300,
                  child: AgentCanvasNotice(
                    id: id,
                    at: at,
                    client: 'Codex',
                    onView: () => views++,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await pump('one', at);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await pump('one', DateTime.now());
      await tester.pump(const Duration(milliseconds: 2300));
      final opacity = find.ancestor(
        of: find.byKey(const Key('agent-canvas-notice')),
        matching: find.byType(AnimatedOpacity),
      );
      expect(tester.widget<AnimatedOpacity>(opacity).opacity, 0);
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('agent-canvas-notice-view'))),
      );
      expect(views, 0);
      expect(canvas, 1);
      await pump('two', DateTime.now());
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.widget<AnimatedOpacity>(opacity).opacity, 1);
      await tester.tap(find.byKey(const Key('agent-canvas-notice-view')));
      expect(views, 1);
    },
  );
  testWidgets('old results stay expired after canvas remount', (tester) async {
    await tester.pumpWidget(
      genApp(
        SizedBox(
          width: 300,
          child: AgentCanvasNotice(
            id: 'old',
            at: DateTime.now().subtract(const Duration(minutes: 1)),
            client: 'Codex',
            onView: () {},
          ),
        ),
      ),
    );
    final opacity = find.ancestor(
      of: find.byKey(const Key('agent-canvas-notice')),
      matching: find.byType(AnimatedOpacity),
    );
    expect(tester.widget<AnimatedOpacity>(opacity).opacity, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'an idle notice slot leaves existing toolbar geometry unchanged',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final capture = GlobalKey();
      for (final width in [1200.0, 450.0, 320.0, 200.0]) {
        tester.view.physicalSize = Size(width, 360);
        final data = GenFixture.view();
        final rects = <Rect>[];
        String? beforePixels;
        for (final enabled in [false, true]) {
          await tester.pumpWidget(
            genApp(
              RepaintBoundary(
                key: capture,
                child: GenHost(
                  data: data,
                  actions: GenActions.logging((_) {}),
                  slots: GenSlots(
                    editor: GenFixtureEditor.builder,
                    canvas: (_, _) => const SizedBox.expand(),
                    canvasNotice: enabled ? const SizedBox.shrink() : null,
                  ),
                  child: const GenCanvas(),
                ),
              ),
            ),
          );
          await tester.pump();
          for (final key in ['gen-bar-info', 'gen-bar-actions']) {
            final rect = tester.getRect(find.byKey(Key(key)));
            if (enabled) {
              expect(rect, rects[key == 'gen-bar-info' ? 0 : 1]);
            } else {
              rects.add(rect);
            }
          }
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final image =
                await (capture.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            image.dispose();
            final digest = sha256
                .convert(bytes!.buffer.asUint8List())
                .toString();
            if (enabled) {
              expect(digest, beforePixels);
            } else {
              beforePixels = digest;
            }
          });
        }
      }
    },
  );
  testWidgets('empty canvas can show results without creating toolbars', (
    tester,
  ) async {
    await tester.pumpWidget(
      genApp(
        GenHost(
          data: GenFixture.empty(),
          actions: GenActions.logging((_) {}),
          slots: GenSlots(
            editor: GenFixtureEditor.builder,
            canvasNotice: AgentCanvasNotice(
              id: 'empty',
              at: DateTime.now(),
              client: 'Codex',
              onView: () {},
            ),
          ),
          child: const GenCanvas(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('agent-canvas-notice')), findsOneWidget);
    expect(find.byKey(const Key('gen-bar-info')), findsNothing);
    expect(find.byKey(const Key('gen-bar-actions')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
