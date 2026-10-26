import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/common/studio_icons.dart';
import 'ui_colors.dart';
import 'ui_glyph.dart';
import 'ui_lib_nav.dart';
import 'ui_text.dart';

/// 块的外观（存储值见 `PromptBlock.appearance`：classic / stripes / dots / solid / gradient / translation）。
enum BlockAppearance { classic, stripes, dots, solid, gradient, translation }

/// 药丸右端的状态角标：随机（骰子）、顺序（→|）、已锁定（锁）、遗传块（DNA，画风探索页）。
enum UiBlockBadge { none, random, sequential, locked, evolution }

/// 药丸的特殊状态：块被删了（红色虚线“块已删除”）、引用失效（灰色虚线“失效块”）。
enum UiBlockPillStatus { normal, missing, invalid }

/// 块药丸（原型 `.pl`）：高 20、圆角 5、内边距 左 4 右 6、间距 3、字 12 / w600、图标 12；
/// 1px 块色 45% 描边、块色 8% 底（深色 15%）；文字 = 块色 72% 混正文色（深色 62%），黄色块在浅底上也读得清。
/// 状态角标统一放最右。大号（卡片标题、详情标题）：高 24、字 13、图标 13、圆角 6、内边距 6 / 8、间距 4。
///
/// 提示词、块库侧栏、积木、管理页、实例卡、编辑块里的药丸全部用这一个组件。
class UiBlockPill extends StatelessWidget {
  const UiBlockPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.look = BlockAppearance.classic,
    this.badge = UiBlockBadge.none,
    this.status = UiBlockPillStatus.normal,
    this.open = false,
    this.disabled = false,
    this.paired = false,
    this.temporary = false,
    this.dragging = false,
    this.ghost = false,
    this.focused = false,
    this.large = false,
    this.count,
    this.translationMark = '译',
  });

  final bool temporary;
  final String label;
  final Color color;

  /// 块图标键（[UiBlockIcon]）；null 用块库默认图标。
  final String? icon;
  final BlockAppearance look;
  final UiBlockBadge badge;
  final UiBlockPillStatus status;

  /// 点开了实例卡：块色 30% 外环 + 块色 16% 底。
  final bool open;

  /// 实例已停用：虚线描边、透明底、弱色删除线。
  final bool disabled;

  /// 正负面一起插入的双面块：尾部 “UC” 小标。
  final bool paired;

  /// 拖动中的那颗（抬起投影、转 −2°）。
  final bool dragging;

  /// 拖动时留在原位的那颗（35% 不透明）。
  final bool ghost;

  /// 键盘选中：2px 强调色外框，离开 1px。
  final bool focused;
  final bool large;

  /// 尾部的计数（积木里“×3”这类），Geist Mono 10.5。
  final String? count;

  /// 翻译外观前面的“译”字（调用方传本地化文案）。
  final String translationMark;

  /// 正文色和块色按 72%（深色 62%）混出的药丸文字色。
  static Color inkOf(UiColors c, Color color) =>
      Color.lerp(c.ink, color, c.dark ? .62 : .72)!;

  /// 实心外观上的字色：浅色块（黄）用深字。
  static Color onSolid(Color color) =>
      color.computeLuminance() > .5 ? const Color(0xFF1A1A1A) : Colors.white;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final h = large ? 24.0 : 20.0;
    final radius = large ? 6.0 : 5.0;
    final font = large ? 13.0 : 12.0;
    final glyph = large ? 13.0 : 12.0;

    final missing = status == UiBlockPillStatus.missing;
    final invalid = status == UiBlockPillStatus.invalid;
    final base = missing ? c.error : (invalid ? c.faint : color);
    final dashed = disabled || missing || invalid;
    final look = (missing || invalid) ? BlockAppearance.classic : this.look;
    final solid = look == BlockAppearance.solid && !disabled;
    final tr = look == BlockAppearance.translation && !disabled;

    final Color ink;
    final Color iconInk;
    if (disabled) {
      ink = c.faint;
      iconInk = c.faint;
    } else if (solid) {
      ink = onSolid(base);
      iconInk = ink;
    } else if (tr) {
      ink = c.ink;
      iconInk = c.muted;
    } else {
      ink = inkOf(c, base);
      iconInk = base;
    }

    final borderColor = tr
        ? c.line
        : (solid ? base : base.withValues(alpha: .45));
    final fillAlpha = c.dark ? .15 : .08;
    final Color? fill = disabled
        ? null
        : open
        ? base.withValues(alpha: .16)
        : switch (look) {
            BlockAppearance.classic => base.withValues(alpha: fillAlpha),
            BlockAppearance.solid => base,
            BlockAppearance.translation => c.control,
            BlockAppearance.dots => base.withValues(alpha: .05),
            BlockAppearance.stripes || BlockAppearance.gradient => null,
          };

    final Widget lead = tr
        ? Text(
            translationMark,
            style: UiText.sans(
              10,
              weight: FontWeight.w700,
              color: iconInk,
              height: 1,
            ),
          )
        : missing
        ? UiGlyph(UiGlyphs.alert, size: glyph, strokeWidth: 2, color: iconInk)
        : invalid
        ? UiGlyph(UiGlyphs.help, size: glyph, strokeWidth: 2, color: iconInk)
        : UiBlockIcon(icon, size: glyph, color: iconInk);

    final tail = switch (badge) {
      UiBlockBadge.none => null,
      UiBlockBadge.random => UiGlyphs.dice,
      UiBlockBadge.sequential => UiGlyphs.seq,
      UiBlockBadge.locked => UiGlyphs.lock,
      UiBlockBadge.evolution => UiGlyphs.evo,
    };

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: large ? 4 : 3,
      children: [
        lead,
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style:
                UiText.sans(
                  font,
                  weight: tr ? FontWeight.w500 : FontWeight.w600,
                  color: ink,
                  height: 1,
                ).copyWith(
                  decoration: disabled ? TextDecoration.lineThrough : null,
                  decorationColor: c.faint.withValues(alpha: .7),
                ),
          ),
        ),
        if (paired)
          Container(
            margin: const EdgeInsets.only(left: 2),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
              color: base.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'UC',
              style: UiText.sans(
                9,
                weight: FontWeight.w700,
                color: ink,
                height: 1,
              ),
            ),
          ),
        if (count != null)
          Padding(
            padding: const EdgeInsets.only(left: 1),
            child: Opacity(
              opacity: .8,
              child: Text(
                count!,
                style: UiText.mono(
                  10.5,
                  weight: FontWeight.w500,
                  color: ink,
                  height: 1,
                ),
              ),
            ),
          ),
        if (tail != null)
          Padding(
            padding: const EdgeInsets.only(left: 1),
            child: Opacity(
              opacity: .8,
              child: UiGlyph(
                tail,
                size: 11,
                strokeWidth: 2.2,
                color: badge == UiBlockBadge.evolution
                    ? (c.dark
                          ? const Color(0xFF9E8CFC)
                          : const Color(0xFF6E56CF))
                    : ink,
              ),
            ),
          ),
      ],
    );

    Widget pill = Container(
      height: h,
      padding: EdgeInsets.only(left: large ? 6 : 4, right: large ? 8 : 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: dashed ? null : Border.all(color: borderColor),
        boxShadow: [
          if (open && !disabled)
            BoxShadow(color: base.withValues(alpha: .30), spreadRadius: 2),
          if (dragging)
            BoxShadow(
              color: Colors.black.withValues(alpha: c.dark ? .45 : .14),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Center(widthFactor: 1, child: row),
    );
    if (!disabled &&
        !open &&
        (look == BlockAppearance.stripes ||
            look == BlockAppearance.dots ||
            look == BlockAppearance.gradient)) {
      pill = CustomPaint(
        painter: _SkinPainter(look, base, radius),
        child: pill,
      );
    }
    if (dashed) {
      pill = UiDashedBox(
        radius: radius,
        strokeWidth: 1,
        dash: 3,
        gap: 2,
        color: disabled ? c.faint.withValues(alpha: .8) : borderColor,
        child: pill,
      );
    }
    if (focused) {
      // CSS outline 2px、offset 1px：画在药丸外面，不占布局。
      pill = CustomPaint(
        foregroundPainter: _OutlinePainter(c.accent, radius),
        child: pill,
      );
    }
    if (dragging) {
      pill = Transform.rotate(angle: -2 * math.pi / 180, child: pill);
    }
    if (ghost) pill = Opacity(opacity: .35, child: pill);
    return pill;
  }
}

/// 细条纹（135° 3px 深 / 4px 浅）、圆点（6px 网格）、渐变（左 24% → 右 2%）三种外观的底纹。
class _SkinPainter extends CustomPainter {
  _SkinPainter(this.look, this.color, this.radius);
  final BlockAppearance look;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas
      ..save()
      ..clipRRect(rr);
    switch (look) {
      case BlockAppearance.stripes:
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = color.withValues(alpha: .05),
        );
        final p = Paint()..color = color.withValues(alpha: .17);
        const k = 1.41421356;
        for (var d = 0.0; d - size.height < size.width; d += 7 * k) {
          canvas.drawPath(
            Path()
              ..moveTo(d, 0)
              ..lineTo(d + 3 * k, 0)
              ..lineTo(d + 3 * k - size.height, size.height)
              ..lineTo(d - size.height, size.height)
              ..close(),
            p,
          );
        }
      case BlockAppearance.dots:
        final p = Paint()..color = color.withValues(alpha: .34);
        for (var y = 4.0; y < size.height; y += 6) {
          for (var x = 4.0; x < size.width; x += 6) {
            canvas.drawCircle(Offset(x, y), 1.05, p);
          }
        }
      case BlockAppearance.gradient:
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = LinearGradient(
              colors: [
                color.withValues(alpha: .24),
                color.withValues(alpha: .02),
              ],
            ).createShader(Offset.zero & size),
        );
      default:
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SkinPainter old) =>
      old.look != look || old.color != color || old.radius != radius;
}

