import '../channel/channel_contract.dart';
import 'settings_contract.dart';

/// 设置页预设状态（预览与测试共用）。
enum SettingsScene {
  /// 和 HTML 原型同一批数据。
  ready,

  /// 刚改过一项：底部“已保存 · 撤销”。
  toast,

  /// 改了代理：需重启提示条。
  restart,

  /// 新装：没有账号、没有服务商、没统计、没有更新。
  fresh,
}

/// 假数据：照 `.devin/mockups/settings/pages.js`。账号、余额、路径、延迟、显卡、更新内容都是示意值。
abstract final class SettingsFixture {
  /// “现在”：2026-10-14 16:40。
  static final now = DateTime(2026, 10, 14, 16, 40);

  static const _gb = 1024 * 1024 * 1024;
  static const _mb = 1024 * 1024;

  static DateTime _ago({int d = 0, int h = 0, int m = 0, int s = 0}) =>
      now.subtract(Duration(days: d, hours: h, minutes: m, seconds: s));

  static const values = SettingsValues({
    SettingKey.themeMode: 'light',
    SettingKey.fontFamily: 'harmony',
    SettingKey.settingsFontScale: 1.0,
    SettingKey.language: 'zh',
    SettingKey.completionSound: true,
    SettingKey.completionSoundFile: r'C:\Users\Pie\Music\chime-soft.wav',
    SettingKey.historyClick: 'linkedPreview',
    SettingKey.outputViewer: 'canvas',
    SettingKey.canvasZoomToFill: true,
    SettingKey.costWarning: true,
    SettingKey.costThreshold: 50.0,
    SettingKey.intervalLimit: true,
    SettingKey.intervalJitter: 20.0,
    SettingKey.imageSavePath: r'E:\A.I\NovelAI\outputs',
    SettingKey.agentModel: 'claude-sonnet-4.5',
    SettingKey.upscaleDefault: 'animeQuality',
    SettingKey.seedCpuOffload: 8.0,
    SettingKey.seedVaeTiling: true,
    SettingKey.ragEnabled: true,
    SettingKey.ragEmbedPath: r'E:\models\embeddinggemma-2',
    SettingKey.ragRerankPath: r'E:\models\Qwen3-Reranker-0.6B',
    SettingKey.kritaBridge: true,
    SettingKey.comfyEnabled: true,
    SettingKey.proxyEnabled: true,
    SettingKey.proxyMode: 'manual',
    SettingKey.proxyHost: '127.0.0.1',
    SettingKey.proxyPort: '7890',
    SettingKey.stripMetadata: true,
    SettingKey.blacklistAutoSync: true,
    SettingKey.includePrerelease: true,
    SettingKey.defaultAccount: 'pelican',
  });

  /// 和默认值不同的项（假数据里手工列出；真实接线由后端比较）。
  static const modified = {
    SettingKey.completionSoundFile,
    SettingKey.historyClick,
    SettingKey.canvasZoomToFill,
    SettingKey.costWarning,
    SettingKey.intervalLimit,
    SettingKey.intervalJitter,
    SettingKey.imageSavePath,
    SettingKey.seedCpuOffload,
    SettingKey.ragEnabled,
    SettingKey.kritaBridge,
    SettingKey.comfyEnabled,
    SettingKey.stripMetadata,
    SettingKey.includePrerelease,
  };

  static const options = <SettingKey, List<SettingsOption>>{
    SettingKey.fontFamily: [
      SettingsOption(value: 'harmony', label: 'HarmonyOS Sans SC'),
      SettingsOption(value: 'system', label: 'Microsoft YaHei UI'),
    ],
    SettingKey.agentModel: [
      SettingsOption(
        value: 'claude-sonnet-4.5',
        label: 'Claude Sonnet 4.5',
        detail: 'Anthropic',
        mark: 'A',
        color: 0xFFD97757,
      ),
      SettingsOption(
        value: 'gpt-4.1',
        label: 'GPT-4.1',
        detail: 'OpenAI',
        mark: 'AI',
        color: 0xFF10A37F,
      ),
      SettingsOption(
        value: 'deepseek-chat',
        label: 'DeepSeek-V3',
        detail: 'DeepSeek',
        mark: 'DS',
        color: 0xFF4D6BFE,
      ),
    ],
    SettingKey.upscaleDefault: [
      SettingsOption(
        value: 'animeQuality',
        label: '动漫 · 画质',
        detail: 'Real-ESRGAN',
      ),
      SettingsOption(value: 'seed3b', label: 'SeedVR2 3B', detail: '扩散'),
      SettingsOption(value: 'rtxVideo', label: 'RTX Video', detail: '最快'),
    ],
    SettingKey.defaultAccount: [
      SettingsOption(value: 'pelican', label: '鹈鹕 · Opus'),
      SettingsOption(value: 'alt', label: '小号 · Tablet'),
      SettingsOption(value: 'test', label: '测试'),
    ],
  };

