import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_inputs.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'blocks_contract.dart';
import 'blocks_format.dart';

/// 块 → 药丸（统一入口：标题、颜色、图标、外观都取块自己的）。
class BlockPill extends StatelessWidget {
  const BlockPill(
    this.block, {
    super.key,
    this.large = false,
    this.badge = UiBlockBadge.none,
    this.open = false,
    this.disabled = false,
    this.label,
    this.look,
  });

  final BlockData block;
  final bool large;
  final UiBlockBadge badge;
  final bool open;
  final bool disabled;

  /// 覆盖标题（编辑中的名字）。
  final String? label;

  /// 覆盖外观（外观选择格子）。
  final BlockAppearance? look;

  @override
  Widget build(BuildContext context) => UiBlockPill(
    label: label ?? block.title,
    color: block.color,
    icon: block.icon,
    look: look ?? block.look,
    large: large,
    badge: badge,
    open: open,
    disabled: disabled,
    translationMark: context.l10n.blocks_translationMark,
  );
}

/// 内容项（原型 `.atom`）：24 高、圆角 6、控件底、12 / w500；[small] 20 高、圆角 5、11 号、w400。
/// [mono] 用 Geist Mono；[hit] = 本次抽到（块色 12% 底 + 块色 40% 内描边）；[weight] 在前面用弱色等宽数字。
class BlockAtom extends StatelessWidget {
  const BlockAtom(
    this.text, {
    super.key,
    this.small = false,
    this.mono = false,
    this.hit,
    this.weight,
    this.height,
    this.fontSize,
    this.focused = false,
    this.muted = false,
    this.expand = false,
  });

  final String text;
  final bool small;
  final bool mono;

  /// 块色：本次抽到的高亮。
  final Color? hit;
  final double? weight;
  final double? height;
  final double? fontSize;

  /// 编辑器里正在改的那一项（1.5px 强调色内描边）。
  final bool focused;

  /// “+2” 这类透明底弱色项。
  final bool muted;

  /// 撑满宽度、内容居中（顺序卡里当前项）。
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final size = fontSize ?? (small ? 11.0 : 12.0);
    final style = mono
        ? UiText.mono(size, color: muted ? c.faint : c.ink, height: 1.2)
        : UiText.sans(
            size,
            weight: small ? FontWeight.w400 : FontWeight.w500,
            color: muted ? c.faint : c.ink,
            height: 1.2,
          );
    final h = hit;
    return Container(
      height: height ?? (small ? 20 : 24),
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8),
      decoration: BoxDecoration(
        color: muted
            ? null
            : h != null
            ? Color.alphaBlend(h.withValues(alpha: .12), c.raised)
            : c.control,
        borderRadius: BorderRadius.circular(small ? 5 : 6),
        border: h != null
            ? Border.all(color: h.withValues(alpha: .40))
            : focused
            ? Border.all(color: c.accent, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 4,
        children: [
          if (weight != null)
            Text(
              BlocksFormat.num1(weight!),
              style: UiText.mono(
                (size - 1).clamp(10, 12).toDouble(),
                weight: FontWeight.w500,
                color: c.muted,
                height: 1.2,
              ),
            ),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

/// 一组内容项：间距 5。超过 [max] 项时尾部“+N”。
class BlockAtoms extends StatelessWidget {
  const BlockAtoms(
    this.atoms, {
    super.key,
    this.small = true,
    this.mono = false,
    this.max,
    this.fontSize,
  });

  final List<String> atoms;
  final bool small;
  final bool mono;
  final int? max;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final shown = max == null || atoms.length <= max!
        ? atoms
        : atoms.take(max!).toList();
    final more = atoms.length - shown.length;
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final a in shown)
          BlockAtom(a, small: small, mono: mono, fontSize: fontSize),
        if (more > 0) BlockAtom('+$more', small: small, muted: true),
      ],
    );
  }
}

/// 10 色圆点（原型 `.cdots`）：[size] 默认 18、间距 6；选中 = 2px 底色间隙 + 2px 块色环。
class BlockColorDots extends StatelessWidget {
  const BlockColorDots({
    super.key,
    required this.selected,
    required this.onChanged,
    this.size = 18,
    this.gap = 6,
    this.ringGap,
  });

  final Color? selected;
  final ValueChanged<Color>? onChanged;
  final double size;
  final double gap;

