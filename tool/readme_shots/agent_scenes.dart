import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_cards.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_parts.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_prompt_set_card.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_scope.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_thread.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_text.dart';

import 'readme_data.dart';

const agentCardNames = [
  'agent-card-diff',
  'agent-card-position',
  'agent-card-settings',
  'agent-card-gallery',
  'agent-card-tags',
  'agent-card-ask',
  'agent-card-gate',
  'agent-card-images',
  'agent-card-thinking',
  'agent-card-promptset',
];

const _galleryFiles = [
  's05.jpg',
  's06.jpg',
  's07.jpg',
  's08.jpg',
  's14.jpg',
  's21.jpg',
];
const _outputFiles = ['s07.jpg', 's09.jpg', 's15.jpg', 's19.jpg'];

List<AgentImage> _pictures(ReadmeData d, List<String> files) => [
  for (final (i, file) in files.indexed)
    AgentImage(
      id: 'sample-${i + 1}',
      image: d.images.fileImage(file),
      width: d.images.entries.firstWhere((e) => e['file'] == file)['w'] as int,
      height: d.images.entries.firstWhere((e) => e['file'] == file)['h'] as int,
      label: '${i + 1}',
    ),
];

AgentPromptSet _promptSet(ReadmeData d) {
  final pictures = _pictures(d, ['s07.jpg', 's09.jpg', 's15.jpg']);
  return AgentPromptSet(
    setId: 'sample-storyboard',
    revision: 2,
    kind: d.tr('分镜卡', 'Storyboard'),
    kindIcon: 'film',
    title: d.tr('雨夜咖啡馆', 'Rainy-night cafe'),
    unit: d.tr('幕', 'scene'),
    ordered: true,
    shared: const AgentPromptSetShared(
      main:
          'masterpiece, best quality, very aesthetic, cinematic lighting, night, rain, 1girl, solo',
      characters: [
        'girl, silver hair, long hair, blue eyes, white blouse, black skirt',
      ],
      negative: 'lowres, bad anatomy, bad hands, text, watermark, blurry',
    ),
    items: [
      for (final entry in [
        (
          'rain',
          d.tr('大雨', 'Sudden rain'),
          d.tr('大雨突至，她沿街寻找避雨处。', 'She runs down the street, seeking shelter.'),
          'city street, heavy rain, running, wide shot',
          'running, wet hair',
        ),
        (
          'door',
          d.tr('推门', 'An open door'),
          d.tr(
            '街角灯光温暖，推门时风铃响起。',
            'A warm cafe glows; the door chimes as she enters.',
          ),
          'cafe entrance, door bell, warm light',
          'opening door, looking inside',
        ),
        (
          'umbrella',
          d.tr('借伞的人', 'An umbrella to borrow'),
          d.tr(
            '门口留着一把伞，纸条写着“请自取”。',
            'An umbrella by the door has a note: “Please borrow.”',
          ),
          'umbrella stand, note on wall, close-up, warm indoor light',
          'looking at umbrella, curious',
        ),
        (
          'coffee',
          d.tr('热咖啡', 'A warm cup'),
          d.tr(
            '她捧着热咖啡，看雨滴滑过玻璃。',
            'She warms her hands on a cup, watching the rain.',
          ),
          'cafe interior, window seat, coffee mug, bokeh',
          'sitting, holding mug, slight smile',
        ),
        (
          'sun',
          d.tr('雨后晨光', 'Morning after rain'),
          d.tr(
            '雨停了，她迎着晨光回来还伞。',
            'The rain has stopped; she returns the umbrella at dawn.',
          ),
          'morning, sunlight, light rays, cafe entrance',
          'returning umbrella, smiling',
        ),
        (
          'heart',
          d.tr('再次相遇', 'A reason to return'),
          d.tr(
            '又逢雨夜，这一次她为重逢而来。',
            'Another rainy night; this time she comes to meet a friend.',
          ),
          'night, rain, cafe window, warm light',
          'holding umbrella, happy',
        ),
      ])
        AgentPromptSetItem(
          icon: entry.$1,
          title: entry.$2,
          note: entry.$3,
          main: entry.$4,
          characters: [entry.$5],
        ),
    ],
    changedItems: const [4],
    images: {
      0: [pictures[0]],
      2: [pictures[1], pictures[2]],
    },
    unitAnlas: 20,
  );
}