  static final recent = [
    SettingsChange(id: 'r1', title: '主题', from: '浅色', to: '深色', at: _ago(m: 2)),
    SettingsChange(
      id: 'r2',
      title: '提醒阈值',
      from: '30',
      to: '50 Anlas',
      at: _ago(m: 18),
    ),
    SettingsChange(
      id: 'r3',
      title: '快捷键 · 生成图像',
      from: '',
      to: 'Ctrl+Enter',
      at: _ago(h: 2, m: 38),
    ),
    SettingsChange(
      id: 'r4',
      title: '画布视觉通道',
      from: '',
      to: '每次随机',
      at: _ago(d: 1),
      undoable: false,
    ),
    SettingsChange(
      id: 'r5',
      title: '自动保存',
      from: '开',
      to: '关',
      at: _ago(d: 2),
      undoable: false,
    ),
  ];

  static final _account = SettingsAccountData(
    monthlyAnlas: 10000,
    todayUsed: 412,
    accounts: [
      SettingsAccount(
        id: 'pelican',
        name: '鹈鹕',
        tier: SettingsTier.opus,
        anlas: 9866,
        loginKind: SettingsLoginKind.email,
        maskedId: 'pelican@****.com',
        renewsAt: DateTime(2026, 11, 4),
        current: true,
        isDefault: true,
        color: 0xFF1F6BFF,
      ),
      SettingsAccount(
        id: 'alt',
        name: '小号',
        tier: SettingsTier.tablet,
        anlas: 1203,
        loginKind: SettingsLoginKind.token,
        maskedId: 'pst-****a91f',
        lastUsedAt: DateTime(2026, 10, 9),
        color: 0xFF8E4EC6,
      ),
      const SettingsAccount(
        id: 'test',
        name: '测试',
        tier: SettingsTier.none,
        anlas: 0,
        loginKind: SettingsLoginKind.token,
        maskedId: 'pst-****00c2',
        expired: true,
      ),
    ],
  );

  static const _contexts = [
    SettingsShortcutContext(id: 'global', label: '全局'),
    SettingsShortcutContext(id: 'generation', label: '生成页面'),
    SettingsShortcutContext(id: 'gallery', label: '画廊列表'),
    SettingsShortcutContext(id: 'viewer', label: '图片查看器'),
    SettingsShortcutContext(id: 'vibe', label: 'Vibe 详情'),
    SettingsShortcutContext(id: 'input', label: '输入框'),
    SettingsShortcutContext(id: 'settings', label: '设置'),
  ];

  static SettingsShortcut _sc(
    String id,
    String ctx,
    String label,
    List<String> keys, [
    List<String>? def,
    String? conflict,
  ]) => SettingsShortcut(
    id: id,
    context: ctx,
    label: label,
    keys: keys,
    defaultKeys: def ?? keys,
    conflictWith: conflict,
  );

  static final _shortcuts = [
    _sc('nav', 'global', '生图 … 统计（按导航顺序）', ['Ctrl', '1…9']),
    _sc('settings', 'global', '设置', ['Ctrl', ',']),
    _sc('theme', 'global', '切换主题', ['Ctrl', 'Shift', 'T']),
    _sc('fullscreen', 'global', '全屏', ['F11']),
    _sc('help', 'global', '显示快捷键帮助', ['F1']),
    _sc('tray', 'global', '最小化到托盘', ['Ctrl', 'M']),
    _sc('quit', 'global', '退出应用', ['Ctrl', 'Q']),
    _sc('generate', 'generation', '生成图像', ['Ctrl', 'Enter']),
    _sc('cancel', 'generation', '取消生成', ['Esc']),
    _sc('save', 'generation', '保存图像', ['Ctrl', 'S'], null, 'reuse'),
    _sc('reuse', 'generation', '复用参数', ['Ctrl', 'S'], ['Ctrl', 'R'], 'save'),
    _sc('swap', 'generation', '切换正 / 负面', ['Ctrl', 'Tab'], ['Ctrl', 'M']),
    _sc('blocks', 'generation', '打开块库', ['Ctrl', 'B']),
    _sc('params', 'generation', '打开参数面板', ['Ctrl', 'P']),
    _sc('history', 'generation', '打开历史面板', ['Ctrl', 'H']),
    _sc('upscale', 'generation', '放大图像', ['Ctrl', 'U']),
    _sc('copy', 'generation', '复制图像', ['Ctrl', 'C']),
    _sc('undo', 'generation', '撤销', ['Ctrl', 'Z']),
    _sc('search', 'generation', '搜索标签', ['Ctrl', 'F']),
    _sc('clear', 'generation', '清空提示词', []),
    _sc('prev', 'generation', '预览上一张（历史联动）', ['Alt', '↑']),
    _sc('next', 'generation', '预览下一张（历史联动）', ['Alt', '↓']),
    _sc('g-open', 'gallery', '打开大图', ['Enter']),
    _sc('g-del', 'gallery', '删除', ['Delete']),
    _sc('g-all', 'gallery', '全选', ['Ctrl', 'A']),
    _sc('v-prev', 'viewer', '上一张', ['←']),
    _sc('v-next', 'viewer', '下一张', ['→']),
    _sc('v-fav', 'viewer', '收藏', ['F']),
    _sc('vb-apply', 'vibe', '应用到生图', ['Ctrl', 'Enter']),
    _sc('in-weight', 'input', '增加权重', ['Ctrl', '↑']),
    _sc('st-search', 'settings', '搜索设置', ['Ctrl', 'F']),
  ];

