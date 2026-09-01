import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/services/explore_run_image_store.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_roll_capture.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';

class _FakeLibraryNotifier extends PromptBlockLibraryNotifier {
  _FakeLibraryNotifier(this.blocks);

  final List<PromptBlock> blocks;

  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: blocks, folders: const []);
}

final _captureExploreRollSnapshotProvider = Provider<ExploreRollSnapshot>(
  (ref) => captureExploreRollSnapshot(ref),
);

void main() {
  late Directory hiveDirectory;
  late StyleExploreRunStorage runStorage;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'explore_deep_iteration_test_',
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

  ProviderContainer container({List<PromptBlock> blocks = const []}) {
    final c = ProviderContainer(
      overrides: [
        styleExploreRunStorageProvider.overrideWithValue(runStorage),
        exploreRunImageStoreProvider.overrideWithValue(
          ExploreRunImageStore(rootPathResolver: () async => null),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakeLibraryNotifier(blocks),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<ExploreRun> createRun(ProviderContainer c) {
    return c
        .read(exploreRunListNotifierProvider.notifier)
        .create(
          name: '深度任务',
          recipeSnapshot: const ExploreRecipeSnapshot(
            positive: PillDocument(text: 'pos', instances: {}),
            negative: PillDocument(text: 'neg', instances: {}),
          ),
          paramsSnapshot: snapshot(),
          targetCount: 3,
        );
  }

  Future<ExploreRun> reload(ProviderContainer c, String runId) async {
    return (await c.read(
      exploreRunListNotifierProvider.future,
    )).runById(runId)!;
  }

  ExploreCandidate doneCandidate(
    String id,
    String roundId, {
    String? mutatedText,
    int generation = 2,
  }) {
    return ExploreCandidate(
      id: id,
      roundId: roundId,
      generation: const ExploreCandidateGeneration(
        status: ExploreCandidateGenerationStatus.done,
        filePath: '/tmp/x.png',
        seed: 1,
      ),
      lineage: ExploreLineage(
        operation: ExploreLineageOperation.mutation,
        generation: generation,
        mutatedText: mutatedText,
      ),
    );
  }

  /// 家族种子数据：root 父本集（gen1）+ 深度轮（gen2，三个完成候选）。
  Future<ExploreRun> seedFamilyRun(
    ProviderContainer c, {
    List<ExploreCandidate>? deepCandidates,
    ExploreRoundStatus deepRoundStatus = ExploreRoundStatus.generated,
  }) async {
    final created = await createRun(c);
    const rootSet = ExploreParentSet(
      id: 'ps-1',
      familyId: 'fam-1',
      generation: 1,
      status: ExploreParentSetStatus.active,
      parents: [
        ExploreParent(
          id: 'rp-1',
          sourceCandidateId: 'src-1',
          artistString: 'root:a',
          preference: 1.5,
        ),
        ExploreParent(id: 'rp-2', artistString: 'root:b'),
      ],
    );
    final family = ExploreFamily(
      id: 'fam-1',
      name: '家族甲',
      createdAt: DateTime.utc(2026, 9, 1),
      rootParentSetId: 'ps-1',
      activeParentSetId: 'ps-1',
    );
    final deepRound = ExploreRound(
      id: 'dr-1',
      number: 1,
      phase: ExploreRoundPhase.deep,
      status: deepRoundStatus,
      createdAt: DateTime.utc(2026, 9, 1),
      targetCount: 3,
      candidateIds: const ['c-1', 'c-2', 'c-3'],
      familyId: 'fam-1',
      parentSetId: 'ps-1',
      generation: 2,
    );
    final candidates =
        deepCandidates ??
        [
          doneCandidate('c-1', 'dr-1', mutatedText: 'mut:a'),
          doneCandidate('c-2', 'dr-1', mutatedText: 'mut:b'),
          doneCandidate('c-3', 'dr-1', mutatedText: 'mut:c'),
        ];
    return c
        .read(exploreRunListNotifierProvider.notifier)
        .overwrite(
          created.copyWith(
            status: ExploreRunStatus.generated,
            parentSets: [rootSet],
            families: [family],
            rounds: [deepRound],
            candidates: candidates,
          ),
        );
  }

  group('exploreParentStringFor（父本串提取）', () {
    test('优先第一个随机实例 rolledText，空串回退正向全文', () {
      const withRolls = ExploreCandidate(
        id: 'c',
        roundId: 'r',
        rollSnapshot: ExploreRollSnapshot(
          positive: 'full positive',
          negative: 'neg',
          instanceRolls: [
            ExploreInstanceRoll(
              lane: 'pos',
              marker: 'm',
              blockId: 'b-1',
              blockTitle: '池',
              rolledText: 'rolled text',
            ),
          ],
        ),
        lineage: ExploreLineage(operation: ExploreLineageOperation.basicRoll),
      );
      expect(exploreParentStringFor(withRolls), 'rolled text');

      const emptyRoll = ExploreCandidate(
        id: 'c',
        roundId: 'r',
        rollSnapshot: ExploreRollSnapshot(
          positive: 'full positive',
          negative: 'neg',
          instanceRolls: [
            ExploreInstanceRoll(
              lane: 'pos',
              marker: 'm',
              blockId: 'b-1',
              blockTitle: '池',
              rolledText: '  ',
            ),
          ],
        ),
        lineage: ExploreLineage(operation: ExploreLineageOperation.basicRoll),
      );
      expect(exploreParentStringFor(emptyRoll), 'full positive');

      const noRolls = ExploreCandidate(
        id: 'c',
        roundId: 'r',
        rollSnapshot: ExploreRollSnapshot(
          positive: 'full positive',
          negative: 'neg',
        ),
        lineage: ExploreLineage(operation: ExploreLineageOperation.basicRoll),
      );
      expect(exploreParentStringFor(noRolls), 'full positive');

      const noSnapshot = ExploreCandidate(
        id: 'c',
        roundId: 'r',
        lineage: ExploreLineage(operation: ExploreLineageOperation.basicRoll),
      );
      expect(exploreParentStringFor(noSnapshot), '');
    });
  });

  group('createFamily（建家族）', () {
    test('创建家族 + 第一代活跃父本集；串去重去空、来源保留', () async {
      final c = container();
      final created = await createRun(c);
      final family = await c
          .read(exploreRunListNotifierProvider.notifier)
          .createFamily(
            created.id,
            name: '  柔光主线  ',
            parents: const [
              (sourceCandidateId: 'cand-1', artistString: 'artist:a'),
              (sourceCandidateId: 'cand-2', artistString: ' artist:a '),
              (sourceCandidateId: 'cand-3', artistString: ''),
              (sourceCandidateId: null, artistString: 'artist:x'),
            ],
          );

      expect(family.name, '柔光主线');
      final run = await reload(c, created.id);
      expect(run.families, hasLength(1));
      expect(run.parentSets, hasLength(1));
      final set = run.parentSets.single;
      expect(set.generation, 1);
      expect(set.status, ExploreParentSetStatus.active);
      expect(set.familyId, family.id);
      expect(family.rootParentSetId, set.id);
      expect(family.activeParentSetId, set.id);
      // 去重去空后剩 2 个父本；来源候选 id 保留。
      expect(set.parents, hasLength(2));
      expect(set.parents[0].artistString, 'artist:a');
      expect(set.parents[0].sourceCandidateId, 'cand-1');
      expect(set.parents[1].artistString, 'artist:x');
      expect(set.parents[1].sourceCandidateId, isNull);
      expect(set.parents[0].preference, 1.0);
    });

    test('全部空串抛 StateError；空名称回退默认名', () async {
      final c = container();
      final created = await createRun(c);
      expect(
        () => c
            .read(exploreRunListNotifierProvider.notifier)
            .createFamily(
              created.id,
              name: 'x',
              parents: const [(sourceCandidateId: null, artistString: '  ')],
            ),
        throwsStateError,
      );

      final family = await c
          .read(exploreRunListNotifierProvider.notifier)
          .createFamily(
            created.id,
            name: '  ',
            parents: const [
              (sourceCandidateId: null, artistString: 'artist:a'),
            ],
          );
      expect(family.name, '家族 1');
    });
  });

  group('createBranch（建分支）', () {
    test('优秀子代 + 第一代父本回交 → 新父本集，旧置 used', () async {
      final c = container();
      final run = await seedFamilyRun(c);
      final newSet = await c
          .read(exploreRunListNotifierProvider.notifier)
          .createBranch(
            run.id,
            familyId: 'fam-1',
            selectedCandidateIds: const ['c-1', 'c-3'],
            branchName: ' 支线 ',
          );

      expect(newSet.generation, 2);
      expect(newSet.status, ExploreParentSetStatus.active);
      expect(newSet.branchName, '支线');
      // 新父本 = 两个子代 + 回交两个第一代父本。
      expect(newSet.parents, hasLength(4));
      expect(newSet.parents[0].artistString, 'mut:a');
      expect(newSet.parents[0].sourceCandidateId, 'c-1');
      expect(newSet.parents[0].preference, 1.0);
      expect(newSet.parents[1].artistString, 'mut:c');
      // 回交父本保留串与偏好，id 换新。
      expect(newSet.parents[2].artistString, 'root:a');
      expect(newSet.parents[2].preference, 1.5);
      expect(newSet.parents[2].id, isNot('rp-1'));
      expect(newSet.parents[2].sourceCandidateId, 'src-1');
      expect(newSet.parents[3].artistString, 'root:b');

      final after = await reload(c, run.id);
      expect(
        after.parentSetById('ps-1')!.status,
        ExploreParentSetStatus.used,
        reason: '旧活跃集置 used',
      );
      expect(after.familyById('fam-1')!.activeParentSetId, newSet.id);
      expect(after.familyById('fam-1')!.rootParentSetId, 'ps-1');
    });

    test('不变量：只能从最新代选', () async {
      final c = container();
      final run = await seedFamilyRun(c);
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      // 混入手动轮候选。
      final manual = await notifier.addManualCandidates(run.id, count: 1);
      await expectLater(
        notifier.createBranch(
          run.id,
          familyId: 'fam-1',
          selectedCandidateIds: ['c-1', manual.single.id],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('只能从最新代'),
          ),
        ),
      );
    });

    test('不变量：当前代轮次全完成', () async {
      final c = container();
      final candidates = [
        doneCandidate('c-1', 'dr-1', mutatedText: 'mut:a'),
        doneCandidate('c-2', 'dr-1', mutatedText: 'mut:b'),
        const ExploreCandidate(
          id: 'c-3',
          roundId: 'dr-1',
          lineage: ExploreLineage(
            operation: ExploreLineageOperation.mutation,
            generation: 2,
            mutatedText: 'mut:c',
          ),
        ),
      ];
      final run = await seedFamilyRun(c, deepCandidates: candidates);
      await expectLater(
        c
            .read(exploreRunListNotifierProvider.notifier)
            .createBranch(
              run.id,
              familyId: 'fam-1',
              selectedCandidateIds: const ['c-1'],
            ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('未完成'),
          ),
        ),
      );
    });

    test('不变量：子代串不与第一代父本完全重复', () async {
      final c = container();
      final candidates = [
        doneCandidate('c-1', 'dr-1', mutatedText: 'root:a'),
        doneCandidate('c-2', 'dr-1', mutatedText: 'mut:b'),
        doneCandidate('c-3', 'dr-1', mutatedText: 'mut:c'),
      ];
      final run = await seedFamilyRun(c, deepCandidates: candidates);
      await expectLater(
        c
            .read(exploreRunListNotifierProvider.notifier)
            .createBranch(
              run.id,
              familyId: 'fam-1',
              selectedCandidateIds: const ['c-1'],
            ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('完全重复'),
          ),
        ),
      );
    });

    test('不变量：空选择拒绝', () async {
      final c = container();
      final run = await seedFamilyRun(c);
      await expectLater(
        c
            .read(exploreRunListNotifierProvider.notifier)
            .createBranch(
              run.id,
              familyId: 'fam-1',
              selectedCandidateIds: const [],
            ),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', contains('至少')),
        ),
      );
    });
  });

  group('recordComparison（两两排序）', () {
    Future<ExploreRun> seed(ProviderContainer c) => seedFamilyRun(c);

    test('left/right 胜方 +1.0', () async {
      final c = container();
      final run = await seed(c);
      await c
          .read(exploreRunListNotifierProvider.notifier)
          .recordComparison(
            run.id,
            'ps-1',
            leftParentId: 'rp-1',
            rightParentId: 'rp-2',
            result: ExploreComparisonResult.left,
          );
      var set = (await reload(c, run.id)).parentSetById('ps-1')!;
      expect(set.parents[0].preference, 2.5);
      expect(set.parents[1].preference, 1.0);
      expect(set.comparisons, hasLength(1));
      expect(set.comparisons.single.result, ExploreComparisonResult.left);

      await c
          .read(exploreRunListNotifierProvider.notifier)
          .recordComparison(
            run.id,
            'ps-1',
            leftParentId: 'rp-1',
            rightParentId: 'rp-2',
            result: ExploreComparisonResult.right,
          );
      set = (await reload(c, run.id)).parentSetById('ps-1')!;
      expect(set.parents[0].preference, 2.5);
      expect(set.parents[1].preference, 2.0);
    });

    test('neither 各 -0.25，下限 0.25', () async {
      final c = container();
      final run = await seed(c);
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      // rp-2 起始 1.0：1.0 → 0.75 → 0.5 → 0.25 → 0.25（下限）。
      for (var i = 0; i < 4; i++) {
        await notifier.recordComparison(
          run.id,
          'ps-1',
          leftParentId: 'rp-1',
          rightParentId: 'rp-2',
          result: ExploreComparisonResult.neither,
        );
      }
      final set = (await reload(c, run.id)).parentSetById('ps-1')!;
      expect(set.parents[1].preference, 0.25, reason: 'rp-2 触底 0.25 不再降');
      expect(set.parents[0].preference, 0.5, reason: 'rp-1 从 1.5 连降四次');
      expect(set.comparisons, hasLength(4));
    });

    test('skip 只记录不改偏好', () async {
      final c = container();
      final run = await seed(c);
      await c
          .read(exploreRunListNotifierProvider.notifier)
          .recordComparison(
            run.id,
            'ps-1',
            leftParentId: 'rp-1',
            rightParentId: 'rp-2',
            result: ExploreComparisonResult.skip,
          );
      final set = (await reload(c, run.id)).parentSetById('ps-1')!;
      expect(set.parents[0].preference, 1.5);
      expect(set.parents[1].preference, 1.0);
      expect(set.comparisons, hasLength(1));
      expect(set.comparisons.single.result, ExploreComparisonResult.skip);
    });

    test('比较目标不在父本集抛 StateError', () async {
      final c = container();
      final run = await seed(c);
      await expectLater(
        c
            .read(exploreRunListNotifierProvider.notifier)
            .recordComparison(
              run.id,
              'ps-1',
              leftParentId: 'no-such',
              rightParentId: 'rp-2',
              result: ExploreComparisonResult.left,
            ),
        throwsStateError,
      );
    });
  });

  group('谱系数据组装', () {
    test('exploreFamilyGenerations 按代排序，候选堆/轮次归位', () async {
      final c = container();
      final run = await seedFamilyRun(c);
      // 建分支后追加第二代父本集（无轮次）。
      final newSet = await c
          .read(exploreRunListNotifierProvider.notifier)
          .createBranch(
            run.id,
            familyId: 'fam-1',
            selectedCandidateIds: const ['c-1'],
          );
      final after = await reload(c, run.id);
      final family = after.familyById('fam-1')!;
      final generations = exploreFamilyGenerations(after, family);

      expect(generations, hasLength(2));
      expect(generations[0].parentSet.id, 'ps-1');
      expect(generations[0].parentSet.generation, 1);
      expect(generations[0].rounds.map((r) => r.id), ['dr-1']);
      expect(generations[0].pile.map((p) => p.id), [
        'c-1',
        'c-2',
        'c-3',
      ], reason: '第一代父本集的候选堆 = 其深度轮产出');
      expect(generations[1].parentSet.id, newSet.id);
      expect(generations[1].rounds, isEmpty);
      expect(generations[1].pile, isEmpty);
    });

    test('exploreParentSetRoundsComplete 判定', () async {
      final c = container();
      final run = await seedFamilyRun(c);
      final set = run.parentSetById('ps-1')!;
      expect(exploreParentSetRoundsComplete(run, set), isTrue);

      // 有 pending 候选 → 未完成。
      final withPending = run.copyWith(
        candidates: [
          for (final candidate in run.candidates)
            candidate.id == 'c-3'
                ? candidate.copyWith(
                    generation: const ExploreCandidateGeneration(
                      status: ExploreCandidateGenerationStatus.pending,
                    ),
                  )
                : candidate,
        ],
      );
      expect(exploreParentSetRoundsComplete(withPending, set), isFalse);

      // 轮次仍在 generating → 未完成。
      final generating = run.copyWith(
        rounds: [
          for (final round in run.rounds)
            round.copyWith(status: ExploreRoundStatus.generating),
        ],
      );
      expect(exploreParentSetRoundsComplete(generating, set), isFalse);
    });
  });

  group('setInstanceRollOverride（物化语义）', () {
    const marker = '\uE000';

    test('override 后投影采用变异串，currentRoll 更新', () async {
      final block = PromptBlock(
        id: 'b-1',
        title: '画风池',
        content: 'alpha, beta',
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 9, 1),
      );
      final c = container(blocks: [block]);
      await c.read(promptBlockLibraryNotifierProvider.future);
      PillWorkspaceNotifier.rng = Random(1);
      final notifier = c.read(pillWorkspaceProvider(PillScopes.main).notifier);
      notifier.restoreDocument(
        const PillDocument(
          text: 'base, \uE000',
          instances: {
            marker: PillInstance(
              blockId: 'b-1',
              evolutionEnabled: true,
              settings: PillInstanceSettings(mode: PillRollMode.random),
            ),
          },
        ),
      );
      final before = c.read(pillWorkspaceProvider(PillScopes.main));
      expect(before.projection, isNot('base, mutated text'));

      notifier.setInstanceRollOverride(marker, 'mutated text');
      final after = c.read(pillWorkspaceProvider(PillScopes.main));
      expect(after.document.instances[marker]!.currentRoll, 'mutated text');
      expect(after.projection, 'base, mutated text');
    });

    test('未知 marker 静默忽略，状态不变', () {
      final c = container();
      final notifier = c.read(pillWorkspaceProvider(PillScopes.main).notifier);
      final before = c.read(pillWorkspaceProvider(PillScopes.main));
      notifier.setInstanceRollOverride('no-such', 'x');
      final after = c.read(pillWorkspaceProvider(PillScopes.main));
      expect(after, same(before));
    });
  });

  group('目标实例解析', () {
    test('resolveExploreOverrideMarkerInDocument 优先同 blockId，回退第一个', () {
      const document = PillDocument(
        text: '\uE001 x \uE002',
        instances: {
          '\uE001': PillInstance(
            blockId: 'b-1',
            evolutionEnabled: true,
            settings: PillInstanceSettings(mode: PillRollMode.random),
          ),
          '\uE002': PillInstance(
            blockId: 'b-2',
            evolutionEnabled: true,
            settings: PillInstanceSettings(mode: PillRollMode.random),
          ),
        },
      );
      // 同 blockId 命中第二个实例。
      expect(
        resolveExploreOverrideMarkerInDocument(document, blockId: 'b-2'),
        '\uE002',
      );
      // 无匹配 blockId 回退第一个随机实例。
      expect(
        resolveExploreOverrideMarkerInDocument(document, blockId: 'b-9'),
        '\uE001',
      );
      // 固定模式实例不参与。
      const fixedOnly = PillDocument(
        text: '\uE003',
        instances: {'\uE003': PillInstance(blockId: 'b-1')},
      );
      expect(resolveExploreOverrideMarkerInDocument(fixedOnly), isNull);
    });

    test(
      'roll capture only keeps enabled random evolution instances',
      () async {
        final block = PromptBlock(
          id: 'b-1',
          title: '画风池',
          content: 'alpha, beta',
          createdAt: DateTime.utc(2026, 9, 1),
          updatedAt: DateTime.utc(2026, 9, 1),
        );
        final c = container(blocks: [block]);
        await c.read(promptBlockLibraryNotifierProvider.future);
        c
            .read(pillWorkspaceProvider(PillScopes.main).notifier)
            .restoreDocument(
              const PillDocument(
                text: '\uE000 \uE001 \uE002 \uE003',
                instances: {
                  '\uE000': PillInstance(
                    blockId: 'b-1',
                    evolutionEnabled: true,
                    settings: PillInstanceSettings(mode: PillRollMode.random),
                  ),
                  '\uE001': PillInstance(
                    blockId: 'b-1',
                    settings: PillInstanceSettings(mode: PillRollMode.random),
                  ),
                  '\uE002': PillInstance(
                    blockId: 'b-1',
                    enabled: false,
                    evolutionEnabled: true,
                    settings: PillInstanceSettings(mode: PillRollMode.random),
                  ),
                  '\uE003': PillInstance(
                    blockId: 'b-1',
                    evolutionEnabled: true,
                  ),
                },
              ),
            );

        final snapshot = c.read(_captureExploreRollSnapshotProvider);
        expect(snapshot.instanceRolls.map((roll) => roll.marker), ['\uE000']);
      },
    );

    test('exploreTargetBlockIdForParentSet 取第一个有来源父本的块 id', () {
      final run = ExploreRun(
        id: 'r',
        name: 'n',
        status: ExploreRunStatus.generated,
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 9, 1),
        targetCount: 1,
        recipeSnapshot: const ExploreRecipeSnapshot(
          positive: PillDocument(text: '', instances: {}),
          negative: PillDocument(text: '', instances: {}),
        ),
        paramsSnapshot: snapshot(),
        candidates: const [
          ExploreCandidate(
            id: 'src-1',
            roundId: 'rd',
            rollSnapshot: ExploreRollSnapshot(
              positive: 'p',
              negative: 'n',
              instanceRolls: [
                ExploreInstanceRoll(
                  lane: 'pos',
                  marker: 'm',
                  blockId: 'b-7',
                  blockTitle: 't',
                  rolledText: 'x',
                ),
              ],
            ),
            lineage: ExploreLineage(
              operation: ExploreLineageOperation.basicRoll,
            ),
          ),
        ],
        parentSets: const [
          ExploreParentSet(
            id: 'ps',
            familyId: 'f',
            generation: 1,
            status: ExploreParentSetStatus.active,
            parents: [
              ExploreParent(id: 'p-0', artistString: 'custom'),
              ExploreParent(
                id: 'p-1',
                sourceCandidateId: 'src-1',
                artistString: 'x',
              ),
            ],
          ),
        ],
      );
      final parentSet = run.parentSets.single;
      expect(exploreTargetBlockIdForParentSet(run, parentSet), 'b-7');
      // 无来源父本 → null。
      const customOnly = ExploreParentSet(
        id: 'ps2',
        familyId: 'f',
        generation: 1,
        status: ExploreParentSetStatus.active,
        parents: [ExploreParent(id: 'p-0', artistString: 'custom')],
      );
      expect(exploreTargetBlockIdForParentSet(run, customOnly), isNull);
    });
  });
}
