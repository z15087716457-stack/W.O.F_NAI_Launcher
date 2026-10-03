import '../../models/model_catalog_entry.dart';
import '../../models/prompt_assistant_models.dart';
import '../../../../core/utils/localization_extension.dart';

bool allowsModelSampling(ModelConfig? model) => model?.allowsSampling ?? true;

/// Budget APIs have no named native effort levels. These are client presets,
/// constrained by the catalog and by the requested total output budget.
int modelThinkingBudget(ModelConfig model, {bool anthropic = false}) {
  if (model.reasoningEffort == 'none') return 0;
  final minimum = model.catalogEntry?.budgetMin ?? (anthropic ? 1024 : 128);
  final catalogMaximum = model.catalogEntry?.budgetMax ?? 32768;
  final maximum = anthropic && model.maxOutputTokens != null
      ? (model.maxOutputTokens! - 1).clamp(0, catalogMaximum)
      : catalogMaximum;
  if (maximum < minimum) {
    throw StateError(currentL10n.modelParams_thinkingBudgetTooSmall(minimum));
  }
  final proposed = switch (model.reasoningEffort) {
    'minimal' => minimum,
    'low' => 1024,
    'medium' => 8192,
    'high' || 'xhigh' || 'max' => catalogMaximum,
    _ => 8192,
  };
  return proposed.clamp(minimum, maximum);
}

Map<String, dynamic> chatReasoningOptions(
  ProviderConfig provider,
  ModelConfig? model,
) {
  final effort = model?.reasoningEffort;
  if (effort == null) return const {};
  if (provider.preset?.vendor == ProviderPreset.deepseek) {
    return {
      'thinking': {'type': effort == 'none' ? 'disabled' : 'enabled'},
      if (effort != 'none') 'reasoning_effort': effort,
    };
  }
  if (provider.preset?.vendor == ProviderPreset.qwen &&
      model?.reasoningFormat == 'qwenToggle') {
    return {'enable_thinking': effort != 'none'};
  }
  return {'reasoning_effort': effort};
}

Map<String, dynamic> anthropicReasoningOptions(ModelConfig? model) {
  if (model == null) return const {};
  if (model.reasoningEffort == 'none') {
    return {
      'thinking': {'type': 'disabled'},
    };
  }
  if (model.reasoningFormat == 'anthropicBudget' &&
      model.reasoningEffort != null) {
    return {
      'thinking': {
        'type': 'enabled',
        'budget_tokens': modelThinkingBudget(model, anthropic: true),
      },
    };
  }
  return {
    if (model.reasoningProtocol == ModelReasoningProtocol.adaptive)
      'thinking': {'type': 'adaptive'},
    if (model.reasoningEffort != null)
      'output_config': {'effort': model.reasoningEffort},
  };
}

Map<String, dynamic> geminiThinkingOptions(ModelConfig model) =>
    model.reasoningFormat == 'geminiBudget'
    ? {'thinkingBudget': modelThinkingBudget(model)}
    : {'thinkingLevel': model.reasoningEffort!.toUpperCase()};