  static final _storage = SettingsStorageData(
    slices: const [
      SettingsStorageSlice(SettingsStorageKind.images, (31.4 * _gb) ~/ 1),
      SettingsStorageSlice(SettingsStorageKind.upscaleModels, (4.8 * _gb) ~/ 1),
      SettingsStorageSlice(SettingsStorageKind.vibes, (2.3 * _gb) ~/ 1),
      SettingsStorageSlice(SettingsStorageKind.thumbnails, (1.2 * _gb) ~/ 1),
      SettingsStorageSlice(SettingsStorageKind.ragIndex, (1.1 * _gb) ~/ 1),
      SettingsStorageSlice(SettingsStorageKind.dictionaries, 655 * _mb),
      SettingsStorageSlice(SettingsStorageKind.agent, 123 * _mb),
    ],
    diskLabel: 'E:',
    diskFree: 212 * _gb,
    roots: const [
      SettingsGalleryRoot(
        id: 'out',
        path: r'E:\A.I\NovelAI\outputs',
        images: 9840,
        primary: true,
      ),
      SettingsGalleryRoot(id: 'pixiv', path: r'D:\Pixiv\收藏', images: 1962),
      SettingsGalleryRoot(id: 'tmp', path: r'E:\A.I\NovelAI\临时存图', images: 606),
    ],
    imageCount: 12408,
    lastScanAt: DateTime(2026, 10, 14, 9, 12),
    thumbnailBytes: (1.2 * _gb) ~/ 1,
    thumbnailLimit: 2 * _gb,
    folderNames: const {
      SettingsFolder.images: 'outputs',
      SettingsFolder.vibes: 'vibes',
      SettingsFolder.thumbnails: '.thumbs',
      SettingsFolder.appData: 'hive',
      SettingsFolder.logs: 'logs',
    },
  );

