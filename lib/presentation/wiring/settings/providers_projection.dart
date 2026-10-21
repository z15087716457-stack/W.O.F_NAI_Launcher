import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/utils/localization_extension.dart';
import '../../prompt_assistant/models/model_catalog_entry.dart';
import '../../prompt_assistant/models/model_request_overrides.dart';
import '../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../ui/model_providers/model_providers_contract.dart';

ProviderSettings projectProviderSettings(
  ProviderConfig provider,
  List<ModelConfig> models,
  Map<String, String> headers,
) => ProviderSettings(
  name: provider.name,
  baseUrl: provider.baseUrl,
  protocolId: provider.protocol.name,
  timeoutSeconds: provider.timeoutSeconds,
  maxConcurrency: provider.maxConcurrentRequests,
  retryAttempts: provider.retryAttempts,
  headers: [for (final e in headers.entries) ProviderKeyValue(e.key, e.value)],
  models: [
    for (final m in models)
      if (!m.isPlaceholder) projectProviderModel(m),
  ],
);

ProviderModelSettings projectProviderModel(
  ModelConfig m,
) => ProviderModelSettings(
  id: m.name,
  alias: m.displayName == m.name ? '' : m.displayName,
  contextWindow: m.contextWindow,
  maxOutput: m.maxOutputTokens,
  reasoningLevels:
      m.reasoningEfforts == null && m.availableReasoningEfforts.isEmpty
      ? null
      : m.availableReasoningEfforts,
  defaultLevel: m.reasoningEffort,
  adaptiveReasoning: m.reasoningProtocol == ModelReasoningProtocol.adaptive,
  capabilities: {
    if ((m.supportsVision ?? m.catalogEntry?.supportsVision) == true)
      ProviderCapability.vision,
    if ((m.supportsTools ?? m.catalogEntry?.supportsToolCalling) == true)
      ProviderCapability.tools,
    if ((m.supportsNativeSearch ?? m.catalogEntry?.supportsNativeSearch) ==
        true)
      ProviderCapability.search,
  },
  body: [
    for (final e in (m.requestOverrides?.body ?? <String, dynamic>{}).entries)
      ProviderKeyValue(e.key, jsonEncode(e.value)),
  ],
  headers: [
    for (final e in (m.requestOverrides?.headers ?? <String, String>{}).entries)
      ProviderKeyValue(e.key, e.value),
  ],
);

Map<String, String> providerHeaders(List<ProviderKeyValue> rows) {
  final result = <String, String>{};
  final seen = <String>{};
  for (final row in rows) {
    final key = row.key.trim();
    if (!seen.add(key.toLowerCase())) {
      throw FormatException(currentL10n.mp_duplicateKey);
    }
    final error = ModelRequestOverrides.headerError(key, row.value);
    if (error != null) throw FormatException(error);
    result[key] = row.value;
  }
  return result;
}

ModelRequestOverrides providerOverrides(ProviderModelSettings edited) {
  final body = <String, dynamic>{};
  for (final row in edited.body) {
    final key = row.key.trim();
    if (body.containsKey(key)) {
      throw FormatException(currentL10n.mp_duplicateKey);
    }
    body[key] = jsonDecode(row.value);
  }
  final options = ModelRequestOverrides(
    headers: providerHeaders(edited.headers),
    body: body,
  );
  final error = options.validate(edited.id);
  if (error != null) throw FormatException(error);
  return options;
}

ProviderConfig mergeProviderSettings(
  ProviderConfig latest,
  ProviderSettings edited,
) => latest.copyWith(
  name: edited.name.trim(),
  baseUrl: edited.baseUrl.trim(),
  protocol: ProviderProtocol.values.byName(edited.protocolId),
  timeoutSeconds: edited.timeoutSeconds,
  maxConcurrentRequests: edited.maxConcurrency,
  retryAttempts: edited.retryAttempts,
  requestHeaders: providerHeaders(edited.headers),
);

