import '../constants/api_constants.dart';
import '../constants/model_spec.dart';

/// 提示词语义快照
///
/// - basePrompt/baseNegativePrompt: 结构化元数据中保留的基础文本
/// - effectivePrompt/effectiveNegativePrompt: 当前实际送给模型时的等效文本
class PromptSemanticsSnapshot {
  const PromptSemanticsSnapshot({
    required this.basePrompt,
    required this.baseNegativePrompt,
    required this.effectivePrompt,
    required this.effectiveNegativePrompt,
  });

  final String basePrompt;
  final String baseNegativePrompt;
  final String effectivePrompt;
  final String effectiveNegativePrompt;
}

PromptSemanticsSnapshot buildPromptSemanticsSnapshot({
  required String prompt,
  required String negativePrompt,
  required String model,
  required bool qualityToggle,
  required int ucPreset,
  bool transparentBackground = false,
}) {
  // 官方 Transparent BG：把 transparent background 拼在质量词之前
  // （bundle 34342 rr() 把它前置到质量 suffix），仅 transparency 模型生效。
  var promptWithTransparency = prompt;
  if (transparentBackground && ModelSpecs.of(model).transparency) {
    const tag = 'transparent background';
    final trimmed = prompt.trim();
    if (!trimmed.contains(tag)) {
      promptWithTransparency = trimmed.isEmpty
          ? tag
          : (trimmed.endsWith(',') ? '$trimmed $tag' : '$trimmed, $tag');
    }
  }

  final effectivePrompt = qualityToggle
      ? QualityTags.applyQualityTags(promptWithTransparency, model)
      : promptWithTransparency;

  final effectiveNegativePrompt = UcPresets.applyPresetWithNsfwCheck(
    negativePrompt,
    promptWithTransparency,
    model,
    ucPreset,
  );

  return PromptSemanticsSnapshot(
    basePrompt: prompt,
    baseNegativePrompt: negativePrompt,
    effectivePrompt: effectivePrompt,
    effectiveNegativePrompt: effectiveNegativePrompt,
  );
}
