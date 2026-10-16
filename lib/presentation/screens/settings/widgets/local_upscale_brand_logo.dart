import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../../../data/models/upscale/local_upscale_models.dart';
import '../../../widgets/common/upscale_brand_logo.dart';

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
  Widget build(BuildContext context) => method == LocalUpscaleMethod.rtx
      ? UpscaleBrandLogo.nvidia(size: size)
      : UpscaleBrandLogo.seedvr(size: size);
}
