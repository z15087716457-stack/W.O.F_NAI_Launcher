import 'package:flutter/material.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/library/library_widgets.dart';
import 'library_test_helpers.dart';

void main() {
  testWidgets(
    'selection is outside image; checkbox replaces in-generation pill; static bundle and favorite',
    (tester) async {
      await pumpLibrary(
        tester,
        const Center(
          child: SizedBox(
            width: 180,
            height: 271,
            child: LibraryCard(
              title: '组合包',
              isSelected: true,
              isInGeneration: true,
              checkbox: true,
              isFavorite: true,
              bundleCount: 5,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('library-card-checkbox')), findsOneWidget);
      expect(find.byKey(const Key('library-card-in-generation')), findsNothing);
      expect(find.byKey(const Key('library-card-favorite')), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.byKey(const ValueKey('library-card-back-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('library-card-back-1')), findsOneWidget);
      final image = find.byKey(const Key('library-card-image'));
      expect(tester.getSize(image), const Size(180, 225));
      final decoration =
          tester
                  .widget<AnimatedContainer>(
                    find.byKey(const Key('library-card-selection')),
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.boxShadow!.last.spreadRadius, 2);
    },
  );
  testWidgets(
    'click selects, double click sends, hover exposes actions without scaling',
    (tester) async {
      var selected = 0, sent = 0, retried = 0;
      await pumpLibrary(
        tester,
        Center(
          child: SizedBox(
            width: 180,
            height: 271,
            child: LibraryCard(
              title: 'test',
              hasError: true,
              onRetry: () => retried++,
              onTap: () => selected++,
              onDoubleTap: () => sent++,
              hoverActions: const LibraryHoverActionBar(
                children: [Text('加入生图', style: TextStyle(color: Colors.white))],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('test'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(selected, 1);
      expect(sent, 0);
      await tester.tap(find.text('test'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('test'));
      expect(sent, 1);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(LibraryCard)));
      await tester.pumpAndSettle();
      expect(find.text('加入生图'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('library-card-image'))),
        const Size(180, 225),
      );
      await tester.tap(find.byTooltip('重试'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(retried, 1);
      await mouse.removePointer();
    },
  );
}
