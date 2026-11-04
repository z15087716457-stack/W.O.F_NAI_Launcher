import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/app.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/core/krita/krita_bridge_models.dart';
import 'package:nai_launcher/core/network/dio_client.dart';
import 'package:nai_launcher/core/services/anlas_calculator.dart';
import 'package:nai_launcher/core/utils/inpaint_focus_region.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_generation_api_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_tag_suggestion_api_service.dart';
import 'package:nai_launcher/data/models/director/director_tool_type.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/services/anlas_statistics_service.dart';
import 'package:nai_launcher/data/services/anlas_usage_metrics.dart';
import 'package:nai_launcher/data/services/local_upscale_service.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/wiring/generation_backend.dart';
import '../wiring/generation_backend_test.dart' show MemoryGenerationPlatform;
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/director_tools_notifier.dart';
import 'package:nai_launcher/presentation/providers/generation/cloud_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_retry_policy.dart';
import 'package:nai_launcher/presentation/providers/generation/image_action_providers.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_service.dart';
import 'package:nai_launcher/presentation/providers/notification_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/utils/official_image_variations.dart';
import 'package:nai_launcher/presentation/wiring/tools_director_wiring.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_logger_test_isolation.dart';
import '../../helpers/balance_requests.dart';
import '../../helpers/novelai_billing.dart';

// User decision (2026-10-31, 「按每次请求的价格记」): the Anlas statistics
// record each billed NovelAI request once NovelAI delivered it, at the price
// the app shows or quotes for it, without asking anything; a lower balance
// on a later click records nothing.

const _stream = ApiConstants.generateImageStreamEndpoint;
const _model = ImageModels.animeDiffusionV45Full;

/// An Opus account whose free quota is far from used up: a one-image
/// request of at most 1 MP and 28 steps costs nothing.
Map<String, dynamic> _opusAnswer() => {
  'tier': 3,
  'active': true,
  'trainingStepsLeft': {
    'fixedTrainingStepsLeft': 5000,
    'purchasedTrainingSteps': 0,
  },
  'usage': {'percent': 80.0, 'purchasedPercent': 0.0, 'isNegative': false},
};

class _OpusAuth extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    accountId: 'synthetic-opus',
    displayName: 'Synthetic Opus',
    subscriptionInfo: _opusAnswer(),
  );
}

/// A balance click on that Opus account finds its free quota used up.
class _QuotaRunOut extends BalanceRequests {
  @override
  Future<Map<String, dynamic>> getUserSubscription({
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) async {
    requests++;
    return {
      ..._opusAnswer(),
      'usage': {'percent': 0.0, 'purchasedPercent': 0.0, 'isNegative': true},
    };
  }
}

class _LocalUpscaler extends Mock implements LocalUpscaleService {}

/// The bridge's price helper, as `kritaBridgeNotifierProvider` reads it.
final _bridgeBilling = Provider<Map<String, dynamic> Function(ImageParams)>(
  (ref) =>
      (params) => readBridgeBilling(ref, params),
);

/// One app session against [novelAi], logged in with the real balance
/// notifier ([balances] counts every balance request), its Anlas
/// statistics kept in [spend] (or, with [realStatistics], in preferences).
class _Session {
  _Session({
    AuthNotifier Function() auth = ValidatedBalanceAuth.new,
    BalanceRequests? balances,
    bool realStatistics = false,
    List<Override> overrides = const [],
  }) : balances = balances ?? BalanceRequests() {
    container = ProviderContainer(
      overrides: [
        imageGenerationDioClientProvider.overrideWithValue(
          Dio()..httpClientAdapter = novelAi,
        ),
        dioClientProvider.overrideWithValue(Dio()..httpClientAdapter = novelAi),
        ...realBalanceOverrides(this.balances, auth: auth),
        if (!realStatistics)
          anlasStatisticsServiceProvider.overrideWith(() => spend),
        generationRetryDelayProvider.overrideWithValue((_, __) async {}),
        ...overrides,
      ],
    );
  }

  final novelAi = FakeNovelAi();
  final BalanceRequests balances;
  final spend = SpendRecords();
  late final ProviderContainer container;

  ImageGenerationNotifier get generation =>
      container.read(imageGenerationNotifierProvider.notifier);

  Future<void> open({
    String model = _model,
    int requests = 1,
    int perRequest = 1,
    (int, int) size = (832, 1216),
  }) async {
    await container
        .read(notificationSettingsNotifierProvider.notifier)
        .setSoundEnabled(false);
    await container
        .read(imageSaveSettingsNotifierProvider.notifier)
        .setAutoSave(false);
    container.read(generationParamsNotifierProvider.notifier)
      ..updateModel(model)
      ..updateSize(size.$1, size.$2)
      ..updateSteps(28)
      ..updatePromptImmediately('1girl, garden')
      ..updateNSamples(requests);
    container.read(imagesPerRequestProvider.notifier).set(perRequest);
    // The real balance notifier, read before the work as the screens keep
    // it. The token validation brought the balance: nothing asked.
    expect(container.read(subscriptionNotifierProvider).balance, 5000);
  }

  /// Generate as the generation page does: the request it projects, with
  /// the images per request it shows. Returns the price it shows.
  Future<int> generate() async {
    final request = container.read(generationRequestParamsProvider);
    final shown = container.read(estimatedCostProvider);
    await generation.generate(
      request,
      imagesPerRequestOverride: container.read(imagesPerRequestProvider),
    );
    return shown;
  }

  /// What the statistics were given, once the records started have landed.
  Future<List<int>> recorded() async {
    await pumpEventQueue();
    return spend.amounts;
  }

