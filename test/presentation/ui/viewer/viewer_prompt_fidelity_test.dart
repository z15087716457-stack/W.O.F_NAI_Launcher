// B07（10-24）：大图详情的提示词只换样式不改字；权重底色半透明，框选不被盖住。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_prompt.dart';

String _plain(List<InlineSpan> spans) =>
    TextSpan(children: spans).toPlainText(includeSemanticsLabels: false);

void main() {
  final c = UiColors.fromTheme(GeistTheme.light);
  const samples = [
    'girl, 2::aokumo rin::,2::nude::,clitoris, 1.7::white skin::',
    '  leading and trailing  \n\n\n\nblank lines kept\n',
    '-2::flat color, logo::, 0.6::hwansang::, .5::no zero::',
    'unclosed 1.5::blue eyes, {{{nested (paren)}}}, [[x]]',
    'artist:chen_bin, 1.2::artist:shion(mirudakemann)::, plain',
  ];

  for (final hl in [true, false]) {
    test('highlight=$hl：纯文本与原始提示词逐字一致', () {
      for (final s in samples) {
        expect(_plain(viewerPromptSpans(s, c: c, highlight: hl)), s);
      }
    });
  }

  test('权重组保留 :: 并按大于 1 / 小于 1 / 负数分色', () {
    final spans = viewerPromptSpans(
      '2::a::,0.5::b::,-1::c::',
      c: c,
      highlight: true,
    );
    final groups = spans.whereType<TextSpan>().where(
      (s) => s.style?.background != null,
    );
    expect(groups, hasLength(3));
    expect(groups.map(_plainOne), ['2::a::', '0.5::b::', '-1::c::']);
  });

  test('权重底色半透明，叠在卡片底上与原色板一致', () {
    final spans = viewerPromptSpans('2::a::', c: c, highlight: true);
    final bg = (spans.single as TextSpan).style!.background!.color;
    expect(bg.a, lessThan(1));
    // alpha 合成回卡片底色后与原不透明色差不超过 1/255。
    final blended = Color.alphaBlend(bg, c.card);
    expect((blended.r - c.weightUp.r).abs(), lessThanOrEqualTo(1.5 / 255));
    expect((blended.g - c.weightUp.g).abs(), lessThanOrEqualTo(1.5 / 255));
    expect((blended.b - c.weightUp.b).abs(), lessThanOrEqualTo(1.5 / 255));
  });
}

String _plainOne(TextSpan s) => s.toPlainText(includeSemanticsLabels: false);
