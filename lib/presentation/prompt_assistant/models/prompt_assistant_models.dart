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
  qwen,
  moonshot,
  zhipu,
  minimax,
  doubao,
  hunyuan,
  qianfan,
  xai,
  mistral,
  groq,
  siliconflow,
  openrouter,
}

// Built-in vendor connections, checked against official docs on 2026-10-02.
// These are starter IDs, never a claim about access or a model's capabilities.
class _VendorDefaults {
  const _VendorDefaults(
    this.label,
    this.url,
    this.protocol,
    this.models,
    this.group,
  );
  final String label, url, group;
  final ProviderProtocol protocol;
  final List<String> models;
}

const _vendorDefaults = <ProviderPreset, _VendorDefaults>{
  ProviderPreset.openaiChat: _VendorDefaults(
    'OpenAI',
    'https://api.openai.com/v1',
    ProviderProtocol.openaiChatCompletions,
    ['gpt-4.1-mini'],
    '国际厂商',
  ),
  ProviderPreset.openaiResponses: _VendorDefaults(
    'OpenAI',
    'https://api.openai.com/v1',
    ProviderProtocol.openaiResponses,
    ['gpt-6-astra'],
    '国际厂商',
  ),
  ProviderPreset.openaiCompatibleChat: _VendorDefaults(
    '自定义服务',
    '',
    ProviderProtocol.openaiChatCompletions,
    [],
    '本地与自定义',
  ),
  ProviderPreset.openaiCompatibleResponses: _VendorDefaults(
    '自定义服务',
    '',
    ProviderProtocol.openaiResponses,
    [],
    '本地与自定义',
  ),
  ProviderPreset.anthropic: _VendorDefaults(
    'Anthropic',
    'https://api.anthropic.com',
    ProviderProtocol.anthropicMessages,
    ['claude-sonnet-5-5'],
    '国际厂商',
  ),
  ProviderPreset.gemini: _VendorDefaults(
    'Google Gemini',
    'https://generativelanguage.googleapis.com',
    ProviderProtocol.geminiGenerateContent,
    ['gemini-3.8-flash'],
    '国际厂商',
  ),
  ProviderPreset.deepseek: _VendorDefaults(
    'DeepSeek',
    'https://api.deepseek.com',
    ProviderProtocol.openaiChatCompletions,
    ['deepseek-flash', 'deepseek-v4-pro'],
    '国内厂商',
  ),
  ProviderPreset.lmStudioChat: _VendorDefaults(
    'LM Studio',
    'http://localhost:1234/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '本地与自定义',
  ),
  ProviderPreset.lmStudioResponses: _VendorDefaults(
    'LM Studio',
    'http://localhost:1234/v1',
    ProviderProtocol.openaiResponses,
    [],
    '本地与自定义',
  ),
  ProviderPreset.ollama: _VendorDefaults(
    'Ollama',
    'http://127.0.0.1:11434/v1',
    ProviderProtocol.ollamaChatCompletions,
    [],
    '本地与自定义',
  ),
  ProviderPreset.pollinations: _VendorDefaults(
    'Pollinations',
    'https://gen.pollinations.ai',
    ProviderProtocol.openaiChatCompletions,
    ['openai-large'],
    '聚合平台',
  ),
  ProviderPreset.qwen: _VendorDefaults(
    '通义千问 · 百炼',
    'https://dashscope.aliyuncs.com/compatible-mode/v1',
    ProviderProtocol.openaiChatCompletions,
    ['qwen-plus'],
    '国内厂商',
  ),
  ProviderPreset.moonshot: _VendorDefaults(
    'Kimi · 月之暗面',
    'https://api.moonshot.cn/v1',
    ProviderProtocol.openaiChatCompletions,
    ['kimi-k3'],
    '国内厂商',
  ),
  ProviderPreset.zhipu: _VendorDefaults(
    '智谱 GLM',
    'https://open.bigmodel.cn/api/paas/v4',
    ProviderProtocol.openaiChatCompletions,
    ['glm-5.3'],
    '国内厂商',
  ),
  ProviderPreset.minimax: _VendorDefaults(
    'MiniMax',
    'https://api.minimax.io/v1',
    ProviderProtocol.openaiChatCompletions,
    ['MiniMax-M3'],
    '国内厂商',
  ),
  ProviderPreset.doubao: _VendorDefaults(
    '豆包 · 火山方舟',
    'https://ark.cn-beijing.volces.com/api/v3',
    ProviderProtocol.openaiChatCompletions,
    ['doubao-seed-2-1-pro-260628'],
    '国内厂商',
  ),
  ProviderPreset.hunyuan: _VendorDefaults(
    '腾讯混元',
    'https://api.hunyuan.cloud.tencent.com/v1',
    ProviderProtocol.openaiChatCompletions,
    ['hunyuan-turbos-latest'],
    '国内厂商',
  ),
  ProviderPreset.qianfan: _VendorDefaults(
    '百度千帆',
    'https://qianfan.baidubce.com/v2',
    ProviderProtocol.openaiChatCompletions,
    [],
    '国内厂商',
  ),
  ProviderPreset.xai: _VendorDefaults(
    'xAI · Grok',
    'https://api.x.ai/v1',
    ProviderProtocol.openaiResponses,
    ['grok-4.7'],
    '国际厂商',
  ),
  ProviderPreset.mistral: _VendorDefaults(
    'Mistral AI',
    'https://api.mistral.ai/v1',
    ProviderProtocol.openaiChatCompletions,
    ['mistral-small-latest'],
    '国际厂商',
  ),
  ProviderPreset.groq: _VendorDefaults(
    'Groq',
    'https://api.groq.com/openai/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
  ),
  ProviderPreset.siliconflow: _VendorDefaults(
    '硅基流动',
    'https://api.siliconflow.cn/v1',
    ProviderProtocol.openaiChatCompletions,
    ['deepseek-ai/DeepSeek-V4-Flash'],
    '聚合平台',
  ),
  ProviderPreset.openrouter: _VendorDefaults(
    'OpenRouter',
    'https://openrouter.ai/api/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
  ),
};

