import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/core/network/dio_client.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/datasources/remote/nai_user_info_api_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/anlas_statistics_service.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_image_approvals.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import 'package:nai_launcher/presentation/providers/notification_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';

import '../../../helpers/balance_requests.dart' show afterBilledWork;
import '../../../helpers/novelai_billing.dart';
import '../../../helpers/prompt_normalization_fixture.dart';
import '../krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings, MemoryCharacters;
import 'generation_binding_test.dart'
    show
        GenerationTestAccounts,
        GenerationTestAuth,
        GenerationTestBalances,
        GenerationTestLibrary,
        GenerationTestVibes;

// The Agent's billed actions reach NovelAI through the same native entry
// points and API services as the generation page: each request NovelAI
// delivered is recorded once, at the price the Agent quoted for it, and
// nothing is asked (user decision 2026-10-31, 「按每次请求的价格记」).

const _owner = NaiAgentConversationOwner('workspace', 'chat');

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() =>
      const ImageParams(prompt: 'unrelated draft', seed: 999);
}

/// The generation page showing [source], the image the Agent's tools use.
class _Images extends ImageGenerationNotifier {
  _Images(this.source);
  final Uint8List source;
  @override
  ImageGenerationState build() {
    final image = GeneratedImage(
      id: 'source',
      bytes: source,
      width: 64,
      height: 48,
    );
    return ImageGenerationState(
      currentImages: [image],
      displayImages: [image],
      history: [image],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late ProviderContainer container;
  late FakeNovelAi novelAi;
  late SpendRecords spend;
  late GenerationTestBalances balances;

  /// NovelAI is faked at the network; the app's API services, the ledger and
  /// every notifier are the real ones.
  List<Override> network() => [
    imageGenerationDioClientProvider.overrideWithValue(
      Dio()..httpClientAdapter = novelAi,
    ),
    dioClientProvider.overrideWithValue(Dio()..httpClientAdapter = novelAi),
    naiUserInfoApiServiceProvider.overrideWithValue(balances),
    accountManagerNotifierProvider.overrideWith(GenerationTestAccounts.new),
    anlasStatisticsServiceProvider.overrideWith(() => spend),
    authNotifierProvider.overrideWith(GenerationTestAuth.new),
  ];

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-agent-billing-');
    Hive.init(root.path);
    for (final box in [
      StorageKeys.settingsBox,
      StorageKeys.historyBox,
      StorageKeys.statisticsCacheBox,
    ]) {
      await Hive.openBox(box);
    }
    novelAi = FakeNovelAi();
    spend = SpendRecords();
    balances = GenerationTestBalances();
  });

  tearDown(() async {
    // Anything the work left running has had time to show (the removed
    // post-billing balance request came 0.5 s late): after the test's own
    // requests, neither the balance nor NovelAI may be asked again.
    final asked = balances.requests;
    final sent = novelAi.paths.length;
    await Future<void>.delayed(afterBilledWork);
    expect(balances.requests, asked, reason: 'the balance was asked later');
    expect(novelAi.paths.length, sent, reason: 'NovelAI was asked later');
    container.dispose();
    expect(novelAi.unexpected, isEmpty, reason: 'only NovelAI was faked');
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    await root.delete(recursive: true);
  });

  test(
    'an Agent generation records each request at the price it quoted',
    () async {
      final storage = PromptBlockStorage(hivePath: root.path);
      await storage.init();
      container = ProviderContainer(
        overrides: [
          ...network(),
          localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
          characterPromptRepositoryProvider.overrideWithValue(
            MemoryCharacters(),
          ),
          promptBlockRepositoryProvider.overrideWithValue(
            PromptBlockRepository(storage),
          ),
          promptBlockLibraryNotifierProvider.overrideWith(
            GenerationTestLibrary.new,
          ),
          vibeLibraryStorageServiceProvider.overrideWithValue(
            GenerationTestVibes(),
          ),
        ],
      );
      await container.read(promptBlockLibraryNotifierProvider.future);
      await container
          .read(notificationSettingsNotifierProvider.notifier)
          .setSoundEnabled(false);
      await container
          .read(imageSaveSettingsNotifierProvider.notifier)
          .setAutoSave(false);
      await configurePromptComposition(container);
      final service = container.read(naiAgentStudioFactoryProvider)(
        root,
        root,
        true,
        owner: _owner,
      );
      final quote = (await service.execute('generation_prepare', {
        'requests': 2,
        'images_per_request': 2,
      }, NaiAgentCancellation()))['details']['quote'];
      // An Opus account: the first image of a request is free, the second
      // is not.
      final perRequest = quote['per_request_anlas'] as int;
      expect(perRequest, greaterThan(0));
      final run = service.execute('generation_run', {
        'quote_id': quote['quote_id'],
      }, NaiAgentCancellation());
      final broker = container.read(naiAgentGenerationApprovalsProvider);
      broker.decide(broker.forChat('chat').single.id, generate: true);
      final result = (await run.timeout(
        const Duration(seconds: 20),
      ))['details'];
      expect(result['status'], 'completed');
      await pumpEventQueue();
      expect(spend.amounts, [perRequest, perRequest]);
      expect(
        spend.amounts.fold<int>(0, (sum, anlas) => sum + anlas),
        quote['estimated_anlas'],
      );
      expect(novelAi.paths, [
        ApiConstants.generateImageStreamEndpoint,
        ApiConstants.generateImageStreamEndpoint,
      ]);
      expect(balances.requests, 0);
    },
  );

  for (final (tool, endpoint) in [
    ('cloud_upscale', ApiConstants.upscaleEndpoint),
    ('removeBackground', ApiConstants.augmentImageEndpoint),
  ]) {
    test('the Agent image tool $tool records once, at its quote', () async {
      final source = await ImageSaveUtils.rebuildImageBytesWithMetadata(
        imageBytes: syntheticPng(64, 48),
        params: const ImageParams(
          prompt: 'source prompt',
          seed: 123,
          width: 64,
          height: 48,
        ),
      );
      container = ProviderContainer(
        overrides: [
          ...network(),
          localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
          generationParamsNotifierProvider.overrideWith(_Params.new),
          imageGenerationNotifierProvider.overrideWith(() => _Images(source)),
        ],
      );
      final studio = container.read(naiAgentStudioFactoryProvider)(
        root,
        root,
        false,
        owner: _owner,
      );
      Future<Map<String, dynamic>> run(Map<String, dynamic> p) async =>
          Map<String, dynamic>.from(
            (await studio.execute(
              'image_tool',
              p,
              NaiAgentCancellation(),
            ))['details'],
          );
      final quote = Map<String, dynamic>.from(
        (await run({
          'action': 'prepare',
          'tool': tool,
          'image_id': 'source',
        }))['quote'],
      );
      expect(quote['estimated_anlas'], greaterThan(0));
      final future = run({'action': 'run', 'quote_id': quote['quote_id']});
      final approvals = container.read(naiAgentImageApprovalsProvider);
      for (var i = 0; i < 100 && approvals.forChat('chat').isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      approvals.decide(approvals.forChat('chat').single.id, run: true);
      final result = await future;
      expect(result['artifacts'], isNotEmpty);
      await pumpEventQueue();
      expect(spend.amounts, [quote['estimated_anlas']]);
      expect(novelAi.paths, [endpoint]);
      expect(balances.requests, 0);
    });
  }
}
