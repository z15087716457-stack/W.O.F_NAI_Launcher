import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_glyph.dart';
import 'blocks_contract.dart';

/// 块系统的文案拼装和小算法（不带样式）。
abstract final class BlocksFormat {
  static String _two(int v) => v.toString().padLeft(2, '0');

  /// 10-06 18:54
  static String dateTime(DateTime t) =>
      '${_two(t.month)}-${_two(t.day)} ${_two(t.hour)}:${_two(t.minute)}';

  /// 08-21
  static String date(DateTime t) => '${_two(t.month)}-${_two(t.day)}';

  static String num1(double v) => v.toStringAsFixed(1);

  static String mode(BuildContext context, BlockMode m) {
    final l10n = context.l10n;
    return switch (m) {
      BlockMode.fixed => l10n.blocks_modeFixed,
      BlockMode.sequential => l10n.blocks_modeSequential,
      BlockMode.random => l10n.blocks_modeRandom,
    };
  }

  static String modeGlyph(BlockMode m) => switch (m) {
    BlockMode.fixed => UiGlyphs.fixed,
    BlockMode.sequential => UiGlyphs.seq,
    BlockMode.random => UiGlyphs.dice,
  };

  static String sort(BuildContext context, BlocksSort s) {
    final l10n = context.l10n;
    return switch (s) {
      BlocksSort.custom => l10n.blocks_sortCustom,
      BlocksSort.updated => l10n.blocks_sortUpdated,
      BlocksSort.title => l10n.blocks_sortTitle,
      BlocksSort.color => l10n.blocks_sortColor,
      BlocksSort.icon => l10n.blocks_sortIcon,
    };
  }

  static String look(BuildContext context, BlockAppearance a) {
    final l10n = context.l10n;
    return switch (a) {
      BlockAppearance.classic => l10n.blocks_lookClassic,
      BlockAppearance.stripes => l10n.blocks_lookStripes,
      BlockAppearance.dots => l10n.blocks_lookDots,
      BlockAppearance.solid => l10n.blocks_lookSolid,
      BlockAppearance.gradient => l10n.blocks_lookGradient,
      BlockAppearance.translation => l10n.blocks_lookTranslation,
    };
  }

  /// 数量范围“1–2”或“1”。
  static String range(int a, int b) => a == b ? '$a' : '$a–$b';

  /// 权重范围“0.1–2.0”。
  static String weightRange(BlockRollSettings s) =>
      '${num1(s.weightMin)}–${num1(s.weightMax)}';

  static String dispersion(BuildContext context, BlockRollSettings s) {
    final l10n = context.l10n;
    final p = preset(s);
    return switch (p) {
      BlockRollSettings.focused => l10n.blocks_distFocused,
      BlockRollSettings.balanced => l10n.blocks_distBalanced,
      BlockRollSettings.spread => l10n.blocks_distSpread,
      _ => l10n.blocks_distCustom,
    };
  }

  /// 左右离散相同且等于某个预设时返回那个值，否则 null（“自定义”）。
  static double? preset(BlockRollSettings s) {
    for (final v in const [
      BlockRollSettings.focused,
      BlockRollSettings.balanced,
      BlockRollSettings.spread,
    ]) {
      if ((s.leftDispersion - v).abs() < 1e-6 &&
          (s.rightDispersion - v).abs() < 1e-6) {
        return v;
      }
    }
    return null;
  }

  static String percent(double v) => '${(v * 100).round()}%';

  /// “V4.5 Full · 28 步 · 引导 5.0 · Euler Ancestral”
  static String params(
    BuildContext context,
    BlockParams p,
    BlockParamCatalog catalog, {
    bool short = false,
  }) {
    final l10n = context.l10n;
    return [
      if (p.model case final m?) catalog.model(m),
      if (p.steps case final s?) l10n.blocks_steps(s),
      if (p.scale case final g?) l10n.blocks_guidance(num1(g)),
      if (p.sampler case final s?)
        short ? shortSampler(catalog.sampler(s)) : catalog.sampler(s),
      if (!short && p.noiseSchedule != null) catalog.noise(p.noiseSchedule!),
    ].join(' · ');
  }

  /// “Euler Ancestral” → “Euler A”（参数小胶囊里放不下全名）。
  static String shortSampler(String s) => s.replaceAll(' Ancestral', ' A');

  /// 原子里的权重写法：“0.8::sincos::” → (0.8, "sincos")；没有权重返回 (null, 原文)。
  static (double?, String) weighted(String atom) {
    final m = RegExp(r'^(-?\d+(?:\.\d+)?)::(.*?)(?:::)?$').firstMatch(atom);
    if (m == null) return (null, atom);
    return (double.tryParse(m.group(1)!), m.group(2)!);
  }

  /// 去掉 `artist:` 前缀，抽到的项显示得短一点（发送文本仍是原文）。
  static String short(String atom) =>
      atom.startsWith('artist:') ? atom.substring(7) : atom;

  /// 分布图里每一格的相对高度（0…1）：两侧各按 Beta(1, 12 − 11d) 的距离分布，
  /// 和抽取引擎同一形状；只用来画图，不参与抽取。
  static List<double> histogram(BlockRollSettings s, int bins) {
    final lo = s.weightMin, hi = s.weightMax, av = s.weightAverage;
    if (hi <= lo) return List.filled(bins, 1);
    double side(double t, double d) {
      final b = 12 - 11 * d.clamp(0.0, 1.0);
      return t >= 1 ? 0 : math.pow(1 - t, b - 1).toDouble();
    }

    return [
      for (var i = 0; i < bins; i++)
        () {
          final x = lo + (hi - lo) * (i + .5) / bins;
          if (x < av) {
            final span = av - lo;
            return span <= 0 ? 0.0 : side((av - x) / span, s.leftDispersion);
          }
          final span = hi - av;
          return span <= 0 ? 0.0 : side((x - av) / span, s.rightDispersion);
        }(),
    ];
  }

  /// 编辑块 / 存为块里把一段粘贴文字拆成项：按顶层逗号拆（括号 / 花括号 / `::` 里的逗号不拆），去掉空项。
  static List<String> split(String text) {
    final out = <String>[];
    final buf = StringBuffer();
    var depth = 0;
    var weighted = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if ('([{'.contains(ch)) depth++;
      if (')]}'.contains(ch) && depth > 0) depth--;
      if (ch == ':' && i + 1 < text.length && text[i + 1] == ':') {
        weighted = !weighted;
        buf.write('::');
        i++;
        continue;
      }
      if ((ch == ',' || ch == '\n') && depth == 0 && !weighted) {
        final s = buf.toString().trim();
        if (s.isNotEmpty) out.add(s);
        buf.clear();
        continue;
      }
      buf.write(ch);
    }
    final s = buf.toString().trim();
    if (s.isNotEmpty) out.add(s);
    return out;
  }
}