  static final _models = SettingsModelsData(
    requestTotal: 128,
    providers: [
      SettingsProvider(
        id: 'ds',
        name: 'DeepSeek',
        protocol: 'OpenAI Chat Completions 兼容',
        mark: 'DS',
        color: 0xFF4D6BFE,
        baseUrl: 'https://api.deepseek.com/v1',
        apiKeyMasked: 'sk-••••••••••••••••••••3f9a',
        status: SettingsTone.ok,
        latencyMs: 96,
        checkedAt: _ago(s: 5),
        models: const [
          SettingsModel(
            id: 'deepseek-chat',
            detail: 'V3 · 64K',
            capabilities: {SettingsModelCapability.tools},
            usedFor: {
              SettingsModelTask.promptTranslate,
              SettingsModelTask.tagTranslate,
            },
          ),
          SettingsModel(
            id: 'deepseek-reasoner',
            detail: 'R1 · 64K',
            capabilities: {SettingsModelCapability.reasoning},
            usedFor: {SettingsModelTask.promptReverse},
          ),
          SettingsModel(id: 'deepseek-coder', detail: '已弃用', retired: true),
        ],
      ),
      const SettingsProvider(
        id: 'oa',
        name: 'OpenAI',
        protocol: 'OpenAI Responses',
        mark: 'AI',
        color: 0xFF10A37F,
        baseUrl: 'https://api.openai.com/v1',
        apiKeyMasked: 'sk-••••••••c01d',
        status: SettingsTone.ok,
        models: [
          SettingsModel(id: 'gpt-4.1'),
          SettingsModel(id: 'gpt-4.1-mini'),
          SettingsModel(id: 'gpt-4o'),
          SettingsModel(id: 'o3'),
          SettingsModel(id: 'o4-mini'),
          SettingsModel(id: 'gpt-image-1'),
        ],
      ),
      const SettingsProvider(
        id: 'an',
        name: 'Anthropic',
        protocol: 'Anthropic Messages',
        mark: 'A',
        color: 0xFFD97757,
        status: SettingsTone.ok,
        models: [
          SettingsModel(id: 'claude-sonnet-4.5'),
          SettingsModel(id: 'claude-opus-4.1'),
          SettingsModel(id: 'claude-haiku-4.5'),
          SettingsModel(id: 'claude-sonnet-4'),
        ],
      ),
      const SettingsProvider(
        id: 'gm',
        name: 'Gemini',
        protocol: 'Gemini API',
        mark: 'G',
        color: 0xFF4285F4,
        enabled: false,
      ),
      const SettingsProvider(
        id: 'ol',
        name: 'Ollama',
        protocol: 'Ollama',
        mark: 'OL',
        color: 0xFF555555,
        local: true,
        baseUrl: 'http://127.0.0.1:11434',
        status: SettingsTone.warn,
        models: [
          SettingsModel(id: 'qwen3:8b'),
          SettingsModel(id: 'gemma3:12b'),
          SettingsModel(id: 'llava:13b'),
        ],
      ),
    ],
    assignments: const [
      SettingsTaskAssignment(
        task: SettingsModelTask.promptTranslate,
        providerId: 'ds',
        modelId: 'deepseek-chat',
        presetId: 'b-tr',
      ),
      SettingsTaskAssignment(
        task: SettingsModelTask.promptReverse,
        providerId: 'oa',
        modelId: 'gpt-4.1',
        presetId: 'my-rev',
      ),
      SettingsTaskAssignment(
        task: SettingsModelTask.tagTranslate,
        providerId: 'ds',
        modelId: 'deepseek-chat',
        presetId: 'b-tag',
      ),
      SettingsTaskAssignment(
        task: SettingsModelTask.wikiTranslate,
        presetId: 'b-wiki',
        fallback: true,
      ),
    ],
    presets: const [
      SettingsPreset(
        id: 'b-tr',
        name: '内置 · 翻译',
        task: SettingsModelTask.promptTranslate,
        builtin: true,
      ),
      SettingsPreset(
        id: 'b-rev',
        name: '内置 · 反推',
        task: SettingsModelTask.promptReverse,
        builtin: true,
      ),
      SettingsPreset(
        id: 'my-rev',
        name: '我的反推',
        task: SettingsModelTask.promptReverse,
      ),
      SettingsPreset(
        id: 'b-tag',
        name: '内置 · 标签',
        task: SettingsModelTask.tagTranslate,
        builtin: true,
      ),
      SettingsPreset(
        id: 'b-wiki',
        name: '内置 · 百科',
        task: SettingsModelTask.wikiTranslate,
        builtin: true,
      ),
    ],
    requests: [
      for (var i = 0; i < 8; i++)
        SettingsRequestLog(
          id: 'request-$i',
          at: _ago(m: 3 + i * 7),
          task: SettingsModelTask.values[i % 3],
          provider: i % 3 == 1 ? 'OpenAI' : 'DeepSeek',
          model: i % 3 == 1 ? 'gpt-4.1' : 'deepseek-chat',
          ok: i != 4,
          latencyMs: i == 4 ? null : 620 + i * 113,
          tokens: i == 4 ? null : 412 + i * 57,
        ),
    ],
  );

  static const _agent = SettingsAgentData(
    globalInstructions:
        '回答时先给结论，再给理由。\n写提示词遵循当前模型的标签规则；涉及 V5 时不要套用 V4.5 的权重写法。\n生成前一定先报价并等待确认。',
    extensions: [
      SettingsExtension(id: 'studio', name: 'Studio', builtin: true),
      SettingsExtension(
        id: 'lint',
        name: 'prompt-lint',
        path: r'C:\Users\Pie\.pi\extensions\prompt-lint',
      ),
    ],
    mcp: [
      SettingsMcpServer(
        id: 'studio',
        name: 'NAI Studio',
        transport: '',
        state: SettingsMcpState.connected,
        mode: SettingsMcpMode.codemode,
        builtin: true,
      ),
      SettingsMcpServer(
        id: 'fs',
        name: 'filesystem',
        transport: 'stdio · npx @modelcontextprotocol/server-filesystem',
        state: SettingsMcpState.connected,
        mode: SettingsMcpMode.deferred,
        tools: 11,
      ),
      SettingsMcpServer(
        id: 'notion',
        name: 'notion',
        transport: 'Streamable HTTP · mcp.notion.com',
        state: SettingsMcpState.needsLogin,
        mode: SettingsMcpMode.deferred,
      ),
    ],
    tools: [
      'read_prompt',
      'write_prompt',
      'search_blocks',
      'wiki_lookup',
      'list_history',
      'read_image',
      'quote_generation',
      'generate',
      'read_settings',
    ],
    dataPath: r'%APPDATA%\nai_launcher\agent',
    workspaces: 3,
    sessions: 27,
  );

