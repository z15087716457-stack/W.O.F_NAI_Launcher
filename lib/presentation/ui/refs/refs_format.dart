import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_glyph.dart';
import 'refs_contract.dart';

/// 卡片墙排版（原型 `.lgrid` / `.grid`）：内边距 左右 18、上 4、下 18；列间距 12、行间距 16；
/// 图片 4:5；卡片按可用宽度取整列。
abstract final class RefsLayout {
  static const padding = EdgeInsets.fromLTRB(18, 4, 18, 18);
  static const colGap = 12.0;
  static const rowGap = 16.0;

  static double targetWidth(RefsCardSize s) => switch (s) {
    RefsCardSize.small => 140,
    RefsCardSize.medium => 180,
    RefsCardSize.large => 240,
  };

  static int columns(double width, RefsCardSize size) =>
      math.max(1, ((width + colGap) / (targetWidth(size) + colGap)).ceil());

  /// 名称行 13 × 1.45 + 间距 2 + 参数行 11 × 1.4，上内边距 7。
  static const caption = 7 + 18.85 + 2 + 15.4;

  static double cardHeight(double width) => width * 1.25 + caption;
}

abstract final class RefsFormat {
  static String two(double v) => v.toStringAsFixed(2);

  static final _naiModelName = RegExp(
    r'^NAI Diffusion (V\d+(?:\.\d+)*)(?: \((Full|Curated)\))?$',
  );

  /// 紧凑操作名称保留 Full / Curated；完整型号继续用于说明和编码确认。
  static String compactModel(RefsModel model) {
    final match = _naiModelName.firstMatch(model.name);
    if (match == null) return model.name;
    return [match.group(1)!, ?match.group(2)].join(' ');
  }

  static String date(DateTime d) => '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

  static String dateTime(DateTime d) =>
      '${date(d)} ${_pad(d.hour)}:${_pad(d.minute)}';

  static String _pad(int v) => v.toString().padLeft(2, '0');

  /// 没用过 / 刚刚 / N 分钟前 / N 小时前 / 昨天 / N 天前 / 8 月 20 日 / 2025-08-20。
  static String relative(BuildContext context, DateTime? t, DateTime now) {
    final l10n = context.l10n;
    if (t == null) return l10n.refs_timeNever;
    final diff = now.difference(t);
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final days = today.difference(day).inDays;
    if (diff.inMinutes < 1) return l10n.refs_timeJustNow;
    if (diff.inHours < 1) return l10n.refs_timeMinutes(diff.inMinutes);
    if (days == 0) return l10n.refs_timeHours(diff.inHours);
    if (days == 1) return l10n.refs_timeYesterday;
    if (days < 7) return l10n.refs_timeDays(days);
    if (t.year == now.year) return l10n.refs_timeMonthDay(t.month, t.day);
    return date(t);
  }

  static String source(BuildContext context, RefsVibeSource s) {
    final l10n = context.l10n;
    return switch (s) {
      RefsVibeSource.png => l10n.refs_srcPng,
      RefsVibeSource.vibeFile => l10n.refs_srcVibeFile,
      RefsVibeSource.bundle => l10n.refs_srcBundle,
      RefsVibeSource.rawImage => l10n.refs_srcImage,
    };
  }

  /// 左栏“来源”一节：普通图片写成“待编码的图片”。
  static String sourceNav(BuildContext context, RefsVibeSource s) {
    final l10n = context.l10n;
    return switch (s) {
      RefsVibeSource.png => l10n.refs_srcPng,
      RefsVibeSource.vibeFile => l10n.refs_srcVibeFile,
      RefsVibeSource.bundle => l10n.refs_srcBundle,
      RefsVibeSource.rawImage => l10n.refs_srcRaw,
    };
  }

  static String sourceGlyph(RefsVibeSource s) => switch (s) {
    RefsVibeSource.png => UiGlyphs.picture,
    RefsVibeSource.vibeFile => UiGlyphs.file,
    RefsVibeSource.bundle => UiGlyphs.stack,
    RefsVibeSource.rawImage => UiGlyphs.bolt,
  };

  static String type(BuildContext context, RefsPreciseType t) {
    final l10n = context.l10n;
    return switch (t) {
      RefsPreciseType.character => l10n.refs_typeCharacter,
      RefsPreciseType.style => l10n.refs_typeStyle,
      RefsPreciseType.both => l10n.refs_typeBoth,
    };
  }

  static String typeDesc(BuildContext context, RefsPreciseType t) {
    final l10n = context.l10n;
    return switch (t) {
      RefsPreciseType.character => l10n.refs_typeCharacterDesc,
      RefsPreciseType.style => l10n.refs_typeStyleDesc,
      RefsPreciseType.both => l10n.refs_typeBothDesc,
    };
  }

  static String typeGlyph(RefsPreciseType t) => switch (t) {
    RefsPreciseType.character => UiGlyphs.user,
    RefsPreciseType.style => UiGlyphs.palette,
    RefsPreciseType.both => UiGlyphs.personStar,
  };

  static String sort(BuildContext context, RefsSort s) {
    final l10n = context.l10n;
    return switch (s) {
      RefsSort.lastUsed => l10n.refs_sortLastUsed,
      RefsSort.createdAt => l10n.refs_sortCreated,
      RefsSort.usedCount => l10n.refs_sortUsed,
      RefsSort.name => l10n.refs_sortName,
    };
  }

  /// 加入 [adding] 个之后，超出免费额度每张图多收多少。
  static int extraAfter(RefsCosts k, int total) =>
      math.max(0, total - k.freeVibes) * k.extraPerVibe;
}

/// 本页的状态色和类型色，集中在一处。
abstract final class RefsPalette {
  static Color type(RefsPreciseType t) => switch (t) {
    RefsPreciseType.character => const Color(0xFF1E88E5),
    RefsPreciseType.style => const Color(0xFFD81B60),
    RefsPreciseType.both => const Color(0xFF8E24AA),
  };

  /// 类型标签文字：正文色和类型色 2 : 8 混合。
  static Color typeInk(RefsPreciseType t, UiColors c) =>
      Color.lerp(c.ink, type(t), .8)!;

  /// 卡片上的深色角标底：黑 72%。
  static const badge = Color(0xB80F0F0F);

  /// 悬停操作条：黑 78%。
  static const hoverBar = Color(0xC7121212);

  /// 大图详情左边的暗底。
  static const stage = Color(0xFF0D0D0D);
}
