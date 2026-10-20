import 'package:flutter/widgets.dart';

import '../kit/ui_fixture_image.dart';
import 'agent_contract.dart';

/// 侧栏的样例数据（预览、测试、截图）。和原型 `.devin/mockups/agent-redesign` 同一组内容。
enum AgentScene {
  welcome,
  chat,
  ask,
  run,
  compose,
  shelf,
  memory,
  empty,
  error,
  approval,
}

abstract final class AgentFixture {
  static final now = DateTime(2026, 10, 18, 16, 44, 8);

  static AgentImage img(
    String key, {
    String? label,
    bool starred = false,
    AgentImageSource source = AgentImageSource.generated,
  }) => AgentImage(
    id: key,
    image: UiFixtureImage.gradient(key),
    width: 832,
    height: 1216,
    label: label,
    starred: starred,
    source: source,
    historyId: source == AgentImageSource.attachment ? null : 'h-$key',
  );

  static const workspace = AgentWorkspaceInfo(
    id: 'w1',
    name: '画风研究',
    chatCount: 3,
  );

  static final chats = [
    AgentChatInfo(
      id: 'c3',
      title: '水彩改稿',
      createdAt: DateTime(2026, 10, 18, 16, 38),
      state: AgentChatState.waitingUser,
      canExport: true,
    ),
    AgentChatInfo(
      id: 'c2',
      title: '厚涂对比三种光源',
      createdAt: DateTime(2026, 10, 18, 16, 12),
      canExport: true,
    ),
    AgentChatInfo(
      id: 'c1',
      title: '赛博街景提示词拆解',
      createdAt: DateTime(2026, 10, 17, 21, 3),
      canExport: true,
    ),
    AgentChatInfo(
      id: 'c0',
      title: '角色 1 发型统一',
      createdAt: DateTime(2026, 10, 16, 10, 20),
      canExport: true,
    ),
  ];

  static const workspaces = [
    workspace,
    AgentWorkspaceInfo(id: 'w2', name: '角色设定集', chatCount: 6),
    AgentWorkspaceInfo(id: 'w3', name: '画师收藏整理', chatCount: 2),
  ];

  static final models = [
    const AgentModelOption(
      providerId: 'anthropic',
      modelId: 'claude-sonnet-4-5',
      label: 'Sonnet 4.5',
      provider: 'Anthropic',
      selected: true,
      logoAsset: 'anthropic',
    ),
    const AgentModelOption(
      providerId: 'anthropic',
      modelId: 'claude-opus-4-1',
      label: 'Opus 4.1',
      provider: 'Anthropic',
      logoAsset: 'anthropic',
    ),
    const AgentModelOption(
      providerId: 'openai',
      modelId: 'gpt-5',
      label: 'GPT-5',
      provider: 'OpenAI',
      logoAsset: 'openai',
    ),
    const AgentModelOption(
      providerId: 'deepseek',
      modelId: 'deepseek-chat',
      label: 'DeepSeek V3.2',
      provider: 'DeepSeek',
      mark: 'DS',
    ),
  ];

  static const thinking = AgentThinkingData(
    options: [('low', '低'), ('medium', '中'), ('high', '高')],
    selected: 'medium',
    followsModel: false,
  );

  static final mentions = [
    const AgentMention(
      id: 'm-prompt',
      kind: AgentMentionKind.prompt,
      label: '基础提示词',
      detail: '24 个标签',
    ),
    const AgentMention(
      id: 'm-c1',
      kind: AgentMentionKind.character,
      label: '角色 1',
      detail: '17 个标签',
    ),
    AgentMention(
      id: 'g18',
      kind: AgentMentionKind.image,
      label: '本次产物 2',
      detail: '★',
      image: UiFixtureImage.gradient('g18'),
    ),
    AgentMention(
      id: 'h0',
      kind: AgentMentionKind.image,
      label: '历史 16:42',
      detail: '832×1216',
      image: UiFixtureImage.gradient('h0'),
    ),
    const AgentMention(
      id: 'b400',
      kind: AgentMentionKind.block,
      label: '400精选画师池',
      detail: '32 个',
    ),
    const AgentMention(
      id: 'b-water',
      kind: AgentMentionKind.block,
      label: '水彩晕染',
      detail: '6 个',
    ),
  ];

