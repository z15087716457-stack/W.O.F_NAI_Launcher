import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/services/explore_run_image_store.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';

final _epoch = DateTime.utc(2026, 9, 1);

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

  test(
    'append parents deduplicates, keeps preference and serializes concurrent writes',
    () async {
      final c = container(),
          notifier = c.read(exploreRunListNotifierProvider.notifier);
      final run = await createRun(c);
      final line = await notifier.createFamily(
        run.id,
        name: 'Evolution line',
        parents: const [(sourceCandidateId: 'a', artistString: 'artist:a')],
      );
      final futures = [
        notifier.addParentsToActiveSet(
          run.id,
          familyId: line.id,
          parents: const [
            (sourceCandidateId: 'duplicate', artistString: ' artist:a '),
            (sourceCandidateId: 'b', artistString: 'artist:b'),
            (sourceCandidateId: 'b2', artistString: ' artist:b '),
            (sourceCandidateId: null, artistString: ' '),
          ],
        ),
        notifier.addParentsToActiveSet(
          run.id,
          familyId: line.id,
          parents: const [(sourceCandidateId: null, artistString: 'artist:c')],
        ),
      ];
      await Future.wait(futures);
      final updated = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(run.id)!;
      expect(updated.parentSets.single.parents.map((p) => p.artistString), [
        'artist:a',
        'artist:b',
        'artist:c',
      ]);
      expect(
        updated.parentSets.single.parents.map((p) => p.sourceCandidateId),
        ['a', 'b', null],
      );
      expect(updated.parentSets.single.parents.first.preference, 1);
      expect(updated.families.single.activeParentSetId, line.activeParentSetId);
    },
  );

  test(
    'append parents only touches the active set and rejects in-flight rounds or pending candidates',
    () async {
      final c = container(),
          notifier = c.read(exploreRunListNotifierProvider.notifier);
      final run = await createRun(c);
      final family = await notifier.createFamily(
        run.id,
        name: 'Line',
        parents: const [(sourceCandidateId: null, artistString: 'artist:root')],
      );
      final original = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(run.id)!;
      final active = original.parentSets.single.copyWith(
        id: 'next',
        generation: 2,
      );
      final current = original.copyWith(
        parentSets: [
          original.parentSets.single.copyWith(
            status: ExploreParentSetStatus.used,
          ),
          active,
        ],
        families: [family.copyWith(activeParentSetId: active.id)],
      );
      await notifier.overwrite(current);
      await notifier.addParentsToActiveSet(
        run.id,
        familyId: family.id,
        parents: const [(sourceCandidateId: null, artistString: 'artist:next')],
      );
      final updated = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(run.id)!;
      expect(updated.parentSets.first.parents, hasLength(1));
      expect(updated.parentSets.last.parents, hasLength(2));
      for (final status in [
        ExploreRoundStatus.pending,
        ExploreRoundStatus.generating,
        ExploreRoundStatus.generated,
      ]) {
        await notifier.overwrite(
          updated.copyWith(
            rounds: [
              ExploreRound(
                id: 'deep',
                number: 1,
                phase: ExploreRoundPhase.deep,
                status: status,
                createdAt: _epoch,
                targetCount: 1,
                parentSetId: active.id,
                candidateIds: ['pending'],
              ),
            ],
            candidates: const [
              ExploreCandidate(
                id: 'pending',
                roundId: 'deep',
                lineage: ExploreLineage(
                  operation: ExploreLineageOperation.mutation,
                ),
                generation: ExploreCandidateGeneration(
                  status: ExploreCandidateGenerationStatus.pending,
                ),
              ),
            ],
          ),
        );
        await expectLater(
          notifier.addParentsToActiveSet(
            run.id,
            familyId: family.id,
            parents: const [
              (sourceCandidateId: null, artistString: 'artist:no'),
            ],
          ),
          throwsStateError,
        );
        expect(
          (await c.read(
            exploreRunListNotifierProvider.future,
          )).runById(run.id)!.parentSets.last.parents,
          hasLength(2),
        );
      }
    },
  );

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
    'addManualCandidates creates a numbered round per call and links lineage',
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

      // 再次点击建立独立轮，已有候选不挪动。
      final second = await notifier.addManualCandidates(created.id, count: 1);
      run = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(created.id)!;
      expect(run.rounds, hasLength(2));
      expect(run.rounds.map((round) => round.number), [1, 2]);
      expect(
        run.rounds.first.candidateIds,
        first.map((candidate) => candidate.id),
      );
      expect(run.rounds.last.candidateIds, [second.single.id]);
      expect(second.single.roundId, run.rounds.last.id);
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
      String? folderId,
      ExploreCandidateGenerationStatus status =
          ExploreCandidateGenerationStatus.done,
    }) {
      return ExploreCandidate.shell(roundId: 'r').copyWith(
        generation: ExploreCandidateGeneration(status: status),
        review: ExploreCandidateReview(heart: heart),
        folderId: folderId,
      );
    }

    test('each filter matches its semantics', () {
      final plain = candidate();
      final hearted = candidate(heart: true);
      final inFolder = candidate(folderId: 'folder-a');

      expect(
        exploreCandidateMatchesFilter(plain, const ExploreGalleryFilterAll()),
        isTrue,
      );
      expect(
        exploreCandidateMatchesFilter(hearted, const ExploreGalleryFilterAll()),
        isTrue,
      );
      expect(
        exploreCandidateMatchesFilter(
          hearted,
          const ExploreGalleryFilterHearted(),
        ),
        isTrue,
      );
      expect(
        exploreCandidateMatchesFilter(
          plain,
          const ExploreGalleryFilterHearted(),
        ),
        isFalse,
      );
      // 文件夹筛选：folderId 精确匹配；null = 未分类。
      expect(
        exploreCandidateMatchesFilter(
          inFolder,
          const ExploreGalleryFilterFolder('folder-a'),
        ),
        isTrue,
      );
      expect(
        exploreCandidateMatchesFilter(
          plain,
          const ExploreGalleryFilterFolder('folder-a'),
        ),
        isFalse,
      );
      expect(
        exploreCandidateMatchesFilter(
          plain,
          const ExploreGalleryFilterFolder(null),
        ),
        isTrue,
      );
      expect(
        exploreCandidateMatchesFilter(
          inFolder,
          const ExploreGalleryFilterFolder(null),
        ),
        isFalse,
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

    test('reorderFolders persists new order and rejects stale lists', () async {
      final c = container();
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      final run = await seedRun(c, []);
      final a = await notifier.createFolder(run.id, 'A');
      final b = await notifier.createFolder(run.id, 'B');
      final d = await notifier.createFolder(run.id, 'D');

      await notifier.reorderFolders(run.id, [d.id, a.id, b.id]);
      var stored = await reload(c, run.id);
      expect(stored.folders.map((f) => f.name), ['D', 'A', 'B']);

      // 非同集合（漏项/外项）拒绝且不污染现状。
      expect(
        () => notifier.reorderFolders(run.id, [a.id, b.id]),
        throwsA(isA<StateError>()),
      );
      expect(
        () => notifier.reorderFolders(run.id, [a.id, b.id, 'ghost']),
        throwsA(isA<StateError>()),
      );
      stored = await reload(c, run.id);
      expect(stored.folders.map((f) => f.name), ['D', 'A', 'B']);
    });

    test('deleting the filtered folder resets gallery filter to all', () async {
      final c = container();
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      final run = await seedRun(c, []);
      final folder = await notifier.createFolder(run.id, '暖光');

      c.read(exploreGalleryFilterProvider.notifier).state =
          ExploreGalleryFilterFolder(folder.id);
      await notifier.deleteFolder(run.id, folder.id);
      expect(
        c.read(exploreGalleryFilterProvider),
        isA<ExploreGalleryFilterAll>(),
      );

      // 指着别处的筛选不受影响。
      final other = await notifier.createFolder(run.id, '冷光');
      c.read(exploreGalleryFilterProvider.notifier).state =
          ExploreGalleryFilterFolder(other.id);
      final gone = await notifier.createFolder(run.id, '无关');
      await notifier.deleteFolder(run.id, gone.id);
      final filter = c.read(exploreGalleryFilterProvider);
      expect(filter, isA<ExploreGalleryFilterFolder>());
      expect((filter as ExploreGalleryFilterFolder).folderId, other.id);
    });
  });

  group('removeCandidates (FEAT-55 连记录删)', () {
    ExploreCandidate doneCandidate(String id, {String roundId = 'r-1'}) {
      return ExploreCandidate.shell(roundId: roundId, id: id).copyWith(
        generation: const ExploreCandidateGeneration(
          status: ExploreCandidateGenerationStatus.done,
          filePath: '/tmp/x.png',
        ),
      );
    }

    test('removes records and cleans round/lineage references', () async {
      final c = container();
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      final created = await createRun(c);
      final run = await notifier.overwrite(
        created.copyWith(
          status: ExploreRunStatus.generated,
          candidates: [
            doneCandidate('cand-1'),
            doneCandidate('cand-2'),
            // 子代血缘引用 cand-1：删后引用应被清掉。
            doneCandidate('cand-3', roundId: 'r-2').copyWith(
              lineage: const ExploreLineage(
                operation: ExploreLineageOperation.mutation,
                generation: 2,
                parentCandidateIds: ['cand-1', 'cand-x'],
              ),
            ),
          ],
          rounds: [
            ExploreRound(
              id: 'r-1',
              number: 1,
              phase: ExploreRoundPhase.basic,
              status: ExploreRoundStatus.generated,
              createdAt: DateTime.utc(2026, 9, 1),
              targetCount: 2,
              candidateIds: const ['cand-1', 'cand-2'],
            ),
            ExploreRound(
              id: 'r-2',
              number: 2,
              phase: ExploreRoundPhase.deep,
              status: ExploreRoundStatus.generated,
              createdAt: DateTime.utc(2026, 9, 1),
              targetCount: 1,
              candidateIds: const ['cand-3'],
            ),
          ],
        ),
      );

      await notifier.removeCandidates(run.id, ['cand-1', 'cand-2']);
      final stored = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(run.id)!;

      expect(stored.candidates.map((candidate) => candidate.id), ['cand-3']);
      expect(
        stored.rounds.firstWhere((round) => round.id == 'r-1').candidateIds,
        isEmpty,
      );
      expect(
        stored.rounds.firstWhere((round) => round.id == 'r-2').candidateIds,
        ['cand-3'],
      );
      // 血缘引用只清已删项，外部悬空引用（cand-x）原样保留。
      expect(stored.candidateById('cand-3')!.lineage.parentCandidateIds, [
        'cand-x',
      ]);
    });

    test('rejects empty ids and missing candidates', () async {
      final c = container();
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      final run = await createRun(c);
      expect(
        () => notifier.removeCandidates(run.id, const []),
        throwsStateError,
      );
      expect(
        () => notifier.removeCandidates(run.id, const ['ghost']),
        throwsStateError,
      );
    });
  });

  group('deleteFamily （整族删）', () {
    ExploreCandidate doneCandidate(
      String id,
      String roundId, {
      List<String> parentCandidateIds = const [],
    }) {
      return ExploreCandidate.shell(roundId: roundId, id: id).copyWith(
        generation: const ExploreCandidateGeneration(
          status: ExploreCandidateGenerationStatus.done,
          filePath: '/tmp/x.png',
        ),
        lineage: ExploreLineage(
          operation: ExploreLineageOperation.mutation,
          parentCandidateIds: parentCandidateIds,
        ),
      );
    }

    ExploreRound deepRound(
      String id, {
      required String parentSetId,
      String? familyId,
      int generation = 1,
      ExploreRoundStatus status = ExploreRoundStatus.generated,
      List<String> candidateIds = const [],
    }) {
      return ExploreRound(
        id: id,
        number: 2,
        phase: ExploreRoundPhase.deep,
        status: status,
        createdAt: DateTime.utc(2026, 9, 1),
        targetCount: candidateIds.length,
        candidateIds: candidateIds,
        familyId: familyId,
        parentSetId: parentSetId,
        generation: generation,
      );
    }

    test('cascades family, parent sets, rounds and candidates', () async {
      final c = container();
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      final created = await createRun(c);
      final run = await notifier.overwrite(
        created.copyWith(
          status: ExploreRunStatus.generated,
          families: [
            ExploreFamily(
              id: 'fam-1',
              name: '家族1',
              createdAt: _epoch,
              rootParentSetId: 'ps-1',
              activeParentSetId: 'ps-1',
            ),
            ExploreFamily(
              id: 'fam-2',
              name: '家族2',
              createdAt: _epoch,
              rootParentSetId: 'ps-3',
              activeParentSetId: 'ps-3',
            ),
          ],
          parentSets: const [
            ExploreParentSet(
              id: 'ps-1',
              familyId: 'fam-1',
              generation: 1,
              status: ExploreParentSetStatus.active,
            ),
            ExploreParentSet(
              id: 'ps-2',
              familyId: 'fam-1',
              generation: 2,
              status: ExploreParentSetStatus.active,
            ),
            ExploreParentSet(
              id: 'ps-3',
              familyId: 'fam-2',
              generation: 1,
              status: ExploreParentSetStatus.active,
            ),
          ],
          rounds: [
            deepRound(
              'dr-1',
              parentSetId: 'ps-1',
              familyId: 'fam-1',
              candidateIds: const ['cand-1'],
            ),
            deepRound(
              'dr-2',
              parentSetId: 'ps-2',
              familyId: 'fam-1',
              generation: 2,
              candidateIds: const ['cand-2'],
            ),
            // 家族2 的轮带 fam-2 标注：归组真源是 parentSetId，
            // 不是 familyId 冗余字段。
            deepRound(
              'dr-3',
              parentSetId: 'ps-3',
              familyId: 'fam-2',
              candidateIds: const ['cand-3'],
            ),
            // 无 parentSetId 的手动轮：不该被任何家族删除波及。
            ExploreRound(
              id: 'mr-1',
              number: 9,
              phase: ExploreRoundPhase.manual,
              status: ExploreRoundStatus.generated,
              createdAt: DateTime.utc(2026, 9, 1),
              targetCount: 1,
              candidateIds: const ['cand-m'],
            ),
          ],
          candidates: [
            doneCandidate('cand-1', 'dr-1'),
            doneCandidate('cand-2', 'dr-2'),
            doneCandidate('cand-3', 'dr-3'),
            // 存活候选引用了将被删除的 cand-1：引用应被清掉。
            doneCandidate(
              'cand-m',
              'mr-1',
              parentCandidateIds: const ['cand-1', 'cand-x'],
            ),
          ],
        ),
      );

      c.read(exploreActiveFamilyIdProvider.notifier).state = 'fam-1';
      await notifier.deleteFamily(run.id, 'fam-1');
      final stored = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(run.id)!;

      expect(stored.families.map((family) => family.id), ['fam-2']);
      expect(stored.parentSets.map((set) => set.id), ['ps-3']);
      expect(stored.rounds.map((round) => round.id), ['dr-3', 'mr-1']);
      expect(stored.candidates.map((candidate) => candidate.id), [
        'cand-3',
        'cand-m',
      ]);
      // 只清已删项，外部悬空引用（cand-x）原样保留。
      expect(stored.candidateById('cand-m')!.lineage.parentCandidateIds, [
        'cand-x',
      ]);
      // 面板指针指向被删家族时清空。
      expect(c.read(exploreActiveFamilyIdProvider), isNull);
    });

    test('refuses while a round or candidate is still pending', () async {
      final c = container();
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      final created = await createRun(c);
      ExploreRun base() => created.copyWith(
        families: [
          ExploreFamily(
            id: 'fam-1',
            name: '家族1',
            createdAt: _epoch,
            rootParentSetId: 'ps-1',
            activeParentSetId: 'ps-1',
          ),
        ],
        parentSets: const [
          ExploreParentSet(
            id: 'ps-1',
            familyId: 'fam-1',
            generation: 1,
            status: ExploreParentSetStatus.active,
          ),
        ],
      );

      // pending 深度轮拒删。
      var run = await notifier.overwrite(
        base().copyWith(
          rounds: [
            deepRound(
              'dr-1',
              parentSetId: 'ps-1',
              familyId: 'fam-1',
              status: ExploreRoundStatus.pending,
            ),
          ],
        ),
      );
      expect(() => notifier.deleteFamily(run.id, 'fam-1'), throwsStateError);

      // generated 轮但轮内还有 pending 候选同样拒删。
      run = await notifier.overwrite(
        base().copyWith(
          rounds: [
            deepRound(
              'dr-1',
              parentSetId: 'ps-1',
              familyId: 'fam-1',
              candidateIds: const ['cand-1'],
            ),
          ],
          candidates: [ExploreCandidate.shell(roundId: 'dr-1', id: 'cand-1')],
        ),
      );
      expect(() => notifier.deleteFamily(run.id, 'fam-1'), throwsStateError);
      final stored = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(run.id)!;
      expect(stored.families, hasLength(1));
      expect(stored.rounds, hasLength(1));
      expect(stored.candidates, hasLength(1));
    });

    test('deletes a shell family without rounds cleanly', () async {
      final c = container();
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      final created = await createRun(c);
      // 空壳家族：只有 family + rootParentSet，没有轮和候选
      // （比如建家族后从未成功出过深度轮）。
      final run = await notifier.overwrite(
        created.copyWith(
          families: [
            ExploreFamily(
              id: 'fam-1',
              name: '家族1',
              createdAt: _epoch,
              rootParentSetId: 'ps-1',
              activeParentSetId: 'ps-1',
            ),
          ],
          parentSets: const [
            ExploreParentSet(
              id: 'ps-1',
              familyId: 'fam-1',
              generation: 1,
              status: ExploreParentSetStatus.active,
            ),
          ],
        ),
      );

      await notifier.deleteFamily(run.id, 'fam-1');
      final stored = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(run.id)!;
      expect(stored.families, isEmpty);
      expect(stored.parentSets, isEmpty);
    });

    test('rejects unknown family id', () async {
      final c = container();
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      final run = await createRun(c);
      expect(() => notifier.deleteFamily(run.id, 'ghost'), throwsStateError);
    });
  });

  group('legacy reviewing status', () {
    test('decodes and normalizes to generated on storage read', () async {
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

      // 评审体系拆除后无路径可再写入 reviewing；存量值只作反序列化兼容，
      // 存储层读入即归一化为 generated（下次落盘自愈）。
      final legacy = await notifier.overwrite(
        generated.copyWith(status: ExploreRunStatus.reviewing),
      );
      expect(legacy.status, ExploreRunStatus.reviewing);
      final stored = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(run.id)!;
      expect(stored.status, ExploreRunStatus.generated);
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
