import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/services/explore_run_image_store.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_models.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_manual_capture.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';

class _FakeLibraryNotifier extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: const [], folders: const []);
}

void main() {
  late Directory hiveDirectory;
  late Directory imageDirectory;
  late StyleExploreRunStorage runStorage;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'explore_manual_capture_hive_',
    );
    imageDirectory = await Directory.systemTemp.createTemp(
      'explore_manual_capture_img_',
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

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        styleExploreRunStorageProvider.overrideWithValue(runStorage),
        exploreRunImageStoreProvider.overrideWithValue(
          ExploreRunImageStore(
            rootPathResolver: () async => imageDirectory.path,
          ),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakeLibraryNotifier(),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  GeneratedImage fakeImage(List<int> marker) => GeneratedImage.create(
    Uint8List.fromList([9, 9, ...marker]),
    width: 832,
    height: 1216,
  );

  Future<ExploreRun> reloadRun(ProviderContainer c, String runId) async {
    final state = await c.read(exploreRunListNotifierProvider.future);
    return state.runById(runId)!;
  }

  test(
    'arm auto-creates a draft run and completed generation registers candidates',
    () async {
      final c = container();
      final notifier = c.read(exploreManualCaptureProvider.notifier);
      // 主 lane 有内容：roll 快照应抓到这个投影。
      c.read(pillWorkspaceProvider(PillScopes.main).notifier).setText('girl');

      await notifier.arm(autoRunName: '手动候选 测试', expectedCount: 2);
      final capture = c.read(exploreManualCaptureProvider);
      expect(capture.armed, isTrue);
      expect(capture.runId, isNotNull);
      expect(capture.candidateIds, hasLength(2));
      expect(capture.rollSnapshot!.positive, 'girl');

      // 自动建 draft run 并选中；手动轮 + 两个 pending 壳（首张带快照）。
      var run = await reloadRun(c, capture.runId!);
      expect(run.name, '手动候选 测试');
      expect(run.status, ExploreRunStatus.draft);
      expect(run.rounds.single.phase, ExploreRoundPhase.manual);
      expect(run.candidates, hasLength(2));
      expect(run.candidates.first.rollSnapshot, isNotNull);
      expect(run.candidates[1].rollSnapshot, isNull);
      expect(capture.rollSnapshots, hasLength(1));
      expect(
        run.candidates.first.lineage.operation,
        ExploreLineageOperation.manual,
      );
      expect(c.read(exploreActiveRunIdProvider), run.id);

      const autoRunName = '手动候选 测试';
      await notifier.handleBatchEvent(
        const GenerationBatchEvent(
          kind: GenerationBatchEventKind.start,
          batchIndex: 0,
          slotStart: 1,
          slotCount: 1,
          totalSlots: 2,
        ),
        autoRunName: autoRunName,
      );
      await notifier.handleBatchEvent(
        GenerationBatchEvent(
          kind: GenerationBatchEventKind.complete,
          batchIndex: 0,
          slotStart: 1,
          slotCount: 1,
          totalSlots: 2,
          images: [
            fakeImage([1]),
          ],
          elapsedMs: 10,
        ),
        autoRunName: autoRunName,
      );
      await notifier.handleBatchEvent(
        const GenerationBatchEvent(
          kind: GenerationBatchEventKind.start,
          batchIndex: 1,
          slotStart: 2,
          slotCount: 1,
          totalSlots: 2,
        ),
        autoRunName: autoRunName,
      );
      await notifier.handleBatchEvent(
        GenerationBatchEvent(
          kind: GenerationBatchEventKind.complete,
          batchIndex: 1,
          slotStart: 2,
          slotCount: 1,
          totalSlots: 2,
          images: [
            fakeImage([2]),
          ],
          elapsedMs: 10,
        ),
        autoRunName: autoRunName,
      );
      run = await reloadRun(c, capture.runId!);
      expect(run.generatedCount, 2);
      expect(run.candidates.first.rollSnapshot, isNotNull);
      expect(run.candidates[1].rollSnapshot, isNotNull);
      expect(
        run.candidates.first.rollSnapshot,
        isNot(same(run.candidates[1].rollSnapshot)),
      );
      for (final candidate in run.candidates) {
        expect(
          candidate.generation.status,
          ExploreCandidateGenerationStatus.done,
        );
        expect(candidate.generation.filePath, isNotNull);
        expect(await File(candidate.generation.filePath!).exists(), isTrue);
        expect(candidate.generation.elapsedMs, isNotNull);
      }
      // 卸防：后续主页生成不再登记。
      expect(c.read(exploreManualCaptureProvider).armed, isFalse);
    },
  );

  test('failed generation marks shells failed and disarms', () async {
    final c = container();
    final notifier = c.read(exploreManualCaptureProvider.notifier);

    await notifier.arm(autoRunName: '手动候选 失败', expectedCount: 1);
    final capture = c.read(exploreManualCaptureProvider);

    await notifier.handleBatchEvent(
      const GenerationBatchEvent(
        kind: GenerationBatchEventKind.start,
        batchIndex: 0,
        slotStart: 1,
        slotCount: 1,
        totalSlots: 1,
      ),
      autoRunName: '手动候选 失败',
    );
    await notifier.handleBatchEvent(
      const GenerationBatchEvent(
        kind: GenerationBatchEventKind.complete,
        batchIndex: 0,
        slotStart: 1,
        slotCount: 1,
        totalSlots: 1,
        error: 'boom',
      ),
      autoRunName: '手动候选 失败',
    );
    final run = await reloadRun(c, capture.runId!);
    expect(run.failedCount, 1);
    expect(run.candidates.single.generation.error, 'boom');
    expect(c.read(exploreManualCaptureProvider).armed, isFalse);
  });

  test('partial production fails leftover shells', () async {
    final c = container();
    final notifier = c.read(exploreManualCaptureProvider.notifier);

    await notifier.arm(autoRunName: '手动候选 部分', expectedCount: 2);
    final capture = c.read(exploreManualCaptureProvider);

    await notifier.handleBatchEvent(
      const GenerationBatchEvent(
        kind: GenerationBatchEventKind.start,
        batchIndex: 0,
        slotStart: 1,
        slotCount: 1,
        totalSlots: 2,
      ),
      autoRunName: '手动候选 部分',
    );
    await notifier.handleBatchEvent(
      GenerationBatchEvent(
        kind: GenerationBatchEventKind.complete,
        batchIndex: 0,
        slotStart: 1,
        slotCount: 1,
        totalSlots: 2,
        images: [
          fakeImage([7]),
        ],
      ),
      autoRunName: '手动候选 部分',
    );
    await notifier.handleBatchEvent(
      const GenerationBatchEvent(
        kind: GenerationBatchEventKind.start,
        batchIndex: 1,
        slotStart: 2,
        slotCount: 1,
        totalSlots: 2,
      ),
      autoRunName: '手动候选 部分',
    );
    await notifier.handleBatchEvent(
      const GenerationBatchEvent(
        kind: GenerationBatchEventKind.complete,
        batchIndex: 1,
        slotStart: 2,
        slotCount: 1,
        totalSlots: 2,
        error: 'no image produced',
      ),
      autoRunName: '手动候选 部分',
    );
    final run = await reloadRun(c, capture.runId!);
    expect(run.generatedCount, 1);
    expect(run.failedCount, 1);
  });

  test(
    'pairs failed first batch and successful second batch by slot range',
    () async {
      final c = container();
      final notifier = c.read(exploreManualCaptureProvider.notifier);

      await notifier.arm(autoRunName: '批次配对', expectedCount: 4);
      final capture = c.read(exploreManualCaptureProvider);
      await notifier.handleBatchEvent(
        const GenerationBatchEvent(
          kind: GenerationBatchEventKind.start,
          batchIndex: 0,
          slotStart: 1,
          slotCount: 2,
          totalSlots: 4,
        ),
        autoRunName: '批次配对',
      );
      await notifier.handleBatchEvent(
        const GenerationBatchEvent(
          kind: GenerationBatchEventKind.complete,
          batchIndex: 0,
          slotStart: 1,
          slotCount: 2,
          totalSlots: 4,
          error: 'first batch failed',
        ),
        autoRunName: '批次配对',
      );
      await notifier.handleBatchEvent(
        const GenerationBatchEvent(
          kind: GenerationBatchEventKind.start,
          batchIndex: 1,
          slotStart: 3,
          slotCount: 2,
          totalSlots: 4,
        ),
        autoRunName: '批次配对',
      );
      await notifier.handleBatchEvent(
        GenerationBatchEvent(
          kind: GenerationBatchEventKind.complete,
          batchIndex: 1,
          slotStart: 3,
          slotCount: 2,
          totalSlots: 4,
          images: [
            fakeImage([3]),
            fakeImage([4]),
          ],
        ),
        autoRunName: '批次配对',
      );

      final run = await reloadRun(c, capture.runId!);
      expect(
        run.candidates.map((candidate) => candidate.generation.status),
        orderedEquals([
          ExploreCandidateGenerationStatus.failed,
          ExploreCandidateGenerationStatus.failed,
          ExploreCandidateGenerationStatus.done,
          ExploreCandidateGenerationStatus.done,
        ]),
      );
      expect(run.candidates[0].generation.error, 'first batch failed');
      expect(run.candidates[1].generation.error, 'first batch failed');
      expect(run.candidates[2].generation.filePath, isNotNull);
      expect(run.candidates[3].generation.filePath, isNotNull);
      expect(
        run.candidates.map((candidate) => candidate.rollSnapshot),
        everyElement(isNotNull),
      );
    },
  );

  test(
    'done candidate is not overwritten when a later batch is cancelled',
    () async {
      final c = container();
      final notifier = c.read(exploreManualCaptureProvider.notifier);

      await notifier.arm(autoRunName: '取消保护', expectedCount: 2);
      final capture = c.read(exploreManualCaptureProvider);
      await notifier.handleBatchEvent(
        const GenerationBatchEvent(
          kind: GenerationBatchEventKind.start,
          batchIndex: 0,
          slotStart: 1,
          slotCount: 1,
          totalSlots: 2,
        ),
        autoRunName: '取消保护',
      );
      await notifier.handleBatchEvent(
        GenerationBatchEvent(
          kind: GenerationBatchEventKind.complete,
          batchIndex: 0,
          slotStart: 1,
          slotCount: 1,
          totalSlots: 2,
          images: [
            fakeImage([1]),
          ],
          elapsedMs: 10,
        ),
        autoRunName: '取消保护',
      );
      final doneRun = await reloadRun(c, capture.runId!);
      final doneGeneration = doneRun.candidates.first.generation;

      await notifier.handleBatchEvent(
        const GenerationBatchEvent(
          kind: GenerationBatchEventKind.start,
          batchIndex: 1,
          slotStart: 2,
          slotCount: 1,
          totalSlots: 2,
        ),
        autoRunName: '取消保护',
      );
      await notifier.handleBatchEvent(
        const GenerationBatchEvent(
          kind: GenerationBatchEventKind.complete,
          batchIndex: 1,
          slotStart: 2,
          slotCount: 1,
          totalSlots: 2,
          error: 'cancelled',
        ),
        autoRunName: '取消保护',
      );
      final run = await reloadRun(c, capture.runId!);
      expect(run.candidates.first.generation, doneGeneration);
      expect(
        run.candidates[1].generation.status,
        ExploreCandidateGenerationStatus.failed,
      );
    },
  );

  test(
    'cancelled current and unstarted slots leave no pending candidates',
    () async {
      final c = container();
      final notifier = c.read(exploreManualCaptureProvider.notifier);

      await notifier.arm(autoRunName: '取消剩余候选', expectedCount: 3);
      final capture = c.read(exploreManualCaptureProvider);
      const generationRunId = 42;

      await notifier.handleBatchEvent(
        const GenerationBatchEvent(
          kind: GenerationBatchEventKind.start,
          generationRunId: generationRunId,
          batchIndex: 0,
          slotStart: 1,
          slotCount: 1,
          totalSlots: 3,
        ),
        autoRunName: '取消剩余候选',
      );
      await notifier.handleBatchEvent(
        GenerationBatchEvent(
          kind: GenerationBatchEventKind.complete,
          generationRunId: generationRunId,
          batchIndex: 0,
          slotStart: 1,
          slotCount: 1,
          totalSlots: 3,
          images: [
            fakeImage([1]),
          ],
          elapsedMs: 10,
        ),
        autoRunName: '取消剩余候选',
      );
      await notifier.handleBatchEvent(
        const GenerationBatchEvent(
          kind: GenerationBatchEventKind.start,
          generationRunId: generationRunId,
          batchIndex: 1,
          slotStart: 2,
          slotCount: 1,
          totalSlots: 3,
        ),
        autoRunName: '取消剩余候选',
      );
      await notifier.handleBatchEvent(
        const GenerationBatchEvent(
          kind: GenerationBatchEventKind.complete,
          generationRunId: generationRunId,
          batchIndex: 1,
          slotStart: 2,
          slotCount: 1,
          totalSlots: 3,
          error: 'cancelled',
        ),
        autoRunName: '取消剩余候选',
      );
      await notifier.handleBatchEvent(
        const GenerationBatchEvent(
          kind: GenerationBatchEventKind.complete,
          generationRunId: generationRunId,
          batchIndex: 2,
          slotStart: 3,
          slotCount: 1,
          totalSlots: 3,
          error: 'cancelled',
        ),
        autoRunName: '取消剩余候选',
      );

      final run = await reloadRun(c, capture.runId!);
      expect(
        run.candidates.map((candidate) => candidate.generation.status),
        orderedEquals([
          ExploreCandidateGenerationStatus.done,
          ExploreCandidateGenerationStatus.failed,
          ExploreCandidateGenerationStatus.failed,
        ]),
      );
      expect(run.candidates.first.generation.error, isNull);
      expect(run.candidates[1].generation.error, 'cancelled');
      expect(run.candidates[2].generation.error, 'cancelled');
      expect(c.read(exploreManualCaptureProvider).armed, isFalse);
    },
  );

  test('ignores a different generation session id', () async {
    final c = container();
    final notifier = c.read(exploreManualCaptureProvider.notifier);

    const start = GenerationBatchEvent(
      kind: GenerationBatchEventKind.start,
      generationRunId: 11,
      batchIndex: 0,
      slotStart: 1,
      slotCount: 1,
      totalSlots: 2,
    );
    await notifier.handleBatchEvent(start, autoRunName: '会话隔离');
    final capture = c.read(exploreManualCaptureProvider);
    await notifier.handleBatchEvent(
      const GenerationBatchEvent(
        kind: GenerationBatchEventKind.complete,
        generationRunId: 12,
        batchIndex: 0,
        slotStart: 1,
        slotCount: 1,
        totalSlots: 2,
        error: 'stale',
      ),
      autoRunName: '会话隔离',
    );
    var run = await reloadRun(c, capture.runId!);
    expect(
      run.candidates.every(
        (candidate) =>
            candidate.generation.status ==
            ExploreCandidateGenerationStatus.pending,
      ),
      isTrue,
    );

    await notifier.handleBatchEvent(
      const GenerationBatchEvent(
        kind: GenerationBatchEventKind.complete,
        generationRunId: 11,
        batchIndex: 0,
        slotStart: 1,
        slotCount: 1,
        totalSlots: 2,
        images: [],
        error: 'failed',
      ),
      autoRunName: '会话隔离',
    );
    run = await reloadRun(c, capture.runId!);
    expect(
      run.candidates.first.generation.status,
      ExploreCandidateGenerationStatus.failed,
    );
    expect(
      run.candidates[1].generation.status,
      ExploreCandidateGenerationStatus.pending,
    );
  });

  test('cancelling arm leaves no pending shells', () async {
    final c = container();
    final notifier = c.read(exploreManualCaptureProvider.notifier);
    final arm = notifier.arm(autoRunName: '中途取消', expectedCount: 2);
    notifier.cancelSession();
    await arm;

    final runs = (await c.read(exploreRunListNotifierProvider.future)).runs;
    expect(
      runs
          .expand((run) => run.candidates)
          .where(
            (candidate) =>
                candidate.lineage.operation == ExploreLineageOperation.manual &&
                candidate.generation.status ==
                    ExploreCandidateGenerationStatus.pending,
          ),
      isEmpty,
    );
  });

  test('cancelling arm leaves no pending shells', () async {
    final c = container();
    final notifier = c.read(exploreManualCaptureProvider.notifier);
    final arm = notifier.arm(autoRunName: '中途取消', expectedCount: 2);
    notifier.cancelSession();
    await arm;

    final runs = (await c.read(exploreRunListNotifierProvider.future)).runs;
    expect(
      runs
          .expand((run) => run.candidates)
          .where(
            (candidate) =>
                candidate.lineage.operation == ExploreLineageOperation.manual &&
                candidate.generation.status ==
                    ExploreCandidateGenerationStatus.pending,
          ),
      isEmpty,
    );
  });

  test(
    'pending manual shells left over are swept to failed on build',
    () async {
      // 预置一个带 pending 手动壳的 run（模拟应用被杀现场）。
      const candidate = ExploreCandidate(
        id: 'orphan-1',
        roundId: 'round-m',
        lineage: ExploreLineage(operation: ExploreLineageOperation.manual),
      );
      final run =
          ExploreRun.create(
            name: '孤儿任务',
            recipeSnapshot: ExploreRecipeSnapshot(
              positive: PillDocument.empty(),
              negative: PillDocument.empty(),
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
              noiseSchedule: 'native',
              varietyPlus: false,
              decrisp: false,
            ),
            targetCount: 3,
          ).copyWith(
            rounds: [
              ExploreRound(
                id: 'round-m',
                number: 1,
                phase: ExploreRoundPhase.manual,
                status: ExploreRoundStatus.generated,
                createdAt: DateTime.utc(2026, 9, 1),
                targetCount: 0,
                candidateIds: const ['orphan-1'],
              ),
            ],
            candidates: [candidate],
          );
      await runStorage.putRun(run);

      final c = container();
      c.read(exploreManualCaptureProvider); // build 触发清扫

      ExploreRun? after;
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        after = await reloadRun(c, run.id);
        if (after.candidates.single.generation.status ==
            ExploreCandidateGenerationStatus.failed) {
          break;
        }
      }
      expect(
        after!.candidates.single.generation.status,
        ExploreCandidateGenerationStatus.failed,
      );
      expect(after.candidates.single.generation.error, 'interrupted');
    },
  );
}
