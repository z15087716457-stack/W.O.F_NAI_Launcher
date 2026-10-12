import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_text.dart';
import 'explore_contract.dart';
import 'explore_format.dart';

/// 计数徽章（原型 `.cnt`）：最小 18 × 18、圆角 9、控件底、11 / w600 次要色。
class ExploreCount extends StatelessWidget {
  const ExploreCount(this.count, {super.key, this.color, this.background});
  final int count;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 18,
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: background ?? c.control,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          '$count',
          style: UiText.sans(
            11,
            weight: FontWeight.w600,
            color: color ?? c.muted,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// 画师小块（原型 `.ar`）：24 高、圆角 6、控件底、12 / w500；权重 Geist Mono 11 次要色在前。
/// [highlight] 用于“变了的画师”（子代来源色 14% 底 + 来源色字）。
class ExploreAtomChip extends StatelessWidget {
  const ExploreAtomChip(
    this.atom, {
    super.key,
    this.highlight,
    this.background,
    this.border,
    this.trailing,
    this.struck = false,
    this.onTap,
  });
  final ExploreAtom atom;
  final Color? highlight;
  final Color? background;
  final Color? border;
  final Widget? trailing;

  /// 存为块里去掉的画师：弱色删除线。
  final bool struck;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final h = highlight;
    final ink = struck ? c.faint : (h ?? c.ink);
    Widget chip(bool hover) => Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: h != null
            ? h.withValues(alpha: .14)
            : (hover ? c.hover : (background ?? c.control)),
        border: border == null ? null : Border.all(color: border!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (atom.weight != null)
            Text(
              atom.weight!,
              style: UiText.mono(
                11,
                weight: FontWeight.w500,
                color: struck ? c.faint : (h ?? c.muted),
                height: 1.2,
              ),
            ),
          Flexible(
            child: Text(
              atom.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  UiText.sans(
                    12,
                    weight: FontWeight.w500,
                    color: ink,
                    height: 1.2,
                  ).copyWith(
                    decoration: struck ? TextDecoration.lineThrough : null,
                    decorationColor: c.faint,
                  ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
    return Tooltip(
      message: atom.raw,
      waitDuration: const Duration(milliseconds: 600),
      child: onTap == null
          ? chip(false)
          : UiPressable(onTap: onTap, builder: (context, hover) => chip(hover)),
    );
  }
}

/// 一行画师串（候选卡下方、父本行）：权重 Geist Mono 10.5 弱色，画师之间“ · ”用较深描边色。
class ExploreArtistsText extends StatelessWidget {
  const ExploreArtistsText(
    this.atoms, {
    super.key,
    this.maxLines = 2,
    this.size = 11.5,
    this.color,
    this.textAlign = TextAlign.start,
    this.empty,
  });
  final List<ExploreAtom> atoms;
  final int maxLines;
  final double size;
  final Color? color;
  final TextAlign textAlign;

  /// 没有画师时显示的文字（默认什么都不写）。
  final String? empty;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final spans = <InlineSpan>[];
    for (final (i, a) in atoms.indexed) {
      if (i > 0) {
        spans.add(
          TextSpan(
            text: ' · ',
            style: TextStyle(color: c.strong),
          ),
        );
      }
      if (a.weight != null) {
        spans.add(
          TextSpan(
            text: '${a.weight} ',
            style: UiText.mono(
              size - 1,
              weight: FontWeight.w500,
              color: c.faint,
            ),
          ),
        );
      }
      spans.add(TextSpan(text: a.text));
    }
    if (spans.isEmpty && empty != null) {
      spans.add(
        TextSpan(
          text: empty,
          style: TextStyle(color: c.faint),
        ),
      );
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: UiText.sans(size, color: color ?? c.ink),
    );
  }
}

/// 小节标题（原型 `.sect`）：11.5 / w600 次要色、字距 0.02em，右边可放链接。
class ExploreSect extends StatelessWidget {
  const ExploreSect(this.title, {super.key, this.trailing, this.color});
  final String title;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final text = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: UiText.sans(
        11.5,
        weight: FontWeight.w600,
        color: color ?? c.muted,
        letterSpacing: .23,
      ),
    );
    if (trailing == null) return text;
    return Row(
      spacing: 6,
      children: [
        Expanded(child: text),
        trailing!,
      ],
    );
  }
}

/// 小节右侧的文字链接（“复制画师串”）：11 / w500 强调色，前面 12px 图标。
class ExploreLink extends StatelessWidget {
  const ExploreLink({
    super.key,
    required this.label,
    required this.onTap,
    this.glyph,
  });
  final String label;
  final String? glyph;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (glyph != null) UiGlyph(glyph!, size: 12, color: c.accent),
          Text(
            label,
            style: UiText.sans(
              11,
              weight: FontWeight.w500,
              color: c.accent,
            ).copyWith(decoration: hover ? TextDecoration.underline : null),
          ),
        ],
      ),
    );
  }
}

