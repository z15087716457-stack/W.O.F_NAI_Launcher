import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_panel.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_parts.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_prompt_set_card.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_dock.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_instance.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_page.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_parts.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_fixture.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_page.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_preview_image.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_shell.dart';
import 'package:nai_launcher/presentation/ui/online/online_contract.dart';
import 'package:nai_launcher/presentation/ui/online/online_page.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_page.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_intel.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_page.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_director.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_editor.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_sheets.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/translation_pill_view.dart';

import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/ui/blocks/blocks_test_harness.dart'
    show RecordingBlocks;
import '../../test/presentation/ui/settings/settings_test_harness.dart'
    show SettingsHost, SettingsRecorder;
import '../../test/presentation/ui/viewer/viewer_test_harness.dart'
    show RecordingViewerActions;
import 'agent_scenes.dart';
import 'canvas_scene.dart';
import 'images.dart';
import 'readme_data.dart';
import 'safety.dart';
import 'semantic_scenes.dart';
import 'gallery_scene.dart';

const captureKey = Key('readme-capture');

Widget shotApp(
  Widget page,
  ReadmeData data, {
  bool dark = false,
  bool tickers = false,
  NavPage? nav,
}) => RepaintBoundary(
  key: captureKey,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: dark ? GeistTheme.dark : GeistTheme.light,
    locale: Locale(data.locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: TickerMode(enabled: tickers, child: child!),
    ),
    home: Scaffold(
      body: WindowChromeScope(
        child: nav == null
            ? page
            : NavShell(
                data: NavViewData(
                  current: nav,
                  account: data.account,
                  ctrlHintSeen: true,
                ),
                actions: NavActions.none,
                child: page,
              ),
      ),
    ),
  ),
);

Widget promptEditor(ReadmeData d, GenEditorTarget target) {
  if (target.negative) {
    return const Text(negative, style: TextStyle(fontSize: 13, height: 1.65));
  }
  if (!target.isBase) {
    return const Text(
      '1girl, solo, long hair, silver hair, blue eyes, white dress',
      style: TextStyle(fontSize: 13, height: 1.65),
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        '1girl, solo, long hair, silver hair,',
        style: TextStyle(fontSize: 13, height: 1.7),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            BlockPill(d.blocks.first),
            BlockPill(d.blocks[1]),
            BlockPill(d.blocks[5]),
          ],
        ),
      ),
      const Text(
        'starry sky, glowing flowers, night,\ncinematic lighting, depth of field,',
        style: TextStyle(fontSize: 13, height: 1.7),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TranslationPillView(
          pill: TranslationPill(
            source: 'soft lighting, blue theme',
            zh: d.tr('柔和光影，蓝色调', 'soft lighting, blue theme'),
            languageCode: d.locale,
          ),
          onToggle: () {},
          onEdit: (_) {},
        ),
      ),
      const Text(
        'very aesthetic, masterpiece, no text',
        style: TextStyle(fontSize: 13, height: 1.7),
      ),
    ],
  );
}

Widget generation(
  ReadmeData d, {
  String scene = 'hero',
  ChannelTheme theme = ChannelTheme.stars,
}) {
  final settings = ChannelSettings(
    mode: ChannelMode.fixed,
    fixed: theme,
    level: ChannelLevel.strong,
    motion: false,
    ruler: true,
    seed: 7,
  );
  final dock = scene == 'blocks-dock';
  final agent = scene == 'gen-agent';
  final data = d.gen(dockOpen: dock, compact: agent, channel: settings);
  final page = GenerationPage(
    data: scene == 'tools-upscale'
        ? data.copyWith(
            canvas: GenCanvasData(
              focus: data.canvas.focus,
              info: data.canvas.info,
              upscale: data.canvas.upscale,
              sheet: GenToolSheet.upscale,
            ),
          )
        : data,
    actions: GenActions.logging((_) {}),
    slots: GenSlots(
      editor: (context, target) => promptEditor(d, target),
      canvas: (context, tile) =>
          ReadmeCanvas(images: d.images, settings: settings),
      dock: dock
          ? BlocksDock(data: d.dock, actions: RecordingBlocks().dock)
          : null,
      preserveHistory: agent,
      historyCaptionInset: !agent,
      toolSheet: scene == 'tools-upscale'
          ? ToolsUpscaleSheet(
              data: d.upscale,
              actions: ToolsUpscaleActions.logging((_) {}),
            )
          : null,
    ),
  );
  if (!agent) return page;
  return Row(
    children: [
      Expanded(child: page),
      SizedBox(
        width: 460,
        child: AgentPanel(
          data: d.agent('chat'),
          actions: AgentFixture.actions(),
        ),
      ),
    ],
  );
}

