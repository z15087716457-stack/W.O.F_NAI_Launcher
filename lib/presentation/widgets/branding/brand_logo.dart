import 'package:flutter/widgets.dart';

/// The complete, original wordmark. The asset only removes empty source margins;
/// both the W.O.F block and the NAI STUDIO signature remain in their original ratio.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 360});
  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/wof_logo_full.png',
    width: width,
    height: width * 547 / 1111,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: 'W.O.F NAI Studio',
  );
}
