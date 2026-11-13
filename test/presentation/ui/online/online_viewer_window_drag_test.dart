import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/online/online_fixture.dart';
import 'package:nai_launcher/presentation/ui/online/online_page.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'online_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);
  final windowCalls = <String>[];
  var maximized = false;
  setUp(() {
    windowCalls.clear();
    maximized = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), (
          call,
        ) async {
          windowCalls.add(call.method);
          if (call.method == 'isFullScreen') return false;
          if (call.method == 'isMaximized') return maximized;
          if (call.method == 'maximize') maximized = true;
          if (call.method == 'unmaximize') maximized = false;
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), null),
  );

  Future<void> mount(
    WidgetTester tester, {
    RecordingOnlineActions? actions,
    bool chromeEnabled = true,
    bool? draggable,
    bool info = true,
  }) async {
    await pumpOnline(
      tester,
      data: OnlineFixture.view(image: (_) => null, selectedKey: 'c03'),
      actions: actions?.actions,
      window: 2000,
      height: 1200,
      chromeEnabled: chromeEnabled,
      draggable: draggable,
    );
    (tester.state(find.byType(OnlineGalleryPage)) as OnlineController)
        .openViewer('c03');
    await tester.pumpAndSettle();
    if (!info) {
      await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
      await tester.pumpAndSettle();
    }
    windowCalls.clear();
  }

  Offset blank(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(const Key('online-viewer'))) +
      const Offset(500, 28);

  for (final info in [true, false]) {
    testWidgets(
      'empty viewer header starts native window dragging: info=$info',
      (tester) async {
        await mount(tester, info: info);
        await tester.dragFrom(blank(tester), const Offset(70, 15));
        await tester.pump(const Duration(milliseconds: 100));
        expect(windowCalls, contains('startDragging'));
        expect(find.byKey(const Key('online-viewer')), findsOneWidget);
      },
    );
  }

  testWidgets('passive title and position text also drag the window', (
    tester,
  ) async {
    await mount(tester);
    final header = find.byKey(const Key('online-viewer-header'));
    expect(tester.getSize(header).height, 56);
    final title = OnlineFixture.view(
      image: (_) => null,
    ).list.items.firstWhere((w) => w.key == 'c03').title!;
    for (final target in [
      find.descendant(of: header, matching: find.text(title)),
      find.byKey(const Key('online-viewer-position')),
    ]) {
      windowCalls.clear();
      await tester.drag(target, const Offset(70, 15));
      await tester.pump(const Duration(milliseconds: 100));
      expect(windowCalls, contains('startDragging'));
    }
  });

  testWidgets(
    'header buttons remain clickable and never initiate a window drag',
    (tester) async {
      final actions = RecordingOnlineActions();
      await mount(tester, actions: actions);
      final browser = find.byKey(const Key('online-viewer-open-browser'));
      final close = find.byKey(const Key('online-viewer-close'));
      for (final target in [browser, close]) {
        await tester.drag(target, const Offset(-65, 12));
        await tester.pump(const Duration(milliseconds: 100));
        expect(windowCalls, isNot(contains('startDragging')));
      }
      await tester.tap(browser);
      await tester.pump(const Duration(milliseconds: 100));
      expect(actions.calls, contains('open:c03'));
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('online-viewer')), findsNothing);
      expect(windowCalls, isNot(contains('startDragging')));
    },
  );

  testWidgets('double click on empty header toggles maximize and restore', (
    tester,
  ) async {
    await mount(tester);
    for (final expected in ['maximize', 'unmaximize']) {
      final point = blank(tester);
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(windowCalls, contains(expected));
      await tester.pump(const Duration(milliseconds: 400));
    }
  });

  testWidgets('image area does not move the window', (tester) async {
    await mount(tester);
    await tester.dragFrom(
      blank(tester) + const Offset(0, 200),
      const Offset(70, 15),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(windowCalls, isNot(contains('startDragging')));
  });

  testWidgets(
    'docked pane caption ownership does not disable viewer header dragging',
    (tester) async {
      await mount(tester, chromeEnabled: false, draggable: true);
      await tester.dragFrom(blank(tester), const Offset(70, 15));
      await tester.pump(const Duration(milliseconds: 100));
      expect(windowCalls, contains('startDragging'));
    },
  );

  testWidgets(
    'fullscreen or unsupported host does not request native window dragging',
    (tester) async {
      await mount(tester, chromeEnabled: false);
      await tester.dragFrom(blank(tester), const Offset(70, 15));
      await tester.pump(const Duration(milliseconds: 100));
      expect(windowCalls, isNot(contains('startDragging')));
    },
  );
}
