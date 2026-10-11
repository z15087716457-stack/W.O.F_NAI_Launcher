import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_slider.dart';
import '../kit/ui_text.dart';
import 'refs_contract.dart';
import 'refs_format.dart';

/// 图片：铺满裁切；加载失败留控件底。
class RefsImage extends StatelessWidget {
  const RefsImage(
    this.image, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });
  final ImageProvider? image;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => image == null
      ? const SizedBox.expand()
      : Image(
          image: image!,
          fit: fit,
          alignment: alignment,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        );
}

/// 多选勾：22 圆、2px 白描边；勾上是强调色。
class RefsPickMark extends StatelessWidget {
  const RefsPickMark({super.key, required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? c.accent : const Color(0x38000000),
        shape: BoxShape.circle,
        border: Border.all(color: on ? c.accent : Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: on
          ? const UiGlyph(
              UiGlyphs.check,
              size: 12,
              strokeWidth: 3,
              color: Colors.white,
            )
          : null,
    );
  }
}

/// “✓ 在生图页”：20 高胶囊、强调色底。
class RefsInGenBadge extends StatelessWidget {
  const RefsInGenBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 20,
      padding: const EdgeInsets.only(left: 6, right: 7),
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          const UiGlyph(
            UiGlyphs.check,
            size: 10,
            strokeWidth: 3,
            color: Colors.white,
          ),
          Text(
            context.l10n.refs_inGeneration,
            style: UiText.sans(
              10.5,
              weight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 收藏星：24 白圆底；收藏了是实心琥珀星，否则灰色描边星。
class RefsStarButton extends StatelessWidget {
  const RefsStarButton({super.key, required this.on, this.onTap});
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final mark = Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xF0FFFFFF),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: UiGlyph(
        UiGlyphs.star,
        size: 13,
        filled: on,
        strokeWidth: 2,
        color: on ? c.star : const Color(0xFF777777),
      ),
    );
    if (onTap == null) return mark;
    return Tooltip(
      message: on ? context.l10n.refs_unfavorite : context.l10n.refs_favorite,
      child: UiPressable(onTap: onTap, builder: (_, _) => mark),
    );
  }
}

/// 图片上的深色角标：20 高、黑 72% + 模糊。
class RefsDarkBadge extends StatelessWidget {
  const RefsDarkBadge({super.key, required this.text, this.glyph, this.color});
  final String text;
  final String? glyph;
  final Color? color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        color: color ?? RefsPalette.badge,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (glyph != null)
              UiGlyph(glyph!, size: 11, strokeWidth: 2, color: Colors.white),
            Text(
              text,
              style: UiText.sans(
                10.5,
                weight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 卡片悬停操作条：34 高、圆角 9、黑 78% + 模糊、内边距 3、间距 2。
class RefsDarkBar extends StatelessWidget {
  const RefsDarkBar({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(9),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        color: RefsPalette.hoverBar,
        child: Row(spacing: 2, children: children),
      ),
    ),
  );
}

/// 操作条里的按钮：28 高、圆角 6；主按钮品牌色底。
class RefsBarButton extends StatelessWidget {
  const RefsBarButton({
    super.key,
    required this.glyph,
    this.label,
    this.onTap,
    this.primary = false,
    this.tooltip,
    this.glyphSize = 13,
  });
  final String glyph;
  final String? label;
  final VoidCallback? onTap;
  final bool primary;
  final String? tooltip;
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final b = UiPressable(
      onTap: onTap,
      builder: (context, hover) {
        final fg = onTap == null ? Colors.white54 : Colors.white;
        return Container(
          height: 28,
          constraints: const BoxConstraints(minWidth: 28),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary
                ? (onTap == null
                      ? c.brand.withValues(alpha: .45)
                      : hover
                      ? Color.lerp(c.brand, Colors.black, .08)
                      : c.brand)
                : (hover && onTap != null
                      ? Colors.white.withValues(alpha: .14)
                      : null),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              UiGlyph(
                glyph,
                size: glyphSize,
                strokeWidth: primary
                    ? 2.4
                    : glyph == UiGlyphs.more
                    ? 3
                    : 2,
                color: fg,
              ),
              if (label != null)
                Text(
                  label!,
                  maxLines: 1,
                  style: UiText.sans(12, weight: FontWeight.w500, color: fg),
                ),
            ],
          ),
        );
      },
    );
    return tooltip == null ? b : Tooltip(message: tooltip, child: b);
  }
}

