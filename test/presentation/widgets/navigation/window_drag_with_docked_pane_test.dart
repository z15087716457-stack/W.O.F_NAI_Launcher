import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

Widget _page(WindowChromeScope Function(Widget) scope) => MaterialApp(
  home: Scaffold(
    body: scope(
      const Column(
        children: [
          WindowHeader(
            enabled: false,
            dragBackground: true,
            child: SizedBox(height: 40),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'page keeps blank-header window drag while a docked pane owns the captions',
    (tester) async {
      await tester.pumpWidget(
        _page(
          (child) =>
              WindowChromeScope(enabled: false, draggable: true, child: child),
        ),
      );
      expect(
        find.byKey(const Key('window-header-background-drag')),
        findsOneWidget,
      );
    },
  );

  testWidgets('disabled chrome (fullscreen / no shell) has no drag area', (
    tester,
  ) async {
    await tester.pumpWidget(
      _page((child) => WindowChromeScope(enabled: false, child: child)),
    );
    expect(
      find.byKey(const Key('window-header-background-drag')),
      findsNothing,
    );
  });
}