  static const skills = [
    AgentSkillOption(name: 'nai-prompt', description: 'NovelAI 提示词写法与模型差异'),
    AgentSkillOption(name: 'nai-studio', description: 'Studio 工具与工作流参考'),
    AgentSkillOption(name: 'style-replica', description: '画风复刻：拆解参考图并逐步逼近'),
  ];

  static final draft = AgentDraftSummary(
    model: 'V4.5 Full',
    prompt:
        'scenery, panorama, from behind, green theme, magical atmosphere, wide shot…',
    width: 832,
    height: 1216,
    image: UiFixtureImage.gradient('h0'),
    characters: 1,
    blocks: 2,
  );

  static const _diff = AgentPromptDiff(
    id: 'd1',
    field: AgentPromptField.prompt,
    segments: [
      AgentDiffSegment('scenery, panorama, from behind, '),
      AgentDiffSegment('(extremely vibrant colors)', AgentDiffKind.removed),
      AgentDiffSegment(' '),
      AgentDiffSegment(
        'watercolor (medium), wet-on-wet, muted colors',
        AgentDiffKind.added,
      ),
      AgentDiffSegment(
        ', magical atmosphere, wide shot, white dress, blue flower, ',
      ),
      AgentDiffSegment('sketch,', AgentDiffKind.removed),
      AgentDiffSegment(' '),
      AgentDiffSegment('0.6::lineart::', AgentDiffKind.added),
      AgentDiffSegment(', very aesthetic, masterpiece'),
    ],
  );

  static List<AgentStep> _steps(AgentScene s) => [
    const AgentStep(
      id: 's1',
      tool: 'studio_context',
      status: AgentStepStatus.done,
      duration: Duration(milliseconds: 200),
      arguments: '{ "include": ["prompt", "characters", "blocks"] }',
      result:
          '{ "model": "nai-diffusion-4-5-full", "size": "832×1216", "characters": 1 }',
    ),
    const AgentStep(
      id: 's2',
      tool: 'image_read',
      status: AgentStepStatus.done,
      subject: 'g07.jpg',
      duration: Duration(milliseconds: 3100),
    ),
    const AgentStep(
      id: 's3',
      tool: 'wiki_query',
      status: AgentStepStatus.done,
      subject: 'watercolor',
      duration: Duration(milliseconds: 800),
    ),
    if (s == AgentScene.ask) ...[
      const AgentStep(
        id: 's4',
        tool: 'ask_user',
        status: AgentStepStatus.waitingUser,
      ),
    ] else if (s == AgentScene.run) ...[
      const AgentStep(
        id: 's4',
        tool: 'prompt_update',
        status: AgentStepStatus.done,
        duration: Duration(milliseconds: 300),
      ),
      const AgentStep(
        id: 's5',
        tool: 'generation_run',
        status: AgentStepStatus.running,
        subject: '3/4',
      ),
    ] else ...[
      const AgentStep(
        id: 's4',
        tool: 'prompt_update',
        status: AgentStepStatus.done,
        duration: Duration(milliseconds: 300),
      ),
      const AgentStep(
        id: 's5',
        tool: 'generation_prepare',
        status: AgentStepStatus.waitingUser,
        subject: '80 Anlas',
      ),
    ],
  ];

  static List<AgentTurn> thread(AgentScene s) {
    final blocks = <AgentBlock>[
      AgentStepsBlock(_steps(s)),
      const AgentTextBlock(
        '参考图是**低饱和的湿画法水彩**：边缘晕开、留白多、线稿很淡。和草稿冲突的主要是高饱和与草图线条。',
      ),
      if (s != AgentScene.ask) const AgentDiffBlock(_diff),
      if (s == AgentScene.run)
        AgentImagesBlock(
          images: [
            img('g03', label: '1'),
            img('g18', label: '2', starred: true),
            img('h1', label: '3'),
          ],
          expected: 4,
          anlasSpent: 60,
        ),
    ];
    return [
      AgentTurn(
        id: 't1',
        user: AgentUserMessage(
          text: '参考这张图的画风，把当前草稿改成水彩感。先给我看改动，再生成 4 张。',
          at: DateTime(2026, 10, 18, 16, 40),
          images: [img('g07', source: AgentImageSource.attachment)],
          entryId: 'e1',
        ),
        reply: AgentReply(blocks: blocks, live: s == AgentScene.run),
      ),
    ];
  }

