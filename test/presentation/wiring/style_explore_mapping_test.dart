import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/error_mappers/api_error_mapper.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart'
    as domain;
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_models.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_retry_policy.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_manual_capture.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_roll_capture.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart'
    as ui;
import 'package:nai_launcher/presentation/wiring/style_explore_mapping.dart';
import 'package:nai_launcher/presentation/utils/explore_display_data.dart';

final epoch = DateTime(2026, 10, 12, 12);

domain.ExploreRun runFixture() =>
    domain.ExploreRun.create(
      id: 'run',
      name: 'Test',
      createdAt: epoch,
      recipeSnapshot: recipeFixture,
      paramsSnapshot: domain.ExploreParamsSnapshot.fromImageParams(
        const ImageParams(),
      ),
      targetCount: 3,
    ).copyWith(
      rounds: [
        domain.ExploreRound(
          id: 'basic',
          number: 1,
          phase: domain.ExploreRoundPhase.manual,
          status: domain.ExploreRoundStatus.generated,
          createdAt: epoch,
          targetCount: 2,
          candidateIds: ['a', 'b'],
        ),
        domain.ExploreRound(
          id: 'deep',
          number: 2,
          phase: domain.ExploreRoundPhase.deep,
          status: domain.ExploreRoundStatus.generated,
          createdAt: epoch.add(const Duration(minutes: 1)),
          targetCount: 1,
          candidateIds: ['child'],
          parentSetId: 'set',
          familyId: 'line',
          generation: 2,
        ),
        domain.ExploreRound(
          id: 'basic-two',
          number: 3,
          phase: domain.ExploreRoundPhase.basic,
          status: domain.ExploreRoundStatus.generated,
          createdAt: epoch.add(const Duration(minutes: 2)),
          targetCount: 0,
        ),
      ],
      candidates: [
        domain.ExploreCandidate(
          id: 'a',
          roundId: 'basic',
          number: 7,
          rollSnapshot: const domain.ExploreRollSnapshot(
            positive: 'prefix, 1.2::artist:a, artist:b::, suffix',
            negative: 'negative',
            instanceRolls: [
              domain.ExploreInstanceRoll(
                lane: 'pos',
                marker: '\ue000',
                blockId: 'block',
                blockTitle: 'Captured name',
                rolledText: '1.2::artist:a, artist:b::',
              ),
            ],
          ),
          generation: const domain.ExploreCandidateGeneration(
            status: domain.ExploreCandidateGenerationStatus.done,
            filePath: 'a.png',
            seed: 42,
            elapsedMs: 300,
          ),
          review: const domain.ExploreCandidateReview(heart: true),
          lineage: const domain.ExploreLineage(
            operation: domain.ExploreLineageOperation.manual,
          ),
          paramsSnapshot: domain.ExploreParamsSnapshot.fromImageParams(
            const ImageParams(width: 1024, height: 1536, steps: 20),
          ),
        ),
        const domain.ExploreCandidate(
          id: 'b',
          roundId: 'basic',
          number: 8,
          generation: domain.ExploreCandidateGeneration(
            status: domain.ExploreCandidateGenerationStatus.failed,
            error: 'failure',
          ),
          lineage: domain.ExploreLineage(
            operation: domain.ExploreLineageOperation.manual,
          ),
        ),
        const domain.ExploreCandidate(
          id: 'child',
          roundId: 'deep',
          number: 9,
          rollSnapshot: domain.ExploreRollSnapshot(
            positive: 'artist:c',
            negative: '',
          ),
          generation: domain.ExploreCandidateGeneration(
            status: domain.ExploreCandidateGenerationStatus.done,
          ),
          lineage: domain.ExploreLineage(
            operation: domain.ExploreLineageOperation.mutation,
            generation: 2,
            parentCandidateIds: ['a'],
            mutatedText: 'artist:c',
          ),
        ),
      ],
      families: [
        domain.ExploreFamily(
          id: 'line',
          name: 'Line',
          createdAt: epoch,
          rootParentSetId: 'set',
          activeParentSetId: 'set',
        ),
      ],
      parentSets: const [
        domain.ExploreParentSet(
          id: 'set',
          familyId: 'line',
          generation: 1,
          status: domain.ExploreParentSetStatus.active,
          parents: [
            domain.ExploreParent(
              id: 'parent',
              sourceCandidateId: 'a',
              artistString: '1.2::artist:a, artist:b::',
              preference: 2,
            ),
          ],
        ),
      ],
    );

const recipeFixture = domain.ExploreRecipeSnapshot(
  positive: PillDocument(text: '', instances: {}),
  negative: PillDocument(text: '', instances: {}),
);

