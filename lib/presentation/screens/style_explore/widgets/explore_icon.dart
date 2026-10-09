import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../widgets/library/library_icon.dart';

/// Paths differing from the shared reference library prototype are kept exact.
class ExploreIcon extends StatelessWidget {
  const ExploreIcon(
    this.name, {
    super.key,
    this.size = 16,
    this.color,
    this.strokeWidth = 1.8,
    this.filled = false,
  });
  final String name;
  final double size, strokeWidth;
  final Color? color;
  final bool filled;
  static const _paths = {
    'enter': 'M20 4v7a4 4 0 01-4 4H5M9 11l-4 4 4 4',
    'dice':
        'M5 4h14a1 1 0 011 1v14a1 1 0 01-1 1H5a1 1 0 01-1-1V5a1 1 0 011-1zM9 9h.01M15 15h.01M15 9h.01M9 15h.01M12 12h.01',
    'box': 'M4 5h16v4H4zM5 9v10h14V9M10 13h4',
    'max': 'M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5',
    'pause': 'M9 5v14M15 5v14',
    'stop': 'M6 6h12v12H6z',
    'minus': 'M5 12h14',
    'chevU': 'M6 15l6-6 6 6',
    'play': 'M8 5l11 7-11 7z',
    'panel': 'M4 5h16v14H4zM15 5v14',
    'swap':
        'M4 12a8 8 0 0114-5.3L20 9M20 4v5h-5M20 12a8 8 0 01-14 5.3L4 15M4 20v-5h5',
  };
  @override
  Widget build(BuildContext context) {
    final path = _paths[name];
    if (path == null) {
      return LibraryIcon(
        name,
        size: size,
        color: color,
        strokeWidth: strokeWidth,
        filled: filled,
      );
    }
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="${filled ? '#000' : 'none'}" stroke="${filled ? 'none' : '#000'}" '
      'stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round">'
      '<path d="$path"/></svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ??
            IconTheme.of(context).color ??
            Theme.of(context).colorScheme.onSurface,
        BlendMode.srcIn,
      ),
    );
  }
}