  /// 选中环和圆点之间那圈的颜色（默认抬起底）。
  final Color? ringGap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: [
        for (final (i, color) in blockPalette.indexed)
          UiPressable(
            key: Key('block-color-$i'),
            onTap: onChanged == null ? null : () => onChanged!(color),
            builder: (context, hover) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: selected?.toARGB32() == color.toARGB32()
                    ? [
                        BoxShadow(color: color, spreadRadius: 4),
                        BoxShadow(color: ringGap ?? c.raised, spreadRadius: 2),
                      ]
                    : hover
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: .35),
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// 标签小块（原型 `.tg`）：19 高、圆角 4、11 / w500；标签色 12% 底、字 = 标签色 75% 混正文色。
class BlockTagChip extends StatelessWidget {
  const BlockTagChip(this.tag, {super.key, this.onRemove, this.onTap});
  final BlockTag tag;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final fg = Color.lerp(c.ink, tag.color, .75)!;
    final chip = Container(
      height: 19,
      padding: EdgeInsets.only(left: 6, right: onRemove == null ? 6 : 3),
      decoration: BoxDecoration(
        color: tag.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Text(
            tag.name,
            style: UiText.sans(
              11,
              weight: FontWeight.w500,
              color: fg,
              height: 1.2,
            ),
          ),
          if (onRemove != null)
            UiPressable(
              onTap: onRemove,
              builder: (context, hover) => UiGlyph(
                UiGlyphs.close,
                size: 11,
                strokeWidth: 2.2,
                color: fg.withValues(alpha: hover ? 1 : .6),
              ),
            ),
        ],
      ),
    );
    return onTap == null
        ? chip
        : UiPressable(onTap: onTap, builder: (_, _) => chip);
  }
}

/// 小徽章（原型 `.badge`）：20 高、圆角 10、11 / w600、控件底、次要色。
class BlockBadge extends StatelessWidget {
  const BlockBadge(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          style: UiText.sans(
            11,
            weight: FontWeight.w600,
            color: color ?? c.muted,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

/// 小节标题（原型 `.lab` / `.ist`）：11.5 / w600 次要色，后面可跟弱色等宽计数和右侧控件。
class BlockLabel extends StatelessWidget {
  const BlockLabel(
    this.text, {
    super.key,
    this.count,
    this.trailing,
    this.color,
  });
  final String text;
  final String? count;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      spacing: 6,
      children: [
        Text(
          text,
          style: UiText.sans(
            11.5,
            weight: FontWeight.w600,
            color: color ?? c.muted,
            letterSpacing: .23,
          ),
        ),
        if (count != null) Text(count!, style: UiText.mono(11, color: c.faint)),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

/// 抬起底的小框（原型 `.box`）：圆角 9、1px 描边、内边距 10。
class BlockBox extends StatelessWidget {
  const BlockBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.line),
      ),
      child: child,
    );
  }
}

/// 键值两列（原型 `.kv`）：12 号；左列次要色，列间距 14、行间距 4。
class BlockKv extends StatelessWidget {
  const BlockKv(this.rows, {super.key});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        for (final (i, (k, v)) in rows.indexed)
          TableRow(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 14, top: i == 0 ? 0 : 4),
                child: Text(k, style: UiText.sans(12, color: c.muted)),
              ),
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
                child: Text(v, style: UiText.sans(12, color: c.ink)),
              ),
            ],
          ),
      ],
    );
  }
}

/// 分段控件（原型 `.seg`）：控件底、内边距 2、圆角 7；项 26 高、内边距 10、12.5 号，可带 13px 图标。
/// [mini]（`.seg` 内边距 1 + 项 22 高 11.5 号）用于“正面 / 负面”这类小切换。
/// [multi] 时 [isOn] 决定每项亮不亮（“作用于 正面 + 负面”）。
class BlockSeg<T> extends StatelessWidget {
  const BlockSeg({
    super.key,
    required this.values,
    required this.labelOf,
    required this.onTap,
    this.selected,
    this.isOn,
    this.glyphOf,
    this.enabledOf,
    this.mini = false,
    this.expand = false,
    this.keyOf,
  });

  final List<T> values;
  final T? selected;
  final bool Function(T value)? isOn;
  final String Function(T value) labelOf;
  final String? Function(T value)? glyphOf;
  final bool Function(T value)? enabledOf;
  final ValueChanged<T> onTap;
  final bool mini;

