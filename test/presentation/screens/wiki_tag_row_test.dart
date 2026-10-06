import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/presentation/screens/tag_wiki/wiki_article_outline.dart';
import 'package:nai_launcher/presentation/screens/tag_wiki/wiki_tag_row.dart';

const candidate = CompletionCandidate(
  canonicalTag: 'long_hair',
  category: TagCategory.general,
  translation: '长发',
  postCount: 4400000,
  matchKind: CompletionMatchKind.englishExact,
  sources: {CompletionSourceKind.base},
);

void main() {
  test(
    'outline respects fences, duplicate titles, setext and linked headings',
    () {
      final headings = wikiArticleHeadings(
        '# 简介\n\n```md\n## 不是标题\n```\n\n'
        '## [blue eyes](wof-tag:blue_eyes)\n\n示例\n---\n\n## 示例\n\n> ### 引用标题',
      );
      expect(headings.map((item) => item.label), [
        '简介',
        'blue eyes',
        '示例',
        '示例',
        '引用标题',
      ]);
      expect(headings.map((item) => item.level), [1, 2, 2, 2, 3]);
      expect(headings.map((item) => item.anchor).toSet().length, 5);
    },
  );

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets(
      'row keeps two readable lines and reserves action width at scale $scale',
      (tester) async {
        var selected = 0;
        var bookmarked = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 360,
                    child: WikiTagRow(
                      candidate: candidate,
                      subtitle: '长发',
                      countLabel: '4.4m',
                      selected: false,
                      bookmarked: false,
                      bookmarkLabel: '添加书签',
                      onSelect: () => selected++,
                      onBookmark: () => bookmarked++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final icon = find.byKey(const ValueKey('wiki-row-bookmark-long_hair'));
        final count = find.byKey(const ValueKey('wiki-row-count-long_hair'));
        final before = tester.getRect(count);
        expect(
          tester
              .widget<Icon>(
                find.byKey(const ValueKey('wiki-category-general-long_hair')),
              )
              .icon,
          Icons.sell_rounded,
        );
        expect(icon, findsNothing);
        expect(
          tester.getRect(find.text('长发')).top,
          greaterThan(tester.getRect(find.text('long hair')).bottom),
        );
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: const Offset(500, 500));
        await mouse.moveTo(tester.getCenter(find.byType(WikiTagRow)));
        await tester.pump();
        expect(icon, findsOneWidget);
        expect(tester.getRect(count), before);
        await tester.tap(icon);
        await tester.pump();
        expect(bookmarked, 1);
        expect(selected, 0);
        await mouse.moveTo(const Offset(500, 500));
        await tester.pump();
        // Remove incidental pointer/tap focus before checking the tab path.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        expect(icon, findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(icon, findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(bookmarked, 2);
        expect(selected, 0);
        expect(tester.takeException(), isNull);
        await mouse.removePointer();
      },
    );
  }
}
