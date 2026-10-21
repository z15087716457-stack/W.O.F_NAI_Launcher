import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_history.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final windowCalls = <String>[];
  setUp(() {
    windowCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), (
          call,
        ) async {
          windowCalls.add(call.method);
          if (call.method == 'isFullScreen') return false;
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), null);
  });

  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets(
        'history header stays centered across Agent docking $locale $dark',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetDevicePixelRatio);
          final capture = GlobalKey();
          final recorder = GenRecorder();
          for (final width in [280.0, 200.0]) {
            for (final expanded in [false, true, false]) {
              await tester.pumpWidget(
                genApp(
                  WindowChromeScope(
                    enabled: !expanded,
                    draggable: true,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: width,
                        height: 360,
                        child: RepaintBoundary(
                          key: capture,
                          child: GenHost(
                            data: GenFixture.empty(),
                            actions: recorder.actions,
                            slots: GenSlots(
                              editor: (_, _) => const SizedBox.shrink(),
                              historyCaptionInset: !expanded,
                            ),
                            child: GenHistoryPanel(width: width),
                          ),
                        ),
                      ),
                    ),
                  ),
                  locale: locale,
                  dark: dark,
                ),
              );
              await tester.pumpAndSettle();
              final header = find.byKey(const Key('gen-history-header'));
              final headerRect = tester.getRect(header);
              final l = AppLocalizations.of(tester.element(header))!;
              final output = Platform.environment['HISTORY_HEADER_CAPTURES'];
              if (output != null && locale == 'zh' && width == 280) {
                await tester.runAsync(() async {
                  final image =
                      await (capture.currentContext!.findRenderObject()!
                              as RenderRepaintBoundary)
                          .toImage();
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  image.dispose();
                  final file = File(
                    '$output/${expanded ? 'expanded' : 'collapsed'}-${dark ? 'dark' : 'light'}.png',
                  );
                  await file.parent.create(recursive: true);
                  await file.writeAsBytes(bytes!.buffer.asUint8List());
                });
              }
              expect(headerRect.height, 40);
              expect(headerRect.top, expanded ? 0 : WindowChromeScope.height);
              for (final control in [
                find.text(l.gen_history),
                find.byKey(const Key('gen-collapse-history')),
                find.byKey(const Key('gen-history-select')),
              ]) {
                expect(
                  tester.getCenter(control).dy,
                  closeTo(headerRect.center.dy, .6),
                  reason:
                      'Header contents must stay centered when Agent is $expanded.',
                );
              }
              if (expanded) {
                windowCalls.clear();
                // Empty space at the bottom of the header still moves the window.
                await tester.dragFrom(
                  headerRect.bottomLeft + const Offset(12, -3),
                  const Offset(50, 0),
                );
                await tester.pumpAndSettle();
                expect(windowCalls, contains('startDragging'));
                windowCalls.clear();
                await tester.tap(find.byKey(const Key('gen-collapse-history')));
                await tester.pumpAndSettle();
                expect(recorder.called('onLayoutChanged'), isTrue);
                expect(windowCalls, isNot(contains('startDragging')));
              }
              expect(tester.takeException(), isNull);
            }
          }
        },
      );
    }
  }
}
