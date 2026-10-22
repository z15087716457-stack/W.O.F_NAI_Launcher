import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_contract.dart';
import 'package:nai_launcher/presentation/ui/online/online_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_fixture.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';

import 'images.dart';

const prompt =
    '1girl, solo, long hair, silver hair, starry sky, glowing flowers, '
    'night, cinematic lighting, depth of field, very aesthetic, masterpiece, no text';
const negative =
    'lowres, blurry, artistic error, worst quality, bad quality, '
    'jpeg artifacts, watermark, text';
const artists = [
  'sample_alpha',
  'sample_beta',
  'sample_gamma',
  'sample_delta',
  'sample_epsilon',
  'sample_zeta',
  'sample_eta',
  'sample_theta',
  'sample_iota',
  'sample_kappa',
];
const accent = Color(0xFF9C66CD);

class ReadmeData {
  ReadmeData(this.locale, this.images);
  final String locale;
  final ShotImages images;
  String tr(String zh, String en) => locale == 'zh' ? zh : en;
  static final now = DateTime(2026, 10, 22, 16, 45);

  NavAccountData get account => const NavAccountData(
    current: NavAccount(id: 'sample', name: 'W.O.F'),
    anlas: 2218,
    plan: 'Opus',
  );

  late final List<BlockData> blocks = [
    for (final (i, row) in <(String, String, List<String>)>[
      ('画师池·示范', 'Artists · Sample', [for (final a in artists) 'artist:$a']),
      ('质量词', 'Quality', ['very aesthetic', 'masterpiece', 'no text']),
      ('负面·通用', 'Negative · General', []),
      (
        '服装轮换',
        'Outfit rotation',
        ['hoodie', 'kimono', 'long dress', 'maid outfit'],
      ),
      ('场景·夜景', 'Scene · Night', ['starry sky', 'night', 'glowing flowers']),
      (
        '光影·电影感',
        'Light · Cinematic',
        ['cinematic lighting', 'rim light', 'bloom'],
      ),
      (
        '构图·特写',
        'Composition · Close-up',
        ['portrait', 'close-up', 'depth of field'],
      ),
      (
        '配色·冷色调',
        'Palette · Cool',
        ['blue theme', 'purple theme', 'muted colors'],
      ),
      ('场景·花园', 'Scene · Garden', ['garden', 'flowers', 'sunlight']),
      ('光影·柔光', 'Light · Soft', ['soft lighting', 'backlighting', 'bokeh']),
      (
        '材质·水彩',
        'Medium · Watercolor',
        ['watercolor (medium)', 'soft edges', 'paper texture'],
      ),
      (
        '构图·远景',
        'Composition · Wide',
        ['scenery', 'wide shot', 'detailed background'],
      ),
      (
        '配色·暖色调',
        'Palette · Warm',
        ['warm colors', 'orange sky', 'golden hour'],
      ),
      ('场景·海边', 'Scene · Coast', ['ocean', 'sky', 'cloud', 'horizon']),
      ('服装·日常', 'Outfit · Casual', ['sweater', 'coat', 'scarf']),
      ('光影·月光', 'Light · Moonlight', ['moonlight', 'night', 'light particles']),
    ].indexed)
      BlockData(
        id: 'b$i',
        title: tr(row.$1, row.$2),
        color: [accent, Colors.teal, Colors.blue, Colors.orange][i % 4],
        atoms: row.$3,
        negativeAtoms: i == 2 ? negative.split(', ') : const [],
        folderId: 'f${i % 5}',
        folderName: folders[i % 5],
        thumb: BlockThumb(
          images.image(
            'blocks/$i',
            direction: i % 3 == 0 ? 'landscape' : 'portrait',
          ),
        ),
        favorite: i < 4,
        useCount: 124 - i * 6,
        createdAt: now,
        updatedAt: now,
      ),
  ];

  List<String> get folders => locale == 'zh'
      ? ['常用', '画风', '场景', '服装', '示范']
      : ['Favorites', 'Styles', 'Scenes', 'Outfits', 'Examples'];

