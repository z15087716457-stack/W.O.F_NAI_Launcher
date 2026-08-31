import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/prompt/nai_syntax_controller.dart';

void main() {
  const markerA = '\uE000';
  const markerB = '\uE001';

  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return captured;
  }

  TextSpan build(
    NaiSyntaxController controller,
    BuildContext context, {
    String? text,
  }) {
    return controller.buildTextSpan(
      context: context,
      style: const TextStyle(),
      withComposing: false,
    );
  }

  testWidgets('null pillBuilder leaves markers as plain text spans', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    final controller = NaiSyntaxController(text: 'a${markerA}b');
    addTearDown(controller.dispose);

    final span = build(controller, context);
    final widgetSpans = span.children!.whereType<WidgetSpan>().toList();
    expect(widgetSpans, isEmpty);
    final plain = span.children!
        .whereType<TextSpan>()
        .map((s) => s.text)
        .join();
    expect(plain, 'a${markerA}b');
  });

  testWidgets('pillBuilder splices pills inline and counts occurrences', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    final seen = <String>[];
    final controller = NaiSyntaxController(text: 'x$markerA y $markerA$markerB')
      ..pillBuilder = (context, marker, occurrence) {
        seen.add('$marker#$occurrence');
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(
            key: Key('pill-$marker-$occurrence'),
            width: 10,
            height: 10,
          ),
        );
      };
    addTearDown(controller.dispose);

    final span = build(controller, context);
    final widgetSpans = span.children!.whereType<WidgetSpan>().toList();
    expect(widgetSpans.length, 3);
    // 同一字符第二次出现 occurrence=1，另一字符从 0 计
    expect(seen, ['$markerA#0', '$markerA#1', '$markerB#0']);
    // 文本片段仍保留在药丸两侧
    final plain = span.children!
        .whereType<TextSpan>()
        .map((s) => s.text)
        .join();
    expect(plain, 'x y ');
  });

  testWidgets('refreshPillSpans busts the cache and rebuilds pills', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    var pillWidth = 10.0;
    final controller = NaiSyntaxController(text: markerA)
      ..pillBuilder = (context, marker, occurrence) {
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(width: pillWidth, height: 10),
        );
      };
    addTearDown(controller.dispose);

    final first = build(controller, context);
    final firstPill =
        first.children!.whereType<WidgetSpan>().single.child as SizedBox;
    expect(firstPill.width, 10.0);

    // 文本与主题都没变：不刷新时拿到的是缓存（还是旧药丸）
    pillWidth = 20.0;
    final cached = build(controller, context);
    final cachedPill =
        cached.children!.whereType<WidgetSpan>().single.child as SizedBox;
    expect(cachedPill.width, 10.0);

    controller.refreshPillSpans();
    final rebuilt = build(controller, context);
    final rebuiltPill =
        rebuilt.children!.whereType<WidgetSpan>().single.child as SizedBox;
    expect(rebuiltPill.width, 20.0);
  });

  testWidgets('pills coexist with emphasis highlight around markers', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    final controller = NaiSyntaxController(text: '1.2::a$markerA b::')
      ..pillBuilder = (context, marker, occurrence) {
        return const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(width: 8, height: 8),
        );
      };
    addTearDown(controller.dispose);

    final span = build(controller, context);
    expect(span.children!.whereType<WidgetSpan>().length, 1);
    // 强调语法的文本片段依旧存在且带背景色（高亮未被药丸破坏）
    final highlighted = span.children!
        .whereType<TextSpan>()
        .where((s) => s.style?.backgroundColor != null)
        .toList();
    expect(highlighted, isNotEmpty);
  });
}
