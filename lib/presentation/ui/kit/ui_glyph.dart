import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 线性图标：直接用 HTML 原型里的 SVG 路径（24 网格、圆头圆角描边）。
class UiGlyph extends StatelessWidget {
  const UiGlyph(
    this.path, {
    super.key,
    this.size = 16,
    this.color,
    this.strokeWidth = 1.8,
  });

  /// SVG `d` 属性，取 [UiGlyphs] 里的常量。
  final String path;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? IconTheme.of(context).color ?? Colors.black;
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#000" stroke-width="$strokeWidth" stroke-linecap="round" '
      'stroke-linejoin="round"><path d="$path"/></svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}

/// 原型图标路径。新页面用到新图标时从对应 mock.html 的 `const P` 里照抄加在这里。
abstract final class UiGlyphs {
  static const refresh = 'M20 11a8 8 0 10-2.3 5.7M20 5v6h-6';
  static const chevronDown = 'M6 9l6 6 6-6';
  static const arrowRight = 'M5 12h14M13 6l6 6-6 6';
  static const info = 'M12 8v.01M11 12h1v5h1';
  static const image = 'M4 5h16v14H4zM4 15l5-5 4 4 3-3 4 4';
  static const heart =
      'M12 20s-7-4.5-7-10a4 4 0 017-2.6A4 4 0 0119 10c0 5.5-7 10-7 10z';
  static const coin =
      'M12 4a8 8 0 100 16 8 8 0 000-16zM9.5 9.5h4a1.5 1.5 0 010 3h-3a1.5 1.5 0 000 3h4M12 7.5v9';
  static const flame =
      'M12 3c1 4 5 5 5 10a5 5 0 01-10 0c0-3 2-4 2-7 1.5 1 2.5 2 3-3z';
  static const disk = 'M4 7h16v10H4zM8 12h.01M12 12h5';
  static const alert = 'M12 4l9 16H3zM12 10v4M12 17v.01';
}
