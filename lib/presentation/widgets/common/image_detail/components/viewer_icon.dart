import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Stage icons copied from viewer/mock.html, independent of page data.
class ViewerIcon extends StatelessWidget {
  const ViewerIcon(
    this.name, {
    super.key,
    this.size = 16,
    this.color,
    this.strokeWidth = 1.8,
  });
  final String name;
  final double size, strokeWidth;
  final Color? color;
  static const paths = {
    'arrL': 'M19 12H5M11 6l-6 6 6 6',
    'chevL': 'M15 6l-6 6 6 6',
    'chevR': 'M9 6l6 6-6 6',
    'chevD': 'M6 9l6 6 6-6',
    'min': 'M6 12h12',
    'plus': 'M12 5v14M5 12h14',
    'full': 'M4 9V4h5M15 4h5v5M20 15v5h-5M9 20H4v-5',
    'panel': 'M4 5h16v14H4zM15 5v14',
    'img': 'M4 5h16v14H4zM4 16l5-5 4 4 3-3 4 4M15 9h.01',
    'more': 'M6 12h.01M12 12h.01M18 12h.01',
  };
  @override
  Widget build(BuildContext context) => SvgPicture.string(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round"><path d="${paths[name]}"/></svg>',
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(
      color ?? Colors.white.withValues(alpha: .72),
      BlendMode.srcIn,
    ),
  );
}
