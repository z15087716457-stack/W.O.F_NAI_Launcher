import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/services/explore_run_image_store.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';

void main() {
  late Directory hiveDirectory;
  late Directory imageDirectory;
  late StyleExploreRunStorage runStorage;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'explore_run_provider_test_',
    );
    imageDirectory = await Directory.systemTemp.createTemp(
      'explore_run_provider_img_',
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
    if (await imageDirectory.exists()) {
      await imageDirectory.delete(recursive: true);
    }
  });

  ExploreParamsSnapshot snapshot() => const ExploreParamsSnapshot(
    model: 'nai-diffusion-4-5-full',
    width: 832,
    height: 1216,
    steps: 28,
    scale: 5.0,
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

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        styleExploreRunStorageProvider.overrideWithValue(runStorage),
        exploreRunImageStoreProvider.overrideWithValue(
          ExploreRunImageStore(
            rootPathResolver: () async => imageDirectory.path,
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<ExploreRun> createRun(ProviderContainer c, {String name = '任务A'}) {
    return c
        .read(exploreRunListNotifierProvider.notifier)
        .create(
          name: name,
          recipeSnapshot: const ExploreRecipeSnapshot(
            positive: PillDocument(text: 'pos', instances: {}),
            negative: PillDocument(text: 'neg', instances: {}),
          ),
          paramsSnapshot: snapshot(),
          targetCount: 5,
        );
  }

  test('create/rename/archive/delete keep list consistent', () async {
    final c = container();
    final notifier = c.read(exploreRunListNotifierProvider.notifier);

    final created = await createRun(c);
    var list = await c.read(exploreRunListNotifierProvider.future);
    expect(list.runs.single.id, created.id);
    expect(created.status, ExploreRunStatus.draft);

    await notifier.rename(created.id, '  改名  ');
    list = await c.read(exploreRunListNotifierProvider.future);
    expect(list.runs.single.name, '改名');

    await notifier.setArchived(created.id, true);
    list = await c.read(exploreRunListNotifierProvider.future);
    expect(list.runs.single.isArchived, isTrue);
    await notifier.setArchived(created.id, false);
    list = await c.read(exploreRunListNotifierProvider.future);
    expect(list.runs.single.isArchived, isFalse);

    // 建一个 run 目录副本再删 run，连带目录一并清除。
    final store = c.read(exploreRunImageStoreProvider);
    final dir = await store.runDirectory(created.id);
    await Directory(dir!).create(recursive: true);
    await File('$dir/leftover.png').writeAsBytes([1, 2, 3]);
    await notifier.delete(created.id);
    list = await c.read(exploreRunListNotifierProvider.future);
    expect(list.runs, isEmpty);
    expect(await Directory(dir).exists(), isFalse);
  });

  test(
    'targetCount editable in draft and generated, rejected elsewhere',
    () async {
      final c = container();
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      final created = await createRun(c);

      final updated = await notifier.updateTargetCount(created.id, 25);
      expect(updated.targetCount, 25);

      // generated 态仍可编辑（作用于追加的新一轮）。
      await notifier.overwrite(
        updated.copyWith(status: ExploreRunStatus.generated),
      );
      final again = await notifier.updateTargetCount(created.id, 8);
      expect(again.targetCount, 8);

      // 其他状态拒绝修改。
      await notifier.overwrite(again.copyWith(status: ExploreRunStatus.paused));
      expect(
        () => notifier.updateTargetCount(created.id, 50),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'addManualCandidates reuses one manual round and links lineage',
    () async {
      final c = container();
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      final created = await createRun(c);

      const snapshot = ExploreRollSnapshot(positive: 'pos', negative: 'neg');
      const secondSnapshot = ExploreRollSnapshot(
        positive: 'pos 2',
        negative: 'neg 2',
      );
      final first = await notifier.addManualCandidates(
        created.id,
        count: 2,
        rollSnapshots: [snapshot, secondSnapshot],
      );
      expect(first, hasLength(2));
      // 每个候选都带有对应槽位快照；谱系 operation=manual。
      expect(first.first.rollSnapshot, snapshot);
      expect(first[1].rollSnapshot, secondSnapshot);
      for (final candidate in first) {
        expect(candidate.lineage.operation, ExploreLineageOperation.manual);
        expect(
          candidate.generation.status,
          ExploreCandidateGenerationStatus.pending,
        );
      }

      var run = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(created.id)!;
      expect(run.rounds, hasLength(1));
      expect(run.rounds.single.phase, ExploreRoundPhase.manual);
      expect(run.rounds.single.status, ExploreRoundStatus.generated);
      expect(run.rounds.single.candidateIds, hasLength(2));
      expect(run.candidates, hasLength(2));

      // 再次追加：复用同一手动轮，不新建轮次。
      final second = await notifier.addManualCandidates(created.id, count: 1);
      run = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(created.id)!;
      expect(run.rounds, hasLength(1));
      expect(run.rounds.single.candidateIds, hasLength(3));
      expect(second.single.roundId, run.rounds.single.id);
    },
  );

  test('updateReview toggles heart and rejects unknown candidate', () async {
    final c = container();
    final notifier = c.read(exploreRunListNotifierProvider.notifier);
    final created = await createRun(c);
    final withCandidate = await notifier.overwrite(
      created.copyWith(
        candidates: [ExploreCandidate.shell(roundId: 'r-1', id: 'cand-1')],
      ),
    );

    await notifier.updateReview(withCandidate.id, 'cand-1', heart: true);
    var run = (await c.read(
      exploreRunListNotifierProvider.future,
    )).runById(created.id)!;
    expect(run.candidateById('cand-1')!.review.heart, isTrue);

    await notifier.updateReview(created.id, 'cand-1', heart: false);
    run = (await c.read(
      exploreRunListNotifierProvider.future,
    )).runById(created.id)!;
    expect(run.candidateById('cand-1')!.review.heart, isFalse);

    expect(
      () => notifier.updateReview(created.id, 'no-such', heart: true),
      throwsA(isA<StateError>()),
    );
  });

  test('active run provider follows the selected id', () async {
    final c = container();
    final created = await createRun(c);

    expect(c.read(exploreActiveRunProvider), isNull);
    c.read(exploreActiveRunIdProvider.notifier).state = created.id;
    // 列表构建后按 id 找到实体。
    await c.read(exploreRunListNotifierProvider.future);
    expect(c.read(exploreActiveRunProvider)?.id, created.id);
    c.read(exploreActiveRunIdProvider.notifier).state = null;
    expect(c.read(exploreActiveRunProvider), isNull);
  });

  group('gallery filter matcher', () {
    ExploreCandidate candidate({
      bool heart = false,
      ExploreCandidateGenerationStatus status =
          ExploreCandidateGenerationStatus.done,
    }) {
      return ExploreCandidate.shell(roundId: 'r').copyWith(
        generation: ExploreCandidateGeneration(status: status),
        review: ExploreCandidateReview(heart: heart),
      );
    }

    test('each filter matches its semantics', () {
      final plain = candidate();
      final hearted = candidate(heart: true);
      final failed = candidate(status: ExploreCandidateGenerationStatus.failed);

      expect(
        exploreCandidateMatchesFilter(plain, ExploreGalleryFilter.all),
        isTrue,
      );
      expect(
        exploreCandidateMatchesFilter(hearted, ExploreGalleryFilter.all),
        isTrue,
      );
      expect(
        exploreCandidateMatchesFilter(hearted, ExploreGalleryFilter.hearted),
        isTrue,
      );
      expect(
        exploreCandidateMatchesFilter(plain, ExploreGalleryFilter.hearted),
        isFalse,
      );
      expect(
        exploreCandidateMatchesFilter(failed, ExploreGalleryFilter.failed),
        isTrue,
      );
      expect(
        exploreCandidateMatchesFilter(plain, ExploreGalleryFilter.failed),
        isFalse,
      );
      expect(
        ExploreGalleryFilter.values.map((filter) => filter.name),
        ['all', 'hearted', 'failed'],
        reason: '筛选层只保留 全部/收藏/失败 三枚',
      );
    });
  });

  group('candidate folders', () {
    ExploreCandidate doneCandidate(String id) {
      return ExploreCandidate.shell(roundId: 'r-1', id: id).copyWith(
        generation: const ExploreCandidateGeneration(
          status: ExploreCandidateGenerationStatus.done,
          filePath: '/tmp/x.png',
          seed: 1,
        ),
      );
    }

    Future<ExploreRun> seedRun(
      ProviderContainer c,
      List<ExploreCandidate> candidates,
    ) {
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      return createRun(c).then(
        (created) => notifier.overwrite(
          created.copyWith(
            status: ExploreRunStatus.generated,
            candidates: candidates,
          ),
        ),
      );
    }

    Future<ExploreRun> reload(ProviderContainer c, String runId) async {
      return (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(runId)!;
    }

    test('create/rename/delete folder keeps members and images', () async {
      final c = container();
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      final run = await seedRun(c, [doneCandidate('cand-1')]);

      final folder = await notifier.createFolder(run.id, '  暖光  ');
      expect(folder.name, '暖光', reason: '名称去首尾空白');
      var stored = await reload(c, run.id);
      expect(stored.folders.single, folder);

      await notifier.assignCandidateFolder(run.id, 'cand-1', folder.id);
      stored = await reload(c, run.id);
      expect(stored.candidateById('cand-1')!.folderId, folder.id);

      await notifier.renameFolder(run.id, folder.id, '冷光');
      stored = await reload(c, run.id);
      expect(stored.folders.single.name, '冷光');

      await notifier.deleteFolder(run.id, folder.id);
      stored = await reload(c, run.id);
      expect(stored.folders, isEmpty);
      final orphan = stored.candidateById('cand-1')!;
      expect(orphan.folderId, isNull, reason: '删文件夹后成员回未分类');
      expect(orphan.generation.filePath, '/tmp/x.png', reason: '不删图');
    });

    test(
      'assign is single/batch, supports clearing, rejects bad ids',
      () async {
        final c = container();
        final notifier = c.read(exploreRunListNotifierProvider.notifier);
        final run = await seedRun(c, [
          doneCandidate('cand-1'),
          doneCandidate('cand-2'),
          doneCandidate('cand-3'),
        ]);
        final folder = await notifier.createFolder(run.id, 'A');

        await notifier.assignCandidatesFolder(run.id, [
          'cand-1',
          'cand-2',
        ], folder.id);
        var stored = await reload(c, run.id);
        expect(stored.candidateById('cand-1')!.folderId, folder.id);
        expect(stored.candidateById('cand-2')!.folderId, folder.id);
        expect(stored.candidateById('cand-3')!.folderId, isNull);

        // folderId = null：移回未分类。
        await notifier.assignCandidateFolder(run.id, 'cand-1', null);
        stored = await reload(c, run.id);
        expect(stored.candidateById('cand-1')!.folderId, isNull);

        expect(
          () => notifier.assignCandidateFolder(run.id, 'cand-1', 'no-folder'),
          throwsA(isA<StateError>()),
        );
        expect(
          () => notifier.assignCandidateFolder(run.id, 'no-cand', folder.id),
          throwsA(isA<StateError>()),
        );
        expect(
          () => notifier.assignCandidatesFolder(run.id, const [], folder.id),
          throwsA(isA<StateError>()),
        );
        expect(
          () => notifier.createFolder(run.id, '   '),
          throwsA(isA<StateError>()),
        );
        expect(
          () => notifier.renameFolder(run.id, 'no-folder', 'x'),
          throwsA(isA<StateError>()),
        );
        expect(
          () => notifier.deleteFolder(run.id, 'no-folder'),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('legacy reviewing status', () {
    test('decodes and round-trips for stored runs', () async {
      final c = container();
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      final run = await createRun(c);
      final candidate = ExploreCandidate.shell(roundId: 'r-1', id: 'cand-1')
          .copyWith(
            generation: const ExploreCandidateGeneration(
              status: ExploreCandidateGenerationStatus.done,
              filePath: '/tmp/x.png',
              seed: 1,
            ),
          );
      final generated = await notifier.overwrite(
        run.copyWith(
          status: ExploreRunStatus.generated,
          candidates: [candidate],
        ),
      );

      // 评审体系拆除后无路径可再写入 reviewing；存量值只作反序列化兼容。
      final legacy = await notifier.overwrite(
        generated.copyWith(status: ExploreRunStatus.reviewing),
      );
      expect(legacy.status, ExploreRunStatus.reviewing);
      final stored = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(run.id)!;
      expect(stored.status, ExploreRunStatus.reviewing);
    });
  });

  group('mergeExploreRollPositives', () {
    test('merges atoms with trim, dedup and no trailing comma', () {
      expect(
        mergeExploreRollPositives([
          'soft light, watercolor',
          'watercolor, 1girl,',
        ]),
        'soft light, watercolor, 1girl',
      );
      expect(mergeExploreRollPositives(['  a , b ', 'b, c']), 'a, b, c');
      expect(mergeExploreRollPositives([]), '');
      expect(mergeExploreRollPositives([' , ', '']), '');
      // 单串等价原子规范化（去尾部逗号）。
      expect(mergeExploreRollPositives(['x, y,']), 'x, y');
    });
  });
}