  /// 基础提示词编辑。[_agent] 默认不带（原型没有这一行，原基准截图不变），预览和测试按需带上。
  static const systemPrompt = SettingsSystemPrompt(
    builtin:
        '你是 NAI Studio 里的创作助手，帮用户写提示词、整理块和查资料。\n'
        '先读当前模型和画布状态，再动手；不确定就问。\n'
        '任何会花 Anlas 的操作都要先报价，等用户确认后才执行。',
    workspaceId: 'inspire',
    workspaceName: '灵感',
  );

  static const _rag = SettingsRagData(
    runtime: SettingsRagStep(value: 'CUDA 12.4', detail: '独立 Python · 不影响放大组件'),
    embedder: SettingsRagStep(value: 'EmbeddingGemma 2', detail: '文字 + 图片'),
    reranker: SettingsRagStep(value: 'Qwen3-Reranker 0.6B', detail: '仅文字'),
    device: SettingsRagStep(value: 'RTX 4070', detail: '自动选择'),
    indexBytes: 812 * _mb,
    runtimeReady: true,
    runtimeCuda: true,
    runtimePython: r'%APPDATA%\nai_launcher\rag\python\python.exe',
    sources: [
      SettingsRagSource(
        kind: SettingsRagSourceKind.tags,
        state: SettingsRagState.ready,
        done: 182340,
        total: 182340,
      ),
      SettingsRagSource(
        kind: SettingsRagSourceKind.wiki,
        state: SettingsRagState.ready,
        done: 12406,
        total: 12406,
      ),
      SettingsRagSource(
        kind: SettingsRagSourceKind.blocks,
        state: SettingsRagState.ready,
        done: 842,
        total: 842,
      ),
      SettingsRagSource(
        kind: SettingsRagSourceKind.gallery,
        state: SettingsRagState.paused,
        done: 7702,
        total: 12408,
        secondary: 9120,
      ),
    ],
  );

  static const _upscale = SettingsUpscaleData(
    gpuName: 'NVIDIA GeForce RTX 4070',
    vramGb: 12,
    caps: {
      SettingsGpuCap.vulkan,
      SettingsGpuCap.cuda,
      SettingsGpuCap.int8,
      SettingsGpuCap.rtxVideo,
    },
    cudaVersion: '12.4',
    esrgan: [
      SettingsUpscaleModel(
        id: 'animeQuality',
        state: SettingsInstallState.builtin,
        bytes: 17 * _mb,
        file: 'realesrgan-x4plus-anime',
        isDefault: true,
      ),
      SettingsUpscaleModel(
        id: 'animeFast',
        state: SettingsInstallState.installed,
        bytes: 6 * _mb,
        file: 'realesr-animevideov3',
      ),
      SettingsUpscaleModel(
        id: 'general',
        state: SettingsInstallState.notInstalled,
        bytes: 64 * _mb,
        file: 'realesrgan-x4plus',
      ),
    ],
    seed: [
      SettingsUpscaleModel(
        id: 'seed3b',
        state: SettingsInstallState.installed,
        bytes: (6.8 * _gb) ~/ 1,
        vramGb: 8,
      ),
      SettingsUpscaleModel(
        id: 'seed7b',
        state: SettingsInstallState.downloading,
        bytes: (15.2 * _gb) ~/ 1,
        total: (15.2 * _gb) ~/ 1,
        received: (6.4 * _gb) ~/ 1,
        speed: 18 * _mb,
        vramGb: 12,
      ),
      SettingsUpscaleModel(
        id: 'seed7bSharp',
        state: SettingsInstallState.notInstalled,
        bytes: (15.2 * _gb) ~/ 1,
        vramGb: 12,
      ),
    ],
    rtx: SettingsUpscaleModel(
      id: 'rtxVideo',
      state: SettingsInstallState.installed,
      bytes: 64 * _mb,
    ),
  );

