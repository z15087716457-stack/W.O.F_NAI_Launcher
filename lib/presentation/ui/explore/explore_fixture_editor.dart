import 'package:flutter/material.dart';

import '../../widgets/common/studio_icons.dart';
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_svg_icon.dart';
import '../kit/ui_text.dart';
import 'explore_contract.dart';
import 'explore_editor.dart';
import 'explore_fixture.dart';
import 'explore_format.dart';

/// 预览和截图用的编辑列：照原型画出生图页的模块（静态，不可编辑），中间插本页的“随机变量”和生成条。
/// 真实应用里由接线方用生图页的组件拼（见接线说明），这里的文字不进 ARB。
Widget exploreFixtureEditor(
  BuildContext context,
  ExploreEditorParts parts, {
  bool v45 = false,
}) => _FixtureEditor(parts: parts, v45: v45);

class _FixtureEditor extends StatelessWidget {
  const _FixtureEditor({required this.parts, required this.v45});
  final ExploreEditorParts parts;
  final bool v45;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(v45: v45),
        Expanded(
          child: ClipRect(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  const _Prompt(),
                  parts.randomVariables,
                  const _Character(),
                  _Refs(v45: v45),
                  const _ImageModule(),
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.bg,
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              const _Sum('步数', Text('28')),
              const _Sum('引导', Text('5.0')),
              _Sum(
                '种子',
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    UiGlyph(UiGlyphs.dice, size: 12, color: c.ink),
                    const Text('随机'),
                  ],
                ),
              ),
              const Expanded(child: _Sum('采样器', Text('DPM++ 2M SDE'))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: UiGlyph(
                    UiGlyphs.chevronUp,
                    size: 15,
                    strokeWidth: 2.2,
                    color: c.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        parts.generateBar,
      ],
    );
  }
}

class _Sum extends StatelessWidget {
  const _Sum(this.label, this.value);
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: UiText.sans(
              11,
              weight: FontWeight.w500,
              color: c.ink.withValues(alpha: .55),
              height: 1.4,
            ),
          ),
          DefaultTextStyle.merge(
            style: UiText.sans(
              12,
              weight: FontWeight.w500,
              color: c.ink,
              height: 1.4,
            ),
            maxLines: 1,
            child: value,
          ),
        ],
      ),
    );
  }
}

