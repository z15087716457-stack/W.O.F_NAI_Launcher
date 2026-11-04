import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_text_selection_toolbar.dart';

Future<void> _pumpToolbar(WidgetTester tester) async {
  // ThemeData 的 platform 取构建时的 defaultTargetPlatform，所以在测试里现建
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'ThemeFont'),
      home: Scaffold(
        body: Builder(
          builder: (context) => buildThemedTextSelectionToolbar(
            context,
            anchors: const TextSelectionToolbarAnchors(
              primaryAnchor: Offset(200, 200),
            ),
            buttonItems: [
              ContextMenuButtonItem(label: 'Copy', onPressed: () {}),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('macOS：Mac 样式的菜单按钮，字体跟主题，悬停时反白字', (tester) async {
    await _pumpToolbar(tester);
    expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsOneWidget);
    expect(
      find.byType(CupertinoDesktopTextSelectionToolbarButton),
      findsOneWidget,
    );
    expect(find.byType(DesktopTextSelectionToolbarButton), findsNothing);

    Text label() => tester.widget<Text>(find.text('Copy'));
    expect(label().style?.fontFamily, 'ThemeFont');
    final context = tester.element(find.text('Copy'));
    final normal = label().style?.color;

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('Copy')));
    await tester.pump();
    expect(
      label().style?.color,
      CupertinoTheme.of(context).primaryContrastingColor,
    );
    expect(label().style?.fontFamily, 'ThemeFont');

    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(label().style?.color, normal);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Windows：照旧是桌面按钮，字体跟主题', (tester) async {
    await _pumpToolbar(tester);
    expect(find.byType(DesktopTextSelectionToolbarButton), findsOneWidget);
    expect(
      find.byType(CupertinoDesktopTextSelectionToolbarButton),
      findsNothing,
    );
    expect(
      tester.widget<Text>(find.text('Copy')).style?.fontFamily,
      'ThemeFont',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