  static final _bridges = SettingsBridgesData(
    kritaConnected: true,
    kritaClient: 'Krita 5.2.6 · krita-ai-diffusion 1.24',
    kritaEndpoint: 'ws://127.0.0.1:47821/krita',
    kritaDiscovery: r'%APPDATA%\krita\nai-studio.json',
    agentClients: 2,
    activity: [
      SettingsBridgeActivity(
        client: 'Claude Code',
        action: '读取参数',
        at: _ago(m: 1),
      ),
      SettingsBridgeActivity(
        client: 'Claude Code',
        action: '修改参数 · 正面提示词',
        at: _ago(m: 3),
      ),
      SettingsBridgeActivity(
        client: 'Codex',
        action: '预估消耗 · 20 Anlas',
        at: _ago(m: 12),
        tone: SettingsTone.idle,
      ),
      SettingsBridgeActivity(
        client: 'Codex',
        action: '生成图片 · 等待确认',
        at: _ago(m: 12),
        tone: SettingsTone.warn,
      ),
    ],
    comfyTone: SettingsTone.error,
    comfyMessage: '服务无响应',
    comfyCheckedAt: _ago(m: 2),
  );

  static final _network = SettingsNetworkData(
    systemProxy: '127.0.0.1:7897',
    checkedAt: _ago(s: 3),
    endpoints: const [
      SettingsEndpoint(
        kind: SettingsEndpointKind.naiImage,
        host: 'image.novelai.net',
        latencyMs: 182,
        tone: SettingsTone.ok,
      ),
      SettingsEndpoint(
        kind: SettingsEndpointKind.naiApi,
        host: 'api.novelai.net',
        latencyMs: 204,
        tone: SettingsTone.ok,
      ),
      SettingsEndpoint(
        kind: SettingsEndpointKind.danbooru,
        host: 'danbooru.donmai.us',
        latencyMs: 340,
        tone: SettingsTone.ok,
      ),
      SettingsEndpoint(
        kind: SettingsEndpointKind.update,
        host: 'github.com',
        latencyMs: 1200,
        tone: SettingsTone.warn,
      ),
      SettingsEndpoint(
        kind: SettingsEndpointKind.provider,
        host: 'api.deepseek.com',
        name: 'DeepSeek',
        latencyMs: 96,
        tone: SettingsTone.ok,
      ),
    ],
  );

  static final _about = SettingsAboutData(
    build: 'ffdaba9',
    platform: 'Windows x64',
    update: SettingsUpdateState.available,
    latest: '2.0 Preview r9',
    releasedAt: DateTime(2026, 10, 15),
    updateBytes: 48 * _mb,
    notes: const ['画布视觉通道：极窄窗口下提示条不再溢出', '字符框菜单文案精简', '修复 Krita 断线后会话不自动恢复'],
    checkedAt: _ago(m: 3),
    system: const [
      ('系统', 'Windows 11 23H2'),
      ('显卡', 'RTX 4070 12 GB'),
      ('Flutter', '3.47.7'),
      ('数据', '41.6 GB'),
    ],
  );

  /// 语义检索的忙碌状态（测试与预览用）：嵌入模型下载中、Wiki 待确认计划、
  /// 图库出错、没找到本地模型、选了别的解释器。
  static const ragBusy = SettingsRagData(
    runtime: SettingsRagStep(value: 'CUDA 12.4', detail: '独立 Python · 不影响放大组件'),
    embedder: SettingsRagStep(value: '下载中 41%', tone: SettingsTone.warn),
    reranker: SettingsRagStep(value: 'Qwen3-Reranker 0.6B', detail: '仅文字'),
    device: SettingsRagStep(value: 'RTX 4070', detail: '自动选择'),
    indexBytes: 812 * _mb,
    runtimeReady: true,
    runtimeCuda: true,
    runtimePython: r'%APPDATA%\nai_launcher\rag\python\python.exe',
    pythonPending: true,
    modelsMissing: true,
    download: SettingsRagDownload(
      model: SettingsRagModel.embedder,
      received: 484 * _mb,
      total: 1180 * _mb,
    ),
    plan: SettingsRagPlan(
      kind: SettingsRagSourceKind.wiki,
      documents: 1204,
      total: 12406,
    ),
    error: '模型下载中断：连接超时（huggingface.co）',
    sources: [
      SettingsRagSource(
        kind: SettingsRagSourceKind.tags,
        state: SettingsRagState.ready,
        done: 120400,
        total: 182340,
      ),
      SettingsRagSource(
        kind: SettingsRagSourceKind.wiki,
        state: SettingsRagState.empty,
      ),
      SettingsRagSource(
        kind: SettingsRagSourceKind.blocks,
        state: SettingsRagState.building,
        done: 310,
        total: 842,
      ),
      SettingsRagSource(
        kind: SettingsRagSourceKind.gallery,
        state: SettingsRagState.error,
        done: 7702,
        total: 12408,
        secondary: 9120,
        skipped: 14,
        error: 'CUDA out of memory · 已停在第 7,702 张',
      ),
    ],
  );

