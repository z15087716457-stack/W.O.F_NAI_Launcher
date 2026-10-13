import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/core/services/anlas_calculator.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import '../krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings, MemoryCharacters;
import '../../../helpers/prompt_normalization_fixture.dart';

class GenerationTestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    accountId: 'synthetic-account',
    displayName: 'Synthetic account',
    subscriptionInfo: {'tier': 3, 'active': true, 'trainingStepsLeft': 10000},
  );
  void setAuth(AuthState value) {
    state = value;
  }
}

class GenerationTestLibrary extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async {
    final data = await ref.read(promptBlockRepositoryProvider).load();
    return PromptBlockLibraryState(
      blocks: data.blocks,
      folders: data.folders,
      collections: data.collections,
    );
  }
}

class GenerationTestVibes extends VibeLibraryStorageService {
  @override
  Future<void> saveGenerationStateJson(String value) async {}
  @override
  Future<String?> loadGenerationStateJson() async => null;
}

class ControlledAgentGeneration extends ImageGenerationNotifier {
  static final pixels = Uint8List.fromList(
    img.encodePng(img.Image(width: 3, height: 2)),
  );
  final requests = <ImageParams>[];
  final sizes = <int?>[];
  final pending = Completer<void>();
  int cancels = 0;
  GenerationBatchCallback? callback;
  @override
  ImageGenerationState build() => const ImageGenerationState();
  @override
  Future<void> generate(
    ImageParams params, {
    GenerationBatchCallback? onBatchEvent,
    int? imagesPerRequestOverride,
    ImageOperation? operation,
  }) {
    requests.add(params);
    sizes.add(imagesPerRequestOverride);
    callback = onBatchEvent;
    state = const ImageGenerationState(
      generationRunId: 1,
      status: GenerationStatus.generating,
    );
    return pending.future;
  }

  void manualTakeover() {
    state = const ImageGenerationState(
      generationRunId: 2,
      status: GenerationStatus.generating,
    );
  }

  void finish({GenerationStatus status = GenerationStatus.completed}) {
    final image = GeneratedImage(
      id: 'native-image',
      bytes: pixels,
      width: 3,
      height: 2,
      generationRunId: 1,
    );
    if (state.generationRunId == 1) {
      state = state.copyWith(
        status: status,
        currentImages: [image],
        displayImages: [image],
        progress: 1,
      );
    }
    callback?.call(
      GenerationBatchEvent(
        kind: GenerationBatchEventKind.complete,
        generationRunId: 1,
        batchIndex: 0,
        slotStart: 0,
        slotCount: 1,
        totalSlots: 1,
        images: [image],
      ),
    );
    pending.complete();
  }

  @override
  void cancel() {
    cancels++;
    finish(status: GenerationStatus.cancelled);
  }
}

