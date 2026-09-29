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

    final label = tester.widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey('prompt-block-pill-body-${block.id}')),
        matching: find.byType(Text),
      ),
    );
    expect(label.maxLines, isNull);
    expect(label.overflow, TextOverflow.visible);
    expect(label.style?.fontSize, 12);
    expect(tester.getSize(find.text(reading)).height, greaterThan(28));
    expect(find.byIcon(Icons.translate_outlined), findsOneWidget);
    final pillMaterial = tester.widget<Material>(
      find.ancestor(
        of: find.byKey(const ValueKey('prompt-block-pill-body-translation-1')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Material && widget.shape is RoundedRectangleBorder,
        ),
      ),
    );
    final pillShape = pillMaterial.shape! as RoundedRectangleBorder;
    expect(pillShape.borderRadius.resolve(TextDirection.ltr).topLeft.x, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'saved palette translation retains its non-general category mark',
    (tester) async {
      final block = PromptBlock.create(
        title: '画师',
        content: 'artist:asteroid_ill',
        readingTranslationZh: '画师',
        readingTranslationMarks: const [
          {
            'start': 0,
            'end': 2,
            'tag': 'artist:asteroid_ill',
            'icon_id': 'artist',
          },
        ],
        appearance: 'translation',
      );
      final restored = PromptBlock.fromJson(block.toJson());
      expect(restored.readingTranslationMarks, block.readingTranslationMarks);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PromptBlockPill(
              block: restored,
              displayTitle: '画师',
              maxWidth: 170,
              paletteStyle: true,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('palette keeps weight colors and category mark together', (
    tester,
  ) async {
    const reading = '1.3::强光::, 0.7::阴影::, 画师';
    final markStart = reading.indexOf('画师');
    final block = PromptBlock.create(
      title: reading,
      content: '1.3::bright light::, 0.7::shadow::, artist:asteroid_ill',
      readingTranslationZh: reading,
      readingTranslationMarks: [
        {
          'start': markStart,
          'end': markStart + 2,
          'tag': 'artist:asteroid_ill',
          'icon_id': 'artist',
        },
      ],
      appearance: 'translation',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PromptBlockPill(
            block: block,
            displayTitle: reading,
            maxWidth: 170,
            paletteStyle: true,
            onTap: () {},
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey('prompt-block-pill-body-${block.id}')),
        matching: find.byType(Text),
      ),
    );
    final leaves = <TextSpan>[];
    void collect(InlineSpan span) {
      if (span is! TextSpan) return;
      if (span.text?.isNotEmpty == true) leaves.add(span);
      for (final child in span.children ?? const <InlineSpan>[]) {
        collect(child);
      }
    }

    collect(label.textSpan!);
    expect(
      leaves.any(
        (span) =>
            span.text!.contains('强光') &&
            span.style?.backgroundColor?.toARGB32() != null &&
            (span.style!.backgroundColor!.toARGB32() & 0xFFFFFF) == 0xED5807,
      ),
      isTrue,
    );
    expect(
      leaves.any(
        (span) =>
            span.text!.contains('阴影') &&
            span.style?.backgroundColor?.toARGB32() != null &&
            (span.style!.backgroundColor!.toARGB32() & 0xFFFFFF) == 0x079CED,
      ),
      isTrue,
    );
    expect(
      leaves.any(
        (span) =>
            span.text!.contains('画师') &&
            span.style?.decoration == TextDecoration.underline,
      ),
      isTrue,
    );
    expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
