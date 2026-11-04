import 'dart:async';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/constants/api_constants.dart'
    show ImageModels;
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/network/error_mappers/api_error_mapper.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_generation_api_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/data/models/image/image_params.dart'
    hide CharacterPrompt;
import 'package:nai_launcher/data/models/image/image_stream_chunk.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_retry_policy.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/nav_activity_provider.dart';
import 'package:nai_launcher/presentation/providers/notification_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_roll_coordinator.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/wiring/generation_error_view.dart';
import 'package:nai_launcher/presentation/wiring/nav_wiring.dart';

import '../../../helpers/app_logger_test_isolation.dart';

class _Api extends Mock implements NAIImageGenerationApiService {}

class _Gallery extends LocalGalleryNotifier {
  @override
  LocalGalleryState build() => const LocalGalleryState(isInitialized: true);

  @override
  Future<int> addNewlySavedImages(List<String> filePaths) async =>
      filePaths.length;
}

/// The pool the prompt's random and sequential blocks draw from.
class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async => PromptBlockLibraryState(
    blocks: [
      PromptBlock(
        id: 'pool',
        title: 'pool',
        content: 'alpha, beta, gamma',
        createdAt: DateTime.utc(2026, 10, 31),
        updatedAt: DateTime.utc(2026, 10, 31),
      ),
    ],
    folders: const [],
  );
}

/// One character that is on, one that is on but has no prompt (the request
/// leaves it out) and one that is switched off.
class _Characters extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig(
    characters: [
      CharacterPrompt(id: 'on', prompt: 'girl'),
      CharacterPrompt(id: 'blank'),
      CharacterPrompt(id: 'off', prompt: 'boy', enabled: false),
    ],
  );

  @override
  void updateCharacter(CharacterPrompt character) =>
      state = state.updateCharacter(character);
}

DioException _rejected(int status, {String? retryAfter}) {
  final options = RequestOptions(path: '/ai/generate-image');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<void>(
      requestOptions: options,
      statusCode: status,
      headers: Headers.fromMap({
        if (retryAfter != null) 'retry-after': [retryAfter],
      }),
    ),
  );
}

/// The error chunk the stream service yields for an HTTP status.
ImageStreamChunk _streamRejected(int status, {Duration? retryAfter}) =>
    ImageStreamChunk.error(
      ApiErrorMapper.formatDioError(_rejected(status)),
      retryAfter: retryAfter,
    );

/// What the stream service yields for an `error` event in an HTTP 200 stream.
ImageStreamChunk _serverEvent(String message) =>
    ImageStreamChunk.error(message, source: ImageStreamErrorSource.serverEvent);

/// What it yields when the stream ends without a final image.
ImageStreamChunk _noFinalImage() => ImageStreamChunk.error(
  'No final image received from stream',
  source: ImageStreamErrorSource.noFinalImage,
);

/// A body cut off mid-stream, as each desktop OS words it.
String _droppedConnection(TargetPlatform platform) =>
    platform == TargetPlatform.windows
    ? const SocketException(
        'An existing connection was forcibly closed by the remote host.',
        osError: OSError(
          'An existing connection was forcibly closed by the remote host.',
          10054,
        ),
      ).toString()
    : const SocketException(
        'Connection reset by peer',
        osError: OSError('Connection reset by peer', 54),
      ).toString();

const _streamingNotAllowed = 'Streaming is not allowed for this request';

const _seconds = Duration(seconds: 1);

Uint8List _png() =>
    Uint8List.fromList(img.encodePng(img.Image(width: 64, height: 96)));

Stream<ImageStreamChunk> _completedSamples(int count) => Stream.fromIterable([
  for (var index = 0; index < count; index++)
    ImageStreamChunk.complete(_png(), sampleIndex: index),
]);