/// 拖动时跟着指针的小图（多张时右上角写数量）。
class RefsDragFeedback extends StatelessWidget {
  const RefsDragFeedback({super.key, required this.image, required this.count});
  final ImageProvider? image;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Transform.rotate(
      angle: -.07,
      child: Container(
        width: 80,
        height: 100,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.control,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.dark ? .45 : .18),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: .92, child: RefsImage(image)),
            if (count > 1)
              Positioned(
                right: 6,
                top: 6,
                child: RefsDarkBadge(text: '$count', color: c.accent),
              ),
          ],
        ),
      ),
    );
  }
}

/// 编码状态的文案和色调（卡片标签、检查器提示框共用）。
class RefsEncodingInfo {
  const RefsEncodingInfo({
    required this.label,
    required this.title,
    required this.desc,
    required this.glyph,
    required this.tone,
    required this.ok,
  });
  final String label;
  final String title;
  final String desc;
  final String glyph;
  final UiMiniTone tone;
  final bool ok;

  static RefsEncodingInfo? of(
    BuildContext context,
    RefsEntry e,
    RefsModel m,
    RefsCosts k,
  ) {
    final l10n = context.l10n;
    if (!m.vibeUsable) {
      return RefsEncodingInfo(
        label: l10n.refs_encModelOff(m.shortName),
        title: l10n.refs_encModelOff(m.shortName),
        desc: l10n.refs_encModelOffDesc(m.shortName),
        glyph: UiGlyphs.alert,
        tone: UiMiniTone.warn,
        ok: false,
      );
    }
    return switch (e.encoding) {
      RefsEncoding.ready => RefsEncodingInfo(
        label: l10n.refs_encReadyShort(m.shortName),
        title: l10n.refs_encReady(m.shortName),
        desc: l10n.refs_encReadyDesc,
        glyph: UiGlyphs.check,
        tone: UiMiniTone.ok,
        ok: true,
      ),
      RefsEncoding.encodeOnUse => RefsEncodingInfo(
        label: l10n.refs_encOnUse,
        title: l10n.refs_encOnUse,
        desc: l10n.refs_encOnUseDesc(k.encode),
        glyph: UiGlyphs.bolt,
        tone: UiMiniTone.warn,
        ok: false,
      ),
      RefsEncoding.reencode => RefsEncodingInfo(
        label: l10n.refs_encRe,
        title: l10n.refs_encRe,
        desc: l10n.refs_encReDesc(e.encodedFor ?? '?', m.name, k.encode),
        glyph: UiGlyphs.bolt,
        tone: UiMiniTone.warn,
        ok: false,
      ),
      RefsEncoding.unusable => RefsEncodingInfo(
        label: l10n.refs_encUnusable(m.shortName),
        title: l10n.refs_encUnusable(m.shortName),
        desc: l10n.refs_encUnusableDesc(e.encodedFor ?? '?', m.name),
        glyph: UiGlyphs.alert,
        tone: UiMiniTone.error,
        ok: false,
      ),
      RefsEncoding.unknown => null,
    };
  }
}

/// 卡片名称行尾的编码标签：已编码、未知、或当前模型不能用 Vibe 时不出。
class RefsEncodingChip extends StatelessWidget {
  const RefsEncodingChip({super.key, required this.entry, required this.model});
  final RefsEntry entry;
  final RefsModel model;

  @override
  Widget build(BuildContext context) {
    if (!model.vibeUsable) return const SizedBox.shrink();
    final i = RefsEncodingInfo.of(context, entry, model, const RefsCosts());
    if (i == null || i.ok) return const SizedBox.shrink();
    return UiMini(i.label, tone: i.tone, glyph: i.glyph);
  }
}

