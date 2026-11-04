import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/network/dio_client.dart';
import 'package:nai_launcher/core/network/error_mappers/api_error_mapper.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_generation_api_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/image/image_stream_chunk.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/services/explore_run_image_store.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_retry_policy.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/locale_provider.dart';
import 'package:nai_launcher/presentation/providers/notification_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_roll_coordinator.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/deep_round_roll_guard.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';

import '../../../helpers/app_logger_test_isolation.dart';

class _Api extends Mock implements NAIImageGenerationApiService {}

class _Gallery extends LocalGalleryNotifier {
  @override
  LocalGalleryState build() => const LocalGalleryState(isInitialized: true);

  @override
  Future<int> addNewlySavedImages(List<String> filePaths) async =>
      filePaths.length;
}

/// The pool the deep round draws its children from.
class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async => PromptBlockLibraryState(
    blocks: [
      PromptBlock(
        id: 'b-1',
        title: 'pool',
        content: 'alpha, beta, gamma',
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 9, 1),
      ),
    ],
    folders: const [],
  );
}

/// A local upscale that can be switched on: while it runs, the native
/// generation turns every new request away.
class _Upscale extends LocalUpscaleTask {
  @override
  LocalUpscaleTaskState build() => const LocalUpscaleTaskState();

  void run() => state = const LocalUpscaleTaskState(running: true);
}

class _Locale extends LocaleNotifier {
  @override
  Locale build() => const Locale('zh');
}

class _Passed extends ErrorInterceptorHandler {
  DioException? error;
  @override
  void next(DioException err) => error = err;
}

final _request = RequestOptions(path: '/ai/generate-image');

/// A request NovelAI rejects with [status], as the stream service words it.
ImageStreamChunk _streamRejected(int status) => ImageStreamChunk.error(
  ApiErrorMapper.formatDioError(
    DioException.badResponse(
      statusCode: status,
      requestOptions: _request,
      response: Response<void>(requestOptions: _request, statusCode: status),
    ),
  ),
);

/// The same without streaming: dio's error as the app's error interceptor
/// hands it on, worded in Chinese ("Anlas 不足").
DioException _rejected(int status) {
  final container = ProviderContainer(
    overrides: [localeNotifierProvider.overrideWith(_Locale.new)],
  );
  addTearDown(container.dispose);
  final handler = _Passed();
  container
      .read(Provider((ref) => ErrorInterceptor(ref)))
      .onError(
        DioException.badResponse(
          statusCode: status,
          requestOptions: _request,
          // A non-stream request asks for bytes, so the body is never a map.
          response: Response<Uint8List>(
            requestOptions: _request,
            statusCode: status,
            data: Uint8List(0),
          ),
        ),
        handler,
      );
  return handler.error!;
}

const _streamingNotAllowed = 'Streaming is not allowed for this request';

const _marker = '';

/// A random block instance with evolution on: the deep round's target.
const _evolving = PillInstance(
  blockId: 'b-1',
  evolutionEnabled: true,
  settings: PillInstanceSettings(mode: PillRollMode.random),
);

Uint8List _png() =>
    Uint8List.fromList(img.encodePng(img.Image(width: 64, height: 96)));

