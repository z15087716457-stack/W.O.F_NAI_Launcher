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
      final first = await notifier.addManualCandidates(
        created.id,
        count: 2,
        firstRollSnapshot: snapshot,
      );
      expect(first, hasLength(2));
      // 首张带 roll 快照，其余为 null；谱系 operation=manual。
      expect(first.first.rollSnapshot, snapshot);
      expect(first[1].rollSnapshot, isNull);
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

  test('updateReview writes heart and preliminary label with clear', () async {
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

    await notifier.updateReview(
      created.id,
      'cand-1',
      preliminaryLabel: ExploreReviewLabel.treasure,
    );
    run = (await c.read(
      exploreRunListNotifierProvider.future,
    )).runById(created.id)!;
    expect(
      run.candidateById('cand-1')!.review.preliminaryLabel,
      ExploreReviewLabel.treasure,
    );

    // 再点同一标签 = 清除。
    await notifier.updateReview(
      created.id,
      'cand-1',
      preliminaryLabel: null,
      clearPreliminaryLabel: true,
    );
    run = (await c.read(
      exploreRunListNotifierProvider.future,
    )).runById(created.id)!;
    final review = run.candidateById('cand-1')!.review;
    expect(review.preliminaryLabel, isNull);
    expect(review.heart, isTrue, reason: '清预标记不动心形');

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
      ExploreReviewLabel? preliminary,
      ExploreCandidateGenerationStatus status =
          ExploreCandidateGenerationStatus.done,
    }) {
      return ExploreCandidate.shell(roundId: 'r').copyWith(
        generation: ExploreCandidateGeneration(status: status),
        review: ExploreCandidateReview(
          heart: heart,
          preliminaryLabel: preliminary,
        ),
      );
    }

    test('each filter matches its semantics', () {
      final plain = candidate();
      final hearted = candidate(heart: true);
      final treasure = candidate(preliminary: ExploreReviewLabel.treasure);
      final failed = candidate(status: ExploreCandidateGenerationStatus.failed);

      expect(
        exploreCandidateMatchesFilter(plain, ExploreGalleryFilter.all),
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
        exploreCandidateMatchesFilter(
          plain,
          ExploreGalleryFilter.pendingReview,
        ),
        isTrue,
      );
      expect(
        exploreCandidateMatchesFilter(
          hearted,
          ExploreGalleryFilter.pendingReview,
        ),
        isFalse,
      );
      expect(
        exploreCandidateMatchesFilter(
          treasure,
          ExploreGalleryFilter.pendingReview,
        ),
        isFalse,
      );
      expect(
        exploreCandidateMatchesFilter(treasure, ExploreGalleryFilter.treasure),
        isTrue,
      );
      expect(
        exploreCandidateMatchesFilter(treasure, ExploreGalleryFilter.special),
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
    });
  });

  group('phase C: formal review lifecycle', () {
    ExploreCandidate doneCandidate(String id, {ExploreReviewLabel? label}) {
      return ExploreCandidate.shell(roundId: 'r-1', id: id).copyWith(
        generation: const ExploreCandidateGeneration(
          status: ExploreCandidateGenerationStatus.done,
          filePath: '/tmp/x.png',
          seed: 1,
        ),
        review: ExploreCandidateReview(label: label),
      );
    }

    Future<ExploreRun> seedGeneratedRun(
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

    test(
      'updateReview writes formal label with timestamp and clears both',
      () async {
        final c = container();
        final notifier = c.read(exploreRunListNotifierProvider.notifier);
        final run = await seedGeneratedRun(c, [doneCandidate('cand-1')]);
        final reviewedAt = DateTime.utc(2026, 9, 1, 9);

        await notifier.updateReview(
          run.id,
          'cand-1',
          label: ExploreReviewLabel.treasure,
          formalReviewedAt: reviewedAt,
        );
        var stored = (await c.read(
          exploreRunListNotifierProvider.future,
        )).runById(run.id)!;
        var review = stored.candidateById('cand-1')!.review;
        expect(review.label, ExploreReviewLabel.treasure);
        expect(review.formalReviewedAt, reviewedAt);

        await notifier.updateReview(run.id, 'cand-1', clearLabel: true);
        stored = (await c.read(
          exploreRunListNotifierProvider.future,
        )).runById(run.id)!;
        review = stored.candidateById('cand-1')!.review;
        expect(review.label, isNull);
        expect(review.formalReviewedAt, isNull, reason: '清标签一并清归类时间');
      },
    );

    test(
      'beginReview: generated/draft enter reviewing, guards reject',
      () async {
        final c = container();
        final notifier = c.read(exploreRunListNotifierProvider.notifier);
        final run = await seedGeneratedRun(c, [doneCandidate('cand-1')]);

        final reviewing = await notifier.beginReview(run.id);
        expect(reviewing.status, ExploreRunStatus.reviewing);

        // 续筛：reviewing 幂等。
        final again = await notifier.beginReview(run.id);
        expect(again.status, ExploreRunStatus.reviewing);

        // 手动候选 run（draft + done 候选）可进入。
        await notifier.overwrite(
          again.copyWith(status: ExploreRunStatus.draft),
        );
        final fromDraft = await notifier.beginReview(run.id);
        expect(fromDraft.status, ExploreRunStatus.reviewing);

        // 无可审查候选拒绝。
        final empty = await createRun(c, name: '空任务');
        expect(
          () => notifier.beginReview(empty.id),
          throwsA(isA<StateError>()),
        );

        // generating/paused/cancelled 不放行。
        await notifier.overwrite(
          fromDraft.copyWith(status: ExploreRunStatus.generating),
        );
        expect(() => notifier.beginReview(run.id), throwsA(isA<StateError>()));
        await notifier.overwrite(
          fromDraft.copyWith(status: ExploreRunStatus.paused),
        );
        expect(() => notifier.beginReview(run.id), throwsA(isA<StateError>()));
      },
    );

    test('completeReview requires reviewing status and all labeled', () async {
      final c = container();
      final notifier = c.read(exploreRunListNotifierProvider.notifier);
      final run = await seedGeneratedRun(c, [
        doneCandidate('cand-1', label: ExploreReviewLabel.treasure),
        doneCandidate('cand-2'),
      ]);

      // 未进筛选态：拒绝。
      expect(await notifier.completeReview(run.id), isFalse);

      await notifier.beginReview(run.id);
      // 还有一张未归类：拒绝且状态不变。
      expect(await notifier.completeReview(run.id), isFalse);
      var stored = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(run.id)!;
      expect(stored.status, ExploreRunStatus.reviewing);

      await notifier.updateReview(
        run.id,
        'cand-2',
        label: ExploreReviewLabel.reject,
        formalReviewedAt: DateTime.utc(2026, 9, 1),
      );
      expect(await notifier.completeReview(run.id), isTrue);
      stored = (await c.read(
        exploreRunListNotifierProvider.future,
      )).runById(run.id)!;
      expect(stored.status, ExploreRunStatus.completed);
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
