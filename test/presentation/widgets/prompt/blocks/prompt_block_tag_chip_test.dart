import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_tag_chip.dart';

void main() {
  testWidgets(
    'nested tag strip applies a wheel tick once and hands off at its edge',
    (tester) async {
      final parent = ScrollController();
      addTearDown(parent.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: parent,
              children: [
                SizedBox(
                  height: 100,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 160,
                      child: PromptBlockTagStrip(
                        tags: [
                          for (var i = 0; i < 30; i++)
                            PromptBlockTag(name: 'tag$i', color: '#FF268BEA'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 1600),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final area = find.byKey(const Key('block-tag-scroll-area'));
      final child = tester
          .state<ScrollableState>(
            find.descendant(of: area, matching: find.byType(Scrollable)),
          )
          .position;
      final point = tester.getCenter(area);
      Future<void> wheel(Offset delta) => tester.sendEventToBinding(
        PointerScrollEvent(
          kind: PointerDeviceKind.mouse,
          position: point,
          scrollDelta: delta,
        ),
      );
      child.jumpTo(100);
      // The strip is reversed: horizontal input follows its native axis.
      await wheel(const Offset(24, 0));
      expect(child.pixels, 76);
      expect(parent.offset, 0);
      await wheel(const Offset(0, 35));
      expect(child.pixels, 111);
      expect(parent.offset, 0);
      child.jumpTo(child.maxScrollExtent);
      await wheel(const Offset(0, 30));
      expect(child.pixels, child.maxScrollExtent);
      expect(parent.offset, 30);
      parent.jumpTo(0);
      child.jumpTo(0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await wheel(const Offset(0, 20));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(
        child.pixels,
        0,
        reason:
            'Shift+wheel follows the reversed horizontal axis even at its edge',
      );
      expect(parent.offset, 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'overflowing header tags show a divider and accept wheel scroll',
    (tester) async {
      final tags = [
        for (var i = 0; i < 8; i++)
          PromptBlockTag(name: '标签$i', color: '#FF268BEA'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 140,
                child: PromptBlockTagStrip(tags: tags),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('block-tag-overflow-divider')),
        findsOneWidget,
      );
      final area = find.byKey(const Key('block-tag-scroll-area'));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(area));
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(area),
          scrollDelta: const Offset(0, 80),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await gesture.removePointer();
    },
  );
}
