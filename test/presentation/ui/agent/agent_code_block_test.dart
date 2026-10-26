// B07（10-24）：Agent 代码块自动换行、右上角单块复制；行内代码底色不盖住选区。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_thread.dart';

Future<void> _pump(WidgetTester t, String markdown, {double width = 320}) =>
    t.pumpWidget(
      MaterialApp(
        theme: GeistTheme.light,
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: AgentMarkdown(markdown, onOpenLink: (_) {}),
            ),
          ),
        ),
      ),
    );

void main() {
  const long =
      'bent over desk, from behind, hands on desk, arched back, '
      'looking back, blush, open mouth, sweat, indoors, office';

  testWidgets('长代码块在面板宽度内自动换行，不再横向滚动', (t) async {
    await _pump(t, '之前：\n\n```\n$long\n```\n\n现在：');
    final block = find.byKey(const Key('agent-code-block'));
    expect(block, findsOneWidget);
    expect(t.getSize(block).width, lessThanOrEqualTo(320));
    expect(
      find.descendant(
        of: block,
        matching: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
        ),
      ),
      findsNothing,
    );
    final text = find.descendant(of: block, matching: find.text(long));
    expect(t.getSize(text).height, greaterThan(30)); // 多行
    expect(t.takeException(), isNull);
  });

  testWidgets('右上角复制：只复制块内原文（不含围栏、语言名，保留缩进）', (t) async {
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    const code = 'first line\n  indented, 1.2::tag::\nlast';
    await _pump(t, '说明\n\n```text\n$code\n```\n\n第二块：\n\n```\nother\n```');
    expect(find.byKey(const Key('agent-code-copy')), findsNWidgets(2));
    await t.tap(find.byKey(const Key('agent-code-copy')).first);
    await t.pump();
    expect(copied, code);
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('行内代码底色半透明（选区画在文字底色下面，不透明会盖住）', (t) async {
    await _pump(t, '用 `1.2::blue eyes::` 这种写法');
    final rich = t
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text)
        .whereType<TextSpan>();
    Color? bg;
    for (final span in rich) {
      span.visitChildren((s) {
        if (s is TextSpan && s.text == '1.2::blue eyes::') {
          bg = s.style?.backgroundColor;
        }
        return true;
      });
      if (span.text == '1.2::blue eyes::') bg = span.style?.backgroundColor;
    }
    expect(bg, isNotNull);
    expect(bg!.a, lessThan(1));
  });
}
