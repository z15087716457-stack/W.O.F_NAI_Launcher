import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'generation_data_wiring_test.dart' show DataSubscription;
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/wiring/generation_backend.dart';
import 'package:nai_launcher/presentation/wiring/generation_editor_wiring.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart'
    as role;
import '../providers/krita/agent_bridge_draft_test.dart'
    show
        MemoryCharacters,
        MemoryDraftSettings,
        EmptyBlocks,
        OfflineAuth,
        IdleGeneration;

class MemoryGenerationPlatform extends GenerationPlatform {
  final backups = <Map<String, dynamic>>[];
  Completer<void>? pending;
  bool fail = false;
  @override
  Future<void> backupDraft(String snapshot) async {
    if (fail) throw StateError('backup failed');
    backups.add(jsonDecode(snapshot) as Map<String, dynamic>);
    await pending?.future;
  }
}

class RecordingGeneration extends IdleGeneration {
  final requests = <ImageParams>[];
  final retried = <GenerationRetryRequest>[];
  GenerationRetryRequest? attempt;
  @override
  GenerationRetryRequest? get lastRequest => attempt;
  @override
  Future<void> retry(GenerationRetryRequest request) async {
    retried.add(request);
  }

  void fail(ImageParams params, {int count = 1, String account = 'account-a'}) {
    attempt = GenerationRetryRequest(
      params: params,
      count: count,
      workflow: const ImageWorkflowState(),
      accountId: account,
    );
    state = const ImageGenerationState(
      status: GenerationStatus.error,
      errorMessage: 'failed',
    );
  }

  @override
  Future<void> generate(
    ImageParams params, {
    GenerationBatchCallback? onBatchEvent,
    int? imagesPerRequestOverride,
    ImageOperation? operation,
  }) async {
    requests.add(params);
  }

  void setGenerating() =>
      state = const ImageGenerationState(status: GenerationStatus.generating);
}