/// 抬起底的小框（原型 `.blk`）：圆角 8、1px 描边、内边距 9 / 10、内容间距 6。
class ExploreBox extends StatelessWidget {
  const ExploreBox({
    super.key,
    required this.children,
    this.background,
    this.gap = 6,
  });
  final List<Widget> children;
  final Color? background;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: background ?? c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: gap,
        children: children,
      ),
    );
  }
}

/// “本张抽到”的一块：块药丸 + 抽到的画师（没抽中写一句）。
class ExploreDrawBox extends StatelessWidget {
  const ExploreDrawBox(this.draw, {super.key});
  final ExploreDraw draw;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return ExploreBox(
      children: [
        UiBlockPill(
          label: draw.title,
          color: draw.color,
          icon: draw.icon,
          badge: draw.evolution ? UiBlockBadge.evolution : UiBlockBadge.random,
        ),
        if (draw.atoms.isEmpty)
          Text(l.explore_drawEmpty, style: UiText.sans(12, color: c.faint))
        else
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [for (final a in draw.atoms) ExploreAtomChip(a)],
          ),
      ],
    );
  }
}

/// 操作格（原型 `.act`）：34 高、圆角 7、抬起底 + 描边、12.5 / w500、图标 15、间距 7，右侧可放键帽。
class ExploreActTile extends StatelessWidget {
  const ExploreActTile({
    super.key,
    required this.glyph,
    required this.label,
    this.onTap,
    this.keyLabel,
    this.color,
    this.on = false,
    this.filled = false,
  });
  final String glyph;
  final String label;
  final VoidCallback? onTap;
  final String? keyLabel;

  /// 文字和图标色（“加入进化”紫）。
  final Color? color;

  /// 已收藏：收藏红字 + 红 40% 描边 + 红 6% 底。
  final bool on;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final ink = on ? c.fav : (color ?? c.ink);
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: on
              ? Color.alphaBlend(c.fav.withValues(alpha: .06), c.raised)
              : (hover ? c.hover : c.raised),
          border: Border.all(color: on ? c.fav.withValues(alpha: .4) : c.line),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          spacing: 7,
          children: [
            UiGlyph(glyph, size: 15, color: ink, filled: filled),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(12.5, weight: FontWeight.w500, color: ink),
              ),
            ),
            if (keyLabel != null) UiKeycap(keyLabel!),
          ],
        ),
      ),
    );
  }
}

/// 张数步进（原型 `.st2`）：控件底、圆角 6、左右箭头 22 × 28、数字 Geist Mono 13 / w600。
class ExploreStepper extends StatelessWidget {
  const ExploreStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 100,
    this.height = 32,
    this.bordered = false,
    this.keyPrefix = 'explore-count',
  });
  final int value;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;
  final double height;
  final bool bordered;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final enabled = onChanged != null;
    Widget arrow(String glyph, int delta, String key) {
      final next = (value + delta).clamp(min, max);
      return UiPressable(
        key: Key('$keyPrefix-$key'),
        onTap: enabled && next != value ? () => onChanged!(next) : null,
        builder: (context, hover) => SizedBox(
          width: 22,
          height: 28,
          child: Center(
            child: UiGlyph(
              glyph,
              size: 13,
              color: !enabled || next == value
                  ? c.faint
                  : (hover ? c.ink : c.muted),
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: bordered ? c.raised : c.control,
        border: bordered ? Border.all(color: c.line) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(UiGlyphs.chevronLeft, -1, 'down'),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 34),
            child: Text(
              '$value',
              key: Key('$keyPrefix-value'),
              textAlign: TextAlign.center,
              style: UiText.mono(
                13,
                weight: FontWeight.w600,
                color: enabled ? c.ink : c.muted,
              ),
            ),
          ),
          arrow(UiGlyphs.chevronRight, 1, 'up'),
        ],
      ),
    );
  }
}

