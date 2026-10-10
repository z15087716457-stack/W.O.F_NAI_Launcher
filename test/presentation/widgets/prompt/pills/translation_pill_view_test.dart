import 'package:nai_launcher/presentation/widgets/common/translation_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/translation_pill_view.dart';

void main() {
  testWidgets('both translation faces reuse prompt syntax colors', (
    tester,
  ) async {
    const source = '1.4::silver hair::, {blue eyes}, |red|';
    const translated = '1.4::银发::, {蓝眼睛}, |红|';
    var pill = const TranslationPill(source: source, zh: translated);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => TranslationPillView(
              pill: pill,
              onToggle: () => setState(
                () => pill = pill.copyWith(showOriginal: !pill.showOriginal),
              ),
              onEdit: _noopPosition,
            ),
          ),
        ),
      ),
    );

    var spans = _visibleSyntaxSpans(tester);
    expect(_visibleText(tester), translated);
    expect(
      spans.any(
        (span) =>
            span.text!.contains('银发') && span.style?.backgroundColor != null,
      ),
      isTrue,
    );
    expect(
      spans.any(
        (span) => span.text == '::' && span.style?.backgroundColor != null,
      ),
      isTrue,
    );
    expect(
      spans.any(
        (span) =>
            span.text!.contains('蓝眼睛') && span.style?.backgroundColor != null,
      ),
      isTrue,
    );
    expect(
      spans.any(
        (span) => span.text == '|' && span.style?.fontWeight == FontWeight.w800,
      ),
      isTrue,
    );

    final center = tester.getCenter(find.byType(TranslationPillView));
    final middle = await tester.startGesture(
      center,
      kind: PointerDeviceKind.mouse,
      buttons: kMiddleMouseButton,
    );
    await middle.up();
    await tester.pump();

    spans = _visibleSyntaxSpans(tester);
    expect(_visibleText(tester), source);
    expect(
      spans.any(
        (span) =>
            span.text!.contains('silver hair') &&
            span.style?.backgroundColor != null,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tag icon and matching underline decorate only the zh face', (
    tester,
  ) async {
    var pill = const TranslationPill(
      source: '1.4::artist:asteroid_ill::, sky',
      zh: '1.4::画师::，天空',
      marks: [
        TranslationTagMark(
          start: 5,
          end: 7,
          tag: 'artist:asteroid_ill',
          iconId: 'artist',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: StatefulBuilder(
              builder: (context, setState) => TranslationPillView(
                pill: pill,
                onToggle: () => setState(
                  () => pill = pill.copyWith(showOriginal: !pill.showOriginal),
                ),
                onEdit: _noopPosition,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
    final children =
        (tester.widget<Text>(_visibleTextFinder()).textSpan! as TextSpan)
            .children!;
    final marked = children.whereType<TextSpan>().firstWhere(
      (span) => span.text == '画师',
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.brush_rounded));
    expect(marked.style!.decoration, TextDecoration.underline);
    expect(marked.style!.decorationColor, icon.color);
    expect(
      children.whereType<TextSpan>().any(
        (span) => span.text == '::' && span.style?.backgroundColor != null,
      ),
      isTrue,
    );
    expect(
      tester.getSize(find.byType(TranslationPillView)).width,
      lessThanOrEqualTo(180),
    );

    final middle = await tester.startGesture(
      tester.getCenter(find.byType(TranslationPillView)),
      kind: PointerDeviceKind.mouse,
      buttons: kMiddleMouseButton,
    );
    await middle.up();
    await tester.pump();
    expect(find.byIcon(Icons.brush_rounded), findsNothing);
    expect(find.text('1.4::artist:asteroid_ill::, sky'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy general marks show plain reading text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TranslationPillView(
            pill: TranslationPill(
              source: 'blue eyes',
              zh: '蓝眼睛',
              marks: [
                TranslationTagMark(
                  start: 0,
                  end: 3,
                  tag: 'blue_eyes',
                  iconId: 'general',
                ),
              ],
            ),
            onToggle: _noop,
            onEdit: _noopPosition,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.sell_rounded), findsNothing);
    expect(find.text('蓝眼睛'), findsOneWidget);
    expect(
      _visibleSyntaxSpans(
        tester,
      ).every((span) => span.style?.decoration != TextDecoration.underline),
      isTrue,
    );
  });

  testWidgets('translation syntax follows emphasis and model switches', (
    tester,
  ) async {
    var highlight = true;
    var numeric = true;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return TranslationPillView(
                pill: const TranslationPill(
                  source: '2::source::',
                  zh: '2::中文:: |甲|',
                ),
                highlightEnabled: highlight,
                numericEmphasisEnabled: numeric,
                onToggle: _noop,
                onEdit: _noopPosition,
              );
            },
          ),
        ),
      ),
    );
    expect(
      _visibleSyntaxSpans(
        tester,
      ).any((span) => span.style?.backgroundColor != null),
      isTrue,
    );

    update(() => numeric = false);
    await tester.pump();
    expect(
      _visibleSyntaxSpans(
        tester,
      ).every((span) => span.style?.backgroundColor == null),
      isTrue,
    );

    update(() {
      numeric = true;
      highlight = false;
    });
    await tester.pump();
    final spans = _visibleSyntaxSpans(tester);
    expect(spans.every((span) => span.style?.backgroundColor == null), isTrue);
    expect(
      spans.any(
        (span) => span.text == '|' && span.style?.fontWeight == FontWeight.w800,
      ),
      isTrue,
    );
    expect(_visibleText(tester), '2::中文:: |甲|');
  });

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
    expect(find.byType(TranslationIcon), findsNothing);
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
    expect(find.byType(TranslationIcon), findsOneWidget);
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

  testWidgets('review wrench remains visible on either face', (tester) async {
    var pill = const TranslationPill(
      source: 'edited source',
      zh: '旧译文',
      needsReview: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => TranslationPillView(
              pill: pill,
              onToggle: () => setState(
                () => pill = pill.copyWith(showOriginal: !pill.showOriginal),
              ),
              onEdit: _noopPosition,
            ),
          ),
        ),
      ),
    );
    expect(find.text('旧译文'), findsOneWidget);
    expect(find.byIcon(Icons.build_outlined), findsOneWidget);
    final middle = await tester.startGesture(
      tester.getCenter(find.byType(TranslationPillView)),
      kind: PointerDeviceKind.mouse,
      buttons: kMiddleMouseButton,
    );
    await middle.up();
    await tester.pump();
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

  testWidgets(
    'editor icon actions return delete and offer both conversion directions',
    (tester) async {
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
      expect(
        find.byKey(const Key('translation-pill-to-source')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('translation-pill-to-chinese')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('translation-pill-retranslate')),
        findsNothing,
      );
      first.dismiss();
      expect(await first.result, isNull);
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
    },
  );

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
      initial: const TranslationPill(
        source: 'source',
        zh: '译文',
        marks: [
          TranslationTagMark(
            start: 0,
            end: 2,
            tag: 'source',
            iconId: 'general',
          ),
        ],
      ),
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
    expect(result.marks, isEmpty);

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

  testWidgets('editing the reading clears stale category marks', (
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
      initial: const TranslationPill(
        source: 'blue eyes',
        zh: '蓝眼睛',
        marks: [
          TranslationTagMark(
            start: 0,
            end: 3,
            tag: 'blue_eyes',
            iconId: 'general',
          ),
        ],
      ),
      globalPosition: const Offset(120, 80),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, '青色眼睛');
    await tester.tap(find.byKey(const Key('translation-pill-save')));
    final result = await editor.result as TranslationPill;
    expect(result.zh, '青色眼睛');
    expect(result.marks, isEmpty);
    expect(result.source, 'blue eyes');
    expect(result.needsReview, isFalse);
  });

  testWidgets('polishing the reading keeps an existing review flag', (
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
      initial: const TranslationPill(
        source: 'edited source',
        zh: '旧译文',
        needsReview: true,
      ),
      globalPosition: const Offset(120, 80),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, '手工润色');
    await tester.tap(find.byKey(const Key('translation-pill-save')));
    final result = await editor.result as TranslationPill;
    expect(result.zh, '手工润色');
    expect(result.source, 'edited source');
    expect(result.needsReview, isTrue);
  });

  testWidgets('plain text action returns the visible source', (tester) async {
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
      initial: const TranslationPill(source: 'blue eyes', zh: '蓝眼睛'),
      globalPosition: const Offset(120, 80),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'green eyes');
    await tester.tap(find.byKey(const Key('translation-pill-plain-text')));
    final result = await editor.result as TranslationPillPlainText;
    expect(result.source, 'green eyes');
    await tester.pump();
    expect(
      find.byKey(const Key('translation-pill-editor-popover')),
      findsNothing,
    );
  });
}

String _visibleText(WidgetTester tester) =>
    tester.widget<Text>(_visibleTextFinder()).textSpan!.toPlainText();

List<TextSpan> _visibleSyntaxSpans(WidgetTester tester) =>
    (tester.widget<Text>(_visibleTextFinder()).textSpan! as TextSpan).children!
        .cast<TextSpan>();

Finder _visibleTextFinder() => find.descendant(
  of: find.byType(TranslationPillView),
  matching: find.byType(Text),
);

void _noop() {}
void _noopPosition(Offset _) {}
