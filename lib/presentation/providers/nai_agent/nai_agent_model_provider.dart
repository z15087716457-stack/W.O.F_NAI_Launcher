import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/nai_agent/vision_access.dart';
import '../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../prompt_assistant/models/model_request_overrides.dart';
import '../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../prompt_assistant/services/provider_adapters/model_request_options.dart';
import '../../prompt_assistant/services/provider_adapters/prompt_assistant_adapter.dart';

class NaiAgentToolModelUnavailable extends StateError {
  NaiAgentToolModelUnavailable()
    : super('Selected model does not support tools');
}

/// A request-scoped snapshot, never a second settings or credential store.
class NaiAgentModelConnection {
  NaiAgentModelConnection(
    this._private, {
    this.providerName,
    NaiAgentModelConnection Function(String)? reasoningOverride,
    List<String> reasoningEfforts = const [],
  }) : _reasoningOverride = reasoningOverride,
       _reasoningEfforts = List.unmodifiable(reasoningEfforts);
  final Map<String, dynamic> _private;
  final NaiAgentModelConnection Function(String)? _reasoningOverride;
  final List<String> _reasoningEfforts;
  bool get allowsImages => _private['vision'] == true;
  final String? providerName;
  NaiAgentVisionAccess get visionAccess =>
      NaiAgentVisionAccess(providerName: providerName);
  bool supportsReasoningEffort(String effort) =>
      _reasoningEfforts.contains(effort);
  NaiAgentModelConnection withReasoningEffort(String effort) {
    final override = _reasoningOverride;
    if (override == null) throw StateError('Reasoning override unavailable');
    return override(effort);
  }

  /// Only send through the owned child's private stdin. Never log or persist.
  Map<String, dynamic> toPrivateJson() => Map.of(_private);
  Map<String, dynamic> get description => {
    for (final key in [
      'providerId',
      'modelId',
      'protocol',
      'vision',
      'tools',
      'contextWindow',
      'maxTokens',
    ])
      key: _private[key],
    'costKnown': false,
  };
  @override
  String toString() => jsonEncode(description);
}

List<String> naiAgentReasoningEfforts(
  ProviderConfig provider,
  ModelConfig model,
) => [
  for (final effort in model.availableReasoningEfforts)
    if (provider.protocol.supportedReasoningEfforts.contains(effort)) effort,
];

ModelRequestOverrides? _reasoningRequestOverrides(ModelConfig model) {
  final overrides = model.requestOverrides;
  if (overrides == null) return null;
  final body = Map<String, dynamic>.of(overrides.body);
  for (final key in ['reasoning_effort', 'enable_thinking', 'thinking']) {
    body.remove(key);
  }
  for (final entry in {
    'reasoning': 'effort',
    'output_config': 'effort',
    'generationConfig': 'thinkingConfig',
  }.entries) {
    final value = body[entry.key];
    if (value == null) continue;
    if (value is! Map) {
      throw const FormatException(
        'Reasoning request overrides must be objects',
      );
    }
    final fields = Map<String, dynamic>.from(value)..remove(entry.value);
    if (fields.isEmpty) {
      body.remove(entry.key);
    } else {
      body[entry.key] = fields;
    }
  }
  return ModelRequestOverrides(headers: overrides.headers, body: body);
}

