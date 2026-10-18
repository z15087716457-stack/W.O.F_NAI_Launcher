import '../settings/settings_contract.dart'
    show SettingsModelTask, SettingsTone;
import 'model_providers_contract.dart';

/// 假数据：照 `.devin/mockups/model-providers/app.js` 的 PROV（方案 B）。服务商、地址和模型 ID
/// 取自现有预设；延迟、价格、目录数量都是示意值。ID 和设置页旧假数据一致（ds / oa / an / gm / ol），
/// 搜索跳转 `provider-<id>` 能选中同一个服务商。
abstract final class ProvidersFixture {
  /// 与 [SettingsFixture.now] 相同：2026-10-14 16:40。
  static final now = DateTime(2026, 10, 14, 16, 40);

  static DateTime _ago({int d = 0, int h = 0, int m = 0, int s = 0}) =>
      now.subtract(Duration(days: d, hours: h, minutes: m, seconds: s));

  static const _oai = [
    'none',
    'minimal',
    'low',
    'medium',
    'high',
    'xhigh',
    'max',
  ];

  static const protocols = [
    ProvidersProtocol(
      id: 'openaiChatCompletions',
      label: 'OpenAI Chat Completions',
      reasoningLevels: _oai,
    ),
    ProvidersProtocol(
      id: 'openaiResponses',
      label: 'OpenAI Responses',
      reasoningLevels: _oai,
    ),
    ProvidersProtocol(
      id: 'anthropicMessages',
      label: 'Anthropic Messages',
      reasoningLevels: ['none', 'low', 'medium', 'high', 'xhigh', 'max'],
    ),
    ProvidersProtocol(
      id: 'geminiGenerateContent',
      label: 'Gemini generateContent',
      reasoningLevels: ['none', 'minimal', 'low', 'medium', 'high'],
    ),
    ProvidersProtocol(
      id: 'ollamaChatCompletions',
      label: 'Ollama Chat Completions',
    ),
  ];

  static const presets = [
    ProviderPresetItem(
      id: 'deepseek',
      name: 'DeepSeek',
      group: ProviderGroup.domestic,
      host: 'api.deepseek.com',
      logoAsset: 'deepseek-color',
    ),
    ProviderPresetItem(
      id: 'qwen',
      name: '通义千问 · 百炼',
      group: ProviderGroup.domestic,
      host: 'dashscope.aliyuncs.com',
      logoAsset: 'qwen',
    ),
    ProviderPresetItem(
      id: 'moonshot',
      name: 'Kimi · 月之暗面',
      group: ProviderGroup.domestic,
      host: 'api.moonshot.cn',
      logoAsset: 'kimi',
    ),
    ProviderPresetItem(
      id: 'zhipu',
      name: '智谱 GLM',
      group: ProviderGroup.domestic,
      host: 'open.bigmodel.cn',
      logoAsset: 'zhipu',
    ),
    ProviderPresetItem(
      id: 'minimax',
      name: 'MiniMax',
      group: ProviderGroup.domestic,
      host: 'api.minimax.io',
      logoAsset: 'minimax',
    ),
    ProviderPresetItem(
      id: 'doubao',
      name: '豆包 · 火山方舟',
      group: ProviderGroup.domestic,
      host: 'ark.cn-beijing.volces.com',
      logoAsset: 'doubao',
    ),
    ProviderPresetItem(
      id: 'hunyuan',
      name: '腾讯混元',
      group: ProviderGroup.domestic,
      host: 'api.hunyuan.cloud.tencent.com',
      logoAsset: 'hunyuan',
    ),
    ProviderPresetItem(
      id: 'qianfan',
      name: '百度千帆',
      group: ProviderGroup.domestic,
      host: 'qianfan.baidubce.com',
      logoAsset: 'wenxin',
    ),
    ProviderPresetItem(
      id: 'openaiChat',
      name: 'OpenAI',
      group: ProviderGroup.international,
      host: 'api.openai.com',
      logoAsset: 'openai',
    ),
    ProviderPresetItem(
      id: 'anthropic',
      name: 'Anthropic',
      group: ProviderGroup.international,
      host: 'api.anthropic.com',
      logoAsset: 'anthropic',
    ),
    ProviderPresetItem(
      id: 'gemini',
      name: 'Google Gemini',
      group: ProviderGroup.international,
      host: 'generativelanguage.googleapis.com',
      logoAsset: 'gemini-color',
    ),
    ProviderPresetItem(
      id: 'xai',
      name: 'xAI · Grok',
      group: ProviderGroup.international,
      host: 'api.x.ai',
      logoAsset: 'xai',
    ),
    ProviderPresetItem(
      id: 'mistral',
      name: 'Mistral AI',
      group: ProviderGroup.international,
      host: 'api.mistral.ai',
      logoAsset: 'mistral',
    ),
    ProviderPresetItem(
      id: 'openrouter',
      name: 'OpenRouter',
      group: ProviderGroup.aggregator,
      host: 'openrouter.ai',
      logoAsset: 'openrouter',
    ),
    ProviderPresetItem(
      id: 'siliconflow',
      name: '硅基流动',
      group: ProviderGroup.aggregator,
      host: 'api.siliconflow.cn',
      logoAsset: 'siliconcloud',
    ),
    ProviderPresetItem(
      id: 'groq',
      name: 'Groq',
      group: ProviderGroup.aggregator,
      host: 'api.groq.com',
      logoAsset: 'groq',
    ),
    ProviderPresetItem(
      id: 'togetherAi',
      name: 'Together AI',
      group: ProviderGroup.aggregator,
      host: 'api.together.xyz',
      logoAsset: 'together',
    ),
    ProviderPresetItem(
      id: 'ollama',
      name: 'Ollama',
      group: ProviderGroup.local,
      host: '127.0.0.1:11434',
      logoAsset: 'ollama',
    ),
    ProviderPresetItem(
      id: 'lmStudioChat',
      name: 'LM Studio',
      group: ProviderGroup.local,
      host: 'localhost:1234',
      logoAsset: 'lmstudio',
    ),
    ProviderPresetItem(
      id: 'openaiCompatibleChat',
      name: '自定义端点',
      group: ProviderGroup.local,
      host: '填写兼容接口地址',
      custom: true,
    ),
  ];

