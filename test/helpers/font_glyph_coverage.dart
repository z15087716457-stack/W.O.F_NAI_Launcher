import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// 自带字体里哪些码位有字形：按 FontManifest.json 找到字族的字体文件，读它们的 cmap 表。
///
/// 测试里没有系统字体兜底，自带字体链（fontFamily + fontFamilyFallback）都没有的字会画成方框。
class FontGlyphCoverage {
  FontGlyphCoverage._(this._families);

  final Map<String, Set<int>> _families;

  static Future<FontGlyphCoverage> load() async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    final families = <String, Set<int>>{};
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final points = families[entry['family'] as String] = <int>{};
      for (final font
          in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
        points.addAll(_cmapCodePoints(await rootBundle.load(font['asset'])));
      }
    }
    return FontGlyphCoverage._(families);
  }

  /// [text] 里 [style] 的字体链画不出来的字。
  List<String> missing(String text, TextStyle style) {
    final chain = [?style.fontFamily, ...?style.fontFamilyFallback];
    return [
      for (final rune in text.runes)
        if (!chain.any((f) => _families[f]?.contains(rune) ?? false))
          String.fromCharCode(rune),
    ];
  }
}

// OpenType cmap 的格式 4（BMP）和格式 12（全部码位）。
Set<int> _cmapCodePoints(ByteData d) {
  final points = <int>{};
  var cmap = -1;
  for (var i = 0; i < d.getUint16(4); i++) {
    final record = 12 + 16 * i;
    final tag = String.fromCharCodes([
      for (var j = 0; j < 4; j++) d.getUint8(record + j),
    ]);
    if (tag == 'cmap') cmap = d.getUint32(record + 8);
  }
  if (cmap < 0) return points;
  for (var i = 0; i < d.getUint16(cmap + 2); i++) {
    final at = cmap + d.getUint32(cmap + 8 + 8 * i);
    switch (d.getUint16(at)) {
      case 4:
        final segments = d.getUint16(at + 6) ~/ 2;
        final ends = at + 14;
        final starts = ends + 2 * segments + 2;
        final deltas = starts + 2 * segments;
        final ranges = deltas + 2 * segments;
        for (var s = 0; s < segments; s++) {
          final start = d.getUint16(starts + 2 * s);
          final end = d.getUint16(ends + 2 * s);
          final delta = d.getInt16(deltas + 2 * s);
          final range = d.getUint16(ranges + 2 * s);
          for (var c = start; c <= end && c != 0xFFFF; c++) {
            var glyph = 0;
            if (range == 0) {
              glyph = (c + delta) & 0xFFFF;
            } else {
              glyph = d.getUint16(ranges + 2 * s + range + 2 * (c - start));
              if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
            }
            if (glyph != 0) points.add(c);
          }
        }
      case 12:
        for (var g = 0; g < d.getUint32(at + 12); g++) {
          final group = at + 16 + 12 * g;
          for (var c = d.getUint32(group); c <= d.getUint32(group + 4); c++) {
            points.add(c);
          }
        }
    }
  }
  return points;
}