  /// 正在安装运行环境（CUDA 依赖阶段），图库重建计划统计中。
  static const ragInstalling = SettingsRagData(
    runtime: SettingsRagStep(value: '安装中', tone: SettingsTone.warn),
    embedder: SettingsRagStep(value: 'EmbeddingGemma 2', detail: '文字 + 图片'),
    reranker: SettingsRagStep(value: 'Qwen3-Reranker 0.6B', detail: '仅文字'),
    device: SettingsRagStep(value: 'RTX 4070', detail: '自动选择'),
    install: SettingsRagInstall(
      phase: SettingsRagInstallPhase.cuda,
      elapsed: Duration(minutes: 2, seconds: 31),
      detail:
          'Downloading torch-2.6.0+cu124-cp312-cp312-win_amd64.whl (2.4 GB)',
    ),
    plan: SettingsRagPlan(
      kind: SettingsRagSourceKind.gallery,
      rebuild: true,
      loading: true,
    ),
    sources: [
      SettingsRagSource(
        kind: SettingsRagSourceKind.tags,
        state: SettingsRagState.empty,
      ),
      SettingsRagSource(
        kind: SettingsRagSourceKind.wiki,
        state: SettingsRagState.off,
        enabled: false,
      ),
      SettingsRagSource(
        kind: SettingsRagSourceKind.blocks,
        state: SettingsRagState.off,
        enabled: false,
      ),
      SettingsRagSource(
        kind: SettingsRagSourceKind.gallery,
        state: SettingsRagState.ready,
        done: 12408,
        total: 12408,
        secondary: 9120,
      ),
    ],
  );