/// One app session with a fake NovelAI and a recording retry clock.
class _Session {
  _Session({
    this.holdWaits = false,
    this.saveTo,
    this.waitsThatEnd = 0,
    this.chime = false,
    List<Override> overrides = const [],
  }) {
    when(() => api.generateImageStream(any())).thenAnswer((call) {
      streamCalls++;
      streamRequests.add(call.positionalArguments.first as ImageParams);
      return stream?.call(streamCalls) ??
          Stream.value(ImageStreamChunk.complete(_png()));
    });
    when(
      () => api.generateImage(any(), onProgress: any(named: 'onProgress')),
    ).thenAnswer((call) async {
      imageCalls++;
      imageRequests.add(call.positionalArguments.first as ImageParams);
      final answer = image?.call(imageCalls);
      if (answer is Object && answer is! List<Uint8List>) throw answer;
      return (answer as List<Uint8List>? ?? [_png()], <int, String>{});
    });
    when(
      () => api.generateImageCancellable(
        any(),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((call) async {
      imageCalls++;
      imageRequests.add(call.positionalArguments.first as ImageParams);
      final answer = image?.call(imageCalls);
      if (answer is Object && answer is! List<Uint8List>) throw answer;
      return answer as List<Uint8List>? ?? [_png()];
    });
    when(() => api.cancelGeneration()).thenReturn(null);
    container = ProviderContainer(
      overrides: [
        naiImageGenerationApiServiceProvider.overrideWithValue(api),
        localGalleryNotifierProvider.overrideWith(_Gallery.new),
        generationRetryDelayProvider.overrideWithValue((delay, cancelled) {
          delays.add(delay);
          cancels.add(cancelled);
          return holdWaits && delays.length > waitsThatEnd
              ? Completer<void>().future
              : Future<void>.value();
        }),
        // The window is in the background; the completion sound is recorded.
        completionWindowIsFocusedProvider.overrideWithValue(() async => false),
        notificationSoundPreviewProvider.overrideWithValue((path) async {
          sounds.add(path);
          return true;
        }),
        ...overrides,
      ],
    );
  }

  /// The completion sound is on and listened for.
  final bool chime;

  /// Each completion sound played.
  final sounds = <String?>[];

  /// Waits never end on their own (only a cancel ends them) ...
  final bool holdWaits;

  /// ... except the first [waitsThatEnd].
  final int waitsThatEnd;
  final String? saveTo;
  final api = _Api();
  late final ProviderContainer container;
  final delays = <Duration>[];

  /// The cancel signal each wait was given, in order.
  final cancels = <Future<void>>[];
  final events = <GenerationBatchEvent>[];
  int streamCalls = 0;
  int imageCalls = 0;

  /// What each stream and each non-stream request asked for, in order.
  final streamRequests = <ImageParams>[];
  final imageRequests = <ImageParams>[];

  /// Answer to the n-th stream request; a finished image when null.
  Stream<ImageStreamChunk> Function(int call)? stream;

  /// Answer to the n-th non-stream request: images, or an error to throw.
  Object? Function(int call)? image;

  ImageGenerationNotifier get notifier =>
      container.read(imageGenerationNotifierProvider.notifier);
  ImageGenerationState get state =>
      container.read(imageGenerationNotifierProvider);

  Future<void> prepare() async {
    await container
        .read(notificationSettingsNotifierProvider.notifier)
        .setSoundEnabled(chime);
    if (chime) container.read(generationCompletionWatcherProvider);
    final save = container.read(imageSaveSettingsNotifierProvider.notifier);
    if (saveTo != null) await save.setCustomPath(saveTo!);
    await save.setAutoSave(saveTo != null);
  }

  /// [requests] repeats of [perRequest] images each.
  Future<void> generate({
    int requests = 1,
    int perRequest = 1,
    bool badRequestStopsRun = true,
    String prompt = '1girl',
  }) async {
    await prepare();
    await notifier.generate(
      container
          .read(generationParamsNotifierProvider)
          .copyWith(prompt: prompt, nSamples: requests),
      imagesPerRequestOverride: perRequest,
      onBatchEvent: events.add,
      badRequestStopsRun: badRequestStopsRun,
    );
  }

  List<int> completedBatches() => [
    for (final event in events)
      if (event.kind == GenerationBatchEventKind.complete) event.batchIndex,
  ];

  List<int> startedBatches() => [
    for (final event in events)
      if (event.kind == GenerationBatchEventKind.start) event.batchIndex,
  ];

  void dispose() => container.dispose();
}

Future<void> _until(bool Function() condition, String reason) async {
  for (var i = 0; i < 400; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail(reason);
}

const _backoff = [
  Duration(seconds: 3),
  Duration(seconds: 6),
  Duration(seconds: 12),
  Duration(seconds: 24),
  Duration(seconds: 30),
  Duration(seconds: 15),
];

void main() {
  late Directory hiveDir;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    registerFallbackValue(const ImageParams());
    hiveDir = await Directory.systemTemp.createTemp('nai_retry_hive_');
    Hive.init(hiveDir.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
    await Hive.openBox(StorageKeys.statisticsCacheBox);
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await Hive.box(StorageKeys.settingsBox).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) await hiveDir.delete(recursive: true);
    await AppLoggerTestIsolation.tearDown();
  });

  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    group('${platform.name}:', () {
      late _Session session;

      _Session start({
        bool holdWaits = false,
        int waitsThatEnd = 0,
        String? saveTo,
        bool chime = false,
        List<Override> overrides = const [],
      }) {
        debugDefaultTargetPlatformOverride = platform;
        return session = _Session(
          holdWaits: holdWaits,
          waitsThatEnd: waitsThatEnd,
          saveTo: saveTo,
          chime: chime,
          overrides: overrides,
        );
      }

      tearDown(() => session.dispose());

      for (final (name, failure) in [
        ('truncated', _noFinalImage()),
        ('server error', _serverEvent('render stream stopped')),
        ('429', _streamRejected(429)),
        ('unsupported streaming', ImageStreamChunk.error(_streamingNotAllowed)),
      ]) {
        test(
          'partial batch ($name) keeps delivered slots, then retries only unsent requests',
          () async {
            final saveDir = await Directory.systemTemp.createTemp(
              'partial-batch-',
            );
            addTearDown(() => saveDir.delete(recursive: true));
            final bytes = _png();
            start(saveTo: saveDir.path).stream = (call) async* {
              if (call == 2) {
                yield ImageStreamChunk.complete(bytes, sampleIndex: 2);
                yield ImageStreamChunk.complete(bytes, sampleIndex: 0);
                yield failure;
              } else {
                for (var index = 0; index < 3; index++) {
                  yield ImageStreamChunk.complete(bytes, sampleIndex: index);
                }
              }
            };

            await session.generate(requests: 3, perRequest: 3);

            expect(session.streamCalls, 2);
            expect(session.imageCalls, 0);
            expect(session.delays, isEmpty);
            final made = session.state.currentImages;
            expect(session.state.status, GenerationStatus.error);
            expect(made.map((image) => image.batchIndex), [0, 1, 2, 3, 5]);
            expect(
              session.state.history.where((image) => image.canSave),
              hasLength(5),
            );
            expect(session.state.displayImages, made);
            expect(
              made.every((image) => File(image.filePath!).existsSync()),
              isTrue,
            );
            final completed = session.events
                .where((e) => e.kind == GenerationBatchEventKind.complete)
                .toList();
            expect(completed.map((event) => event.batchIndex), [0, 1, 2]);
            expect(completed[1].images.map((image) => image.batchIndex), [
              3,
              5,
            ]);
            expect(completed[1].error, isNotNull);
            final card = generationCanvasError(
              lookupAppLocalizations(const Locale('en')),
              session.state,
            )!;
            expect(card.retry, isTrue);
            expect(card.hint, contains('2 of 3'));
            final request = session.notifier.lastRequest!;
            expect((request.params.nSamples, request.count), (1, 3));
            await session.notifier.retry(request);
            expect(session.streamCalls, 3);
            expect(
              session.state.history.where((image) => image.canSave),
              hasLength(8),
            );
          },
        );
      }

      for (final way in [
        'unsupported event',
        'unsupported exception',
        'empty stream',
        'retry fallback',
      ]) {
        test(
          'short non-stream batch via $way preserves its only final image',
          () async {
            start()
              ..stream = ((_) => switch (way) {
                'unsupported exception' => Stream.error(
                  Exception(_streamingNotAllowed),
                ),
                'empty stream' => const Stream.empty(),
                _ => Stream.value(ImageStreamChunk.error(_streamingNotAllowed)),
              })
              ..image = (call) => way == 'retry fallback' && call == 1
                  ? _rejected(503)
                  : [_png()];
            await session.generate(requests: 2, perRequest: 3);
            expect(session.streamCalls, 1);
            expect(session.imageCalls, way == 'retry fallback' ? 2 : 1);
            expect(session.state.status, GenerationStatus.error);
            expect(session.state.currentImages.single.batchIndex, 0);
            expect(session.notifier.lastRequest!.params.nSamples, 1);
          },
        );
      }

      test(
        'a provider stream that ends cleanly with one final still stops an incomplete batch',
        () async {
          start().stream = (_) =>
              Stream.value(ImageStreamChunk.complete(_png(), sampleIndex: 2));
          await session.generate(requests: 2, perRequest: 3);
          expect(session.streamCalls, 1);
          expect(session.state.status, GenerationStatus.error);
          expect(session.state.currentImages.single.batchIndex, 2);
          expect(session.notifier.lastRequest!.params.nSamples, 1);
        },
      );

      test('partial final batch has no full request left to retry', () async {
        start().stream = (_) => Stream.fromIterable([
          ImageStreamChunk.complete(_png(), sampleIndex: 1),
          _noFinalImage(),
        ]);
        await session.generate(perRequest: 2);
        expect(session.streamCalls, 1);
        expect(session.state.status, GenerationStatus.error);
        expect(session.state.currentImages.single.batchIndex, 1);
        expect(
          generationCanvasError(
            lookupAppLocalizations(const Locale('en')),
            session.state,
          )!.retry,
          isFalse,
        );
        expect(session.notifier.lastRequest, isNull);
      });

      test(
        'a trailing stream error after every final image does not resend a completed batch',
        () async {
          start().stream = (_) => Stream.fromIterable([
            ImageStreamChunk.complete(_png(), sampleIndex: 1),
            ImageStreamChunk.complete(_png(), sampleIndex: 0),
            _serverEvent('closing stream'),
          ]);
          await session.generate(perRequest: 2);
          expect(session.streamCalls, 1);
          expect(session.state.status, GenerationStatus.completed);
          expect(session.state.currentImages.map((image) => image.batchIndex), [
            0,
            1,
          ]);
        },
      );

      test(
        'stopped explore candidates leave no retry on the generation canvas',
        () async {
          start().stream = (_) => Stream.value(_streamRejected(402));
          await session.generate(requests: 2);
          expect(session.notifier.lastRequest, isNotNull);
          await session.generate(requests: 3, badRequestStopsRun: false);
          expect(session.notifier.lastRequest, isNull);
          final l = lookupAppLocalizations(const Locale('en'));
          expect(generationCanvasError(l, session.state), isNull);
          await session.generate();
          expect(session.notifier.lastRequest, isNotNull);
          await session.notifier.generateForExplore(
            session.container.read(generationParamsNotifierProvider),
          );
          expect(session.notifier.lastRequest, isNull);
          expect(generationCanvasError(l, session.state), isNull);
        },
      );

      group('client errors fail at once', () {
        // 400 to 404 stop the whole run (below); the other client errors fail
        // only their batch.
        for (final status in [409, 422]) {
          test('HTTP $status: one request per batch, no waiting', () async {
            start().stream = (_) => Stream.value(_streamRejected(status));

            await session.generate(requests: 3);

            expect(session.streamCalls, 3);
            expect(session.delays, isEmpty);
            expect(session.state.status, GenerationStatus.error);
            expect(session.state.errorMessage, contains('$status'));
            expect(isGenerationRunStopped(session.state.errorMessage), isFalse);
            expect(session.completedBatches(), [0, 1, 2]);
          });

          test(
            'HTTP $status on one batch: the next batches still go',
            () async {
              start().stream = (call) => Stream.value(
                call == 1
                    ? _streamRejected(status)
                    : ImageStreamChunk.complete(_png()),
              );

              await session.generate(requests: 3);

              expect(session.streamCalls, 3);
              expect(session.delays, isEmpty);
              expect(session.state.status, GenerationStatus.completed);
              expect(session.state.currentImages, hasLength(2));
            },
          );
        }

        for (final status in [400, 401, 402, 403, 404]) {
          test('HTTP $status without streaming: one request', () async {
            start()
              ..stream = ((_) =>
                  Stream.value(ImageStreamChunk.error(_streamingNotAllowed)))
              ..image = ((_) => _rejected(status));

            await session.generate();

            expect(session.imageCalls, 1);
            expect(session.delays, isEmpty);
            expect(session.state.status, GenerationStatus.error);
          });
        }
      });

      group('400, 401, 402, 403 and 404 stop the whole run', () {
        for (final status in [400, 401, 402, 403, 404]) {
          test(
            'HTTP $status on the first batch: the rest is never sent',
            () async {
              start().stream = (_) => Stream.value(_streamRejected(status));

              await session.generate(requests: 3);

              expect(session.streamCalls, 1);
              expect(session.delays, isEmpty);
              expect(session.startedBatches(), [0]);
              expect(session.completedBatches(), [0, 1, 2]);
              for (final event in session.events.where(
                (event) => event.kind == GenerationBatchEventKind.complete,
              )) {
                expect(isGenerationStatusStopped('${event.error}'), isTrue);
              }
              final state = session.state;
              expect(state.status, GenerationStatus.error);
              expect(isGenerationStatusStopped(state.errorMessage), isTrue);
              // The card can tell which error stopped the run.
              expect(generationFailureStatus(state.errorMessage!), status);
              // Nothing was made: Retry asks for all three batches again.
              expect(session.notifier.lastRequest!.params.nSamples, 3);
            },
          );

          test(
            'HTTP $status without streaming stops it the same way',
            () async {
              start()
                ..stream = ((_) =>
                    Stream.value(ImageStreamChunk.error(_streamingNotAllowed)))
                ..image = ((_) => _rejected(status));

              await session.generate(requests: 3);

              expect(session.streamCalls, 1);
              expect(session.imageCalls, 1);
              expect(session.delays, isEmpty);
              expect(session.startedBatches(), [0]);
              expect(session.state.status, GenerationStatus.error);
              expect(
                isGenerationStatusStopped(session.state.errorMessage),
                isTrue,
              );
              expect(
                generationFailureStatus(session.state.errorMessage!),
                status,
              );
            },
          );
        }

        for (final status in [400, 401, 404]) {
          for (final streamed in [true, false]) {
            final way = streamed ? 'stream' : 'non-stream';
            test('$status after two batches ($way): their images stay, '
                'Retry sends the rest', () async {
              final saveDir = await Directory.systemTemp.createTemp(
                'nai_retry_save_',
              );
              addTearDown(() => saveDir.delete(recursive: true));
              start(saveTo: saveDir.path);
              if (streamed) {
                session.stream = (call) => call <= 2
                    ? _completedSamples(2)
                    : Stream.value(_streamRejected(status));
              } else {
                session
                  ..stream = ((_) => Stream.value(
                    ImageStreamChunk.error(_streamingNotAllowed),
                  ))
                  ..image = ((call) =>
                      call <= 2 ? [_png(), _png()] : _rejected(status));
              }
              int sent() => streamed ? session.streamCalls : session.imageCalls;

              await session.generate(requests: 4, perRequest: 2);

              // Batches 1 and 2 came back, batch 3 got the error, batch 4
              // was never sent.
              expect(sent(), 3);
              expect(session.delays, isEmpty);
              expect(session.startedBatches(), [0, 1, 2]);
              expect(session.completedBatches(), [0, 1, 2, 3]);
              final state = session.state;
              expect(state.status, GenerationStatus.error);
              expect(isGenerationStatusStopped(state.errorMessage), isTrue);
              expect(generationFailureStatus(state.errorMessage!), status);
              final made = state.currentImages
                  .where((image) => image.canSave)
                  .toList();
              expect(made, hasLength(4));
              expect(
                state.displayImages.map((image) => image.id),
                made.map((image) => image.id),
              );
              expect(
                state.history.map((image) => image.id),
                containsAll(made.map((image) => image.id)),
              );
              for (final image in made) {
                expect(image.filePath, isNotNull);
                expect(File(image.filePath!).existsSync(), isTrue);
              }
              final request = session.notifier.lastRequest!;
              // What Retry quotes and sends: the two batches of 2 not made.
              expect(request.params.nSamples, 2);
              expect(request.count, 2);

              // Whatever the card asked for is sorted out; the user clicks
              // Retry.
              session.image = (_) => [_png(), _png()];
              if (streamed) {
                session.stream = (_) => _completedSamples(2);
              }
              final before = sent();
              await session.notifier.retry(request);

              expect(sent() - before, 2);
              expect(session.state.status, GenerationStatus.completed);
            });
          }
        }

        for (final (status, title) in [
          (400, (AppLocalizations l) => l.api_error_400),
          (402, (AppLocalizations l) => l.api_error_402),
          (404, (AppLocalizations l) => l.api_error_404),
        ]) {
          test('$status after images were made: the nav names the reason and '
              'the sound plays', () async {
            start(chime: true).stream = (call) => Stream.value(
              call == 1
                  ? ImageStreamChunk.complete(_png())
                  : _streamRejected(status),
            );

            await session.generate(requests: 3);
            await pumpEventQueue();

            expect(session.streamCalls, 2);
            expect(session.sounds, hasLength(1));
            for (final locale in const [Locale('zh'), Locale('en')]) {
              final l = lookupAppLocalizations(locale);
              final nav = navGenerationData(
                const ImageGenerationState(),
                NavGenerationResult(
                  status: session.state.status,
                  total: 1,
                  error: session.state.errorMessage,
                ),
                visible: false,
                l10n: l,
              );
              expect(nav.state, NavGenerationState.failed);
              expect(nav.error, title(l), reason: '$locale');
            }
          });
        }

        for (final status in [400, 403, 404]) {
          test('$status before any image: no sound', () async {
            start(chime: true).stream = (_) =>
                Stream.value(_streamRejected(status));

            await session.generate(requests: 3);
            await pumpEventQueue();

            expect(session.streamCalls, 1);
            expect(session.state.status, GenerationStatus.error);
            expect(session.sounds, isEmpty);
          });
        }
      });

      // The style explore page draws its candidates one request each, and
      // every request has the artist string just drawn for it.
      group('style explore draws', () {
        for (final streamed in [true, false]) {
          final way = streamed ? 'stream' : 'non-stream';
          void answer(int status) {
            if (streamed) {
              session.stream = (call) => Stream.value(
                call == 2
                    ? _streamRejected(status)
                    : ImageStreamChunk.complete(_png()),
              );
            } else {
              session
                ..stream = ((_) =>
                    Stream.value(ImageStreamChunk.error(_streamingNotAllowed)))
                ..image = ((call) => call == 2 ? _rejected(status) : null);
            }
          }

          int sent() => streamed ? session.streamCalls : session.imageCalls;

          test('400 on one candidate ($way): the next ones still go', () async {
            start();
            answer(400);

            await session.generate(requests: 4, badRequestStopsRun: false);

            expect(sent(), 4);
            expect(session.startedBatches(), [0, 1, 2, 3]);
            expect(session.completedBatches(), [0, 1, 2, 3]);
            final failed = session.events
                .where(
                  (event) =>
                      event.kind == GenerationBatchEventKind.complete &&
                      event.error != null,
                )
                .toList();
            expect(failed.map((event) => event.batchIndex), [1]);
            expect(generationFailureStatus(failed.single.error!), 400);
            expect(isGenerationRunStopped('${failed.single.error}'), isFalse);
            expect(session.state.status, GenerationStatus.completed);
            expect(session.state.currentImages, hasLength(3));
            // The explore says why on the candidate; the canvas says
            // nothing.
            expect(session.state.rejectedBatches, isNull);
          });

          for (final status in [401, 402, 403, 404]) {
            test(
              '$status on one candidate ($way): the rest is never sent',
              () async {
                start();
                answer(status);

                await session.generate(requests: 4, badRequestStopsRun: false);

                expect(sent(), 2);
                expect(session.startedBatches(), [0, 1]);
                expect(session.state.status, GenerationStatus.error);
                expect(
                  isGenerationStatusStopped(session.state.errorMessage),
                  isTrue,
                );
                expect(
                  generationFailureStatus(session.state.errorMessage!),
                  status,
                );
              },
            );
          }
        }
      });

      // A random or sequential block in the prompt draws its words again for
      // every batch, so a 400 may come from what one batch drew: it fails
      // only that batch and the run goes on, as in a style explore. Without
      // one every batch sends the same words and a 400 stops the run (above).
      // 401 to 404 stop it either way.
      group('random blocks in the prompt', () {
        const marker = '\uE000';

        setUp(PillRollCoordinator.resetRollSuppression);

        _Session open({String? saveTo}) => start(
          saveTo: saveTo,
          overrides: [
            promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
            characterPromptNotifierProvider.overrideWith(_Characters.new),
          ],
        );

        PillDocument box(
          String text, {
          PillRollMode mode = PillRollMode.random,
          bool enabled = true,
          bool locked = false,
        }) => PillDocument(
          text: '$text$marker',
          instances: {
            marker: PillInstance(
              blockId: 'pool',
              enabled: enabled,
              locked: locked,
              settings: PillInstanceSettings(mode: mode),
              // A locked block keeps what it drew before.
              currentRoll: locked ? 'alpha' : null,
            ),
          },
        );

        /// Fills the generation page's prompt boxes ([PillScopes]) and hands
        /// what they read on to the parameters and the characters, as the
        /// editors do; returns the prompt the page sends.
        Future<String> type(Map<String, PillDocument> boxes) async {
          final container = session.container;
          await container.read(promptBlockLibraryNotifierProvider.future);
          container
              .read(generationParamsNotifierProvider.notifier)
              .updatePromptImmediately('1girl');
          for (final MapEntry(key: scope, value: document) in boxes.entries) {
            final lane = pillWorkspaceProvider(scope);
            container.read(lane.notifier).restoreDocument(document);
            container
                .read(pillRollCoordinatorProvider)
                .syncLaneProjection(scope, container.read(lane).projection);
          }
          await pumpEventQueue();
          return container.read(generationParamsNotifierProvider).prompt;
        }

        List<GenerationBatchEvent> failedBatches() => [
          for (final event in session.events)
            if (event.kind == GenerationBatchEventKind.complete &&
                event.error != null)
              event,
        ];

        for (final streamed in [true, false]) {
          final way = streamed ? 'stream' : 'non-stream';
          void answer(int? Function(int request) status) {
            if (streamed) {
              session.stream = (call) => Stream.value(switch (status(call)) {
                final code? => _streamRejected(code),
                null => ImageStreamChunk.complete(_png()),
              });
            } else {
              session
                ..stream = ((_) =>
                    Stream.value(ImageStreamChunk.error(_streamingNotAllowed)))
                ..image = ((call) => switch (status(call)) {
                  final code? => _rejected(code),
                  null => null,
                });
            }
          }

          int sent() => streamed ? session.streamCalls : session.imageCalls;
          List<ImageParams> asked() =>
              streamed ? session.streamRequests : session.imageRequests;

          test('400 on the first batch ($way): each batch draws its own words '
              'and the next batches still go', () async {
            open();
            answer((request) => request == 1 ? 400 : null);
            final prompt = await type({
              PillScopes.main: box('1girl, ', mode: PillRollMode.sequential),
            });

            await session.generate(requests: 3, prompt: prompt);

            expect(sent(), 3);
            expect(session.delays, isEmpty);
            expect(
              [for (final params in asked()) params.prompt],
              [contains('alpha'), contains('beta'), contains('gamma')],
            );
            final [failed] = failedBatches();
            expect(failed.batchIndex, 0);
            expect(generationFailureStatus(failed.error!), 400);
            expect(isGenerationRunStopped('${failed.error}'), isFalse);
            expect(session.state.status, GenerationStatus.completed);
            expect(session.state.currentImages, hasLength(2));
            // The canvas is told one request was turned down and skipped.
            expect(
              session.state.rejectedBatches,
              GenerationRejectedBatches(count: 1, lastError: '${failed.error}'),
            );
            expect(session.state.errorMessage, isNull);
          });

          test('400 on two of three batches ($way): the run ends saying two '
              'requests were turned down, with the last one', () async {
            open();
            answer((request) => request == 2 ? null : 400);
            final prompt = await type({
              PillScopes.main: box('1girl, ', mode: PillRollMode.sequential),
            });

            await session.generate(requests: 3, prompt: prompt);

            expect(sent(), 3);
            final failed = failedBatches();
            expect(failed.map((event) => event.batchIndex), [0, 2]);
            final state = session.state;
            expect(state.status, GenerationStatus.completed);
            expect(state.currentImages, hasLength(1));
            expect(
              state.rejectedBatches,
              GenerationRejectedBatches(
                count: 2,
                lastError: '${failed.last.error}',
              ),
            );
            expect(state.errorMessage, isNull);
          });

          test('400 on every batch ($way): every batch is still sent and the '
              'run ends on the last 400', () async {
            open();
            answer((_) => 400);
            final prompt = await type({PillScopes.main: box('1girl, ')});

            await session.generate(requests: 3, prompt: prompt);

            expect(sent(), 3);
            final failed = failedBatches();
            expect(failed.map((event) => event.batchIndex), [0, 1, 2]);
            for (final event in failed) {
              expect(generationFailureStatus(event.error!), 400);
              expect(isGenerationRunStopped('${event.error}'), isFalse);
            }
            final state = session.state;
            expect(state.status, GenerationStatus.error);
            // The error card reads the last batch's error, without a stop.
            expect(state.errorMessage, '${failed.last.error}');
            expect(isGenerationRunStopped(state.errorMessage), isFalse);
            // Nothing came out: the 400 card as before, not a count.
            expect(state.rejectedBatches, isNull);
          });

          for (final status in [401, 402, 403, 404]) {
            test('$status with a random block ($way): the rest is never '
                'sent', () async {
              open();
              answer((_) => status);
              final prompt = await type({PillScopes.main: box('1girl, ')});

              await session.generate(requests: 3, prompt: prompt);

              expect(sent(), 1);
              expect(session.startedBatches(), [0]);
              final state = session.state;
              expect(state.status, GenerationStatus.error);
              expect(isGenerationStatusStopped(state.errorMessage), isTrue);
              expect(generationFailureStatus(state.errorMessage!), status);
            });
          }

          // A box the request does not carry draws nothing new for it: Turbo
          // drops the custom negative prompts, V3 sends no characters and a
          // character with no prompt is left out. Its block still draws
          // again for every batch, but every batch sends the same.
          for (final (name, model, boxes) in [
            (
              'the negative prompt under Turbo',
              ImageModels.animeDiffusionV5FullMedium,
              {PillScopes.negative: box('lowres, ')},
            ),
            (
              "a character's negative prompt under Turbo",
              ImageModels.animeDiffusionV5FullMedium,
              {PillScopes.charNeg('on'): box('lowres, ')},
            ),
            (
              "a character's prompt under V3",
              ImageModels.animeDiffusionV3,
              {PillScopes.charPos('on'): box('girl, ')},
            ),
            (
              "a character's negative prompt under Furry V3",
              ImageModels.furryDiffusionV3,
              {PillScopes.charNeg('on'): box('lowres, ')},
            ),
            (
              'the negative prompt of a character with no prompt',
              ImageModels.animeDiffusionV5Full,
              {PillScopes.charNeg('blank'): box('lowres, ')},
            ),
          ]) {
            test('a random block in $name ($way): 400 still stops the '
                'run', () async {
              open();
              answer((_) => 400);
              session.container
                  .read(generationParamsNotifierProvider.notifier)
                  .updateModel(model, persist: false);
              final prompt = await type(boxes);

              await session.generate(requests: 3, prompt: prompt);

              expect(sent(), 1);
              expect(session.startedBatches(), [0]);
              final state = session.state;
              expect(state.status, GenerationStatus.error);
              expect(isGenerationStatusStopped(state.errorMessage), isTrue);
              expect(generationFailureStatus(state.errorMessage!), 400);
            });
          }

          // The words of the first batch may be the ones NovelAI turned
          // down; Retry sends those of the batch that stopped the run, which
          // the boxes still show. The request turned down before the stop
          // goes along with Retry: once Retry has sent the rest, the canvas
          // says it was skipped, which is why an image is missing.
          for (final (status, stopTitle) in [
            (402, (AppLocalizations l) => l.api_error_402),
            (429, (AppLocalizations l) => l.api_error_429),
          ]) {
            test('400, then $status ($way): Retry sends the words of the '
                'batch that stopped, then the canvas says one request was '
                'skipped', () async {
              open();
              var sorted = false;
              answer((request) {
                if (asked().last.prompt.contains('alpha')) return 400;
                return !sorted && request >= 3 ? status : null;
              });
              final prompt = await type({
                PillScopes.main: box('1girl, ', mode: PillRollMode.sequential),
              });

              await session.generate(requests: 3, prompt: prompt);

              final prompts = [for (final params in asked()) params.prompt];
              expect(prompts.take(2), [contains('alpha'), contains('beta')]);
              expect(prompts.skip(2), everyElement(contains('gamma')));
              final stopped = session.state;
              expect(stopped.status, GenerationStatus.error);
              expect(isGenerationRunStopped(stopped.errorMessage), isTrue);
              // The card says why the run stopped; that is what to act on.
              expect(stopped.rejectedBatches, isNull);
              final request = session.notifier.lastRequest!;
              expect(request.params.nSamples, 1);
              expect(request.params.prompt, contains('gamma'));
              // The request turned down before the stop goes along.
              final turnedDown = failedBatches().first;
              expect(turnedDown.batchIndex, 0);
              expect(generationFailureStatus(turnedDown.error!), 400);
              final skipped = GenerationRejectedBatches(
                count: 1,
                lastError: '${turnedDown.error}',
              );
              expect(request.rejectedBatches, skipped);

              // The user sorts out what the card asked for and clicks Retry.
              sorted = true;
              final before = sent();
              await session.notifier.retry(request);

              expect(sent() - before, 1);
              expect(asked().last.prompt, contains('gamma'));
              final done = session.state;
              expect(done.status, GenerationStatus.completed);
              expect(done.errorMessage, isNull);
              // Two of the three came out: one request was skipped.
              expect(done.rejectedBatches, skipped);

              // What the canvas shows, in every language.
              for (final locale in AppLocalizations.supportedLocales) {
                final tag = locale.toLanguageTag();
                final l = lookupAppLocalizations(locale);
                // Stopped: why, and Retry; nothing yet about the skip.
                final stop = generationCanvasError(l, stopped)!;
                expect(
                  stop.title,
                  '${stopTitle(l)} (HTTP $status)',
                  reason: tag,
                );
                expect(
                  stop.hint,
                  contains(
                    status == 429
                        ? l.gen_concurrencyStopped
                        : l.api_error_402_hint,
                  ),
                  reason: tag,
                );
                expect(stop.detail, stopped.errorMessage, reason: tag);
                expect(stop.retry, isTrue, reason: tag);
                // Retry has sent the rest: the 400 card says one request
                // was turned down and skipped, and has no Retry.
                final told = generationCanvasError(l, done)!;
                expect(told.title, l.api_error_400, reason: tag);
                expect(told.hint, l.gen_rejectedRequestsHint(1), reason: tag);
                expect(told.retry, isFalse, reason: tag);
                expect(told.copy, skipped.lastError, reason: tag);
              }
            });
          }

          // Retry may send several requests and stop once more; each Retry
          // takes along what was skipped before, until one sends the rest.
          for (final again in [false, true]) {
            test(
              again
                  ? '400, then 402, then 402 again on Retry ($way): the '
                        'next Retry still takes the skipped request along'
                  : '400, then 402 ($way): a Retry of two requests ends '
                        'saying one was skipped',
              () async {
                open();
                var phase = 0;
                var retried = 0;
                answer((request) {
                  final words = asked().last.prompt;
                  return switch (phase) {
                    0 when words.contains('alpha') => 400,
                    0 when words.contains('gamma') => 402,
                    1 when again && ++retried == 2 => 402,
                    _ => null,
                  };
                });
                final prompt = await type({
                  PillScopes.main: box(
                    '1girl, ',
                    mode: PillRollMode.sequential,
                  ),
                });

                await session.generate(requests: 4, prompt: prompt);

                // alpha was turned down, beta came out, gamma stopped the
                // run and the fourth was never sent.
                expect(sent(), 3);
                expect(session.state.status, GenerationStatus.error);
                final skipped = GenerationRejectedBatches(
                  count: 1,
                  lastError: '${failedBatches().first.error}',
                );
                var request = session.notifier.lastRequest!;
                expect(request.params.nSamples, 2);
                expect(request.rejectedBatches, skipped);

                phase = 1;
                await session.notifier.retry(request);

                expect(sent(), 5);
                if (again) {
                  // The second of the two stopped it once more.
                  expect(session.state.status, GenerationStatus.error);
                  expect(session.state.rejectedBatches, isNull);
                  request = session.notifier.lastRequest!;
                  expect(request.params.nSamples, 1);
                  expect(request.rejectedBatches, skipped);

                  phase = 2;
                  await session.notifier.retry(request);

                  expect(sent(), 6);
                }
                expect(session.state.status, GenerationStatus.completed);
                expect(session.state.rejectedBatches, skipped);
              },
            );
          }

          test('400, then 402 ($way): Generate instead of Retry counts only '
              'its own requests', () async {
            open();
            var sorted = false;
            answer((request) {
              if (sorted) return null;
              if (asked().last.prompt.contains('alpha')) return 400;
              return request >= 3 ? 402 : null;
            });
            final prompt = await type({
              PillScopes.main: box('1girl, ', mode: PillRollMode.sequential),
            });
            await session.generate(requests: 3, prompt: prompt);
            expect(session.state.status, GenerationStatus.error);
            expect(session.notifier.lastRequest!.rejectedBatches?.count, 1);

            sorted = true;
            await session.generate(requests: 3, prompt: prompt);

            expect(session.state.status, GenerationStatus.completed);
            expect(session.state.rejectedBatches, isNull);
            expect(session.notifier.lastRequest!.rejectedBatches, isNull);
          });
        }

        for (final (name, boxes, words) in [
          (
            'the negative prompt',
            {PillScopes.negative: box('lowres, ')},
            (ImageParams params) => params.negativePrompt,
          ),
          (
            "a character's prompt",
            {PillScopes.charPos('on'): box('girl, ')},
            (ImageParams params) => params.characters.single.prompt,
          ),
          (
            "a character's negative prompt",
            {PillScopes.charNeg('on'): box('lowres, ')},
            (ImageParams params) => params.characters.single.negativePrompt,
          ),
        ]) {
          test('a random block in $name counts too: 400 fails only its '
              'batch', () async {
            open().stream = (call) => Stream.value(
              call == 1
                  ? _streamRejected(400)
                  : ImageStreamChunk.complete(_png()),
            );
            final prompt = await type(boxes);

            await session.generate(requests: 3, prompt: prompt);

            expect(session.streamCalls, 3);
            // What the block drew is in what was sent.
            for (final params in session.streamRequests) {
              expect(words(params), matches(RegExp('alpha|beta|gamma')));
            }
            expect(session.state.status, GenerationStatus.completed);
            expect(session.state.currentImages, hasLength(2));
          });
        }

        for (final (name, boxes) in [
          (
            'a fixed block',
            {PillScopes.main: box('1girl, ', mode: PillRollMode.fixed)},
          ),
          (
            'a locked random block',
            {PillScopes.main: box('1girl, ', locked: true)},
          ),
          (
            'a random block that is switched off',
            {PillScopes.main: box('1girl, ', enabled: false)},
          ),
          (
            'a random block of a character that is switched off',
            {PillScopes.charPos('off'): box('boy, ')},
          ),
        ]) {
          test('$name draws nothing new: 400 still stops the run', () async {
            open().stream = (_) => Stream.value(_streamRejected(400));
            final prompt = await type(boxes);

            await session.generate(requests: 3, prompt: prompt);

            expect(session.streamCalls, 1);
            expect(
              isGenerationStatusStopped(session.state.errorMessage),
              isTrue,
            );
          });
        }

        test('Retry sends every batch with the words it had: 400 stops '
            'it', () async {
          open().stream = (_) => Stream.value(_streamRejected(400));
          final prompt = await type({PillScopes.main: box('1girl, ')});
          await session.generate(requests: 3, prompt: prompt);
          expect(session.streamCalls, 3);
          final request = session.notifier.lastRequest!;
          expect(request.params.nSamples, 3);

          await session.notifier.retry(request);

          expect(session.streamCalls, 3 + 1);
          expect(isGenerationStatusStopped(session.state.errorMessage), isTrue);
        });

        test('a single image is as before: one request, one failed '
            'card', () async {
          open().stream = (_) => Stream.value(_streamRejected(400));
          final prompt = await type({PillScopes.main: box('1girl, ')});

          await session.generate(prompt: prompt);

          expect(session.streamCalls, 1);
          final state = session.state;
          expect(state.status, GenerationStatus.error);
          expect(isGenerationRunStopped(state.errorMessage), isFalse);
          expect(generationFailureStatus(state.errorMessage!), 400);
          expect(state.rejectedBatches, isNull);
        });

        test('the count stays while the images are saved and edited, and '
            'goes with Close and with the next run', () async {
          final saveDir = await Directory.systemTemp.createTemp(
            'nai_retry_save_',
          );
          addTearDown(() => saveDir.delete(recursive: true));
          // Of every three requests the first and the last are turned down.
          var turnDown = true;
          open(saveTo: saveDir.path).stream = (call) => Stream.value(
            turnDown && (call - 1) % 3 != 1
                ? _streamRejected(400)
                : ImageStreamChunk.complete(_png()),
          );
          final prompt = await type({PillScopes.main: box('1girl, ')});

          await session.generate(requests: 3, prompt: prompt);

          final rejected = session.state.rejectedBatches;
          expect(rejected?.count, 2);
          // The one image that came out was saved without dropping it.
          final made = session.state.currentImages;
          expect(made, hasLength(1));
          expect(made.single.filePath, isNotNull);
          final notifier = session.notifier;
          final bytes = _png();
          final edits = <String, FutureOr<void> Function()>{
            'register an upscale': () => notifier.registerExternalImage(
              bytes,
              params: const ImageParams(),
              addToDisplay: true,
            ),
            'register tool results': () => notifier.registerToolResults(
              [bytes],
              operation: ImageOperation.upscale,
              originalBytes: bytes,
            ),
            'update the shown images': () =>
                notifier.updateDisplayImages(session.state.displayImages),
            'delete an image': () => notifier.removeImages({made.single.id}),
            'clear the history': notifier.clearHistory,
          };
          for (final MapEntry(key: name, value: edit) in edits.entries) {
            await edit();
            expect(
              session.state.status,
              GenerationStatus.completed,
              reason: name,
            );
            expect(session.state.rejectedBatches, rejected, reason: name);
          }

          // Close on the card: the count goes, the run stays completed.
          notifier.clearError();
          expect(session.state.rejectedBatches, isNull);
          expect(session.state.status, GenerationStatus.completed);

          // A run again with two turned down, then one NovelAI takes whole:
          // the count goes with that next run.
          await session.generate(requests: 3, prompt: prompt);
          expect(session.state.rejectedBatches?.count, 2);
          turnDown = false;
          await session.generate(requests: 3, prompt: prompt);
          expect(session.state.status, GenerationStatus.completed);
          expect(session.state.rejectedBatches, isNull);
        });
      });

      group('network errors, timeouts and 5xx retry after 1, 2, 4 s', () {
        final failures = <String, ImageStreamChunk Function()>{
          'HTTP 500': () => _streamRejected(500),
          'HTTP 502': () => _streamRejected(502),
          'HTTP 503': () => _streamRejected(503),
          'a timeout': () => ImageStreamChunk.error(
            ApiErrorMapper.formatDioError(
              DioException.receiveTimeout(
                timeout: const Duration(seconds: 30),
                requestOptions: RequestOptions(path: '/'),
              ),
            ),
          ),
          'a dropped connection': () =>
              ImageStreamChunk.error(_droppedConnection(platform)),
          // dio passes the socket read error of a body cut off mid-stream
          // through as it is; the stream service yields its text.
          'a body cut off mid-stream': () => ImageStreamChunk.error(
            HttpException(
              'Connection closed while receiving data',
              uri: Uri.parse(
                'https://image.novelai.net/ai/generate-image-stream',
              ),
            ).toString(),
          ),
        };
        for (final MapEntry(key: name, value: failure) in failures.entries) {
          test('$name is tried 4 times in all', () async {
            start().stream = (_) => Stream.value(failure());

            await session.generate(perRequest: 2);

            expect(session.streamCalls, 4);
            expect(session.delays, [_seconds, _seconds * 2, _seconds * 4]);
            expect(session.state.status, GenerationStatus.error);
          });
        }

        test('a retry that succeeds finishes the run', () async {
          start().stream = (call) => call == 1
              ? Stream.value(_streamRejected(502))
              : _completedSamples(2);

          await session.generate(perRequest: 2);

          expect(session.streamCalls, 2);
          expect(session.delays, [_seconds]);
          expect(session.state.status, GenerationStatus.completed);
          expect(session.state.currentImages, hasLength(2));
        });

        test('HTTP 503 without streaming is tried 4 times', () async {
          start()
            ..stream = ((_) =>
                Stream.value(ImageStreamChunk.error(_streamingNotAllowed)))
            ..image = ((_) => _rejected(503));

          await session.generate();

          expect(session.imageCalls, 4);
          expect(session.delays, [_seconds, _seconds * 2, _seconds * 4]);
        });
      });

      group('an unexplained stream failure retries after 1, 2, 4 s', () {
        final failures = <String, ImageStreamChunk Function()>{
          'a server error event without a message': () =>
              _serverEvent('Stream generation failed'),
          'a server error event with its own message': () =>
              _serverEvent('Internal error while sampling'),
          'a stream that ended without a final image': _noFinalImage,
        };
        for (final MapEntry(key: name, value: failure) in failures.entries) {
          test('$name is tried 4 times in all, then fails', () async {
            start().stream = (_) => Stream.value(failure());

            await session.generate(perRequest: 2);

            expect(session.streamCalls, 4);
            expect(session.delays, [_seconds, _seconds * 2, _seconds * 4]);
            expect(session.state.status, GenerationStatus.error);
            expect(session.state.errorMessage, contains(failure().error!));
          });
        }

        test('a retry that succeeds finishes the run', () async {
          start().stream = (call) => Stream.value(
            call == 1 ? _noFinalImage() : ImageStreamChunk.complete(_png()),
          );

          await session.generate(requests: 2);

          expect(session.streamCalls, 3);
          expect(session.delays, [_seconds]);
          expect(session.state.status, GenerationStatus.completed);
          expect(session.state.currentImages, hasLength(2));
        });

        test('cancel during the wait sends nothing more', () async {
          start(holdWaits: true).stream = (_) =>
              Stream.value(_serverEvent('Stream generation failed'));

          final run = session.generate(perRequest: 2);
          await _until(
            () => session.delays.isNotEmpty,
            'the run never started waiting',
          );
          session.notifier.cancel();
          await run.timeout(const Duration(seconds: 5));
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(session.streamCalls, 1);
          expect(session.delays, hasLength(1));
          expect(session.state.status, GenerationStatus.cancelled);
        });

        test(
          'a server error event with 402 is not retried and stops the run',
          () async {
            start().stream = (_) =>
                Stream.value(_serverEvent('API_ERROR_402|Insufficient Anlas'));

            await session.generate(requests: 3);

            expect(session.streamCalls, 1);
            expect(session.delays, isEmpty);
            expect(session.startedBatches(), [0]);
            expect(session.state.status, GenerationStatus.error);
            expect(
              isGenerationStatusStopped(session.state.errorMessage),
              isTrue,
            );
            expect(generationFailureStatus(session.state.errorMessage!), 402);
          },
        );

        test('a server error event with 429 waits as for a 429', () async {
          start().stream = (call) => call <= 2
              ? Stream.value(
                  _serverEvent('API_ERROR_429|Concurrent generation is locked'),
                )
              : _completedSamples(2);

          await session.generate(perRequest: 2);

          expect(session.delays, [_seconds * 3, _seconds * 6]);
          expect(session.streamCalls, 3);
          expect(session.state.status, GenerationStatus.completed);
        });

        test(
          'a server error event with 429 stops once the 90 s are used up',
          () async {
            start().stream = (_) => Stream.value(
              _serverEvent('API_ERROR_429|Concurrent generation is locked'),
            );

            await session.generate(requests: 2);

            expect(session.delays, _backoff);
            expect(session.startedBatches(), [0]);
            expect(
              isGenerationConcurrencyStopped(session.state.errorMessage),
              isTrue,
            );
          },
        );

        test('a server error event with 5xx is tried 4 times', () async {
          start().stream = (_) =>
              Stream.value(_serverEvent('API_ERROR_HTTP_502|Bad Gateway'));

          await session.generate(perRequest: 2);

          expect(session.streamCalls, 4);
          expect(session.delays, [_seconds, _seconds * 2, _seconds * 4]);
        });
      });

      group('429', () {
        test(
          'backs off 3, 6, 12, 24, 30, 15 s, then stops the whole run',
          () async {
            start().stream = (_) => Stream.value(_streamRejected(429));

            await session.generate(requests: 3);

            expect(session.delays, _backoff);
            expect(
              session.delays.fold(Duration.zero, (a, b) => a + b),
              const Duration(seconds: 90),
            );
            // Only the first batch was ever sent: once at first, then after
            // each wait. The other two were never requested.
            expect(session.streamCalls, _backoff.length + 1);
            expect(session.startedBatches(), [0]);
            expect(session.completedBatches(), [0, 1, 2]);
            for (final event in session.events.where(
              (event) => event.kind == GenerationBatchEventKind.complete,
            )) {
              expect(isGenerationConcurrencyStopped('${event.error}'), isTrue);
            }
            expect(session.state.status, GenerationStatus.error);
            expect(
              isGenerationConcurrencyStopped(session.state.errorMessage),
              isTrue,
            );
          },
        );

        test('a single image backs off the same way and stops', () async {
          start().stream = (_) => Stream.value(_streamRejected(429));

          await session.generate();

          expect(session.delays, _backoff);
          expect(session.streamCalls, _backoff.length + 1);
          expect(session.state.status, GenerationStatus.error);
          expect(
            isGenerationConcurrencyStopped(session.state.errorMessage),
            isTrue,
          );
        });

        for (final serverDelay in [false, true]) {
          test(
            'a full batch after a 60-second wait leaves only 30 seconds for later 429s (Retry-After: $serverDelay)',
            () async {
              start().stream = (call) {
                if (call == 2) return _completedSamples(2);
                final retryAfter = switch (call) {
                  1 => const Duration(seconds: 60),
                  3 when serverDelay => const Duration(seconds: 30),
                  _ => null,
                };
                return Stream.value(
                  _streamRejected(429, retryAfter: retryAfter),
                );
              };

              await session.generate(requests: 3, perRequest: 2);

              // A successful batch resets the 3-second backoff step. It never
              // resets the whole run's budget; the last local step is capped to 9.
              final seconds = serverDelay ? [60, 30] : [60, 3, 6, 12, 9];
              expect(session.delays.map((delay) => delay.inSeconds), seconds);
              expect(session.streamCalls, seconds.length + 2);
              expect(session.startedBatches(), [0, 1]);
              expect(
                session.state.currentImages.map((image) => image.batchIndex),
                [0, 1],
              );
              expect(session.state.status, GenerationStatus.error);
              expect(
                isGenerationConcurrencyStopped(session.state.errorMessage),
                isTrue,
              );
            },
          );
        }

        test('Retry-After from the stream is followed', () async {
          start().stream = (call) => Stream.value(
            call <= 2
                ? _streamRejected(429, retryAfter: const Duration(seconds: 7))
                : ImageStreamChunk.complete(_png()),
          );

          await session.generate(requests: 2);

          expect(session.delays, [_seconds * 7, _seconds * 7]);
          expect(session.streamCalls, 4);
          expect(session.state.status, GenerationStatus.completed);
          expect(session.state.currentImages, hasLength(2));
        });

        test('Retry-After without streaming is followed', () async {
          start()
            ..stream = ((_) =>
                Stream.value(ImageStreamChunk.error(_streamingNotAllowed)))
            ..image = ((call) =>
                call == 1 ? _rejected(429, retryAfter: '11') : null);

          await session.generate();

          expect(session.delays, [_seconds * 11]);
          expect(session.imageCalls, 2);
          expect(session.state.status, GenerationStatus.completed);
        });

        test(
          'Retry-After past the 90 s budget stops without waiting',
          () async {
            start().stream = (_) => Stream.value(
              _streamRejected(429, retryAfter: const Duration(seconds: 120)),
            );

            await session.generate(requests: 2);

            expect(session.delays, isEmpty);
            expect(session.streamCalls, 1);
            expect(session.completedBatches(), [0, 1]);
            expect(
              isGenerationConcurrencyStopped(session.state.errorMessage),
              isTrue,
            );
          },
        );

        test('images made before the stop are kept and saved', () async {
          final saveDir = await Directory.systemTemp.createTemp(
            'nai_retry_save_',
          );
          addTearDown(() => saveDir.delete(recursive: true));
          start(saveTo: saveDir.path).stream = (call) => Stream.value(
            call == 1
                ? ImageStreamChunk.complete(_png())
                : _streamRejected(429),
          );

          await session.generate(requests: 3);

          // Batch 1 succeeded, batch 2 waited out the budget, batch 3 was
          // never sent.
          expect(session.streamCalls, 1 + _backoff.length + 1);
          expect(session.delays, _backoff);
          expect(session.startedBatches(), [0, 1]);
          final state = session.state;
          expect(state.status, GenerationStatus.error);
          expect(isGenerationConcurrencyStopped(state.errorMessage), isTrue);
          final made = state.currentImages.where((image) => image.canSave);
          expect(made, hasLength(1));
          expect(state.displayImages.map((image) => image.id), [
            made.single.id,
          ]);
          expect(made.single.filePath, isNotNull);
          expect(File(made.single.filePath!).existsSync(), isTrue);
        });

        test(
          'Retry after the stop sends only the batches that were not sent',
          () async {
            start().stream = (call) => call <= 3
                ? _completedSamples(2)
                : Stream.value(_streamRejected(429));

            await session.generate(requests: 4, perRequest: 2);

            // Batches 1-3 came back, batch 4 waited out the budget.
            expect(session.state.currentImages, hasLength(6));
            expect(
              isGenerationConcurrencyStopped(session.state.errorMessage),
              isTrue,
            );
            final request = session.notifier.lastRequest!;
            // What Retry quotes and sends: the one batch of 2 still missing.
            expect(request.params.nSamples, 1);
            expect(request.count, 2);

            // The other generation is done; the user clicks Retry.
            session.stream = (_) => _completedSamples(2);
            final sent = session.streamCalls;
            await session.notifier.retry(request);

            expect(session.streamCalls - sent, 1);
            expect(session.state.status, GenerationStatus.completed);
          },
        );

        test('the stop reason stays while the images are edited', () async {
          start().stream = (call) => Stream.value(
            call <= 2
                ? ImageStreamChunk.complete(_png())
                : _streamRejected(429),
          );
          await session.generate(requests: 3);
          final reason = session.state.errorMessage;
          expect(isGenerationConcurrencyStopped(reason), isTrue);
          final made = session.state.currentImages;
          final notifier = session.notifier;
          final bytes = _png();
          final edits = <String, FutureOr<void> Function()>{
            'delete an image': () => notifier.removeImages({made.first.id}),
            'register an upscale': () => notifier.registerExternalImage(
              bytes,
              params: const ImageParams(),
              addToDisplay: true,
            ),
            'register tool results': () => notifier.registerToolResults(
              [bytes],
              operation: ImageOperation.upscale,
              originalBytes: bytes,
            ),
            'update the shown images': () =>
                notifier.updateDisplayImages(session.state.displayImages),
            'clear the history': notifier.clearHistory,
          };
          for (final MapEntry(key: name, value: edit) in edits.entries) {
            await edit();
            expect(session.state.status, GenerationStatus.error, reason: name);
            expect(session.state.errorMessage, reason, reason: name);
          }
        });

        test('Retry after a stop before any image sends every batch', () async {
          start().stream = (_) => Stream.value(_streamRejected(429));

          await session.generate(requests: 3);

          expect(session.state.status, GenerationStatus.error);
          expect(session.notifier.lastRequest!.params.nSamples, 3);
        });

        test('a success starts the backoff over within the run', () async {
          start().stream = (call) => Stream.value(switch (call) {
            1 || 2 || 4 => _streamRejected(429),
            _ => ImageStreamChunk.complete(_png()),
          });

          await session.generate(requests: 2);

          expect(session.delays, [_seconds * 3, _seconds * 6, _seconds * 3]);
          expect(session.state.status, GenerationStatus.completed);
        });
      });

      group('cancel', () {
        test('during a 429 wait sends nothing more', () async {
          start(holdWaits: true).stream = (_) =>
              Stream.value(_streamRejected(429));

          final run = session.generate(requests: 3);
          await _until(
            () => session.delays.isNotEmpty,
            'the run never started waiting',
          );
          session.notifier.cancel();
          await run.timeout(const Duration(seconds: 5));
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(session.streamCalls, 1);
          expect(session.delays, hasLength(1));
          expect(session.state.status, GenerationStatus.cancelled);
          expect(session.completedBatches(), [0, 1, 2]);
        });

        test('during a single-image 429 wait sends nothing more', () async {
          start(holdWaits: true).stream = (_) =>
              Stream.value(_streamRejected(429));

          final run = session.generate();
          await _until(
            () => session.delays.isNotEmpty,
            'the run never started waiting',
          );
          session.notifier.cancel();
          await run.timeout(const Duration(seconds: 5));
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(session.streamCalls, 1);
          expect(session.state.status, GenerationStatus.cancelled);
        });

        test('each wait listens for its own cancel only', () async {
          // Three waits end on their own, the user cancels the fourth.
          start(holdWaits: true, waitsThatEnd: 3).stream = (_) =>
              Stream.value(_streamRejected(429));
          final settled = <int>{};
          final run = session.generate(requests: 2);
          await _until(
            () => session.cancels.length == 4,
            'the run never reached its fourth wait',
          );
          for (final (index, cancel) in session.cancels.indexed) {
            unawaited(cancel.then((_) => settled.add(index)));
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
          expect(settled, isEmpty);
          session.notifier.cancel();
          await run.timeout(const Duration(seconds: 5));
          await Future<void>.delayed(const Duration(milliseconds: 20));

          expect(session.cancels.toSet(), hasLength(4));
          expect(settled, {3});
          expect(session.state.status, GenerationStatus.cancelled);
        });

        test('during a 5xx wait sends nothing more', () async {
          start(holdWaits: true).stream = (_) =>
              Stream.value(_streamRejected(503));

          final run = session.generate(perRequest: 2);
          await _until(
            () => session.delays.isNotEmpty,
            'the run never started waiting',
          );
          session.notifier.cancel();
          await run.timeout(const Duration(seconds: 5));
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(session.streamCalls, 1);
          expect(session.state.status, GenerationStatus.cancelled);
        });
      });
    });
  }
}