class _OutlinePainter extends CustomPainter {
  _OutlinePainter(this.color, this.radius);
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(2),
      Radius.circular(radius + 2),
    ),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color,
  );

  @override
  bool shouldRepaint(_OutlinePainter old) =>
      old.color != color || old.radius != radius;
}

/// 块图标：键名就是 `PromptBlock.iconName` 的存储值（与旧表 `kPromptBlockIconOptions` 的 40 个键一一对应），
/// 图形统一换成原型风格的 24 网格圆头描边；未知键 / null 用块库图标（StudioIcons）。
class UiBlockIcon extends StatelessWidget {
  const UiBlockIcon(this.name, {super.key, this.size = 12, this.color});
  final String? name;
  final double size;
  final Color? color;

  /// 编辑块里图标网格的顺序。
  static const keys = [
    'palette', 'brush', 'draw', 'color_lens', 'image', 'photo', 'filter', //
    'person', 'face', 'groups', 'heart', 'star', 'bolt', 'fire', 'sparkle',
    'moon', 'sun', 'cloud', 'snow', 'landscape', 'city', 'home', 'park',
    'beach', 'forest', 'dress', 'diamond', 'cake', 'food', 'game', 'music',
    'pets', 'book', 'science', 'school', 'car', 'flight', 'shield', 'build',
    'tag',
  ];

