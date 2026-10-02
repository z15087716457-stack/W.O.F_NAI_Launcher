import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/model_request_overrides.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';

import '../screens/settings/model_management_section_test.dart' as harness;

class _Settings extends harness.MemorySettings {
  bool? failAfterWrite;

  @override
  Future<void> setSetting<T>(String key, T value) async {
    final failure = key == StorageKeys.promptAssistantConfigJson
        ? failAfterWrite
        : null;
    if (failure != null) failAfterWrite = null;
    if (failure == false) throw StateError('offline config write failed');
    await super.setSetting(key, value);
    if (failure == true) {
      throw StateError('offline config write failed after write');
    }
  }
}

class _Secrets extends harness.MemorySecrets {
  String? failure;
  bool failAfterWrite = false;
  Completer<void>? release;
  Completer<void>? entered;

  Future<void> _write(String action, Future<void> Function() write) async {
    final fail = failure == action;
    if (fail) failure = null;
    if (entered != null) {
      entered!.complete();
      entered = null;
      await release!.future;
    }
    if (fail && !failAfterWrite) {
      throw StateError('offline secure write failed');
    }
    await write();
    if (fail) throw StateError('offline secure write failed after write');
  }

  @override
  Future<void> deletePromptAssistantHeaders(String id) =>
      _write('options', () => super.deletePromptAssistantHeaders(id));
  @override
  Future<void> deletePromptAssistantApiKey(String id) =>
      _write('key', () => super.deletePromptAssistantApiKey(id));
  @override
  Future<void> savePromptAssistantHeaders(String id, String value) =>
      _write('options', () => super.savePromptAssistantHeaders(id, value));
  @override
  Future<void> savePromptAssistantApiKey(String id, String value) =>
      _write('key', () => super.savePromptAssistantApiKey(id, value));
}

const _model = ModelConfig(
  providerId: 'deepseek',
  name: 'offline-model',
  displayName: '离线模型',
  hasRequestOverrides: true,
);
const _modelOptions = ModelRequestOverrides(
  headers: {'X-Model': 'offline-model-value'},
);

Future<ProviderContainer> _container(_Settings local, _Secrets secrets) async {
  local.values[StorageKeys.promptAssistantConfigJson] = harness.sampleConfig
      .copyWith(models: [_model])
      .encode();
  secrets.keys['deepseek'] = 'previous-key';
  secrets.headers['deepseek'] = jsonEncode({'X-Client': 'previous-client'});
  secrets.headers['model/deepseek/offline-model'] = _modelOptions.encode();
  final container = ProviderContainer(
    overrides: [
      localStorageServiceProvider.overrideWithValue(local),
      secureStorageServiceProvider.overrideWithValue(secrets),
    ],
  );
  addTearDown(container.dispose);
  container.read(promptAssistantConfigProvider);
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(ModelCatalogRepository.load);

  for (final stage in ['options', 'key', 'config']) {
    for (final afterWrite in [false, true]) {
      test(
        'delete rollback retains all state: stage=$stage, afterWrite=$afterWrite',
        () async {
          final local = _Settings();
          final secrets = _Secrets();
          final container = await _container(local, secrets);
          final notifier = container.read(
            promptAssistantConfigProvider.notifier,
          );
          final before = container.read(promptAssistantConfigProvider);
          final keys = Map.of(secrets.keys), options = Map.of(secrets.headers);
          final raw = local.values[StorageKeys.promptAssistantConfigJson];
          if (stage == 'config') {
            local.failAfterWrite = afterWrite;
          } else {
            secrets.failure = stage;
            secrets.failAfterWrite = afterWrite;
          }
          await expectLater(
            notifier.deleteProvider('deepseek'),
            throwsStateError,
          );
          expect(container.read(promptAssistantConfigProvider), same(before));
          expect(secrets.keys, keys);
          expect(secrets.headers, options);
          expect(local.values[StorageKeys.promptAssistantConfigJson], raw);
          await notifier.deleteProvider('deepseek');
          final saved = container.read(promptAssistantConfigProvider);
          expect(saved.providers.map((p) => p.id), isNot(contains('deepseek')));
          expect(saved.modelsForProvider(providerId: 'deepseek'), isEmpty);
          expect(
            saved.interfaceFor(LauncherInterface.translate).isConfigured,
            isFalse,
          );
          expect(saved.providerHasApiKey, isNot(contains('deepseek')));
          expect(secrets.keys, isNot(contains('deepseek')));
          expect(secrets.headers, isEmpty);
          expect(
            PromptAssistantConfigState.decode(
              local.values[StorageKeys.promptAssistantConfigJson] as String,
            ).encode(),
            saved.encode(),
          );
        },
      );
    }
  }

  for (final deleting in [false, true]) {
    test(
      'overlapping ${deleting ? 'delete' : 'save'} cannot revert a successful save',
      () async {
        final local = _Settings();
        final secrets = _Secrets();
        final container = await _container(local, secrets);
        final notifier = container.read(promptAssistantConfigProvider.notifier);
        final provider = container
            .read(promptAssistantConfigProvider)
            .providers
            .first;
        final entered = Completer<void>();
        secrets.entered = entered;
        secrets.release = Completer<void>();
        final first = notifier.saveServiceDraft(
          provider: provider.copyWith(name: '已保存的新名称'),
          models: [_model],
          headers: {'X-Client': 'new-client'},
          apiKey: 'new-key',
        );
        await entered.future;
        final second = deleting
            ? notifier.deleteProvider(provider.id)
            : notifier.saveServiceDraft(
                provider: provider.copyWith(name: '过期的第二次保存'),
                models: [_model],
                headers: {'X-Client': 'stale-client'},
                apiKey: 'stale-key',
              );
        final rejection = expectLater(second, throwsStateError);
        secrets.release!.complete();
        await first;
        await rejection;
        expect(
          container.read(promptAssistantConfigProvider).providers.first.name,
          '已保存的新名称',
        );
        expect(secrets.keys['deepseek'], 'new-key');
        expect(jsonDecode(secrets.headers['deepseek']!), {
          'X-Client': 'new-client',
        });
        expect(
          secrets.headers['model/deepseek/offline-model'],
          _modelOptions.encode(),
        );
      },
    );
  }

  test(
    'failed preset deletion and import never publish an unpersisted config',
    () async {
      final local = _Settings();
      final secrets = _Secrets();
      final container = await _container(local, secrets);
      final notifier = container.read(promptAssistantConfigProvider.notifier);
      await notifier.savePreset(
        const TaskPresetConfig(
          id: 'custom',
          name: '自定义',
          task: LauncherInterface.translate,
          prompt: '离线规则',
        ),
      );
      final before = container.read(promptAssistantConfigProvider);
      final raw = local.values[StorageKeys.promptAssistantConfigJson];
      local.failAfterWrite = true;
      await expectLater(notifier.deletePreset('custom'), throwsStateError);
      expect(container.read(promptAssistantConfigProvider), same(before));
      expect(local.values[StorageKeys.promptAssistantConfigJson], raw);
      local.failAfterWrite = true;
      final imported = before.copyWith(
        providers: [before.providers.first.copyWith(name: '未提交导入')],
      );
      await expectLater(
        notifier.importConfiguration(imported.encode()),
        throwsStateError,
      );
      expect(container.read(promptAssistantConfigProvider), same(before));
      expect(local.values[StorageKeys.promptAssistantConfigJson], raw);
      expect(secrets.keys['deepseek'], 'previous-key');
      await notifier.deletePreset('custom');
      expect(container.read(promptAssistantConfigProvider).presets, isEmpty);
    },
  );
}
