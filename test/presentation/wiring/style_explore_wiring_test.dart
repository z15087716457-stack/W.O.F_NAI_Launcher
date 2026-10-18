import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_dock.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_instance.dart';
import 'package:nai_launcher/presentation/wiring/blocks_preferences.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/pill_workspace_storage.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_candidate_deletion.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart'
    as domain;
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/layout_state_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_page.dart';
import 'package:nai_launcher/presentation/wiring/style_explore_backend.dart';
import 'package:nai_launcher/presentation/wiring/style_explore_platform.dart';
import 'package:nai_launcher/presentation/wiring/style_explore_wiring.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_controls/generation_controls.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_window_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_panel.dart';
import 'package:nai_launcher/presentation/widgets/nai_agent/nai_agent_image_input.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:nai_launcher/presentation/wiring/generation_wiring.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent_generation_host.dart';
import '../../helpers/studio_capture_fonts.dart';
import '../screens/generation/widgets/reference_module_test.dart'
    show prepareGenerationDropTestPlatform;
import 'generation_data_wiring_test.dart' show DataShortcuts;
import 'generation_reference_imports_test.dart' show ImportStorage;

class _Runs extends StyleExploreRunStorage {
  final runs = <String, domain.ExploreRun>{};
  final deletions = <String, ExploreCandidateDeletion>{};
  @override
  Future<List<domain.ExploreRun>> getRuns() async => runs.values.toList();
  @override
  Future<domain.ExploreRun?> getRun(String id) async => runs[id];
  @override
  Future<void> putRun(
    domain.ExploreRun run, {
    void Function()? beforeWrite,
  }) async {
    beforeWrite?.call();
    runs[run.id] = run;
  }

  @override
  Future<void> deleteRun(String id) async {
    runs.remove(id);
  }

  @override
  Future<List<ExploreCandidateDeletion>> getCandidateDeletions() async =>
      deletions.values.toList();
  @override
  Future<void> putCandidateDeletion(ExploreCandidateDeletion deletion) async {
    deletions[deletion.id] = deletion;
  }

  @override
  Future<void> deleteCandidateDeletion(String id) async {
    deletions.remove(id);
  }
}

class _Settings extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] is T ? values[key] as T : defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

class _Pills extends PillWorkspaceStorage {
  final values = <String, PillDocument>{
    PillScopes.main: const PillDocument(text: 'draft', instances: {}),
    PillScopes.negative: const PillDocument(text: 'negative', instances: {}),
  };
  @override
  PillDocument? tryLoadSync(String scope) => values[scope];
  @override
  Future<void> persist(String scope, PillDocument document) async {
    values[scope] = document;
  }
}

class _Library extends PromptBlockLibraryNotifier {
  final blocks = <PromptBlock>[];
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: blocks, folders: []);
}

class _Auth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(accountId: 'test', status: AuthStatus.authenticated);
}

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(
    prompt: 'draft',
    negativePrompt: 'negative',
    nSamples: 10,
  );
}

class _Characters extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig();
}

class _Subscription extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.initial();
}

class _Runner extends ExploreRunRunner {
  final calls = <String>[];
  int pauseCalls = 0;
  void configure(ExploreRunRunnerState value) {
    state = value;
  }

  @override
  void pause() {
    pauseCalls++;
  }

  @override
  ExploreRunRunnerState build() => const ExploreRunRunnerState();
  @override
  Future<bool> retryFailed(
    String id, {
    void Function(ImageParams)? beforeGenerate,
  }) async {
    calls.add('retry:$id');
    return true;
  }

  @override
  Future<bool> start(
    String id, {
    void Function(ImageParams)? beforeGenerate,
  }) async {
    calls.add('resume:$id');
    return true;
  }

  @override
  Future<bool> startDeepRound(
    String id, {
    String? familyId,
    String? parentSetId,
    int? count,
    void Function(ImageParams)? beforeGenerate,
  }) async {
    calls.add('children:$id:$familyId:$parentSetId:$count');
    return true;
  }
}

