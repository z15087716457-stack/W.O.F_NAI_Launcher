import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../data/models/upscale/local_upscale_models.dart';

/// Decorative identity beside the component's accessible text label.
class LocalUpscaleBrandLogo extends StatelessWidget {
  const LocalUpscaleBrandLogo({
    super.key,
    required this.method,
    this.size = 22,
  });
  final LocalUpscaleMethod method;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (method == LocalUpscaleMethod.rtx) {
      return SvgPicture.asset(
        'assets/icons/providers/nvidia.svg',
        width: size,
        height: size,
        excludeFromSemantics: true,
        colorFilter: const ColorFilter.mode(Color(0xff76b900), BlendMode.srcIn),
      );
    }
    // The official 1280 × 342 artwork combines the emblem and wordmark.
    // Display its 320 × 320 emblem region without modifying the source asset.
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox.square(
              dimension: 320,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: 1280,
                  maxWidth: 1280,
                  minHeight: 342,
                  maxHeight: 342,
                  child: Image.asset(
                    'assets/icons/seedvr_logo.png',
                    width: 1280,
                    height: 342,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
