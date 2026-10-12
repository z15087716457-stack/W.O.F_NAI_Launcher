import 'package:flutter/material.dart';

import '../kit/ui_colors.dart';
import '../kit/ui_text.dart';
import 'gen_contract.dart';
import 'gen_format.dart';

/// 预览和截图用的编辑器：照原型画出提示词文字和权重高亮（静态，不可编辑）。
/// 真实应用里由接线方用现有编辑器（药丸、补全、翻译叠字）填槽位，这里的文字不进 ARB。
class GenFixtureEditor extends StatelessWidget {
  const GenFixtureEditor({super.key, required this.target, this.empty = false});
  final GenEditorTarget target;

  /// 已清空：显示占位提示。
  final bool empty;

  static Widget builder(BuildContext context, GenEditorTarget target) =>
      GenFixtureEditor(target: target);

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final style = UiText.sans(
      target.fullscreen ? 14 : 13,
      color: c.ink,
      height: 1.38,
    );
    if (empty) {
      return Text(
        target.negative ? 'lowres, bad anatomy …' : '1girl, scenery …',
        style: style.copyWith(color: c.faint),
      );
    }
    TextSpan o(String t, double a) => TextSpan(
      text: t,
      style: TextStyle(backgroundColor: GenFormat.up(c, a)),
    );
    TextSpan b(String t, double a) => TextSpan(
      text: t,
      style: TextStyle(backgroundColor: GenFormat.down(c, a)),
    );
    const g = TextSpan(
      text: '::',
      style: TextStyle(backgroundColor: GenFormat.colons),
    );
    final ch = target.character ?? 0;
    if (ch > 0 && !target.negative) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: ch == 1 ? 'boy, ' : 'cat, '),
            o(ch == 1 ? '1.2::black hair' : '1.3::white fur', .26),
            g,
            TextSpan(
              text: ch == 1
                  ? ', short hair, red eyes, school uniform, holding umbrella'
                  : ', sitting, curled tail, looking at viewer',
            ),
          ],
        ),
        style: style,
      );
    }
    final spans = switch ((target.isBase, target.negative)) {
      (true, false) => <InlineSpan>[
        const TextSpan(
          text:
              'scenery,panorama,from behind,green theme, blue theme, plant,\n'
              'detailed background,',
        ),
        o('(extremely vibrant colors)', .2),
        const TextSpan(
          text:
              ', magical atmosphere, dynamic composition,sitting,wide shot, '
              'white dress,blue flower,frilled dress,giant,',
        ),
        b('0.8::artist:sincos', .28),
        g,
        const TextSpan(
          text:
              '\n\nartist:asteroid_ill,candid,,year 2025, very aesthetic, '
              'masterpiece,sketch,lineart,solo, very aesthetic, masterpiece, no text',
        ),
      ],
      (true, true) => const <InlineSpan>[
        TextSpan(
          text:
              'lowres, artistic error, scan artifacts, worst quality, bad quality, '
              'jpeg artifacts, multiple views, very displeasing, too many watermarks, '
              'negative space, blank page',
        ),
      ],
      (false, false) => <InlineSpan>[
        const TextSpan(text: 'girl, '),
        o('1.5::loli,child', .36),
        g,
        const TextSpan(text: ', '),
        o('1.4::silver hair', .3),
        g,
        const TextSpan(text: ', '),
        o('1.3::long hair', .26),
        g,
        const TextSpan(text: ',\n'),
        b('0.3::fluffy hair, messy hair', .48),
        g,
        const TextSpan(
          text:
              ', pale skin, hair between eyes, blue eyes, blush,  black capelet, '
              'blue butterfly brooch, white blouse, ruffled shirt, long sleeves, '
              'frilled cuffs, collar bow, black bow, high-waist skirt, black pinstripe '
              'skirt, pleated skirt, frilled hem, ',
        ),
        o('2::black pantyhose', .55),
        g,
        const TextSpan(text: ', black mary janes, '),
        b('-1::twintails, headpiece, headdress', .62),
        g,
      ],
      (false, true) => <InlineSpan>[
        TextSpan(
          text: 'hat, ',
          style: TextStyle(color: c.ink),
        ),
        const TextSpan(text: 'short hair'),
      ],
    };
    return Text.rich(TextSpan(children: spans), style: style);
  }
}