/// One app session: the real explore runner and native generation, with a
/// fake NovelAI and a retry clock that only records its waits.
class _Explore {
  _Explore({
    required this.storage,
    required this.imageRoot,
    required this.streamed,
  }) {
    when(() => api.generateImageStream(any())).thenAnswer((_) {
      if (!streamed) {
        return Stream.value(ImageStreamChunk.error(_streamingNotAllowed));
      }
      final status = answer(++requests);
      return Stream.value(
        status == null
            ? ImageStreamChunk.complete(_png())
            : _streamRejected(status),
      );
    });
    when(
      () => api.generateImage(any(), onProgress: any(named: 'onProgress')),
    ).thenAnswer((_) async {
      final status = answer(++requests);
      if (status != null) throw _rejected(status);
      return ([_png()], <int, String>{});
    });
    when(() => api.cancelGeneration()).thenReturn(null);
    container = ProviderContainer(
      overrides: [
        naiImageGenerationApiServiceProvider.overrideWithValue(api),
        localGalleryNotifierProvider.overrideWith(_Gallery.new),
        localUpscaleTaskProvider.overrideWith(_Upscale.new),
        styleExploreRunStorageProvider.overrideWithValue(storage),
        exploreRunImageStoreProvider.overrideWithValue(
          ExploreRunImageStore(rootPathResolver: () async => imageRoot),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
        generationRetryDelayProvider.overrideWithValue((delay, cancelled) {
          delays.add(delay);
          return Future<void>.value();
        }),
      ],
    );
  }

  final StyleExploreRunStorage storage;
  final String imageRoot;

  /// Requests go out with streaming, or NovelAI refuses streaming and they
  /// go out without.
  final bool streamed;
  final api = _Api();
  late final ProviderContainer container;
  final delays = <Duration>[];

  /// Requests that reached NovelAI (a refused stream does not count).
  int requests = 0;

  /// The status NovelAI rejects the n-th request with; null makes an image.
  int? Function(int request) answer = (_) => null;

  ExploreRunRunner get runner =>
      container.read(exploreRunRunnerProvider.notifier);

  Future<void> prepare() async {
    await container
        .read(notificationSettingsNotifierProvider.notifier)
        .setSoundEnabled(false);
    await container
        .read(imageSaveSettingsNotifierProvider.notifier)
        .setAutoSave(false);
    container.read(localUpscaleTaskProvider);
    await container.read(exploreRunRunnerProvider.notifier).ready;
  }

  Future<ExploreRun> seedRun(int candidates) async {
    final run = ExploreRun.create(
      name: 'stop',
      recipeSnapshot: ExploreRecipeSnapshot(
        positive: PillDocument.empty(),
        negative: PillDocument.empty(),
      ),
      paramsSnapshot: ExploreParamsSnapshot.fromImageParams(
        const ImageParams(),
      ),
      targetCount: candidates,
    );
    await storage.putRun(run);
    return run;
  }

  /// An explore with one evolution line whose first generation has a single
  /// parent, ready for a deep round.
  Future<ExploreRun> seedLine() async {
    final run =
        ExploreRun.create(
          name: 'line',
          recipeSnapshot: const ExploreRecipeSnapshot(
            positive: PillDocument(
              text: 'base',
              instances: {_marker: _evolving},
            ),
            negative: PillDocument(text: 'neg', instances: {}),
          ),
          paramsSnapshot: ExploreParamsSnapshot.fromImageParams(
            const ImageParams(),
          ),
          targetCount: 2,
        ).copyWith(
          status: ExploreRunStatus.generated,
          parentSets: const [
            ExploreParentSet(
              id: 'ps-1',
              familyId: 'fam-1',
              generation: 1,
              status: ExploreParentSetStatus.active,
              parents: [ExploreParent(id: 'par-1', artistString: 'alpha')],
            ),
          ],
          families: [
            ExploreFamily(
              id: 'fam-1',
              name: 'line',
              createdAt: DateTime.utc(2026, 9, 1),
              rootParentSetId: 'ps-1',
              activeParentSetId: 'ps-1',
            ),
          ],
        );
    await storage.putRun(run);
    return run;
  }

  Future<ExploreRun> reload(String id) async => (await container.read(
    exploreRunListNotifierProvider.future,
  )).runById(id)!;

  void dispose() => container.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDir;
  late Directory imageDir;
  late StyleExploreRunStorage runStorage;

  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    registerFallbackValue(const ImageParams());
    hiveDir = await Directory.systemTemp.createTemp('explore_stop_hive_');
    imageDir = await Directory.systemTemp.createTemp('explore_stop_img_');
    Hive.init(hiveDir.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
    await Hive.openBox(StorageKeys.statisticsCacheBox);
    await Hive.openBox<String>(StorageKeys.promptWorkspaceStateBox);
    runStorage = StyleExploreRunStorage();
    await runStorage.init();
  });

