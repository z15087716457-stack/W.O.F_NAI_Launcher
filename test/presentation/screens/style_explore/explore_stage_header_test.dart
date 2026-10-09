import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_manual_capture.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_stage_header.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

class _MemoryRuns extends StyleExploreRunStorage {
  final runs = <String, ExploreRun>{};
  @override
  Future<List<ExploreRun>> getRuns() async => runs.values.toList();
  @override
  Future<ExploreRun?> getRun(String id) async => runs[id];
  @override
  Future<void> putRun(ExploreRun run, {void Function()? beforeWrite}) async {
    beforeWrite?.call();
    runs[run.id] = run;
  }

  @override
  ExploreRun? currentRun(String id) => runs[id];

  @override
  Future<ExploreRun> transformRun(
    String id,
    ExploreRun Function(ExploreRun) update,
  ) async {
    final next = update(runs[id]!);
    runs[id] = next;
    return next;
  }

  @override
  Future<void> deleteRun(String id) async {
    runs.remove(id);
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

class _Runner extends ExploreRunRunner {
  int cancelCalls = 0, pauseCalls = 0;
  String? started;
  @override
  ExploreRunRunnerState build() => const ExploreRunRunnerState();
  void set(ExploreRunRunnerState value) {
    state = value;
  }

  @override
  void pause() {
    pauseCalls++;
  }

  @override
  void cancel() {
    cancelCalls++;
  }

  @override
  Future<bool> start(
    String runId, {
    void Function(ImageParams)? beforeGenerate,
  }) async {
    started = runId;
    return true;
  }
}

class _Capture extends ExploreManualCaptureNotifier {
  @override
  ExploreManualCaptureState build() => const ExploreManualCaptureState();
  void set(ExploreManualCaptureState value) {
    state = value;
  }
}

class _Generation extends ImageGenerationNotifier {
  int cancelCalls = 0;
  @override
  ImageGenerationState build() => const ImageGenerationState();
  void set(ImageGenerationState value) {
    state = value;
  }

  @override
  void cancel() {
    cancelCalls++;
  }
}

ExploreRun _run(
  String name, {
  ExploreRunStatus status = ExploreRunStatus.draft,
  List<ExploreCandidate> candidates = const [],
}) => ExploreRun.create(
  name: name,
  recipeSnapshot: const ExploreRecipeSnapshot(
    positive: PillDocument(text: 'pos', instances: {}),
    negative: PillDocument(text: 'neg', instances: {}),
  ),
  paramsSnapshot: const ExploreParamsSnapshot(
    model: 'nai-diffusion-4-5-full',
    width: 832,
    height: 1216,
    steps: 28,
    scale: 5,
    sampler: 'k_euler_ancestral',
    seed: -1,
    ucPreset: 0,
    qualityToggle: true,
    smea: false,
    smeaDyn: false,
    cfgRescale: 0,
    noiseSchedule: 'karras',
    varietyPlus: false,
    decrisp: false,
  ),
  targetCount: 10,
).copyWith(status: status, candidates: candidates);

void main() {
  late _MemoryRuns storage;
  late _Runner runner;
  late _Capture capture;
  late _Generation generation;
  final windowCalls = <String>[];
  setUp(() {
    storage = _MemoryRuns();
    runner = _Runner();
    capture = _Capture();
    generation = _Generation();
    windowCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), (
          call,
        ) async {
          windowCalls.add(call.method);
          return call.method == 'isMaximized' || call.method == 'isFullScreen'
              ? false
              : null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), null);
  });