AgentViewData agentCardData(ReadmeData d, String name) {
  final base = d.agent('chat');
  final blocks = <AgentBlock>[];
  final pending = <AgentPending>[];
  AgentTurnSummary? summary;
  switch (name) {
    case 'agent-card-promptset':
      final data = _promptSet(d);
      blocks.add(
        AgentPromptSetBlock(
          setId: data.setId,
          revision: data.revision,
          changedItems: data.changedItems,
          data: data,
        ),
      );
    case 'agent-card-diff':
      blocks.addAll([
        AgentTextBlock(
          d.tr(
            '已修改 5 处字段：基础提示词、负面提示词、步数、采样器和尺寸。下方 3 张改动卡可整体撤销。',
            'Updated 5 fields: base prompt, negative prompt, steps, sampler and size. Undo all 3 change cards together below.',
          ),
        ),
        // The real summary counts undoable cards, not individual parameters.
        const AgentChangeSummaryBlock(
          id: 'sample-all',
          ids: ['sample-base', 'sample-negative', 'sample-params'],
          added: 5,
          removed: 2,
        ),
        const AgentDiffBlock(
          AgentPromptDiff(
            id: 'sample-base',
            field: AgentPromptField.prompt,
            segments: [
              AgentDiffSegment('1girl, solo, artist:sample_alpha, '),
              AgentDiffSegment('day, ', AgentDiffKind.removed),
              AgentDiffSegment(
                'starry sky, night, soft lighting, ',
                AgentDiffKind.added,
              ),
              AgentDiffSegment('glowing flowers'),
            ],
          ),
        ),
        const AgentDiffBlock(
          AgentPromptDiff(
            id: 'sample-negative',
            field: AgentPromptField.negative,
            segments: [
              AgentDiffSegment('lowres, blurry, '),
              AgentDiffSegment('dark, ', AgentDiffKind.removed),
              AgentDiffSegment('text, watermark', AgentDiffKind.added),
            ],
          ),
        ),
        const AgentParamBlock(
          id: 'sample-params',
          changes: [
            AgentParamChange(
              AgentParam.steps,
              AgentParamValue.text('28'),
              AgentParamValue.text('32'),
            ),
            AgentParamChange(
              AgentParam.sampler,
              AgentParamValue.text('Euler'),
              AgentParamValue.text('Euler Ancestral'),
            ),
            AgentParamChange(
              AgentParam.size,
              AgentParamValue.text('1024×1024'),
              AgentParamValue.text('832×1216'),
            ),
          ],
        ),
      ]);
    case 'agent-card-position':
      blocks.add(
        AgentPositionBlock(
          id: 'sample-position',
          customBefore: false,
          customAfter: true,
          aspect: 832 / 1216,
          marks: [
            AgentPositionMark(
              index: 0,
              name: d.tr('旅人', 'Traveler'),
              after: const Offset(.25, .4),
            ),
            AgentPositionMark(
              index: 1,
              name: d.tr('向导', 'Guide'),
              after: const Offset(.75, .4),
            ),
            AgentPositionMark(
              index: 2,
              name: d.tr('同伴', 'Companion'),
              after: const Offset(.5, .75),
            ),
          ],
        ),
      );
    case 'agent-card-settings':
      blocks.add(
        AgentSettingsBlock(
          id: 'sample-settings',
          changes: [
            AgentSettingChange(
              key: 'theme',
              label: d.tr('主题', 'Theme'),
              before: d.tr('浅色', 'Light'),
              after: d.tr('深色', 'Dark'),
              anchor: (section: 'appearance', anchor: 'theme'),
            ),
            AgentSettingChange(
              key: 'font_scale',
              label: d.tr('界面字号', 'UI text size'),
              before: '100%',
              after: '110%',
              anchor: (section: 'appearance', anchor: 'font_scale'),
            ),
            AgentSettingChange(
              key: 'visual_channel',
              label: d.tr('视觉通道', 'Visual channel'),
              before: d.tr('关', 'Off'),
              after: d.tr('星图', 'Star chart'),
              anchor: (section: 'appearance', anchor: 'visual_channel'),
            ),
          ],
        ),
      );
    case 'agent-card-gallery':
      blocks.add(
        AgentGalleryBlock(
          id: 'sample-gallery',
          action: AgentGalleryAction.move,
          images: _pictures(d, _galleryFiles),
          count: 6,
          target: d.tr('夜景', 'Night scenes'),
          undoable: true,
        ),
      );
    case 'agent-card-tags':
      blocks.add(
        AgentStepsBlock([
          AgentStep(
            id: 'sample-tags',
            tool: 'tag_query',
            subject: d.tr('星夜与银河', 'Starry nights'),
            status: AgentStepStatus.done,
            duration: const Duration(milliseconds: 240),
            tags: [
              AgentTagHit(
                tag: 'starry_sky',
                count: 428000,
                translation: d.tr('星空', 'Starry sky'),
                summary: d.tr('布满星星的天空。', 'A sky filled with stars.'),
              ),
              AgentTagHit(
                tag: 'night_sky',
                count: 316000,
                translation: d.tr('夜空', 'Night sky'),
              ),
              AgentTagHit(
                tag: 'milky_way',
                count: 62400,
                translation: d.tr('银河', 'Milky Way'),
              ),
              AgentTagHit(
                tag: 'shooting_star',
                count: 48100,
                translation: d.tr('流星', 'Shooting star'),
                summary: d.tr('夜空中划过的流星。', 'A meteor crossing the night sky.'),
              ),
            ],
          ),
        ]),
      );
    case 'agent-card-ask':
      pending.add(
        AgentAsk(
          'sample-ask',
          questions: [
            AgentQuestion(
              id: 'sample-aspect',
              text: d.tr('画面比例选哪个？', 'Which image aspect ratio?'),
              options: [
                d.tr('竖图 · 832 × 1216', 'Portrait · 832 × 1216'),
                d.tr('横图 · 1216 × 832', 'Landscape · 1216 × 832'),
                d.tr('方图 · 1024 × 1024', 'Square · 1024 × 1024'),
              ],
              placeholder: d.tr('自定义比例或尺寸…', 'Custom ratio or dimensions…'),
            ),
          ],
        ),
      );
    case 'agent-card-gate':
      pending.add(
        AgentGate(
          'sample-gate',
          kind: AgentGateKind.text2img,
          expiresAt: base.now.add(const Duration(minutes: 2)),
          ready: true,
          model: 'V5 Full',
          width: 832,
          height: 1216,
          requests: 4,
          batch: 1,
          unitAnlas: 20,
          encodingAnlas: 2,
          totalAnlas: 82,
          balanceAnlas: 2218,
          account: d.tr('示范账号', 'Sample account'),
          extra: d.tr(
            '生成 20 × 4 = 80；首次参考图编码 2；合计 82 Anlas。',
            '20 × 4 = 80 for images + 2 for reference encoding = 82 Anlas.',
          ),
        ),
      );
    case 'agent-card-images':
      blocks.add(
        AgentImagesBlock(images: _pictures(d, _outputFiles), anlasSpent: 80),
      );
      summary = const AgentTurnSummary(
        took: Duration(seconds: 42),
        anlas: 80,
        toolCalls: 4,
      );
    case 'agent-card-thinking':
      blocks.addAll([
        AgentThinkingBlock(
          d.tr(
            '先读取当前草稿，确认主体与构图；查阅星空词条，再用通用标签改写提示词。保留原负面提示词，不调用生成接口。',
            'Read the draft and preserve the subject and composition. Look up sky tags, then revise the prompt with general tags. Keep the negative prompt; do not generate.',
          ),
        ),
        const AgentStepsBlock([
          AgentStep(
            id: 'sample-context',
            tool: 'studio_context',
            status: AgentStepStatus.done,
            duration: Duration(milliseconds: 180),
          ),
          AgentStep(
            id: 'sample-wiki',
            tool: 'wiki_query',
            subject: 'starry_sky',
            status: AgentStepStatus.done,
            duration: Duration(milliseconds: 620),
          ),
          AgentStep(
            id: 'sample-update',
            tool: 'prompt_update',
            status: AgentStepStatus.done,
            duration: Duration(milliseconds: 90),
          ),
        ]),
      ]);
    default:
      throw ArgumentError.value(name, 'name', 'Unknown Agent card scene');
  }
  return AgentViewData(
    now: base.now,
    workspace: base.workspace,
    chat: base.chat,
    workspaces: base.workspaces,
    chats: base.chats,
    composer: AgentComposerData(text: '', pending: pending),
    thread: blocks.isEmpty
        ? const []
        : [
            AgentTurn(
              id: 'sample-turn',
              user: AgentUserMessage(
                at: base.now,
                text: d.tr('卡片示例', 'Card example'),
              ),
              reply: AgentReply(blocks: blocks, summary: summary),
            ),
          ],
    shelf: const AgentShelfData(groups: []),
    usage: base.usage,
    models: base.models,
    thinking: base.thinking,
    permission: base.permission,
    mentions: const [],
    skills: const [],
    status: pending.isEmpty ? AgentRunStatus.idle : AgentRunStatus.waitingUser,
  );
}

