import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

/// 比窗口按钮高的页头：按钮正下方的保留区也能拖动窗口（可选）。
void main() {
  final windowCalls = <String>[];
  setUp(() {
    windowCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), (
          call,
        ) async {
          windowCalls.add(call.method);
          return call.method == 'isMaximized' || call.method == 'isFullScreen'
              ? false
              : null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), null);
  });

  Future<void> pumpHeader(WidgetTester tester, {required bool dragBelow}) {
    tester.view.physicalSize = const Size(1000, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WindowChromeScope(
            child: Align(
              alignment: Alignment.topCenter,
              child: LibraryWindowHeader(
                inlineDragWidth: 17,
                dragBelowCaptions: dragBelow,
                child: const SizedBox(height: 62, width: double.infinity),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 窗口按钮区（右侧 138px、高 36px）的正下方
  const belowCaptions = Offset(1000 - 60, 50);

  testWidgets('strip below the captions drags the window when enabled', (
    tester,
  ) async {
    await pumpHeader(tester, dragBelow: true);
    expect(
      find.byKey(const Key('window-header-drag-below-captions')),
      findsOneWidget,
    );
    await tester.dragFrom(belowCaptions, const Offset(-80, 20));
    await tester.pumpAndSettle();
    expect(windowCalls, contains('startDragging'));
  });

  testWidgets('other headers keep the strip below the captions inert', (
    tester,
  ) async {
    await pumpHeader(tester, dragBelow: false);
    expect(
      find.byKey(const Key('window-header-drag-below-captions')),
      findsNothing,
    );
    await tester.dragFrom(belowCaptions, const Offset(-80, 20));
    await tester.pumpAndSettle();
    expect(windowCalls, isNot(contains('startDragging')));
  });
}
