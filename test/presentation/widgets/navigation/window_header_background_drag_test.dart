import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';

import '../../../helpers/studio_capture_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  var maximized = false;
  const windows = MethodChannel('window_manager');
  const nativeChrome = MethodChannel('com.nailauncher/titlebar');
  setUpAll(loadStudioCaptureFonts);
  setUp(() {
    calls.clear();
    maximized = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(nativeChrome, (_) async => null);
    messenger.setMockMethodCallHandler(windows, (call) async {
      calls.add(call.method);
      if (call.method == 'isMaximized') return maximized;
      if (call.method == 'isFullScreen') return false;
      if (call.method == 'maximize') maximized = true;
      if (call.method == 'unmaximize') maximized = false;
      return null;
    });
  });
  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(windows, null);
    messenger.setMockMethodCallHandler(nativeChrome, null);
  });

  for (final width in [400.0, 1000.0]) {
    for (final reservedCaptions in [false, true]) {
      testWidgets(
        'blank space moves and maximizes; controls stay independent $width $reservedCaptions',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 600));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final controller = TextEditingController();
          addTearDown(controller.dispose);
          var taps = 0;
          var chosen = false;
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: IntegratedTitleBarShell(
                child: Scaffold(
                  body: Column(
                    children: [
                      WindowHeader(
                        enabled: reservedCaptions,
                        dragBackground: true,
                        child: SizedBox(
                          height: 100,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    key: const Key('search'),
                                    controller: controller,
                                  ),
                                ),
                                IconButton(
                                  key: const Key('action'),
                                  onPressed: () => taps++,
                                  icon: const Icon(Icons.add),
                                ),
                                PopupMenuButton<String>(
                                  key: const Key('menu'),
                                  onSelected: (_) => chosen = true,
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'sort',
                                      child: Text('Sort'),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          calls.clear();
          final header = tester.getRect(find.byType(WindowHeader));
          final blank = header.bottomLeft + const Offset(3, -5);
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.down(blank);
          await mouse.moveBy(const Offset(45, 0));
          await mouse.up();
          await tester.pump();
          expect(calls.where((call) => call == 'startDragging'), hasLength(1));
          calls.clear();

          await tester.enterText(
            find.byKey(const Key('search')),
            'unchanged draft',
          );
          await tester.pump();
          final field = tester.getRect(find.byKey(const Key('search')));
          await mouse.down(Offset(field.left + 20, field.center.dy));
          await mouse.moveBy(const Offset(30, 0));
          await mouse.moveBy(const Offset(30, 0));
          await mouse.up();
          await tester.pump();
          expect(controller.text, 'unchanged draft');
          expect(controller.selection.isCollapsed, isFalse);
          expect(calls, isNot(contains('startDragging')));

          await tester.tap(find.byKey(const Key('action')));
          expect(taps, 1);
          await tester.tap(find.byKey(const Key('menu')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sort'));
          await tester.pumpAndSettle();
          expect(chosen, isTrue);
          expect(calls, isNot(contains('startDragging')));

          for (var i = 0; i < 2; i++) {
            await tester.tapAt(blank);
            await tester.pump(const Duration(milliseconds: 100));
            await tester.tapAt(blank);
            await tester.pumpAndSettle();
          }
          expect(calls, containsAllInOrder(['maximize', 'unmaximize']));
          expect(tester.takeException(), isNull);
        },

        variant: TargetPlatformVariant.only(TargetPlatform.windows),
      );
    }
  }

  testWidgets(
    'standalone and disabled chrome never turn headers into window drag targets',
    (tester) async {
      for (final scoped in [false, true]) {
        const header = WindowHeader(
          dragBackground: true,
          child: SizedBox(height: 62, width: 500),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: GeistTheme.light,
            home: Scaffold(
              body: scoped
                  ? const WindowChromeScope(enabled: false, child: header)
                  : header,
            ),
          ),
        );
        expect(find.byType(WindowDragArea), findsNothing);
        expect(tester.getSize(find.byType(WindowHeader)), const Size(500, 62));
      }
    },

    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
