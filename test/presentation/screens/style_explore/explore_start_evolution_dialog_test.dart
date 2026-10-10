import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_view_state.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_start_evolution_dialog.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'explore_candidate_wall_test.dart' show wallFixture;
import 'explore_random_variables_module_test.dart'
    show variableFixtureDocument, variableFixtureLibrary;

class EvolutionDialogStorage extends StyleExploreRunStorage {
  EvolutionDialogStorage(this.run);
  ExploreRun run;
  @override
  Future<List<ExploreRun>> getRuns() async => [run];
  @override
  Future<ExploreRun?> getRun(String id) async => run.id == id ? run : null;
  @override
  Future<void> putRun(ExploreRun value, {void Function()? beforeWrite}) async {
    beforeWrite?.call();
    run = value;
  }
}

class EvolutionDialogWorkspace extends PillWorkspaceNotifier {
  EvolutionDialogWorkspace(this.target);
  final bool target;
  @override
  PillWorkspaceState build(String scope) => PillWorkspaceState(
    document: target && scope == PillScopes.main
        ? variableFixtureDocument(1)
        : PillDocument.empty(),
    projection: '',
  );
}

class EvolutionDialogBlocks extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async => variableFixtureLibrary();
}

class EvolutionDialogRunner extends ExploreRunRunner {
  EvolutionDialogRunner({this.accept = true});
  final bool accept;
  final calls =
      <({String runId, String familyId, String parentSetId, int count})>[];
  @override
  ExploreRunRunnerState build() => const ExploreRunRunnerState();
  @override
  Future<bool> startDeepRound(
    String runId, {
    required String familyId,
    required String parentSetId,
    required int count,
    void Function(ImageParams)? beforeGenerate,
  }) async {
    calls.add((
      runId: runId,
      familyId: familyId,
      parentSetId: parentSetId,
      count: count,
    ));
    return accept;
  }
}

Widget evolutionDialogApp(
  EvolutionDialogStorage storage,
  EvolutionDialogRunner runner, {
  bool target = true,
  String locale = 'zh',
  bool dark = false,
  bool compare = false,
  Widget? dialog,
}) => ProviderScope(
  overrides: [
    styleExploreRunStorageProvider.overrideWithValue(storage),
    exploreRunRunnerProvider.overrideWith(() => runner),
    promptBlockLibraryNotifierProvider.overrideWith(EvolutionDialogBlocks.new),
    pillWorkspaceProvider.overrideWith(() => EvolutionDialogWorkspace(target)),
    exploreActiveRunIdProvider.overrideWith((ref) => storage.run.id),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: (dark ? GeistTheme.dark : GeistTheme.light).copyWith(
      platform: TargetPlatform.windows,
    ),
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Consumer(
        builder: (context, ref, _) {
          ref.watch(exploreRunListNotifierProvider);
          ref.watch(promptBlockLibraryNotifierProvider);
          return Center(
            child: TextButton(
              key: const Key('open-evolution'),
              onPressed: () => dialog == null
                  ? ExploreStartEvolutionDialog.show(
                      context,
                      run: storage.run,
                      candidates: storage.run.candidates.take(4).toList(),
                    )
                  : showDialog<void>(context: context, builder: (_) => dialog),
              child: const Text('open'),
            ),
          );
        },
      ),
    ),
  ),
);

