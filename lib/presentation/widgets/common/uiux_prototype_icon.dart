import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'uiux_prototype_icon_paths.dart';

enum UiuxPrototypeIconSource { blocks, generation }

/// Uses the actual HTML paths while keeping IconData APIs and stored icon names.
/// Choices without a prototype counterpart use the existing host glyph.
class UiuxPrototypeIcon extends StatelessWidget {
  const UiuxPrototypeIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.strokeWidth = 1.8,
    this.source = UiuxPrototypeIconSource.blocks,
    this.prototypeName,
    this.semanticLabel,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final double strokeWidth;
  final UiuxPrototypeIconSource source;
  final String? prototypeName;
  final String? semanticLabel;

  String? get prototypePath {
    final name = prototypeName ?? _names[icon];
    if (name == null) return null;
    final paths = source == UiuxPrototypeIconSource.blocks
        ? blocksPrototypeIconPaths
        : generationPrototypeIconPaths;
    return paths[name];
  }

  @override
  Widget build(BuildContext context) {
    final path = prototypePath;
    if (path == null) {
      return Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
    }
    final theme = IconTheme.of(context);
    final dimension = size ?? theme.size ?? 24;
    final ink = color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="none" stroke="#000" stroke-width="$strokeWidth" '
      'stroke-linecap="round" stroke-linejoin="round">'
      '<path d="$path"/></svg>',
      width: dimension,
      height: dimension,
      colorFilter: ColorFilter.mode(
        ink.withValues(alpha: ink.a * (theme.opacity ?? 1)),
        BlendMode.srcIn,
      ),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }

  static final _names = <IconData, String>{
    Icons.add: 'plus',
    Icons.add_outlined: 'plus',
    Icons.close: 'x',
    Icons.clear: 'x',
    Icons.expand_more: 'chevD',
    Icons.expand_less: 'chevU',
    Icons.chevron_right: 'chevR',
    Icons.chevron_left: 'chevL',
    Icons.keyboard_arrow_down: 'chevD',
    Icons.keyboard_arrow_up: 'chevU',
    Icons.upload_outlined: 'upload',
    Icons.file_upload_outlined: 'upload',
    Icons.download_outlined: 'download',
    Icons.lock_outline: 'lock',
    Icons.lock_open_outlined: 'unlock',
    Icons.casino_outlined: 'dice',
    Icons.arrow_right_alt: 'seq',
    Icons.error_outline: 'warn',
    Icons.help_outline: 'help',
    Icons.check: 'check',
    Icons.check_circle: 'check',
    Icons.delete_outline: 'trash',
    Icons.more_horiz: 'more',
    Icons.crop_landscape: 'land',
    Icons.crop_portrait: 'port',
    Icons.crop_square: 'sq',
    Icons.palette_outlined: 'palette',
    Icons.color_lens_outlined: 'palette',
    Icons.brush_outlined: 'brush',
    Icons.brush_rounded: 'brush',
    Icons.draw_outlined: 'brush',
    Icons.image_outlined: 'img',
    Icons.person_outline: 'person',
    Icons.star_outline: 'star',
    Icons.bolt_outlined: 'bolt',
    Icons.auto_awesome_outlined: 'spark',
    Icons.wb_sunny_outlined: 'sun',
    Icons.landscape_outlined: 'scene',
    Icons.checkroom_outlined: 'dress',
    Icons.shield_outlined: 'shield',
    Icons.label_outline: 'tag',
    Icons.translate: 'tr',
  };
}
