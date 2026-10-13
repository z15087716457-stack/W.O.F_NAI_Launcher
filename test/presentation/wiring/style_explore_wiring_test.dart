import 'dart:async';

import 'package:flutter/material.dart';
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
  late _Runs storage;
  late _Settings settings;
  late _Pills pills;
  late _Runner runner;
  late _Platform platform;
  late _Controls controls;
  late _Library library;
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
  });

  Future<ProviderContainer> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
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
        ],
        child: MaterialApp(
          theme: GeistTheme.light,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StyleExploreWiring(
            generationController: controls,
            editor: (context, parts) => Column(
              children: [
                parts.randomVariables,
                const Spacer(),
                parts.generateBar,
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StyleExploreWiring)),
    );
    container.read(exploreActiveRunIdProvider.notifier).state = 'first';
    await tester.pumpAndSettle();
    return container;
  }

  ExploreActions actions(WidgetTester tester) =>
      tester.widget<StyleExplorePage>(find.byType(StyleExplorePage)).actions;

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