  Future<ProviderContainer> pump(
    WidgetTester tester,
    ExploreRun run, {
    double width = 900,
    Locale locale = const Locale('zh'),
    List<ExploreRun> others = const [],
    bool desktopChrome = false,
  }) async {
    await storage.putRun(run);
    for (final other in others) {
      await storage.putRun(other);
    }
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => _Settings()),
          styleExploreRunStorageProvider.overrideWithValue(storage),
          exploreRunRunnerProvider.overrideWith(() => runner),
          exploreManualCaptureProvider.overrideWith(() => capture),
          imageGenerationNotifierProvider.overrideWith(() => generation),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WindowChromeScope(
            enabled: desktopChrome,
            child: const Scaffold(
              body: Column(
                children: [ExploreStageHeader(inspectorVisible: true)],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> confirmCancel(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('explore-run-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('取消任务'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, '取消任务'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'blank header drags the native window without stealing controls',
    (tester) async {
      await pump(tester, _run('探索'), desktopChrome: true);
      final drag = find.byKey(const Key('explore-header-blank-drag'));
      expect(tester.getSize(drag).width, greaterThan(100));
      await tester.drag(drag, const Offset(80, 0));
      await tester.pumpAndSettle();
      expect(windowCalls, contains('startDragging'));
      windowCalls.clear();
    await tester.tap(find.byKey(const Key('explore-run-switcher-button')));
      await tester.pumpAndSettle();
    expect(find.byKey(const Key('explore-run-switcher-menu')), findsOneWidget);
      expect(windowCalls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('runner zero total claim window has safe progress and controls', (
    tester,
  ) async {
    final run = _run(
      '探索1',
      candidates: [
        ExploreCandidate.shell(roundId: 'r', id: 'c1'),
        ExploreCandidate.shell(roundId: 'r', id: 'c2'),
      ],
    );
    await pump(tester, run, width: 480);
    runner.set(ExploreRunRunnerState(runId: run.id, isRunning: true));
    await tester.pump();
    expect(find.text('第 1 轮 · 生成中'), findsOneWidget);
    expect(find.byKey(const Key('explore-run-pause')), findsOneWidget);
    expect(find.byKey(const Key('explore-run-cancel')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.tap(find.byKey(const Key('explore-run-pause')));
    expect(runner.pauseCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('runner progress uses processed plus one and caps at total', (
    tester,
  ) async {
    final run = _run('探索1');
    await pump(tester, run);
    runner.set(
      ExploreRunRunnerState(
        runId: run.id,
        isRunning: true,
        processedCount: 99,
        totalCount: 12,
      ),
    );
    await tester.pump();
    expect(find.text('第 1 轮 · 12 / 12'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1,
    );
    await confirmCancel(tester);
    expect(runner.cancelCalls, 1);
    expect(generation.cancelCalls, 0);
  });

  testWidgets(
    'manual capture uses main progress and offers stop without pause',
    (tester) async {
      final run = _run('手动探索');
      await pump(tester, run);
      capture.set(ExploreManualCaptureState(armed: true, runId: run.id));
      generation.set(
        const ImageGenerationState(
          status: GenerationStatus.generating,
          currentImage: 3,
          totalImages: 10,
        ),
      );
      await tester.pump();
      expect(find.text('第 1 轮 · 3 / 10'), findsOneWidget);
      expect(find.byKey(const Key('explore-run-pause')), findsNothing);
      expect(find.byKey(const Key('explore-run-cancel')), findsOneWidget);
      await confirmCancel(tester);
      expect(generation.cancelCalls, 1);
      expect(runner.cancelCalls, 0);
    },
  );

  testWidgets(
    'paused run continues through runner and cancellation leaves another session alone',
    (tester) async {
      final now = DateTime.now();
      final run =
          _run(
            '暂停探索',
            status: ExploreRunStatus.paused,
            candidates: [
              ExploreCandidate.shell(roundId: 'r-1', id: 'c1'),
              ExploreCandidate.shell(roundId: 'r-1', id: 'c2'),
              ExploreCandidate.shell(roundId: 'r-1', id: 'done').copyWith(
                generation: const ExploreCandidateGeneration(
                  status: ExploreCandidateGenerationStatus.done,
                ),
              ),
            ],
          ).copyWith(
            rounds: [
              ExploreRound(
                id: 'r-1',
                number: 1,
                phase: ExploreRoundPhase.deep,
                status: ExploreRoundStatus.generating,
                createdAt: now,
                targetCount: 3,
              ),
              ExploreRound(
                id: 'r-2',
                number: 2,
                phase: ExploreRoundPhase.deep,
                status: ExploreRoundStatus.pending,
                createdAt: now,
                targetCount: 2,
              ),
            ],
          );
      await pump(tester, run);
      runner.set(const ExploreRunRunnerState(runId: 'other', isRunning: true));
      await tester.pump();
      expect(find.text('已暂停 · 剩 2 张'), findsOneWidget);
      await tester.tap(find.byKey(const Key('explore-run-resume')));
      await tester.pump();
      expect(runner.started, run.id);
      await confirmCancel(tester);
      expect(runner.cancelCalls, 0);
      final stored = (await storage.getRun(run.id))!;
      expect(stored.status, ExploreRunStatus.cancelled);
      expect(
        stored.candidates
            .where((c) => c.generation.error == 'cancelled')
            .map((c) => c.id),
        unorderedEquals(['c1', 'c2']),
      );
      expect(
        stored.candidates.last.generation.status,
        ExploreCandidateGenerationStatus.done,
      );
      expect(
        stored.rounds.every((r) => r.status == ExploreRoundStatus.cancelled),
        true,
      );
    },
  );

  testWidgets(
    'confirmation cancellation reads fresh run rather than replacing resumed state',
    (tester) async {
      final run = _run('暂停探索', status: ExploreRunStatus.paused);
      final container = await pump(tester, run);
      await tester.tap(find.byKey(const Key('explore-run-cancel')));
      await tester.pumpAndSettle();
      await container
          .read(exploreRunListNotifierProvider.notifier)
          .overwrite(
            run.copyWith(status: ExploreRunStatus.generated, name: '另一个更新'),
          );
      await tester.tap(find.widgetWithText(FilledButton, '取消任务'));
      await tester.pumpAndSettle();
      expect(
        (await storage.getRun(run.id))!.status,
        ExploreRunStatus.generated,
      );
      expect((await storage.getRun(run.id))!.name, '另一个更新');
    },
  );

  testWidgets(
    'switching run during generation changes view only and artist search is local',
    (tester) async {
      final run = _run('正在跑');
      final other = _run(
        '另一个探索',
        candidates: [
          ExploreCandidate.shell(roundId: 'r', id: 'c').copyWith(
            rollSnapshot: const ExploreRollSnapshot(
              positive: '',
              negative: '',
              instanceRolls: [
                ExploreInstanceRoll(
                  lane: 'pos',
                  marker: '\uE000',
                  blockId: 'b',
                  blockTitle: '画师池',
                  rolledText: 'Artist:DORemi',
                ),
              ],
            ),
          ),
        ],
      );
      final container = await pump(tester, run, others: [other]);
      runner.set(
        ExploreRunRunnerState(
          runId: run.id,
          isRunning: true,
          processedCount: 8,
          totalCount: 12,
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('explore-run-switcher-button')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('explore-run-search')),
        'doremi',
      );
      await tester.pump();
      expect(find.byKey(ValueKey('explore-run-${run.id}')), findsNothing);
      expect(find.byKey(ValueKey('explore-run-${other.id}')), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('explore-run-${other.id}')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(container.read(exploreActiveRunIdProvider), other.id);
      expect(runner.cancelCalls, 0);
      expect(runner.pauseCalls, 0);
      expect(container.read(exploreRunRunnerProvider).runId, run.id);
      expect(find.byKey(const Key('explore-stage-progress')), findsNothing);
      expect(find.byKey(const Key('explore-run-switcher-menu')), findsNothing);
    },
  );

  testWidgets(
    'double click inline name supports Escape and Enter; menu rename and delete retained',
    (tester) async {
      final run = _run('当前探索'), other = _run('其他探索');
      final container = await pump(tester, run, others: [other]);
      await tester.tap(find.byKey(const Key('explore-run-switcher-button')));
      await tester.pumpAndSettle();
      final row = find.descendant(
        of: find.byKey(ValueKey('explore-run-${run.id}')),
        matching: find.text(run.name),
      );
      await tester.tap(row);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explore-run-inline-name')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('explore-run-inline-name')),
        '不保存',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(container.read(exploreActiveRunProvider)!.name, '当前探索');
      await tester.tap(find.byKey(ValueKey('explore-run-menu-${other.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('重命名'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      final field = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, '改过的探索');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '确定'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(exploreRunListNotifierProvider)
            .requireValue
            .runById(other.id)!
            .name,
        '改过的探索',
      );
      await tester.tap(find.byKey(ValueKey('explore-run-menu-${other.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '删除'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(exploreRunListNotifierProvider)
            .requireValue
            .runById(other.id),
        isNull,
      );
      expect(container.read(exploreActiveRunIdProvider), run.id);
    },
  );

  testWidgets(
    'status badges are limited to generating, paused, failed and cancelled',
    (tester) async {
      final runs = [
        for (final status in ExploreRunStatus.values)
          _run(status.name, status: status),
        _run(
          'failed',
          candidates: [
            ExploreCandidate.shell(roundId: 'r', id: 'bad').copyWith(
              generation: const ExploreCandidateGeneration(
                status: ExploreCandidateGenerationStatus.failed,
              ),
            ),
          ],
        ),
      ];
      await pump(tester, runs.first, others: runs.skip(1).toList());
      await tester.tap(find.byKey(const Key('explore-run-switcher-button')));
      await tester.pumpAndSettle();
      for (final run in runs) {
        final visible =
            [
              ExploreRunStatus.generating,
              ExploreRunStatus.paused,
              ExploreRunStatus.cancelled,
            ].contains(run.status) ||
            run.failedCount > 0;
        expect(
          find.byKey(ValueKey('explore-run-status-${run.id}')),
          visible ? findsOneWidget : findsNothing,
        );
      }
      expect(
        tester
            .getSize(find.byKey(const Key('explore-run-switcher-menu')))
            .width,
        420,
      );
      expect(
        tester
            .getSize(find.byKey(const Key('explore-run-switcher-menu')))
            .height,
        lessThanOrEqualTo(630),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in ['zh', 'en', 'ja', 'ko']) {
    testWidgets('long name and progress fit a 480 stage in $locale', (
      tester,
    ) async {
      final run = _run(
        '非常长的探索名称 · Long exploration title repeated ${'abc ' * 20}',
        candidates: [ExploreCandidate.shell(roundId: 'r', id: 'c')],
      );
      await pump(tester, run, width: 480, locale: Locale(locale));
      runner.set(
        ExploreRunRunnerState(
          runId: run.id,
          isRunning: true,
          processedCount: 8,
          totalCount: 12,
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('explore-run-pause')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
