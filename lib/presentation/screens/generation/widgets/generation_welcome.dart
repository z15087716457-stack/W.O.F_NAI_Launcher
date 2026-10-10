import 'dart:math' as math;

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../../providers/tips_provider.dart';
import '../../../widgets/branding/brand_entry_scene.dart';
import '../../../widgets/common/tip_welcome.dart';

/// Calm canvas empty state. A tip is chosen once per visit, never on a timer.
class GenerationWelcome extends StatelessWidget {
  const GenerationWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return TipWelcome(
      surface: TipSurface.studio,
      logoAspectRatio: 1111 / 547,
      logoWidthFor: (column) => math.min(300, column * .8),
      logoBuilder: (width) => BrandLogo(width: width),
    );
  }
}