  static AgentGate gate() => AgentGate(
    'g1',
    kind: AgentGateKind.text2img,
    expiresAt: now.add(const Duration(minutes: 4, seconds: 52)),
    ready: true,
    model: 'V4.5 Full',
    width: 832,
    height: 1216,
    requests: 4,
    batch: 1,
    unitAnlas: 20,
    totalAnlas: 80,
    balanceAnlas: 2218,
    source: UiFixtureImage.gradient('h0'),
  );

  static const ask = AgentAsk(
    'q1',
    questions: [
      AgentQuestion(
        id: 'keep',
        text: '这次要保留现在的哪部分？',
        options: ['保留构图，只换画风', '保留角色和构图', '都可以改，按参考图来'],
        prefill: '保留角色和构图',
      ),
    ],
  );

  static const approval = AgentApproval(
    'a1',
    tool: 'block_manage',
    preview:
        '{\n  "action": "save",\n  "name": "水彩湿画法",\n  "content": "watercolor (medium), wet-on-wet, muted colors, 0.6::lineart::"\n}',
    options: ['允许一次', '本会话允许相同调用', '拒绝'],
  );

  static final shelf = AgentShelfData(
    groups: [
      AgentShelfGroup(
        id: 't1',
        title: '水彩改稿',
        at: DateTime(2026, 10, 18, 16, 40),
        images: [
          img('g18', label: '2', starred: true),
          img('g03', label: '1'),
          img('h1', label: '3'),
          img('g07', source: AgentImageSource.attachment),
        ],
      ),
      AgentShelfGroup(
        id: 't0',
        title: '厚涂对比三种光源',
        at: DateTime(2026, 10, 18, 16, 12),
        images: [
          img('g33', label: '1'),
          img('g41', label: '2'),
          img('g46', label: '3'),
        ],
      ),
    ],
    files: const [
      AgentFile(id: 'f1', name: 'watercolor-notes.md', bytes: 2150),
      AgentFile(id: 'f2', name: 'prompt-backup-1640.json', note: '备份'),
    ],
  );

  static const memory = AgentMemoryData(
    globalInstructions: '回答用中文。改提示词前先列出要改的地方；花 Anlas 前一定先问我。',
    workspaceRules: '这个工作区专门研究画风：每次只改一个变量，产物按「画风-日期」命名。',
    activeSkills: ['nai-prompt', 'nai-studio', 'style-replica'],
  );

  static AgentViewData view(AgentScene s, {double? width}) {
    final pending = <AgentPending>[
      if (s == AgentScene.chat) gate(),
      if (s == AgentScene.ask) ask,
      if (s == AgentScene.approval) approval,
    ];
    final welcome = s == AgentScene.welcome;
    return AgentViewData(
      now: now,
      workspace: workspace,
      chat: welcome
          ? AgentChatInfo(id: 'c4', title: '新聊天', createdAt: now)
          : chats.first,
      workspaces: workspaces,
      chats: welcome
          ? [AgentChatInfo(id: 'c4', title: '新聊天', createdAt: now), ...chats]
          : chats,
      composer: AgentComposerData(
        text: '',
        pending: pending,
        canSend: s == AgentScene.compose || s == AgentScene.run,
        canAttachCanvas: true,
        queue: s == AgentScene.run
            ? const [
                AgentQueued(
                  id: 'q1',
                  text: '然后把最好的一张做成积木',
                  kind: AgentQueueKind.queued,
                ),
              ]
            : const [],
      ),
      thread: welcome || s == AgentScene.empty || s == AgentScene.error
          ? const []
          : thread(s == AgentScene.approval ? AgentScene.chat : s),
      shelf: welcome ? const AgentShelfData() : shelf,
      memory: memory,
      usage: const AgentUsageData(
        tokens: 43200,
        window: 200000,
        input: 128400,
        output: 9620,
        cacheRead: 96000,
        cacheWrite: 21300,
        total: 255320,
        userMessages: 3,
        assistantMessages: 3,
        toolCalls: 11,
      ),
      models: models,
      thinking: thinking,
      permission: AgentPermissionMode.auto,
      mentions: mentions,
      skills: skills,
      draft: draft,
      status: switch (s) {
        AgentScene.run => AgentRunStatus.working,
        AgentScene.ask ||
        AgentScene.chat ||
        AgentScene.approval => AgentRunStatus.waitingUser,
        _ => AgentRunStatus.idle,
      },
      error: s == AgentScene.error ? '服务商返回 429：请求太频繁，稍后再试。' : null,
      initError: null,
      revision: 1,
    );
  }

