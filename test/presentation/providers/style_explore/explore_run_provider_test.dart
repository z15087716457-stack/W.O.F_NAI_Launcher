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

  test('targetCount and params snapshot only editable in draft', () async {
    final c = container();
    final notifier = c.read(exploreRunListNotifierProvider.notifier);
    final created = await createRun(c);

    final updated = await notifier.updateTargetCount(created.id, 25);
    expect(updated.targetCount, 25);

    final synced = await notifier.syncParamsSnapshot(
      created.id,
      snapshot().copyWith(steps: 23, model: 'nai-diffusion-5-full'),
    );
    expect(synced.paramsSnapshot.steps, 23);

    // 非草稿态拒绝修改。
    await notifier.overwrite(
      synced.copyWith(status: ExploreRunStatus.generated),
    );
    expect(
      () => notifier.updateTargetCount(created.id, 50),
      throwsA(isA<StateError>()),
    );
    expect(
      () => notifier.syncParamsSnapshot(created.id, snapshot()),
      throwsA(isA<StateError>()),
    );
  });

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
}
