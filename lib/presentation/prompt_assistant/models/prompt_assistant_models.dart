import 'dart:convert';

// Legacy storage/UI type. New code should prefer ProviderProtocol and
// ProviderPreset, but this remains to decode existing saved configs.
enum ProviderType { pollinations, openaiCompatible, ollama }

enum ProviderProtocol {
  openaiChatCompletions,
  openaiResponses,
  anthropicMessages,
  geminiGenerateContent,
  ollamaChatCompletions,
}

extension ProviderProtocolLabel on ProviderProtocol {
  String get label {
    switch (this) {
      case ProviderProtocol.openaiChatCompletions:
        return 'OpenAI Chat Completions';
      case ProviderProtocol.openaiResponses:
        return 'OpenAI Responses';
      case ProviderProtocol.anthropicMessages:
        return 'Anthropic Messages';
      case ProviderProtocol.geminiGenerateContent:
        return 'Gemini generateContent';
      case ProviderProtocol.ollamaChatCompletions:
        return 'Ollama Chat Completions';
    }
  }

  bool get supportsModelList => true;

  bool get supportsImagePayload {
    switch (this) {
      case ProviderProtocol.openaiChatCompletions:
      case ProviderProtocol.openaiResponses:
      case ProviderProtocol.anthropicMessages:
      case ProviderProtocol.geminiGenerateContent:
        return true;
      case ProviderProtocol.ollamaChatCompletions:
        return false;
    }
  }
}

enum ProviderPreset {
  openaiChat,
  openaiResponses,
  openaiCompatibleChat,
  openaiCompatibleResponses,
  anthropic,
  gemini,
  deepseek,
  lmStudioChat,
  lmStudioResponses,
  ollama,
  pollinations,
}

extension ProviderPresetDefaults on ProviderPreset {
  String get label {
    switch (this) {
      case ProviderPreset.openaiChat:
        return 'OpenAI Chat Completions';
      case ProviderPreset.openaiResponses:
        return 'OpenAI Responses';
      case ProviderPreset.openaiCompatibleChat:
        return 'OpenAI-compatible Chat';
      case ProviderPreset.openaiCompatibleResponses:
        return 'OpenAI-compatible Responses';
      case ProviderPreset.anthropic:
        return 'Anthropic';
      case ProviderPreset.gemini:
        return 'Gemini';
      case ProviderPreset.deepseek:
        return 'DeepSeek';
      case ProviderPreset.lmStudioChat:
        return 'LM Studio Chat';
      case ProviderPreset.lmStudioResponses:
        return 'LM Studio Responses';
      case ProviderPreset.ollama:
        return 'Ollama';
      case ProviderPreset.pollinations:
        return 'Pollinations';
    }
  }

  String get defaultId {
    switch (this) {
      case ProviderPreset.openaiChat:
        return 'openai_chat';
      case ProviderPreset.openaiResponses:
        return 'openai_responses';
      case ProviderPreset.openaiCompatibleChat:
        return 'openai_compatible_chat';
      case ProviderPreset.openaiCompatibleResponses:
        return 'openai_compatible_responses';
      case ProviderPreset.anthropic:
        return 'anthropic';
      case ProviderPreset.gemini:
        return 'gemini';
      case ProviderPreset.deepseek:
        return 'deepseek';
      case ProviderPreset.lmStudioChat:
        return 'lmstudio_chat';
      case ProviderPreset.lmStudioResponses:
        return 'lmstudio_responses';
      case ProviderPreset.ollama:
        return 'ollama';
      case ProviderPreset.pollinations:
        return 'pollinations';
    }
  }

  String get defaultName {
    switch (this) {
      case ProviderPreset.openaiChat:
        return 'OpenAI Chat';
      case ProviderPreset.openaiResponses:
        return 'OpenAI Responses';
      case ProviderPreset.openaiCompatibleChat:
        return 'OpenAI Compatible Chat';
      case ProviderPreset.openaiCompatibleResponses:
        return 'OpenAI Compatible Responses';
      case ProviderPreset.anthropic:
        return 'Anthropic';
      case ProviderPreset.gemini:
        return 'Gemini';
      case ProviderPreset.deepseek:
        return 'DeepSeek';
      case ProviderPreset.lmStudioChat:
        return 'LM Studio Chat';
      case ProviderPreset.lmStudioResponses:
        return 'LM Studio Responses';
      case ProviderPreset.ollama:
        return 'Ollama';
      case ProviderPreset.pollinations:
        return 'pollinations.ai';
    }
  }

