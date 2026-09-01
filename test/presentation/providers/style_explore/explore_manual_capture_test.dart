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
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_manual_capture.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';

/// 直接驱动状态的假生成 notifier（不触发任何真实生成链）。
class _FakeImageGenerationNotifier extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();

  void emit(ImageGenerationState next) {
    state = next;
  }
}

class _FakeLibraryNotifier extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: const [], folders: const []);
}

void main() {
  late Directory hiveDirectory;
  late Directory imageDirectory;
  late StyleExploreRunStorage runStorage;
  late _FakeImageGenerationNotifier generationNotifier;

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
    generationNotifier = _FakeImageGenerationNotifier();
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
        imageGenerationNotifierProvider.overrideWith(() => generationNotifier),
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
      expect(
        run.candidates.first.lineage.operation,
        ExploreLineageOperation.manual,
      );
      expect(c.read(exploreActiveRunIdProvider), run.id);

      // 完成：两张新图按序配对登记，副本落 run 目录。
      generationNotifier.emit(
        ImageGenerationState(
          status: GenerationStatus.completed,
          currentImages: [
            fakeImage([1]),
            fakeImage([2]),
          ],
        ),
      );
      // 等登记链跑完（listener → 异步 finalize）。
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        run = await reloadRun(c, capture.runId!);
        if (run.generatedCount == 2) break;
      }
      expect(run.generatedCount, 2);
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

    generationNotifier.emit(
      const ImageGenerationState(
        status: GenerationStatus.error,
        errorMessage: 'boom',
      ),
    );
    ExploreRun run = await reloadRun(c, capture.runId!);
    for (var i = 0; i < 100; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      run = await reloadRun(c, capture.runId!);
      if (run.failedCount == 1) break;
    }
    expect(run.failedCount, 1);
    expect(run.candidates.single.generation.error, 'boom');
    expect(c.read(exploreManualCaptureProvider).armed, isFalse);
  });

  test('partial production fails leftover shells', () async {
    final c = container();
    final notifier = c.read(exploreManualCaptureProvider.notifier);

    await notifier.arm(autoRunName: '手动候选 部分', expectedCount: 2);
    final capture = c.read(exploreManualCaptureProvider);

    generationNotifier.emit(
      ImageGenerationState(
        status: GenerationStatus.completed,
        currentImages: [
          fakeImage([7]),
        ],
      ),
    );
    ExploreRun run = await reloadRun(c, capture.runId!);
    for (var i = 0; i < 100; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      run = await reloadRun(c, capture.runId!);
      if (run.generatedCount == 1 && run.failedCount == 1) break;
    }
    expect(run.generatedCount, 1);
    expect(run.failedCount, 1);
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