  /// Ends the session once anything the work left running has had time to
  /// show (the removed post-billing balance request came 0.5 s late): after
  /// the test's own requests, neither the balance nor NovelAI may be asked
  /// again.
  Future<void> dispose() async {
    final asked = balances.requests;
    final sent = novelAi.paths.length;
    await Future<void>.delayed(afterBilledWork);
    expect(balances.requests, asked, reason: 'the balance was asked later');
    expect(novelAi.paths.length, sent, reason: 'NovelAI was asked later');
    container.dispose();
    expect(novelAi.unexpected, isEmpty, reason: 'only NovelAI was faked');
  }
}

const _serviceFiles = {
  'NAIImageGenerationApiService':
      'lib/data/datasources/remote/nai_image_generation_api_service.dart',
  'NAIImageEnhancementApiService':
      'lib/data/datasources/remote/nai_image_enhancement_api_service.dart',
};

const _apiConstantsFile = 'lib/core/constants/api_constants.dart';
const _ledgerFile = 'lib/data/services/anlas_request_ledger.dart';

/// A path under NovelAI's /ai/ in the text of one string literal: with or
/// without its leading slash (the endpoint service adds a missing one),
/// whole, or a piece that `+`, an adjacent literal or an interpolation
/// finishes ('/ai/', 'ai/', '$base/ai', '/ai/$tool').
final _aiPath = RegExp(r'^ai/|/ai(?:/|$|(?=\$))');

/// The one free path there: tag suggestions.
final _freeAiPath = RegExp(r'/?ai/generate-image/suggest-tags(?![\w-])');

bool _reachesBilledPath(String text) =>
    _aiPath.hasMatch(text.replaceAll(_freeAiPath, ''));

/// One-line string literals, raw or not: the quote, the text, the quote.
final _literal = RegExp(r'''r?(['"])((?:\\.|(?!\1)[^\\\n])*)\1''');

/// A string constant, the way api_constants.dart declares its endpoints.
final _stringConstant = RegExp(
  r'''static const String (\w+)\s*=\s*(['"])((?:\\.|(?!\2)[^\\\n])*)\2\s*;''',
);

/// The billed paths among the string constants of [apiConstants] (the source
/// of api_constants.dart), as `Class.name`. They are read by their value, so
/// a new or renamed one counts as well.
Set<String> billedConstantsIn(String apiConstants) {
  final types = RegExp(
    r'^(?:[a-z]+ )*(?:class|enum|mixin) (\w+)',
    multiLine: true,
  ).allMatches(apiConstants);
  return {
    for (final constant in _stringConstant.allMatches(apiConstants))
      if (_reachesBilledPath(constant[3]!))
        '${types.lastWhere((type) => type.start < constant.start)[1]}'
            '.${constant[1]}',
  };
}

/// A service built (its unnamed constructor, or a named one), declared or
/// called.
final _serviceCall = RegExp(
  r'\b(NAIImageGenerationApiService|NAIImageEnhancementApiService)'
  r'(\.[A-Za-z_]\w*)?\s*\(',
);

final _serviceTearOff = RegExp(
  r'\b(?:NAIImageGenerationApiService|NAIImageEnhancementApiService)\.new\b',
);

final _serviceSubtype = RegExp(
  r'\b(?:extends|implements|with)\s+'
  r'(?:NAIImageGenerationApiService|NAIImageEnhancementApiService)\b',
);

/// How the two providers build their service: with the app's ledger.
final _providerBuild = RegExp(
  r'return (?:NAIImageGenerationApiService|NAIImageEnhancementApiService)'
  r'\([^;]*ledger: ref\.watch\(anlasRequestLedgerProvider\),?\s*\);',
);

/// What in [source] (the file at [path], relative to the package) reaches a
/// billed NovelAI endpoint outside the two image API services, or builds one
/// of them anywhere but in its own provider with the app's ledger, or puts
/// another ledger in its place. [billedConstants] are the billed endpoint
/// constants ([billedConstantsIn]). Every billed request records itself in
/// those services (AnlasRequestLedger); a way around them would spend Anlas
/// the statistics never see.
List<String> billedRequestBypasses(
  String path,
  String source,
  Set<String> billedConstants,
) {
  final found = <String>[];
  if (!_serviceFiles.containsValue(path)) {
    final constants = path == _apiConstantsFile;
    // api_constants.dart writes each billed path once, as a string constant
    // that billedConstantsIn reads; elsewhere they are followed by name.
    final rest = constants ? source.replaceAll(_stringConstant, '') : source;
    for (final literal in _literal.allMatches(rest)) {
      if (_reachesBilledPath(literal[2]!)) found.add('$path: ${literal[0]}');
    }
    for (final constant in billedConstants) {
      final name = constants ? constant.split('.').last : constant;
      final uses = RegExp(
        '\\b${RegExp.escape(name)}\\b',
      ).allMatches(source).length;
      if (uses > (constants ? 1 : 0)) found.add('$path: $constant');
    }
  }
  for (final match in [
    ..._serviceSubtype.allMatches(source),
    ..._serviceTearOff.allMatches(source),
  ]) {
    found.add('$path: ${match[0]}');
  }
  for (final match in _serviceCall.allMatches(source)) {
    final ownFile = _serviceFiles[match[1]] == path;
    final unnamed = match[2] == null;
    // The constructor itself, the class's only one: a member of the class
    // (two spaces in) whose parameters start with `this._dio`.
    final line = source.substring(
      source.lastIndexOf('\n', match.start) + 1,
      match.start,
    );
    final declaration =
        ownFile &&
        unnamed &&
        line == '  ' &&
        source.substring(match.end).trimLeft().startsWith('this._dio');
    final returned = source.lastIndexOf('return', match.start);
    final provider =
        ownFile &&
        unnamed &&
        returned >= 0 &&
        source.substring(returned, match.start).trim() == 'return' &&
        _providerBuild.matchAsPrefix(source, returned) != null;
    if (!declaration && !provider) found.add('$path: ${match[0]}');
  }
  if (path != _ledgerFile) {
    for (final match in RegExp(
      r'\bAnlasRequestLedger\s*\(|\banlasRequestLedgerProvider\.overrid',
    ).allMatches(source)) {
      found.add('$path: ${match[0]}');
    }
  }
  return found;
}

Future<void> _until(bool Function() condition, String reason) async {
  for (var i = 0; i < 400; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail(reason);
}

void main() {
  late Directory hive;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(LocalUpscaleCancellation());
    registerFallbackValue(const Seedvr2Options());
    hive = await Directory.systemTemp.createTemp('anlas_request_billing_');
    Hive.init(hive.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
    await Hive.openBox(StorageKeys.statisticsCacheBox);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  tearDown(() async {
    await Hive.box(StorageKeys.settingsBox).clear();
    await Hive.box(StorageKeys.historyBox).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hive.exists()) await hive.delete(recursive: true);
    await AppLoggerTestIsolation.tearDown();
  });

  group('each billed request records once, at its price', () {
    late _Session session;
    tearDown(() => session.dispose());

    test('a generation: every request at the price the page shows, nothing '
        'asked', () async {
      session = _Session();
      await session.open(requests: 2, perRequest: 2);
      final shown = await session.generate();
      expect(
        session.container.read(imageGenerationNotifierProvider).status,
        GenerationStatus.completed,
      );
      expect(shown, greaterThan(0));
      // Two requests of two images: one record per request.
      expect(await session.recorded(), [shown ~/ 2, shown ~/ 2]);
      // Recording sends nothing: the two generations are all NovelAI saw,
      // and the balance was never asked.
      expect(session.novelAi.paths, [_stream, _stream]);
      expect(session.balances.requests, 0);
    });

    test(
      'a known zero balance still sends Generate, manual Retry, and an explore candidate',
      () async {
        session = _Session(
          overrides: [
            generationPlatformProvider.overrideWithValue(
              MemoryGenerationPlatform(),
            ),
          ],
        );
        await session.open();
        session.balances.balance = 0;
        await session.container
            .read(subscriptionNotifierProvider.notifier)
            .refreshBalance();
        expect(session.container.read(subscriptionNotifierProvider).balance, 0);
        expect(session.container.read(isBalanceInsufficientProvider), isTrue);
        final quoted = session.container.read(estimatedCostProvider);
        expect(quoted, greaterThan(0));
        final backend = session.container.read(generationBackendProvider);
        final confirms = <int>[];
        Future<bool> confirm(int cost) async {
          confirms.add(cost);
          return true;
        }

        session.novelAi.refuse = (index, _) => index == 0 ? 402 : null;
        await backend.generate(confirm: confirm);
        expect(session.novelAi.paths, [_stream]);
        expect(
          session.container.read(imageGenerationNotifierProvider).status,
          GenerationStatus.error,
        );
        expect(await session.recorded(), isEmpty);
        await backend.retry(confirm: confirm);
        expect(confirms, [quoted, quoted]);
        expect(session.novelAi.paths, [_stream, _stream]);
        expect(
          session.container.read(imageGenerationNotifierProvider).status,
          GenerationStatus.completed,
        );

        final candidate = await session.generation.generateForExplore(
          session.container
              .read(generationParamsNotifierProvider)
              .copyWith(prompt: 'artist:fixture'),
        );
        expect(candidate, isNotNull);
        expect(session.novelAi.paths, [_stream, _stream, _stream]);
        expect(await session.recorded(), [quoted, quoted]);
        expect(session.container.read(subscriptionNotifierProvider).balance, 0);
        expect(
          session.balances.requests,
          1,
          reason: 'only the explicit balance refresh',
        );
      },
    );

    test('a single image: one record at its price', () async {
      session = _Session();
      await session.open();
      final shown = await session.generate();
      expect(shown, 20);
      expect(await session.recorded(), [20]);
      expect(session.novelAi.paths, [_stream]);
    });

    test('a stream answered with a ZIP (a non-streamed answer): one record '
        'at its price', () async {
      session = _Session();
      await session.open();
      session.novelAi.streamAnswer = StreamAnswer.zip;
      final shown = await session.generate();
      expect(
        session.container.read(imageGenerationNotifierProvider).status,
        GenerationStatus.completed,
      );
      expect(shown, 20);
      expect(await session.recorded(), [20]);
      expect(session.novelAi.paths, [_stream]);
    });

    test('a manual retry records each newly sent request again', () async {
      session = _Session();
      await session.open();
      final shown = await session.generate();
      expect(await session.recorded(), [shown]);
      await session.generation.retry(session.generation.lastRequest!);
      expect(session.container.read(imageGenerationNotifierProvider).status,
          GenerationStatus.completed);
      expect(await session.recorded(), [shown, shown]);
      expect(session.novelAi.paths, [_stream, _stream]);
      expect(session.balances.requests, 0);
    });

    test('a three-image ZIP on the stream endpoint publishes every image in archive order', () async {
      session = _Session();
      await session.open(perRequest: 3);
      final originals = [
        for (var index = 0; index < 3; index++) syntheticPng(32 + index, 48),
      ];
      session.novelAi
        ..streamAnswer = StreamAnswer.zip
        ..zipImages = originals;
      final shown = await session.generate();
      final state = session.container.read(imageGenerationNotifierProvider);
      expect(state.currentImages.map((image) => image.batchIndex), [0, 1, 2]);
      expect(state.currentImages.map((image) => image.bytes), originals);
      expect(state.status, GenerationStatus.completed);
      expect(await session.recorded(), [shown]);
      expect(session.novelAi.paths, [_stream]);
    });

    for (final format in [
      StreamAnswer.zip,
      StreamAnswer.events,
      StreamAnswer.dataMessage,
    ]) {
      test(
        'a clean EOF after one of three images in $format keeps the image and quotes only unsent requests',
        () async {
          session = _Session();
          await session.open(requests: 2, perRequest: 3);
          session.novelAi
            ..streamAnswer = format
            ..streamImagesBeforeEnd = 1
            ..zipImages = [syntheticPng(32, 48)];
          final shown = await session.generate();
          final state = session.container.read(imageGenerationNotifierProvider);
          expect(state.status, GenerationStatus.error);
          expect(state.currentImages.map((image) => image.batchIndex), [0]);
          expect(state.partialBatch, (
            received: 1,
            expected: 3,
            unsentRequests: 1,
          ));
          expect(session.novelAi.paths, [_stream]);
          expect(await session.recorded(), isEmpty);
          final pending = session.generation.lastRequest!;
          expect((pending.params.nSamples, pending.count), (1, 3));
          session.novelAi
            ..streamAnswer = StreamAnswer.events
            ..streamImagesBeforeEnd = null
            ..zipImages = null;
          await session.generation.retry(pending);
          expect(session.novelAi.paths, [_stream, _stream]);
          expect(await session.recorded(), [shown ~/ 2]);
          expect(
            session.container
                .read(imageGenerationNotifierProvider)
                .history
                .where((image) => image.canSave),
            hasLength(4),
          );
        },
      );
    }

    test('a short ZIP from the actual non-stream fallback is retained without charging or repeating the accepted batch', () async {
      session = _Session();
      await session.open(requests: 2, perRequest: 3);
      final only = syntheticPng(41, 67);
      session.novelAi
        ..streamErrorEvent = 'Streaming is not allowed for this request'
        ..zipImages = [only];
      final shown = await session.generate();
      final state = session.container.read(imageGenerationNotifierProvider);
      expect(session.novelAi.paths, [
        _stream,
        ApiConstants.generateImageEndpoint,
      ]);
      expect(state.status, GenerationStatus.error);
      expect(state.currentImages.single.bytes, only);
      expect(state.partialBatch, (received: 1, expected: 3, unsentRequests: 1));
      expect(await session.recorded(), isEmpty);
      final pending = session.generation.lastRequest!;
      expect((pending.params.nSamples, pending.count), (1, 3));
      session.novelAi
        ..streamErrorEvent = null
        ..zipImages = null;
      await session.generation.retry(pending);
      expect(session.novelAi.paths, [
        _stream,
        ApiConstants.generateImageEndpoint,
        _stream,
      ]);
      expect(await session.recorded(), [shown ~/ 2]);
      expect(
        session.container
            .read(imageGenerationNotifierProvider)
            .history
            .where((image) => image.canSave),
        hasLength(4),
      );
    });

    test('a truncated paid stream keeps its final image and never replays that request', () async {
      session = _Session();
      await session.open(requests: 3, perRequest: 2);
      session.novelAi.refuse = (index, _) {
        session.novelAi.streamImagesBeforeEnd = index == 1 ? 1 : null;
        return null;
      };
      final shown = await session.generate();
      final state = session.container.read(imageGenerationNotifierProvider);
      expect(state.status, GenerationStatus.error);
      expect(state.currentImages.map((image) => image.batchIndex), [0, 1, 2]);
      expect(session.novelAi.paths, [_stream, _stream]);
      final oneRequest = shown ~/ 3;
      expect(await session.recorded(), [oneRequest]);
      final pending = session.generation.lastRequest!;
      expect((pending.params.nSamples, pending.count), (1, 2));
      await session.generation.retry(pending);
      expect(session.novelAi.paths, [_stream, _stream, _stream]);
      expect(await session.recorded(), [oneRequest, oneRequest]);
      expect(session.balances.requests, 0);
    });

    test('a retry records only the requests it sends again', () async {
      session = _Session();
      await session.open(requests: 3);
      // The second of three requests is refused (not enough Anlas): the run
      // stops, the first one was billed.
      session.novelAi.refuse = (index, _) => index == 1 ? 402 : null;
      final shown = await session.generate();
      final state = session.container.read(imageGenerationNotifierProvider);
      expect(state.status, GenerationStatus.error);
      final price = shown ~/ 3;
      expect(await session.recorded(), [price]);
      final retry = session.generation.lastRequest!;
      expect(retry.params.nSamples, 2);
      final quoted = generationRequestCost(
        retry.params,
        retry.workflow,
        session.container.read(subscriptionNotifierProvider).subscription,
        retry.count,
      );
      session.novelAi.refuse = null;
      await session.generation.retry(retry);
      expect(
        session.container.read(imageGenerationNotifierProvider).status,
        GenerationStatus.completed,
      );
      expect(await session.recorded(), [price, price, price]);
      expect(quoted, price * 2);
      expect(session.novelAi.paths, [_stream, _stream, _stream, _stream]);
      expect(session.balances.requests, 0);
    });

    test('an automatic retry after a server error records the request that '
        'succeeded', () async {
      session = _Session();
      await session.open(requests: 2);
      // A run of several requests tries a request again after a server
      // error: the failed attempt is not recorded, the one that came back
      // is.
      session.novelAi.refuse = (index, _) => index == 0 ? 500 : null;
      final shown = await session.generate();
      expect(
        session.container.read(imageGenerationNotifierProvider).status,
        GenerationStatus.completed,
      );
      expect(await session.recorded(), [shown ~/ 2, shown ~/ 2]);
      expect(session.novelAi.paths, [_stream, _stream, _stream]);
    });

    test('a variation: one record at the price its button shows', () async {
      session = _Session();
      await session.open();
      final source = syntheticPng(832, 1216);
      const metadata = NaiImageMetadata(
        prompt: '1girl, garden',
        seed: 7,
        steps: 28,
        width: 832,
        height: 1216,
        model: _model,
      );
      final image = GeneratedImage.create(
        source,
        width: 832,
        height: 1216,
        metadata: metadata,
      );
      final keep = session.container.listen(
        imageVariationCostProvider(image),
        (_, __) {},
      );
      addTearDown(keep.close);
      await session.container.read(
        generatedImageMetadataProvider(image).future,
      );
      final shown = session.container.read(imageVariationCostProvider(image));
      expect(shown, greaterThan(0));
      final params = OfficialImageVariations.project(
        current: session.container.read(generationParamsNotifierProvider),
        source: source,
        width: 832,
        height: 1216,
        metadata: metadata,
      );
      await session.generation.generateOfficialVariations(
        params,
        original: GeneratedImage.create(
          source,
          width: 832,
          height: 1216,
          metadata: metadata,
          isVariationOriginal: true,
        ),
      );
      expect(
        session.container.read(imageGenerationNotifierProvider).status,
        GenerationStatus.completed,
      );
      // One request of three images.
      expect(await session.recorded(), [shown]);
      expect(session.novelAi.paths, [_stream]);
    });

    test(
      'a style explore candidate: one record at the explore price',
      () async {
        session = _Session();
        await session.open();
        final shown = session.container.read(
          styleExploreCostForCountProvider(1),
        );
        expect(shown, greaterThan(0));
        final draft = session.container.read(generationParamsNotifierProvider);
        final result = await session.generation.generateForExplore(
          draft.copyWith(prompt: 'artist:synthetic, ${draft.prompt}'),
        );
        expect(result, isNotNull);
        expect(await session.recorded(), [shown]);
        expect(session.novelAi.paths, [_stream]);
      },
    );

    /// Run [tool] on a 1024×1024 image as the director page does, with the
    /// label it shows (its price on the account the page reads). Returns the
    /// label.
    Future<int> runDirectorTool(
      DirectorToolType tool,
      ToolsDirectorTool shownAs,
    ) async {
      final director = session.container.read(
        directorToolsNotifierProvider.notifier,
      );
      director
        ..addSource(syntheticPng(1024, 1024))
        ..selectTool(tool);
      final subscription = session.container
          .read(subscriptionNotifierProvider)
          .subscription;
      final shown = toolsDirectorView(
        session.container.read(directorToolsNotifierProvider),
        opus: subscription?.isOpus == true,
      ).costs[shownAs]!;
      await director.runTool(quotedCost: shown);
      expect(session.container.read(directorToolsNotifierProvider).error, null);
      expect(await session.recorded(), [shown]);
      expect(session.novelAi.paths, [ApiConstants.augmentImageEndpoint]);
      expect(session.balances.requests, 0);
      return shown;
    }

    test('a director tool: one record at the price it shows', () async {
      session = _Session();
      await session.open();
      // Background removal at 1 MP: 20 × 3 + 5.
      expect(
        await runDirectorTool(
          DirectorToolType.removeBackground,
          ToolsDirectorTool.removeBackground,
        ),
        65,
      );
    });

    test('an Opus director tool at 1 MP is free, and records 0', () async {
      session = _Session(auth: _OpusAuth.new);
      await session.open();
      expect(
        await runDirectorTool(
          DirectorToolType.extractLineArt,
          ToolsDirectorTool.lineArt,
        ),
        0,
      );
    });

    test('a cloud upscale: one record at the upscale price', () async {
      session = _Session();
      await session.open();
      session.container
          .read(imageWorkflowControllerProvider.notifier)
          .updateUpscaleBackend(UpscaleBackend.novelai);
      final source = syntheticPng(1024, 1536);
      final image = GeneratedImage.create(source, width: 1024, height: 1536);
      final shown = session.container.read(imageUpscaleCostProvider(image));
      expect(shown, 2);
      final result = await session.container
          .read(cloudUpscaleTaskProvider.notifier)
          .processGenerated(source, cancellation: CancelToken());
      expect(result, isNotNull);
      expect(await session.recorded(), [shown]);
      expect(session.novelAi.paths, [ApiConstants.upscaleEndpoint]);
      expect(session.balances.requests, 0);
    });

    test('a vibe encoding: one record; a cached one sends nothing', () async {
      session = _Session();
      await session.open();
      final params = session.container.read(
        generationParamsNotifierProvider.notifier,
      );
      final image = syntheticPng(64, 64);
      for (var i = 0; i < 2; i++) {
        expect(
          await params.encodeVibeWithCache(image, model: _model),
          'BwcHBw==',
        );
      }
      expect(await session.recorded(), [AnlasCalculator.vibeEncodingCost]);
      expect(session.novelAi.paths, [ApiConstants.encodeVibeEndpoint]);
    });

    test('a generation that encodes a vibe: the encoding and the image, '
        'together the price the page shows', () async {
      session = _Session();
      await session.open();
      session.container
          .read(generationParamsNotifierProvider.notifier)
          .addVibeReference(
            VibeReference(
              displayName: 'synthetic vibe',
              vibeEncoding: '',
              rawImageData: syntheticPng(64, 64),
            ),
          );
      final shown = await session.generate();
      expect(
        session.container.read(imageGenerationNotifierProvider).status,
        GenerationStatus.completed,
      );
      expect(
        await session.recorded(),
        unorderedEquals([
          AnlasCalculator.vibeEncodingCost,
          shown - AnlasCalculator.vibeEncodingCost,
        ]),
      );
      expect(session.novelAi.paths, [ApiConstants.encodeVibeEndpoint, _stream]);
    });

    test(
      'a Krita / external bridge generation: one record at its quote',
      () async {
        session = _Session();
        await session.open();
        final c = session.container;
        final sent = <Map<String, dynamic>>[];
        // The bridge's own wiring (kritaBridgeNotifierProvider) against the
        // session's API service.
        final service = KritaBridgeService(
          readBaseParams: () => c.read(generationParamsNotifierProvider),
          prepareParams: c.read(kritaBridgePromptPreparerProvider),
          readBilling: c.read(_bridgeBilling),
          send: sent.add,
          isUiGenerating: () =>
              c.read(imageGenerationNotifierProvider).isGenerating,
          generateStream: (request) => c
              .read(naiImageGenerationApiServiceProvider)
              .generateImageStream(request.params),
          generateFallback: (request) => c
              .read(naiImageGenerationApiServiceProvider)
              .generateImageArtifactsCancellable(
                request.params,
                onProgress: (_, __) {},
              ),
          registerExternalImage: (_, {required params, addToDisplay}) async =>
              null,
          cancelGeneration: () =>
              c.read(naiImageGenerationApiServiceProvider).cancelGeneration(),
          failureCooldown: Duration.zero,
        );
        // What the bridge quotes first, as a client asks before generating.
        await service.handle(
          const KritaQuoteMessage(id: 'synthetic-quote', payload: {}),
        );
        final quote = sent.single['billing'] as Map<String, dynamic>;
        expect(quote['estimated_anlas'], 20);
        await service.handle(
          const KritaGenerateMessage(id: 'synthetic', payload: {}),
        );
        expect(sent.last['type'], 'result');
        expect(await session.recorded(), [quote['estimated_anlas']]);
        expect(session.novelAi.paths, [_stream]);
      },
    );

    test('an Opus-free request records 0, as its price shows', () async {
      session = _Session(auth: _OpusAuth.new);
      await session.open();
      final shown = await session.generate();
      expect(shown, 0);
      expect(
        session.container.read(imageGenerationNotifierProvider).status,
        GenerationStatus.completed,
      );
      expect(await session.recorded(), [0]);
    });

    test(
      'the Opus-free price follows the cached quota, and the record with it',
      () async {
        // User decision (2026-10-31): the quota is asked again only when the
        // cached one is under 5 %. Until then a request the server may bill
        // is shown, and recorded, as free; a click that finds the quota used
        // up makes the next one show and record its price.
        session = _Session(auth: _OpusAuth.new, balances: _QuotaRunOut());
        await session.open(model: ImageModels.animeDiffusionV5Full);
        expect(await session.generate(), 0);
        expect(await session.recorded(), [0]);
        expect(
          await session.container
              .read(subscriptionNotifierProvider.notifier)
              .refreshBalance(),
          isTrue,
        );
        expect(await session.generate(), 30);
        expect(await session.recorded(), [0, 30]);
        expect(session.balances.requests, 1);
        expect(session.novelAi.paths, [_stream, _stream]);
      },
    );
  });

  group('at the NovelAI image API', () {
    late _Session session;
    tearDown(() => session.dispose());

    test(
      'a non-stream request records once; a refused one not at all',
      () async {
        session = _Session();
        await session.open();
        final api = session.container.read(
          naiImageGenerationApiServiceProvider,
        );
        final request = session.container
            .read(generationRequestParamsProvider)
            .copyWith(nSamples: 2);
        final (images, _) = await api.generateImage(request);
        expect(images, hasLength(2));
        session.novelAi.refuse = (_, __) => 402;
        await expectLater(
          api.generateImage(request),
          throwsA(isA<DioException>()),
        );
        expect(await session.recorded(), [40]);
        expect(session.novelAi.paths, [
          ApiConstants.generateImageEndpoint,
          ApiConstants.generateImageEndpoint,
        ]);
      },
    );

    test(
      'a vibe the request encodes while it is built (a bridge request) '
      'records the encoding with the image: together the bridge quote',
      () async {
        session = _Session();
        await session.open();
        final request = session.container
            .read(generationRequestParamsProvider)
            .copyWith(
              vibeReferencesV4: [
                VibeReference(
                  displayName: 'synthetic vibe',
                  vibeEncoding: '',
                  rawImageData: syntheticPng(64, 64),
                ),
              ],
            );
        final quote = session.container.read(_bridgeBilling)(request);
        expect(quote['encoding_anlas'], AnlasCalculator.vibeEncodingCost);
        final chunks = await session.container
            .read(naiImageGenerationApiServiceProvider)
            .generateImageStream(request)
            .toList();
        expect(chunks.last.hasFinalImage, isTrue);
        final recorded = await session.recorded();
        expect(
          recorded,
          unorderedEquals([
            AnlasCalculator.vibeEncodingCost,
            quote['per_request_anlas'],
          ]),
        );
        expect(
          recorded.fold<int>(0, (sum, anlas) => sum + anlas),
          quote['estimated_anlas'],
        );
        expect(session.novelAi.paths, [
          ApiConstants.encodeVibeEndpoint,
          _stream,
        ]);
      },
    );
  });

  // The generation page's label comes from its own calculator
  // (generationRequestCost, from the workflow); the record from the request
  // sent. Wherever the price depends on more than the size, both must agree.
  group('what is recorded is the label the generation page shows', () {
    late _Session session;
    tearDown(() => session.dispose());

    /// Generate as the page does; the records, one per request, add up to
    /// the label. Returns the label.
    Future<int> recordsTheLabel({int requests = 1}) async {
      final shown = await session.generate();
      final state = session.container.read(imageGenerationNotifierProvider);
      expect(
        state.status,
        GenerationStatus.completed,
        reason: state.errorMessage,
      );
      expect(shown % requests, 0);
      expect(
        await session.recorded(),
        List.filled(requests, shown ~/ requests),
      );
      expect(session.novelAi.paths, List.filled(requests, _stream));
      return shown;
    }

    test('an inpaint with a focus area', () async {
      session = _Session();
      await session.open(size: (512, 512));
      session.container.read(generationParamsNotifierProvider.notifier)
        ..setSourceImage(syntheticPng(512, 512))
        ..setMaskImage(
          syntheticMask(512, 512, (x: 224, y: 224, width: 64, height: 64)),
          focusRegion: const InpaintFocusRegion(
            x: 128,
            y: 128,
            width: 256,
            height: 256,
          ),
        )
        ..updateAction(ImageGenerationAction.infill);
      // The focus area goes out at about 1 MP (1024×1024): 20, not the 5 of
      // the whole 512×512 image.
      expect(await recordsTheLabel(), 20);
    });

    test('a Max enhance', () async {
      session = _Session();
      await session.open(model: ImageModels.animeDiffusionV5Full);
      session.container.read(imageWorkflowControllerProvider.notifier)
        ..openTemporaryTool(syntheticPng(832, 1216), ImageWorkflowMode.enhance)
        ..setEnhanceMaxUpscale(true);
      expect(
        session.container.read(generationRequestParamsProvider).upscaledEnhance,
        isTrue,
      );
      // Priced on the 1440×2144 the server upscales to, at strength 0.5:
      // 45, not the 15 of the 832×1216 source.
      expect(await recordsTheLabel(), 45);
    });

    test('an image to image at strength 0.4', () async {
      session = _Session();
      await session.open();
      session.container.read(generationParamsNotifierProvider.notifier)
        ..setSourceImage(syntheticPng(832, 1216))
        ..updateAction(ImageGenerationAction.img2img)
        ..updateStrength(0.4);
      expect(await recordsTheLabel(), 8);
    });

    test('a V4.5 character reference', () async {
      session = _Session();
      await session.open();
      session.container
          .read(generationParamsNotifierProvider.notifier)
          .addPreciseReference(
            syntheticPng(64, 64),
            type: PreciseRefType.character,
          );
      // 20 for the image, 5 for the reference.
      expect(await recordsTheLabel(), 25);
    });

    test('more than four Vibes', () async {
      session = _Session();
      await session.open(requests: 2);
      session.container
          .read(generationParamsNotifierProvider.notifier)
          .addVibeReferences([
            for (var i = 0; i < 5; i++)
              VibeReference(
                displayName: 'synthetic vibe $i',
                vibeEncoding: 'BwcHBw==',
                encodingModel: _model,
                sourceType: VibeSourceType.naiv4vibe,
              ),
          ], recordUsage: false);
      // Each request: 20, and 2 for the fifth Vibe.
      expect(await recordsTheLabel(requests: 2), 44);
    });

    test('Turbo', () async {
      session = _Session();
      await session.open(model: ImageModels.animeDiffusionV5FullMedium);
      // Fixed 14 steps at the Turbo rate: 17, not the 30 of V5 Full.
      expect(await recordsTheLabel(), 17);
    });

    test('Opus with several images per request', () async {
      session = _Session(auth: _OpusAuth.new);
      await session.open(requests: 2, perRequest: 3);
      // Each request: its first image free, two at 20.
      expect(await recordsTheLabel(requests: 2), 80);
    });
  });

  group('nothing is recorded for', () {
    late _Session session;
    tearDown(() => session.dispose());

    test('a request NovelAI refuses, on every billed endpoint', () async {
      session = _Session();
      await session.open();
      final c = session.container;
      session.novelAi.refuse = (_, __) => 402;
      // A generation (streamed), and the same request not streamed.
      await session.generate();
      expect(
        c.read(imageGenerationNotifierProvider).status,
        GenerationStatus.error,
      );
      await expectLater(
        c
            .read(naiImageGenerationApiServiceProvider)
            .generateImage(c.read(generationRequestParamsProvider)),
        throwsA(isA<DioException>()),
      );
      // A cloud upscale.
      expect(
        await c
            .read(cloudUpscaleTaskProvider.notifier)
            .processGenerated(
              syntheticPng(64, 64),
              cancellation: CancelToken(),
            ),
        isNull,
      );
      // A vibe encoding.
      expect(
        await c
            .read(generationParamsNotifierProvider.notifier)
            .encodeVibeWithCache(syntheticPng(64, 64), model: _model),
        isNull,
      );
      // A director tool.
      final director = c.read(directorToolsNotifierProvider.notifier);
      director
        ..addSource(syntheticPng(1024, 1024))
        ..selectTool(DirectorToolType.removeBackground);
      await director.runTool(
        quotedCost: c.read(directorToolsNotifierProvider).estimatedAnlasCost(),
      );
      expect(c.read(directorToolsNotifierProvider).error, isNotNull);
      expect(await session.recorded(), isEmpty);
      // Each refused once, and nothing else was sent.
      expect(session.novelAi.paths, [
        _stream,
        ApiConstants.generateImageEndpoint,
        ApiConstants.upscaleEndpoint,
        ApiConstants.encodeVibeEndpoint,
        ApiConstants.augmentImageEndpoint,
      ]);
    });

    test('a single-image request with a data message publishes that image and records one charge', () async {
      session = _Session();
      await session.open();
      session.novelAi.streamAnswer = StreamAnswer.dataMessage;
      final shown = await session.generate();
      final state = session.container.read(imageGenerationNotifierProvider);
      expect(state.status, GenerationStatus.completed);
      expect(state.currentImages, hasLength(1));
      expect(await session.recorded(), [shown]);
      expect(session.novelAi.paths, [_stream]);
    });

    test('a request cancelled before NovelAI answered', () async {
      session = _Session();
      await session.open();
      session.novelAi.hold = Completer<void>();
      final run = session.generate();
      await _until(
        () => session.novelAi.paths.isNotEmpty,
        'the generation never reached NovelAI',
      );
      session.generation.cancel();
      await run;
      session.novelAi.hold!.complete();
      expect(
        session.container.read(imageGenerationNotifierProvider).status,
        GenerationStatus.cancelled,
      );
      expect(await session.recorded(), isEmpty);
    });

    test('a stream NovelAI ends early or reports an error in', () async {
      session = _Session();
      await session.open();
      final api = session.container.read(naiImageGenerationApiServiceProvider);
      final request = session.container
          .read(generationRequestParamsProvider)
          .copyWith(nSamples: 2);
      session.novelAi.streamImagesBeforeEnd = 1;
      final early = await api.generateImageStream(request).toList();
      expect(early.where((chunk) => chunk.hasFinalImage), hasLength(1));
      expect(early.last.hasError, isTrue);
      session.novelAi
        ..streamImagesBeforeEnd = null
        ..streamErrorEvent = 'Internal error while sampling';
      final failed = await api.generateImageStream(request).toList();
      expect(failed.last.hasError, isTrue);
      expect(await session.recorded(), isEmpty);
    });

    test('a local upscale (not NovelAI)', () async {
      final upscaler = _LocalUpscaler();
      when(
        () => upscaler.upscale(
          any(),
          modelId: any(named: 'modelId'),
          scale: any(named: 'scale'),
          seedvr2Options: any(named: 'seedvr2Options'),
          cancellation: any(named: 'cancellation'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer(
        (_) async => LocalUpscaleResult(syntheticPng(128, 128), 128, 128),
      );
      session = _Session(
        overrides: [localUpscaleServiceProvider.overrideWithValue(upscaler)],
      );
      await session.open();
      final result = await session.container
          .read(localUpscaleTaskProvider.notifier)
          .processGenerated(
            syntheticPng(64, 64),
            modelId: 'synthetic-model',
            scale: 2,
          );
      expect(result, isNotNull);
      expect(await session.recorded(), isEmpty);
      expect(session.novelAi.paths, isEmpty);
    });

    test('tag suggestions (a free endpoint)', () async {
      session = _Session();
      await session.open();
      final tags = await session.container
          .read(naiTagSuggestionApiServiceProvider)
          .suggestTags('1girl');
      expect(tags, isEmpty);
      expect(await session.recorded(), isEmpty);
      expect(session.novelAi.paths, [ApiConstants.suggestTagsEndpoint]);
    });
  });

  group('the statistics follow the requests, not the balance', () {
    test('a balance click after a recorded generation adds nothing', () async {
      final session = _Session();
      addTearDown(session.dispose);
      await session.open();
      final shown = await session.generate();
      expect(await session.recorded(), [shown]);
      session.balances.balance -= shown;
      expect(
        await session.container
            .read(subscriptionNotifierProvider.notifier)
            .refreshBalance(),
        isTrue,
      );
      expect(
        session.container.read(subscriptionNotifierProvider).balance,
        5000 - shown,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(await session.recorded(), [shown]);
      expect(session.balances.requests, 1);
    });

    testWidgets('the running app records nothing when the balance goes down', (
      tester,
    ) async {
      final balances = BalanceRequests();
      final spend = SpendRecords();
      final quiet = StateProvider<int>((ref) => 0);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...realBalanceOverrides(balances),
            anlasStatisticsServiceProvider.overrideWith(() => spend),
          ],
          child: MaterialApp(
            home: AppBootstrapEffects(
              backgroundRefresh: quiet,
              kritaBridge: quiet,
              generationCompletionWatcher: quiet,
              promptBlockLibrary: quiet,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppBootstrapEffects)),
      );
      expect(container.read(subscriptionNotifierProvider).balance, 5000);
      balances.balance = 4970;
      await tester.runAsync(
        () => container
            .read(subscriptionNotifierProvider.notifier)
            .refreshBalance(),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      expect(container.read(subscriptionNotifierProvider).balance, 4970);
      expect(spend.amounts, isEmpty);
    });

    test('the hourly use and the largest single spend see each request on its '
        'own', () async {
      final session = _Session(realStatistics: true);
      addTearDown(session.dispose);
      // Two requests of 20, then one of 30 (a larger image).
      await session.open(requests: 2);
      expect(await session.generate(), 40);
      session.container.read(generationParamsNotifierProvider.notifier)
        ..updateSize(1024, 1536)
        ..updateNSamples(1);
      expect(await session.generate(), 30);
      Future<AnlasUsageMetrics> metrics() async =>
          (await session.container.read(
            anlasUsageMetricsProvider.future,
          )).at(DateTime.now());
      await _until(
        () =>
            session.container
                .read(anlasStatisticsServiceProvider)
                .valueOrNull
                ?.todayCost ==
            70,
        'the three requests were not recorded',
      );
      await _until(
        () =>
            session.container
                .read(anlasUsageMetricsProvider)
                .valueOrNull
                ?.at(DateTime.now())
                .maxDeduction ==
            30,
        'the largest request was not recorded',
      );
      final today = await metrics();
      expect(today.maxDeduction, 30);
      expect(today.hourly.fold<int>(0, (sum, anlas) => sum + anlas), 70);
      expect(today.hourly[DateTime.now().hour], 70);
      final statistics = await session.container.read(
        anlasStatisticsServiceProvider.future,
      );
      expect(statistics.todayCost, 70);
      expect(statistics.getDailyStats(days: 1).single.cost, 70);
      expect(session.balances.requests, 0);
    });
  });

  group('the billed endpoints are reached only through the two NovelAI '
      'image API services, built by their providers with the ledger', () {
    test('nothing in the app goes around them', () async {
      final billedConstants = billedConstantsIn(
        await File(_apiConstantsFile).readAsString(),
      );
      final found = <String>[];
      var providers = 0;
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final path = file.path.replaceAll(r'\', '/');
        if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
          continue;
        }
        final source = await file.readAsString();
        found.addAll(billedRequestBypasses(path, source, billedConstants));
        providers += _providerBuild.allMatches(source).length;
      }
      expect(found, isEmpty);
      // Not vacuous: each service is built once, by its provider.
      expect(providers, 2);
      // Read by value, the constants are the six billed endpoints, not the
      // free one. A new billed endpoint stops here even if only the services
      // use it: give it its record and a test above, then list it here.
      expect(billedConstants, {
        'ApiConstants.generateImageEndpoint',
        'ApiConstants.generateImageStreamEndpoint',
        'ApiConstants.upscaleEndpoint',
        'ApiConstants.encodeVibeEndpoint',
        'ApiConstants.augmentImageEndpoint',
        'ApiConstants.annotateImageEndpoint',
      });
    });

    test('a path in any form, a service or a ledger built elsewhere, a named '
        'constructor, a new constant is caught', () {
      const elsewhere = 'lib/presentation/providers/elsewhere.dart';
      const enhancement =
          'lib/data/datasources/remote/nai_image_enhancement_api_service.dart';
      const constants =
          'class ApiConstants {\n'
          "  static const String upscaleEndpoint = '/ai/upscale';\n"
          "  static const String cloudUpscaleEndpoint = '/ai/upscale';\n"
          '  static const String suggestTagsEndpoint =\n'
          "      '/ai/generate-image/suggest-tags';\n"
          '}\n'
          'class Other {\n'
          "  static const String tools = '/ai/augment-image';\n"
          '}\n';
      final billed = billedConstantsIn(constants);
      expect(billed, {
        'ApiConstants.upscaleEndpoint',
        'ApiConstants.cloudUpscaleEndpoint',
        'Other.tools',
      });
      List<String> bypasses(String path, String source) =>
          billedRequestBypasses(path, source, billed);

      for (final bypass in [
        "dio.post('https://image.novelai.net/ai/generate-image')",
        "dio.post('https://image.novelai.net/ai/generate-image-stream')",
        r"dio.post('$base/ai/augment-image')",
        r'dio.post("${endpoint.imageBase}/ai/upscale")',
        "const path = '/ai/encode-vibe';",
        "endpoints.imageUrl('ai/upscale')",
        "endpoints.imageUrl(r'/ai/upscale')",
        "endpoints.imageUrl('/ai/' + 'upscale')",
        "endpoints.imageUrl('/ai/' 'upscale')",
        "endpoints.imageUrl('ai/' + tool)",
        r"dio.post('$base/ai' '/upscale')",
        r"dio.post('$base/ai/$tool')",
        "endpoints.imageUrl('/ai/up' + 'scale')",
        'dio.post(ApiConstants.upscaleEndpoint)',
        'dio.post(ApiConstants.cloudUpscaleEndpoint)',
        'dio.post(Other.tools)',
        'NAIImageEnhancementApiService(dio, NaiApiEndpointService())',
        'NAIImageGenerationApiService(dio, enhancement, endpoint, '
            'ledger: ledger)',
        'NAIImageEnhancementApiService.unrecorded(dio)',
        'final build = NAIImageEnhancementApiService.new;',
        'class Quiet extends NAIImageGenerationApiService {}',
        'final quiet = AnlasRequestLedger(readAccount: () => null, '
            'record: (_, _) async {});',
        'anlasRequestLedgerProvider.overrideWithValue(quiet)',
      ]) {
        expect(bypasses(elsewhere, bypass), isNotEmpty, reason: bypass);
      }
      for (final bypass in [
        // The provider, giving its service anything but the app's ledger.
        'return NAIImageEnhancementApiService(dio, ledger: unrecorded);',
        // Another constructor, named or a factory, or a method building one.
        '  NAIImageEnhancementApiService.unrecorded(this._dio)\n'
            '    : _ledger = quiet;',
        '  factory NAIImageEnhancementApiService.quiet(Dio dio) =>\n'
            '      NAIImageEnhancementApiService(dio, ledger: quiet);',
        '  NAIImageEnhancementApiService copy() =>\n'
            '      NAIImageEnhancementApiService(this._dio, ledger: quiet);',
      ]) {
        expect(bypasses(enhancement, bypass), isNotEmpty, reason: bypass);
      }
      for (final bypass in [
        // A billed path in api_constants.dart, but not as a string
        // constant, or as a second name for one.
        "  static const String quiet = r'/ai/upscale';",
        "  static const String quiet = '/ai/' 'upscale';",
        "  static const quiet = '/ai/upscale';",
        "  static const String upscaleEndpoint = '/ai/upscale';\n"
            '  static const String quiet = upscaleEndpoint;',
      ]) {
        expect(bypasses(_apiConstantsFile, bypass), isNotEmpty, reason: bypass);
      }

      // Tag suggestions are free; the rest is as the app has it.
      for (final fine in [
        "dio.get('https://image.novelai.net/ai/generate-image/suggest-tags')",
        "endpoints.imageUrl('ai/generate-image/suggest-tags')",
        'dio.get(ApiConstants.suggestTagsEndpoint)',
        "const name = 'novelai/upscale';",
        "dio.post('https://api.openai.com/v1/chat/completions')",
        'final api = ref.watch(naiImageEnhancementApiServiceProvider);',
      ]) {
        expect(bypasses(elsewhere, fine), isEmpty, reason: fine);
      }
      for (final fine in [
        'return NAIImageEnhancementApiService(\n'
            '    dio,\n'
            '    endpointService: endpointService,\n'
            '    ledger: ref.watch(anlasRequestLedgerProvider),\n'
            '  );',
        '  NAIImageEnhancementApiService(\n'
            '    this._dio, {\n'
            '    required AnlasRequestLedger ledger,\n'
            '  }) : _ledger = ledger;',
        "_dio.post(_endpointService.imageUrl('/ai/upscale'))",
      ]) {
        expect(bypasses(enhancement, fine), isEmpty, reason: fine);
      }
      expect(bypasses(_apiConstantsFile, constants), isEmpty);
    });
  });
}
