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
    this.filled = false,
  });

  /// SVG `d` 属性，取 [UiGlyphs] 里的常量。
  final String path;
  final double size;
  final Color? color;
  final double strokeWidth;

  /// 实心（原型里 `fill:currentColor;stroke:none` 的图标，例如已收藏的心形）。
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? IconTheme.of(context).color ?? Colors.black;
    return SvgPicture.string(
      filled
          ? '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
                'fill="#000" stroke="none"><path d="$path"/></svg>'
          : '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
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

  // 主导航（.devin/mockups/nav/mock.html）
  static const doubleRight = 'M6 6l6 6-6 6M13 6l6 6-6 6';
  static const doubleLeft = 'M18 6l-6 6 6 6M11 6l-6 6 6 6';
  static const chevronRight = 'M9 6l6 6-6 6';
  static const check = 'M5 12.5l4.5 4.5L19 7';
  static const pin = 'M9 4h6l-1 6 3 3H7l3-3zM12 13v7';
  static const lock = 'M6 11h12v9H6zM9 11V8a3 3 0 016 0v3';
  static const plus = 'M12 5v14M5 12h14';
  static const logout = 'M10 5H5v14h5M14 8l4 4-4 4M18 12H9';
  static const download = 'M12 4v11M7 10l5 5 5-5M5 19h14';
  static const close = 'M6 6l12 12M18 6L6 18';
  static const user = 'M12 12a4 4 0 100-8 4 4 0 000 8zM5 20a7 7 0 0114 0';

  // 在线画廊 / 库页（.devin/mockups/online/mock.html）
  static const search = 'M11 18a7 7 0 100-14 7 7 0 000 14zM20 20l-4-4';
  static const spark =
      'M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z';
  static const trophy =
      'M8 4h8v5a4 4 0 01-8 0zM8 6H5a3 3 0 003 4M16 6h3a3 3 0 01-3 4M12 13v4M8 20h8M10 17h4';
  static const heartLib =
      'M12 20s-7.5-4.6-9.2-9.4C1.6 7 4 4 7.3 4c2 0 3.6 1.1 4.7 2.7C13.1 5.1 14.7 4 16.7 4 20 4 22.4 7 21.2 10.6 19.5 15.4 12 20 12 20z';
  static const folder = 'M3 6h6l2 2h10v11H3z';
  static const grid = 'M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z';
  static const select =
      'M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM14.5 16.5l2 2 3.5-4';
  static const panel = 'M4 5h16v14H4zM15 5v14';
  static const ban = 'M12 21a9 9 0 100-18 9 9 0 000 18zM5.6 5.6l12.8 12.8';
  static const clock = 'M12 21a9 9 0 100-18 9 9 0 000 18zM12 7v5l3 2';
  static const calendar = 'M4 6h16v14H4zM4 10h16M8 3v5M16 3v5';
  static const userPlus =
      'M10 12a4 4 0 100-8 4 4 0 000 8zM3 20a7 7 0 0114 0M19 8v6M16 11h6';
  static const eye =
      'M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12zM12 15a3 3 0 100-6 3 3 0 000 6z';
  static const layers = 'M4 6h12v12H4zM8 3h12v12';
  static const external = 'M14 4h6v6M20 4l-9 9M18 14v6H4V6h6';
  static const send = 'M4 12l16-8-6 16-3-7z';
  static const copy = 'M8 8h11v12H8zM5 16V4h11';
  static const more = 'M6 12h.01M12 12h.01M18 12h.01';
  static const chevronLeft = 'M15 6l-6 6 6 6';
  static const chevronUp = 'M6 15l6-6 6 6';
  static const infoCircle =
      'M12 21a9 9 0 100-18 9 9 0 000 18zM12 11v6M12 7.5h.01';
  static const login = 'M10 17l5-5-5-5M15 12H3M14 4h6v16h-6';
  static const move = 'M4 7h16M4 12h10M4 17h7M17 14l3 3-3 3';
  static const pencil = 'M4 20h4L19 9l-4-4L4 16zM13.5 6.5l4 4';
  static const trash = 'M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3';
}