  static const _paths = <String, String>{
    'palette': UiGlyphs.palette,
    'brush': 'M14 4l6 6-8 8H6v-6zM4 20l2-2',
    'draw': 'M4 20h4L19 9l-4-4L4 16zM13 7l4 4M14 20h6',
    'color_lens': 'M12 3s6 6.5 6 11a6 6 0 01-12 0c0-4.5 6-11 6-11z',
    'image': UiGlyphs.picture,
    'photo': 'M4 8h3l2-3h6l2 3h3v11H4zM12 16.5a3 3 0 100-6 3 3 0 000 6z',
    'filter':
        'M12 14a2 2 0 100-4 2 2 0 000 4zM12 10a3 3 0 113-3M14 12a3 3 0 113 3M12 14a3 3 0 11-3 3M10 12a3 3 0 11-3-3',
    'person': UiGlyphs.user,
    'face':
        'M12 21a9 9 0 100-18 9 9 0 000 18zM9 10h.01M15 10h.01M9 14.5a4 4 0 006 0',
    'groups':
        'M9 11a3 3 0 100-6 3 3 0 000 6zM3 19a6 6 0 0112 0M16 11a2.5 2.5 0 100-5M17 14a5 5 0 014 5',
    'heart':
        'M12 20s-7-4.4-9.2-9A4.8 4.8 0 0112 5.6 4.8 4.8 0 0121.2 11C19 15.6 12 20 12 20z',
    'star': UiGlyphs.star,
    'bolt': UiGlyphs.bolt,
    'fire': UiGlyphs.flame,
    'sparkle':
        'M12 3l1.9 5.6L19.5 10l-5.6 1.9L12 17.5l-1.9-5.6L4.5 10l5.6-1.4z',
    'moon': 'M20 14.5A8 8 0 019.5 4a8 8 0 1010.5 10.5z',
    'sun':
        'M12 16a4 4 0 100-8 4 4 0 000 8zM12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4',
    'cloud': 'M7 18h10a4 4 0 00.5-8A6 6 0 006 11a3.5 3.5 0 001 7z',
    'snow':
        'M12 3v18M4.2 7.5l15.6 9M4.2 16.5l15.6-9M9.5 4.5L12 7l2.5-2.5M9.5 19.5L12 17l2.5 2.5',
    'landscape': 'M3 19l6-8 4 5 3-3 5 6zM16 8h.01',
    'city':
        'M4 20V9l5-3v14M9 20V4h7v16M16 10h4v10M3 20h18M12 8h1M12 12h1M12 16h1',
    'home': 'M4 11l8-7 8 7M6 9.5V20h12V9.5M10 20v-5h4v5',
    'park': 'M12 3l6 9h-3l4 6H5l4-6H6zM12 18v3',
    'beach': 'M3 12a9 9 0 0118 0zM12 12v7a2 2 0 004 0',
    'forest': 'M8 3l4 7H9l3 5H4l3-5H4zM8 15v5M16 6l4 7h-3l3 5h-8M16 18v2',
    'dress': 'M12 6.5a2 2 0 112 2L12 10M12 10l-9 7h18z',
    'diamond': 'M7 4h10l4 5-9 11L3 9zM3 9h18M12 20L9 9l3-5 3 5z',
    'cake':
        'M4 21h16v-8H4zM4 16c2 1.5 4 1.5 6 0s4-1.5 6 0 4 1.5 4 0M12 13V9M12 6v.01',
    'food': 'M7 3v8M5 3v5a2 2 0 004 0V3M7 11v10M17 3c-2 0-3 3-3 6s1 4 3 4v8',
    'game':
        'M7 8h10a4 4 0 014 4v2a3 3 0 01-5.5 1.7L14.5 14h-5l-1 1.7A3 3 0 013 14v-2a4 4 0 014-4zM8 11v3M6.5 12.5h3M15.5 12h.01M17.5 13.5h.01',
    'music':
        'M9 18V5l11-2v13M9 18a3 3 0 11-6 0 3 3 0 016 0zM20 16a3 3 0 11-6 0 3 3 0 016 0z',
    'pets':
        'M12 13c-3 0-5 3-5 5 0 1.5 1.5 2 3 1.5s2.5-.5 4 0 3 0 3-1.5c0-2-2-5-5-5zM6.5 12a1.5 2 0 100-4 1.5 2 0 000 4zM17.5 12a1.5 2 0 100-4 1.5 2 0 000 4zM9.5 8a1.5 2 0 100-4 1.5 2 0 000 4zM14.5 8a1.5 2 0 100-4 1.5 2 0 000 4z',
    'book':
        'M12 6c-2-1.5-5-2-8-1.5V19c3-.5 6 0 8 1.5 2-1.5 5-2 8-1.5V4.5c-3-.5-6 0-8 1.5zM12 6v14.5',
    'science':
        'M9 3h6M10 3v6l-5 9a2 2 0 001.7 3h10.6a2 2 0 001.7-3l-5-9V3M7.5 14h9',
    'school': 'M2 9l10-5 10 5-10 5zM6 11v5c3 2.5 9 2.5 12 0v-5M22 9v6',
    'car':
        'M4 16h16v-4l-2.5-5h-11L4 12zM4 12h16M7.5 19a1.5 1.5 0 100-3 1.5 1.5 0 000 3zM16.5 19a1.5 1.5 0 100-3 1.5 1.5 0 000 3z',
    'flight':
        'M12 3a1.5 1.5 0 011.5 1.5V10l7.5 4.5v2l-7.5-2.5V19l2 1.5V22L12 21l-3.5 1v-1.5l2-1.5v-5L3 16.5v-2L10.5 10V4.5A1.5 1.5 0 0112 3z',
    'shield': 'M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z',
    'build':
        'M14.5 6.5a4 4 0 00-5.2 5.2L4 17l3 3 5.3-5.3a4 4 0 005.2-5.2l-2.5 2.5-2.5-.5-.5-2.5z',
    'tag': UiGlyphs.tag,
  };

  @override
  Widget build(BuildContext context) {
    final ink = color ?? IconTheme.of(context).color ?? context.ui.muted;
    final path = _paths[name];
    if (path == null) {
      return Icon(StudioIcons.promptBlocks, size: size, color: ink);
    }
    return UiGlyph(path, size: size, strokeWidth: 2, color: ink);
  }
}