  static const _flash = ProviderModelSettings(
    id: 'deepseek-flash',
    contextWindow: 128000,
    maxOutput: 8000,
    reasoningLevels: ['none', 'high'],
    defaultLevel: 'none',
    temperature: 1.3,
    capabilities: {
      ProviderCapability.vision,
      ProviderCapability.tools,
      ProviderCapability.structured,
    },
  );

  static const _pro = ProviderModelSettings(
    id: 'deepseek-v4-pro',
    contextWindow: 128000,
    maxOutput: 32000,
    reasoningLevels: ['none', 'low', 'medium', 'high', 'max'],
    defaultLevel: 'high',
    adaptiveReasoning: true,
    temperature: .7,
    capabilities: {ProviderCapability.tools, ProviderCapability.structured},
    body: [ProviderKeyValue('response_format', '{"type":"json_object"}')],
  );

  static ProviderItem get deepseek => ProviderItem(
    id: 'ds',
    presetId: 'deepseek',
    group: ProviderGroup.domestic,
    logoAsset: 'deepseek-color',
    apiKeyMasked: 'sk-••••••••••••••••3f9a',
    status: SettingsTone.ok,
    latencyMs: 96,
    checkedAt: _ago(s: 5),
    hint: '地址与协议已预填；保存 Key 后即可选择模型使用。',
    settings: const ProviderSettings(
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      protocolId: 'openaiChatCompletions',
      imageInput: true,
      models: [_flash, _pro],
    ),
    models: const {
      'deepseek-flash': ProviderModelInfo(
        detail: 'DeepSeek V4.1 Flash',
        usedFor: {
          SettingsModelTask.promptTranslate,
          SettingsModelTask.tagTranslate,
        },
      ),
      'deepseek-v4-pro': ProviderModelInfo(
        detail: 'DeepSeek V4 Pro',
        usedFor: {SettingsModelTask.promptReverse},
      ),
    },
  );