  String get defaultBaseUrl {
    switch (this) {
      case ProviderPreset.openaiChat:
      case ProviderPreset.openaiResponses:
        return 'https://api.openai.com/v1';
      case ProviderPreset.openaiCompatibleChat:
      case ProviderPreset.openaiCompatibleResponses:
        return '';
      case ProviderPreset.anthropic:
        return 'https://api.anthropic.com';
      case ProviderPreset.gemini:
        return 'https://generativelanguage.googleapis.com';
      case ProviderPreset.deepseek:
        return 'https://api.deepseek.com';
      case ProviderPreset.lmStudioChat:
      case ProviderPreset.lmStudioResponses:
        return 'http://localhost:1234/v1';
      case ProviderPreset.ollama:
        return 'http://127.0.0.1:11434/v1';
      case ProviderPreset.pollinations:
        return 'https://gen.pollinations.ai';
    }
  }

  ProviderProtocol get defaultProtocol {
    switch (this) {
      case ProviderPreset.openaiChat:
      case ProviderPreset.openaiCompatibleChat:
      case ProviderPreset.deepseek:
      case ProviderPreset.lmStudioChat:
      case ProviderPreset.pollinations:
        return ProviderProtocol.openaiChatCompletions;
      case ProviderPreset.openaiResponses:
      case ProviderPreset.openaiCompatibleResponses:
      case ProviderPreset.lmStudioResponses:
        return ProviderProtocol.openaiResponses;
      case ProviderPreset.anthropic:
        return ProviderProtocol.anthropicMessages;
      case ProviderPreset.gemini:
        return ProviderProtocol.geminiGenerateContent;
      case ProviderPreset.ollama:
        return ProviderProtocol.ollamaChatCompletions;
    }
  }

  List<String> get defaultModelNames {
    switch (this) {
      case ProviderPreset.openaiChat:
      case ProviderPreset.openaiResponses:
        return const ['gpt-4.1-mini'];
      case ProviderPreset.anthropic:
        return const ['claude-sonnet-4-20250514'];
      case ProviderPreset.gemini:
        return const ['gemini-2.5-flash'];
      case ProviderPreset.deepseek:
        return const ['deepseek-v4-flash', 'deepseek-v4-pro'];
      case ProviderPreset.pollinations:
        return const ['openai-large'];
      case ProviderPreset.openaiCompatibleChat:
      case ProviderPreset.openaiCompatibleResponses:
      case ProviderPreset.lmStudioChat:
      case ProviderPreset.lmStudioResponses:
      case ProviderPreset.ollama:
        return const [];
    }
  }

  bool get requiresApiKey {
    switch (this) {
      case ProviderPreset.lmStudioChat:
      case ProviderPreset.lmStudioResponses:
      case ProviderPreset.ollama:
      case ProviderPreset.pollinations:
        return false;
      case ProviderPreset.openaiChat:
      case ProviderPreset.openaiResponses:
      case ProviderPreset.openaiCompatibleChat:
      case ProviderPreset.openaiCompatibleResponses:
      case ProviderPreset.anthropic:
      case ProviderPreset.gemini:
      case ProviderPreset.deepseek:
        return true;
    }
  }

  bool get defaultAllowImageInput {
    switch (this) {
      case ProviderPreset.openaiChat:
      case ProviderPreset.openaiResponses:
      case ProviderPreset.openaiCompatibleChat:
      case ProviderPreset.openaiCompatibleResponses:
      case ProviderPreset.anthropic:
      case ProviderPreset.gemini:
      case ProviderPreset.lmStudioChat:
      case ProviderPreset.lmStudioResponses:
        return true;
      case ProviderPreset.deepseek:
      case ProviderPreset.ollama:
      case ProviderPreset.pollinations:
        return false;
    }
  }