  BlocksLibraryViewData get library => BlocksLibraryViewData(
    now: now,
    blocks: blocks,
    counts: const BlocksCounts(all: 16, favorites: 4, recent: 8),
    folders: [
      for (var i = 0; i < 5; i++)
        BlocksFolder(id: 'f$i', name: folders[i], count: 4),
    ],
    selectedId: 'b0',
    cardSize: .4,
  );

  BlocksDockViewData get dock => BlocksDockViewData(
    total: blocks.length,
    favorites: blocks.take(4).toList(),
    recent: blocks.skip(4).take(3).toList(),
    chips: [
      for (var i = 0; i < 5; i++) BlocksDockChip(id: 'f$i', name: folders[i]),
    ],
    groups: [
      for (var i = 0; i < 5; i++)
        BlocksDockGroup(
          id: 'f$i',
          name: folders[i],
          count: 3,
          blocks: blocks.where((b) => b.folderId == 'f$i').toList(),
        ),
    ],
  );

  BlockInstanceViewData instance({
    bool sequential = false,
    bool locked = false,
  }) => BlockInstanceViewData(
    block: blocks[sequential ? 3 : 0],
    locked: locked,
    settings: BlockRollSettings(
      mode: sequential ? BlockMode.sequential : BlockMode.random,
      countMin: sequential ? 1 : 2,
      countMax: sequential ? 1 : 3,
      probability: .8,
      weightEnabled: !sequential,
      weightMin: .5,
      weightAverage: .9,
      weightMax: 1.4,
    ),
    drawn: sequential
        ? const [BlockDrawn('kimono')]
        : const [
            BlockDrawn('artist:sample_alpha', .8),
            BlockDrawn('artist:sample_beta', 1.2),
          ],
    send: sequential
        ? 'kimono'
        : '0.8::artist:sample_alpha::, 1.2::artist:sample_beta::',
    seqIndex: 1,
    prevText: sequential ? 'hoodie' : null,
    nextText: sequential ? 'long dress' : null,
  );

  GenViewData gen({
    bool dockOpen = false,
    bool compact = false,
    ChannelSettings? channel,
  }) {
    // Replace the fixture history instead of cycling its nine portrait keys
    // through a seven-image pool. Canvas/history covers deliberately differ.
    final base = GenFixture.view(images: (_) => images.fileImage('s23.jpg'));
    const historyFiles = [
      ['s09.jpg'],
      ['s03.jpg', 's04.jpg'],
      ['s15.jpg', 's16.jpg', 's17.jpg', 's19.jpg'],
      ['s08.jpg', 's10.jpg'],
    ];
    final history = GenHistoryData(
      selected: 'readme-history-0',
      batches: [
        for (final (i, files) in historyFiles.indexed)
          GenBatch(
            id: 'readme-history-$i',
            time: now.subtract(Duration(minutes: 3 + i * 6)),
            images: [
              for (final file in files)
                GenHistoryImage(
                  id: 'history-$file',
                  thumb: images.fileImage(file),
                  width:
                      images.entries.firstWhere((e) => e['file'] == file)['w']
                          as int,
                  height:
                      images.entries.firstWhere((e) => e['file'] == file)['h']
                          as int,
                ),
            ],
          ),
      ],
    );
    return base.copyWith(
      models: const [GenModel(id: 'nai-diffusion-5', name: 'V5 Full')],
      quota: const GenQuota(opusPercent: 147, anlas: 2218),
      layout: GenLayout(
        leftWidth: compact ? 352 : 420,
        historyWidth: 200,
        dockOpen: dockOpen,
      ),
      prompt: GenPromptData(
        positiveTokens: const GenTokens(86, 512),
        negativeTokens: const GenTokens(24, 512),
        qualityPresets: [GenOption(id: 'none', label: tr('无', 'None'))],
        ucPresets: [GenOption(id: 'heavy', label: tr('重度', 'Heavy'))],
        ucPreset: 'heavy',
        positivePreview: [
          GenPreviewSection(label: tr('主提示词', 'Prompt'), text: prompt),
        ],
        negativePreview: [
          GenPreviewSection(label: tr('负面', 'Negative'), text: negative),
        ],
        tools: const GenPromptTools(palettePinned: true),
        translate: const GenTranslate(route: 'Sample · Local preview'),
      ),
      characters: const GenCharactersData(
        list: [GenCharacter(id: 'c1', positiveTokens: GenTokens(22, 512))],
        max: 32,
        freeform: true,
      ),
      generate: GenGenerateData(
        label: tr('生成 1 张图片', 'Generate 1 image'),
        cost: 0,
      ),
      canvas: base.canvas.withChannel(channel),
      history: history,
    );
  }

