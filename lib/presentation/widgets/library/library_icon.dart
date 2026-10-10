import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'library_icon_paths.dart';

/// Exact SVG paths exported from refs/mock.html. No Material substitutes.
class LibraryIcon extends StatelessWidget {
  const LibraryIcon(
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
  @override
  Widget build(BuildContext context) => SvgPicture.string(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
    'fill="${filled ? '#000' : 'none'}" stroke="${filled ? 'none' : '#000'}" '
    'stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="${libraryPrototypeIconPaths[name]}"/></svg>',
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