/// Equivalent to pumpAgent's isolated host, without the header/composer.
/// AgentThread still dispatches every block and renders the actual task card,
/// process timeline, summary and pending cards. No provider or live state.
Widget agentCardScene(ReadmeData d, String name) => Builder(
  builder: (context) => AgentScope(
    data: agentCardData(d, name),
    actions: AgentFixture.actions(),
    slots: const AgentSlots(),
    run: (action) async {
      await action();
    },
    rename: ({required title, required value, required save}) {},
    zoom: (image, {group}) {},
    insert: (text, {replace = false}) {},
    toast: (_) {},
    confirm:
        ({
          required title,
          required message,
          required confirm,
          danger = false,
          optOut,
        }) async => null,
    undoToast: (text, onUndo) {},
    child: DefaultTextStyle.merge(
      style: UiText.sans(13, color: context.ui.ink),
      child: const TooltipTheme(
        data: TooltipThemeData(preferBelow: true),
        child: Padding(padding: EdgeInsets.all(4), child: AgentThread()),
      ),
    ),
  ),
);

Future<void> prepareAgentCard(WidgetTester t, ReadmeData d, String name) async {
  if (name == 'agent-card-promptset') {
    // Selection and prompt expansion are real widget-internal state.
    for (var i = 0; i < 2; i++) {
      await t.tap(find.byKey(const Key('agent-ps-next')));
      await t.pump();
    }
    expect(find.byKey(const Key('agent-ps-more-prompt')), findsNothing);
    await t.tap(find.byKey(const Key('agent-ps-prompt')));
    await t.pump();
  }
  if (name == 'agent-card-thinking') {
    await t.tap(find.byKey(const Key('agent-fold-0')));
    await t.pump();
    expect(find.byKey(const Key('agent-thinking')), findsOneWidget);
    expect(find.byKey(const Key('agent-thinking-text')), findsNothing);
    for (final id in ['sample-context', 'sample-wiki', 'sample-update']) {
      expect(find.byKey(Key('agent-step-$id')), findsOneWidget);
    }
  }
  if (name == 'agent-card-tags') {
    final chip = find.byKey(const Key('agent-tag-sample-tags-shooting_star'));
    final tooltip = find.ancestor(of: chip, matching: find.byType(Tooltip));
    expect(t.state<TooltipState>(tooltip).ensureTooltipVisible(), isTrue);
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.textContaining(d.tr('流星', 'Shooting star')), findsWidgets);
    final fade = find.ancestor(
      of: find.textContaining(
        d.tr('夜空中划过的流星。', 'A meteor crossing the night sky.'),
      ),
      matching: find.byType(FadeTransition),
    );
    expect(fade, findsWidgets);
    expect(t.widget<FadeTransition>(fade.first).opacity.value, 1);
    expect(
      find.byKey(const Key('agent-step-tags-sample-tags')),
      findsOneWidget,
    );
  }
  if (name == 'agent-card-gate') {
    expect(find.text('20 Anlas'), findsOneWidget);
    expect(find.text('2 Anlas'), findsOneWidget);
    expect(find.text('82'), findsOneWidget);
    expect(find.textContaining('2,218'), findsOneWidget);
    expect(find.text(d.tr('参考图编码', 'Reference encoding')), findsOneWidget);
    final confirm = t.widget<AgentButton>(
      find.byKey(const Key('agent-gate-confirm')),
    );
    expect(confirm.onPressed, isNotNull);
  }
  if (name == 'agent-card-gallery' || name == 'agent-card-images') {
    final thumbs = t.widgetList<AgentThumb>(find.byType(AgentThumb)).toList();
    expect(thumbs.length, name == 'agent-card-gallery' ? 6 : 4);
    expect(thumbs.map((e) => e.image.image).toSet().length, thumbs.length);
    if (name == 'agent-card-images') {
      expect(
        find.byKey(const Key('agent-turn-summary-sample-turn')),
        findsOneWidget,
      );
    }
  }
}

