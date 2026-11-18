import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_resource_window.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_resource_kind.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  GenViewData data(ResourceWindowVisibility state, bool pinned) {
    final original = GenFixture.view();
    return original.copyWith(
      prompt: GenPromptData(
        tools: GenPromptTools(
          resourceWindowsPinned: pinned,
          resourceWindowVisibility: state,
        ),
      ),
    );
  }

  for (final state in ResourceWindowVisibility.values) {
    for (final pinned in [false, true]) {
      testWidgets('toolbar $state pinned=$pinned follows actual open state', (
        tester,
      ) async {
        final log = GenRecorder();
        await pumpGen(tester, data: data(state, pinned), actions: log.actions);
        final shown = pinned || state != ResourceWindowVisibility.closed;
        final icon = find.byKey(const Key('gen-tool-resources'));
        expect(icon, shown ? findsOneWidget : findsNothing);
        if (shown) {
          final glyph = tester.widget<GenResourceWindowIcon>(
            find.descendant(
              of: icon,
              matching: find.byType(GenResourceWindowIcon),
            ),
          );
          expect(glyph.visibility, state);
          await tester.tap(icon);
          await tester.pumpAndSettle();
          expect(
            log.last('onToggleResourceWindow'),
            'onToggleResourceWindow(true)',
          );
          expect(find.byKey(const Key('gen-tool-resource-vibe')), findsNothing);
        }
        await tester.tap(find.byKey(const Key('gen-tool-menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('gen-resource-windows')));
        await tester.pumpAndSettle();
        expect(
          log.last('onToggleResourceWindow'),
          'onToggleResourceWindow(true)',
        );
        expect(find.byKey(const Key('gen-resource-gallery')), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets(
    'keyboard activation does not reuse the mouse activation snapshot',
    (tester) async {
      final log = GenRecorder();
      await pumpGen(
        tester,
        data: data(ResourceWindowVisibility.back, true),
        actions: log.actions,
      );
      final icon = find.byKey(const Key('gen-tool-resources'));
      await tester.tap(icon);
      await tester.pumpAndSettle();
      // A semantics activation has no pointer event and uses the current order.
      final gesture = find
          .descendant(of: icon, matching: find.byType(GestureDetector))
          .first;
      tester.widget<GestureDetector>(gesture).onTap!();
      await tester.pump();
      expect(
        log.last('onToggleResourceWindow'),
        'onToggleResourceWindow(false)',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    testWidgets('narrow toolbar keeps resource toggle visible $locale', (
      tester,
    ) async {
      await pumpGen(
        tester,
        data: data(ResourceWindowVisibility.back, false),
        locale: locale,
        window: 1000,
      );
      expect(find.byKey(const Key('gen-tool-resources')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final dark in [false, true]) {
    testWidgets('capture approved stacked-window states dark=$dark', (
      tester,
    ) async {
      final boundary = GlobalKey();
      await tester.pumpWidget(
        genApp(
          Scaffold(
            body: RepaintBoundary(
              key: boundary,
              child: SizedBox(
                width: 420,
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final state in ResourceWindowVisibility.values)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GenResourceWindowIcon(visibility: state, size: 40.8),
                          const SizedBox(height: 12),
                          GenResourceWindowIcon(visibility: state),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          dark: dark,
        ),
      );
      await tester.pumpAndSettle();
      final object =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await object.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final output = File(
          '.dart_tool/resource-window-toggle-20261118/icons-${dark ? 'dark' : 'light'}.png',
        );
        await output.parent.create(recursive: true);
        await output.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    });
  }
}