  static List<ProviderItem> get providers => [
    deepseek,
    ProviderItem(
      id: 'oa',
      presetId: 'openaiResponses',
      group: ProviderGroup.international,
      logoAsset: 'openai',
      apiKeyMasked: 'sk-proj-••••••••••••7c21',
      status: SettingsTone.ok,
      latencyMs: 312,
      checkedAt: _ago(m: 3),
      settings: const ProviderSettings(
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        protocolId: 'openaiResponses',
        imageInput: true,
        models: [
          ProviderModelSettings(
            id: 'gpt-4.1-mini',
            contextWindow: 1000000,
            maxOutput: 32000,
            reasoningLevels: [],
            capabilities: {
              ProviderCapability.vision,
              ProviderCapability.tools,
              ProviderCapability.structured,
            },
          ),
          ProviderModelSettings(
            id: 'gpt-6-astra',
            contextWindow: 400000,
            maxOutput: 128000,
            reasoningLevels: ['minimal', 'low', 'medium', 'high', 'xhigh'],
            defaultLevel: 'medium',
            capabilities: {
              ProviderCapability.vision,
              ProviderCapability.tools,
              ProviderCapability.structured,
              ProviderCapability.search,
            },
          ),
        ],
      ),
      models: const {
        'gpt-4.1-mini': ProviderModelInfo(
          detail: 'GPT-4.1 mini',
          usedFor: {SettingsModelTask.wikiTranslate},
        ),
        'gpt-6-astra': ProviderModelInfo(detail: 'GPT-6 Astra'),
      },
    ),
    ProviderItem(
      id: 'an',
      presetId: 'anthropic',
      group: ProviderGroup.international,
      logoAsset: 'anthropic',
      apiKeyMasked: 'sk-ant-••••••••••••d0e4',
      status: SettingsTone.ok,
      latencyMs: 420,
      checkedAt: _ago(m: 12),
      settings: const ProviderSettings(
        name: 'Anthropic',
        baseUrl: 'https://api.anthropic.com',
        protocolId: 'anthropicMessages',
        timeoutSeconds: 180,
        maxConcurrency: 3,
        retryAttempts: 2,
        imageInput: true,
        models: [
          ProviderModelSettings(
            id: 'claude-sonnet-5-5',
            contextWindow: 1000000,
            maxOutput: 64000,
            reasoningLevels: ['none', 'low', 'medium', 'high', 'max'],
            defaultLevel: 'low',
            capabilities: {
              ProviderCapability.vision,
              ProviderCapability.tools,
              ProviderCapability.structured,
            },
          ),
          ProviderModelSettings(
            id: 'claude-haiku-5',
            contextWindow: 200000,
            maxOutput: 32000,
            reasoningLevels: ['none', 'low'],
            defaultLevel: 'none',
            capabilities: {ProviderCapability.vision, ProviderCapability.tools},
          ),
        ],
      ),
      models: const {
        'claude-sonnet-5-5': ProviderModelInfo(detail: 'Claude Sonnet 5.5'),
        'claude-haiku-5': ProviderModelInfo(detail: 'Claude Haiku 5'),
      },
    ),
    const ProviderItem(
      id: 'gm',
      presetId: 'gemini',
      group: ProviderGroup.international,
      logoAsset: 'gemini-color',
      enabled: false,
      apiKeyMasked: 'AIza••••••••••••Qm8',
      settings: ProviderSettings(
        name: 'Google Gemini',
        baseUrl: 'https://generativelanguage.googleapis.com',
        protocolId: 'geminiGenerateContent',
        imageInput: true,
        models: [
          ProviderModelSettings(
            id: 'gemini-3.8-flash',
            contextWindow: 1000000,
            maxOutput: 64000,
            capabilities: {
              ProviderCapability.vision,
              ProviderCapability.tools,
              ProviderCapability.structured,
              ProviderCapability.search,
            },
          ),
        ],
      ),
      models: {
        'gemini-3.8-flash': ProviderModelInfo(detail: 'Gemini 3.8 Flash'),
      },
    ),
    ProviderItem(
      id: 'or',
      presetId: 'openrouter',
      group: ProviderGroup.aggregator,
      logoAsset: 'openrouter',
      apiKeyMasked: 'sk-or-v1-••••••••••••a9b2',
      status: SettingsTone.ok,
      latencyMs: 188,
      checkedAt: _ago(h: 1),
      settings: const ProviderSettings(
        name: 'OpenRouter',
        baseUrl: 'https://openrouter.ai/api/v1',
        protocolId: 'openaiChatCompletions',
        maxConcurrency: 8,
        imageInput: true,
        headers: [
          ProviderKeyValue('HTTP-Referer', 'https://wof.studio'),
          ProviderKeyValue('X-Title', 'W.O.F NAI Studio'),
        ],
        models: [
          ProviderModelSettings(
            id: 'anthropic/claude-sonnet-5-5',
            contextWindow: 1000000,
            maxOutput: 64000,
            reasoningLevels: ['none', 'low', 'high'],
            defaultLevel: 'none',
            capabilities: {ProviderCapability.vision, ProviderCapability.tools},
          ),
          ProviderModelSettings(
            id: 'google/gemini-3.8-pro',
            contextWindow: 2000000,
            maxOutput: 64000,
            capabilities: {
              ProviderCapability.vision,
              ProviderCapability.tools,
              ProviderCapability.search,
            },
          ),
          ProviderModelSettings(
            id: 'qwen/qwen3.5-max',
            contextWindow: 256000,
            maxOutput: 32000,
            reasoningLevels: [],
            capabilities: {ProviderCapability.tools},
          ),
        ],
      ),
    ),
    ProviderItem(
      id: 'ol',
      presetId: 'ollama',
      group: ProviderGroup.local,
      logoAsset: 'ollama',
      local: true,
      status: SettingsTone.warn,
      error: '本机服务未启动',
      checkedAt: _ago(s: 5),
      hint: '先启动本地服务，再读取已加载的模型目录。',
      settings: const ProviderSettings(
        name: 'Ollama',
        baseUrl: 'http://127.0.0.1:11434/v1',
        protocolId: 'ollamaChatCompletions',
        timeoutSeconds: 300,
        maxConcurrency: 1,
        retryAttempts: 0,
        models: [
          ProviderModelSettings(
            id: 'qwen3:8b',
            contextWindow: 32000,
            maxOutput: 8000,
            reasoningLevels: [],
          ),
          ProviderModelSettings(
            id: 'gemma4:12b',
            contextWindow: 128000,
            maxOutput: 8000,
            reasoningLevels: [],
            capabilities: {ProviderCapability.vision},
          ),
        ],
      ),
    ),
    ProviderItem(
      id: 'relay',
      presetId: 'openaiCompatibleChat',
      mark: '中',
      color: 0xFF7C5CFF,
      apiKeyMasked: 'sk-••••••••••••••••11ac',
      status: SettingsTone.error,
      error: '401 · API Key 无效',
      checkedAt: _ago(d: 3),
      settings: const ProviderSettings(
        name: '自用中转',
        baseUrl: 'https://relay.pelican.dev/v1',
        protocolId: 'openaiChatCompletions',
        timeoutSeconds: 90,
        maxConcurrency: 4,
        retryAttempts: 3,
        models: [
          ProviderModelSettings(
            id: 'gpt-4.1-mini',
            contextWindow: 1000000,
            maxOutput: 32000,
            capabilities: {ProviderCapability.tools},
          ),
        ],
      ),
    ),
  ];

