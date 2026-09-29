import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/translation_pill_view.dart';

void main() {
  testWidgets('Chinese view hides controls and tap reveals the original', (
    tester,
  ) async {
    var pill = const TranslationPill(source: 'blue eyes', zh: '蓝眼睛');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: TranslationPillView(
                  pill: pill,
                  onToggle: () => setState(
                    () =>
                        pill = pill.copyWith(showOriginal: !pill.showOriginal),
                  ),
                  onEdit: () {},
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('蓝眼睛'), findsOneWidget);
    expect(find.byIcon(Icons.translate_outlined), findsNothing);
    expect(find.byIcon(Icons.build_outlined), findsNothing);

    await tester.tap(find.byType(TranslationPillView));
    await tester.pump();
    expect(find.text('blue eyes'), findsOneWidget);
    expect(find.byIcon(Icons.translate_outlined), findsOneWidget);
    expect(find.byIcon(Icons.build_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long reading text stays within a bounded pill', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranslationPillView(
            pill: TranslationPill(
              source: 'source',
              zh: List.filled(200, '很长的译文').join(),
            ),
            onToggle: () {},
            onEdit: () {},
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(TranslationPillView));
    expect(size.width, lessThanOrEqualTo(300));
    expect(size.height, lessThanOrEqualTo(160));
    expect(tester.takeException(), isNull);
  });

  testWidgets('double click opens editing without leaving display toggled', (
    tester,
  ) async {
    var pill = const TranslationPill(source: 'blue eyes', zh: '蓝眼睛');
    var edits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => TranslationPillView(
              pill: pill,
              onToggle: () => setState(
                () => pill = pill.copyWith(showOriginal: !pill.showOriginal),
              ),
              onEdit: () => edits++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TranslationPillView));
    await tester.pump();
    await tester.tap(find.byType(TranslationPillView));
    await tester.pump();
    expect(edits, 1);
    expect(find.text('蓝眼睛'), findsOneWidget);
  });
}
