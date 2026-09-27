import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_add_menu_button.dart';

void main() {
  testWidgets('opens a compact anchored menu and dispatches both actions', (
    tester,
  ) async {
    var createCount = 0;
    var importCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GalleryAddMenuButton(
                onCreateCategory: () => createCount++,
                onImportFolder: () => importCount++,
              ),
            ),
          ),
        ),
      ),
    );

    final button = find.text('新建/导入');
    final buttonBottom = tester.getRect(button).bottom;
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('新建分类'), findsOneWidget);
    expect(find.text('导入文件夹'), findsOneWidget);
    final menuItems = find.byWidgetPredicate((widget) => widget is PopupMenuItem);
    expect(menuItems, findsNWidgets(2));
    final menuRect = tester.getRect(menuItems.first);
    expect(menuRect.top, greaterThanOrEqualTo(buttonBottom));
    expect(menuRect.width, lessThan(230));

    await tester.tap(find.text('新建分类'));
    await tester.pumpAndSettle();
    expect(createCount, 1);
    expect(importCount, 0);

    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('导入文件夹'));
    await tester.pumpAndSettle();
    expect(createCount, 1);
    expect(importCount, 1);
  });
}
