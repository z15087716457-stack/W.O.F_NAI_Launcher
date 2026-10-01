import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../widgets/common/studio_icons.dart';

/// Provider identity comes from the selected vendor, independently of protocol.
class ProviderLogo extends StatelessWidget {
  const ProviderLogo(this.preset, {super.key, this.size = 24});
  final ProviderPreset? preset;
  final double size;

  static String? assetFor(ProviderPreset? preset) => switch (preset) {
    ProviderPreset.openaiChat || ProviderPreset.openaiResponses => 'openai',
    ProviderPreset.anthropic => 'anthropic',
    ProviderPreset.gemini => 'gemini-color',
    ProviderPreset.deepseek => 'deepseek-color',
    ProviderPreset.lmStudioChat ||
    ProviderPreset.lmStudioResponses => 'lmstudio',
    ProviderPreset.ollama => 'ollama',
    ProviderPreset.pollinations => 'pollinations',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(preset);
    if (asset == null) {
      return Icon(
        StudioIcons.settingsModels,
        size: size,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    final colored = asset.endsWith('-color');
    return SvgPicture.asset(
      'assets/icons/providers/$asset.svg',
      width: size,
      height: size,
      colorFilter: colored
          ? null
          : ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
    );
  }
}