  static SettingsViewData view({
    SettingsPageId page = SettingsPageId.overview,
    SettingsScene scene = SettingsScene.ready,
    bool dark = false,
    ChannelSettings? channel,
  }) {
    final fresh = scene == SettingsScene.fresh;
    final v = values.copyWith(SettingKey.themeMode, dark ? 'dark' : 'light');
    final ch =
        channel ??
        const ChannelSettings(
          seed: 20261014,
          pool: {
            ChannelTheme.circuit,
            ChannelTheme.stars,
            ChannelTheme.herb,
            ChannelTheme.arcade,
            ChannelTheme.abyss,
          },
        );
    if (fresh) {
      return SettingsViewData(
        page: page,
        values: SettingsValues({SettingKey.themeMode: dark ? 'dark' : 'light'}),
        modified: {if (!dark) SettingKey.themeMode},
        now: now,
        version: '2.0 Preview r8',
        options: {SettingKey.fontFamily: options[SettingKey.fontFamily]!},
        account: const SettingsAccountData(),
        canvas: const SettingsCanvasData(
          channel: ChannelSettings(seed: 20261014),
        ),
        shortcuts: SettingsShortcutsData(
          contexts: _contexts,
          shortcuts: [
            for (final x in _shortcuts)
              x.conflictWith == null
                  ? x
                  : _sc(x.id, x.context, x.label, x.defaultKeys),
          ],
        ),
        generation: const SettingsGenerationData(),
        storage: const SettingsStorageData(diskLabel: 'C:'),
        dictionaries: const SettingsDictionaryData(
          tagCount: 182340,
          dataVersion: '2026.09',
          cooccurrence: 1204551,
        ),
        models: const SettingsModelsData(),
        agent: const SettingsAgentData(
          tools: ['read_prompt', 'write_prompt'],
          dataPath: r'%APPDATA%\nai_launcher\agent',
        ),
        rag: const SettingsRagData(
          runtime: SettingsRagStep(value: '未安装', tone: SettingsTone.idle),
          embedder: SettingsRagStep(value: '未选择', tone: SettingsTone.idle),
          reranker: SettingsRagStep(value: '未选择', tone: SettingsTone.idle),
          device: SettingsRagStep(value: '自动', tone: SettingsTone.idle),
          sources: [
            SettingsRagSource(
              kind: SettingsRagSourceKind.tags,
              state: SettingsRagState.empty,
            ),
            SettingsRagSource(
              kind: SettingsRagSourceKind.wiki,
              state: SettingsRagState.off,
              enabled: false,
            ),
            SettingsRagSource(
              kind: SettingsRagSourceKind.blocks,
              state: SettingsRagState.off,
              enabled: false,
            ),
            SettingsRagSource(
              kind: SettingsRagSourceKind.gallery,
              state: SettingsRagState.off,
              enabled: false,
            ),
          ],
        ),
        upscale: const SettingsUpscaleData(),
        bridges: const SettingsBridgesData(
          kritaEndpoint: 'ws://127.0.0.1:47821/krita',
        ),
        network: const SettingsNetworkData(),
        privacy: const SettingsPrivacyData(),
        backup: const SettingsBackupData(),
        about: SettingsAboutData(
          build: 'ffdaba9',
          platform: 'Windows x64',
          checkedAt: _ago(m: 1),
        ),
      );
    }
    return SettingsViewData(
      page: page,
      values: v,
      now: now,
      version: '2.0 Preview r8',
      modified: {...modified, if (!dark) SettingKey.themeMode},
      options: options,
      lastChange: scene == SettingsScene.toast
          ? SettingsChange(
              id: 'toast',
              title: '提醒阈值',
              from: '30',
              to: '50 Anlas',
              at: now,
            )
          : (scene == SettingsScene.restart
                ? SettingsChange(
                    id: 'proxy',
                    title: '使用代理',
                    from: '关',
                    to: '开',
                    at: now,
                  )
                : null),
      recent: recent,
      restartPending: scene == SettingsScene.restart,
      attention: [
        const SettingsAttention(
          kind: SettingsAttentionKind.update,
          tone: SettingsTone.error,
          subject: '2.0 Preview r9',
          detail: '包含画布视觉通道修复',
          bytes: 48 * _mb,
        ),
        const SettingsAttention(
          kind: SettingsAttentionKind.ragPaused,
          tone: SettingsTone.warn,
          subject: 'gallery',
          done: 7702,
          total: 12408,
        ),
        SettingsAttention(
          kind: SettingsAttentionKind.bridgeDown,
          tone: SettingsTone.warn,
          subject: 'comfyui',
          detail: 'http://127.0.0.1:8188',
          at: _ago(m: 2),
        ),
      ],
      account: _account,
      canvas: SettingsCanvasData(channel: ch),
      shortcuts: SettingsShortcutsData(
        contexts: _contexts,
        shortcuts: _shortcuts,
      ),
      generation: const SettingsGenerationData(
        estimate: SettingsCostEstimate(
          model: 'V4.5',
          width: 832,
          height: 1216,
          steps: 28,
          images: 4,
          cost: 20,
        ),
        hourlyUsage: [4, 9, 2, 12, 6, 0, 3, 8, 14, 5, 11, 7],
        warningsToday: 2,
        maxSingleToday: 68,
        translationModel: 'DeepSeek-V3',
        ragTagsReady: true,
      ),
      storage: _storage,
      dictionaries: SettingsDictionaryData(
        tagCount: 182340,
        dataVersion: '2026.09',
        cooccurrence: 1204551,
        translationModel: 'DeepSeek-V3',
        caches: const {
          SettingsCacheKind.danbooru: (18204, 212 * _mb),
          SettingsCacheKind.translation: (6931, 9 * _mb),
        },
        l1: const SettingsCacheStat(hitRate: .94, entries: 2104),
        l2: const SettingsCacheStat(hitRate: .81, entries: 48220),
        l3: const SettingsCacheStat(hitRate: .67, entries: 12408, images: true),
        statsUpdatedAt: _ago(s: 12),
      ),
      models: _models,
      agent: _agent,
      rag: _rag,
      upscale: _upscale,
      bridges: _bridges,
      network: _network,
      privacy: SettingsPrivacyData(
        blacklist: const [
          'guro',
          'scat',
          'loli',
          'realistic',
          'photo_(medium)',
          '3d',
          'text_focus',
          'watermark',
        ],
        danbooruUser: 'pelican_dan',
        lastSyncAt: DateTime(2026, 10, 14, 8, 40),
      ),
      backup: SettingsBackupData(
        lastImportAt: DateTime(2026, 10, 12, 16, 20),
        shortcutsCustomized: 3,
        backups: [
          SettingsBackup(
            id: 'b1',
            kind: SettingsBackupKind.import,
            at: DateTime(2026, 10, 12, 16, 20),
          ),
          SettingsBackup(
            id: 'b2',
            kind: SettingsBackupKind.reset,
            at: DateTime(2026, 9, 30, 11, 2),
          ),
          SettingsBackup(
            id: 'b3',
            kind: SettingsBackupKind.upgrade,
            at: DateTime(2026, 9, 28, 20, 15),
          ),
        ],
      ),
      about: _about,
    );
  }
}