class SwitchingAuth extends OfflineAuth {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, accountId: 'account-a');
  void changeAccount([String id = 'account-b']) =>
      state = AuthState(status: AuthStatus.authenticated, accountId: id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  late MemoryGenerationPlatform platform;
  late GenerationBackend backend;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('gen-backend-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    platform = MemoryGenerationPlatform();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        imageGenerationNotifierProvider.overrideWith(RecordingGeneration.new),
        authNotifierProvider.overrideWith(SwitchingAuth.new),
        subscriptionNotifierProvider.overrideWith(DataSubscription.new),
        generationPlatformProvider.overrideWithValue(platform),
        estimatedCostProvider.overrideWith((ref) => 12),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    backend = container.read(generationBackendProvider);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('original');
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test('写入前备份完整草稿，负向不变且药丸与参数同步', () async {
    final notifier = container.read(generationParamsNotifierProvider.notifier);
    notifier.updateNegativePromptImmediately('negative');
    final undo = await backend.clearPrompt(const GenEditorTarget.base());
    expect(platform.backups.single['fields']['prompt'], 'original');
    expect(platform.backups.single['fields']['negative_prompt'], 'negative');
    expect(container.read(generationParamsNotifierProvider).prompt, '');
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).projection,
      '',
    );
    expect(
      container.read(generationParamsNotifierProvider).negativePrompt,
      'negative',
    );
    await backend.undoPrompt(undo!);
    expect(container.read(generationParamsNotifierProvider).prompt, 'original');
  });
  test('ComfyUI 确认提交先完整备份，再同时更新主提示词与角色', () async {
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateNegativePromptImmediately('keep negative');
    final commit = container.read(generationEditorImportProvider)(() => true);
    await commit('global imported', [
      const role.CharacterPrompt(id: 'imported', prompt: 'new role'),
    ]);
    expect(platform.backups.single['fields']['prompt'], 'original');
    expect(platform.backups.single['fields']['characters'][0]['id'], 'kept');
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'global imported',
    );
    expect(
      container.read(generationParamsNotifierProvider).negativePrompt,
      'keep negative',
    );
    expect(
      container.read(characterPromptNotifierProvider).characters.single.id,
      'imported',
    );
  });
  test('ComfyUI 弹窗期间角色或其他参数变化，不覆盖新编辑', () async {
    final commit = container.read(generationEditorImportProvider)(() => true);
    container.read(generationParamsNotifierProvider.notifier).updateSteps(31);
    await expectLater(
      commit('wrong', [
        const role.CharacterPrompt(id: 'wrong', prompt: 'wrong'),
      ]),
      throwsStateError,
    );
    expect(container.read(generationParamsNotifierProvider).prompt, 'original');
    expect(
      container.read(characterPromptNotifierProvider).characters.single.id,
      'kept',
    );
    expect(platform.backups, isEmpty);
  });
  test('备份失败不清空当前内容', () async {
    platform.fail = true;
    await expectLater(
      backend.clearPrompt(const GenEditorTarget.base()),
      throwsStateError,
    );
    expect(container.read(generationParamsNotifierProvider).prompt, 'original');
  });
  test('备份期间新编辑不能被旧清空覆盖', () async {
    platform.pending = Completer<void>();
    final operation = backend.clearPrompt(const GenEditorTarget.base());
    await Future<void>.delayed(Duration.zero);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('new editing');
    platform.pending!.complete();
    await expectLater(operation, throwsStateError);
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'new editing',
    );
  });
  test('清空撤销不能覆盖后来输入', () async {
    final undo = await backend.clearPrompt(const GenEditorTarget.base());
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('new editing');
    await expectLater(backend.undoPrompt(undo!), throwsStateError);
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'new editing',
    );
  });
  test('已空提示词再次清空不创建备份或替换已有撤销', () async {
    final undo = await backend.clearPrompt(const GenEditorTarget.base());
    final count = platform.backups.length;
    expect(await backend.clearPrompt(const GenEditorTarget.base()), isNull);
    expect(platform.backups.length, count);
    await backend.undoPrompt(undo!);
    expect(container.read(generationParamsNotifierProvider).prompt, 'original');
  });
  test('撤销不能覆盖新输入后手动重新留空的意图', () async {
    final undo = await backend.clearPrompt(const GenEditorTarget.base());
    final params = container.read(generationParamsNotifierProvider.notifier);
    params.updatePromptImmediately('later input');
    params.updatePromptImmediately('');
    await expectLater(backend.undoPrompt(undo!), throwsStateError);
    expect(container.read(generationParamsNotifierProvider).prompt, '');
  });
  test('撤销不能越过后一次清空；最新撤销只恢复后一次内容', () async {
    final first = await backend.clearPrompt(const GenEditorTarget.base());
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('second editing');
    final second = await backend.clearPrompt(const GenEditorTarget.base());
    await expectLater(backend.undoPrompt(first!), throwsStateError);
    await backend.undoPrompt(second!);
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'second editing',
    );
  });
  test('撤销不能跨账号切换后恢复的旧会话', () async {
    final undo = await backend.clearPrompt(const GenEditorTarget.base());
    final auth = container.read(authNotifierProvider.notifier) as SwitchingAuth;
    auth.changeAccount();
    auth.changeAccount('account-a');
    await expectLater(backend.undoPrompt(undo!), throwsStateError);
    expect(container.read(generationParamsNotifierProvider).prompt, '');
  });
  test('撤销负面仍保留清空后修改的正面与姓名', () async {
    final undo = await backend.clearPrompt(
      const GenEditorTarget.character(0, negative: true),
    );
    final notifier = container.read(characterPromptNotifierProvider.notifier);
    final current = container
        .read(characterPromptNotifierProvider)
        .characters
        .single;
    notifier.updateCharacter(
      current.copyWith(prompt: 'latest positive', name: 'latest name'),
    );
    await backend.undoPrompt(undo!);
    final restored = container
        .read(characterPromptNotifierProvider)
        .characters
        .single;
    expect(restored.negativePrompt, 'raw uc');
    expect(restored.prompt, 'latest positive');
    expect(restored.name, 'latest name');
  });
  test('角色清空只改指定一面，保留姓名与另一面', () async {
    final undo = await backend.clearPrompt(
      const GenEditorTarget.character(0, negative: true),
    );
    final character = container
        .read(characterPromptNotifierProvider)
        .characters
        .single;
    expect(character.prompt, 'raw character');
    expect(character.negativePrompt, '');
    expect(character.name, 'My character');
    await backend.undoPrompt(undo!);
    expect(
      container
          .read(characterPromptNotifierProvider)
          .characters
          .single
          .negativePrompt,
      'raw uc',
    );
  });
  test('捕获后角色被删除，不能清空换位的另一个角色', () async {
    platform.pending = Completer<void>();
    final operation = backend.clearPrompt(const GenEditorTarget.character(0));
    await Future<void>.delayed(Duration.zero);
    container.read(characterPromptNotifierProvider.notifier).clearAll();
    platform.pending!.complete();
    await expectLater(operation, throwsStateError);
  });
  test('备份含底图蒙版和工作流，不只存纯提示词', () async {
    final params = container.read(generationParamsNotifierProvider.notifier);
    params.setSourceImage(Uint8List.fromList([1, 2]));
    params.setMaskImage(Uint8List.fromList([3, 4]));
    await backend.mutate(() => params.updateSteps(29));
    final snapshot = platform.backups.single;
    expect(snapshot['sourceImage'], base64Encode([1, 2]));
    expect(snapshot['maskImage'], base64Encode([3, 4]));
    expect(snapshot['workflow'], isA<Map>());
    expect(snapshot['generation']['steps'], 28);
  });
  test('连续设置串行执行，每次都备份最新值', () async {
    final notifier = container.read(generationParamsNotifierProvider.notifier);
    await Future.wait([
      backend.mutate(() => notifier.updateSteps(29)),
      backend.mutate(() => notifier.updateScale(6)),
    ]);
    expect(container.read(generationParamsNotifierProvider).steps, 29);
    expect(container.read(generationParamsNotifierProvider).scale, 6);
    expect(platform.backups.last['generation']['steps'], 29);
  });
  test('第一项失败不会污染后续写队列', () async {
    platform.fail = true;
    await expectLater(backend.mutate(() {}), throwsStateError);
    platform.fail = false;
    await backend.mutate(
      () => container
          .read(generationParamsNotifierProvider.notifier)
          .updateSteps(30),
    );
    expect(container.read(generationParamsNotifierProvider).steps, 30);
  });
  for (final change in [
    'prompt',
    'count',
    'count-restored',
    'account',
    'account-restored',
    'workflow',
    'generating',
    'disposed',
  ]) {
    test('费用确认期间 $change 变化阻止旧生成', () async {
      final confirm = Completer<bool>();
      var alive = true;
      final operation = backend.generate(
        confirm: (cost) {
          expect(cost, 12);
          return confirm.future;
        },
        alive: () => alive,
      );
      await Future<void>.delayed(Duration.zero);
      switch (change) {
        case 'prompt':
          container
              .read(generationParamsNotifierProvider.notifier)
              .updatePromptImmediately('new draft');
        case 'count':
          container.read(imagesPerRequestProvider.notifier).set(2);
        case 'count-restored':
          container.read(imagesPerRequestProvider.notifier).set(2);
          container.read(imagesPerRequestProvider.notifier).set(1);
        case 'account':
          (container.read(authNotifierProvider.notifier) as SwitchingAuth)
              .changeAccount();
        case 'account-restored':
          final auth =
              container.read(authNotifierProvider.notifier) as SwitchingAuth;
          auth.changeAccount();
          auth.changeAccount('account-a');
        case 'workflow':
          container
              .read(imageWorkflowControllerProvider.notifier)
              .setPanelExpanded(true);
        case 'generating':
          (container.read(imageGenerationNotifierProvider.notifier)
                  as RecordingGeneration)
              .setGenerating();
        case 'disposed':
          alive = false;
      }
      confirm.complete(true);
      await operation;
      expect(
        (container.read(imageGenerationNotifierProvider.notifier)
                as RecordingGeneration)
            .requests,
        isEmpty,
      );
    });
  }
  test('重试保留上次请求和张数，不把当前新草稿当成失败请求', () async {
    final generation =
        container.read(imageGenerationNotifierProvider.notifier)
            as RecordingGeneration;
    final original = container
        .read(generationParamsNotifierProvider)
        .copyWith(seed: 123, nSamples: 2);
    generation.fail(original, count: 3);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('new draft');
    container.read(imagesPerRequestProvider.notifier).set(1);
    await backend.retry(confirm: (_) async => true);
    expect(generation.retried.single.params, original);
    expect(generation.retried.single.count, 3);
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'new draft',
    );
    expect(platform.backups.single['fields']['prompt'], 'new draft');
  });
  for (final change in ['draft', 'account-restored', 'new-request']) {
    test('重试确认期间 $change 使旧确认失效', () async {
      final generation =
          container.read(imageGenerationNotifierProvider.notifier)
              as RecordingGeneration;
      generation.fail(container.read(generationParamsNotifierProvider));
      final confirm = Completer<bool>();
      final pending = backend.retry(confirm: (_) => confirm.future);
      await Future<void>.delayed(Duration.zero);
      if (change == 'draft') {
        container
            .read(generationParamsNotifierProvider.notifier)
            .updatePromptImmediately('new');
      } else if (change == 'account-restored') {
        final auth =
            container.read(authNotifierProvider.notifier) as SwitchingAuth;
        auth.changeAccount();
        auth.changeAccount('account-a');
      } else {
        generation.fail(
          container.read(generationParamsNotifierProvider).copyWith(seed: 987),
        );
      }
      confirm.complete(true);
      await pending;
      expect(generation.retried, isEmpty);
    });
  }
  test('重试不跨账号提交上一次失败请求', () async {
    final generation =
        container.read(imageGenerationNotifierProvider.notifier)
            as RecordingGeneration;
    generation.fail(
      container.read(generationParamsNotifierProvider),
      account: 'another',
    );
    await backend.retry(confirm: (_) async => fail('must not confirm'));
    expect(generation.retried, isEmpty);
  });
  test('真实确认后先备份，再把原请求交给生成 provider', () async {
    await backend.generate(confirm: (_) async => true);
    expect(platform.backups.length, 1);
    expect(
      (container.read(imageGenerationNotifierProvider.notifier)
              as RecordingGeneration)
          .requests
          .single
          .prompt,
      'original',
    );
  });
  test('取消确认不生成也不备份，重复点击只保留首个确认', () async {
    final confirm = Completer<bool>();
    var confirmations = 0;
    final first = backend.generate(
      confirm: (_) {
        confirmations++;
        return confirm.future;
      },
    );
    await backend.generate(
      confirm: (_) async {
        confirmations++;
        return true;
      },
    );
    confirm.complete(false);
    await first;
    expect(confirmations, 1);
    expect(platform.backups, isEmpty);
  });
  test('生成备份期间的新编辑仍受保护', () async {
    platform.pending = Completer<void>();
    final operation = backend.generate(confirm: (_) async => true);
    await Future<void>.delayed(Duration.zero);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('new');
    platform.pending!.complete();
    await operation;
    expect(
      (container.read(imageGenerationNotifierProvider.notifier)
              as RecordingGeneration)
          .requests,
      isEmpty,
    );
  });
}