enum ExplorePillTone { run, pause, error, evo }

/// 状态小胶囊（原型 `.pill2`）：20 高、圆角 10、11 / w600。
class ExplorePill extends StatelessWidget {
  const ExplorePill(this.text, {super.key, required this.tone});
  final String text;
  final ExplorePillTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final (bg, fg) = switch (tone) {
      ExplorePillTone.run => (c.accent.withValues(alpha: .12), c.accent),
      ExplorePillTone.pause => (c.warn.withValues(alpha: .14), c.warn),
      ExplorePillTone.error => (c.error.withValues(alpha: .10), c.error),
      ExplorePillTone.evo => (c.evoBg, c.evo),
    };
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          maxLines: 1,
          style: UiText.sans(11, weight: FontWeight.w600, color: fg, height: 1),
        ),
      ),
    );
  }
}

/// 子代来源角标（原型 `.op`）：19 高、圆角 5、10.5 / w600 白字。
class ExploreOpBadge extends StatelessWidget {
  const ExploreOpBadge(this.op, {super.key});
  final ExploreOp op;

  @override
  Widget build(BuildContext context) => Container(
    height: 19,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: ExploreFormat.opColor(op),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Center(
      widthFactor: 1,
      child: Text(
        ExploreFormat.opLabel(context.l10n, op),
        style: UiText.sans(
          10.5,
          weight: FontWeight.w600,
          color: Colors.white,
          height: 1,
        ),
      ),
    ),
  );
}

/// 代标签（原型 `.gtag`）：22 高、圆角 6、12 / w700；当前代紫底，历史代控件底次要色。
class ExploreGenTag extends StatelessWidget {
  const ExploreGenTag(this.text, {super.key, this.current = true});
  final String text;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: current ? c.evo : c.control,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          style: UiText.sans(
            12,
            weight: FontWeight.w700,
            color: current ? c.onEvo : c.muted,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// 偏好条（原型 `.pref`）：4 高、圆角 2、控件底、紫色填充。
class ExplorePrefBar extends StatelessWidget {
  const ExplorePrefBar(this.value, {super.key, this.height = 4});

  /// 0–1。
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: c.control,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0, 1),
            child: ColoredBox(color: c.evo),
          ),
        ),
      ),
    );
  }
}

/// 图片（[fit] 铺满或完整显示），没有图时控件底。
class ExploreImage extends StatelessWidget {
  const ExploreImage(
    this.image, {
    super.key,
    this.fit = BoxFit.cover,
    this.radius = 0,
  });
  final ImageProvider? image;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final img = image;
    final child = img == null
        ? ColoredBox(color: c.control)
        : Image(
            image: img,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => ColoredBox(color: c.control),
          );
    return radius == 0
        ? child
        : ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}

/// 完整提示词：本张抽到的片段按块色 22% 高亮。
class ExplorePromptText extends StatelessWidget {
  const ExplorePromptText({
    super.key,
    required this.text,
    this.hits = const [],
    this.style,
  });
  final String text;
  final List<ExploreHit> hits;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final sorted = [...hits]..sort((a, b) => a.start.compareTo(b.start));
    final spans = <InlineSpan>[];
    var at = 0;
    for (final h in sorted) {
      if (h.start < at || h.end > text.length || h.start >= h.end) continue;
      if (h.start > at) spans.add(TextSpan(text: text.substring(at, h.start)));
      spans.add(
        TextSpan(
          text: text.substring(h.start, h.end),
          style: TextStyle(
            backgroundColor: h.color.withValues(alpha: c.dark ? .32 : .22),
          ),
        ),
      );
      at = h.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(
      TextSpan(children: spans),
      style: style ?? UiText.sans(12, color: c.ink, height: 1.6),
    );
  }
}

