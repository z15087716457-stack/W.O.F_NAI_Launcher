import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_card.dart';

void main() {
  testWidgets('palette translation block shows complete wrapped reading', (
    tester,
  ) async {
    const reading = '风景，全景，从后方，绿色主题，蓝色主题，植物，细节丰富的背景，充满自然气息';
    final block = PromptBlock(
      id: 'translation-1',
      title: '风景，全景…',
      content: 'scenery, panorama, from behind, green theme',
      readingTranslationZh: reading,
      appearance: 'translation',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PromptBlockPill(
              block: block,
              displayTitle: reading,
              maxWidth: 170,
              paletteStyle: true,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text(reading));
    expect(label.maxLines, isNull);
    expect(label.overflow, TextOverflow.visible);
    expect(label.style?.fontSize, 12);
    expect(tester.getSize(find.text(reading)).height, greaterThan(28));
    expect(find.byIcon(Icons.translate_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
