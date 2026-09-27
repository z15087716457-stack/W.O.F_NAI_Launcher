import 'package:nai_launcher/presentation/widgets/common/image_detail/components/detail_top_bar.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/image_detail_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.nailauncher/titlebar');
  const windows = MethodChannel('window_manager');
  final calls = <MethodCall>[];
  final windowCalls = <String>[];
  var maximized = false;
  setUp(() {
    calls.clear();
    windowCalls.clear();
    maximized = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(windows, (call) async {
      windowCalls.add(call.method);
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
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(windows, null);
  });
  Widget host(Widget child, {bool immersive = false, VoidCallback? toggle}) =>
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: IntegratedTitleBarShell(
          immersive: immersive,
          onToggleTheme: toggle,
          child: child,
        ),
      );

  testWidgets(
    'content starts at zero; caption buttons stay fixed and callable',
    (tester) async {
      await tester.pumpWidget(host(const Scaffold(key: Key('page'))));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const Key('page'))), Offset.zero);
      expect(find.text('NAI Studio'), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(
        tester.getTopRight(find.byKey(const Key('window-caption-controls'))).dx,
        800,
      );
      expect((calls.last.arguments as Map)['barHeight'], 0);
      await tester.tap(find.byIcon(Icons.remove));
      await tester.tap(find.byIcon(Icons.crop_square));
      await tester.tap(find.byIcon(Icons.close));
      expect(windowCalls, containsAll(['minimize', 'maximize', 'close']));
      await tester.pumpWidget(const SizedBox());
      expect(calls.last.method, 'clear');
    },
  );

  testWidgets('entry has native drag area; workspace clears it on transition', (
    tester,
  ) async {
    var toggles = 0;
    await tester.pumpWidget(
      host(const Scaffold(), immersive: true, toggle: () => toggles++),
    );
    await tester.pumpAndSettle();
    expect((calls.last.arguments as Map)['barHeight'], 36);
    expect((calls.last.arguments as Map)['reservedRight'], 187);
    await tester.tap(find.byKey(const Key('brand_appearance_toggle')));
    expect(toggles, 1);
    await tester.pumpWidget(host(const Scaffold()));
    await tester.pumpAndSettle();
    expect((calls.last.arguments as Map)['barHeight'], 0);
    expect(find.byKey(const Key('brand_appearance_toggle')), findsNothing);
  });

  testWidgets(
    'full-image controls stay below window captions and can close only the viewer',
    (tester) async {
      var viewerClosed = 0;
      await tester.pumpWidget(
        host(
          Scaffold(
            backgroundColor: Colors.black,
            body: Align(
              alignment: Alignment.topCenter,
              child: DetailTopBar(
                currentIndex: 0,
                totalImages: 1,
                currentImage: GeneratedImageDetailData(
                  imageBytes: Uint8List(0),
                ),
                onClose: () => viewerClosed++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final viewerClose = find.descendant(
        of: find.byType(DetailTopBar),
        matching: find.byIcon(Icons.close),
      );
      final captionRect = tester.getRect(
        find.byKey(const Key('window-caption-controls')),
      );
      expect(tester.getRect(viewerClose).overlaps(captionRect), isFalse);
      await tester.tap(viewerClose);
      expect(viewerClosed, 1);
      expect(windowCalls, isNot(contains('close')));
      expect(find.byType(WindowDragArea), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [400.0, 1000.0]) {
    testWidgets(
      'header avoids captions at $width; controls and drag area are independent',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var taps = 0;
        await tester.pumpWidget(
          host(
            Scaffold(
              body: Column(
                children: [
                  WindowHeader(
                    child: SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          const Expanded(child: TextField(key: Key('search'))),
                          IconButton(
                            key: const Key('action'),
                            onPressed: () => taps++,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final action = tester.getRect(find.byKey(const Key('action')));
        final captions = tester.getRect(
          find.byKey(const Key('window-caption-controls')),
        );
        expect(action.overlaps(captions), isFalse);
        await tester.tap(find.byKey(const Key('action')));
        expect(taps, 1);
        await tester.enterText(
          find.byKey(const Key('search')),
          'keep this draft',
        );
        final drag = find.byType(WindowDragArea);
        await tester.drag(drag, const Offset(-32, 20));
        await tester.pumpAndSettle();
        expect(windowCalls, contains('startDragging'));
        windowCalls.clear();
        await tester.tap(drag);
        await tester.pump(const Duration(milliseconds: 80));
        await tester.tap(drag);
        await tester.pumpAndSettle();
        expect(windowCalls, contains('maximize'));
        expect(find.text('keep this draft'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final width in [400.0, 600.0, 1000.0]) {
    testWidgets('full-height canvas keeps only top toolbar clear at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: IntegratedTitleBarShell(
            accessoryWidth: 88,
            accessory: const SizedBox(),
            child: Scaffold(
              body: Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: ColoredBox(
                            key: Key('canvas-area'),
                            color: Colors.blue,
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: WindowSafeTopToolbar(
                              outsideRightWidth: 56,
                              child: SizedBox(
                                width: 300,
                                height: 40,
                                child: TextButton(
                                  key: const Key('canvas-top-tool'),
                                  onPressed: () => taps++,
                                  child: const Text('tool'),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final canvas = tester.getRect(find.byKey(const Key('canvas-area')));
      final tool = tester.getRect(find.byKey(const Key('canvas-top-tool')));
      expect(canvas.top, 0);
      expect(canvas.height, 600);
      expect(tool.overlaps(Rect.fromLTWH(width - 226, 0, 226, 36)), isFalse);
      if (width == 1000) {
        expect(tool.top, 16);
        expect(tool.center.dx, canvas.center.dx);
      }
      await tester.tap(find.byKey(const Key('canvas-top-tool')));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
