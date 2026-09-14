import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_run_control_bar.dart';

/// 内存版 Run 存储：取消路径里的连续写若落真 Hive，会在 testWidgets 的
/// fakeAsync 区里死等（其内部计时器不触发），故改走纯内存实现。
class _MemoryRunStorage extends StyleExploreRunStorage {
  final Map<String, ExploreRun> _store = {};

  @override
  Future<List<ExploreRun>> getRuns() async => _store.values.toList();

  @override
  Future<ExploreRun?> getRun(String id) async => _store[id];

  @override
  Future<void> putRun(ExploreRun run) async {
    _store[run.id] = run;
  }

  @override
  Future<void> deleteRun(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}

/// 可手推运行态的 runner 替身：跳过恢复的微任务，仅记录 cancel 调用。
class _FakeRunner extends ExploreRunRunner {
  int cancelCalls = 0;

  @override
  ExploreRunRunnerState build() => const ExploreRunRunnerState();

  void setRunning({
    String? runId,
    bool isRunning = false,
    int processedCount = 0,
    int totalCount = 0,
  }) {
    state = ExploreRunRunnerState(
      runId: runId,
      isRunning: isRunning,
      processedCount: processedCount,
      totalCount: totalCount,
    );
  }

  @override
  void cancel() {
    cancelCalls++;
    state = const ExploreRunRunnerState();
  }
}

void main() {
  late Directory hiveDirectory;
  late StyleExploreRunStorage runStorage;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'explore_control_bar_test_',
    );
    Hive.init(hiveDirectory.path);
    runStorage = StyleExploreRunStorage();
    await runStorage.init();
  });

  setUp(() async {
    await runStorage.clear();
  });

  tearDownAll(() async {
    await runStorage.close();
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  ExploreRun draftRun() => ExploreRun.create(
    name: '探索1',
    recipeSnapshot: const ExploreRecipeSnapshot(
      positive: PillDocument(text: 'pos', instances: {}),
      negative: PillDocument(text: 'neg', instances: {}),
    ),
    paramsSnapshot: const ExploreParamsSnapshot(
      model: 'm',
      width: 832,
      height: 1216,
      steps: 28,
      scale: 5,
      sampler: 's',
      seed: -1,
      ucPreset: 0,
      qualityToggle: true,
      smea: false,
      smeaDyn: false,
      cfgRescale: 0,
      noiseSchedule: 'n',
      varietyPlus: false,
      decrisp: false,
    ),
    targetCount: 10,
  );

  testWidgets('基础轮入口不在 Run 控制条重复显示', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(body: ExploreRunControlBar(run: draftRun())),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('explore-run-target-count')), findsNothing);
    expect(find.byKey(const Key('explore-run-start')), findsNothing);
    expect(find.text('共 0 张'), findsOneWidget);
    expect(find.byKey(const Key('explore-run-actions')), findsOneWidget);
  });

  testWidgets('窄宽 Run 控制条会换行且不溢出', (tester) async {
    tester.view.physicalSize = const Size(300, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final run = draftRun().copyWith(
      status: ExploreRunStatus.generated,
      candidates: [
        ExploreCandidate.shell(roundId: 'r-1', id: 'failed').copyWith(
          generation: const ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.failed,
            error: 'boom',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(body: ExploreRunControlBar(run: run)),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('explore-run-control-bar-content')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('explore-run-retry')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Widget barHost(
    ExploreRun run,
    _FakeRunner fake, {
    StyleExploreRunStorage? storage,
  }) {
    return ProviderScope(
      overrides: [
        styleExploreRunStorageProvider.overrideWithValue(storage ?? runStorage),
        exploreRunRunnerProvider.overrideWith(() => fake),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: ExploreRunControlBar(run: run)),
      ),
    );
  }

  testWidgets('runner claim 窗口 totalCount=0 回退候选总数、不抛 clamp 异常', (
    tester,
  ) async {
    final fake = _FakeRunner();
    final run = draftRun().copyWith(
      status: ExploreRunStatus.generating,
      candidates: [
        ExploreCandidate.shell(roundId: 'r-1', id: 'c-1'),
        ExploreCandidate.shell(roundId: 'r-1', id: 'c-2'),
      ],
    );
    await tester.pumpWidget(barHost(run, fake));
    await tester.pump();

    // claim 已持有 session（isRunning）但 prepare 未写入 totalCount。
    fake.setRunning(runId: run.id, isRunning: true);
    await tester.pump();

    expect(find.text('共 2 张'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('暂停 run 的取消只终态化本 run，不取消其他 run 的 runner', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('zh'));
    final fake = _FakeRunner();
    final createdAt = DateTime.utc(2026, 9, 1);
    final run = draftRun().copyWith(
      status: ExploreRunStatus.paused,
      candidates: [
        ExploreCandidate.shell(roundId: 'r-1', id: 'c-1'),
        ExploreCandidate.shell(roundId: 'r-1', id: 'c-2'),
        ExploreCandidate.shell(roundId: 'r-1', id: 'c-3').copyWith(
          generation: const ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.done,
          ),
        ),
      ],
      rounds: [
        ExploreRound(
          id: 'r-1',
          number: 1,
          phase: ExploreRoundPhase.deep,
          status: ExploreRoundStatus.generating,
          createdAt: createdAt,
          targetCount: 3,
          candidateIds: const ['c-1', 'c-2', 'c-3'],
        ),
        ExploreRound(
          id: 'r-2',
          number: 2,
          phase: ExploreRoundPhase.deep,
          status: ExploreRoundStatus.pending,
          createdAt: createdAt,
          targetCount: 2,
        ),
      ],
    );
    final memoryStorage = _MemoryRunStorage();
    await memoryStorage.putRun(run);
    await tester.pumpWidget(barHost(run, fake, storage: memoryStorage));
    await tester.pump();

    // 另一个 run 的 runner 正在跑：本 run 的取消不得误伤它。
    fake.setRunning(runId: 'other-run', isRunning: true);
    await tester.pump();

    await tester.tap(find.byKey(const Key('explore-run-cancel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.styleExplore_cancelRun),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fake.cancelCalls, 0);
    final stored = (await memoryStorage.getRun(run.id))!;
    expect(stored.status, ExploreRunStatus.cancelled);
    // pending 候选标 failed(cancelled)，done 不动。
    expect(
      stored.candidates
          .where(
            (candidate) =>
                candidate.generation.status ==
                ExploreCandidateGenerationStatus.failed,
          )
          .map((candidate) => candidate.id),
      unorderedEquals(<String>['c-1', 'c-2']),
    );
    // generating 与 pending 轮次一并终态化。
    expect(stored.roundById('r-1')!.status, ExploreRoundStatus.cancelled);
    expect(stored.roundById('r-2')!.status, ExploreRoundStatus.cancelled);
  });
}