/// Keep the full 460 logical px width (18px side margins), but crop vertically
/// to real task/pending geometry. Export adds 18px above/below; extending the
/// screenshot bounds itself would accidentally include the preceding user row.
/// The tag tooltip is also real rendered UI, including its inner padding.
Rect agentCardFrame(WidgetTester t) {
  final rects = [
    for (final element in find.byType(AgentCard).evaluate())
      t.getRect(find.byWidget(element.widget)),
    for (final element in find.byType(AgentGateCard).evaluate())
      t.getRect(find.byWidget(element.widget)),
    for (final element in find.byType(AgentPromptSetCard).evaluate())
      t.getRect(find.byWidget(element.widget)),
    for (final element in find.byType(Tooltip).evaluate())
      if (element.widget is Tooltip) ...[
        for (final text
            in find.text((element.widget as Tooltip).message ?? '').evaluate())
          t.getRect(find.byWidget(text.widget)).inflate(10),
      ],
  ];
  expect(rects, isNotEmpty);
  final bounds = rects.reduce((a, b) => a.expandToInclude(b));
  final viewport = t.view.physicalSize / t.view.devicePixelRatio;
  final frame = Rect.fromLTRB(0, bounds.top, 460, bounds.bottom);
  expect(frame.top, greaterThanOrEqualTo(0));
  expect(frame.bottom, lessThanOrEqualTo(viewport.height));
  return frame;
}