class _Platform extends StyleExplorePlatform {
  bool fullscreen = false;
  final backups = <String>[];
  Completer<void>? wait;
  @override
  Future<bool> isFullscreen() async => fullscreen;
  @override
  Future<bool> isMaximized() async => false;
  @override
  Future<void> setFullscreen(bool value) async {
    fullscreen = value;
  }

  @override
  Future<void> backupDraft(String snapshot) async {
    backups.add(snapshot);
    await wait?.future;
  }
}

class _Controls extends GenerationControlsController {
  int calls = 0;
  @override
  Future<void> generate() async {
    calls++;
  }
}

class _AgentStore extends AgentWorkspaceStore {
  _AgentStore(super.root);
  AgentSettings settings = const AgentSettings();
  @override
  Future<AgentSettings> readSettings() async => settings;
  @override
  Future<AgentSettings> patchSettings(Map<String, dynamic> changes) async =>
      settings = AgentSettings.fromJson({...settings.toJson(), ...changes});
  @override
  Future<void> saveComposer(
    String workspaceId,
    String chatId,
    AgentComposerState state,
  ) async {}
}

domain.ExploreRun _run(String id) {
  final created = DateTime(2026, 10, 12, 12);
  return domain.ExploreRun.create(
    id: id,
    name: id,
    targetCount: 2,
    createdAt: created,
    recipeSnapshot: const domain.ExploreRecipeSnapshot(
      positive: PillDocument(text: '', instances: {}),
      negative: PillDocument(text: '', instances: {}),
    ),
    paramsSnapshot: domain.ExploreParamsSnapshot.fromImageParams(
      const ImageParams(),
    ),
  ).copyWith(
    rounds: [
      domain.ExploreRound(
        id: 'round',
        number: 1,
        phase: domain.ExploreRoundPhase.manual,
        status: domain.ExploreRoundStatus.generated,
        createdAt: created,
        targetCount: 2,
        candidateIds: ['a', 'b'],
      ),
    ],
    candidates: const [
      domain.ExploreCandidate(
        id: 'a',
        roundId: 'round',
        number: 1,
        rollSnapshot: domain.ExploreRollSnapshot(
          positive: 'artist:a',
          negative: 'old negative',
        ),
        generation: domain.ExploreCandidateGeneration(
          status: domain.ExploreCandidateGenerationStatus.done,
        ),
        lineage: domain.ExploreLineage(
          operation: domain.ExploreLineageOperation.manual,
        ),
      ),
      domain.ExploreCandidate(
        id: 'b',
        roundId: 'round',
        number: 2,
        rollSnapshot: domain.ExploreRollSnapshot(
          positive: 'artist:b',
          negative: '',
        ),
        generation: domain.ExploreCandidateGeneration(
          status: domain.ExploreCandidateGenerationStatus.failed,
          error: 'failure',
        ),
        lineage: domain.ExploreLineage(
          operation: domain.ExploreLineageOperation.manual,
        ),
      ),
    ],
  );
}

