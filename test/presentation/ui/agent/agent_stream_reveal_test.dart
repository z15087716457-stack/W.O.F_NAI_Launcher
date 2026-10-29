import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_stream_reveal.dart';

import '../../../helpers/studio_capture_fonts.dart';

class _LayoutProbe extends SingleChildRenderObjectWidget {
  const _LayoutProbe({required this.onLayout, required super.child});
  final VoidCallback onLayout;
  @override
  RenderObject createRenderObject(BuildContext context) => _Probe(onLayout);
}

class _Probe extends RenderProxyBox {
  _Probe(this.onLayout);
  final VoidCallback onLayout;
  @override
  void performLayout() {
    onLayout();
    super.performLayout();
  }
}

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets(
    'long native selectable text reveals by paint without per-frame layout',
    (t) async {
      final initial = List.filled(250, '已有正文 English text。\n').join();
      final progress = AgentStreamProgress(const TestVSync(), initial);
      addTearDown(progress.dispose);
      var text = initial;
      var layouts = 0;
      late StateSetter update;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionArea(
              child: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return SingleChildScrollView(
                    child: SizedBox(
                      width: 320,
                      child: AgentStreamReveal(
                        progress: progress,
                        child: _LayoutProbe(
                          onLayout: () => layouts++,
                          child: Text(text),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      final target =
          '$initial新文字 e\u0301 👩‍💻\nEnglish wrapped content and 中文。';
      progress.update(target, animate: true);
      update(() => text = target);
      await t.pump();
      expect(layouts, greaterThan(0));
      layouts = 0;
      var previous = initial.runes.length;
      final boundaries = <int>{0};
      var offset = 0;
      for (final character in target.characters) {
        offset += character.length;
        boundaries.add(offset);
      }
      for (var frame = 0; frame < 7; frame++) {
        await t.pump(const Duration(milliseconds: 16));
        expect(
          progress.visibleCharacters,
          inInclusiveRange(previous, target.runes.length),
        );
        expect(boundaries, contains(progress.visibleOffset));
        previous = progress.visibleCharacters;
      }
      expect(layouts, 0, reason: 'animation must invalidate only paint');
      expect(progress.visibleOffset, target.length);
      expect(progress.visibleCharacters, target.runes.length);
      final paragraph = t.renderObject<RenderParagraph>(
        find.byType(RichText).first,
      );
      expect(
        paragraph.registrar,
        isNotNull,
        reason: 'native text selection remains registered',
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('replacement, completion and pause retain exact received text', (
    t,
  ) async {
    final progress = AgentStreamProgress(const TestVSync(), 'abc');
    addTearDown(progress.dispose);
    progress.update('abcdefghi', animate: true);
    await t.pump();
    await t.pump(const Duration(milliseconds: 32));
    expect(progress.visibleCharacters, lessThan(9));
    progress.finish();
    expect(progress.visibleCharacters, 9);
    await t.pump(const Duration(seconds: 1));
    expect(
      progress.visibleCharacters,
      9,
      reason: 'no synthetic growth during a pause',
    );
    progress.update('替换 👩‍💻', animate: true);
    expect(progress.visibleOffset, progress.text.length);
    progress.update('${progress.text} 新增', animate: false);
    expect(progress.visibleCharacters, progress.text.runes.length);
  });
}
