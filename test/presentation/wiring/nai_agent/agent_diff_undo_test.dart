import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/pill_workspace_storage.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_writer.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_diff_undo.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_thread_mapper.dart';
import '../../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('agent-undo-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox<String>(PillWorkspaceStorage.boxName);
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    container.listen(bridgeDraftVersionProvider, (_, __) {});
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  final refProvider = Provider<Ref>((ref) => ref);
  Map<String, dynamic> snapshot() =>
      readBridgeDraft(container.read(refProvider)).toJson();
  String version() => container.read(bridgeDraftVersionProvider);
  test(
    'real bridge writer undo restores only requested prompt, pill structure, backs up first',
    () async {
      final params = container.read(generationParamsNotifierProvider.notifier);
      params.updatePromptImmediately('before, tags');
      final lane = container.read(
        pillWorkspaceProvider(PillScopes.main).notifier,
      );
      lane.insertTranslationAt(offset: 0, source: 'artist tag', zh: '画师');
      final before = snapshot();
      final originalDoc = before['documents']['prompt'];
      params.updatePromptImmediately('after');
      params.updateNegativePromptImmediately('leave this alone');
      final current = version();
      final diff = AgentDiffRestore(
        id: 'd',
        version: current,
        backup: before,
        field: 'prompt',
      );
      expect(
        await container.read(agentDiffUndoProvider).restore(diff, directory),
        true,
      );
      expect(snapshot()['fields']['prompt'], before['fields']['prompt']);
      expect(snapshot()['fields']['negative_prompt'], 'leave this alone');
      expect(snapshot()['documents']['prompt'], originalDoc);
      expect(
        Directory('${directory.path}/draft-backups').listSync(),
        hasLength(1),
      );
      expect(
        await container.read(agentDiffUndoProvider).restore(diff, directory),
        false,
      );
    },
  );
  test('stale version does not write or create a backup', () async {
    final before = snapshot();
    final current = version();
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('new user input');
    final diff = AgentDiffRestore(
      id: 'd',
      version: current,
      backup: before,
      field: 'prompt',
    );
    expect(
      await container.read(agentDiffUndoProvider).restore(diff, directory),
      false,
    );
    expect(snapshot()['fields']['prompt'], 'new user input');
    expect(Directory('${directory.path}/draft-backups').existsSync(), false);
  });
  test(
    'character field undo preserves current other lane and identity',
    () async {
      final before = snapshot();
      final writer = container.read(bridgeDraftWriterProvider);
      writer({
        'characters': [
          for (final c in agentMaps(before['fields']['characters']))
            {...c, 'prompt': 'after character', 'uc': 'keep current uc'},
        ],
      });
      final diff = AgentDiffRestore(
        id: 'char',
        version: version(),
        backup: before,
        field: 'characters/kept/prompt',
        characterId: 'kept',
        characterIndex: 0,
      );
      expect(
        await container.read(agentDiffUndoProvider).restore(diff, directory),
        true,
      );
      final c = container
          .read(characterPromptNotifierProvider)
          .characters
          .single;
      expect(c.id, 'kept');
      expect(c.prompt, 'raw character');
      expect(c.negativePrompt, 'keep current uc');
      expect(c.thumbnailPath, 'local-thumbnail');
    },
  );
  test(
    'params card restores its keys; several cards undo in one write',
    () async {
      final params = container.read(generationParamsNotifierProvider.notifier);
      params.updatePromptImmediately('before');
      params.updateSteps(28);
      params.updateSeed(-1);
      final before = snapshot();
      params.updatePromptImmediately('after');
      params.updateSteps(40);
      params.updateSeed(1234);
      params.updateScale(7);
      final current = version();
      final restores = [
        AgentDiffRestore(
          id: 'p',
          version: current,
          backup: before,
          field: 'prompt',
        ),
        AgentDiffRestore(
          id: 'params',
          version: current,
          backup: before,
          field: 'params',
          params: const ['steps', 'seed'],
        ),
      ];
      expect(
        await container
            .read(agentDiffUndoProvider)
            .restoreAll(restores, directory),
        true,
      );
      final now = snapshot()['fields'];
      expect(now['prompt'], 'before');
      expect(now['steps'], 28);
      expect(now['seed'], -1);
      // 卡上没有的参数（引导）保持用户当前值。
      expect(now['cfg_scale'], 7);
      expect(
        Directory('${directory.path}/draft-backups').listSync(),
        hasLength(1),
        reason: '一次写入、一份备份',
      );
      // 草稿已变：整组都不写。
      expect(
        await container
            .read(agentDiffUndoProvider)
            .restoreAll(restores, directory),
        false,
      );
    },
  );
}