void main() {
  prepareGenerationDropTestPlatform();
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  late _Runs storage;
  late _Settings settings;
  late _Pills pills;
  late _Runner runner;
  late _Platform platform;
  late _Controls controls;
  late _Library library;
  Directory? agentDirectory;
  NaiAgentWorkspaceController? agentController;
  ProviderContainer? mountedContainer;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    library = _Library();
    storage = _Runs()
      ..runs['first'] = _run('first')
      ..runs['second'] = _run('second');
    settings = _Settings();
    pills = _Pills();
    runner = _Runner();
    platform = _Platform();
    controls = _Controls();
    agentDirectory = null;
    agentController = null;
    mountedContainer = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('window_manager'),
          (call) async => call.method == 'isMaximized' ? false : null,
        );
  });
  tearDown(() async {
    mountedContainer?.dispose();
    await agentController?.close();
    await agentDirectory?.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), null);
  });

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    List<Override> overrides = const [],
    bool realEditor = false,
    ValueNotifier<bool>? generationRoute,
    Locale locale = const Locale('zh'),
    bool dark = false,
    double width = 1600,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: mountedContainer = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(settings),
            pillWorkspaceStorageProvider.overrideWithValue(pills),
            styleExploreRunStorageProvider.overrideWithValue(storage),
            promptBlockLibraryNotifierProvider.overrideWith(() => library),
            imageGenerationNotifierProvider.overrideWith(_Generation.new),
            authNotifierProvider.overrideWith(_Auth.new),
            generationParamsNotifierProvider.overrideWith(_Params.new),
            characterPromptNotifierProvider.overrideWith(_Characters.new),
            subscriptionNotifierProvider.overrideWith(_Subscription.new),
            exploreRunRunnerProvider.overrideWith(() => runner),
            styleExplorePlatformProvider.overrideWithValue(platform),
            kritaBridgeNotifierProvider.overrideWith(
              (ref) => KritaBridgeNotifier(),
            ),
            estimatedCostForBatchSizeProvider(1).overrideWith((ref) => 0),
            styleExploreCostForCountProvider.overrideWith((ref, count) => 0),
            anlasBalanceProvider.overrideWith((ref) => 100),
            shortcutConfigNotifierProvider.overrideWith(DataShortcuts.new),
            ...overrides,
          ],
        ),
        child: MaterialApp(
          theme: dark ? GeistTheme.dark : GeistTheme.light,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => RepaintBoundary(
            key: const Key('explore-agent-capture'),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
          home: Builder(
            builder: (context) {
              Widget explore() => StyleExploreWiring(
                generationController: controls,
                editor: realEditor
                    ? null
                    : (context, parts) => Column(
                        children: [
                          parts.randomVariables,
                          const Spacer(),
                          parts.generateBar,
                        ],
                      ),
              );
              return generationRoute == null
                  ? explore()
                  : NaiAgentIntegrationScope(
                      child: IntegratedTitleBarShell(
                        deferToRoute: true,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: generationRoute,
                          builder: (_, generation, _) =>
                              generation ? const GenerationRoute() : explore(),
                        ),
                      ),
                    );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/wof_logo_full.png'),
        tester.element(find.byType(StyleExploreWiring)),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StyleExploreWiring)),
    );
    container.read(exploreActiveRunIdProvider.notifier).state = 'first';
    await tester.pumpAndSettle();
    return container;
  }

  ExploreActions actions(WidgetTester tester) =>
      tester.widget<StyleExplorePage>(find.byType(StyleExplorePage)).actions;

  Future<ProviderContainer> mountAgent(
    WidgetTester tester,
    ValueNotifier<bool> route, {
    Locale locale = const Locale('zh'),
    bool dark = false,
    double width = 1600,
  }) async {
    late Directory directory;
    late NaiAgentWorkspaceController agent;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('explore-agent-');
      agent = NaiAgentWorkspaceController(
        store: _AgentStore(directory),
        initialWorkspaceName: 'Synthetic workspace',
        initialChatName: 'Synthetic chat',
        startClient: (_, __, ___, ____, _____) =>
            Future.error(StateError('UI test must not start a model')),
      );
      await agent.initialize(restoreHistory: false);
    });
    final preferences = NaiAgentUiPreferences()..replace(agent.settings);
    agent.addListener(() => preferences.replace(agent.settings));
    agent.ready = Future.value();
    agentDirectory = directory;
    agentController = agent;
    addTearDown(route.dispose);
    return mount(
      tester,
      realEditor: true,
      generationRoute: route,
      locale: locale,
      dark: dark,
      width: width,
      overrides: [
        naiAgentControllerProvider.overrideWith((ref) => agent),
        naiAgentWorkspaceStoreProvider.overrideWithValue(agent.store),
        naiAgentUiPreferencesProvider.overrideWith((ref) => preferences),
        naiAgentWindowHostProvider.overrideWithValue(null),
        naiAgentWindowControllerProvider.overrideWith(
          (ref) => NaiAgentWindowController(
            host: null,
            readSettings: () async => agent.settings,
            saveExpanded: (expanded) =>
                agent.updateSettings({'panelExpanded': expanded}),
          ),
        ),
        naiAgentNativeDragEnabledProvider.overrideWithValue(false),
        vibeLibraryStorageServiceProvider.overrideWithValue(ImportStorage()),
        tipEpochProvider.overrideWith((ref) => Stream.value(0)),
      ],
    );
  }

  Future<void> captureAgent(WidgetTester tester, String name) async {
    if (Platform.environment['CAPTURE_EXPLORE_AGENT'] != '1') return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('explore-agent-capture')),
      );
      final bitmap = await boundary.toImage(pixelRatio: 1);
      final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
      bitmap.dispose();
      final file = File(
        '.dart_tool/explore-agent-entry-20261015/captures/$name.png',
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('explore Agent pin and panel share the generation runtime', (
    tester,
  ) async {
    final route = ValueNotifier(false);
    final container = await mountAgent(tester, route);
    final documents = Map.of(pills.values);
    final params = container.read(generationParamsNotifierProvider);
    final run = storage.runs['first'];
    final toggle = find.byKey(const Key('nai-agent-toggle'));
    expect(toggle, findsOneWidget);
    await tester.tap(find.byKey(const Key('gen-tool-menu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gen-pin-agent')), findsOneWidget);
    await captureAgent(tester, 'shared-menu');
    await tester.tap(find.byKey(const Key('gen-pin-agent')));
    await tester.pumpAndSettle();
    expect(toggle, findsNothing);
    expect(settings.getNaiAgentToolPinned(), isFalse);
    await tester.tapAt(const Offset(20, 850));
    await tester.pumpAndSettle();

    route.value = true;
    await tester.pumpAndSettle();
    expect(toggle, findsNothing);
    await tester.tap(find.byKey(const Key('gen-tool-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gen-pin-agent')));
    await tester.pumpAndSettle();
    expect(settings.getNaiAgentToolPinned(), isTrue);
    await tester.tapAt(const Offset(20, 850));
    await tester.pumpAndSettle();
    route.value = false;
    await tester.pumpAndSettle();
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      container.read(naiAgentControllerProvider).settings.panelExpanded,
      isTrue,
    );
    expect(find.byType(AgentPanel), findsOneWidget);
    expect(
      container.read(naiAgentUiPreferencesProvider).settings.panelExpanded,
      isTrue,
    );
    final reveal = find.byKey(const Key('nai-agent-reveal'));
    expect(tester.getSize(reveal).width, greaterThan(0));
    final editor = find.byKey(const Key('explore-editor'));
    final element = tester.element(editor);
    await captureAgent(tester, 'explore-open');
    final panelBefore = tester.getSize(reveal).width;
    await tester.drag(
      find.byKey(const Key('nai-agent-resize')),
      const Offset(-80, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(reveal).width, greaterThan(panelBefore));
    expect(tester.element(editor), same(element));

    route.value = true;
    await tester.pumpAndSettle();
    expect(find.byType(AgentPanel), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    route.value = false;
    await tester.pumpAndSettle();
    expect(find.byType(AgentPanel), findsNothing);
    expect(tester.getSize(reveal).width, 0);
    expect(pills.values, documents);
    expect(container.read(generationParamsNotifierProvider), params);
    expect(storage.runs['first'], run);
    expect(controls.calls, 0);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('explore Agent toolbar $language dark=$dark', (tester) async {
        final locale = language == 'zh_TW'
            ? const Locale('zh', 'TW')
            : Locale(language);
        final container = await mountAgent(
          tester,
          ValueNotifier(false),
          locale: locale,
          dark: dark,
          width: dark ? 1280 : 1800,
        );
        await tester.tap(find.byKey(const Key('gen-tool-menu')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('gen-pin-agent')), findsOneWidget);
        await captureAgent(tester, 'menu-$language-$dark');
        await tester.tapAt(const Offset(20, 850));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('nai-agent-toggle')));
        await tester.pumpAndSettle();
        expect(
          container.read(naiAgentControllerProvider).settings.panelExpanded,
          isTrue,
        );
        expect(find.byType(AgentPanel), findsOneWidget);
        final page = tester.getRect(find.byType(StyleExplorePage));
        final panel = tester.getRect(find.byType(AgentPanel));
        expect(panel.left, greaterThanOrEqualTo(page.right));
        expect(panel.right, lessThanOrEqualTo(dark ? 1280 : 1800));
        expect(find.byKey(const Key('explore-editor')), findsOneWidget);
        expect(
          find.byKey(const Key('window-caption-controls')),
          findsOneWidget,
        );
        expect(
          WindowChromeScope.activeOf(
            tester.element(find.byType(StyleExplorePage)),
          ),
          isFalse,
        );
        await captureAgent(tester, 'open-$language-$dark');
        expect(controls.calls, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'routes real run data and preserves a stale callback target after switching runs',
    (tester) async {
      await mount(tester);
      final old = actions(tester);
      old.onOpenRun('second');
      await tester.pumpAndSettle();
      old.onSetFavorite(['a'], true);
      await tester.pumpAndSettle();
      expect(storage.runs['first']!.candidateById('a')!.review.heart, isTrue);
      expect(storage.runs['second']!.candidateById('a')!.review.heart, isFalse);
      expect(
        tester
            .widget<StyleExplorePage>(find.byType(StyleExplorePage))
            .data
            .run
            ?.id,
        'second',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('group callbacks and run rename use their explicit targets', (
    tester,
  ) async {
    await mount(tester);
    actions(tester).onCreateGroup('Group', ['a']);
    await tester.pumpAndSettle();
    final group = storage.runs['first']!.folders.single;
    expect(storage.runs['first']!.candidateById('a')!.folderId, group.id);
    actions(tester).onRenameGroup(group.id, 'Renamed');
    actions(tester).onRenameRun('first', 'New name');
    await tester.pumpAndSettle();
    expect(storage.runs['first']!.folders.single.name, 'Renamed');
    expect(storage.runs['first']!.name, 'New name');
    actions(tester).onDeleteGroup(group.id);
    await tester.pumpAndSettle();
    expect(storage.runs['first']!.candidateById('a')!.folderId, isNull);
  });

  testWidgets(
    'layout and card-size callbacks persist through the existing stores',
    (tester) async {
      final container = await mount(tester);
      actions(tester).onCardSizeChanged(ExploreCardSize.small);
      actions(tester).onInspectorChanged(false);
      actions(tester).onEditorWidthChanged(900);
      actions(tester).onCountChanged(200);
      await tester.pumpAndSettle();
      expect(
        container.read(styleExploreCardSizeProvider),
        ExploreCardSize.small,
      );
      expect(
        container
            .read(layoutStateNotifierProvider)
            .styleExploreInspectorVisible,
        isFalse,
      );
      expect(
        container.read(layoutStateNotifierProvider).styleExploreEditorWidth,
        560,
      );
      expect(container.read(generationParamsNotifierProvider).nSamples, 100);
    },
  );

  testWidgets(
    'generation and retry delegate to guarded native handlers without an API request',
    (tester) async {
      await mount(tester);
      actions(tester).onGenerate();
      await tester.pumpAndSettle();
      expect(controls.calls, 1);
      actions(tester).onRetryFailed();
      await tester.pumpAndSettle();
      expect(runner.calls, ['retry:first']);
    },
  );

  testWidgets(
    'apply backs up before replacing only the positive draft and its parameter state',
    (tester) async {
      final container = await mount(tester);
      actions(tester).onApplyToEditor('a');
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(StyleExploreWiring)),
          )!.styleExplore_discardChangesConfirm,
        ),
      );
      await tester.pumpAndSettle();
      expect(platform.backups, hasLength(1));
      expect(
        container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
        'artist:a',
      );
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.negative))
            .document
            .text,
        'negative',
      );
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'artist:a',
      );
      expect(
        container.read(generationParamsNotifierProvider).negativePrompt,
        'negative',
      );
    },
  );

  testWidgets(
    'dock inserts a paired block after backup and records recent use',
    (tester) async {
      library.blocks.add(
        PromptBlock.create(
          id: 'block',
          title: 'Block',
          content: 'artist:a',
          negativeContent: 'bad anatomy',
        ),
      );
      final container = await mount(tester);
      actions(tester).onOpenBlockLibrary();
      await tester.pumpAndSettle();
      tester
          .widget<BlocksDock>(find.byType(BlocksDock))
          .actions
          .onInsert('block');
      await tester.pumpAndSettle();
      expect(platform.backups, hasLength(1));
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.main))
            .document
            .instances,
        hasLength(1),
      );
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.negative))
            .document
            .instances,
        hasLength(1),
      );
      expect(
        (await container.read(blocksPreferencesProvider.future)).recentIds,
        ['block'],
      );
    },
  );

  testWidgets(
    'a newer draft during dock backup is not replaced or inserted into',
    (tester) async {
      library.blocks.add(
        PromptBlock.create(id: 'block', title: 'Block', content: 'artist:a'),
      );
      final container = await mount(tester);
      actions(tester).onOpenBlockLibrary();
      await tester.pumpAndSettle();
      platform.wait = Completer<void>();
      tester
          .widget<BlocksDock>(find.byType(BlocksDock))
          .actions
          .onInsert('block');
      await tester.pump();
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .replaceWithPlainText('newer');
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('newer');
      platform.wait!.complete();
      await tester.pumpAndSettle();
      expect(
        container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
        'newer',
      );
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.main))
            .document
            .instances,
        isEmpty,
      );
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets(
    'variable rules use the real instance and do not initialize unopened negative lanes',
    (tester) async {
      library.blocks.add(
        PromptBlock.create(
          id: 'block',
          title: 'Block',
          content: 'artist:a, artist:b',
        ),
      );
      pills.values[PillScopes.main] = const PillDocument(
        text: '\uE000',
        instances: {
          '\uE000': PillInstance(
            blockId: 'block',
            settings: PillInstanceSettings(mode: PillRollMode.random),
            evolutionEnabled: true,
            currentRoll: 'artist:a',
          ),
        },
      );
      final container = await mount(tester);
      actions(tester).onOpenVariable(0);
      await tester.pumpAndSettle();
      final card = tester.widget<BlockInstanceCard>(
        find.byType(BlockInstanceCard),
      );
      expect(card.data.send, 'artist:a');
      card.actions.onSaveSettings(
        const BlockRollSettings(
          mode: BlockMode.sequential,
          countMin: 2,
          countMax: 2,
          weightEnabled: true,
          weightMin: .7,
          weightMax: 1.5,
          probability: .5,
        ),
      );
      await tester.pumpAndSettle();
      final current = container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document
          .instances['\uE000']!;
      expect(current.settings.mode, PillRollMode.sequential);
      expect(current.settings.countMax, 2);
      expect(current.settings.triggerProbability, .5);
      expect(platform.backups, hasLength(1));
      expect(
        container.exists(pillWorkspaceProvider(PillScopes.negative)),
        isFalse,
      );
    },
  );

  testWidgets(
    'ordinary variables keep row identity and genetic writes are backed up',
    (tester) async {
      library.blocks.addAll([
        PromptBlock.create(
          id: 'ordinary',
          title: 'Ordinary',
          content: 'artist:a, artist:b',
        ),
        PromptBlock.create(
          id: 'genetic',
          title: 'Genetic',
          content: 'artist:c, artist:d',
        ),
      ]);
      pills.values[PillScopes.main] = const PillDocument(
        text: '\ue001, \ue000',
        instances: {
          '\ue000': PillInstance(
            blockId: 'genetic',
            evolutionEnabled: true,
            currentRoll: 'artist:c',
            sequenceCursor: 1,
            settings: PillInstanceSettings(mode: PillRollMode.sequential),
          ),
          '\ue001': PillInstance(
            blockId: 'ordinary',
            currentRoll: 'artist:a',
            settings: PillInstanceSettings(mode: PillRollMode.random),
          ),
        },
      );
      final container = await mount(tester);
      final page = tester.widget<StyleExplorePage>(
        find.byType(StyleExplorePage),
      );
      expect(page.data.variables.map((v) => v.title), ['Ordinary', 'Genetic']);
      expect(page.data.variables.map((v) => v.evolution), [false, true]);
      actions(tester).onOpenVariable(0);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BlockInstanceCard>(find.byType(BlockInstanceCard))
            .data
            .block
            .title,
        'Ordinary',
      );
      await tester.tap(find.byKey(const Key('block-card-genetic')));
      await tester.pumpAndSettle();
      final after = container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document;
      expect(after.instances['\ue001']!.evolutionEnabled, isTrue);
      expect(after.instances['\ue001']!.currentRoll, 'artist:a');
      expect(after.instances['\ue000']!.sequenceCursor, 1);
      expect(platform.backups, hasLength(1));
      expect(
        tester
            .widget<StyleExplorePage>(find.byType(StyleExplorePage))
            .data
            .variables
            .every((v) => v.evolution),
        isTrue,
      );
      Navigator.of(tester.element(find.byType(BlockInstanceCard))).pop();
      await tester.pumpAndSettle();
      actions(tester).onOpenVariable(1);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BlockInstanceCard>(find.byType(BlockInstanceCard))
            .data
            .block
            .title,
        'Genetic',
      );
      await tester.tap(find.byKey(const Key('block-card-mode-fixed')));
      await tester.pumpAndSettle();
      final before = container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document;
      final backups = platform.backups.length;
      final control = tester.widget<Semantics>(
        find.byKey(const Key('block-card-genetic')),
      );
      expect(control.properties.enabled, isFalse);
      tester
          .widget<BlockInstanceCard>(find.byType(BlockInstanceCard))
          .actions
          .onEvolutionChanged!(false);
      await tester.pumpAndSettle();
      expect(
        container.read(pillWorkspaceProvider(PillScopes.main)).document,
        before,
      );
      expect(platform.backups.length, backups);
      expect(controls.calls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'evolution callbacks create, compare, generate, rename and delete the explicit line',
    (tester) async {
      await mount(tester);
      actions(tester).onStartEvolution(
        const ExploreEvolutionPlan(
          candidateKeys: [],
          newLineName: 'Line',
          customParents: ['artist:x', 'artist:y'],
          generate: 2,
        ),
      );
      await tester.pumpAndSettle();
      final family = storage.runs['first']!.families.single;
      final parentSet = storage.runs['first']!.parentSetById(
        family.activeParentSetId,
      )!;
      expect(runner.calls, ['children:first:${family.id}:${parentSet.id}:2']);
      actions(tester).onCompare(
        family.id,
        parentSet.parents[0].id,
        parentSet.parents[1].id,
        ExploreCompareResult.left,
      );
      await tester.pumpAndSettle();
      expect(
        storage.runs['first']!.parentSetById(parentSet.id)!.comparisons,
        hasLength(1),
      );
      expect(
        storage.runs['first']!
            .parentSetById(parentSet.id)!
            .parents[0]
            .preference,
        parentSet.parents[0].preference + 1,
      );
      actions(tester).onGenerateChildren(family.id, 4);
      await tester.pumpAndSettle();
      expect(
        runner.calls.last,
        'children:first:${family.id}:${parentSet.id}:4',
      );
      actions(tester).onRenameLine(family.id, 'New line');
      await tester.pumpAndSettle();
      expect(storage.runs['first']!.families.single.name, 'New line');
      actions(tester).onDeleteLine(family.id);
      await tester.pumpAndSettle();
      expect(storage.runs['first']!.families, isEmpty);
    },
  );

  testWidgets('stale pause actions do not pause a different generation run', (
    tester,
  ) async {
    await mount(tester);
    runner.configure(
      const ExploreRunRunnerState(runId: 'first', isRunning: true),
    );
    await tester.pump();
    final old = actions(tester);
    runner.configure(
      const ExploreRunRunnerState(runId: 'second', isRunning: true),
    );
    await tester.pump();
    old.onPause();
    expect(runner.pauseCalls, 0);
    actions(tester).onOpenRun('second');
    await tester.pump();
    actions(tester).onPause();
    expect(runner.pauseCalls, 1);
  });

  testWidgets(
    'fullscreen enters and restores physical and provider state on disposal',
    (tester) async {
      final container = await mount(tester);
      actions(tester).onFullscreenChanged(true);
      await tester.pumpAndSettle();
      expect(platform.fullscreen, isTrue);
      expect(container.read(styleExploreWindowProvider).fullscreen, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(platform.fullscreen, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