/// 精准参考类型标签：18 高、圆角 4、类型色 11–12% 底。
class RefsTypeChip extends StatelessWidget {
  const RefsTypeChip(this.type, {super.key});
  final RefsPreciseType type;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final ink = RefsPalette.typeInk(type, c);
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: RefsPalette.type(
          type,
        ).withValues(alpha: type == RefsPreciseType.character ? .12 : .11),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          UiGlyph(
            RefsFormat.typeGlyph(type),
            size: 11,
            strokeWidth: 2,
            color: ink,
          ),
          Text(
            RefsFormat.type(context, type),
            style: UiText.sans(
              10.5,
              weight: FontWeight.w600,
              color: ink,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 参数块：标题行（12.5 / w600 + 数字框）· 滑杆 · 说明（11.5 弱色）。间距 5。
class RefsParam extends StatelessWidget {
  const RefsParam({
    super.key,
    required this.label,
    required this.value,
    this.defaultValue,
    this.onChanged,
    this.onSubmitted,
    this.desc,
    this.changed = false,
    this.mixed,
    this.max = 1,
    this.trailing,
  });
  final String label;
  final double value;
  final double? defaultValue;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onSubmitted;
  final String? desc;
  final bool changed;

  /// 多选“混合”：数字框写这段字、滑杆不画圆钮。
  final String? mixed;
  final double max;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 5,
      children: [
        Row(
          spacing: 6,
          children: [
            Text(
              label,
              style: UiText.sans(12.5, weight: FontWeight.w600, color: c.ink),
            ),
            if (trailing != null) trailing!,
            const Spacer(),
            UiNumBox(
              value: value,
              changed: changed,
              placeholder: mixed,
              max: max,
              onSubmitted: onSubmitted ?? onChanged,
            ),
          ],
        ),
        UiSlider(
          value: value,
          defaultValue: changed ? defaultValue : null,
          empty: mixed != null,
          onChanged: onChanged,
        ),
        if (desc != null)
          Text(desc!, style: UiText.sans(11.5, color: c.muted, height: 1.45)),
      ],
    );
  }
}

/// 抬起底小框：圆角 9、1px 描边、内边距 10 / 12。
class RefsBox extends StatelessWidget {
  const RefsBox({super.key, required this.child, this.color, this.border});
  final Widget child;
  final Color? color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color ?? c.raised,
        border: Border.all(color: border ?? c.line),
        borderRadius: BorderRadius.circular(9),
      ),
      child: child,
    );
  }
}

