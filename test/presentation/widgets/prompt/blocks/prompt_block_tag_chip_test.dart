import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_tag_chip.dart';

void main() {
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