  ProviderConfig createConfig({String? id}) {
    final resolvedId = (id == null || id.trim().isEmpty)
        ? defaultId
        : id.trim();
    return ProviderConfig(
      id: resolvedId,
      name: defaultName,
      type: legacyType,
      protocol: defaultProtocol,
      preset: this,
      baseUrl: defaultBaseUrl,
      allowImageInput: defaultAllowImageInput,
      enabled: true,
    );
  }

  ProviderType get legacyType {
    switch (this) {
      case ProviderPreset.pollinations:
        return ProviderType.pollinations;
      case ProviderPreset.ollama:
        return ProviderType.ollama;
      case ProviderPreset.openaiChat:
      case ProviderPreset.openaiResponses:
      case ProviderPreset.openaiCompatibleChat:
      case ProviderPreset.openaiCompatibleResponses:
      case ProviderPreset.anthropic:
      case ProviderPreset.gemini:
      case ProviderPreset.deepseek:
      case ProviderPreset.lmStudioChat:
      case ProviderPreset.lmStudioResponses:
        return ProviderType.openaiCompatible;
    }
  }
}

class ProviderConfig {
  final String id;
  final String name;
  final ProviderType type;
  final ProviderProtocol protocol;
  final ProviderPreset? preset;
  final String baseUrl;
  final bool enabled;
  final bool allowImageInput;

  const ProviderConfig({
    required this.id,
    required this.name,
    this.type = ProviderType.openaiCompatible,
    this.protocol = ProviderProtocol.openaiChatCompletions,
    this.preset,
    required this.baseUrl,
    this.enabled = true,
    this.allowImageInput = false,
  });

  ProviderConfig copyWith({
    String? id,
    String? name,
    ProviderType? type,
    ProviderProtocol? protocol,
    ProviderPreset? preset,
    bool clearPreset = false,
    String? baseUrl,
    bool? enabled,
    bool? allowImageInput,
  }) {
    return ProviderConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      protocol: protocol ?? this.protocol,
      preset: clearPreset ? null : preset ?? this.preset,
      baseUrl: baseUrl ?? this.baseUrl,
      enabled: enabled ?? this.enabled,
      allowImageInput: allowImageInput ?? this.allowImageInput,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'protocol': protocol.name,
    'preset': preset?.name,
    'baseUrl': baseUrl,
    'enabled': enabled,
    'allowImageInput': allowImageInput,
  };

  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    final type = ProviderType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => ProviderType.openaiCompatible,
    );
    final preset = _decodePreset(json['preset'] as String?);
    final protocol = _decodeProtocol(
      json['protocol'] as String?,
      legacyType: type,
      preset: preset,
    );
    return ProviderConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      type: type,
      protocol: protocol,
      preset: preset ?? _inferPreset(type, json['id'] as String?, protocol),
      baseUrl: json['baseUrl'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      allowImageInput:
          json['allowImageInput'] as bool? ??
          (preset?.defaultAllowImageInput ?? protocol.supportsImagePayload),
    );
  }

  static ProviderPreset? _decodePreset(String? value) {
    if (value == null || value.isEmpty) return null;
    return ProviderPreset.values.cast<ProviderPreset?>().firstWhere(
      (preset) => preset?.name == value,
      orElse: () => null,
    );
  }

  static ProviderProtocol _decodeProtocol(
    String? value, {
    required ProviderType legacyType,
    required ProviderPreset? preset,
  }) {
    if (value != null && value.isNotEmpty) {
      return ProviderProtocol.values.firstWhere(
        (protocol) => protocol.name == value,
        orElse: () => preset?.defaultProtocol ?? _protocolForLegacy(legacyType),
      );
    }
    return preset?.defaultProtocol ?? _protocolForLegacy(legacyType);
  }

  static ProviderProtocol _protocolForLegacy(ProviderType type) {
    switch (type) {
      case ProviderType.pollinations:
      case ProviderType.openaiCompatible:
        return ProviderProtocol.openaiChatCompletions;
      case ProviderType.ollama:
        return ProviderProtocol.ollamaChatCompletions;
    }
  }

  static ProviderPreset? _inferPreset(
    ProviderType type,
    String? id,
    ProviderProtocol protocol,
  ) {
    if (type == ProviderType.pollinations || id == 'pollinations') {
      return ProviderPreset.pollinations;
    }
    if (type == ProviderType.ollama || id == 'ollama') {
      return ProviderPreset.ollama;
    }
    if (id == 'lmstudio' || id == 'lmstudio_chat') {
      return ProviderPreset.lmStudioChat;
    }
    if (id == 'lmstudio_responses') {
      return ProviderPreset.lmStudioResponses;
    }
    if (id == 'deepseek') {
      return ProviderPreset.deepseek;
    }
    if (id == 'anthropic') {
      return ProviderPreset.anthropic;
    }
    if (id == 'gemini') {
      return ProviderPreset.gemini;
    }
    if (id == 'openai_responses') {
      return ProviderPreset.openaiResponses;
    }
    if (id == 'openai' || id == 'openai_chat') {
      return ProviderPreset.openaiChat;
    }
    if (protocol == ProviderProtocol.openaiResponses) {
      return ProviderPreset.openaiCompatibleResponses;
    }
    return ProviderPreset.openaiCompatibleChat;
  }
}

