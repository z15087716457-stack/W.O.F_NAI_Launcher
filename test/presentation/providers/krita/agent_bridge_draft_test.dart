import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/presentation/providers/uc_preset_provider.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/krita/krita_bridge_server.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import '../../../core/krita/agent_bridge_integration_test.dart' show Peer;

class MemoryDraftSettings extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

class MemoryCharacters extends CharacterPromptRepository {
  CharacterPromptConfig value = const CharacterPromptConfig(
    characters: [
      CharacterPrompt(
        id: 'kept',
        name: 'My character',
        gender: CharacterGender.female,
        thumbnailPath: 'local-thumbnail',
        prompt: 'raw character',
        negativePrompt: 'raw uc',
        enabled: false,
      ),
    ],
  );
  @override
  CharacterPromptConfig load() => value;
  @override
  Future<bool> save(CharacterPromptConfig config) async {
    value = config;
    return true;
  }
}

class EmptyBlocks extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [], folders: []);
}

class IdleGeneration extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class OfflineAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  test('生产写入保留角色身份、元信息和等价积木；未挂载 lane 同步并先备份', () async {
    final directory = await Directory.systemTemp.createTemp(
      'studio-agent-draft-',
    );
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    final repository = MemoryCharacters();
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(repository),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        imageGenerationNotifierProvider.overrideWith(IdleGeneration.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        kritaBridgeServerFactoryProvider.overrideWithValue(
          () => KritaBridgeServer(discoveryDirectory: directory),
        ),
        kritaBridgePromptPreparerProvider.overrideWithValue(
          (params, _) => params,
        ),
        for (final target in PromptTokenCountTarget.values)
          promptTokenUsageProvider(target).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
      ],
    );
    final bridge = container.read(kritaBridgeNotifierProvider.notifier);
    Peer? peer;
    try {
      await container.read(promptBlockLibraryNotifierProvider.future);
      final lane = container.read(
        pillWorkspaceProvider(PillScopes.charPos('kept')).notifier,
      );
      lane.insertTranslationAt(offset: 0, source: 'raw character', zh: '角色原文');
      final document = container
          .read(pillWorkspaceProvider(PillScopes.charPos('kept')))
          .document;
      await bridge.enable(persist: false);
      final socket = await WebSocket.connect(
        'ws://127.0.0.1:${bridge.state.port}/krita',
      );
      peer = Peer(socket, StreamIterator<dynamic>(socket));
      socket.add(
        jsonEncode({
          'type': 'ping',
          'version': 1,
          'secret': bridge.state.secret,
          'client': {'kind': 'agent', 'name': 'Offline test'},
        }),
      );
      await peer.events.moveNext();
      final before = await peer.rpc('get_params');
      final draft = before['_draft'] as Map;
      final characters = (draft['fields']['characters'] as List)
          .cast<Map<String, dynamic>>();
      expect(characters.single['prompt'], 'raw character');
      expect(characters.single['uc'], 'raw uc');
      final result = await peer.rpc(
        'set_params',
        payload: {
          'characters': [
            {...characters.single, 'uc': 'new negative'},
          ],
          '_expected': draft['field_versions'],
        },
      );
      expect(result['type'], 'params_set');
      final saved = repository.value.characters.single;
      expect(saved.id, 'kept');
      expect(saved.gender, CharacterGender.female);
      expect(saved.thumbnailPath, 'local-thumbnail');
      expect(saved.enabled, isFalse);
      expect(
        container.read(generationParamsNotifierProvider).characters,
        isEmpty,
      );
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.charPos('kept')))
            .document,
        document,
      );
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.charNeg('kept')))
            .projection,
        'new negative',
      );
      final backup =
          jsonDecode(await File(result['backup_path'] as String).readAsString())
              as Map;
      expect(backup['fields']['characters'][0]['uc'], 'raw uc');
      expect(
        backup['documents']['characters']['lanes']['kept']['positive'],
        document.toJson(),
      );
      final readback = await peer.rpc('get_params');
      expect(
        readback['_draft']['fields']['characters'][0]['uc'],
        'new negative',
      );
      container
          .read(ucPresetNotifierProvider.notifier)
          .setPresetType(UcPresetType.none);
      final stalePreset = await peer.rpc(
        'set_params',
        payload: {'uc_preset': 0, '_expected': draft['field_versions']},
      );
      expect(stalePreset['code'], 'conflict');
      expect(
        container.read(ucPresetNotifierProvider).presetType,
        UcPresetType.none,
      );
      final stale = await peer.rpc(
        'set_params',
        payload: {'characters': [], '_expected': draft['field_versions']},
      );
      expect(stale['code'], 'conflict');
      expect(repository.value.characters, hasLength(1));
    } finally {
      await peer?.close();
      await bridge.close();
      container.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });
}