void main() {
  test(
    'candidate mapping keeps stable numbers, request snapshots and atomic weights',
    () {
      final run = runFixture();
      final library = PromptBlockLibraryState(
        blocks: [
          PromptBlock.create(
            id: 'block',
            title: 'Renamed',
            content: '',
            color: '#FF112233',
            iconName: 'star',
          ),
        ],
        folders: [],
      );
      final mapped = styleExploreCandidate(
        run,
        run.candidates.first,
        library: library,
      );
      expect(mapped.number, 7);
      expect((mapped.width, mapped.height, mapped.steps), (1024, 1536, 20));
      expect(mapped.draws.single.title, 'Captured name');
      expect(mapped.draws.single.atoms.single.raw, '1.2::artist:a, artist:b::');
      expect(mapped.draws.single.atoms.single.weight, '1.2');
      expect(mapped.hits.single.color, const Color(0xff112233));
      expect(
        mapped.prompt.substring(
          mapped.hits.single.start,
          mapped.hits.single.end,
        ),
        '1.2::artist:a, artist:b::',
      );
      expect(mapped.inEvolution, isTrue);
      expect(mapped.seed, 42);
      expect(mapped.elapsed, const Duration(milliseconds: 300));
      expect(mapped.thumb, isA<ResizeImage>());
    },
  );

  test('a candidate the stop left behind says why, as the error card does', () {
    final run = runFixture();
    for (final locale in const [Locale('zh'), Locale('en')]) {
      final l = lookupAppLocalizations(locale);
      String? reason(String? error) => styleExploreCandidate(
        run,
        run.candidates[1].copyWith(
          generation: domain.ExploreCandidateGeneration(
            status: domain.ExploreCandidateGenerationStatus.failed,
            error: error,
          ),
        ),
        l10n: l,
      ).error;
      for (final (failure, title, hint) in [
        ('API_ERROR_401|Unauthorized', l.api_error_401, l.api_error_401_hint),
        (
          'API_ERROR_402|Payment required',
          l.api_error_402,
          l.api_error_402_hint,
        ),
        (
          'API_ERROR_HTTP_403|Forbidden',
          l.api_error_403,
          l.explore_error403Hint,
        ),
        (
          'API_ERROR_HTTP_404|Not Found',
          l.api_error_404,
          l.explore_error404Hint,
        ),
      ]) {
        expect(
          reason(generationStatusStoppedError(failure)),
          '$title\n$hint',
          reason: '$locale $failure',
        );
      }
      // The explore's own button, not the page's Retry.
      expect(
        reason(
          generationConcurrencyStoppedError(
            'API_ERROR_429|Concurrent generation is locked',
          ),
        ),
        '${l.api_error_429}\n${l.explore_concurrencyStoppedHint}',
      );
    }
    final zh = lookupAppLocalizations(const Locale('zh'));
    expect(
      styleExploreCandidate(
        run,
        run.candidates[1].copyWith(
          generation: domain.ExploreCandidateGeneration(
            status: domain.ExploreCandidateGenerationStatus.failed,
            error: generationStatusStoppedError('API_ERROR_402|x'),
          ),
        ),
        l10n: zh,
      ).error,
      '余额不足\nAnlas 余额不足，请充值后重试',
    );
  });

  test('a candidate that failed on its own says why too, as the error card '
      'does', () {
    final run = runFixture();
    final request = RequestOptions(path: '/ai/generate-image-stream');
    DioException rejected(int status) => DioException.badResponse(
      statusCode: status,
      requestOptions: request,
      response: Response<void>(requestOptions: request, statusCode: status),
    );
    for (final locale in const [Locale('zh'), Locale('en')]) {
      final l = lookupAppLocalizations(locale);
      String? reason(String? error) => styleExploreCandidate(
        run,
        run.candidates[1].copyWith(
          generation: domain.ExploreCandidateGeneration(
            status: domain.ExploreCandidateGenerationStatus.failed,
            error: error,
          ),
        ),
        l10n: l,
      ).error;
      // What the explore keeps when a candidate's own request fails: the
      // stream service's text, wrapped by the generation in `Exception: `.
      String kept(DioException error) =>
          'Exception: ${ApiErrorMapper.formatDioError(error)}';
      for (final (error, title, hint) in [
        (kept(rejected(400)), l.api_error_400, l.explore_error400Hint),
        (kept(rejected(500)), l.api_error_500, l.api_error_500_hint),
        (kept(rejected(502)), l.api_error_500, l.api_error_500_hint),
        (kept(rejected(503)), l.api_error_503, l.api_error_503_hint),
        (
          kept(
            DioException.connectionError(
              requestOptions: request,
              reason: 'Connection refused',
            ),
          ),
          l.api_error_network,
          l.api_error_network_hint,
        ),
        (
          const SocketException(
            'Connection reset by peer',
            osError: OSError('Connection reset by peer', 54),
          ).toString(),
          l.api_error_network,
          l.api_error_network_hint,
        ),
        (
          kept(
            DioException.receiveTimeout(
              timeout: const Duration(seconds: 30),
              requestOptions: request,
            ),
          ),
          l.api_error_timeout,
          l.api_error_timeout_hint,
        ),
        // Kept by an explore from before the stop came in.
        (
          'API_ERROR_402|Payment required',
          l.api_error_402,
          l.api_error_402_hint,
        ),
      ]) {
        expect(reason(error), '$title\n$hint', reason: '$locale $error');
      }
      // What the error card cannot name either is shown as it was.
      for (final error in [
        'Exception: API_ERROR_HTTP_409|Conflict',
        'Exception: No final image received from stream',
        'generation failed',
        'no image produced',
        'no random instance for deep target',
        'cancelled',
        'interrupted',
        null,
      ]) {
        expect(reason(error), error, reason: '$locale $error');
      }
    }
    final zh = lookupAppLocalizations(const Locale('zh'));
    expect(
      styleExploreFailure(zh, 'Exception: API_ERROR_500|Internal Server Error'),
      '服务器错误\nNovelAI 服务器出现问题，请稍后重试',
    );
  });

  test('400, 403, 404 and a waited-out 429 send the user to Retry failed '
      "candidates, not Generate or the page's Retry", () {
    // Retry failed candidates draws those candidates again and sends them
    // with the prompt, parameters, model and account as they are now, so
    // what these reasons ask to fix takes effect there.
    const generate = {
      'en': 'then click Generate',
      'ja': '「生成」を押してください',
      'ko': '“생성”을 누르세요',
      'zh': '再点“生成”',
      'zh-TW': '再點“生成”',
    };
    String retryFailed(String tag, AppLocalizations l) => switch (tag) {
      'en' => 'then click "${l.explore_retryFailed}"',
      'ja' => '「${l.explore_retryFailed}」を押してください',
      'ko' => '“${l.explore_retryFailed}”를 누르세요',
      'zh' => '再点“${l.explore_retryFailed}”',
      _ => '再點“${l.explore_retryFailed}”',
    };
    String pageRetry(String tag, AppLocalizations l) => switch (tag) {
      'en' => 'then click ${l.gen_retry}',
      'ja' => '「${l.gen_retry}」を押してください',
      'ko' => '“${l.gen_retry}”를 누르세요',
      'zh' => '再点“${l.gen_retry}”',
      _ => '再點“${l.gen_retry}”',
    };
    for (final locale in AppLocalizations.supportedLocales) {
      final tag = locale.toLanguageTag();
      final l = lookupAppLocalizations(locale);
      for (final (error, title) in [
        // 400 fails only its own candidate.
        ('Exception: API_ERROR_400|Bad request', l.api_error_400),
        // 403 and 404 stop the whole explore.
        (
          generationStatusStoppedError('API_ERROR_HTTP_403|Forbidden'),
          l.api_error_403,
        ),
        (
          generationStatusStoppedError('API_ERROR_HTTP_404|Not Found'),
          l.api_error_404,
        ),
      ]) {
        final [shownTitle, hint] = styleExploreFailure(l, error)!.split('\n');
        expect(shownTitle, title, reason: '$tag $error');
        expect(hint, endsWith(retryFailed(tag, l)), reason: '$tag $hint');
        expect(hint, isNot(contains(generate[tag]!)), reason: '$tag $hint');
      }
      // A 429 that waited out its time stops the explore too; Retry failed
      // candidates goes on with the candidates it left, after the other
      // generation is done. The page's card names its own Retry there.
      final [shownTitle, hint] = styleExploreFailure(
        l,
        generationConcurrencyStoppedError(
          'API_ERROR_429|Concurrent generation is locked',
        ),
      )!.split('\n');
      expect(shownTitle, l.api_error_429, reason: tag);
      expect(hint, contains(retryFailed(tag, l)), reason: '$tag $hint');
      expect(hint, isNot(contains(pageRetry(tag, l))), reason: '$tag $hint');
      expect(l.gen_concurrencyStopped, contains(pageRetry(tag, l)));
    }
    final zh = lookupAppLocalizations(const Locale('zh'));
    expect(
      styleExploreFailure(zh, 'Exception: API_ERROR_400|Bad request'),
      '请求无效\n无法生成：NovelAI 不接受这组设置。请检查提示词和参数，改好后再点“重试失败的候选”',
    );
    final en = lookupAppLocalizations(const Locale('en'));
    expect(
      styleExploreFailure(
        en,
        generationStatusStoppedError('API_ERROR_HTTP_404|Not Found'),
      ),
      "Not found\nCan't generate: the server doesn't have this endpoint or "
      'model. Check the API address and the model, then click "Retry failed '
      'candidates"',
    );
    final waitedOut = generationConcurrencyStoppedError(
      'API_ERROR_429|Concurrent generation is locked',
    );
    expect(
      styleExploreFailure(zh, waitedOut),
      '并发限制\n继续等待生成名额会超出本轮累计 90 秒的上限，后续请求已停止。'
      '请稍后再点“重试失败的候选”。',
    );
    expect(
      styleExploreFailure(en, waitedOut),
      'Concurrency limit reached\nAnother wait for a generation slot would '
      'exceed the 90-second total for this run. No further requests were sent. '
      'Wait a moment, then click "Retry failed candidates".',
    );
  });

  test(
    'evolution uses the parent-set generation, not the child lineage number',
    () {
      final view = styleExploreRunView(runFixture());
      expect(view.candidates.last.lineId, 'line');
      expect(view.candidates.last.generation, 1);
      expect(view.candidates.last.op, ui.ExploreOp.mutation);
      expect(view.candidates.last.changedAtoms.single.raw, 'artist:c');
      expect(view.lines.single.current.childKeys, ['child']);
      expect(view.lines.single.current.parents.single.preference, 2);
      expect(
        view.rounds
            .where((round) => round.kind == ui.ExploreRoundKind.basic)
            .map((round) => round.number),
        [1, 2],
      );
      expect(styleExploreRunSummary(runFixture()).total, 2);
    },
  );

  test('only a pending slot in the owned run is reported as running', () {
    final run = runFixture().copyWith(
      candidates: [
        runFixture().candidates.first.copyWith(
          generation: const domain.ExploreCandidateGeneration(
            status: domain.ExploreCandidateGenerationStatus.pending,
          ),
        ),
        runFixture().candidates[1],
      ],
    );
    const capture = ExploreManualCaptureState(
      armed: true,
      runId: 'run',
      candidateIds: ['a', 'b'],
    );
    final view = styleExploreRunView(run, capture: capture);
    expect(view.candidates.first.state, ui.ExploreCandidateState.running);
    expect(view.candidates.last.state, ui.ExploreCandidateState.failed);
    expect(view.progress?.done, 1);
    expect(view.progress?.total, 2);
    expect(
      styleExploreRunSummary(run, capture: capture).state,
      ui.ExploreRunState.running,
    );
    expect(
      styleExploreRunningCandidate(
        run.copyWith(id: 'other'),
        const ExploreRunRunnerState(),
        capture,
      ),
      isNull,
    );
  });

  test(
    'variable order follows prompt markers and marks every genetic block',
    () {
      const settings = PillInstanceSettings(mode: PillRollMode.random);
      const document = PillDocument(
        text: '\ue001, \ue000',
        instances: {
          '\ue000': PillInstance(
            blockId: 'first',
            evolutionEnabled: true,
            settings: settings,
          ),
          '\ue001': PillInstance(
            blockId: 'second',
            evolutionEnabled: true,
            settings: settings,
          ),
        },
      );
      final variables = styleExploreVariables(
        document,
        null,
        missingLabel: 'Missing',
      );
      expect(
        styleExploreVariableInstances(document).map((entry) => entry.key),
        ['\ue001', '\ue000'],
      );
      expect(variables.map((variable) => variable.evolution), [true, true]);
      expect(variables.every((variable) => variable.missing), isTrue);
    },
  );

  test(
    'ordinary random and sequential variables do not enter genetic helpers',
    () {
      const document = PillDocument(
        text: '\ue003, \ue001, \ue002, \ue004, \ue005, \ue006',
        instances: {
          '\ue000': PillInstance(
            blockId: 'orphan',
            settings: PillInstanceSettings(mode: PillRollMode.random),
          ),
          '\ue001': PillInstance(
            blockId: 'genetic-random',
            evolutionEnabled: true,
            settings: PillInstanceSettings(mode: PillRollMode.random),
          ),
          '\ue002': PillInstance(
            blockId: 'ordinary-sequence',
            settings: PillInstanceSettings(mode: PillRollMode.sequential),
          ),
          '\ue003': PillInstance(
            blockId: 'ordinary-random',
            locked: true,
            settings: PillInstanceSettings(mode: PillRollMode.random),
          ),
          '\ue004': PillInstance(
            blockId: 'genetic-sequence',
            evolutionEnabled: true,
            settings: PillInstanceSettings(mode: PillRollMode.sequential),
          ),
          '\ue005': PillInstance(blockId: 'fixed', evolutionEnabled: true),
          '\ue006': PillInstance(
            blockId: 'disabled',
            enabled: false,
            settings: PillInstanceSettings(mode: PillRollMode.random),
          ),
        },
      );
      expect(
        styleExploreVariableInstances(document).map((e) => e.value.blockId),
        [
          'ordinary-random',
          'genetic-random',
          'ordinary-sequence',
          'genetic-sequence',
        ],
      );
      final variables = styleExploreVariables(
        document,
        null,
        missingLabel: 'Missing',
      );
      expect(variables.map((v) => v.evolution), [false, true, false, true]);
      expect(exploreGeneticInstances(document).map((e) => e.value.blockId), [
        'genetic-random',
        'genetic-sequence',
      ]);
      expect(resolveExploreOverrideMarkerInDocument(document), '\ue001');
    },
  );

  test(
    'shared artist helpers retain weighted atomic text and stable deduplication',
    () {
      final candidate = runFixture().candidates.first;
      final other = candidate.copyWith(
        rollSnapshot: const domain.ExploreRollSnapshot(
          positive: '1.2::artist:a, artist:b::, artist:c',
          negative: '',
        ),
      );
      expect(exploreMergedArtistAtoms([candidate, other]), [
        '1.2::artist:a, artist:b::',
        'artist:c',
      ]);
      expect(parseExploreArtistAtom('1.2::artist:a, artist:b::'), (
        weight: '1.2',
        text: 'a, artist:b',
      ));
      expect(
        exploreNewLineageAtoms(runFixture(), runFixture().candidates.last),
        ['artist:c'],
      );
    },
  );

  test(
    'shared prompt matching preserves repeated block ranges and excludes negative draws',
    () {
      const snapshot = domain.ExploreRollSnapshot(
        positive: 'x, artist:a, y, artist:a',
        negative: '',
        instanceRolls: [
          domain.ExploreInstanceRoll(
            lane: 'pos',
            marker: '\ue000',
            blockId: 'block',
            blockTitle: 'Block',
            rolledText: 'artist:a',
          ),
          domain.ExploreInstanceRoll(
            lane: 'neg',
            marker: '\ue001',
            blockId: 'negative',
            blockTitle: 'Negative',
            rolledText: 'artist:a',
          ),
        ],
      );
      final matches = explorePromptMatches(snapshot);
      expect(matches.map((match) => (match.start, match.end, match.blockId)), [
        (3, 11, 'block'),
        (16, 24, 'block'),
      ]);
    },
  );

  test('block folders retain tree order and depth', () {
    final library = PromptBlockLibraryState(
      blocks: [],
      folders: [
        PromptBlockFolder.create(id: 'b', name: 'B', sortOrder: 2),
        PromptBlockFolder.create(id: 'child', parentId: 'a', name: 'Child'),
        PromptBlockFolder.create(id: 'a', name: 'A', sortOrder: 1),
      ],
    );
    final folders = styleExploreBlockFolders(library, 'Library');
    expect(folders.map((folder) => folder.id), [null, 'a', 'child', 'b']);
    expect(folders.map((folder) => folder.depth), [0, 0, 1, 0]);
  });

  test(
    'generate phase separates owned manual capture, unrelated work and cooldown',
    () {
      ui.ExploreGenerate map({
        ExploreManualCaptureState capture = const ExploreManualCaptureState(),
        bool busy = false,
        int cooldown = 0,
      }) => styleExploreGenerate(
        count: 10,
        cost: 20,
        balance: 5,
        generation: const ImageGenerationState(),
        runner: const ExploreRunRunnerState(),
        capture: capture,
        activeRunId: 'run',
        cooldown: cooldown,
        otherBusy: busy,
      );
      expect(map().phase, ui.ExploreGeneratePhase.ready);
      expect(map().insufficient, isTrue);
      expect(map(cooldown: 3).phase, ui.ExploreGeneratePhase.cooldown);
      expect(map(busy: true).phase, ui.ExploreGeneratePhase.busy);
      expect(
        map(
          capture: const ExploreManualCaptureState(armed: true, runId: 'run'),
        ).phase,
        ui.ExploreGeneratePhase.running,
      );
    },
  );
}