extension ProviderPresetDefaults on ProviderPreset {
  ProviderPreset get vendor => switch (this) {
    ProviderPreset.openaiChat => ProviderPreset.openaiResponses,
    ProviderPreset.openaiCompatibleResponses =>
      ProviderPreset.openaiCompatibleChat,
    ProviderPreset.lmStudioResponses => ProviderPreset.lmStudioChat,
    _ => this,
  };
  static const selectable = [
    ProviderPreset.deepseek,
    ProviderPreset.qwen,
    ProviderPreset.moonshot,
    ProviderPreset.zhipu,
    ProviderPreset.minimax,
    ProviderPreset.doubao,
    ProviderPreset.hunyuan,
    ProviderPreset.qianfan,
    ProviderPreset.openaiResponses,
    ProviderPreset.anthropic,
    ProviderPreset.gemini,
    ProviderPreset.xai,
    ProviderPreset.mistral,
    ProviderPreset.siliconflow,
    ProviderPreset.openrouter,
    ProviderPreset.groq,
    ProviderPreset.pollinations,
    ProviderPreset.lmStudioChat,
    ProviderPreset.ollama,
    ProviderPreset.openaiCompatibleChat,
  ];
  String get label => _vendorDefaults[this]!.label;
  String get group => _vendorDefaults[this]!.group;
  String get defaultId => switch (this) {
    ProviderPreset.openaiChat => 'openai_chat',
    ProviderPreset.openaiResponses => 'openai_responses',
    ProviderPreset.openaiCompatibleChat => 'openai_compatible_chat',
    ProviderPreset.openaiCompatibleResponses => 'openai_compatible_responses',
    ProviderPreset.lmStudioChat => 'lmstudio_chat',
    ProviderPreset.lmStudioResponses => 'lmstudio_responses',
    _ => name,
  };
  String get defaultName => label;
  String get defaultBaseUrl => _vendorDefaults[this]!.url;
  ProviderProtocol get defaultProtocol => _vendorDefaults[this]!.protocol;
  List<String> get defaultModelNames => _vendorDefaults[this]!.models;
  bool get requiresApiKey => ![
    ProviderPreset.lmStudioChat,
    ProviderPreset.lmStudioResponses,
    ProviderPreset.ollama,
  ].contains(this);
  bool get defaultAllowImageInput => [
    ProviderPreset.openaiChat,
    ProviderPreset.openaiResponses,
    ProviderPreset.anthropic,
    ProviderPreset.gemini,
    ProviderPreset.openaiCompatibleChat,
    ProviderPreset.openaiCompatibleResponses,
    ProviderPreset.lmStudioChat,
    ProviderPreset.lmStudioResponses,
  ].contains(this);
  String get connectionHint => switch (vendor) {
    ProviderPreset.qwen => '默认北京区域；其他区域请使用对应 Key 并修改接口地址。',
    ProviderPreset.minimax => '默认国际按量接口；国内平台请使用对应区域的 Key 和接口地址。',
    ProviderPreset.moonshot => '默认国内平台；国际平台请使用对应区域的 Key 和接口地址。',
    ProviderPreset.zhipu => '默认按量接口；Coding Plan 请使用套餐专用地址。',
    ProviderPreset.doubao => '使用方舟 API Key；需先开通模型，也可添加推理接入点 ID。',
    ProviderPreset.openaiCompatibleChat => '填写兼容服务的地址与 Key，并在连接信息中选择接口协议。',
    ProviderPreset.lmStudioChat ||
    ProviderPreset.ollama => '先启动本地服务，再读取已加载的模型目录。',
    _ => '地址与协议已预填；保存 Key 后即可选择模型使用。',
  };
  ProviderConfig createConfig({String? id}) => ProviderConfig(
    id: id == null || id.trim().isEmpty ? defaultId : id.trim(),
    name: defaultName,
    type: legacyType,
    protocol: defaultProtocol,
    preset: this,
    baseUrl: defaultBaseUrl,
    allowImageInput: defaultAllowImageInput,
    enabled: true,
  );
  ProviderType get legacyType => switch (this) {
    ProviderPreset.pollinations => ProviderType.pollinations,
    ProviderPreset.ollama => ProviderType.ollama,
    _ => ProviderType.openaiCompatible,
  };
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
  final int timeoutSeconds;
  final int maxConcurrentRequests;
  final int retryAttempts;