/// 舞台筛选胶囊（原型 `.chip`）：28 高、圆角 14、12.5；选中正文色实心 + 窗口底色字 w600，
/// 计数 Geist Mono 11（75%）。[dashed] 是“+ 分组”。
class ExploreChip extends StatelessWidget {
  const ExploreChip({
    super.key,
    required this.label,
    this.selected = false,
    this.count,
    this.countText,
    this.leading,
    this.onTap,
    this.onSecondaryTap,
    this.dashed = false,
    this.selectedColor,
    this.selectedInk,
  });
  final String label;
  final bool selected;
  final int? count;

  /// 文字计数（进化线的 “G3”）。
  final String? countText;
  final Widget? leading;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onSecondaryTap;
  final bool dashed;
  final Color? selectedColor;
  final Color? selectedInk;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final n = countText ?? (count == null ? null : '$count');
    return GestureDetector(
      onSecondaryTapUp: onSecondaryTap == null
          ? null
          : (d) => onSecondaryTap!(d.globalPosition),
      child: UiPressable(
        onTap: onTap,
        builder: (context, hover) {
          final fg = selected
              ? (selectedInk ?? c.bg)
              : (dashed ? c.faint : (hover ? c.ink : c.muted));
          final chip = Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected
                  ? (selectedColor ?? c.ink)
                  : (hover ? c.hover : null),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                ?leading,
                Text(
                  label,
                  maxLines: 1,
                  style: UiText.sans(
                    12.5,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: fg,
                  ),
                ),
                if (n != null)
                  Opacity(
                    opacity: .75,
                    child: Text(
                      n,
                      style: UiText.mono(11, color: fg, height: 1.2),
                    ),
                  ),
              ],
            ),
          );
          return dashed
              ? CustomPaint(
                  foregroundPainter: _DashPainter(c.strong),
                  child: chip,
                )
              : chip;
        },
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
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
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 6) {
        canvas.drawPath(m.extractPath(d, d + 3), p);
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// 输入胶囊（新分组 / 改名）：28 高、圆角 14、强调色描边；回车提交、Esc 或失焦取消（失焦时有字也提交）。
class ExploreInlineInput extends StatefulWidget {
  const ExploreInlineInput({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    this.initial = '',
    this.hint,
    this.width = 120,
    this.height = 28,
    this.radius = 14,
    this.style,
  });
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  final String initial;
  final String? hint;
  final double width;
  final double height;
  final double radius;
  final TextStyle? style;

  @override
  State<ExploreInlineInput> createState() => _ExploreInlineInputState();
}

class _ExploreInlineInputState extends State<ExploreInlineInput> {
  late final _ctrl = TextEditingController(text: widget.initial)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initial.length,
    );
  final _focus = FocusNode();
  var _done = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _finish(_ctrl.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _finish(String v) {
    if (_done) return;
    _done = true;
    final t = v.trim();
    if (t.isEmpty || t == widget.initial.trim()) {
      widget.onCancel();
    } else {
      widget.onSubmit(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.accent),
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: [
          BoxShadow(color: c.accent.withValues(alpha: .15), spreadRadius: 3),
        ],
      ),
      child: Focus(
        onKeyEvent: (_, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
            _done = true;
            widget.onCancel();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _ctrl,
          focusNode: _focus,
          style: widget.style ?? UiText.sans(12.5, color: c.ink),
          cursorColor: c.accent,
          cursorHeight: 14,
          decoration: InputDecoration(
            isCollapsed: true,
            isDense: true,
            filled: false,
            hintText: widget.hint,
            hintStyle: UiText.sans(12.5, color: c.faint),
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onSubmitted: _finish,
        ),
      ),
    );
  }
}
