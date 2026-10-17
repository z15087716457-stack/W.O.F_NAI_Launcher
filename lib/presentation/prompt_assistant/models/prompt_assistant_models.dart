import 'dart:convert';

import '../../../l10n/app_localizations.dart';
import 'model_request_overrides.dart';
import 'model_catalog_entry.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/prompt_translation_language.dart';

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
  List<String> get supportedReasoningEfforts => switch (this) {
    ProviderProtocol.openaiChatCompletions ||
    ProviderProtocol.openaiResponses => const [
      'none',
      'minimal',
      'low',
      'medium',
      'high',
      'xhigh',
      'max',
    ],
    ProviderProtocol.anthropicMessages => const [
      'none',
      'low',
      'medium',
      'high',
      'xhigh',
      'max',
    ],
    ProviderProtocol.geminiGenerateContent => const [
      'none',
      'minimal',
      'low',
      'medium',
      'high',
    ],
    ProviderProtocol.ollamaChatCompletions => const [],
  };

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
  togetherAi,
  fireworks,
  cerebras,
  baseten,
  huggingFace,
  nvidia,
  vercel,
  openCodeZen,
  zai,
  zaiCodingPlan,
  zhipuCodingPlan,
  kimiCoding,
  moonshotInternational,
  minimaxChinaChat,
  minimaxChinaMessages,
  minimaxInternationalMessages,
  xiaomi,
  antLing,
  stepfunPlan,
  qwenTokenPlanChina,
}

