import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/services/explore_run_image_store.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_models.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';

/// 循环推进的确定性 Random：nextInt 依调用序轮换，保证逐张 roll 出不同原子。
class _CyclicRandom implements Random {
  int _counter = 0;

  @override
  int nextInt(int max) => (_counter++) % max;

  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => true;
}

class _FakeLibraryNotifier extends PromptBlockLibraryNotifier {
  _FakeLibraryNotifier(this.blocks);

  final List<PromptBlock> blocks;

  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: blocks, folders: const []);
}

void main() {
  late Directory hiveDirectory;
  late Directory imageDirectory;
  late StyleExploreRunStorage runStorage;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'explore_runner_hive_',
    );
    imageDirectory = await Directory.systemTemp.createTemp(
      'explore_runner_img_',
    );
    Hive.init(hiveDirectory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox<String>(StorageKeys.promptWorkspaceStateBox);
    runStorage = StyleExploreRunStorage();
    await runStorage.init();
  });

  setUp(() async {
    await runStorage.clear();
    await Hive.box(StorageKeys.settingsBox).clear();
    await Hive.box<String>(StorageKeys.promptWorkspaceStateBox).clear();
    PillWorkspaceNotifier.rng = Random();
  });

  tearDownAll(() async {
    await runStorage.close();
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
    if (await imageDirectory.exists()) {
      await imageDirectory.delete(recursive: true);
    }
  });

  ExploreParamsSnapshot testSnapshot() => const ExploreParamsSnapshot(
    model: 'nai-diffusion-4-5-full',
    width: 832,
    height: 1216,
    steps: 28,
    scale: 5.5,
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
  );

  Future<ExploreRun> seedRun({String name = '测试任务', int targetCount = 3}) {
    final run = ExploreRun.create(
      name: name,
      recipeSnapshot: ExploreRecipeSnapshot(
        positive: PillDocument.empty(),
        negative: PillDocument.empty(),
      ),
      paramsSnapshot: testSnapshot(),
      targetCount: targetCount,
    );
    return runStorage.putRun(run).then((_) => run);
  }

  ProviderContainer container({
    required ExploreGenerateFn generateFn,
    List<PromptBlock> blocks = const [],
    List<Override> overrides = const [],
  }) {
    final c = ProviderContainer(
      overrides: [
        styleExploreRunStorageProvider.overrideWithValue(runStorage),
        exploreGenerateFnProvider.overrideWithValue(generateFn),
        exploreRunImageStoreProvider.overrideWithValue(
          ExploreRunImageStore(
            rootPathResolver: () async => imageDirectory.path,
          ),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakeLibraryNotifier(blocks),
        ),
        ...overrides,
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  ExploreGenerationResult okResult(int seed) => ExploreGenerationResult(
    imageBytes: Uint8List.fromList([1, 2, 3, seed & 0xFF]),
    seed: seed,
    elapsedMs: 7,
    imageWidth: 832,
    imageHeight: 1216,
  );

  Future<ExploreRun> reload(ProviderContainer c, String runId) async {
    final state = await c.read(exploreRunListNotifierProvider.future);
    return state.runById(runId)!;
  }

  group('runner state machine', () {
    test('start generates all candidates and lands on generated', () async {
      final run = await seedRun(targetCount: 3);
      final sentParams = <ImageParams>[];
      var seed = 100;
      final c = container(
        generateFn: (params) async {
          sentParams.add(params);
          return okResult(seed += 1);
        },
      );
      // 触发恢复微任务排空后再 start。
      c.read(exploreRunRunnerProvider);
      await Future<void>.delayed(Duration.zero);

      final started = await c
          .read(exploreRunRunnerProvider.notifier)
          .start(run.id);
      expect(started, isTrue);

      final after = await reload(c, run.id);
      expect(after.status, ExploreRunStatus.generated);
      expect(after.generatedCount, 3);
      expect(after.rounds.single.status, ExploreRoundStatus.generated);
      expect(after.rounds.single.candidateIds, hasLength(3));
      expect(c.read(exploreRunRunnerProvider).isRunning, isFalse);

      for (final candidate in after.candidates) {
        expect(
          candidate.generation.status,
          ExploreCandidateGenerationStatus.done,
        );
        expect(candidate.generation.seed, greaterThan(100));
        expect(candidate.generation.filePath, isNotNull);
        expect(candidate.rollSnapshot, isNotNull);
        // 副本真实落盘且内容自包含（路径分隔符随平台）。
        final file = File(candidate.generation.filePath!);
        expect(await file.exists(), isTrue);
        expect(
          file.path,
          contains(
            '${ExploreRunImageStore.runsDirectoryName}'
            '${Platform.pathSeparator}${run.id}',
          ),
        );
      }

      // 每张独立随机种子 -1、单张、快照参数。
      for (final params in sentParams) {
        expect(params.nSamples, 1);
        expect(params.seed, -1);
        expect(params.model, testSnapshot().model);
        expect(params.steps, 28);
        expect(params.scale, 5.5);
      }
    });

    test('mid-run failure marks candidate failed and continues', () async {
      final run = await seedRun(targetCount: 3);
      var call = 0;
      final c = container(
        generateFn: (params) async {
          call += 1;
          return call == 2 ? null : okResult(call);
        },
      );
      c.read(exploreRunRunnerProvider);
      await Future<void>.delayed(Duration.zero);

      await c.read(exploreRunRunnerProvider.notifier).start(run.id);

      final after = await reload(c, run.id);
      expect(after.status, ExploreRunStatus.generated);
      expect(after.generatedCount, 2);
      expect(after.failedCount, 1);
      final failed = after.candidates[1];
      expect(failed.generation.status, ExploreCandidateGenerationStatus.failed);
      expect(failed.generation.error, isNotEmpty);
    });

    test('pause exits after current image; resume finishes the rest', () async {
      final run = await seedRun(targetCount: 3);
      var call = 0;
      final secondInFlight = Completer<void>();
      final allowSecondToFinish = Completer<void>();
      final c = container(
        generateFn: (params) async {
          call += 1;
          if (call == 2) {
            secondInFlight.complete();
            await allowSecondToFinish.future;
          }
          return okResult(call);
        },
      );
      c.read(exploreRunRunnerProvider);
      await Future<void>.delayed(Duration.zero);

      final runner = c.read(exploreRunRunnerProvider.notifier);
      final firstPass = runner.start(run.id);
      // 等第二张在途，请求暂停后放行。
      await secondInFlight.future;
      runner.pause();
      allowSecondToFinish.complete();
      expect(await firstPass, isTrue);

      var after = await reload(c, run.id);
      expect(after.status, ExploreRunStatus.paused);
      expect(after.generatedCount, 2);
      expect(after.pendingCandidates, hasLength(1));
      expect(
        after.rounds.single.status,
        ExploreRoundStatus.generating,
        reason: '暂停时轮次保持 generating 待续跑',
      );

      // 续跑：从 pending 继续，不新建轮次。
      final resumed = await runner.start(run.id);
      expect(resumed, isTrue);
      after = await reload(c, run.id);
      expect(after.status, ExploreRunStatus.generated);
      expect(after.generatedCount, 3);
      expect(after.rounds, hasLength(1));
    });

    test('cancel interrupts in-flight and marks remaining cancelled', () async {
      final run = await seedRun(targetCount: 3);
      var call = 0;
      final firstInFlight = Completer<void>();
      final release = Completer<void>();
      final c = container(
        generateFn: (params) async {
          call += 1;
          if (call == 1) {
            firstInFlight.complete();
            await release.future;
            return null; // 模拟被中断的在途请求
          }
          return okResult(call);
        },
      );
      c.read(exploreRunRunnerProvider);
      await Future<void>.delayed(Duration.zero);

      final runner = c.read(exploreRunRunnerProvider.notifier);
      final pass = runner.start(run.id);
      await firstInFlight.future;
      runner.cancel();
      release.complete();
      await pass;

      final after = await reload(c, run.id);
      expect(after.status, ExploreRunStatus.cancelled);
      expect(after.rounds.single.status, ExploreRoundStatus.cancelled);
      expect(after.generatedCount, 0);
      for (final candidate in after.candidates) {
        expect(
          candidate.generation.status,
          ExploreCandidateGenerationStatus.failed,
        );
        expect(candidate.generation.error, 'cancelled');
      }
      expect(c.read(exploreRunRunnerProvider).isRunning, isFalse);

      // 终态不可再启动。
      expect(await runner.start(run.id), isFalse);
    });

    test('retryFailed resets failed candidates and regenerates them', () async {
      final run = await seedRun(targetCount: 2);
      var call = 0;
      final c = container(
        generateFn: (params) async {
          call += 1;
          // 首轮：第二张失败；重试轮：全部成功。
          return call == 2 ? null : okResult(call);
        },
      );
      c.read(exploreRunRunnerProvider);
      await Future<void>.delayed(Duration.zero);

      final runner = c.read(exploreRunRunnerProvider.notifier);
      await runner.start(run.id);
      var after = await reload(c, run.id);
      expect(after.failedCount, 1);

      final retried = await runner.retryFailed(run.id);
      expect(retried, isTrue);
      after = await reload(c, run.id);
      expect(after.status, ExploreRunStatus.generated);
      expect(after.failedCount, 0);
      expect(after.generatedCount, 2);
      // 没有新建轮次。
      expect(after.rounds, hasLength(1));
    });

    test('reentrant start is rejected while running', () async {
      final run = await seedRun(targetCount: 2);
      final inFlight = Completer<void>();
      final release = Completer<void>();
      var call = 0;
      final c = container(
        generateFn: (params) async {
          call += 1;
          if (call == 1) {
            inFlight.complete();
            await release.future;
          }
          return okResult(call);
        },
      );
      c.read(exploreRunRunnerProvider);
      await Future<void>.delayed(Duration.zero);

      final runner = c.read(exploreRunRunnerProvider.notifier);
      final first = runner.start(run.id);
      await inFlight.future;

      expect(await runner.start(run.id), isFalse);
      expect(await runner.retryFailed(run.id), isFalse);

      release.complete();
      await first;
      expect((await reload(c, run.id)).status, ExploreRunStatus.generated);
    });

    test(
      'draft run with no active generation creates exactly one round',
      () async {
        final run = await seedRun(targetCount: 2);
        final c = container(generateFn: (params) async => okResult(1));
        c.read(exploreRunRunnerProvider);
        await Future<void>.delayed(Duration.zero);

        await c.read(exploreRunRunnerProvider.notifier).start(run.id);
        final after = await reload(c, run.id);
        expect(after.rounds, hasLength(1));
        expect(after.rounds.single.phase, ExploreRoundPhase.basic);
        expect(after.rounds.single.number, 1);

        // 已生成且无 pending 时再 start：新增第二轮。
        await c.read(exploreRunRunnerProvider.notifier).start(run.id);
        final second = await reload(c, run.id);
        expect(second.rounds, hasLength(2));
        expect(second.rounds.last.number, 2);
        expect(second.candidates, hasLength(4));
      },
    );
  });

  group('roll snapshot capture', () {
    test(
      'captures projections and per-instance rolls from explore lanes',
      () async {
        const marker = '';
        final block = PromptBlock(
          id: 'b-1',
          title: '画风池',
          content: 'alpha, beta, gamma',
          createdAt: DateTime.utc(2026, 8, 31),
          updatedAt: DateTime.utc(2026, 8, 31),
        );
        final run = await seedRun(targetCount: 3);
        final sentPrompts = <String>[];
        final c = container(
          blocks: [block],
          generateFn: (params) async {
            sentPrompts.add(params.prompt);
            return okResult(sentPrompts.length);
          },
        );
        c.read(exploreRunRunnerProvider);
        await Future<void>.delayed(Duration.zero);
        await c.read(promptBlockLibraryNotifierProvider.future);

        PillWorkspaceNotifier.rng = _CyclicRandom();
        c
            .read(pillWorkspaceProvider(PillScopes.explorePos).notifier)
            .restoreDocument(
              const PillDocument(
                text: 'base, ',
                instances: {
                  marker: PillInstance(
                    blockId: 'b-1',
                    settings: PillInstanceSettings(mode: PillRollMode.random),
                  ),
                },
              ),
            );
        c
            .read(pillWorkspaceProvider(PillScopes.exploreNeg).notifier)
            .restoreDocument(
              const PillDocument(text: 'neg base', instances: {}),
            );

        await c.read(exploreRunRunnerProvider.notifier).start(run.id);

        final after = await reload(c, run.id);
        expect(after.generatedCount, 3);
        final rolls = [
          for (final candidate in after.candidates)
            candidate.rollSnapshot!.instanceRolls.single,
        ];
        // 循环 rng：materialize 占 beta，之后三张依次 alpha/gamma/beta。
        expect(rolls.map((r) => r.rolledText), ['alpha', 'gamma', 'beta']);
        for (final roll in rolls) {
          expect(roll.lane, 'pos');
          expect(roll.marker, marker);
          expect(roll.blockId, 'b-1');
          expect(roll.blockTitle, '画风池');
        }
        // 快照投影 = 实际发送的提示词；负向无随机实例，快照为空实例表。
        for (var i = 0; i < 3; i++) {
          final snapshot = after.candidates[i].rollSnapshot!;
          expect(snapshot.positive, 'base, ${rolls[i].rolledText}');
          expect(snapshot.negative, 'neg base');
          expect(snapshot.instanceRolls, hasLength(1));
          expect(sentPrompts[i], snapshot.positive);
        }
      },
    );
  });

  group('interrupted run recovery', () {
    test(
      'generating runs left over are recovered to paused on build',
      () async {
        final run = await seedRun(targetCount: 2);
        await runStorage.putRun(
          run.copyWith(status: ExploreRunStatus.generating),
        );
        final c = container(generateFn: (params) async => okResult(1));

        // build 触发恢复微任务；轮询等恢复完成（Hive 读取有真实 I/O）。
        c.read(exploreRunRunnerProvider);
        var after = await reload(c, run.id);
        for (
          var i = 0;
          i < 50 && after.status == ExploreRunStatus.generating;
          i++
        ) {
          await Future<void>.delayed(Duration.zero);
          after = await reload(c, run.id);
        }
        expect(after.status, ExploreRunStatus.paused);
      },
    );
  });
}
