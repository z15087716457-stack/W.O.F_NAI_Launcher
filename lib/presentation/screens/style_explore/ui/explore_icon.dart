import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG paths from the selected A prototype. No glyph substitution.
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
    'chevL': 'M15 6l-6 6 6 6',
    'chevR': 'M9 6l6 6-6 6',
    'chevD': 'M6 9l6 6 6-6',
    'chevU': 'M6 15l6-6 6 6',
    'dbl': 'M6 6l6 6-6 6M13 6l6 6-6 6',
    'x': 'M6 6l12 12M18 6L6 18',
    'plus': 'M12 5v14M5 12h14',
    'trash': 'M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3',
    'check': 'M5 12.5l4.5 4.5L19 7',
    'more': 'M6 12h.01M12 12h.01M18 12h.01',
    'lock': 'M6 11h12v9H6zM8.5 11V8a3.5 3.5 0 017 0v3',
    'link':
        'M10 14a4 4 0 005.66 0l3-3a4 4 0 00-5.66-5.66l-1 1M14 10a4 4 0 00-5.66 0l-3 3a4 4 0 005.66 5.66l1-1',
    'max': 'M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5',
    'grid': 'M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z',
    'box': 'M4 5h16v4H4zM5 9v10h14V9M10 13h4',
    'upload': 'M12 16V5M7 10l5-5 5 5M5 19h14',
    'pin': 'M12 21s-6-5.5-6-10a6 6 0 0112 0c0 4.5-6 10-6 10zM12 11h.01',
    'land': 'M4 7h16v10H4z',
    'port': 'M7 4h10v16H7z',
    'sq': 'M5 5h14v14H5z',
    'min': 'M6 12h12',
    'maxw': 'M6 6h12v12H6z',
    'dice':
        'M5 4h14a1 1 0 011 1v14a1 1 0 01-1 1H5a1 1 0 01-1-1V5a1 1 0 011-1zM9 9h.01M15 15h.01M15 9h.01M9 15h.01M12 12h.01',
    'swap':
        'M4 12a8 8 0 0114-5.3L20 9M20 4v5h-5M20 12a8 8 0 01-14 5.3L4 15M4 20v-5h5',
    'pause': 'M9 5v14M15 5v14',
    'stop': 'M6 6h12v12H6z',
    'play': 'M8 5l11 7-11 7z',
    'heart':
        'M12 20s-7-4.4-9.2-9A4.8 4.8 0 0112 5.6 4.8 4.8 0 0121.2 11C19 15.6 12 20 12 20z',
    'evo':
        'M8 3c0 5 8 5 8 9s-8 4-8 9M16 3c0 5-8 5-8 9s8 4 8 9M9.5 7h5M9.5 17h5',
    'spark': 'M12 3l1.9 5.6L19.5 10l-5.6 1.9L12 17.5l-1.9-5.6L4.5 10l5.6-1.4z',
    'folder': 'M3 6h6l2 2h10v11H3z',
    'folderp': 'M3 6h6l2 2h10v11H3zM12 11v5M9.5 13.5h5',
    'copy': 'M8 8h11v12H8zM5 16V4h11',
    'enter': 'M20 4v7a4 4 0 01-4 4H5M9 11l-4 4 4 4',
    'search': 'M11 18a7 7 0 100-14 7 7 0 000 14zM20 20l-4-4',
    'panel': 'M4 5h16v14H4zM15 5v14',
    'sel': 'M4 4h16v16H4zM8 12l3 3 5-6',
    'size': 'M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z',
    'mas': 'M4 4h7v9H4zM13 4h7v5h-7zM4 15h7v5H4zM13 11h7v9h-7z',
    'branch':
        'M6 3v12M6 21a2.5 2.5 0 100-5 2.5 2.5 0 000 5zM18 9a2.5 2.5 0 100-5 2.5 2.5 0 000 5zM18 9c0 6-12 3-12 9',
    'sort': 'M7 4v16M3 16l4 4 4-4M17 20V4M13 8l4-4 4 4',
    'edit': 'M4 20h4L19 9l-4-4L4 16zM13 7l4 4',
    'arrR': 'M5 12h14M13 6l6 6-6 6',
    'arrL': 'M19 12H5M11 6l-6 6 6 6',
    'arrD': 'M12 5v14M6 13l6 6 6-6',
    'skip': 'M5 5l8 7-8 7zM15 5v14',
    'info': 'M12 21a9 9 0 100-18 9 9 0 000 18zM12 11v6M12 7.5h.01',
    'bolt': 'M13 3L5 14h6l-1 7 8-11h-6z',
    'filter': 'M4 5h16l-6 8v6l-4-2v-4z',
    'warn': 'M12 4l9 16H3zM12 10v4M12 17h.01',
    'cards': 'M4 7h12v13H4zM8 4h12v13',
    'inbox': 'M4 13l3-8h10l3 8v6H4zM4 13h5l1 2h4l1-2h5',
    'img': 'M4 7h12v13H4zM8 4h12v13',
    'minus': 'M6 12h12',
    'send': 'M20 4v7a4 4 0 01-4 4H5M9 11l-4 4 4 4',
  };
  @override
  Widget build(BuildContext context) => SvgPicture.string(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="${filled ? '#000' : 'none'}" stroke="${filled ? 'none' : '#000'}" stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round"><path d="${_paths[name] ?? _paths['info']}"/></svg>',
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