  /// 不做事的回调（预览 / 测试里再按需覆盖）。
  static AgentActions actions({
    VoidCallback? onClose,
    void Function(String name, [Object? arg])? record,
  }) {
    Future<bool> ok(String name, [Object? arg]) async {
      record?.call(name, arg);
      return true;
    }

    void note(String name, [Object? arg]) => record?.call(name, arg);
    return AgentActions(
      onClose: onClose ?? () => note('close'),
      onNewChat: () => ok('newChat'),
      onSelectChat: (id) => ok('selectChat', id),
      onRenameChat: (id, t) => ok('renameChat', (id, t)),
      onSelectWorkspace: (id) => ok('selectWorkspace', id),
      onCreateWorkspace: (n) => ok('createWorkspace', n),
      onRenameWorkspace: (id, n) => ok('renameWorkspace', (id, n)),
      onOpenWorkspaceFolder: () => note('openFolder'),
      onCompact: () => ok('compact'),
      onExport: () => ok('export'),
      onOpenSettings: () => note('settings'),
      onComposerChanged: (t) => note('composer', t),
      onSend: ({required steer}) => ok('send', steer),
      onStop: () => ok('stop'),
      onPickImages: () => ok('pickImages'),
      onAttachCanvas: () => ok('attachCanvas'),
      onAttachImage: (id) => ok('attachImage', id),
      onPaste: () async {
        note('paste');
        return null;
      },
      onRemoveAttachment: (id) => ok('removeAttachment', id),
      onEditQueued: (id, t) => ok('editQueued', (id, t)),
      onSteerQueued: (id) => ok('steerQueued', id),
      onWithdrawQueued: (id) => ok('withdrawQueued', id),
      onRestoreQueued: (id) => ok('restoreQueued', id),
      onEditMessage: (id) => ok('editMessage', id),
      onRegenerate: () => ok('regenerate'),
      onAnswer: (id, a) => note('answer', (id, a)),
      onCancelAsk: (id) => note('cancelAsk', id),
      onApprove: (id, o) => note('approve', (id, o)),
      onCancelApproval: (id) => note('cancelApproval', id),
      onDecideGate: (id, {required confirm}) => note('gate', (id, confirm)),
      onUndoDiff: (id) => ok('undoDiff', id),
      onUndoDiffs: (ids) => ok('undoDiffs', ids),
      onRevealImage: (id) => note('reveal', id),
      onOpenFile: (id) => note('openFile', id),
      onOpenLink: (u) => note('openLink', u),
      onSelectModel: (p, m) => ok('selectModel', (p, m)),
      onOpenModelSettings: () => note('modelSettings'),
      onThinking: (e) => ok('thinking', e),
      onPermission: (m) => ok('permission', m),
      onRefreshUsage: () async => note('refreshUsage'),
      onDismissNotices: () => note('dismissNotices'),
      onRetryInit: () => note('retryInit'),
      onEditMemory: (t) => note('editMemory', t),
      onDeleteChat: (id) async {
        note('deleteChat', id);
        return 'trash-$id';
      },
      onDeleteWorkspace: (id) async {
        note('deleteWorkspace', id);
        return 'trash-$id';
      },
      onUndoDelete: (t) => ok('undoDelete', t),
      onSearchChats: (q) async {
        note('searchChats', q);
        return [
          for (final chat in AgentFixture.chats)
            if (chat.title.contains('角色'))
              AgentChatHit(
                chatId: chat.id,
                title: chat.title,
                snippet: '…$q 出现在这段对话里…',
              ),
        ];
      },
      onImageAction: (id, a) => ok('imageAction', (id, a)),
      onSilenceBypass: () => ok('silenceBypass'),
      onContinue: () => ok('continue'),
      onAdjustLimit: () => note('adjustLimit'),
    );
  }
}
