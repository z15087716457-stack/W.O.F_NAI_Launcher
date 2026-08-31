import '../../data/models/prompt/prompt_preset_mode.dart';
import '../constants/api_constants.dart';
import '../enums/quality_tag_preset.dart';

class PromptPresetResolution {
  const PromptPresetResolution({
    required this.prompt,
    required this.negativePrompt,
    required this.qualityToggle,
    required this.qualityTagPreset,
    required this.ucPreset,
  });

  final String prompt;
  final String negativePrompt;
  final bool qualityToggle;
  final QualityTagPreset qualityTagPreset;
  final int ucPreset;
}

PromptPresetResolution resolvePromptPresetSettings({
  required String prompt,
  required String negativePrompt,
  required PromptPresetMode qualityMode,
  required String? qualityContent,
  required UcPresetType ucPresetType,
  required String? ucPresetContent,
  required bool useCustomUcPreset,
}) {
  final resolvedPrompt = switch (qualityMode) {
    PromptPresetMode.custom => _joinPromptParts([prompt, qualityContent]),
    PromptPresetMode.naiDefault ||
    PromptPresetMode.naiLight ||
    PromptPresetMode.none => prompt,
  };
  final qualityTagPreset = switch (qualityMode) {
    PromptPresetMode.naiDefault => QualityTagPreset.standard,
    PromptPresetMode.naiLight => QualityTagPreset.light,
    PromptPresetMode.none || PromptPresetMode.custom => QualityTagPreset.none,
  };

  final resolvedNegativePrompt = useCustomUcPreset
      ? _joinPromptParts([ucPresetContent, negativePrompt])
      : negativePrompt;

  return PromptPresetResolution(
    prompt: resolvedPrompt,
    negativePrompt: resolvedNegativePrompt,
    qualityToggle: qualityTagPreset != QualityTagPreset.none,
    qualityTagPreset: qualityTagPreset,
    ucPreset: useCustomUcPreset
        ? UcPresets.noneApiValue
        : UcPresets.toApiValue(ucPresetType),
  );
}

String _joinPromptParts(Iterable<String?> parts) {
  return parts
      .map((part) => part?.trim() ?? '')
      .where((part) => part.isNotEmpty)
      .join(', ');
}
