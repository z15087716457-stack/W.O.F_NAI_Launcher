import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

/// 假数据用的占位图：按 key 生成固定的竖向渐变小图（预览和测试里没有原型图时用）。
abstract final class UiFixtureImage {
  static ImageProvider gradient(String key) =>
      _cache.putIfAbsent(key, () => MemoryImage(_png(key)));

  static final _cache = <String, ImageProvider>{};

  static Uint8List _png(String key) {
    // FNV-1a：只差一个字符的 key（c03 / c13）也会得到差得很远的色相。
    final h = key.codeUnits.fold<int>(
      0x811C9DC5,
      (a, b) => ((a ^ b) * 0x01000193) & 0xFFFFFFFF,
    );
    final hue = (h % 360).toDouble();
    final image = img.Image(width: 24, height: 30);
    final a = _hsv(hue, .40 + (h >> 9) % 20 / 100, .82);
    final b = _hsv((hue + 30 + (h >> 13) % 90) % 360, .60, .30);
    for (var y = 0; y < 30; y++) {
      final t = y / 29;
      for (var x = 0; x < 24; x++) {
        final u = (t * .8 + x / 23 * .2).clamp(0, 1);
        image.setPixelRgb(
          x,
          y,
          (a.$1 + (b.$1 - a.$1) * u).round(),
          (a.$2 + (b.$2 - a.$2) * u).round(),
          (a.$3 + (b.$3 - a.$3) * u).round(),
        );
      }
    }
    return img.encodePng(image);
  }

  static (int, int, int) _hsv(double h, double s, double v) {
    final c = v * s;
    final x = c * (1 - ((h / 60) % 2 - 1).abs());
    final m = v - c;
    final (r, g, b) = switch (h ~/ 60) {
      0 => (c, x, 0.0),
      1 => (x, c, 0.0),
      2 => (0.0, c, x),
      3 => (0.0, x, c),
      4 => (x, 0.0, c),
      _ => (c, 0.0, x),
    };
    return (
      ((r + m) * 255).round(),
      ((g + m) * 255).round(),
      ((b + m) * 255).round(),
    );
  }
}