  ExploreViewData get explore {
    List<ExploreAtom> atoms(int i) => [
      ExploreAtom.parse('0.8::artist:${artists[i % artists.length]}::'),
      ExploreAtom.parse('artist:${artists[(i + 1) % artists.length]}'),
    ];
    final candidates = [
      for (var i = 1; i <= 32; i++)
        ExploreCandidate(
          key: 'c$i',
          roundId: i <= 20 ? 'r1' : 'r2',
          number: i,
          image: images.image('explore/$i'),
          thumb: images.image('explore/$i'),
          favorite: i % 5 == 0,
          prompt: '$prompt, ${atoms(i).map((a) => a.raw).join(', ')}',
          negative: negative,
          draws: [
            ExploreDraw(
              title: blocks.first.title,
              color: accent,
              evolution: true,
              atoms: atoms(i),
            ),
          ],
          seed: 194200000 + i,
          model: 'V5 Full',
          steps: 28,
          scale: 5,
          sampler: 'Euler Ancestral',
          createdAt: now,
          op: i > 20 ? ExploreOp.values[i % 3] : null,
          lineId: i > 20 ? 'l1' : null,
          generation: i > 20 ? 2 : null,
          parentKeys: i > 20 ? ['c${i % 4 + 1}'] : const [],
          inEvolution: i <= 4,
        ),
    ];
    final run = ExploreRunView(
      id: 'sample',
      name: tr('星夜·画风示范', 'Starlight · Style study'),
      createdAt: now,
      candidates: candidates,
      rounds: [
        ExploreRound(
          id: 'r1',
          number: 1,
          createdAt: now,
          keys: [for (var i = 1; i <= 20; i++) 'c$i'],
        ),
        ExploreRound(
          id: 'r2',
          number: 2,
          createdAt: now,
          keys: [for (var i = 21; i <= 32; i++) 'c$i'],
          kind: ExploreRoundKind.deep,
          lineName: tr('柔光主线', 'Soft light'),
          generation: 2,
        ),
      ],
      lines: [
        ExploreLine(
          id: 'l1',
          name: tr('柔光主线', 'Soft light'),
          generations: [
            for (var g = 1; g <= 2; g++)
              ExploreGeneration(
                number: g,
                picked: 4,
                fromGeneration: g == 2 ? 1 : null,
                parents: [
                  for (var i = 1; i <= 4; i++)
                    ExploreParent(
                      id: 'p$g-$i',
                      candidateKey: 'c$i',
                      atoms: atoms(i),
                      image: candidates[i - 1].image,
                      preference: 5 - i.toDouble(),
                    ),
                ],
                childKeys: [for (var i = 21; i <= 32; i++) 'c$i'],
              ),
          ],
        ),
      ],
    );
    return ExploreViewData(
      now: now,
      run: run,
      inspectorOpen: locale == 'zh',
      runs: [
        ExploreRunSummary(
          id: run.id,
          name: run.name,
          updatedAt: now,
          total: 20,
          favorites: 4,
          lines: 1,
        ),
      ],
      variables: [
        ExploreVariable(
          title: blocks.first.title,
          color: accent,
          poolSize: 10,
          evolution: true,
        ),
      ],
      generate: const ExploreGenerate(count: 12, cost: 0),
    );
  }

