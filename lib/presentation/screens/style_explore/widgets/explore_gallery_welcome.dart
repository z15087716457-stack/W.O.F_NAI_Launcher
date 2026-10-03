import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../providers/tips_provider.dart';
import '../../../widgets/common/tip_welcome.dart';

/// LAB branding is reserved for the empty exploration gallery.
class ExploreGalleryWelcome extends StatelessWidget {
  const ExploreGalleryWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return TipWelcome(
      surface: TipSurface.lab,
      logoAspectRatio: 1514 / 657,
      // Pixel trails add width beyond the letter bodies.
      // 340px matches the optical height of the 300px STUDIO mark.
      logoWidthFor: (column) => math.min(340, column * .9),
      logoBuilder: (width) => SvgPicture.asset(
        'assets/images/wof_nai_lab.svg',
        width: width,
        semanticsLabel: 'W.O.F NAI LAB',
      ),
    );
  }
}
