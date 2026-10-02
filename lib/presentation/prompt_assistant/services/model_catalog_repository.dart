import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/model_catalog_entry.dart';
import '../models/prompt_assistant_models.dart';

/// Local catalog facts are never inferred from a user's capacity overrides.
class ModelCatalogRepository {
  ModelCatalogRepository._(
    this.entries,
    this.bindings,
    this.providers,
    this.providerEntries,
  );
  static final empty = ModelCatalogRepository._(
    const {},
    const {},
    const {},
    const {},
  );
  static ModelCatalogRepository? cached;
  static Future<ModelCatalogRepository>? _loading;
  final Map<String, ModelCatalogEntry> entries;
  final Map<String, String> bindings;
  final Map<String, List<String>> providers;
  final Map<String, ModelCatalogEntry> providerEntries;

  static Future<ModelCatalogRepository> load() {
    if (cached != null) return Future.value(cached);
    return _loading ??= _read();
  }

  static Future<ModelCatalogRepository> _read() async {
    try {
      final raw = await rootBundle.loadString('assets/data/model_catalog.json');
      return cached = ModelCatalogRepository.decode(raw);
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  factory ModelCatalogRepository.decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return ModelCatalogRepository._(
      {
        for (final value in json['models'] as List)
          (value['id'] as String).toLowerCase(): ModelCatalogEntry.fromJson(
            (value as Map).cast<String, dynamic>(),
          ),
      },
      (json['bindings'] as Map).cast<String, String>(),
      {
        for (final entry in (json['providers'] as Map).entries)
          entry.key as String: List<String>.unmodifiable(
            (entry.value as List).cast<String>(),
          ),
      },
      {
        for (final entry
            in (json['providerModels'] as Map? ?? const {}).entries)
          (entry.key as String).toLowerCase(): ModelCatalogEntry.fromJson(
            (entry.value as Map).cast<String, dynamic>(),
          ),
      },
    );
  }

  String? _vendor(ProviderPreset? preset) => switch (preset?.vendor) {
    ProviderPreset.openaiResponses => 'openai',
    ProviderPreset.anthropic => 'anthropic',
    ProviderPreset.gemini => 'google',
    ProviderPreset.deepseek => 'deepseek',
    ProviderPreset.qwen => 'alibaba',
    ProviderPreset.moonshot => 'moonshotai',
    ProviderPreset.zhipu => 'zhipuai',
    ProviderPreset.minimax => 'minimax',
    ProviderPreset.doubao => 'volcengine',
    ProviderPreset.hunyuan => 'tencent',
    ProviderPreset.qianfan => 'baidu',
    ProviderPreset.xai => 'xai',
    ProviderPreset.mistral => 'mistral',
    ProviderPreset.groq => 'groq',
    ProviderPreset.siliconflow => 'siliconflow',
    ProviderPreset.openrouter => 'openrouter',
    _ => null,
  };

  List<String> namesFor(ProviderPreset preset) {
    final vendor = _vendor(preset);
    if (vendor == null) return const [];
    return providers[vendor] ?? providers['$vendor-cn'] ?? const [];
  }

  ModelCatalogEntry? lookup(ProviderPreset? preset, String name) {
    final key = name.trim().toLowerCase().replaceFirst(RegExp(r'^models/'), '');
    final vendor = _vendor(preset);
    if (vendor != null) {
      final hosted =
          providerEntries['$vendor/$key'] ?? providerEntries['$vendor-cn/$key'];
      if (hosted != null) return hosted;
    }
    if (providerEntries[key] case final hosted?) return hosted;
    final binding = vendor == null
        ? null
        : bindings['$vendor/$key'] ?? bindings['$vendor-cn/$key'];
    if (binding != null) return entries[binding.toLowerCase()];
    if (entries[key] case final entry?) return entry;
    if (vendor != null) {
      final entry = entries['$vendor/$key'];
      if (entry != null) return entry;
    }
    // Unknown gateway prefixes can map only to one exact, known model ID.
    final suffix = key.split('/').last;
    final matches = entries.values
        .where((entry) => entry.id.toLowerCase().split('/').last == suffix)
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  ModelConfig enrich(
    ModelConfig model,
    ProviderPreset? preset, {
    ProviderProtocol? protocol,
  }) {
    final entry = lookup(preset, model.name);
    if (entry == null) return model;
    final preserved = model.preservedFields;
    final efforts = preserved.contains('reasoningEfforts')
        ? model.reasoningEfforts
        : entry.reasoningEfforts;
    var defaultEffort = preserved.contains('reasoningEffort')
        ? model.reasoningEffort
        : entry.defaultReasoningEffort;
    if (defaultEffort != null &&
        efforts != null &&
        !efforts.contains(defaultEffort)) {
      defaultEffort = null;
    }
    return model.copyWith(
      catalogEntry: entry,
      customFields: Set<String>.unmodifiable(preserved),
      displayName: preserved.contains('displayName')
          ? model.displayName
          : entry.name,
      contextWindow: preserved.contains('contextWindow')
          ? model.contextWindow
          : entry.contextLimit,
      maxOutputTokens: preserved.contains('maxOutputTokens')
          ? model.maxOutputTokens
          : entry.outputLimit,
      reasoningEfforts: efforts,
      reasoningEffort: defaultEffort,
      clearReasoningEffort: defaultEffort == null,
      supportsVision: preserved.contains('supportsVision')
          ? model.supportsVision
          : entry.supportsVision,
      supportsNativeSearch: preserved.contains('supportsNativeSearch')
          ? model.supportsNativeSearch
          : entry.supportsNativeSearch,
      reasoningProtocol: preserved.contains('reasoningProtocol')
          ? model.reasoningProtocol
          : protocol == ProviderProtocol.anthropicMessages
          ? entry.reasoningProtocol
          : ModelReasoningProtocol.standard,
      reasoningFormat: entry.reasoningFormat,
    );
  }
}