  /// Loaded from secure storage for a request; never serialized with the
  /// ordinary settings JSON because header values may contain credentials.
  final Map<String, String> requestHeaders;

  const ProviderConfig({
    required this.id,
    required this.name,
    this.type = ProviderType.openaiCompatible,
    this.protocol = ProviderProtocol.openaiChatCompletions,
    this.preset,
    required this.baseUrl,
    this.enabled = true,
    this.allowImageInput = false,
    this.timeoutSeconds = 120,
    this.maxConcurrentRequests = 5,
    this.retryAttempts = 0,
    this.requestHeaders = const {},
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
    int? timeoutSeconds,
    int? maxConcurrentRequests,
    int? retryAttempts,
    Map<String, String>? requestHeaders,
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
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      maxConcurrentRequests:
          maxConcurrentRequests ?? this.maxConcurrentRequests,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      requestHeaders: requestHeaders ?? this.requestHeaders,
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
    'timeoutSeconds': timeoutSeconds,
    'maxConcurrentRequests': maxConcurrentRequests,
    'retryAttempts': retryAttempts,
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
      timeoutSeconds: ((json['timeoutSeconds'] as num?)?.toInt() ?? 120).clamp(
        10,
        600,
      ),
      maxConcurrentRequests:
          ((json['maxConcurrentRequests'] as num?)?.toInt() ?? 5).clamp(1, 20),
      retryAttempts: ((json['retryAttempts'] as num?)?.toInt() ?? 0).clamp(
        0,
        3,
      ),
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

  /// Reference only: the current client does not truncate input by tokens.
  final int? contextWindow;
  final int? maxOutputTokens;

  /// Optional request control. Availability depends on the actual model.
  final String? reasoningEffort;

  /// Provider-owned, user-confirmed reasoning capability. Null is unknown;
  /// an empty list explicitly means this model has no adjustable reasoning.
  final List<String>? reasoningEfforts;
  final double? temperature;
  final double? topP;

  /// User-confirmed capabilities; null means unknown.
  final bool? supportsVision, supportsTools, supportsStructuredOutput;

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
    this.contextWindow,
    this.maxOutputTokens,
    this.reasoningEffort,
    this.reasoningEfforts,
    this.temperature,
    this.topP,
    this.supportsVision,
    this.supportsTools,
    this.supportsStructuredOutput,
  });

