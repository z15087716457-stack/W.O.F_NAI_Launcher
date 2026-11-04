import 'dart:async';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/core/network/dio_client.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_enhancement_api_service.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/data/services/anlas_request_ledger.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/bulk_operation_provider.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/cloud_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_retry_policy.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_binding.dart';
import 'package:nai_launcher/presentation/providers/nav_activity_provider.dart';
import 'package:nai_launcher/presentation/providers/notification_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/router/app_branch.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/wiring/generation_backend.dart';
import 'package:nai_launcher/presentation/wiring/generation_error_view.dart';
import 'package:nai_launcher/presentation/wiring/nav_wiring.dart';

import '../../helpers/app_logger_test_isolation.dart';
import '../providers/krita/agent_bridge_draft_test.dart' show EmptyBlocks;
import '../providers/nav_activity_provider_test.dart'
    show FakeNavBulk, FakeNavCloudUpscale, FakeNavLocalUpscale;
import 'generation_backend_test.dart' show MemoryGenerationPlatform;

const _token = 'pst-account-a';
const _signedIn = AuthState(
  status: AuthStatus.authenticated,
  accountId: 'account-a',
);

/// The session's token. Nothing else may reach the keychain.
class _Keys implements SecureStorageService {
  String? token = _token;
  int revision = 0;

  @override
  int get authRevision => revision;

  @override
  Future<String?> getAccessToken() async => token;

  @override
  Future<void> clearAuth() async {
    token = null;
    revision++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('keychain: ${invocation.memberName}');
}

/// Signed in to account-a. Logging out is the app's own.
class _Account extends AuthNotifier {
  @override
  AuthState build() => _signedIn;

  void signIn(_Keys keys, {String id = 'account-a'}) {
    keys
      ..token = 'pst-$id'
      ..revision += 1;
    state = AuthState(status: AuthStatus.authenticated, accountId: id);
  }
}

class _NoSavedAccounts extends AccountManagerNotifier {
  @override
  AccountManagerState build() => const AccountManagerState();
}

class _Balance extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.loaded(
    UserSubscription(
      tier: 3,
      active: true,
      trainingStepsLeft: TrainingStepsInfo(
        fixedTrainingStepsLeft: 70,
        purchasedTrainingSteps: 20,
      ),
    ),
  );
}

class _Gallery extends LocalGalleryNotifier {
  @override
  LocalGalleryState build() => const LocalGalleryState(isInitialized: true);

  @override
  Future<int> addNewlySavedImages(List<String> filePaths) async =>
      filePaths.length;
}

/// NovelAI as the generation Dio reaches it: every request is answered in turn.
class _NovelAi implements HttpClientAdapter {
  _NovelAi(this.answer);

  final Future<ResponseBody> Function(RequestOptions request) answer;
  final requests = <RequestOptions>[];
  final cancels = <Future<void>?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    cancels.add(cancelFuture);
    return answer(options);
  }

  @override
  void close({bool force = false}) {}

  int count(String endpoint) =>
      requests.where((request) => request.path.endsWith(endpoint)).length;
}

bool _streamed(RequestOptions request) =>
    request.path.endsWith(ApiConstants.generateImageStreamEndpoint);

Uint8List _png() =>
    Uint8List.fromList(img.encodePng(img.Image(width: 64, height: 96)));

/// A stream that ends with its finished image, framed as NovelAI frames it.
Future<ResponseBody> _streamedImage() async {
  final message = msgpack.serialize({
    'event_type': 'final',
    'samp_ix': 0,
    'image': _png(),
  });
  final length = message.length;
  return ResponseBody.fromBytes(
    [
      (length >> 24) & 0xFF,
      (length >> 16) & 0xFF,
      (length >> 8) & 0xFF,
      length & 0xFF,
      ...message,
    ],
    200,
    headers: {
      Headers.contentTypeHeader: ['application/x-msgpack'],
    },
  );
}

/// The non-stream answer: a ZIP with the image.
Future<ResponseBody> _zippedImage() async {
  final png = _png();
  final zip =
      ZipEncoder().encode(
        Archive()..addFile(ArchiveFile('image_0.png', png.length, png)),
      ) ??
      const <int>[];
  return ResponseBody.fromBytes(
    zip,
    200,
    headers: {
      Headers.contentTypeHeader: ['application/x-zip-compressed'],
    },
  );
}

