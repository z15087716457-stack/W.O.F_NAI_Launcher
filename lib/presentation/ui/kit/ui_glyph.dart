import 'package:flutter/material.dart';

import 'ui_svg_icon.dart';

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
    return UiSvgIcon.string(
      filled
          ? '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
                'fill="#000" stroke="none"><path d="$path"/></svg>'
          : '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
                'stroke="#000" stroke-width="$strokeWidth" stroke-linecap="round" '
                'stroke-linejoin="round"><path d="$path"/></svg>',
      size: size,
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

  // Vibe / 精准参考库（.devin/mockups/refs/mock.html）
  static const star =
      'M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8-4.3-4.1 5.9-.9z';
  static const stack = 'M12 3l9 5-9 5-9-5zM3 13l9 5 9-5';
  static const sort = 'M7 4v16M3 16l4 4 4-4M17 20V4M13 8l4-4 4 4';
  static const sizes = 'M4 4h6v6H4zM14 14h6v6h-6zM14 4h6v6h-6z';
  static const upload = 'M12 16V5M7 10l5-5 5 5M5 19h14';
  static const swap = 'M7 7h12l-3-3M17 17H5l3 3';
  static const help =
      'M12 21a9 9 0 100-18 9 9 0 000 18zM9.5 9a2.5 2.5 0 015 .5c0 1.5-2.5 2-2.5 3.5M12 17h.01';
  static const clipboard = 'M9 4h6v3H9zM7 5H5v15h14V5h-2';
  static const file = 'M6 3h8l4 4v14H6zM14 3v4h4';
  static const code = 'M8 8l-4 4 4 4M16 8l4 4-4 4';
  static const cover = 'M5 4h14v16H5zM9 9h6M9 13h4';
  static const tag = 'M3 12V4h8l10 10-8 8zM7.5 8h.01';
  static const inbox = 'M4 13l3-8h10l3 8v6H4zM4 13h5l1 2h4l1-2h5';
  static const bolt = 'M13 3L5 14h6l-1 7 8-11h-6z';
  static const boltOff = 'M13 3L5 14h6l-1 7 8-11h-6z M4 4l16 16';
  static const palette =
      'M12 3a9 9 0 000 18c1 0 1.6-.7 1.6-1.5 0-.4-.2-.8-.4-1-.3-.3-.4-.6-.4-1 0-.8.7-1.5 1.5-1.5H16a5 5 0 005-5c0-4.4-4-8-9-8zM7.5 12h.01M9.5 8h.01M14.5 8h.01M17 12h.01';
  static const personStar =
      'M9 11a3.5 3.5 0 100-7 3.5 3.5 0 000 7zM3 20a6 6 0 0112 0M17 4l1.2 2.6L21 7l-2 2 .5 2.8L17 10.5 14.5 11.8 15 9l-2-2 2.8-.4z';
  static const picture = 'M4 5h16v14H4zM4 16l5-5 4 4 3-3 4 4M15 9h.01';
  static const arrowLeft = 'M19 12H5M11 6l-6 6 6 6';

  // 块系统（.devin/mockups/blocks/mock.html）
  static const dice =
      'M5 4h14a1 1 0 011 1v14a1 1 0 01-1 1H5a1 1 0 01-1-1V5a1 1 0 011-1zM9 9h.01M15 15h.01M15 9h.01M9 15h.01M12 12h.01';
  static const seq = 'M4 12h12M12 7l5 5-5 5M20 6v12';
  static const fixed = 'M5 12h14';
  static const unlock = 'M6 11h12v9H6zM8.5 11V8a3.5 3.5 0 016.8-1.2';
  static const evo =
      'M8 3c0 5 8 5 8 9s-8 4-8 9M16 3c0 5-8 5-8 9s8 4 8 9M9.5 7h5M9.5 17h5';
  static const eyeOff =
      'M3 3l18 18M10.6 5.1A10 10 0 0112 5c6.5 0 10 7 10 7a17 17 0 01-3.2 4.2M6.6 6.6A17 17 0 002 12s3.5 7 10 7a9.6 9.6 0 005.4-1.6M9.9 9.9a3 3 0 004.2 4.2';
  static const folderPlus = 'M3 6h6l2 2h10v11H3zM12 11v5M9.5 13.5h5';
  static const list = 'M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01';
  static const box = 'M4 4h16v16H4zM8 12l3 3 5-6';
  static const keyboard = 'M3 6h18v12H3zM7 10h.01M11 10h.01M15 10h.01M7 14h10';
  static const minus = 'M5 12h14';
  static const drag = 'M9 6h.01M15 6h.01M9 12h.01M15 12h.01M9 18h.01M15 18h.01';
  static const merge = 'M6 4v5a6 6 0 006 6h6M15 12l3 3-3 3M6 20v-3';

  // 画风探索（.devin/mockups/style-explore/mock.html）
  static const expand = 'M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5';
  static const archive = 'M4 5h16v4H4zM5 9v10h14V9M10 13h4';
  static const retry =
      'M4 12a8 8 0 0114-5.3L20 9M20 4v5h-5M20 12a8 8 0 01-14 5.3L4 15M4 20v-5h5';
  static const pause = 'M9 5v14M15 5v14';
  static const stop = 'M6 6h12v12H6z';
  static const play = 'M8 5l11 7-11 7z';
  static const enter = 'M20 4v7a4 4 0 01-4 4H5M9 11l-4 4 4 4';
  static const branch =
      'M6 3v12M6 21a2.5 2.5 0 100-5 2.5 2.5 0 000 5zM18 9a2.5 2.5 0 100-5 2.5 2.5 0 000 5zM18 9c0 6-12 3-12 9';
  static const arrowDown = 'M12 5v14M6 13l6 6 6-6';
  static const skip = 'M5 5l8 7-8 7zM15 5v14';
  static const link =
      'M10 14a4 4 0 005.66 0l3-3a4 4 0 00-5.66-5.66l-1 1M14 10a4 4 0 00-5.66 0l-3 3a4 4 0 005.66 5.66l1-1';
  static const landscape = 'M4 7h16v10H4z';
  static const portrait = 'M7 4h10v16H7z';
  static const square = 'M5 5h14v14H5z';
}