  bool get isPlaceholder =>
      name.trim().isEmpty || name.trim() == 'default-model';

  List<String> get availableReasoningEfforts => List.unmodifiable(
    reasoningEfforts ?? [if (reasoningEffort != null) reasoningEffort!],
  );

  ModelConfig copyWith({
    String? providerId,
    String? name,
    String? displayName,
    bool? isDefault,
    ModelSource? source,
    int? contextWindow,
    int? maxOutputTokens,
    String? reasoningEffort,
    bool clearReasoningEffort = false,
    List<String>? reasoningEfforts,
    bool clearReasoningEfforts = false,
    double? temperature,
    double? topP,
    bool clearTemperature = false,
    bool clearTopP = false,
    bool clearMaxOutputTokens = false,
    bool clearContextWindow = false,
    bool? supportsVision,
    bool? supportsTools,
    bool? supportsStructuredOutput,
    bool clearSupportsVision = false,
    bool clearSupportsTools = false,
    bool clearSupportsStructuredOutput = false,
  }) {
    return ModelConfig(
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      isDefault: isDefault ?? this.isDefault,
      source: source ?? this.source,
      contextWindow: clearContextWindow
          ? null
          : contextWindow ?? this.contextWindow,
      maxOutputTokens: clearMaxOutputTokens
          ? null
          : maxOutputTokens ?? this.maxOutputTokens,
      reasoningEffort: clearReasoningEffort
          ? null
          : reasoningEffort ?? this.reasoningEffort,
      reasoningEfforts: clearReasoningEfforts
          ? null
          : reasoningEfforts ?? this.reasoningEfforts,
      temperature: clearTemperature ? null : temperature ?? this.temperature,
      topP: clearTopP ? null : topP ?? this.topP,
      supportsVision: clearSupportsVision
          ? null
          : supportsVision ?? this.supportsVision,
      supportsTools: clearSupportsTools
          ? null
          : supportsTools ?? this.supportsTools,
      supportsStructuredOutput: clearSupportsStructuredOutput
          ? null
          : supportsStructuredOutput ?? this.supportsStructuredOutput,
    );
  }