Future<ResponseBody> _rejected(int status, String message) async =>
    ResponseBody.fromString(
      '{"message":"$message"}',
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

/// One app session: the generation page is open, with the real interceptors,
/// API service, token refresh and sign-out between it and [novelAi].
class _Studio {
  _Studio(this.novelAi, {required this.saveTo}) {
    container = ProviderContainer(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(keys),
        authNotifierProvider.overrideWith(_Account.new),
        accountManagerNotifierProvider.overrideWith(_NoSavedAccounts.new),
        // The app's own generation client; only the network is NovelAI's.
        imageGenerationDioClientProvider.overrideWith(
          (ref) => imageGenerationDioClient(ref)..httpClientAdapter = novelAi,
        ),
        naiImageEnhancementApiServiceProvider.overrideWith(
          (ref) => NAIImageEnhancementApiService(
            ref.watch(imageGenerationDioClientProvider),
            endpointService: ref.watch(naiApiEndpointServiceProvider),
            ledger: ref.watch(anlasRequestLedgerProvider),
          ),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        subscriptionNotifierProvider.overrideWith(_Balance.new),
        generationPlatformProvider.overrideWithValue(drafts),
        estimatedCostProvider.overrideWith((ref) => 17),
        localGalleryNotifierProvider.overrideWith(_Gallery.new),
        localUpscaleTaskProvider.overrideWith(FakeNavLocalUpscale.new),
        cloudUpscaleTaskProvider.overrideWith(FakeNavCloudUpscale.new),
        bulkOperationNotifierProvider.overrideWith(FakeNavBulk.new),
        generationRetryDelayProvider.overrideWithValue((delay, _) async {
          waits.add(delay);
        }),
        // The window is in the background; the completion sound is recorded.
        completionWindowIsFocusedProvider.overrideWithValue(() async => false),
        notificationSoundPreviewProvider.overrideWithValue((path) async {
          sounds.add(path);
          return true;
        }),
      ],
    );
  }

  final _NovelAi novelAi;
  final String saveTo;
  final keys = _Keys();
  final drafts = MemoryGenerationPlatform();
  final waits = <Duration>[];
  final sounds = <String?>[];
  late final ProviderContainer container;

  GenerationBackend get backend => container.read(generationBackendProvider);
  ImageGenerationNotifier get notifier =>
      container.read(imageGenerationNotifierProvider.notifier);
  ImageGenerationState get state =>
      container.read(imageGenerationNotifierProvider);
  AuthState get auth => container.read(authNotifierProvider);
  _Account get account =>
      container.read(authNotifierProvider.notifier) as _Account;

  /// [requests] requests of [perRequest] images, auto-save and the completion
  /// sound on, the user on another page while it runs.
  Future<void> open({required int requests, int perRequest = 1}) async {
    // No system proxy is read.
    await Hive.box(
      StorageKeys.settingsBox,
    ).put(StorageKeys.proxyEnabled, false);
    await container.read(promptBlockLibraryNotifierProvider.future);
    final save = container.read(imageSaveSettingsNotifierProvider.notifier);
    await save.setCustomPath(saveTo);
    await save.setAutoSave(true);
    await container
        .read(notificationSettingsNotifierProvider.notifier)
        .setSoundEnabled(true);
    container.read(generationCompletionWatcherProvider);
    container
        .read(navActivityProvider.notifier)
        .setCurrentBranch(AppBranch.localGallery);
    container.read(generationParamsNotifierProvider.notifier)
      ..updatePromptImmediately('1girl')
      ..updateNSamples(requests);
    container.read(imagesPerRequestProvider.notifier).set(perRequest);
    container.read(generationBackendProvider);
  }

  /// Generate, as clicked on the page.
  Future<void> generate() => backend.generate(confirm: (_) async => true);

  /// Retry on the error card.
  Future<void> retry() => backend.retry(confirm: (_) async => true);

  List<File> saved() => Directory(saveTo)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.png'))
      .toList();

  void dispose() => container.dispose();
}

Future<void> _until(bool Function() condition, String reason) async {
  for (var i = 0; i < 400; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail(reason);
}

const _agentOwner = NaiAgentConversationOwner('workspace', 'chat');

/// The Agent's generation tool in the same session, writing its backups to
/// [workspace]. Prompt-set buttons and source actions start the same way.
final _agentGeneration = Provider.family<NaiAgentGenerationTools, String>(
  (ref, workspace) => bindNaiAgentGeneration(
    ref,
    Directory(workspace),
    _agentOwner,
    () => naiAgentGenerationBusy(ref),
    () => true,
  ),
);

void main() {
  late Directory hiveDir;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    hiveDir = await Directory.systemTemp.createTemp('nai_sign_out_hive_');
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
      late Directory saveDir;
      late _Studio studio;

      _Studio start(Future<ResponseBody> Function(RequestOptions) answer) {
        debugDefaultTargetPlatformOverride = platform;
        return studio = _Studio(_NovelAi(answer), saveTo: saveDir.path);
      }

      setUp(() async {
        saveDir = await Directory.systemTemp.createTemp('nai_sign_out_save_');
      });

      tearDown(() async {
        studio.dispose();
        await saveDir.delete(recursive: true);
      });

      /// The app signed out because NovelAI rejected the session: the real
      /// interceptor ran on the 401.
      void expectSignedOutBy401() {
        expect(studio.auth.status, AuthStatus.error);
        expect(studio.auth.errorCode, AuthErrorCode.authFailed);
        expect(studio.auth.httpStatusCode, 401);
        expect(studio.auth.accountId, isNull);
        expect(studio.keys.token, isNull);
      }

      /// Stopped at the 401 with [made] images kept, saved, and named on the
      /// card and in the nav; Retry is quoted for [unsent] requests.
      Future<void> expectStoppedAt401({
        required int made,
        required int unsent,
      }) async {
        final state = studio.state;
        expect(state.status, GenerationStatus.error);
        expect(isGenerationStatusStopped(state.errorMessage), isTrue);
        expect(generationFailureStatus(state.errorMessage!), 401);
        final images = state.currentImages
            .where((image) => image.canSave)
            .toList();
        expect(images, hasLength(made));
        for (final image in images) {
          expect(image.filePath, isNotNull);
          expect(File(image.filePath!).existsSync(), isTrue);
        }
        expect(studio.saved(), hasLength(made));
        expect(studio.notifier.lastRequest!.params.nSamples, unsent);
        final unread = studio.container
            .read(navActivityProvider)
            .unreadGeneration;
        expect(unread?.status, GenerationStatus.error);
        for (final locale in const [Locale('zh'), Locale('en')]) {
          final l = lookupAppLocalizations(locale);
          expect(
            generationErrorView(l, state.errorMessage).title,
            l.api_error_401,
          );
          final nav = navGenerationData(state, unread, visible: false, l10n: l);
          expect(nav.state, NavGenerationState.failed);
          expect(nav.error, l.api_error_401, reason: '$locale');
        }
        await pumpEventQueue();
        expect(studio.sounds, hasLength(1));
      }

      test(
        '401 on the third of four batches signs out; the run still stops at '
        'it, keeps and saves what it made, and Retry sends the rest',
        () async {
          start(
            (request) => studio.novelAi.requests.length <= 2
                ? _streamedImage()
                : _rejected(401, 'Unauthorized'),
          );
          await studio.open(requests: 4);

          await studio.generate();

          expectSignedOutBy401();
          // Batches 1 and 2 came back, batch 3 got 401, batch 4 was not sent.
          expect(studio.novelAi.requests, hasLength(3));
          expect(studio.waits, isEmpty);
          await expectStoppedAt401(made: 2, unsent: 2);

          // Back from the login page, signed in to the same account.
          studio.account.signIn(studio.keys);
          studio.novelAi.requests.clear();
          await studio.retry();

          expect(studio.novelAi.requests, hasLength(2));
          expect(
            studio.novelAi.requests.map(
              (request) => request.headers['Authorization'],
            ),
            everyElement('Bearer $_token'),
          );
          expect(studio.state.status, GenerationStatus.completed);
          expect(studio.saved(), hasLength(4));
        },
      );

      test("the Agent's run is not cancelled by that sign-out either: it stops "
          'at the 401 with the reason, keeps and saves what it made', () async {
        start(
          (request) => studio.novelAi.requests.length <= 2
              ? _streamedImage()
              : _rejected(401, 'Unauthorized'),
        );
        await studio.open(requests: 4);
        final workspace = await Directory.systemTemp.createTemp(
          'nai_sign_out_agent_',
        );
        addTearDown(() => workspace.delete(recursive: true));
        // The quote reads the balance the app has loaded; the app's widgets
        // keep it loaded.
        final balance = studio.container.listen(
          subscriptionNotifierProvider,
          (_, _) {},
        );
        addTearDown(balance.close);
        final tools = studio.container.read(_agentGeneration(workspace.path));
        final token = NaiAgentCancellation();
        final quote =
            (await tools.prepare({'requests': 4}, token))['details']['quote']
                as Map;
        expect(quote['can_generate'], isTrue, reason: '$quote');
        final run = tools.run({'quote_id': quote['quote_id']}, token);
        // The user clicks Generate on the Agent's request.
        final approvals = studio.container.read(
          naiAgentGenerationApprovalsProvider,
        );
        await _until(
          () => approvals.forChat(_agentOwner.chatId).isNotEmpty,
          'the Agent did not ask to generate',
        );
        approvals.decide(
          approvals.forChat(_agentOwner.chatId).single.id,
          generate: true,
        );
        final result = (await run)['details'] as Map;

        expectSignedOutBy401();
        expect(studio.novelAi.requests, hasLength(3));
        expect(result['status'], 'error');
        expect(result.containsKey('stop_reason'), isFalse, reason: '$result');
        expect(generationFailureStatus(result['error'] as String), 401);
        // The Agent reads NovelAI's 401 as upstream reports it, and that the
        // run stopped there from a field of its own. The page keeps the stop
        // marker for its reason and Retry.
        final stopped = studio.state.errorMessage!;
        expect(isGenerationStatusStopped(stopped), isTrue, reason: stopped);
        expect(result['error'], generationErrorWithoutStopMarker(stopped));
        expect(result['error'], startsWith('API_ERROR_401|'));
        expect(result['run_stopped'], 'http_status', reason: '$result');
        expect(result['images'], hasLength(2));
        await expectStoppedAt401(made: 2, unsent: 2);
      });

      test('without streaming, the 401 stops the run the same way', () async {
        start(
          (request) => _streamed(request)
              ? _rejected(400, 'Streaming is not allowed for this request')
              : studio.novelAi.count(ApiConstants.generateImageEndpoint) <= 2
              ? _zippedImage()
              : _rejected(401, 'Unauthorized'),
        );
        await studio.open(requests: 4);

        await studio.generate();

        expectSignedOutBy401();
        // Each batch asks for a stream first; batch 4 asks for nothing.
        expect(
          studio.novelAi.count(ApiConstants.generateImageStreamEndpoint),
          3,
        );
        expect(studio.novelAi.count(ApiConstants.generateImageEndpoint), 3);
        await expectStoppedAt401(made: 2, unsent: 2);
      });

      test(
        'a single image that gets 401 fails with the reason, not as cancelled',
        () async {
          start((_) => _rejected(401, 'Unauthorized'));
          await studio.open(requests: 1);

          await studio.generate();

          expectSignedOutBy401();
          expect(studio.novelAi.requests, hasLength(1));
          expect(studio.state.status, GenerationStatus.error);
          for (final locale in const [Locale('zh'), Locale('en')]) {
            final l = lookupAppLocalizations(locale);
            expect(
              generationErrorView(l, studio.state.errorMessage).title,
              l.api_error_401,
            );
          }

          studio.account.signIn(studio.keys);
          studio.novelAi.requests.clear();
          await studio.retry();
          expect(studio.novelAi.requests, hasLength(1));
        },
      );

      test(
        'a 401 on another request signs out mid-run: the run goes on to its '
        'next request, which carries no token, and stops at that 401',
        () async {
          final first = Completer<ResponseBody>();
          start(
            (request) => request.headers['Authorization'] == null
                ? _rejected(401, 'Unauthorized')
                : studio.novelAi.requests.length == 1
                ? first.future
                : _streamedImage(),
          );
          await studio.open(requests: 3);

          final run = studio.generate();
          await _until(
            () => studio.novelAi.requests.length == 1,
            'the first batch was not sent',
          );
          // The balance refresh got 401, and the interceptor signed out.
          await studio.account.logout(
            errorCode: AuthErrorCode.authFailed,
            httpStatusCode: 401,
          );
          first.complete(_streamedImage());
          await run;

          expectSignedOutBy401();
          expect(studio.novelAi.requests, hasLength(2));
          expect(studio.novelAi.requests.last.headers['Authorization'], isNull);
          await expectStoppedAt401(made: 1, unsent: 2);
        },
      );

      for (final change in ['switch account', 'sign out']) {
        test('$change during a run still cancels it', () async {
          start(
            (request) => studio.novelAi.requests.length == 1
                ? _streamedImage()
                : Completer<ResponseBody>().future,
          );
          await studio.open(requests: 3);

          final run = studio.generate();
          await _until(
            () => studio.novelAi.requests.length == 2,
            'the second batch was not sent',
          );
          if (change == 'switch account') {
            studio.account.signIn(studio.keys, id: 'account-b');
          } else {
            await studio.account.logout();
          }
          await run;

          expect(studio.state.status, GenerationStatus.cancelled);
          // The batch in flight was called off; nothing more went out.
          await studio.novelAi.cancels[1]!.timeout(const Duration(seconds: 5));
          expect(studio.novelAi.requests, hasLength(2));
        });
      }
    });
  }
}
