import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../widgets/common/studio_icons.dart';

/// Provider identity comes from the selected vendor, independently of protocol.
class ProviderLogo extends StatelessWidget {
  const ProviderLogo(this.preset, {super.key, this.size = 24});
  final ProviderPreset? preset;
  final double size;

  static String? assetFor(ProviderPreset? preset) => preset?.logoAsset;

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(preset);
    if (asset == null) {
      return Icon(
        StudioIcons.settingsModels,
        size: size,
        color: Theme.of(context).colorScheme.onSurface,
      );
    }
    return SvgPicture.asset(
      'assets/icons/providers/$asset.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.onSurface,
        BlendMode.srcIn,
      ),
    );
  }
}
