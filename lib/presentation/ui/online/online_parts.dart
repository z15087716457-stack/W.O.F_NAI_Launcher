import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';

import '../kit/ui_colors.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_text.dart';
import 'online_contract.dart';
import 'online_format.dart';

/// 在线画廊里的小部件和配色（评级、排行、标签分组），集中在一处。
abstract final class OnlinePalette {
  static Color rating(OnlineRating r) => switch (r) {
    OnlineRating.general => const Color(0xFF2B9A66),
    OnlineRating.sensitive => const Color(0xFFC98A00),
    OnlineRating.questionable => const Color(0xFFD9480F),
    OnlineRating.explicit => const Color(0xFFD6336C),
  };

  /// 前三名金 / 银 / 铜，其余用角标的黑色半透明底。
  static Color? rank(int rank) => switch (rank) {
    1 => const Color(0xFFC8961A),
    2 => const Color(0xFF8A96A3),
    3 => const Color(0xFFA8643A),
    _ => null,
  };

  static Color tagGroup(OnlineTagGroup g, UiColors c) => switch (g) {
    OnlineTagGroup.artist =>
      c.dark ? const Color(0xFFFF7A70) : const Color(0xFFC0392B),
    OnlineTagGroup.character =>
      c.dark ? const Color(0xFF4CD572) : const Color(0xFF1F9D3A),
    OnlineTagGroup.copyright =>
      c.dark ? const Color(0xFFE07AE6) : const Color(0xFFA020A8),
    OnlineTagGroup.meta =>
      c.dark ? const Color(0xFFF7A943) : const Color(0xFFD97706),
    OnlineTagGroup.general => c.accent,
  };

  /// 角标底：黑 66%。
  static const badge = Color(0xA80F0F0F);
}

/// 来源色块：AI TAG 是正文色底 + 页面色字，其他三个是控件底 + 正文色字。
class OnlineSourceMark extends StatelessWidget {
  const OnlineSourceMark(this.source, {super.key, this.size = 30, this.light});
  final OnlineSource source;
  final double size;

  /// 深色背景上（大图查看器）用浅底深字。
  final bool? light;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final ai = source == OnlineSource.aiTag;
    final (bg, fg) = light == true
        ? (const Color(0xFFEEEEEE), const Color(0xFF111111))
        : ai
        ? (c.ink, c.bg)
        : (c.control, c.ink);
    final small = size < 26;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(small ? 6 : (size > 40 ? 16 : 8)),
      ),
      child: Text(
        OnlineFormat.sourceMark(source),
        style: UiText.mono(
          size > 40 ? 22 : (small ? 10 : 12),
          weight: FontWeight.w700,
          color: fg,
          height: 1,
        ),
      ),
    );
  }
}

/// 圆形头像：有图用图（对准上部），没有写首字。
class OnlineAvatar extends StatelessWidget {
  const OnlineAvatar({
    super.key,
    required this.name,
    this.image,
    this.size = 24,
  });
  final String name;
  final ImageProvider? image;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.control, shape: BoxShape.circle),
      child: image != null
          ? Image(
              image: image!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -.64),
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            )
          : Text(
              name.isEmpty ? '?' : name.characters.first,
              style: UiText.sans(
                size * .45,
                weight: FontWeight.w700,
                color: c.muted,
                height: 1,
              ),
            ),
    );
  }
}

/// 浮层标题行：44 高、13.5 / w700、下边线。
class OnlinePopHeader extends StatelessWidget {
  const OnlinePopHeader({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 14, right: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: DefaultTextStyle.merge(
        style: UiText.sans(13.5, weight: FontWeight.w700, color: c.ink),
        child: Row(spacing: 8, children: children),
      ),
    );
  }
}

/// 标签块：24 高、圆角 6、Geist Mono 12 / 500，后面一个删除叉。排除的标签红色加删除线。
class OnlineToken extends StatelessWidget {
  const OnlineToken({super.key, required this.text, this.onRemove});
  final String text;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final ex = text.startsWith('-');
    return Container(
      height: 24,
      padding: const EdgeInsets.only(left: 9, right: 6),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Text(
            text,
            style:
                UiText.mono(
                  12,
                  weight: FontWeight.w500,
                  color: ex ? c.error : c.ink,
                  height: 1.2,
                ).copyWith(
                  decoration: ex ? TextDecoration.lineThrough : null,
                  decorationColor: c.error,
                ),
          ),
          Tooltip(
            message: context.l10n.online_removeTag,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onRemove,
                child: UiGlyph(UiGlyphs.close, size: 11, color: c.faint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 卡片角标：20 高、圆角 10、黑 66%、Geist Mono 10.5 / w600。
class OnlineBadge extends StatelessWidget {
  const OnlineBadge({
    super.key,
    required this.text,
    this.glyph,
    this.color,
    this.minWidth = 0,
  });
  final String text;
  final String? glyph;
  final Color? color;
  final double minWidth;

  @override
  Widget build(BuildContext context) => Container(
    height: 20,
    constraints: BoxConstraints(minWidth: minWidth),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: color ?? OnlinePalette.badge,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 3,
      children: [
        if (glyph != null)
          UiGlyph(glyph!, size: 11, strokeWidth: 2, color: Colors.white),
        Text(
          text,
          style: UiText.mono(
            minWidth > 0 ? 11 : 10.5,
            weight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ],
    ),
  );
}

/// 评级角标：18 高、圆角 5、白字字母。
class OnlineRatingBadge extends StatelessWidget {
  const OnlineRatingBadge(this.rating, {super.key});
  final OnlineRating rating;

  @override
  Widget build(BuildContext context) => Container(
    height: 18,
    constraints: const BoxConstraints(minWidth: 18),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: OnlinePalette.rating(rating),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      OnlineFormat.ratingLetter(rating),
      style: UiText.mono(
        10,
        weight: FontWeight.w600,
        color: Colors.white,
        height: 1.2,
      ),
    ),
  );
}

/// 小节标题：30 高、11.5 / w600 弱色（左栏）。
class OnlineSectionTitle extends StatelessWidget {
  const OnlineSectionTitle({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 30,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(left: 18, right: 12),
      child: DefaultTextStyle.merge(
        style: UiText.sans(11.5, weight: FontWeight.w600, color: c.faint),
        child: Row(spacing: 6, children: children),
      ),
    );
  }
}

/// 一行说明：图标 13 + 12 号次要文字。
class OnlineNote extends StatelessWidget {
  const OnlineNote(this.text, {super.key, this.glyph = UiGlyphs.infoCircle});
  final String text;
  final String glyph;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      spacing: 8,
      children: [
        UiGlyph(glyph, size: 13, color: c.muted),
        Expanded(
          child: Text(text, style: UiText.sans(12, color: c.muted)),
        ),
      ],
    );
  }
}

/// 虚线圆角框。
class OnlineDashedBox extends StatelessWidget {
  const OnlineDashedBox({
    super.key,
    required this.child,
    this.radius = 16,
    this.padding = const EdgeInsets.all(34),
  });
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedPainter(context.ui.strong, radius),
    child: Padding(padding: padding, child: child),
  );
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color, this.radius);
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 6) {
        canvas.drawPath(m.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color || old.radius != radius;
}

/// 模糊底（悬停操作条）。
class OnlineFrosted extends StatelessWidget {
  const OnlineFrosted({
    super.key,
    required this.child,
    required this.radius,
    required this.color,
    this.sigma = 6,
  });
  final Widget child;
  final double radius;
  final Color color;
  final double sigma;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: sigma / 2, sigmaY: sigma / 2),
      child: ColoredBox(color: color, child: child),
    ),
  );
}