Widget exploreEditor(ReadmeData d, ExploreEditorParts parts) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    const Padding(
      padding: EdgeInsets.all(18),
      child: Text('V5 Full', style: TextStyle(fontWeight: FontWeight.w600)),
    ),
    Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              d.tr('提示词', 'Prompt'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            promptEditor(d, const GenEditorTarget.base()),
            const SizedBox(height: 24),
            parts.randomVariables,
            const SizedBox(height: 22),
            Text(
              d.tr('图像与参数', 'Image & parameters'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            const Text('832 × 1216\n\n28 steps · CFG 5.0\n\nEuler Ancestral'),
          ],
        ),
      ),
    ),
    parts.generateBar,
  ],
);

Future<void> warmImages(WidgetTester t, ShotImages images) async {
  await t.runAsync(() async {
    final ctx = t.element(find.byType(Scaffold).first);
    for (final provider in images.providers.toList()) {
      await precacheImage(provider, ctx);
    }
  });
  await t.pump(const Duration(milliseconds: 100));
  for (var pass = 0; pass < 2; pass++) {
    await t.runAsync(() async {
      for (final element in find.byType(Image).evaluate().toList()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> capture(
  WidgetTester t,
  String locale,
  String name,
  ShotImages images,
) async {
  await warmImages(t, images);
  await t.pump(const Duration(milliseconds: 250));
  final texts = scanText(t, '$locale/$name');
  if (name == 'agent-card-promptset') {
    final card = find.byType(AgentPromptSetCard);
    expect(card, findsOneWidget);
    final data = t.widget<AgentPromptSetCard>(card).data!;
    expect(data.ordered, isTrue);
    expect(data.kindIcon, 'film');
    expect(data.items.map((item) => item.icon), [
      'rain',
      'door',
      'umbrella',
      'coffee',
      'sun',
      'heart',
    ]);
    expect(data.revision, 2);
    expect(data.changedItems, [4]);
    expect(data.images[0], hasLength(1));
    final pictures = data.images.values.expand((images) => images).toList();
    expect(pictures.map((image) => image.image).toSet(), hasLength(3));
    expect(
      find.text(locale == 'zh' ? 'v2 · 已改 1 项' : 'v2 · 1 changed'),
      findsOneWidget,
    );
    expect(find.text('3 / 6'), findsOneWidget);
    expect(find.text(data.items[2].title), findsOneWidget);
    expect(find.byKey(const Key('agent-ps-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('agent-ps-dot-4')), findsOneWidget);
    final thumbs = t
        .widgetList<UiPreviewImage>(
          find.descendant(of: card, matching: find.byType(UiPreviewImage)),
        )
        .toList();
    expect(thumbs, hasLength(2));
    expect(
      thumbs.map((image) => image.image).toList(),
      data.images[2]!.map((image) => image.image).toList(),
    );
    expect(
      find.descendant(of: card, matching: find.byType(Image)),
      findsNWidgets(2),
    );
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text(locale == 'zh' ? '共同设定' : 'Shared'), findsOneWidget);
    expect(find.text(locale == 'zh' ? '这一幕' : 'This scene'), findsOneWidget);
    final more = find.byKey(const Key('agent-ps-more-prompt'));
    expect(
      more,
      findsOneWidget,
      reason: 'Prompt expanded, tag window retained',
    );
    expect(
      find.descendant(
        of: more,
        matching: find.text(locale == 'zh' ? '展开全部' : 'Show all'),
      ),
      findsOneWidget,
    );
    final promptFields = t
        .widgetList<Text>(
          find.descendant(of: card, matching: find.byType(Text)),
        )
        .where((text) => text.textSpan != null)
        .toList();
    expect(
      promptFields,
      hasLength(3),
      reason: 'Main, character and negative expanded',
    );
    expect(promptFields.first.textSpan!.toPlainText(), contains('… '));
    expect(
      promptFields.first.textSpan!.toPlainText(),
      contains('umbrella stand,'),
    );
    expect(
      promptFields[1].textSpan!.toPlainText(),
      contains('looking at umbrella,'),
    );
    final segments = (promptFields.first.textSpan! as TextSpan).children!
        .cast<TextSpan>();
    expect(
      segments.any((span) => span.style?.backgroundColor != null),
      isTrue,
      reason: 'Item tags are highlighted',
    );
    expect(
      segments.any((span) => span.style?.backgroundColor == null),
      isTrue,
      reason: 'Shared tags are not highlighted',
    );
    final generate = find.byKey(const Key('agent-ps-generate'));
    expect(t.widget<AgentButton>(generate).onPressed, isNotNull);
    expect(
      find.descendant(of: generate, matching: find.text('20')),
      findsOneWidget,
    );
  }
  if (name == 'translation' || name == 'tag-expansion') {
    final expected = name == 'translation'
        ? (locale == 'en' ? 'Prompt · Bilingual reading' : '提示词 · 双语阅读')
        : (locale == 'en'
              ? 'Tag expansion · Local semantic search'
              : '标签扩展 · 本地语义推荐');
    expect(texts, contains(expected), reason: 'Localized host title');
  }
  expect(t.takeException(), isNull, reason: '$locale/$name rendering error');
  final out = Directory('.dart_tool/readme-shots/out/$locale')
    ..createSync(recursive: true);
  await t.runAsync(() async {
    final boundary = t.renderObject<RenderRepaintBoundary>(
      find.byKey(captureKey),
    );
    final bitmap = await boundary.toImage(pixelRatio: 2);
    try {
      final png = await bitmap.toByteData(format: ui.ImageByteFormat.png);
      File('${out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    } finally {
      bitmap.dispose();
    }
  });
  final content = name.startsWith('agent-card-')
      ? null
      : name == 'blocks-rules'
      ? find.byKey(const Key('block-rules'))
      : name.startsWith('agent-')
      ? find.byType(AgentPanel)
      : name.startsWith('theme-')
      ? find.byKey(const Key('channel-fixture-canvas'))
      : null;
  if (content != null || name.startsWith('agent-card-')) {
    final r = name.startsWith('agent-card-')
        ? agentCardFrame(t)
        : t.getRect(content!);
    File('${out.path}/$name.frame.json').writeAsStringSync(
      jsonEncode({
        'box': [r.left * 2, r.top * 2, r.right * 2, r.bottom * 2],
      }),
    );
  }
  File(
    '${out.path}/$name.text.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(texts));
  File('${out.path}/$name.images.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(images.assignments),
  );
}

Future<void> tap(WidgetTester t, String key) async {
  await t.tap(find.byKey(Key(key)));
  await t.pump(const Duration(milliseconds: 350));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final available = ShotImages().available;
  if (!available) {
    debugPrint(
      'SKIP README screenshots: ${ShotImages.directory}/index.json not found or empty.',
    );
  }
  setUpAll(() async {
    await loadStudioCaptureFonts();
    loadFixtureBlacklist();
  });
  setUpSemanticFakes();
  setUpGalleryFakes();

  test('privacy scanner catches report names and machine paths', () {
    loadFixtureBlacklist();
    for (final s in [
      'artist:sincos',
      'blue_archive',
      '0.8::artist:rella::',
      r'E:\A.I\NovelAI',
      'PieDriver',
      '鹈鹕',
      'nero claudius (fate)',
    ]) {
      expect(forbiddenMatch(s), isNotNull, reason: s);
    }
    expect(forbiddenMatch(prompt), isNull);
    expect(forbiddenMatch('artist:sample_alpha, luminous colors'), isNull);
  });

  test(
    'generation artwork and history covers stay distinct',
    skip: !available,
    () {
      final images = ShotImages();
      final history = ReadmeData('en', images).gen().history;
      final providers = history.batches
          .expand((b) => b.images)
          .map((i) => i.thumb)
          .toList();
      expect(providers.toSet().length, providers.length);
      final canvas = ReadmeCanvas.files.map(images.fileImage).toSet();
      expect(canvas.length, 4);
      expect(canvas.intersection(providers.toSet()), isEmpty);
      expect(
        ReadmeCanvas.files
            .map(
              (f) => images.entries.firstWhere(
                (e) => e['file'] == f,
              )['orientation'],
            )
            .toSet(),
        containsAll(['portrait', 'landscape']),
      );
    },
  );

  const names = [
    'hero',
    'hero-dark',
    'gen-agent',
    'blocks-library',
    'blocks-dock',
    'blocks-random',
    'blocks-sequential',
    'blocks-locked',
    'blocks-rules',
    'explore-main',
    'explore-evolution',
    'explore-compare',
    'channel',
    'channel-dark',
    'gallery',
    'viewer',
    'online',
    'refs-vibe',
    'refs-precise',
    'tools-upscale',
    'tools-director',
    'tools-inpaint',
    'settings-rag',
    'settings-agent',
    'settings-models',
    'settings-dictionaries',
    'agent-chat',
    'agent-approval',
    'agent-run',
    ...agentCardNames,
    'translation',
    'tag-expansion',
    'wiki',
    'stats',
    'theme-stars',
    'theme-circuit',
    'theme-abyss',
    'theme-metro',
    'theme-score',
    'theme-moon',
  ];
  for (final locale in ['zh', 'en']) {
    for (final name in names) {
      testWidgets('$locale/$name', skip: !available, (t) async {
        final images = ShotImages();
        final d = ReadmeData(locale, images);
        final oldShadows = debugDisableShadows;
        debugDisableShadows = false;
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = name.startsWith('agent-card-')
            ? const Size(460, 1200)
            : name.startsWith('agent-')
            ? const Size(460, 1000)
            : name.startsWith('blocks-') &&
                  !['blocks-library', 'blocks-dock'].contains(name)
            ? const Size(520, 1000)
            : name == 'translation'
            ? const Size(900, 430)
            : name == 'tag-expansion'
            ? const Size(1000, 820)
            : const Size(1600, 1000);
        addTearDown(t.view.reset);
        try {
          Widget page;
          NavPage? nav;
          final rec = RecordingBlocks();
          if ([
                'hero',
                'hero-dark',
                'gen-agent',
                'blocks-dock',
                'channel',
                'channel-dark',
                'tools-upscale',
              ].contains(name) ||
              name.startsWith('theme-')) {
            final theme = switch (name) {
              'theme-circuit' => ChannelTheme.circuit,
              'theme-abyss' => ChannelTheme.abyss,
              'theme-metro' => ChannelTheme.metro,
              'theme-score' => ChannelTheme.score,
              'theme-moon' => ChannelTheme.luna,
              _ => ChannelTheme.stars,
            };
            page = name.startsWith('theme-')
                ? Center(
                    child: SizedBox(
                      width: 1100,
                      height: 650,
                      child: ChannelFixtureCanvas(
                        settings: ChannelSettings(
                          mode: ChannelMode.fixed,
                          fixed: theme,
                          level: ChannelLevel.strong,
                          motion: false,
                          ruler: false,
                          seed: 7,
                        ),
                        onSettingsChanged: (_) {},
                        images: (key) => key == 'canvas'
                            ? images.fileImage(switch (theme) {
                                ChannelTheme.circuit => 's09.jpg',
                                ChannelTheme.abyss => 's13.jpg',
                                ChannelTheme.metro => 's15.jpg',
                                ChannelTheme.score => 's16.jpg',
                                ChannelTheme.luna => 's17.jpg',
                                _ => 's07.jpg',
                              })
                            : images.channel(key),
                        focusScale: .82,
                        focusY: 620,
                      ),
                    ),
                  )
                : generation(d, scene: name, theme: theme);
            nav = name.startsWith('theme-') ? null : NavPage.generation;
          } else if (name == 'blocks-library') {
            page = BlocksLibraryPage(data: d.library, actions: rec.library);
            nav = NavPage.promptBlocks;
          } else if (name.startsWith('blocks-')) {
            final data = d.instance(
              sequential: name == 'blocks-sequential',
              locked: name == 'blocks-locked',
            );
            page = Padding(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: Alignment.topCenter,
                child: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(
                        locale == 'en' && name != 'blocks-rules' ? .86 : 1,
                      ),
                    ),
                    child: BlockInstanceCard(
                      data: data,
                      actions: rec.instance(data),
                      initialRules: name == 'blocks-rules',
                    ),
                  ),
                ),
              ),
            );
          } else if (name.startsWith('explore-')) {
            page = StyleExplorePage(
              data: d.explore,
              actions: ExploreActions.none,
              editor: (ctx, parts) => exploreEditor(d, parts),
            );
            nav = NavPage.styleExplore;
          } else if (name == 'viewer') {
            page = ImageViewerPage(
              data: d.viewer,
              actions: RecordingViewerActions().actions,
            );
            nav = NavPage.localGallery;
          } else if (name == 'online') {
            page = OnlineGalleryPage(
              data: d.online,
              actions: OnlineActions.none,
            );
            nav = NavPage.onlineGallery;
          } else if (name.startsWith('refs-')) {
            final vibe = name == 'refs-vibe';
            page = RefsLibraryPage(
              data: d.refs(vibe ? RefsKind.vibe : RefsKind.precise),
              actions: RefsActions.none,
            );
            nav = vibe ? NavPage.vibeLibrary : NavPage.preciseRef;
          } else if (name.startsWith('settings-')) {
            final id = switch (name) {
              'settings-rag' => SettingsPageId.rag,
              'settings-agent' => SettingsPageId.agent,
              'settings-models' => SettingsPageId.models,
              _ => SettingsPageId.dictionaries,
            };
            var data = d.settings(id);
            if (id == SettingsPageId.models) {
              data = data.copyWith(
                models: SettingsModelsData(workbench: d.providers),
              );
            }
            // ignore: invalid_use_of_visible_for_testing_member
            SettingsAgentPage.resetTab();
            page = SettingsHost(data: data, rec: SettingsRecorder());
            nav = NavPage.settings;
          } else if (name.startsWith('agent-card-')) {
            page = agentCardScene(d, name);
          } else if (name.startsWith('agent-')) {
            page = AgentPanel(
              data: d.agent(name.substring(6)),
              actions: AgentFixture.actions(),
            );
          } else if (name == 'stats') {
            page = StatisticsPage(data: d.stats, actions: StatsActions.none);
            nav = NavPage.statistics;
          } else if (name == 'translation') {
            page = Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.tr('提示词 · 双语阅读', 'Prompt · Bilingual reading'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  promptEditor(d, const GenEditorTarget.base()),
                  const SizedBox(height: 20),
                  Text(
                    d.tr(
                      '翻译只改变阅读，生成始终使用英文原文。',
                      'Reading translations do not change the generation source.',
                    ),
                  ),
                ],
              ),
            );
          } else if (name == 'tools-inpaint') {
            final data =
                ToolsFixture.editor(
                  mode: ToolsEditorMode.inpaint,
                  images: images.gen,
                ).copyWith(
                  layers: [
                    ToolsLayer(
                      id: 'mask',
                      name: d.tr('蒙版', 'Mask'),
                      kind: ToolsLayerKind.mask,
                    ),
                    ToolsLayer(
                      id: 'base',
                      name: d.tr('底图', 'Source'),
                      kind: ToolsLayerKind.base,
                      thumb: images.gen('src'),
                      locked: true,
                    ),
                  ],
                );
            page = ToolsEditorPage(
              data: data,
              actions: ToolsEditorActions.logging((_) {}),
              slots: const ToolsEditorSlots(canvas: ToolsFixtureStage.builder),
            );
            nav = NavPage.generation;
          } else if (name == 'tools-director') {
            page = ToolsDirectorPage(
              data: ToolsFixture.director(images: images.gen).copyWith(
                runs: [
                  for (final r in ToolsFixture.runs(images.gen))
                    ToolsDirectorRun(
                      id: r.id,
                      tool: r.tool,
                      inputId: r.inputId,
                      images: r.images,
                      time: r.time,
                      width: r.width,
                      height: r.height,
                      cost: r.cost,
                      variants: r.variants.isEmpty
                          ? const []
                          : [
                              d.tr('透明底', 'Transparent'),
                              d.tr('背景', 'Background'),
                              d.tr('合成', 'Composite'),
                            ],
                    ),
                ],
              ),
              actions: ToolsDirectorActions.logging((_) {}),
            );
            nav = NavPage.generation;
          } else if (name == 'gallery') {
            page = galleryScene(d);
            nav = NavPage.localGallery;
          } else {
            page = name == 'wiki' ? wikiScene(d) : expansionScene(d);
            nav = name == 'wiki' ? NavPage.tagWiki : null;
          }
          final app = shotApp(
            page,
            d,
            dark: name.endsWith('-dark'),
            tickers: name == 'agent-card-tags',
            nav: nav,
          );
          Future<void> render() async {
            await t.pumpWidget(
              name == 'tag-expansion'
                  ? ProviderScope(overrides: overrides(d), child: app)
                  : app,
            );
            await warmImages(t, images);
            await t.pump(const Duration(seconds: 5));
            if (name == 'gallery') await prepareGallery(t, d);
            if (name == 'wiki') await prepareWiki(t);
            if (name == 'tag-expansion') await prepareExpansion(t);
            if (name.startsWith('agent-card-')) {
              await prepareAgentCard(t, d, name);
            }
            if (name == 'settings-agent') await tap(t, 'agent-tab-skills');
            if (name == 'blocks-rules') await tap(t, 'block-rules-advanced');
            if (name == 'explore-evolution' || name == 'explore-compare') {
              await tap(t, 'explore-tab-evolution');
            }
            if (name == 'explore-compare') await tap(t, 'explore-compare');
            if (name.startsWith('channel')) await tap(t, 'gen-display');
            if (name == 'tools-upscale') await tap(t, 'tools-upscale-advanced');
            await capture(t, locale, name, images);
          }

          if (name == 'gallery') {
            await withGalleryFiles(render);
          } else {
            await render();
          }
        } finally {
          await t.pumpWidget(const SizedBox.shrink());
          await t.pump();
          debugDisableShadows = oldShadows;
        }
      });
    }
  }
}