// Built-in connections; pinned references live in tool/branding/provider_catalog_sources.json.
// These are starter IDs, never a claim about access or a model's capabilities.
class _VendorDefaults {
  const _VendorDefaults(
    this.label,
    this.url,
    this.protocol,
    this.models,
    this.group, {
    this.catalogKey,
    this.logoAsset,
  });
  final String label, url, group;
  final String? catalogKey, logoAsset;
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
    catalogKey: 'openai',
    logoAsset: 'openai',
  ),
  ProviderPreset.openaiResponses: _VendorDefaults(
    'OpenAI',
    'https://api.openai.com/v1',
    ProviderProtocol.openaiResponses,
    ['gpt-6-astra'],
    '国际厂商',
    catalogKey: 'openai',
    logoAsset: 'openai',
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
    catalogKey: 'anthropic',
    logoAsset: 'anthropic',
  ),
  ProviderPreset.gemini: _VendorDefaults(
    'Google Gemini',
    'https://generativelanguage.googleapis.com',
    ProviderProtocol.geminiGenerateContent,
    ['gemini-3.8-flash'],
    '国际厂商',
    catalogKey: 'google',
    logoAsset: 'gemini-color',
  ),
  ProviderPreset.deepseek: _VendorDefaults(
    'DeepSeek',
    'https://api.deepseek.com',
    ProviderProtocol.openaiChatCompletions,
    ['deepseek-flash', 'deepseek-v4-pro'],
    '国内厂商',
    catalogKey: 'deepseek',
    logoAsset: 'deepseek-color',
  ),
  ProviderPreset.lmStudioChat: _VendorDefaults(
    'LM Studio',
    'http://localhost:1234/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '本地与自定义',
    logoAsset: 'lmstudio',
  ),
  ProviderPreset.lmStudioResponses: _VendorDefaults(
    'LM Studio',
    'http://localhost:1234/v1',
    ProviderProtocol.openaiResponses,
    [],
    '本地与自定义',
    logoAsset: 'lmstudio',
  ),
  ProviderPreset.ollama: _VendorDefaults(
    'Ollama',
    'http://127.0.0.1:11434/v1',
    ProviderProtocol.ollamaChatCompletions,
    [],
    '本地与自定义',
    logoAsset: 'ollama',
  ),
  ProviderPreset.pollinations: _VendorDefaults(
    'Pollinations',
    'https://gen.pollinations.ai',
    ProviderProtocol.openaiChatCompletions,
    ['openai-large'],
    '聚合平台',
    logoAsset: 'pollinations',
  ),
  ProviderPreset.qwen: _VendorDefaults(
    '通义千问 · 百炼',
    'https://dashscope.aliyuncs.com/compatible-mode/v1',
    ProviderProtocol.openaiChatCompletions,
    ['qwen-plus'],
    '国内厂商',
    catalogKey: 'alibaba',
    logoAsset: 'qwen',
  ),
  ProviderPreset.moonshot: _VendorDefaults(
    'Kimi · 月之暗面',
    'https://api.moonshot.cn/v1',
    ProviderProtocol.openaiChatCompletions,
    ['kimi-k3'],
    '国内厂商',
    catalogKey: 'moonshotai',
    logoAsset: 'kimi',
  ),
  ProviderPreset.zhipu: _VendorDefaults(
    '智谱 GLM',
    'https://open.bigmodel.cn/api/paas/v4',
    ProviderProtocol.openaiChatCompletions,
    ['glm-5.3'],
    '国内厂商',
    catalogKey: 'zhipuai',
    logoAsset: 'zhipu',
  ),
  ProviderPreset.minimax: _VendorDefaults(
    'MiniMax',
    'https://api.minimax.io/v1',
    ProviderProtocol.openaiChatCompletions,
    ['MiniMax-M3'],
    '国内厂商',
    catalogKey: 'minimax',
    logoAsset: 'minimax',
  ),
  ProviderPreset.doubao: _VendorDefaults(
    '豆包 · 火山方舟',
    'https://ark.cn-beijing.volces.com/api/v3',
    ProviderProtocol.openaiChatCompletions,
    ['doubao-seed-2-1-pro-260628'],
    '国内厂商',
    catalogKey: 'volcengine',
    logoAsset: 'doubao',
  ),
  ProviderPreset.hunyuan: _VendorDefaults(
    '腾讯混元',
    'https://api.hunyuan.cloud.tencent.com/v1',
    ProviderProtocol.openaiChatCompletions,
    ['hunyuan-turbos-latest'],
    '国内厂商',
    catalogKey: 'tencent',
    logoAsset: 'hunyuan',
  ),
  ProviderPreset.qianfan: _VendorDefaults(
    '百度千帆',
    'https://qianfan.baidubce.com/v2',
    ProviderProtocol.openaiChatCompletions,
    [],
    '国内厂商',
    catalogKey: 'baidu',
    logoAsset: 'wenxin',
  ),
  ProviderPreset.xai: _VendorDefaults(
    'xAI · Grok',
    'https://api.x.ai/v1',
    ProviderProtocol.openaiResponses,
    ['grok-4.7'],
    '国际厂商',
    catalogKey: 'xai',
    logoAsset: 'xai',
  ),
  ProviderPreset.mistral: _VendorDefaults(
    'Mistral AI',
    'https://api.mistral.ai/v1',
    ProviderProtocol.openaiChatCompletions,
    ['mistral-small-latest'],
    '国际厂商',
    catalogKey: 'mistral',
    logoAsset: 'mistral',
  ),
  ProviderPreset.groq: _VendorDefaults(
    'Groq',
    'https://api.groq.com/openai/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
    catalogKey: 'groq',
    logoAsset: 'groq',
  ),
  ProviderPreset.siliconflow: _VendorDefaults(
    '硅基流动',
    'https://api.siliconflow.cn/v1',
    ProviderProtocol.openaiChatCompletions,
    ['deepseek-ai/DeepSeek-V4-Flash'],
    '聚合平台',
    catalogKey: 'siliconflow',
    logoAsset: 'siliconcloud',
  ),
  ProviderPreset.openrouter: _VendorDefaults(
    'OpenRouter',
    'https://openrouter.ai/api/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
    catalogKey: 'openrouter',
    logoAsset: 'openrouter',
  ),
  ProviderPreset.togetherAi: _VendorDefaults(
    'Together AI',
    'https://api.together.xyz/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
    catalogKey: 'togetherai',
    logoAsset: 'together',
  ),
  ProviderPreset.fireworks: _VendorDefaults(
    'Fireworks',
    'https://api.fireworks.ai/inference/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
    catalogKey: 'fireworks-ai',
    logoAsset: 'fireworks',
  ),
  ProviderPreset.cerebras: _VendorDefaults(
    'Cerebras',
    'https://api.cerebras.ai/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
    catalogKey: 'cerebras',
    logoAsset: 'cerebras',
  ),
  ProviderPreset.baseten: _VendorDefaults(
    'Baseten',
    'https://inference.baseten.co/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
    catalogKey: 'baseten',
    logoAsset: 'baseten',
  ),
  ProviderPreset.huggingFace: _VendorDefaults(
    'Hugging Face',
    'https://router.huggingface.co/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
    catalogKey: 'huggingface',
    logoAsset: 'huggingface',
  ),
  ProviderPreset.nvidia: _VendorDefaults(
    'NVIDIA',
    'https://integrate.api.nvidia.com/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
    catalogKey: 'nvidia',
    logoAsset: 'nvidia',
  ),
  ProviderPreset.vercel: _VendorDefaults(
    'Vercel AI Gateway',
    'https://ai-gateway.vercel.sh/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
    catalogKey: 'vercel',
    logoAsset: 'vercel',
  ),
  ProviderPreset.openCodeZen: _VendorDefaults(
    'OpenCode Zen',
    'https://opencode.ai/zen/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
    catalogKey: 'opencode',
    logoAsset: 'opencode',
  ),
  ProviderPreset.zai: _VendorDefaults(
    'Z.AI · 国际',
    'https://api.z.ai/api/paas/v4',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
    catalogKey: 'zai',
    logoAsset: 'zai',
  ),
  ProviderPreset.zaiCodingPlan: _VendorDefaults(
    'Z.AI Coding Plan',
    'https://api.z.ai/api/coding/paas/v4',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
    catalogKey: 'zai-coding-plan',
    logoAsset: 'zai',
  ),
  ProviderPreset.zhipuCodingPlan: _VendorDefaults(
    '智谱 Coding Plan',
    'https://open.bigmodel.cn/api/coding/paas/v4',
    ProviderProtocol.openaiChatCompletions,
    [],
    '国内厂商',
    catalogKey: 'zhipuai-coding-plan',
    logoAsset: 'zhipu',
  ),
  ProviderPreset.kimiCoding: _VendorDefaults(
    'Kimi 编程',
    'https://api.kimi.com/coding/v1',
    ProviderProtocol.anthropicMessages,
    [],
    '国内厂商',
    catalogKey: 'kimi-code-plan-cn',
    logoAsset: 'kimi',
  ),
  ProviderPreset.moonshotInternational: _VendorDefaults(
    'Moonshot AI · 国际',
    'https://api.moonshot.ai/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '聚合平台',
    catalogKey: 'moonshotai',
    logoAsset: 'kimi',
  ),
  ProviderPreset.minimaxChinaChat: _VendorDefaults(
    'MiniMax · 国内 OpenAI',
    'https://api.minimaxi.com/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '国内厂商',
    catalogKey: 'minimax-cn',
    logoAsset: 'minimax',
  ),
  ProviderPreset.minimaxChinaMessages: _VendorDefaults(
    'MiniMax · 国内 Anthropic',
    'https://api.minimaxi.com/anthropic/v1',
    ProviderProtocol.anthropicMessages,
    [],
    '国内厂商',
    catalogKey: 'minimax-cn',
    logoAsset: 'minimax',
  ),
  ProviderPreset.minimaxInternationalMessages: _VendorDefaults(
    'MiniMax · 国际 Anthropic',
    'https://api.minimax.io/anthropic/v1',
    ProviderProtocol.anthropicMessages,
    [],
    '聚合平台',
    catalogKey: 'minimax',
    logoAsset: 'minimax',
  ),
  ProviderPreset.xiaomi: _VendorDefaults(
    '小米 MiMo',
    'https://api.xiaomimimo.com/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '国内厂商',
    catalogKey: 'xiaomi',
  ),
  ProviderPreset.antLing: _VendorDefaults(
    '蚂蚁 Ling',
    'https://api.ant-ling.com/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '国内厂商',
    catalogKey: 'ant-ling',
    logoAsset: 'antgroup',
  ),
  ProviderPreset.stepfunPlan: _VendorDefaults(
    '阶跃 Step Plan',
    'https://api.stepfun.com/step_plan/v1',
    ProviderProtocol.anthropicMessages,
    [],
    '国内厂商',
    catalogKey: 'stepfun-step-plan',
    logoAsset: 'stepfun',
  ),
  ProviderPreset.qwenTokenPlanChina: _VendorDefaults(
    '通义 Token 套餐 · 国内',
    'https://token-plan.cn-beijing.maas.aliyuncs.com/compatible-mode/v1',
    ProviderProtocol.openaiChatCompletions,
    [],
    '国内厂商',
    catalogKey: 'alibaba-token-plan-cn',
    logoAsset: 'qwen',
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
  // Display order is shared by the picker and future service consumers.
  static const selectable = [
    ProviderPreset.openaiCompatibleChat,
    ProviderPreset.openaiResponses,
    ProviderPreset.anthropic,
    ProviderPreset.gemini,
    ProviderPreset.xai,
    ProviderPreset.mistral,
    ProviderPreset.deepseek,
    ProviderPreset.qwen,
    ProviderPreset.qwenTokenPlanChina,
    ProviderPreset.moonshot,
    ProviderPreset.moonshotInternational,
    ProviderPreset.kimiCoding,
    ProviderPreset.zhipu,
    ProviderPreset.zhipuCodingPlan,
    ProviderPreset.zai,
    ProviderPreset.zaiCodingPlan,
    ProviderPreset.minimax,
    ProviderPreset.minimaxChinaChat,
    ProviderPreset.minimaxChinaMessages,
    ProviderPreset.minimaxInternationalMessages,
    ProviderPreset.doubao,
    ProviderPreset.hunyuan,
    ProviderPreset.qianfan,
    ProviderPreset.siliconflow,
    ProviderPreset.xiaomi,
    ProviderPreset.antLing,
    ProviderPreset.stepfunPlan,
    ProviderPreset.openrouter,
    ProviderPreset.groq,
    ProviderPreset.togetherAi,
    ProviderPreset.fireworks,
    ProviderPreset.cerebras,
    ProviderPreset.baseten,
    ProviderPreset.huggingFace,
    ProviderPreset.nvidia,
    ProviderPreset.openCodeZen,
    ProviderPreset.vercel,
    ProviderPreset.pollinations,
    ProviderPreset.lmStudioChat,
    ProviderPreset.ollama,
  ];
  String get label => labelIn(currentL10n);
  String labelIn(AppLocalizations l10n) {
    return switch (this) {
      ProviderPreset.openaiCompatibleChat ||
      ProviderPreset.openaiCompatibleResponses => l10n.modelProvider_custom,
      ProviderPreset.qwen => l10n.modelProvider_qwen,
      ProviderPreset.moonshot => l10n.modelProvider_moonshot,
      ProviderPreset.zhipu => l10n.modelProvider_zhipu,
      ProviderPreset.doubao => l10n.modelProvider_doubao,
      ProviderPreset.hunyuan => l10n.modelProvider_hunyuan,
      ProviderPreset.qianfan => l10n.modelProvider_qianfan,
      ProviderPreset.siliconflow => l10n.modelProvider_siliconflow,
      ProviderPreset.zai => l10n.modelProvider_zai,
      ProviderPreset.zhipuCodingPlan => l10n.modelProvider_zhipuCodingPlan,
      ProviderPreset.kimiCoding => l10n.modelProvider_kimiCoding,
      ProviderPreset.moonshotInternational =>
        l10n.modelProvider_moonshotInternational,
      ProviderPreset.minimaxChinaChat => l10n.modelProvider_minimaxChinaChat,
      ProviderPreset.minimaxChinaMessages =>
        l10n.modelProvider_minimaxChinaMessages,
      ProviderPreset.minimaxInternationalMessages =>
        l10n.modelProvider_minimaxInternationalMessages,
      ProviderPreset.xiaomi => l10n.modelProvider_xiaomi,
      ProviderPreset.antLing => l10n.modelProvider_antLing,
      ProviderPreset.stepfunPlan => l10n.modelProvider_stepfunPlan,
      ProviderPreset.qwenTokenPlanChina =>
        l10n.modelProvider_qwenTokenPlanChina,
      _ => _vendorDefaults[this]!.label,
    };
  }

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
  String? get catalogProviderKey => _vendorDefaults[vendor]!.catalogKey;
  String? get logoAsset => _vendorDefaults[this]!.logoAsset;
  bool get isLocal => !requiresApiKey;
  String get searchText =>
      '$label ${_vendorDefaults[this]!.label} $name $defaultBaseUrl ${catalogProviderKey ?? ""}';
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
  String get connectionHint => connectionHintIn(currentL10n);
  String connectionHintIn(AppLocalizations l10n) {
    return switch (vendor) {
      ProviderPreset.huggingFace => l10n.modelProvider_hintHuggingFace,
      ProviderPreset.zaiCodingPlan ||
      ProviderPreset.zhipuCodingPlan ||
      ProviderPreset.kimiCoding ||
      ProviderPreset.stepfunPlan ||
      ProviderPreset.qwenTokenPlanChina => l10n.modelProvider_hintPlanKey,
      ProviderPreset.moonshotInternational =>
        l10n.modelProvider_hintInternationalEndpoint,
      ProviderPreset.minimaxChinaChat => l10n.modelProvider_hintRegionOpenAi,
      ProviderPreset.minimaxChinaMessages ||
      ProviderPreset.minimaxInternationalMessages =>
        l10n.modelProvider_hintRegionAnthropic,
      ProviderPreset.qwen => l10n.modelProvider_hintQwen,
      ProviderPreset.minimax => l10n.modelProvider_hintMinimax,
      ProviderPreset.moonshot => l10n.modelProvider_hintMoonshot,
      ProviderPreset.zhipu => l10n.modelProvider_hintZhipu,
      ProviderPreset.doubao => l10n.modelProvider_hintDoubao,
      ProviderPreset.openaiCompatibleChat => l10n.modelProvider_hintCustom,
      ProviderPreset.lmStudioChat ||
      ProviderPreset.ollama => l10n.modelProvider_hintLocal,
      _ => l10n.modelProvider_hintDefault,
    };
  }

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
  static const defaultRetryAttempts = 1;

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
    this.retryAttempts = defaultRetryAttempts,
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
      retryAttempts:
          ((json['retryAttempts'] as num?)?.toInt() ?? defaultRetryAttempts)
              .clamp(0, 3),
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

/// 保存模型的来源。接口目录只供主动选择，不会自动填入已保存配置。
/// 来源仍保留用于旧配置兼容和显式同步。
enum ModelSource {
  /// 来自供应商 `/models` 接口。
  api,

  /// 用户手动添加；也兼容旧配置中的默认/占位模型。
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
  final ModelReasoningProtocol reasoningProtocol;
  final String? reasoningFormat;
  final bool? supportsNativeSearch;

  /// Null marks legacy data; explicit fields survive future catalog updates.
  final Set<String>? customFields;

  /// Loaded locally, never serialized as a mutable user setting.
  final ModelCatalogEntry? catalogEntry;

  final bool _hasRequestOverrides;
  final ModelRequestOverrides? requestOverrides;
  bool get hasRequestOverrides => requestOverrides == null
      ? _hasRequestOverrides
      : !requestOverrides!.isEmpty;

  /// User-confirmed capabilities; null means unknown.
  final bool? supportsVision, supportsTools, supportsStructuredOutput;

  /// 接口来源或手动来源；新模型必须经用户选择或手动添加后才能保存。
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
    this.reasoningProtocol = ModelReasoningProtocol.standard,
    this.reasoningFormat,
    this.supportsNativeSearch,
    this.customFields,
    this.catalogEntry,
    bool hasRequestOverrides = false,
    this.requestOverrides,
    this.supportsVision,
    this.supportsTools,
    this.supportsStructuredOutput,
  }) : _hasRequestOverrides = hasRequestOverrides;

  bool get isPlaceholder =>
      name.trim().isEmpty || name.trim() == 'default-model';

  List<String> get availableReasoningEfforts => List.unmodifiable(
    reasoningEfforts ?? [if (reasoningEffort != null) reasoningEffort!],
  );

  bool get allowsSampling =>
      catalogEntry?.supportsTemperature != false &&
      reasoningProtocol != ModelReasoningProtocol.adaptive &&
      !(reasoningFormat == 'anthropicBudget' &&
          reasoningEffort != null &&
          reasoningEffort != 'none');

  Set<String> get preservedFields =>
      customFields ??
      {
        if (displayName != name) 'displayName',
        if (contextWindow != null) 'contextWindow',
        if (maxOutputTokens != null) 'maxOutputTokens',
        if (reasoningEffort != null) 'reasoningEffort',
        if (reasoningEfforts != null) 'reasoningEfforts',
        if (supportsVision != null) 'supportsVision',
        if (supportsNativeSearch != null) 'supportsNativeSearch',
        if (reasoningFormat != null) 'reasoningProtocol',
      };

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
    ModelReasoningProtocol? reasoningProtocol,
    String? reasoningFormat,
    bool? supportsNativeSearch,
    bool clearSupportsNativeSearch = false,
    Set<String>? customFields,
    ModelCatalogEntry? catalogEntry,
    bool? hasRequestOverrides,
    ModelRequestOverrides? requestOverrides,
    bool clearRequestOverrides = false,
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
      reasoningProtocol: reasoningProtocol ?? this.reasoningProtocol,
      reasoningFormat: reasoningFormat ?? this.reasoningFormat,
      supportsNativeSearch: clearSupportsNativeSearch
          ? null
          : supportsNativeSearch ?? this.supportsNativeSearch,
      customFields: customFields ?? this.customFields,
      catalogEntry: catalogEntry ?? this.catalogEntry,
      hasRequestOverrides: hasRequestOverrides ?? this.hasRequestOverrides,
      requestOverrides: clearRequestOverrides
          ? null
          : requestOverrides ?? this.requestOverrides,
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
    if (hasRequestOverrides) 'hasRequestOverrides': true,
    if (contextWindow != null) 'contextWindow': contextWindow,
    if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
    if (reasoningEffort != null) 'reasoningEffort': reasoningEffort,
    if (reasoningEfforts != null) 'reasoningEfforts': reasoningEfforts,
    if (temperature != null) 'temperature': temperature,
    if (topP != null) 'topP': topP,
    'reasoningProtocol': reasoningProtocol.name,
    if (reasoningFormat != null) 'reasoningFormat': reasoningFormat,
    if (supportsNativeSearch != null)
      'supportsNativeSearch': supportsNativeSearch,
    if (customFields != null) 'customFields': customFields!.toList(),
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
      hasRequestOverrides: json['hasRequestOverrides'] == true,
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
      reasoningProtocol: json['reasoningProtocol'] == 'adaptive'
          ? ModelReasoningProtocol.adaptive
          : ModelReasoningProtocol.standard,
      reasoningFormat: json['reasoningFormat'] as String?,
      supportsNativeSearch: json['supportsNativeSearch'] as bool?,
      customFields: json['customFields'] is List
          ? Set<String>.unmodifiable(
              (json['customFields'] as List).cast<String>(),
            )
          : null,
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

  /// 选中的模型名。提示词转换要求明确选择；标签任务保留首个已保存模型回退。
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
          json['targetLanguage'] == 'auto' ||
              PromptTranslationLanguage.isCode(json['targetLanguage'])
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
      return currentL10n.modelParams_temperatureRange;
    }
    if (topP != null && (!topP!.isFinite || topP! <= 0 || topP! > 1)) {
      return currentL10n.modelParams_topPRange;
    }
    if (maxOutputTokens != null && maxOutputTokens! <= 0) {
      return currentL10n.modelParams_maxOutputPositive;
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
        return currentL10n.modelParams_anthropicTemperatureRange;
      }
      if (temperature != null && topP != null) {
        return currentL10n.modelParams_anthropicSamplingConflict;
      }
    }
    return null;
  }

  factory RequestParameters.fromModel(ModelConfig model) => RequestParameters(
    temperature: model.allowsSampling ? model.temperature : null,
    topP: model.allowsSampling ? model.topP : null,
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
    'schemaVersion': 7,
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
    return [
      ...candidates.where((model) => !model.isPlaceholder),
      ...candidates.where((model) => model.isPlaceholder),
    ];
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