/// Only changed, visible fields become user overrides. All hidden fields (and
/// null capabilities / legacy reasoning lists) come from the latest model.
ModelConfig mergeProviderModel(
  ModelConfig latest,
  ProviderModelSettings base,
  ProviderModelSettings edited,
) {
  var next = latest;
  final fields = <String>{};
  if (base.alias != edited.alias) {
    next = next.copyWith(
      displayName: edited.alias.trim().isEmpty
          ? latest.name
          : edited.alias.trim(),
    );
    fields.add('displayName');
  }
  if (base.contextWindow != edited.contextWindow) {
    next = next.copyWith(
      contextWindow: edited.contextWindow,
      clearContextWindow: edited.contextWindow == null,
    );
    fields.add('contextWindow');
  }
  if (base.maxOutput != edited.maxOutput) {
    next = next.copyWith(
      maxOutputTokens: edited.maxOutput,
      clearMaxOutputTokens: edited.maxOutput == null,
    );
    fields.add('maxOutputTokens');
  }
  if (!listEquals(base.reasoningLevels, edited.reasoningLevels)) {
    next = next.copyWith(
      reasoningEfforts: edited.reasoningLevels,
      clearReasoningEfforts: edited.reasoningLevels == null,
    );
    fields.add('reasoningEfforts');
  }
  if (base.defaultLevel != edited.defaultLevel) {
    next = next.copyWith(
      reasoningEffort: edited.defaultLevel,
      clearReasoningEffort: edited.defaultLevel == null,
    );
    fields.add('reasoningEffort');
  }
  if (base.adaptiveReasoning != edited.adaptiveReasoning) {
    next = next.copyWith(
      reasoningProtocol: edited.adaptiveReasoning
          ? ModelReasoningProtocol.adaptive
          : ModelReasoningProtocol.standard,
    );
    fields.add('reasoningProtocol');
  }
  for (final capability in ProviderCapability.values) {
    final value = edited.capabilities.contains(capability);
    if (base.capabilities.contains(capability) == value) continue;
    switch (capability) {
      case ProviderCapability.vision:
        next = next.copyWith(supportsVision: value);
        fields.add('supportsVision');
      case ProviderCapability.tools:
        next = next.copyWith(supportsTools: value);
        fields.add('supportsTools');
      case ProviderCapability.search:
        next = next.copyWith(supportsNativeSearch: value);
        fields.add('supportsNativeSearch');
    }
  }
  final options = providerOverrides(edited);
  return next.copyWith(
    customFields: fields.isEmpty
        ? latest.customFields
        : {...latest.preservedFields, ...fields},
    requestOverrides: options,
    hasRequestOverrides: !options.isEmpty,
  );
}

void validateProviderDraft(ProviderConfig p, List<ModelConfig> models) {
  final l = currentL10n;
  final url = Uri.tryParse(p.baseUrl);
  String? error = p.timeoutSeconds < 10 || p.timeoutSeconds > 600
      ? l.modelService_timeoutRange
      : p.maxConcurrentRequests < 1 || p.maxConcurrentRequests > 20
      ? l.modelService_concurrencyRange
      : p.retryAttempts < 0 || p.retryAttempts > 3
      ? l.mp_retryRange
      : p.name.isEmpty
      ? l.modelService_nameRequired
      : p.baseUrl.isNotEmpty &&
            (url == null ||
                !url.hasAuthority ||
                !{'http', 'https'}.contains(url.scheme))
      ? l.modelService_invalidUrl
      : null;
  if (error != null) throw FormatException(error);
  final names = <String>{};
  for (final m in models.where((m) => !m.isPlaceholder)) {
    if (!names.add(m.name)) throw FormatException(l.mp_duplicateKey);
    error =
        m.requestOverrides?.validate(m.name) ??
        RequestParameters.fromModel(m).validateFor(p.protocol);
    error ??= m.contextWindow != null && m.contextWindow! <= 0
        ? l.modelService_contextPositive
        : null;
    error ??=
        m.maxOutputTokens != null &&
            m.contextWindow != null &&
            m.maxOutputTokens! > m.contextWindow!
        ? l.modelCard_outputExceedsContext
        : null;
    for (final (value, limit) in [
      (m.contextWindow, m.catalogEntry?.contextLimit),
      (m.maxOutputTokens, m.catalogEntry?.outputLimit),
    ]) {
      if (value != null && limit != null && value > limit) {
        error ??= l.modelCard_catalogLimit(modelTokenLabel(limit));
      }
    }
    if (error != null) throw FormatException(error);
  }
}

String? providerCatalogPrice(ModelCatalogEntry? entry) {
  final input = entry?.cost['input'], output = entry?.cost['output'];
  if (input is! num || output is! num || !input.isFinite || !output.isFinite) {
    return null;
  }
  String number(num n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  return '\$${number(input)} / \$${number(output)}';
}

ProviderGroup providerGroup(ProviderPreset? preset) {
  // Group strings are legacy data, not UI copy. Keep this adapter free of
  // language-dependent comparisons and distinguish regional preset variants.
  if (preset == null) return ProviderGroup.local;
  if ({
    ProviderPreset.openaiCompatibleChat,
    ProviderPreset.openaiCompatibleResponses,
    ProviderPreset.lmStudioChat,
    ProviderPreset.lmStudioResponses,
    ProviderPreset.ollama,
  }.contains(preset)) {
    return ProviderGroup.local;
  }
  if ({
    ProviderPreset.openaiChat,
    ProviderPreset.openaiResponses,
    ProviderPreset.anthropic,
    ProviderPreset.gemini,
    ProviderPreset.xai,
    ProviderPreset.mistral,
  }.contains(preset)) {
    return ProviderGroup.international;
  }
  if ({
    ProviderPreset.deepseek,
    ProviderPreset.qwen,
    ProviderPreset.moonshot,
    ProviderPreset.zhipu,
    ProviderPreset.minimax,
    ProviderPreset.doubao,
    ProviderPreset.hunyuan,
    ProviderPreset.qianfan,
    ProviderPreset.zhipuCodingPlan,
    ProviderPreset.kimiCoding,
    ProviderPreset.minimaxChinaChat,
    ProviderPreset.minimaxChinaMessages,
    ProviderPreset.xiaomi,
    ProviderPreset.antLing,
    ProviderPreset.stepfunPlan,
    ProviderPreset.qwenTokenPlanChina,
  }.contains(preset)) {
    return ProviderGroup.domestic;
  }
  return ProviderGroup.aggregator;
}