  RefsViewData refs(RefsKind kind) {
    final entries = [
      for (var i = 0; i < 16; i++)
        RefsEntry(
          key: 'ref$i',
          name: '${tr('光影练习', 'Light study')} ${i + 1}',
          thumb: images.image('refs/$i'),
          favorite: i % 3 == 0,
          inGeneration: i < 2,
          hasRaw: true,
          encodedFor: 'V4.5',
          usedCount: 32 - i,
          categoryId: 'sample',
          tags: const ['soft lighting', 'starry sky'],
          createdAt: now,
          fileName: 'sample-${i + 1}.png',
          imageSize: const Size(832, 1216),
          imageFormat: 'PNG',
        ),
    ];
    return RefsViewData(
      kind: kind,
      now: now,
      model: const RefsModel(
        name: 'V4.5 Full',
        shortName: 'V4.5',
        vibeUsable: true,
        preciseUsable: true,
      ),
      entries: entries,
      counts: const RefsCounts(all: 16, favorites: 6),
      selectedKey: 'ref0',
      categories: [
        RefsCategory(id: 'sample', name: tr('示范', 'Examples'), count: 16),
      ],
      detail: RefsDetail(key: entries.first.key, image: entries.first.thumb),
      folderPath: r'D:\NAI Studio\references',
    );
  }

  OnlineViewData get online {
    final works = [
      for (var i = 0; i < 24; i++)
        OnlineWork(
          key: 'sample:$i',
          id: 10000 + i,
          thumb: images.image(
            'online/$i',
            direction: i.isEven ? 'portrait' : 'landscape',
          ),
          width: i.isEven ? 832 : 1216,
          height: i.isEven ? 1216 : 832,
          title: '${tr('星光练习', 'Starlight study')} ${i + 1}',
          author: 'sample_${artists[i % 10].substring(7)}',
          views: 2400 + i * 124,
          favorites: 100 + i * 7,
          model: 'V5',
          favorited: i % 4 == 0,
        ),
    ];
    return OnlineViewData(
      source: OnlineSource.aiTag,
      sources: const [
        OnlineSourceStatus(
          source: OnlineSource.aiTag,
          promptQuery: true,
          ranking: true,
          favorites: true,
          favoritesLocal: true,
          multiMedia: true,
        ),
      ],
      query: const OnlineQuery(work: 'starry sky', prompt: 'soft lighting'),
      list: OnlineList(key: 'sample', items: works, pages: 1),
      selectedKey: works.first.key,
      detail: OnlineDetail(
        key: works.first.key,
        prompt: prompt,
        negative: negative,
        siteTags: const ['starry sky', 'long hair', 'flowers'],
        canSendParams: true,
        media: [
          OnlineMedia(
            image: works.first.thumb,
            thumb: works.first.thumb,
            width: 832,
            height: 1216,
          ),
        ],
        params: const OnlineParams(
          model: 'V5 Full',
          width: 832,
          height: 1216,
          seed: 194200001,
          steps: 28,
          cfg: 5,
          sampler: 'Euler Ancestral',
        ),
      ),
    );
  }

  ViewerViewData get viewer {
    final items = [
      for (var i = 1; i <= 24; i++)
        ViewerItem(
          key: '$i',
          width: i.isEven ? 1216 : 832,
          height: i.isEven ? 832 : 1216,
          image: images.viewer('$i', false),
          thumb: images.viewer('$i', true),
          date: now,
          favorite: i % 3 == 0,
        ),
    ];
    return ViewerViewData(
      mode: ViewerMode.gallery,
      items: items,
      currentKey: '2',
      now: now,
      total: 24,
      position: 1,
      actions: ViewerAction.values.toSet(),
      zoomHintSeen: true,
      detail: ViewerDetail(
        key: '2',
        status: ViewerMetaStatus.ready,
        fileName: 'sample-starlight.png',
        folder: tr('示范', 'Examples'),
        model: 'V5 Full',
        seed: 194200002,
        steps: 28,
        scale: 5,
        sampler: 'Euler Ancestral',
        prompt: prompt,
        negative: negative,
      ),
    );
  }