/// 编码状态框：22 圆角方块图标 + 标题 + 说明；需要编码且有原图时给“现在为 … 编码”。
class RefsEncodingBox extends StatelessWidget {
  const RefsEncodingBox({
    super.key,
    required this.entry,
    required this.model,
    required this.costs,
    this.onEncodeNow,
  });
  final RefsEntry entry;
  final RefsModel model;
  final RefsCosts costs;
  final VoidCallback? onEncodeNow;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final i = RefsEncodingInfo.of(context, entry, model, costs);
    if (i == null) return const SizedBox.shrink();
    final color = switch (i.tone) {
      UiMiniTone.ok => c.ok,
      UiMiniTone.error => c.error,
      _ => c.warn,
    };
    final canEncode =
        onEncodeNow != null &&
        model.vibeUsable &&
        (entry.encoding == RefsEncoding.encodeOnUse ||
            entry.encoding == RefsEncoding.reencode);
    return RefsBox(
      key: const Key('refs-encoding'),
      color: i.ok ? null : (i.tone == UiMiniTone.error ? null : c.warnBg),
      border: i.ok
          ? null
          : color.withValues(alpha: i.tone == UiMiniTone.error ? .3 : .28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 9,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(6),
            ),
            child: UiGlyph(i.glyph, size: 13, strokeWidth: 2.4, color: color),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.title,
                  style: UiText.sans(
                    12,
                    weight: FontWeight.w600,
                    color: c.ink,
                    height: 1.5,
                  ),
                ),
                Text(
                  i.desc,
                  style: UiText.sans(12, color: c.muted, height: 1.5),
                ),
                if (canEncode)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: UiBtn(
                      key: const Key('refs-encode-now'),
                      size: UiBtnSize.small,
                      onTap: onEncodeNow,
                      children: [
                        const UiGlyph(UiGlyphs.bolt, size: 13),
                        Text(l10n.refs_encodeNow(model.name, costs.encode)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 两列键值：标签弱色、值正文色；行距 5、列距 14、12 号字。
class RefsKv extends StatelessWidget {
  const RefsKv({super.key, required this.rows});
  final List<(String, Widget)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return DefaultTextStyle.merge(
      style: UiText.sans(12, color: c.ink, height: 1.5),
      child: Table(
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          for (final (i, (k, v)) in rows.indexed)
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 14, top: i == 0 ? 0 : 5),
                  child: Text(
                    k,
                    style: UiText.sans(12, color: c.muted, height: 1.5),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 5),
                  child: v,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 标签块：22 高、圆角 11、控件底；带删除叉。
class RefsTag extends StatelessWidget {
  const RefsTag(this.text, {super.key, this.onRemove});
  final String text;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 22,
      padding: EdgeInsets.only(left: 8, right: onRemove == null ? 8 : 5),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 3,
        children: [
          Text(text, style: UiText.sans(11.5, color: c.ink, height: 1.2)),
          if (onRemove != null)
            UiPressable(
              onTap: onRemove,
              builder: (_, hover) => UiGlyph(
                UiGlyphs.close,
                size: 10,
                strokeWidth: 2.4,
                color: hover ? c.ink : c.faint,
              ),
            ),
        ],
      ),
    );
  }
}

/// “＋ 标签”：虚线胶囊，点开就地输入，回车加一个、Esc / 失焦收起。
class RefsAddTag extends StatefulWidget {
  const RefsAddTag({
    super.key,
    required this.onAdd,
    this.startOpen = false,
    this.onClosed,
  });
  final ValueChanged<String> onAdd;

  /// 一出现就是输入框（多选“加标签”按钮点开后）。
  final bool startOpen;
  final VoidCallback? onClosed;

  @override
  State<RefsAddTag> createState() => _RefsAddTagState();
}

class _RefsAddTagState extends State<RefsAddTag> {
  TextEditingController? _ctrl;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _close();
    });
    if (widget.startOpen) {
      _ctrl = TextEditingController();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focus.requestFocus(),
      );
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _close() {
    final c = _ctrl;
    if (c == null) return;
    setState(() => _ctrl = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
    widget.onClosed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    if (_ctrl == null) {
      return UiPressable(
        key: const Key('refs-add-tag'),
        onTap: () {
          setState(() => _ctrl = TextEditingController());
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _focus.requestFocus(),
          );
        },
        builder: (context, hover) => CustomPaint(
          painter: _DashPill(c.strong),
          child: Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 3,
              children: [
                UiGlyph(
                  UiGlyphs.plus,
                  size: 10,
                  strokeWidth: 2.4,
                  color: hover ? c.ink : c.faint,
                ),
                Text(
                  l10n.refs_tag,
                  style: UiText.sans(
                    11.5,
                    color: hover ? c.ink : c.faint,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      height: 22,
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.accent),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.centerLeft,
      child: Focus(
        onKeyEvent: (_, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
            _focus.unfocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          key: const Key('refs-tag-input'),
          controller: _ctrl,
          focusNode: _focus,
          style: UiText.sans(11.5, color: c.ink, height: 1.2),
          cursorColor: c.accent,
          cursorHeight: 13,
          decoration: uiBareDecoration(),
          onSubmitted: (v) {
            final t = v.trim();
            if (t.isNotEmpty) widget.onAdd(t);
            _ctrl!.clear();
            _focus.requestFocus();
          },
        ),
      ),
    );
  }
}

class _DashPill extends CustomPainter {
  _DashPill(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          Radius.circular(size.height / 2),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 6) {
        canvas.drawPath(m.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashPill old) => old.color != color;
}

/// 16 格用量条：前 [free] 格强调色，超出的琥珀色。
class RefsMeter extends StatelessWidget {
  const RefsMeter({
    super.key,
    required this.used,
    required this.max,
    required this.free,
  });
  final int used;
  final int max;
  final int free;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        for (var i = 0; i < max; i++)
          Container(
            width: 5,
            height: 12,
            decoration: BoxDecoration(
              color: i >= used ? c.control : (i >= free ? c.warn : c.accent),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
      ],
    );
  }
}

/// 小节标题（检查器）：11.5 / w600 弱色。
class RefsSectionLabel extends StatelessWidget {
  const RefsSectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      spacing: 6,
      children: [
        Text(
          text,
          style: UiText.sans(11.5, weight: FontWeight.w600, color: c.muted),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}