Future<void> waitForAgentStart(ControlledAgentGeneration native) async {
  for (var i = 0; i < 200 && native.requests.isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(native.requests, hasLength(1));
}

void main() {
  late Directory root;
  late ProviderContainer container;
  late PromptBlockRepository repository;
  setUp(() async {
    root = await Directory.systemTemp.createTemp(
      'nai-agent-generation-binding-',
    );
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    final storage = PromptBlockStorage(hivePath: root.path);
    await storage.init();
    repository = PromptBlockRepository(storage);
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockRepositoryProvider.overrideWithValue(repository),
        promptBlockLibraryNotifierProvider.overrideWith(
          GenerationTestLibrary.new,
        ),
        vibeLibraryStorageServiceProvider.overrideWithValue(
          GenerationTestVibes(),
        ),
        imageGenerationNotifierProvider.overrideWith(
          ControlledAgentGeneration.new,
        ),
        authNotifierProvider.overrideWith(GenerationTestAuth.new),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    await root.delete(recursive: true);
  });
  ControlledAgentGeneration native() =>
      container.read(imageGenerationNotifierProvider.notifier)
          as ControlledAgentGeneration;
  NaiAgentStudioTools tools() => container.read(naiAgentStudioFactoryProvider)(
    root,
    root,
    true,
    owner: const NaiAgentConversationOwner('workspace', 'chat'),
  );
  Future<Map> quote(
    NaiAgentStudioTools service, [
    Map<String, dynamic> params = const {},
  ]) async =>
      (await service.execute(
            'generation_prepare',
            params,
            NaiAgentCancellation(),
          ))['details']['quote']
          as Map;
  Future<Map> execute(
    NaiAgentStudioTools service,
    Map q, {
    NaiAgentCancellation? token,
  }) async =>
      (await service.execute('generation_run', {
            'quote_id': q['quote_id'],
          }, token ?? NaiAgentCancellation()))['details']
          as Map;
  void decide({bool generate = true}) {
    final broker = container.read(naiAgentGenerationApprovalsProvider);
    broker.decide(broker.forChat('chat').single.id, generate: generate);
  }

  Matcher error(String code) =>
      isA<NaiAgentToolError>().having((e) => e.code, 'code', code);

  test(
    'quote uses native batch billing and loaded balance without API refresh or draft mutation',
    () async {
      final service = tools(),
          before = container.read(generationParamsNotifierProvider);
      final q = await quote(service, {'requests': 3, 'images_per_request': 2});
      final expected = AnlasCalculator.calculateRequestCost(
        width: before.width,
        height: before.height,
        steps: before.steps,
        model: before.model,
        subscriptionTier: 3,
        smea: before.effectiveSmea,
        smeaDyn: before.effectiveSmeaDyn,
        batchCount: 3,
        batchSize: 2,
      );
      expect(q['estimated_anlas'], expected);
      expect(q['per_request_anlas'] * 3 + q['encoding_anlas'], expected);
      expect(q['balance_anlas'], 10000);
      expect(q['samples'], 6);
      expect(q['can_generate'], true);
      expect(container.exists(subscriptionNotifierProvider), false);
      expect(container.read(generationParamsNotifierProvider), before);
      expect(native().requests, isEmpty);
    },
  );

  test(
    'human button starts frozen native counts after full backup and returns real images',
    () async {
      final service = tools(),
          before = container.read(generationParamsNotifierProvider);
      final q = await quote(service, {'requests': 2, 'images_per_request': 3});
      final future = execute(service, q);
      expect(native().requests, isEmpty);
      decide();
      await waitForAgentStart(native());
      expect(native().requests.single.nSamples, 2);
      expect(native().sizes, [3]);
      native().finish();
      final result = await future;
      expect(result['status'], 'completed');
      expect(result['native_generation_id'], 1);
      expect(result['images'].single['image_id'], 'native-image');
      expect(result['images'].single['path'], null);
      expect(result['actual_anlas'], null);
      expect(container.read(generationParamsNotifierProvider), before);
      final backup = jsonDecode(
        await File(result['backup_path'] as String).readAsString(),
      );
      expect(backup['generation']['kind'], 'generation_before_run');
      expect(backup['generation']['image']['params']['prompt'], before.prompt);
      await expectLater(execute(service, q), throwsA(error('quote_missing')));
    },
  );

  test(
    'native admission receives raw prompts so custom presets are applied only once',
    () async {
      final raw = await configurePromptComposition(container);
      final service = tools(), q = await quote(tools());
      // Quotes belong to one tools binding, including its owning chat.
      await expectLater(execute(service, q), throwsA(error('quote_missing')));
      final owned = await quote(service);
      final future = execute(service, owned);
      decide();
      await waitForAgentStart(native());
      expect(native().requests.single.prompt, raw.prompt);
      expectComposedPromptParams(
        native().preparePromptParams(native().requests.single),
      );
      native().finish();
      await future;
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        raw.prompt,
      );
    },
  );

  test(
    'source image changes during approval invalidate the native start',
    () async {
      final service = tools(), q = await quote(tools());
      final owned = await quote(service);
      final future = execute(service, owned);
      final assertion = expectLater(future, throwsA(error('quote_changed')));
      final params = container.read(generationParamsNotifierProvider);
      container
          .read(generationParamsNotifierProvider.notifier)
          .restoreAgentSnapshot(
            params.copyWith(sourceImage: Uint8List.fromList([1])),
          );
      decide();
      await assertion;
      expect(q['quote_id'], isNot(owned['quote_id']));
      expect(native().requests, isEmpty);
    },
  );

  test(
    'missing balance is unavailable rather than invented zero; a real zero balance can quote free generation',
    () async {
      final auth =
          container.read(authNotifierProvider.notifier) as GenerationTestAuth;
      auth.setAuth(
        const AuthState(
          status: AuthStatus.authenticated,
          accountId: 'synthetic-account',
        ),
      );
      final q = await quote(tools());
      expect(q['balance_anlas'], null);
      expect(q['blocked_reason'], 'balance_unavailable');
      auth.setAuth(
        const AuthState(
          status: AuthStatus.authenticated,
          accountId: 'synthetic-account',
          subscriptionInfo: {'tier': 3, 'active': true, 'trainingStepsLeft': 0},
        ),
      );
      final free = await quote(tools());
      expect(free['balance_anlas'], 0);
      expect(free['estimated_anlas'], 0);
      expect(free['can_generate'], true);
    },
  );

  test(
    'cancel protects a new manual run even while an old Agent run is settling',
    () async {
      final service = tools(), q = await quote(tools());
      final owned = await quote(service);
      final token = NaiAgentCancellation(),
          future = execute(service, owned, token: NaiAgentCancellation());
      decide();
      await waitForAgentStart(native());
      native().manualTakeover();
      final result = await service.execute('generation_cancel', {}, token);
      expect(result['details']['status'], 'already_finished');
      expect(native().cancels, 0);
      native().finish();
      expect((await future)['status'], 'interrupted');
      expect(
        container.read(imageGenerationNotifierProvider).generationRunId,
        2,
      );
      expect(q['can_generate'], true);
    },
  );

  test(
    'Agent stop cancels its admitted native task and reports partial produced images',
    () async {
      final service = tools(), owned = await quote(tools());
      final q = await quote(service), token = NaiAgentCancellation();
      final future = execute(service, q, token: token);
      decide();
      await waitForAgentStart(native());
      token.cancel();
      final result = await future;
      expect(result['status'], 'cancelled');
      expect(result['images'].single['image_id'], 'native-image');
      expect(native().cancels, 1);
      expect(owned['can_generate'], true);
    },
  );
  test(
    'referenced alias definition edits invalidate a pending quote',
    () async {
      final alias = await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .createBlock(title: 'lighting', content: 'blue theme');
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('<lighting>');
      final service = tools(), q = await quote(tools());
      final owned = await quote(service);
      final future = execute(service, owned);
      final assertion = expectLater(future, throwsA(error('quote_changed')));
      await repository.updateBlock(alias.copyWith(content: 'green theme'));
      await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .refresh(preserveCurrent: true);
      decide();
      await assertion;
      expect(native().requests, isEmpty);
      expect(q['can_generate'], true);
    },
  );
  test(
    'alias usage increments do not invalidate unchanged referenced definitions',
    () async {
      final alias = await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .createBlock(title: 'lighting', content: 'blue theme');
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('<lighting>');
      final service = tools(), q = await quote(tools());
      final owned = await quote(service);
      final future = execute(service, owned);
      await repository.incrementUseCount(alias.id);
      await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .refresh(preserveCurrent: true);
      decide();
      await waitForAgentStart(native());
      native().finish();
      expect((await future)['status'], 'completed');
      expect(q['can_generate'], true);
    },
  );
  test(
    'account switching stops the owned native run and never reports the new account balance',
    () async {
      final service = tools();
      final q = await quote(service);
      final future = execute(service, q);
      decide();
      await waitForAgentStart(native());
      (container.read(authNotifierProvider.notifier) as GenerationTestAuth)
          .setAuth(
            const AuthState(
              status: AuthStatus.authenticated,
              accountId: 'other-account',
              subscriptionInfo: {
                'tier': 3,
                'active': true,
                'trainingStepsLeft': 54321,
              },
            ),
          );
      final result = await future;
      expect(native().cancels, 1);
      expect(result['status'], 'cancelled');
      expect(result['stop_reason'], 'account_changed');
      expect(result['balance_after_anlas'], null);
      expect(result['balance_source'], 'account_changed');
      expect(result['balance_before_anlas'], 10000);
    },
  );
  test(
    'a disposed binding returns collected results without reading the disposed Ref',
    () async {
      final service = tools();
      final q = await quote(service);
      final future = execute(service, q);
      decide();
      await waitForAgentStart(native());
      final task = native();
      container.invalidate(naiAgentStudioFactoryProvider);
      task.finish();
      final result = await future;
      expect(result['status'], 'interrupted');
      expect(result['images'].single['image_id'], 'native-image');
      expect(result['balance_source'], 'owner_closed');
      expect(result['balance_after_anlas'], null);
    },
  );
}