  Map<String, dynamic> toJson() => {
    'providerId': providerId,
    'name': name,
    'displayName': displayName,
    'isDefault': isDefault,
    'source': source.name,
    if (contextWindow != null) 'contextWindow': contextWindow,
    if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
    if (reasoningEffort != null) 'reasoningEffort': reasoningEffort,
    if (reasoningEfforts != null) 'reasoningEfforts': reasoningEfforts,
    if (temperature != null) 'temperature': temperature,
    if (topP != null) 'topP': topP,
    if (supportsVision != null) 'supportsVision': supportsVision,
    if (supportsTools != null) 'supportsTools': supportsTools,
    if (supportsStructuredOutput != null)
      'supportsStructuredOutput': supportsStructuredOutput,
  };

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      providerId: json['providerId'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String? ?? (json['name'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
      contextWindow: (json['contextWindow'] as num?)?.toInt(),
      maxOutputTokens: (json['maxOutputTokens'] as num?)?.toInt(),
      reasoningEffort: json['reasoningEffort'] as String?,
      reasoningEfforts: json['reasoningEfforts'] is List
          ? List<String>.unmodifiable(
              (json['reasoningEfforts'] as List).whereType<String>().toSet(),
            )
          : null,
      temperature: (json['temperature'] as num?)?.toDouble(),
      topP: (json['topP'] as num?)?.toDouble(),
      supportsVision: json['supportsVision'] as bool?,
      supportsTools: json['supportsTools'] as bool?,
      supportsStructuredOutput: json['supportsStructuredOutput'] as bool?,
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
  promptReverse,

  /// 词库标签翻译接口（自动补全的 LLM 翻译消费）。
  tagTranslate,
  wikiTranslate;

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
  final String? presetId;
  final String targetLanguage;

  /// Null follows the model's default; this is the sole task-level parameter.
  final String? reasoningEffort;

  const InterfaceSlotConfig({
    this.providerId = '',
    this.model = '',
    this.presetId,
    this.targetLanguage = 'auto',
    this.reasoningEffort,
  });

  bool get isConfigured => providerId.trim().isNotEmpty;

  InterfaceSlotConfig copyWith({
    String? providerId,
    String? model,
    String? presetId,
    String? targetLanguage,
    String? reasoningEffort,
    bool clearReasoningEffort = false,
  }) {
    return InterfaceSlotConfig(
      providerId: providerId ?? this.providerId,
      model: model ?? this.model,
      presetId: presetId ?? this.presetId,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      reasoningEffort: clearReasoningEffort
          ? null
          : reasoningEffort ?? this.reasoningEffort,
    );
  }

  Map<String, dynamic> toJson() => {
    'providerId': providerId,
    'model': model,
    if (presetId != null) 'presetId': presetId,
    'targetLanguage': targetLanguage,
    if (reasoningEffort != null) 'reasoningEffort': reasoningEffort,
  };

  factory InterfaceSlotConfig.fromJson(Map<String, dynamic> json) {
    return InterfaceSlotConfig(
      providerId: (json['providerId'] as String? ?? '').trim(),
      model: (json['model'] as String? ?? '').trim(),
      presetId: json['presetId'] as String?,
      reasoningEffort: json['reasoningEffort'] as String?,
      targetLanguage:
          const [
            'auto',
            'zh',
            'en',
            'ja',
            'ko',
          ].contains(json['targetLanguage'])
          ? json['targetLanguage'] as String
          : 'auto',
    );
  }
}

class RequestParameters {
  const RequestParameters({
    this.temperature,
    this.topP,
    this.maxOutputTokens,
    this.reasoningEffort,
  });
  final double? temperature, topP;
  final int? maxOutputTokens;
  final String? reasoningEffort;
  Map<String, dynamic> toJson() => {
    if (temperature != null) 'temperature': temperature,
    if (topP != null) 'topP': topP,
    if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
    if (reasoningEffort != null) 'reasoningEffort': reasoningEffort,
  };
  factory RequestParameters.fromJson(Object? value) {
    final json = value is Map ? value : const {};
    return RequestParameters(
      temperature: (json['temperature'] as num?)?.toDouble(),
      topP: (json['topP'] as num?)?.toDouble(),
      maxOutputTokens: (json['maxOutputTokens'] as num?)?.toInt(),
      reasoningEffort: json['reasoningEffort'] as String?,
    );
  }
  String? get validationError {
    if (temperature != null &&
        (!temperature!.isFinite || temperature! < 0 || temperature! > 2)) {
      return 'Temperature 应在 0–2 之间。';
    }
    if (topP != null && (!topP!.isFinite || topP! <= 0 || topP! > 1)) {
      return 'Top P 应大于 0 且不超过 1。';
    }
    if (maxOutputTokens != null && maxOutputTokens! <= 0) {
      return '最大输出 token 必须大于 0。';
    }
    return null;
  }

  ModelConfig applyTo(ModelConfig base) => base.copyWith(
    temperature: temperature,
    topP: topP,
    maxOutputTokens: maxOutputTokens,
    reasoningEffort: reasoningEffort,
  );

  String? validateFor(ProviderProtocol protocol) {
    final general = validationError;
    if (general != null) return general;
    if (protocol == ProviderProtocol.anthropicMessages) {
      if (temperature != null && temperature! > 1) {
        return 'Anthropic 的 Temperature 应在 0–1 之间。';
      }
      if (temperature != null && topP != null) {
        return 'Anthropic 的 Temperature 与 Top P 请选择一项；请检查模型参数。';
      }
    }
    return null;
  }

  factory RequestParameters.fromModel(ModelConfig model) => RequestParameters(
    temperature: model.temperature,
    topP: model.topP,
    maxOutputTokens: model.maxOutputTokens,
    reasoningEffort: model.reasoningEffort,
  );
}

class TaskPresetConfig {
  const TaskPresetConfig({
    required this.id,
    required this.name,
    required this.task,
    required this.prompt,
  });
  final String id, name, prompt;
  final LauncherInterface task;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'task': task.name,
    'prompt': prompt,
  };
  factory TaskPresetConfig.fromJson(Map<String, dynamic> json) =>
      TaskPresetConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        task: LauncherInterface.fromName(json['task'] as String?),
        prompt: json['prompt'] as String? ?? '',
      );
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
  final List<TaskPresetConfig> presets;

  const PromptAssistantConfigState({
    required this.providers,
    required this.models,
    required this.interfaces,
    required this.providerHasApiKey,
    this.presets = const [],
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
    return interfaces[interface] ??
        switch (interface) {
          LauncherInterface.promptReverse =>
            interfaces[LauncherInterface.translate],
          LauncherInterface.wikiTranslate =>
            interfaces[LauncherInterface.tagTranslate],
          _ => null,
        } ??
        const InterfaceSlotConfig();
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
    List<TaskPresetConfig>? presets,
  }) {
    return PromptAssistantConfigState(
      providers: providers ?? this.providers,
      models: models ?? this.models,
      interfaces: interfaces ?? this.interfaces,
      providerHasApiKey: providerHasApiKey ?? this.providerHasApiKey,
      presets: presets ?? this.presets,
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 5,
    'presets': presets.map((e) => e.toJson()).toList(),
    'providers': providers.map((e) => e.toJson()).toList(),
    'models': models.map((e) => e.toJson()).toList(),
    'interfaces': {
      for (final entry in interfaces.entries)
        entry.key.name: entry.value.toJson(),
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
      presets: [
        if (json['presets'] is List)
          for (final preset in json['presets'] as List)
            if (preset is Map<String, dynamic> &&
                !(preset['id'] as String? ?? '').startsWith('builtin:'))
              TaskPresetConfig.fromJson(preset),
      ],
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
        if (!LauncherInterface.values.any((task) => task.name == entry.key)) {
          continue;
        }
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
    for (final entry in interfaces.entries.toList()) {
      if (entry.value.isConfigured &&
          !providerIds.contains(entry.value.providerId)) {
        final slot = entry.value;
        if (slot.presetId == null && slot.targetLanguage == 'auto') {
          interfaces.remove(entry.key);
        } else {
          interfaces[entry.key] = slot.copyWith(providerId: '', model: '');
        }
      }
    }
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
