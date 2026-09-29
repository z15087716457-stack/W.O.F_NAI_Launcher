import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/translation_pill_view.dart';

void main() {
  testWidgets('left click opens editor at pointer; middle click toggles text', (
    tester,
  ) async {
    var pill = const TranslationPill(source: 'blue eyes', zh: '蓝眼睛');
    final editPositions = <Offset>[];
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
                  onEdit: editPositions.add,
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
    var decoration = tester.widget<Container>(
      find.descendant(
        of: find.byType(TranslationPillView),
        matching: find.byType(Container),
      ),
    );
    expect((decoration.decoration! as BoxDecoration).border, isNotNull);
    expect(decoration.foregroundDecoration, isNull);

    final click = tester.getCenter(find.byType(TranslationPillView));
    await tester.tapAt(click);
    await tester.pump();
    expect(editPositions, [click]);
    expect(find.text('蓝眼睛'), findsOneWidget);

    final middle = await tester.startGesture(
      click,
      kind: PointerDeviceKind.mouse,
      buttons: kMiddleMouseButton,
    );
    await middle.up();
    await tester.pump();
    expect(find.text('blue eyes'), findsOneWidget);
    expect(find.byIcon(Icons.translate_outlined), findsOneWidget);
    expect(find.byIcon(Icons.build_outlined), findsNothing);
    decoration = tester.widget<Container>(
      find.descendant(
        of: find.byType(TranslationPillView),
        matching: find.byType(Container),
      ),
    );
    expect((decoration.decoration! as BoxDecoration).border, isNull);
    expect(decoration.foregroundDecoration, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wrench appears only when changed source needs review', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TranslationPillView(
            pill: TranslationPill(
              source: 'edited source',
              zh: '旧译文',
              needsReview: true,
            ),
            onToggle: _noop,
            onEdit: _noopPosition,
          ),
        ),
      ),
    );
    expect(find.text('edited source'), findsOneWidget);
    expect(find.byIcon(Icons.build_outlined), findsOneWidget);
  });

  testWidgets(
    'long reading text wraps to the available width and full height',
    (tester) async {
      final reading = List.filled(45, '很长的译文').join();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: TranslationPillView(
                pill: TranslationPill(source: 'source', zh: reading),
                onToggle: () {},
                onEdit: _noopPosition,
              ),
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(TranslationPillView));
      final textSize = tester.getSize(find.text(reading));
      expect(size.width, lessThanOrEqualTo(280));
      expect(size.height, greaterThan(160));
      expect(size.height, greaterThanOrEqualTo(textSize.height));
      expect(
        find.descendant(
          of: find.byType(TranslationPillView),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('each left click requests editing without toggling display', (
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
              onEdit: (_) => edits++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TranslationPillView));
    await tester.pump();
    await tester.tap(find.byType(TranslationPillView));
    await tester.pump();
    expect(edits, 2);
    expect(find.text('蓝眼睛'), findsOneWidget);
  });

  testWidgets('editor grows with content and stays inside the viewport', (
    tester,
  ) async {
    BuildContext? editorContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              editorContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    final short = showTranslationPillEditor(
      context: editorContext!,
      initial: const TranslationPill(source: 'blue eyes', zh: '蓝眼睛'),
      globalPosition: const Offset(350, 180),
    );
    await tester.pump();
    final shortRect = tester.getRect(
      find.byKey(const Key('translation-pill-editor-popover')),
    );
    expect(shortRect.top, closeTo(190, 1));
    expect(shortRect.height, lessThan(350));
    short.dismiss();
    await tester.pump();

    final long = showTranslationPillEditor(
      context: editorContext!,
      initial: TranslationPill(
        source: List.filled(60, 'a longer source sentence').join(', '),
        zh: List.filled(60, '一段较长的译文').join('，'),
      ),
      globalPosition: const Offset(350, 580),
    );
    await tester.pump();
    final longRect = tester.getRect(
      find.byKey(const Key('translation-pill-editor-popover')),
    );
    expect(longRect.height, greaterThan(shortRect.height));
    expect(longRect.bottom, lessThanOrEqualTo(592));
    expect(longRect.top, greaterThanOrEqualTo(8));
    expect(tester.takeException(), isNull);
    long.dismiss();
  });

  testWidgets('editor icon actions return delete and retranslate', (
    tester,
  ) async {
    BuildContext? editorContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              editorContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    TranslationPillEditHandle open() => showTranslationPillEditor(
      context: editorContext!,
      initial: const TranslationPill(source: 'source', zh: '译文'),
      globalPosition: const Offset(120, 80),
    );

    final first = open();
    await tester.pump();
    await tester.tap(find.byKey(const Key('translation-pill-retranslate')));
    expect(await first.result, 'retranslate');
    await tester.pump();

    final second = open();
    await tester.pump();
    await tester.tap(find.byKey(const Key('translation-pill-delete')));
    expect(await second.result, 'delete');
    await tester.pump();
    expect(
      find.byKey(const Key('translation-pill-editor-popover')),
      findsNothing,
    );
  });

  testWidgets('saving a changed source marks its reading for review', (
    tester,
  ) async {
    BuildContext? editorContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              editorContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    final editor = showTranslationPillEditor(
      context: editorContext!,
      initial: const TranslationPill(source: 'source', zh: '译文'),
      globalPosition: const Offset(120, 80),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'edited source');
    await tester.tap(find.byKey(const Key('translation-pill-save')));
    final result = await editor.result as TranslationPill;
    expect(result.source, 'edited source');
    expect(result.zh, '译文');
    expect(result.showOriginal, isTrue);
    expect(result.needsReview, isTrue);

    await tester.pump();
    final reopened = showTranslationPillEditor(
      context: editorContext!,
      initial: result,
      globalPosition: const Offset(120, 80),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('translation-pill-save')));
    final unchanged = await reopened.result as TranslationPill;
    expect(unchanged.needsReview, isTrue);
  });
}

void _noop() {}
void _noopPosition(Offset _) {}
