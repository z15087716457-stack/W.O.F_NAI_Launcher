import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture_editor.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      for (final width in [340.0, 400.0, 480.0]) {
        testWidgets(
          'five pinned tools preserve tabs and scroll internally: $locale $width dark=$dark',
          (t) async {
            final record = GenRecorder();
            await pumpGen(
              t,
              dark: dark,
              locale: locale,
              height: 720,
              data: GenFixture.view(layout: GenLayout(leftWidth: width))
                  .copyWith(
                    prompt: const GenPromptData(
                      tools: GenPromptTools(
                        palettePinned: true,
                        dockPinned: true,
                        translatePinned: true,
                        resourceWindowsPinned: true,
                        agentPinned: true,
                      ),
                      bridge: GenBridge(
                        phase: GenBridgePhase.idle,
                        label: 'connected',
                      ),
                    ),
                  ),
              actions: record.actions,
              slots: GenSlots(
                editor: GenFixtureEditor.builder,
                agentToggle: GestureDetector(
                  onTap: () => record.calls.add('agent'),
                  child: const SizedBox(
                    key: Key('overflow-agent'),
                    width: 28,
                    height: 28,
                    child: ColoredBox(color: Color(0xff1754db)),
                  ),
                ),
              ),
            );
            final paragraph = t.renderObject<RenderParagraph>(
              find.descendant(
                of: find.byKey(const Key('gen-tab-positive')),
                matching: find.byType(RichText),
              ),
            );
            expect(paragraph.didExceedMaxLines, false);
            final strip = find.byKey(const Key('gen-prompt-tools-strip'));
            final rect = t.getRect(strip);
            final scrollable = find.descendant(
              of: strip,
              matching: find.byType(Scrollable),
            );
            final position = t.state<ScrollableState>(scrollable).position;
            final parentPosition = Scrollable.maybeOf(
              t.element(strip),
            )!.position;
            final parentOffset = parentPosition.pixels;
            expect(position.maxScrollExtent, greaterThan(0));
            expect(rect.width, lessThanOrEqualTo(152));
            if (width >= 480) expect(rect.width, closeTo(152, .1));
            if (rect.width >= 151.9) {
              final agent = t.getRect(find.byKey(const Key('overflow-agent')));
              expect(agent.intersect(rect).width, closeTo(agent.width / 2, .1));
              final boundary = t.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('gen-capture')),
              );
              late ui.Image bitmap;
              late List<int> pixels;
              await t.runAsync(() async {
                bitmap = await boundary.toImage(pixelRatio: 1);
                pixels = (await bitmap.toByteData(
                  format: ui.ImageByteFormat.rawRgba,
                ))!.buffer.asUint8List();
              });
              List<int> rgb(double x, double y) {
                final i = (y.floor() * bitmap.width + x.floor()) * 4;
                return pixels.sublist(i, i + 3);
              }

              final solid = rgb(agent.left + 1, agent.center.dy);
              final fade = rgb(rect.right - 2, agent.center.dy);
              final background = rgb(rect.right + 3, agent.center.dy);
              int distance(List<int> a, List<int> b) => List.generate(
                3,
                (i) => (a[i] - b[i]).abs(),
              ).reduce((a, b) => a + b);
              expect(
                distance(fade, background),
                lessThan(distance(solid, background)),
              );
              bitmap.dispose();
            }
            await t.sendEventToBinding(
              PointerScrollEvent(
                position: rect.center,
                scrollDelta: const Offset(0, 100),
              ),
            );
            await t.pumpAndSettle();
            expect(position.pixels, position.maxScrollExtent);
            expect(parentPosition.pixels, parentOffset);
            final before = position.pixels;
            await t.sendEventToBinding(
              PointerScrollEvent(
                position: rect.center,
                scrollDelta: const Offset(-10, 0),
              ),
            );
            await t.pumpAndSettle();
            expect(position.pixels, closeTo(before - 10, .1));
            await t.sendEventToBinding(
              PointerScrollEvent(
                position: rect.center,
                scrollDelta: const Offset(0, 100),
              ),
            );
            await t.pumpAndSettle();
            expect(
              t.getRect(find.byKey(const Key('gen-tool-menu'))).right,
              lessThanOrEqualTo(rect.right + .1),
            );
            await tapKey(t, 'gen-tool-menu');
            expect(find.byKey(const Key('gen-pin-resources')), findsOneWidget);
            expect(t.takeException(), isNull);
          },
        );
      }
    }
  }
}