  static ProviderCatalog get _openRouterCatalog => ProviderCatalog(
    state: ProviderCatalogState.ready,
    fetchedAt: DateTime(2026, 10, 14, 9, 12),
    entries: [
      const ProviderCatalogEntry(
        id: 'anthropic/claude-sonnet-5-5',
        contextWindow: 1000000,
        price: r'$3 / $15',
      ),
      const ProviderCatalogEntry(
        id: 'anthropic/claude-opus-5',
        contextWindow: 1000000,
        price: r'$15 / $75',
      ),
      const ProviderCatalogEntry(
        id: 'anthropic/claude-haiku-5',
        contextWindow: 200000,
        price: r'$0.8 / $4',
      ),
      const ProviderCatalogEntry(
        id: 'anthropic/claude-sonnet-4.5',
        contextWindow: 1000000,
        price: r'$3 / $15',
      ),
      const ProviderCatalogEntry(
        id: 'anthropic/claude-3.7-sonnet',
        contextWindow: 200000,
        price: r'$3 / $15',
        retired: true,
      ),
      const ProviderCatalogEntry(
        id: 'google/gemini-3.8-pro',
        contextWindow: 2000000,
        price: r'$1.25 / $10',
      ),
      const ProviderCatalogEntry(
        id: 'qwen/qwen3.5-max',
        contextWindow: 256000,
        price: r'$1.6 / $6.4',
      ),
      for (var i = 0; i < 335; i++)
        ProviderCatalogEntry(
          id: 'vendor-${i ~/ 12}/model-${i % 12}',
          contextWindow: 32000 << (i % 5),
        ),
    ],
  );

  static Map<String, ProviderCatalog> get catalogs => {
    'ds': ProviderCatalog(
      state: ProviderCatalogState.ready,
      fetchedAt: DateTime(2026, 10, 14, 8, 30),
      entries: const [
        ProviderCatalogEntry(id: 'deepseek-flash', contextWindow: 128000),
        ProviderCatalogEntry(id: 'deepseek-v4-pro', contextWindow: 128000),
        ProviderCatalogEntry(id: 'deepseek-chat', contextWindow: 64000),
        ProviderCatalogEntry(
          id: 'deepseek-reasoner',
          contextWindow: 64000,
          retired: true,
        ),
      ],
    ),
    'or': _openRouterCatalog,
    'relay': const ProviderCatalog(
      state: ProviderCatalogState.failed,
      error: '401 · API Key 无效',
    ),
  };

  /// 和原型方案 B 同一批数据。
  static ProvidersViewData get view => ProvidersViewData(
    providers: providers,
    protocols: protocols,
    presets: presets,
    catalogs: catalogs,
  );

  /// 新装：没有服务商。
  static const empty = ProvidersViewData(
    protocols: protocols,
    presets: presets,
  );
}
