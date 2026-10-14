import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shared sampling for small SVG icons, without changing their geometry.
/// Low-density displays use a 2x raster to soften subpixel diagonal edges;
/// higher densities and large graphics retain direct vector rendering.
class UiSvgIcon extends StatelessWidget {
  const UiSvgIcon.asset(
    String asset, {
    super.key,
    this.size = 16,
    this.colorFilter,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  }) : _asset = asset,
       _source = null;

  const UiSvgIcon.string(
    String source, {
    super.key,
    this.size = 16,
    this.colorFilter,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  }) : _source = source,
       _asset = null;

  final String? _asset;
  final String? _source;
  final double size;
  final ColorFilter? colorFilter;
  final String? semanticsLabel;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final dpr = media?.devicePixelRatio ?? View.of(context).devicePixelRatio;
    final smooth = size <= 24 && dpr < 1.5;
    final picture = _asset != null
        ? SvgPicture.asset(
            _asset,
            width: size,
            height: size,
            colorFilter: colorFilter,
            semanticsLabel: semanticsLabel,
            excludeFromSemantics: excludeFromSemantics,
            renderingStrategy: smooth ? .raster : .picture,
          )
        : SvgPicture.string(
            _source!,
            width: size,
            height: size,
            colorFilter: colorFilter,
            semanticsLabel: semanticsLabel,
            excludeFromSemantics: excludeFromSemantics,
            renderingStrategy: smooth ? .raster : .picture,
          );
    if (!smooth) return picture;
    return MediaQuery(
      data: (media ?? MediaQueryData.fromView(View.of(context))).copyWith(
        devicePixelRatio: dpr * 2,
      ),
      child: picture,
    );
  }
}