NaiAgentModelConnection mapNaiAgentModel(
  ProviderConfig provider,
  ModelConfig model, {
  String? apiKey,
}) {
  if (!provider.enabled ||
      model.providerId != provider.id ||
      model.isPlaceholder) {
    throw StateError('Unavailable Studio model selection');
  }
  if ((model.supportsTools ?? model.catalogEntry?.supportsToolCalling) ==
      false) {
    throw NaiAgentToolModelUnavailable();
  }
  final error = RequestParameters.fromModel(
    model,
  ).validateFor(provider.protocol);
  if (error != null) throw FormatException(error);
  final overrides = model.requestOverrides;
  if (overrides != null) {
    final error = overrides.validate(model.name);
    if (error != null) throw FormatException(error);
  }
  final payload = switch (provider.protocol) {
    ProviderProtocol.openaiChatCompletions ||
    ProviderProtocol.ollamaChatCompletions => {
      ...chatReasoningOptions(provider, model),
    },
    ProviderProtocol.openaiResponses => {
      if (model.reasoningEffort != null)
        'reasoning': {'effort': model.reasoningEffort},
    },
    ProviderProtocol.anthropicMessages => {...anthropicReasoningOptions(model)},
    ProviderProtocol.geminiGenerateContent => {
      'generationConfig': {
        if (model.reasoningEffort != null)
          'thinkingConfig': geminiThinkingOptions(model),
      },
    },
  };
  return NaiAgentModelConnection(
    {
      'providerId': provider.id,
      'modelId': model.name,
      'displayName': model.displayName,
      'protocol': provider.protocol.name,
      'baseUrl': provider.type == ProviderType.pollinations
          ? 'https://gen.pollinations.ai/v1'
          : provider.baseUrl,
      'apiKey': apiKey,
      'headers': promptAssistantHeaders(provider, {}, model: model),
      'body': overrides?.body ?? const {},
      'payloadParameters': payload,
      'contextWindow': model.contextWindow ?? model.catalogEntry?.contextLimit,
      'maxTokens': model.maxOutputTokens ?? model.catalogEntry?.outputLimit,
      'vision': model.supportsVision ?? model.catalogEntry?.supportsVision,
      'tools': model.supportsTools ?? model.catalogEntry?.supportsToolCalling,
      'reasoning':
          model.reasoningEffort != null && model.reasoningEffort != 'none',
      'thinkingLevel': switch (model.reasoningEffort) {
        'minimal' ||
        'low' ||
        'medium' ||
        'high' ||
        'xhigh' => model.reasoningEffort,
        'max' => 'xhigh',
        _ => 'off',
      },
      'timeoutSeconds': provider.timeoutSeconds.clamp(10, 600),
      'retryAttempts': provider.retryAttempts.clamp(0, 5),
      'maxConcurrentRequests': provider.maxConcurrentRequests.clamp(1, 20),
    },
    providerName: provider.name,
    reasoningEfforts: naiAgentReasoningEfforts(provider, model),
    reasoningOverride: (effort) {
      if (!naiAgentReasoningEfforts(provider, model).contains(effort)) {
        throw const FormatException(
          'Unsupported reasoning effort for the selected model',
        );
      }
      return mapNaiAgentModel(
        provider,
        model.copyWith(
          reasoningEffort: effort,
          requestOverrides: _reasoningRequestOverrides(model),
        ),
        apiKey: apiKey,
      );
    },
  );
}

typedef NaiAgentModelResolver =
    Future<NaiAgentModelConnection> Function(String providerId, String modelId);

final naiAgentModelResolverProvider = Provider<NaiAgentModelResolver>((ref) {
  return (providerId, modelId) async {
    final before = ref.read(promptAssistantConfigProvider);
    final provider = before.providers
        .where((p) => p.id == providerId)
        .firstOrNull;
    final model = before.models
        .where((m) => m.providerId == providerId && m.name == modelId)
        .firstOrNull;
    if (provider == null || model == null) {
      throw StateError('Studio model selection no longer exists');
    }
    final notifier = ref.read(promptAssistantConfigProvider.notifier);
    final loaded = await notifier.loadModelRequestOverrides(model);
    final apiKey = await notifier.getProviderApiKey(providerId);
    final headers = await notifier.getProviderHeaders(providerId);
    final now = ref.read(promptAssistantConfigProvider);
    final latestProvider = now.providers
        .where((p) => p.id == providerId)
        .firstOrNull;
    final latestModel = now.models
        .where((m) => m.providerId == providerId && m.name == modelId)
        .firstOrNull;
    // Secret loading is asynchronous; do not use settings changed in that gap.
    if (latestProvider == null ||
        latestModel == null ||
        jsonEncode(provider.toJson()) != jsonEncode(latestProvider.toJson()) ||
        jsonEncode(model.toJson()) != jsonEncode(latestModel.toJson())) {
      throw StateError(
        'Studio model settings changed; resolve the selection again',
      );
    }
    return mapNaiAgentModel(
      provider.copyWith(requestHeaders: headers),
      loaded,
      apiKey: apiKey,
    );
  };
});