  AgentViewData agent(String scene) {
    final running = scene == 'run';
    final workspace = AgentWorkspaceInfo(
      id: 'sample',
      name: tr('画风工作室', 'Style studio'),
      chatCount: 3,
    );
    final chat = AgentChatInfo(
      id: 'sample',
      title: tr('星夜配色研究', 'Starlight color study'),
      createdAt: now,
    );
    AgentImage pic(String key) => AgentImage(
      id: key,
      image: images.fileImage('s01.jpg'),
      width: 1024,
      height: 1024,
      source: AgentImageSource.attachment,
    );
    return AgentViewData(
      now: now,
      workspace: workspace,
      chat: chat,
      workspaces: [workspace],
      chats: [chat],
      composer: AgentComposerData(
        text: '',
        canAttachCanvas: true,
        pending: [
          if (scene == 'approval')
            AgentApproval(
              'a1',
              tool: 'block_manage',
              preview:
                  '{\n  "action": "save",\n  "name": "${blocks[5].title}",\n  "content": "cinematic lighting, rim light"\n}',
              options: [
                tr('允许一次', 'Allow once'),
                tr('本会话允许相同调用', 'Allow for this session'),
                tr('拒绝', 'Deny'),
              ],
            ),
        ],
      ),
      thread: [
        AgentTurn(
          id: 't1',
          user: AgentUserMessage(
            at: now,
            text: tr(
              '参考这张图，保留构图，把提示词调整为星夜与柔和光影。先展示改动，不生成。',
              'Keep this composition. Adjust the prompt for a starry night and soft lighting. Show the changes; do not generate.',
            ),
            images: [pic('source')],
          ),
          reply: AgentReply(
            blocks: [
              AgentStepsBlock([
                const AgentStep(
                  id: 's1',
                  tool: 'studio_context',
                  status: AgentStepStatus.done,
                  duration: Duration(milliseconds: 180),
                ),
                const AgentStep(
                  id: 's2',
                  tool: 'image_read',
                  status: AgentStepStatus.done,
                  duration: Duration(milliseconds: 920),
                ),
                AgentStep(
                  id: 's3',
                  tool: 'tag_query',
                  status: running
                      ? AgentStepStatus.running
                      : AgentStepStatus.done,
                  subject: 'starry_sky, soft_lighting',
                ),
              ]),
              AgentTextBlock(
                tr(
                  '已读取草稿和参考图。建议保留主体与构图，加入 **starry sky**、**soft lighting**，用冷色与花朵光点建立层次。\n\n没有调用生成接口，也没有消耗 Anlas。',
                  'I reviewed the draft and reference. Keep the subject and composition; add **starry sky** and **soft lighting**, with cool colors and glowing flowers.\n\nNo generation request or Anlas charge was made.',
                ),
              ),
              if (!running)
                const AgentDiffBlock(
                  AgentPromptDiff(
                    id: 'diff',
                    field: AgentPromptField.prompt,
                    segments: [
                      AgentDiffSegment('1girl, solo, long hair, '),
                      AgentDiffSegment(
                        'starry sky, soft lighting, glowing flowers',
                        AgentDiffKind.added,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
      shelf: AgentShelfData(
        groups: [
          AgentShelfGroup(
            id: 't1',
            title: chat.title,
            at: now,
            images: [pic('source')],
          ),
        ],
      ),
      usage: const AgentUsageData(tokens: 12480, window: 128000, toolCalls: 3),
      models: AgentFixture.models,
      thinking: AgentFixture.thinking,
      permission: AgentPermissionMode.ask,
      mentions: const [],
      skills: const [],
      status: running ? AgentRunStatus.working : AgentRunStatus.idle,
    );
  }

  SettingsViewData settings(SettingsPageId page) {
    final b = SettingsFixture.view(page: page, scene: SettingsScene.fresh);
    return b.copyWith(
      values: SettingsValues({
        SettingKey.language: locale,
        SettingKey.imageSavePath: r'D:\NAI Studio\outputs',
        SettingKey.ragEnabled: true,
        SettingKey.ragEmbedPath: r'D:\NAI Studio\models\embeddinggemma-2',
        SettingKey.ragRerankPath: r'D:\NAI Studio\models\Qwen3-Reranker-0.6B',
        SettingKey.agentModel: 'claude-sonnet-4.5',
      }),
      dictionaries: const SettingsDictionaryData(
        tagCount: 640000,
        wikiCount: 53860,
        cooccurrence: 2400000,
        dataVersion: '2026-10-22',
        caches: {
          SettingsCacheKind.translation: (1280, 320000),
          SettingsCacheKind.danbooru: (2400, 620000),
        },
      ),
      agent: SettingsAgentData(
        dataPath: r'D:\NAI Studio\agent-data',
        workspaces: 3,
        sessions: 8,
        skills: [
          for (final name in ['nai-studio', 'nai-prompt'])
            SettingsSkill(
              id: 'builtin/$name',
              name: name,
              source: SettingsSkillSource.builtin,
              description: tr(
                'Studio 工具与提示词工作流',
                'Studio tools and prompt workflow',
              ),
              path: 'builtin/$name',
            ),
        ],
        tools: const [
          'studio_context',
          'image_read',
          'prompt_update',
          'tag_query',
          'wiki_query',
          'block_manage',
          'studio_search',
          'generation_prepare',
        ],
        skillFolders: const [
          (SettingsSkillSource.global, r'D:\NAI Studio\agent-data\skills'),
        ],
      ),
      rag: SettingsRagData(
        runtimeReady: true,
        runtimeCuda: true,
        runtimePython: r'D:\NAI Studio\runtime\python.exe',
        runtime: SettingsRagStep(
          value: 'Python 3.12 · CUDA',
          detail: tr('独立运行环境', 'Isolated runtime'),
        ),
        embedder: SettingsRagStep(
          value: 'EmbeddingGemma 2',
          detail: tr('文字 + 图片', 'Text + images'),
        ),
        reranker: const SettingsRagStep(value: 'Qwen3-Reranker 0.6B'),
        device: const SettingsRagStep(value: 'NVIDIA GPU'),
        indexBytes: 320 * 1024 * 1024,
        sources: [
          for (final kind in SettingsRagSourceKind.values)
            SettingsRagSource(
              kind: kind,
              state: SettingsRagState.ready,
              done: kind == SettingsRagSourceKind.tags ? 53860 : 240,
              total: kind == SettingsRagSourceKind.tags ? 53860 : 240,
            ),
        ],
      ),
    );
  }

  ProvidersViewData get providers => const ProvidersViewData(
    protocols: [
      ProvidersProtocol(
        id: 'openaiChatCompletions',
        label: 'OpenAI Chat Completions',
        reasoningLevels: ['none', 'low', 'medium', 'high'],
      ),
      ProvidersProtocol(
        id: 'anthropicMessages',
        label: 'Anthropic Messages',
        reasoningLevels: ['none', 'low', 'medium', 'high'],
      ),
    ],
    providers: [
      ProviderItem(
        id: 'sample',
        mark: 'S',
        apiKeyMasked: '••••••••',
        status: SettingsTone.ok,
        latencyMs: 96,
        settings: ProviderSettings(
          name: 'Sample Cloud',
          baseUrl: 'https://api.example.com/v1',
          protocolId: 'openaiChatCompletions',
          models: [
            ProviderModelSettings(
              id: 'sample-vision',
              contextWindow: 128000,
              maxOutput: 8192,
              reasoningLevels: ['none', 'low', 'medium', 'high'],
              defaultLevel: 'medium',
              capabilities: {
                ProviderCapability.vision,
                ProviderCapability.tools,
              },
            ),
          ],
        ),
      ),
      ProviderItem(
        id: 'local',
        mark: 'L',
        local: true,
        settings: ProviderSettings(
          name: 'Local Studio',
          baseUrl: 'http://localhost:1234/v1',
          protocolId: 'openaiChatCompletions',
          models: [
            ProviderModelSettings(
              id: 'sample-local',
              contextWindow: 32768,
              maxOutput: 4096,
              capabilities: {ProviderCapability.tools},
            ),
          ],
        ),
      ),
    ],
    catalogs: {
      'sample': ProviderCatalog(
        state: ProviderCatalogState.ready,
        entries: [
          ProviderCatalogEntry(id: 'sample-vision', contextWindow: 128000),
          ProviderCatalogEntry(id: 'sample-text', contextWindow: 64000),
        ],
      ),
    },
  );

  ToolsUpscaleData get upscale => ToolsUpscaleData(
    backends: [
      ToolsUpscaleBackend(
        id: 'local',
        title: tr('本机', 'Local'),
        detail: tr('本机显卡 · 不消耗 Anlas', 'Local GPU · No Anlas'),
      ),
      ToolsUpscaleBackend(
        id: 'novelai',
        title: 'NovelAI',
        detail: tr('云端 2× 放大', 'Cloud 2× upscale'),
        cost: 1,
      ),
    ],
    backend: 'local',
    sourceWidth: 832,
    sourceHeight: 1216,
    methods: [
      ToolsOption(id: 'regular', label: tr('普通模型', 'Standard')),
      const ToolsOption(id: 'seedvr2', label: 'SeedVR2'),
      const ToolsOption(id: 'rtx', label: 'RTX'),
    ],
    method: 'seedvr2',
    models: const [
      ToolsUpscaleModel(
        id: 'seedvr2-3b',
        label: 'SeedVR2 3B FP8',
        detail: '3.4 GB',
      ),
      ToolsUpscaleModel(
        id: 'seedvr2-7b',
        label: 'SeedVR2 7B FP8',
        detail: '8.2 GB',
      ),
    ],
    model: 'seedvr2-3b',
    scale: 2,
    outWidth: 1664,
    outHeight: 2432,
    advanced: [
      ToolsUpscaleField(
        id: 'blocksToSwap',
        label: tr('CPU 卸载层数', 'CPU offload blocks'),
        kind: ToolsFieldKind.number,
        value: 8.0,
        max: 32,
      ),
      ToolsUpscaleField(
        id: 'vaeTiled',
        label: tr('VAE 分块', 'Tiled VAE'),
        kind: ToolsFieldKind.toggle,
        value: true,
      ),
      ToolsUpscaleField(
        id: 'inputNoise',
        label: tr('输入噪声', 'Input noise'),
        kind: ToolsFieldKind.number,
        value: 0.0,
        decimals: 2,
      ),
    ],
  );

  StatsViewData get stats {
    final s = StatsFixture.snapshot();
    return StatsViewData(
      range: StatsRange.all,
      naiOnly: false,
      today: StatsFixture.today,
      sync: StatsSyncState.idle,
      snapshot: StatsSnapshot(
        libraryTotal: s.libraryTotal,
        images: s.images,
        favorites: s.favorites,
        bytes: s.bytes,
        withMetadata: s.withMetadata,
        weekHour: s.weekHour,
        models: s.models,
        resolutions: s.resolutions,
        samplers: s.samplers,
        steps: s.steps,
        cfg: s.cfg,
        noiseSchedules: s.noiseSchedules,
        sizeBuckets: s.sizeBuckets,
        dailyImages: s.dailyImages,
        dailyModels: s.dailyModels,
        monthlyBytes: s.monthlyBytes,
        dailyAnlas: s.dailyAnlas,
        artists: StatsArtists(
          top: [
            for (var i = 0; i < 10; i++) StatsCount(artists[i], 1200 - i * 95),
          ],
          imagesWithArtist: 4200,
        ),
      ),
    );
  }
}