  setUp(() async {
    await runStorage.clear();
    await Hive.box(StorageKeys.settingsBox).clear();
    await Hive.box<String>(StorageKeys.promptWorkspaceStateBox).clear();
    PillWorkspaceNotifier.rng = Random();
    ExploreRunRunner.deepRng = Random(42);
    PillRollCoordinator.resetRollSuppression();
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  tearDownAll(() async {
    await runStorage.close();
    await Hive.close();
    if (await hiveDir.exists()) await hiveDir.delete(recursive: true);
    if (await imageDir.exists()) await imageDir.delete(recursive: true);
    await AppLoggerTestIsolation.tearDown();
  });

  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    group('${platform.name}:', () {
      late _Explore explore;

      Future<_Explore> start({bool streamed = true}) async {
        debugDefaultTargetPlatformOverride = platform;
        explore = _Explore(
          storage: runStorage,
          imageRoot: imageDir.path,
          streamed: streamed,
        );
        await explore.prepare();
        return explore;
      }

      tearDown(() => explore.dispose());

      for (final streamed in [true, false]) {
        final way = streamed ? 'stream' : 'non-stream';

        for (final status in [401, 402, 403, 404]) {
          test('$status on the second of four candidates ($way): the explore '
              'stops and the rest is never sent', () async {
            final explore = await start(streamed: streamed);
            explore.answer = (request) => request == 2 ? status : null;
            final run = await explore.seedRun(4);

            expect(await explore.runner.start(run.id), isTrue);

            expect(explore.requests, 2);
            expect(explore.delays, isEmpty);
            final after = await explore.reload(run.id);
            expect(after.status, ExploreRunStatus.generated);
            expect(after.pendingCandidates, isEmpty);
            expect(after.rounds.single.status, ExploreRoundStatus.generated);
            final [first, stopped, ...unsent] = after.candidates;
            // What came out before the stop stays.
            expect(
              first.generation.status,
              ExploreCandidateGenerationStatus.done,
            );
            expect(File(first.generation.filePath!).existsSync(), isTrue);
            expect(unsent, hasLength(2));
            for (final candidate in [stopped, ...unsent]) {
              final error = candidate.generation.error!;
              expect(
                candidate.generation.status,
                ExploreCandidateGenerationStatus.failed,
              );
              expect(isGenerationStatusStopped(error), isTrue, reason: error);
              expect(generationFailureStatus(error), status, reason: error);
            }
            expect(
              unsent.map((candidate) => candidate.generation.error),
              everyElement(stopped.generation.error),
            );
            expect(
              explore.container.read(exploreRunRunnerProvider).isRunning,
              isFalse,
            );
            expect(PillRollCoordinator.isRollSuppressed, isFalse);
          });
        }

        test('400 on the second candidate ($way): only that one fails, the '
            'rest go on', () async {
          final explore = await start(streamed: streamed);
          explore.answer = (request) => request == 2 ? 400 : null;
          final run = await explore.seedRun(4);

          expect(await explore.runner.start(run.id), isTrue);

          expect(explore.requests, 4);
          final [first, failed, third, fourth] = (await explore.reload(
            run.id,
          )).candidates;
          for (final candidate in [first, third, fourth]) {
            expect(
              candidate.generation.status,
              ExploreCandidateGenerationStatus.done,
            );
          }
          final error = failed.generation.error!;
          expect(
            failed.generation.status,
            ExploreCandidateGenerationStatus.failed,
          );
          expect(isGenerationRunStopped(error), isFalse, reason: error);
          expect(generationFailureStatus(error), 400, reason: error);
        });

        test(
          'a 429 that outlasts the 90 s ($way): the explore stops',
          () async {
            final explore = await start(streamed: streamed);
            explore.answer = (request) => request >= 2 ? 429 : null;
            final run = await explore.seedRun(4);

            expect(await explore.runner.start(run.id), isTrue);

            // The second candidate waited 3, 6, 12, 24, 30 and 15 s, then
            // stopped; the third and fourth were never sent.
            expect(explore.delays, [
              for (final seconds in [3, 6, 12, 24, 30, 15])
                Duration(seconds: seconds),
            ]);
            expect(explore.requests, 1 + 7);
            final [first, stopped, ...unsent] = (await explore.reload(
              run.id,
            )).candidates;
            expect(
              first.generation.status,
              ExploreCandidateGenerationStatus.done,
            );
            expect(unsent, hasLength(2));
            for (final candidate in [stopped, ...unsent]) {
              final error = candidate.generation.error!;
              expect(
                candidate.generation.status,
                ExploreCandidateGenerationStatus.failed,
              );
              expect(
                isGenerationConcurrencyStopped(error),
                isTrue,
                reason: error,
              );
            }
          },
        );
      }

      // The candidates a stop left behind are failed, not dropped: "Retry
      // failed candidates" goes on with them once the cause is sorted out.
      for (final streamed in [true, false]) {
        final way = streamed ? 'stream' : 'non-stream';
        for (final (stop, answer) in [
          for (final status in [401, 402, 403, 404])
            ('$status', (int request) => request == 2 ? status : null),
          (
            'a 429 that outlasts the 90 s',
            (int request) => request >= 2 ? 429 : null,
          ),
        ]) {
          test('after a stop at $stop ($way), Retry failed candidates sends '
              'the stopped and the unsent ones, and only those', () async {
            final explore = await start(streamed: streamed);
            explore.answer = answer;
            final run = await explore.seedRun(4);
            await explore.runner.start(run.id);
            final stopped = await explore.reload(run.id);
            final [made, ...failed] = stopped.candidates;
            expect(
              made.generation.status,
              ExploreCandidateGenerationStatus.done,
            );
            expect(failed, hasLength(3));
            for (final candidate in failed) {
              expect(
                candidate.generation.status,
                ExploreCandidateGenerationStatus.failed,
              );
              expect(
                isGenerationRunStopped(candidate.generation.error),
                isTrue,
                reason: candidate.generation.error,
              );
            }
            final sent = explore.requests;

            // Topped up, signed in again, model fixed, the account free.
            explore.answer = (_) => null;
            expect(await explore.runner.retryFailed(run.id), isTrue);

            // One request for each failed candidate, none for the one made.
            expect(explore.requests - sent, 3);
            final after = await explore.reload(run.id);
            expect(after.status, ExploreRunStatus.generated);
            expect(after.failedCount, 0);
            expect(after.generatedCount, 4);
            expect(after.rounds, hasLength(1));
            // The same candidates, in the same round; the one made is kept.
            expect(
              after.candidates.map((candidate) => candidate.id),
              stopped.candidates.map((candidate) => candidate.id),
            );
            expect(after.candidates.first.generation, made.generation);
            for (final candidate in after.candidates.skip(1)) {
              expect(
                candidate.generation.status,
                ExploreCandidateGenerationStatus.done,
              );
              expect(candidate.generation.error, isNull);
              expect(File(candidate.generation.filePath!).existsSync(), isTrue);
            }
          });
        }
      }

      test('children of an evolution line stop the same way', () async {
        final explore = await start();
        explore.answer = (request) => request == 1 ? 402 : null;
        final run = await explore.seedLine();
        await explore.container.read(promptBlockLibraryNotifierProvider.future);
        explore.container
            .read(pillWorkspaceProvider(PillScopes.main).notifier)
            .restoreDocument(
              const PillDocument(
                text: 'base, $_marker',
                instances: {_marker: _evolving},
              ),
            );

        expect(
          await explore.runner.startDeepRound(
            run.id,
            familyId: 'fam-1',
            parentSetId: 'ps-1',
            count: 2,
          ),
          isTrue,
        );

        expect(explore.requests, 1);
        final after = await explore.reload(run.id);
        expect(after.rounds.single.phase, ExploreRoundPhase.deep);
        expect(after.rounds.single.status, ExploreRoundStatus.generated);
        expect(after.candidates, hasLength(2));
        for (final candidate in after.candidates) {
          final error = candidate.generation.error!;
          expect(isGenerationStatusStopped(error), isTrue, reason: error);
          expect(generationFailureStatus(error), 402, reason: error);
          expect(candidate.lineage.mutatedText, isNotNull);
        }
        expect(
          explore.container.read(deepRoundRollGuardControllerProvider).guard,
          isNull,
        );
        expect(PillRollCoordinator.isRollSuppressed, isFalse);
      });

      test(
        'an error another run left behind does not stop the explore',
        () async {
          final explore = await start();
          // A single image on the generation page ran out of Anlas ...
          explore.answer = (request) => request == 1 ? 402 : null;
          final generation = explore.container.read(
            imageGenerationNotifierProvider.notifier,
          );
          await generation.generate(
            explore.container
                .read(generationParamsNotifierProvider)
                .copyWith(prompt: '1girl', nSamples: 1),
            imagesPerRequestOverride: 1,
          );
          final left = explore.container
              .read(imageGenerationNotifierProvider)
              .errorMessage;
          expect(generationFailureStatus(left!), 402);
          // ... and a local upscale is running, so the explore's requests are
          // turned away before they start.
          (explore.container.read(localUpscaleTaskProvider.notifier)
                  as _Upscale)
              .run();
          final run = await explore.seedRun(3);

          await explore.runner.start(run.id);

          expect(explore.requests, 1);
          final candidates = (await explore.reload(run.id)).candidates;
          expect(candidates, hasLength(3));
          for (final candidate in candidates) {
            expect(
              candidate.generation.status,
              ExploreCandidateGenerationStatus.failed,
            );
            expect(
              isGenerationRunStopped(candidate.generation.error),
              isFalse,
              reason: candidate.generation.error,
            );
          }
        },
      );
    });
  }
}