  /// 撑满宽度、各项等分。
  final bool expand;
  final Key Function(T value)? keyOf;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget item(T v) {
      final on = isOn?.call(v) ?? v == selected;
      final enabled = enabledOf?.call(v) ?? true;
      final glyph = glyphOf?.call(v);
      final w = UiPressable(
        key: keyOf?.call(v),
        onTap: enabled ? () => onTap(v) : null,
        builder: (context, hover) {
          final fg = on || hover ? c.ink : c.muted;
          return Container(
            height: mini ? 22 : 26,
            padding: EdgeInsets.symmetric(horizontal: mini ? 8 : 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? (c.dark ? c.hover : c.raised) : null,
              borderRadius: BorderRadius.circular(5),
              boxShadow: on && !c.dark
                  ? const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Opacity(
              opacity: enabled ? 1 : .5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 5,
                children: [
                  if (glyph != null) UiGlyph(glyph, size: 13, color: fg),
                  Text(
                    labelOf(v),
                    maxLines: 1,
                    style: UiText.sans(
                      mini ? 11.5 : 12.5,
                      weight: on ? FontWeight.w600 : FontWeight.w400,
                      color: fg,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return expand ? Expanded(child: w) : w;
    }

    return Container(
      padding: EdgeInsets.all(mini ? 1 : 2),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        spacing: 2,
        children: [for (final v in values) item(v)],
      ),
    );
  }
}

/// 没有预览图时的内容封面（原型 `.tcov`）：块色 7% 底（深色 10%）、内边距 11 / 12、
/// Geist Mono 11 / 1.6、字 = 块色 55% 混次要色，最多 4 行；右下角块色 26% 的大图标。
class BlockTextCover extends StatelessWidget {
  const BlockTextCover(
    this.block, {
    super.key,
    this.iconSize = 46,
    this.leftInset = 12,
  });
  final BlockData block;
  final double iconSize;

  /// 左内边距；多选时卡片左上有勾选圈，文字往右让到 36。
  final double leftInset;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final col = block.color;
    final text = block.atoms.isEmpty
        ? block.negativeAtoms.join(', ')
        : block.content;
    return Container(
      color: Color.alphaBlend(
        col.withValues(alpha: c.dark ? .10 : .07),
        c.raised,
      ),
      padding: EdgeInsets.fromLTRB(leftInset, 11, 12, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: UiText.mono(
              11,
              height: 1.6,
              color: Color.lerp(c.muted, col, .55),
            ),
          ),
          Positioned(
            right: -2,
            bottom: 8,
            child: UiBlockIcon(
              block.icon,
              size: iconSize,
              color: col.withValues(alpha: .26),
            ),
          ),
        ],
      ),
    );
  }
}

/// 预览图（按偏移 / 缩放裁）或内容封面。
class BlockCover extends StatelessWidget {
  const BlockCover(
    this.block, {
    super.key,
    this.iconSize = 46,
    this.leftInset = 12,
  });
  final BlockData block;
  final double iconSize;
  final double leftInset;

  @override
  Widget build(BuildContext context) {
    final t = block.thumb;
    if (t == null) {
      return BlockTextCover(block, iconSize: iconSize, leftInset: leftInset);
    }
    return UiCroppedImage(
      image: t.image,
      offsetX: t.offsetX,
      offsetY: t.offsetY,
      scale: t.scale,
    );
  }
}

/// 悬停预览卡（原型 `.hvc`）：宽 300；有图时图高 150；药丸（大）+ 分类、项数 / 附带参数 / 含负面、
/// 前 7 项内容、底栏操作提示和使用次数。侧栏、积木、管理页三处共用。
class BlockHoverCard extends StatelessWidget {
  const BlockHoverCard(this.block, {super.key});
  final BlockData block;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final b = block;
    final atoms = b.atoms.isEmpty ? b.negativeAtoms : b.atoms;
    return UiPopoverSurface(
      key: const Key('block-hover-card'),
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (b.thumb != null) SizedBox(height: 150, child: BlockCover(b)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: BlockPill(b, large: true),
                  ),
                ),
                if (b.folderName != null)
                  Text(b.folderName!, style: UiText.sans(11, color: c.faint)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                BlockBadge(l10n.blocks_items(b.itemCount)),
                if (b.hasParams) BlockBadge(l10n.blocks_hasParams),
                if (b.hasNegative)
                  BlockBadge(l10n.blocks_hasNegative, color: c.error),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: BlockAtoms(atoms, max: 7),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: c.panel,
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: DefaultTextStyle.merge(
              style: UiText.sans(11, color: c.faint),
              child: Row(
                spacing: 10,
                children: [
                  Text(l10n.blocks_hintClick),
                  Text(l10n.blocks_hintDrag),
                  Text(l10n.blocks_hintRightClick),
                  const Spacer(),
                  Text(l10n.blocks_usedTimes(b.useCount)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