/// 模型条目的来源，用于刷新模型列表时区分“可回收的 API 模型”与
/// “用户/预设手动模型”，避免弃用模型残留，也避免误删手动模型。
enum ModelSource {
  /// 通过供应商 `/models` 接口拉取；刷新时若不在最新列表里可安全清理。
  api,

  /// 用户手动添加，或添加供应商时自动创建的默认/占位模型；刷新时永不删除。
  manual;

  static ModelSource fromName(String? value) => ModelSource.values.firstWhere(
    (source) => source.name == value,
    orElse: () => ModelSource.manual,
  );
}

class ModelConfig {
  final String providerId;
  final String name;
  final String displayName;
  final bool isDefault;

  /// 该模型是自动拉取（[ModelSource.api]）还是手动/默认（[ModelSource.manual]）。
  /// 默认 [ModelSource.manual]：只有明确从接口拉取的路径才标记为 api，
  /// 因此手动、预设、占位、测试构造的模型天然免于被刷新清理。
  final ModelSource source;

  const ModelConfig({
    required this.providerId,
    required this.name,
    required this.displayName,
    this.isDefault = false,
    this.source = ModelSource.manual,
  });

  bool get isPlaceholder =>
      name.trim().isEmpty || name.trim() == 'default-model';

  ModelConfig copyWith({
    String? providerId,
    String? name,
    String? displayName,
    bool? isDefault,
    ModelSource? source,
  }) {
    return ModelConfig(
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      isDefault: isDefault ?? this.isDefault,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() => {
    'providerId': providerId,
    'name': name,
    'displayName': displayName,
    'isDefault': isDefault,
    'source': source.name,
  };

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      providerId: json['providerId'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String? ?? (json['name'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
      // 来源迁移（关键决策点）：
      // - 新数据带有 'source' 键 → 直接采用。
      // - 旧数据（升级前保存，无该键）→ 按 isDefault 推断：默认/占位模型
      //   视为 manual 永久保留；其余视为 api，让升级后第一次“刷新模型”
      //   就能清掉历史遗留的弃用模型，无需用户手动逐条删除。
      source: json.containsKey('source')
          ? ModelSource.fromName(json['source'] as String?)
          : ((json['isDefault'] as bool? ?? false)
                ? ModelSource.manual
                : ModelSource.api),
    );
  }
}

/// 启动器级 LLM 接口槽。每个槽独立选择服务商与模型，
/// 未配置时执行端回落到第一个启用的服务商及其首个模型。
enum LauncherInterface {
  /// 提示词翻译接口。
  translate,

  /// 词库标签翻译接口（自动补全的 LLM 翻译消费）。
  tagTranslate;

  static LauncherInterface fromName(String? value) =>
      LauncherInterface.values.firstWhere(
        (interface) => interface.name == value,
        orElse: () => LauncherInterface.translate,
      );
}

class InterfaceSlotConfig {
  final String providerId;

  /// 选中的模型名；空串 = 使用该服务商的首个模型。
  final String model;

  const InterfaceSlotConfig({this.providerId = '', this.model = ''});

  bool get isConfigured => providerId.trim().isNotEmpty;

  InterfaceSlotConfig copyWith({String? providerId, String? model}) {
    return InterfaceSlotConfig(
      providerId: providerId ?? this.providerId,
      model: model ?? this.model,
    );
  }

  Map<String, dynamic> toJson() => {'providerId': providerId, 'model': model};

  factory InterfaceSlotConfig.fromJson(Map<String, dynamic> json) {
    return InterfaceSlotConfig(
      providerId: (json['providerId'] as String? ?? '').trim(),
      model: (json['model'] as String? ?? '').trim(),
    );
  }
}

class StreamingChunk {
  final String delta;
  final bool done;

  const StreamingChunk({required this.delta, this.done = false});
}

class PromptAssistantConfigState {
  final List<ProviderConfig> providers;
  final List<ModelConfig> models;
  final Map<LauncherInterface, InterfaceSlotConfig> interfaces;
  final Map<String, bool> providerHasApiKey;

  const PromptAssistantConfigState({
    required this.providers,
    required this.models,
    required this.interfaces,
    required this.providerHasApiKey,
  });

  factory PromptAssistantConfigState.defaults() {
    return const PromptAssistantConfigState(
      providers: [],
      models: [],
      interfaces: {},
      providerHasApiKey: {},
    );
  }

  InterfaceSlotConfig interfaceFor(LauncherInterface interface) {
    return interfaces[interface] ?? const InterfaceSlotConfig();
  }

  /// Prompt translation is user initiated: require an explicit, enabled
  /// provider and a real selected model instead of silently using the first
  /// provider configured for unrelated tasks.
  ({ProviderConfig provider, ModelConfig model})? get promptTranslationRoute {
    final slot = interfaceFor(LauncherInterface.translate);
    if (!slot.isConfigured || slot.model.trim().isEmpty) return null;
    final provider = providers
        .where((item) => item.enabled && item.id == slot.providerId)
        .firstOrNull;
    if (provider == null) return null;
    final model = modelsForProvider(providerId: provider.id)
        .where((item) => !item.isPlaceholder && item.name == slot.model)
        .firstOrNull;
    if (model == null) return null;
    return (provider: provider, model: model);
  }

  PromptAssistantConfigState copyWith({
    List<ProviderConfig>? providers,
    List<ModelConfig>? models,
    Map<LauncherInterface, InterfaceSlotConfig>? interfaces,
    Map<String, bool>? providerHasApiKey,
  }) {
    return PromptAssistantConfigState(
      providers: providers ?? this.providers,
      models: models ?? this.models,
      interfaces: interfaces ?? this.interfaces,
      providerHasApiKey: providerHasApiKey ?? this.providerHasApiKey,
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 2,
    'providers': providers.map((e) => e.toJson()).toList(),
    'models': models.map((e) => e.toJson()).toList(),
    'interfaces': {
      for (final entry in interfaces.entries)
        if (entry.value.isConfigured) entry.key.name: entry.value.toJson(),
    },
  };

  String encode() => jsonEncode(toJson());

  List<ModelConfig> modelsForProvider({required String providerId}) {
    final candidates = <ModelConfig>[];
    final names = <String>{};
    for (final model in models) {
      if (model.providerId != providerId) continue;
      if (!names.add(model.name)) continue;
      candidates.add(model);
    }
    candidates.sort((a, b) {
      final aPlaceholder = a.isPlaceholder;
      final bPlaceholder = b.isPlaceholder;
      if (aPlaceholder != bPlaceholder) {
        return aPlaceholder ? 1 : -1;
      }
      return a.displayName.compareTo(b.displayName);
    });
    return candidates;
  }

  factory PromptAssistantConfigState.decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final defaults = PromptAssistantConfigState.defaults();

    final providersRaw = json['providers'];
    var providers = providersRaw is List && providersRaw.isNotEmpty
        ? providersRaw
              .map((e) => ProviderConfig.fromJson(e as Map<String, dynamic>))
              .toList()
        : defaults.providers;

    final modelsRaw = json['models'];
    var models = modelsRaw is List && modelsRaw.isNotEmpty
        ? _dedupeModels(
            modelsRaw
                .map((e) => ModelConfig.fromJson(e as Map<String, dynamic>))
                .toList(),
          )
        : defaults.models;

    if (_isUntouchedLegacyPollinationsDefault(
      providers: providers,
      models: models,
      schemaVersion: json['schemaVersion'] as int?,
    )) {
      providers = const [];
      models = const [];
    }

    final interfaces = _decodeInterfaces(json, providers: providers);

    return PromptAssistantConfigState(
      providers: providers,
      models: models,
      interfaces: interfaces,
      providerHasApiKey: const {},
    );
  }

  /// 老版本按任务类型把同一模型复制多份（forTask 已废弃），
  /// 解析后按 (providerId, name) 去重，只保留第一份。
  static List<ModelConfig> _dedupeModels(List<ModelConfig> models) {
    final seen = <String>{};
    final result = <ModelConfig>[];
    for (final model in models) {
      if (seen.add('${model.providerId}\x00${model.name}')) {
        result.add(model);
      }
    }
    return result;
  }

  /// 接口槽读取：优先新的 'interfaces' 段；老配置的
  /// 'routing.translateProviderId/translateModel' 迁移为两个接口槽的种子值；
  /// 已删除服务商的槽位被清空，由执行端回落逻辑兜底。
  static Map<LauncherInterface, InterfaceSlotConfig> _decodeInterfaces(
    Map<String, dynamic> json, {
    required List<ProviderConfig> providers,
  }) {
    final interfaces = <LauncherInterface, InterfaceSlotConfig>{};
    final interfacesRaw = json['interfaces'];
    if (interfacesRaw is Map) {
      for (final entry in interfacesRaw.entries) {
        if (entry.value is! Map) continue;
        final slot = InterfaceSlotConfig.fromJson(
          (entry.value as Map).cast<String, dynamic>(),
        );
        interfaces[LauncherInterface.fromName(entry.key as String?)] = slot;
      }
    } else {
      final routing = json['routing'];
      if (routing is Map) {
        final migrated = InterfaceSlotConfig(
          providerId: (routing['translateProviderId'] as String? ?? '').trim(),
          model: (routing['translateModel'] as String? ?? '').trim(),
        );
        if (migrated.isConfigured) {
          interfaces[LauncherInterface.translate] = migrated;
          interfaces[LauncherInterface.tagTranslate] = migrated;
        }
      }
    }

    final providerIds = providers.map((provider) => provider.id).toSet();
    interfaces.removeWhere(
      (_, slot) => slot.isConfigured && !providerIds.contains(slot.providerId),
    );
    return interfaces;
  }

  static bool _isUntouchedLegacyPollinationsDefault({
    required List<ProviderConfig> providers,
    required List<ModelConfig> models,
    required int? schemaVersion,
  }) {
    if (schemaVersion != null) return false;
    final providerIds = providers.map((provider) => provider.id).toSet();
    final isSinglePollinationsDefault =
        providerIds.length == 1 && providerIds.contains('pollinations');
    final isOldThreeProviderDefault =
        providerIds.length == 3 &&
        providerIds.contains('pollinations') &&
        providerIds.contains('openai_custom') &&
        providerIds.contains('ollama');
    if (!isSinglePollinationsDefault && !isOldThreeProviderDefault) {
      return false;
    }
    final pollinations = providers.firstWhere(
      (provider) => provider.id == 'pollinations',
    );
    if (pollinations.enabled != true ||
        pollinations.baseUrl != 'https://gen.pollinations.ai') {
      return false;
    }
    if (isOldThreeProviderDefault) {
      final openai = providers.firstWhere(
        (provider) => provider.id == 'openai_custom',
      );
      final ollama = providers.firstWhere(
        (provider) => provider.id == 'ollama',
      );
      if (openai.enabled ||
          openai.baseUrl != 'https://api.openai.com/v1' ||
          ollama.enabled ||
          ollama.baseUrl != 'http://127.0.0.1:11434/v1') {
        return false;
      }
    }
    if (models.isEmpty) {
      return false;
    }
    return models.every(
      (model) =>
          model.providerId == 'pollinations' &&
          model.name == 'openai-large' &&
          model.isDefault,
    );
  }
}