void main() {
  final l10n = lookupAppLocalizations(const Locale('zh'));
  Future<void> open(
    WidgetTester tester,
    EvolutionDialogStorage storage,
    EvolutionDialogRunner runner, {
    bool target = true,
  }) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      evolutionDialogApp(storage, runner, target: target),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-evolution')));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  ExploreRun lineRun({bool pending = false}) {
    final base = wallFixture(count: 4),
        set = const ExploreParentSet(
          id: 'set',
          familyId: 'line',
          generation: 2,
          status: ExploreParentSetStatus.active,
          parents: [
            ExploreParent(id: 'old', artistString: 'artist:old', preference: 2),
          ],
        );
    return base.copyWith(
      families: [
        ExploreFamily(
          id: 'line',
          name: '冷色支线',
          createdAt: base.createdAt,
          rootParentSetId: set.id,
          activeParentSetId: set.id,
        ),
      ],
      parentSets: [set],
      rounds: pending
          ? [
              base.rounds.first.copyWith(
                parentSetId: set.id,
                phase: ExploreRoundPhase.deep,
                status: ExploreRoundStatus.generating,
              ),
            ]
          : base.rounds,
    );
  }

  testWidgets(
    'create only localizes the name, deduplicates parents and changes tab',
    (tester) async {
      final base = wallFixture(count: 4);
      final empty = base.candidates.last.copyWith(
        rollSnapshot: const ExploreRollSnapshot(positive: '', negative: ''),
      );
      final storage = EvolutionDialogStorage(
        base.copyWith(
          candidates: [
            base.candidates.first,
            base.candidates.first.copyWith(id: 'copy'),
            base.candidates[2].copyWith(
              rollSnapshot: const ExploreRollSnapshot(
                positive: 'artist:unique',
                negative: '',
              ),
            ),
            empty,
          ],
        ),
      );
      await open(tester, storage, EvolutionDialogRunner());
      expect(find.text(l10n.styleExplore_evolutionParentEmpty), findsOneWidget);
      expect(
        find.byKey(const Key('explore-evolution-mode-join')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const Key('explore-family-name')),
        '   ',
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
      );
      await submit(tester, 'explore-evolution-only-create');
      expect(
        storage.run.families.single.name,
        l10n.styleExplore_defaultEvolutionName(1),
      );
      expect(storage.run.parentSets.single.parents, hasLength(2));
      expect(
        container.read(exploreActiveFamilyIdProvider),
        storage.run.families.single.id,
      );
      expect(
        container.read(exploreStageTabProvider),
        ExploreStageTab.evolution,
      );
      await tester.pump(const Duration(seconds: 4));
    },
  );
  testWidgets('remove, custom parents, generation parameters and lower bound', (
    tester,
  ) async {
    final storage = EvolutionDialogStorage(wallFixture(count: 4)),
        runner = EvolutionDialogRunner();
    await open(tester, storage, runner);
    await tester.tap(find.byKey(const Key('explore-evolution-remove-c1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('explore-evolution-parent-c1')), findsNothing);
    await tester.ensureVisible(
      find.byKey(const Key('explore-add-custom-parent')),
    );
    await tester.tap(find.byKey(const Key('explore-add-custom-parent')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('explore-custom-parent-0')),
      ' artist:custom ',
    );
    await tester.enterText(
      find.byKey(const Key('explore-evolution-count')),
      '0',
    );
    await submit(tester, 'explore-evolution-create-generate');
    final set = storage.run.parentSets.single;
    expect(set.parents.last.artistString, 'artist:custom');
    expect(runner.calls.single, (
      runId: storage.run.id,
      familyId: storage.run.families.single.id,
      parentSetId: set.id,
      count: set.parents.length,
    ));
    await tester.pump(const Duration(seconds: 4));
  });
  testWidgets(
    'join appends to current generation and generates from that set',
    (tester) async {
      final storage = EvolutionDialogStorage(lineRun()),
          runner = EvolutionDialogRunner();
      await open(tester, storage, runner);
      await tester.tap(find.byKey(const Key('explore-evolution-mode-join')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explore-family-name')), findsNothing);
      await submit(tester, 'explore-evolution-create-generate');
      expect(storage.run.families, hasLength(1));
      expect(storage.run.parentSets.single.parents.first.preference, 2);
      expect(storage.run.parentSets.single.parents.length, greaterThan(1));
      expect(runner.calls.single.parentSetId, 'set');
      expect(
        runner.calls.single.count,
        storage.run.parentSets.single.parents.length + 1,
      );
      await tester.pump(const Duration(seconds: 4));
    },
  );
  testWidgets(
    'join refuses an in-flight generation without creating a new line',
    (tester) async {
      final storage = EvolutionDialogStorage(lineRun(pending: true)),
          runner = EvolutionDialogRunner();
      await open(tester, storage, runner);
      await tester.tap(find.byKey(const Key('explore-evolution-mode-join')));
      await tester.pumpAndSettle();
      await submit(tester, 'explore-evolution-only-create');
      expect(storage.run.parentSets.single.parents, hasLength(1));
      expect(find.text(l10n.styleExplore_generationBusy), findsWidgets);
      expect(runner.calls, isEmpty);
      await tester.pump(const Duration(seconds: 4));
    },
  );
  testWidgets('missing evolution target disables both submit actions', (
    tester,
  ) async {
    await open(
      tester,
      EvolutionDialogStorage(wallFixture(count: 4)),
      EvolutionDialogRunner(),
      target: false,
    );
    expect(
      tester
          .widget<ExploreButton>(
            find.byKey(const Key('explore-evolution-only-create')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<ExploreButton>(
            find.byKey(const Key('explore-evolution-create-generate')),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets('runner busy preserves the created line and informs caller', (
    tester,
  ) async {
    final storage = EvolutionDialogStorage(wallFixture(count: 4));
    await open(tester, storage, EvolutionDialogRunner(accept: false));
    await submit(tester, 'explore-evolution-create-generate');
    expect(storage.run.families, hasLength(1));
    expect(
      find.byKey(const Key('explore-start-evolution-dialog')),
      findsNothing,
    );
    expect(find.text(l10n.styleExplore_runBusy), findsWidgets);
    await tester.pump(const Duration(seconds: 4));
  });
}