/// 模型胶囊 + 额度胶囊（原型 `.lh` / `.cap`）。
class _Header extends StatelessWidget {
  const _Header({required this.v45});
  final bool v45;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final capb = ExploreFormat.capsuleBorder(c);
    Widget cap(List<Widget> children) => Container(
      height: 28,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: capb),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle.merge(
        style: UiText.sans(12, color: c.ink),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
    Widget vs() => Container(width: 1, height: 16, color: capb);
    return Container(
      constraints: const BoxConstraints(minHeight: 37),
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          cap([
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 6),
              child: Text(
                'Model',
                style: UiText.sans(12, color: c.ink.withValues(alpha: .55)),
              ),
            ),
            Container(
              height: 22,
              margin: const EdgeInsets.only(right: 3),
              padding: const EdgeInsets.only(left: 7, right: 4),
              decoration: BoxDecoration(
                color: c.ink,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                spacing: 5,
                children: [
                  // 素材是纯黑剪影，按反色内胆底色着色（同生图页 header_capsules）。
                  UiSvgIcon.asset(
                    'assets/icons/novelai-icon.svg',
                    size: 13,
                    colorFilter: ColorFilter.mode(c.bg, BlendMode.srcIn),
                  ),
                  Text(
                    v45 ? 'V4.5 Full' : 'V5 Full',
                    style: UiText.sans(
                      12,
                      weight: FontWeight.w700,
                      color: c.bg,
                    ),
                  ),
                  UiGlyph(
                    UiGlyphs.chevronDown,
                    size: 14,
                    strokeWidth: 2.4,
                    color: c.bg,
                  ),
                ],
              ),
            ),
            vs(),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 9),
              child: Row(
                spacing: 5,
                children: [
                  // 素材是白色填充，按文字色着色。
                  UiSvgIcon.asset(
                    'assets/icons/nai-icon-sakura.svg',
                    size: 13,
                    colorFilter: ColorFilter.mode(c.muted, BlendMode.srcIn),
                  ),
                  Text(
                    'Anime',
                    style: UiText.sans(
                      12,
                      weight: FontWeight.w700,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const Spacer(),
          cap([
            if (!v45) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  spacing: 4,
                  children: [
                    UiGlyph(UiGlyphs.bolt, size: 13, color: c.accent),
                    Text(
                      '147%',
                      style: UiText.sans(
                        12,
                        weight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
              ),
              vs(),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                spacing: 4,
                children: [
                  UiSvgIcon.asset(
                    'assets/icons/nai-icon-anlas.svg',
                    size: 12,
                    colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
                  ),
                  Text(
                    '2,218',
                    style: UiText.sans(
                      12,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

Widget _ib(
  BuildContext context,
  String glyph, {
  double size = 15,
  Color? color,
}) => SizedBox(
  width: 28,
  height: 28,
  child: Center(
    child: UiGlyph(glyph, size: size, color: color ?? context.ui.muted),
  ),
);

class _Prompt extends StatelessWidget {
  const _Prompt();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    TextSpan hl(String t, Color color, double a) => TextSpan(
      text: t,
      style: TextStyle(
        backgroundColor: color.withValues(alpha: a + (c.dark ? .1 : 0)),
      ),
    );
    const orange = Color(0xFFED5807);
    const blue = Color(0xFF079CED);
    WidgetSpan pill(ExploreVariable v) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: UiBlockPill(
          label: v.title,
          color: v.color,
          icon: v.icon,
          badge: v.evolution ? UiBlockBadge.evolution : UiBlockBadge.random,
        ),
      ),
    );
    Widget tab(String t, bool on) => Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? ExploreFormat.selected(c) : null,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        t,
        style: UiText.sans(
          13,
          weight: on ? FontWeight.w700 : FontWeight.w500,
          color: on ? c.ink : c.ink.withValues(alpha: .55),
        ),
      ),
    );
    return ExploreModule(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
            child: Row(
              spacing: 2,
              children: [
                tab('基础提示词', true),
                tab('负面', false),
                _ib(context, UiGlyphs.link),
                const Spacer(),
                _ib(context, UiGlyphs.archive, size: 16),
                _ib(context, UiGlyphs.grid),
                _ib(context, UiGlyphs.expand),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text:
                        'scenery, panorama, from behind, green theme, blue theme, plant, detailed background, ',
                  ),
                  hl('(extremely vibrant colors)', orange, .2),
                  const TextSpan(
                    text:
                        ', magical atmosphere, dynamic composition, sitting, wide shot, white dress, blue flower, frilled dress, giant, ',
                  ),
                  hl('0.8::artist:sincos::', blue, .28),
                  const TextSpan(text: ' '),
                  pill(ExploreFixture.variables[0]),
                  const TextSpan(text: ' '),
                  pill(ExploreFixture.variables[1]),
                  const TextSpan(
                    text:
                        '\nartist:asteroid_ill, candid, year 2025, very aesthetic, masterpiece, sketch, lineart, solo, no text',
                  ),
                ],
              ),
              style: UiText.sans(13, color: c.ink, height: 1.5),
            ),
          ),
          Container(
            height: 3,
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            decoration: BoxDecoration(
              color: c.control,
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: .18,
              child: Container(color: c.ink.withValues(alpha: .85)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Character extends StatelessWidget {
  const _Character();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    const orange = Color(0xFFED5807);
    const blue = Color(0xFF079CED);
    TextSpan hl(String t, Color color, double a) => TextSpan(
      text: t,
      style: TextStyle(
        backgroundColor: color.withValues(alpha: a + (c.dark ? .1 : 0)),
      ),
    );
    return ExploreModule(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExploreModuleHeader(
            children: [
              const Text('角色提示词'),
              Container(
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.control,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '1',
                  style: UiText.sans(
                    11,
                    weight: FontWeight.w600,
                    color: c.muted,
                    height: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text('AI 选择', style: UiText.sans(12, color: c.muted)),
              _ib(context, UiGlyphs.chevronDown),
              _ib(context, UiGlyphs.plus, size: 17, color: c.ink),
            ],
          ),
          Container(height: 1, color: c.line),
          SizedBox(
            height: 62,
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0, .55, 1],
              ).createShader(r),
              blendMode: BlendMode.dstIn,
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 14, 0),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'girl, '),
                        hl('1.5::loli, child', orange, .36),
                        const TextSpan(text: '::, '),
                        hl('1.4::silver hair', orange, .3),
                        const TextSpan(text: '::, '),
                        hl('1.3::long hair', orange, .26),
                        const TextSpan(text: '::, '),
                        hl('0.3::fluffy hair, messy hair', blue, .48),
                        const TextSpan(
                          text:
                              '::, pale skin, hair between eyes, blue eyes, blush, black capelet, blue butterfly brooch, white blouse',
                        ),
                      ],
                    ),
                    style: UiText.sans(12.5, color: c.ink, height: 1.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Refs extends StatelessWidget {
  const _Refs({required this.v45});
  final bool v45;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget row(IconData icon, String name, String desc, List<Widget> tail) =>
        Container(
          height: 44,
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Row(
            spacing: 10,
            children: [
              Icon(icon, size: 18, color: c.ink),
              Text(
                name,
                style: UiText.sans(13, weight: FontWeight.w500, color: c.ink),
              ),
              Expanded(
                child: Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12, color: c.muted),
                ),
              ),
              ...tail,
            ],
          ),
        );
    return ExploreModule(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExploreModuleHeader(children: [Text('参考图')]),
          row(StudioIcons.imageToImage, '图生图', '基于原图生成变体', [
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                spacing: 5,
                children: [
                  UiGlyph(
                    'M12 16V4M7 9l5-5 5 5M5 20h14',
                    size: 15,
                    color: c.accent,
                  ),
                  Text(
                    '上传',
                    style: UiText.sans(
                      13,
                      weight: FontWeight.w500,
                      color: c.accent,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          if (v45) ...[
            row(StudioIcons.styleTransfer, '风格迁移', '改变图像，保留视觉风格', [
              _ib(context, UiGlyphs.chevronDown),
            ]),
            row(StudioIcons.referenceFocus, '精准参考', '绑定角色或风格参考', [
              _ib(context, UiGlyphs.plus),
              _ib(context, UiGlyphs.chevronDown),
            ]),
          ],
        ],
      ),
    );
  }
}

class _ImageModule extends StatelessWidget {
  const _ImageModule();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget inp(String v) => Container(
      height: 32,
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(v, style: UiText.mono(12.5, color: c.ink)),
    );
    Widget seg(String glyph, bool on) => Container(
      width: 32,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? (c.dark ? c.hover : c.raised) : null,
        borderRadius: BorderRadius.circular(4),
        boxShadow: on && !c.dark
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: UiGlyph(glyph, size: 15, color: on ? c.ink : c.muted),
    );
    return ExploreModule(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExploreModuleHeader(children: [Text('图像')]),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: LayoutBuilder(
              builder: (context, box) => Row(
                spacing: box.maxWidth < 330 ? 4 : 6,
                children: [
                  Container(
                    width: 80,
                    height: 32,
                    padding: const EdgeInsets.only(left: 10, right: 8),
                    decoration: BoxDecoration(
                      color: c.control,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        Text('常规', style: UiText.sans(13, color: c.ink)),
                        const Spacer(),
                        UiGlyph(UiGlyphs.chevronDown, size: 14, color: c.muted),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: c.control,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      spacing: 2,
                      children: [
                        seg(UiGlyphs.landscape, false),
                        seg(UiGlyphs.portrait, true),
                        seg(UiGlyphs.square, false),
                      ],
                    ),
                  ),
                  const Spacer(),
                  inp('832'),
                  Text('×', style: UiText.sans(13, color: c.muted)),
                  inp('1216'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
