import 'dart:io';
import 'dart:typed_data';
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_diff_undo.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_prompt_set_actions.dart';
import '../../../core/nai_agent/prompt_set_tools_test.dart' show promptSetInput;
import '../../providers/krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings, MemoryCharacters;
import '../../providers/nai_agent/generation_binding_test.dart'
    show GenerationTestLibrary, GenerationTestVibes, ControlledAgentGeneration;

void main() {
  late Directory root;
  late ProviderContainer container;
  late AgentWorkspace workspace;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('prompt-set-actions-');
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    final storage = PromptBlockStorage(hivePath: root.path);
    await storage.init();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockRepositoryProvider.overrideWithValue(
          PromptBlockRepository(storage),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(
          GenerationTestLibrary.new,
        ),
        vibeLibraryStorageServiceProvider.overrideWithValue(
          GenerationTestVibes(),
        ),
        imageGenerationNotifierProvider.overrideWith(
          ControlledAgentGeneration.new,
        ),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    workspace = await AgentWorkspaceStore(root).createWorkspace('sets');
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    await root.delete(recursive: true);
  });
  test(
    'import touches only prompts; preserves character settings/extras and undo restores all pill documents',
    () async {
      final characters = container.read(
        characterPromptNotifierProvider.notifier,
      );
      characters.restoreAgentSnapshot(
        const CharacterPromptConfig(
          globalAiChoice: false,
          characters: [
            CharacterPrompt(
              id: 'kept',
              name: 'Hero',
              gender: CharacterGender.female,
              enabled: false,
              prompt: 'old',
              negativePrompt: 'old uc',
              positionMode: CharacterPositionMode.custom,
              customPosition: CharacterPosition(
                mode: CharacterPositionMode.custom,
                row: .3,
                column: .7,
              ),
            ),
            CharacterPrompt(id: 'extra', prompt: 'untouched'),
          ],
        ),
      );
      for (final scope in [
        PillScopes.main,
        PillScopes.negative,
        PillScopes.charPos('kept'),
        PillScopes.charNeg('kept'),
      ]) {
        container
            .read(pillWorkspaceProvider(scope).notifier)
            .insertTranslationAt(offset: 0, source: 'old text', zh: '旧文本');
      }
      final params = container.read(generationParamsNotifierProvider.notifier);
      params.updateSeed(123456);
      params.updateSize(832, 1216);
      params.updateSteps(28);
      params.setSourceImage(Uint8List.fromList([1, 2, 3]));
      params.addPreciseReference(
        Uint8List.fromList([4, 5, 6]),
        type: PreciseRefType.character,
      );
      final before = container.read(generationParamsNotifierProvider),
          draft = container.read(agentPromptSetActionsProvider);
      final snapshot = container.read(bridgeDraftVersionProvider);
      final old = container.read(characterPromptNotifierProvider);
      final docs = {
        for (final scope in [
          PillScopes.main,
          PillScopes.negative,
          PillScopes.charPos('kept'),
          PillScopes.charNeg('kept'),
        ])
          scope: container.read(pillWorkspaceProvider(scope)).document.toJson(),
      };
      final imported = await draft.importItem(
        workspace,
        promptSetInput(),
        0,
        (_) {},
      );
      expect(imported, isNotNull);
      final after = container.read(generationParamsNotifierProvider);
      expect(
        after.copyWith(
          prompt: before.prompt,
          negativePrompt: before.negativePrompt,
          characters: before.characters,
        ),
        before,
      );
      expect(after.prompt, 'best quality, 1girl, street');
      expect(after.negativePrompt, 'lowres');
      final current = container.read(characterPromptNotifierProvider);
      expect(
        current.characters.first.copyWith(prompt: old.characters.first.prompt),
        old.characters.first,
      );
      expect(current.characters.last, old.characters.last);
      expect(current.characters.first.prompt, 'silver hair, running');
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.main))
            .document
            .instances,
        isEmpty,
      );
      expect(
        await container
            .read(agentDiffUndoProvider)
            .restoreAll(imported!.restores, workspace.agentDirectory),
        isTrue,
      );
      expect(container.read(characterPromptNotifierProvider), old);
      for (final e in docs.entries) {
        expect(
          container.read(pillWorkspaceProvider(e.key)).document.toJson(),
          e.value,
        );
      }
      expect(container.read(bridgeDraftVersionProvider), isNot(snapshot));
      expect(
        await container
            .read(agentDiffUndoProvider)
            .restoreAll(imported.restores, workspace.agentDirectory),
        isFalse,
      );
    },
  );
  test(
    'add missing slots, undo removes added slot and restores original configuration',
    () async {
      final set = promptSetInput();
      set['shared']['characters'] = ['silver hair', 'blue hair'];
      final old = container.read(characterPromptNotifierProvider);
      final imported = await container
          .read(agentPromptSetActionsProvider)
          .importItem(workspace, set, 0, (_) {});
      expect(
        container.read(characterPromptNotifierProvider).characters,
        hasLength(2),
      );
      expect(
        await container
            .read(agentDiffUndoProvider)
            .restoreAll(imported!.restores, workspace.agentDirectory),
        isTrue,
      );
      expect(container.read(characterPromptNotifierProvider), old);
    },
  );
  test(
    'unsupported character model imports main/negative only and reports warning',
    () async {
      container
          .read(generationParamsNotifierProvider.notifier)
          .updateModel(ImageModels.animeDiffusionV3);
      final old = container.read(characterPromptNotifierProvider),
          toasts = <String>[];
      await container
          .read(agentPromptSetActionsProvider)
          .importItem(workspace, promptSetInput(), 0, toasts.add);
      expect(toasts, hasLength(1));
      expect(container.read(characterPromptNotifierProvider), old);
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'best quality, 1girl, street',
      );
    },
  );
  test('defensive character limit truncates and warns', () async {
    final set = promptSetInput();
    set['shared']['characters'] = List.generate(7, (i) => 'character $i');
    final messages = <String>[];
    await container
        .read(agentPromptSetActionsProvider)
        .importItem(workspace, set, 0, messages.add);
    expect(
      container.read(characterPromptNotifierProvider).characters,
      hasLength(6),
    );
    expect(messages, hasLength(1));
  });
  test(
    'cancel during backup blocks synchronous write and leaves draft intact',
    () async {
      final before = container.read(generationParamsNotifierProvider);
      var checks = 0;
      await expectLater(
        container
            .read(agentPromptSetActionsProvider)
            .importItem(
              workspace,
              promptSetInput(),
              0,
              (_) {},
              check: () {
                if (++checks >= 3) {
                  throw const NaiAgentToolError(
                    'cancelled',
                    'Cancelled during backup',
                  );
                }
              },
            ),
        throwsA(isA<NaiAgentToolError>()),
      );
      expect(container.read(generationParamsNotifierProvider), before);
      expect(
        Directory('${workspace.agentDirectory.path}/draft-backups').listSync(),
        hasLength(1),
      );
    },
  );
  test(
    'save-as-block root with N merged main atoms, copy format has character/negative',
    () async {
      final service = container.read(agentPromptSetActionsProvider),
          set = promptSetInput();
      await service.saveBlock(set);
      final block = container
          .read(promptBlockLibraryNotifierProvider)
          .value!
          .blocks
          .single;
      expect(block.title, 'Rain');
      expect(block.folderId, isNull);
      expect(block.atoms, [
        'best quality, 1girl, street',
        'best quality, 1girl',
      ]);
      expect(block.content, block.atoms!.join(', '));
      expect(
        service.copyText(set, 0),
        '# 1. Rain\nbest quality, 1girl, street\n[character 1] silver hair, running\n[negative] lowres',
      );
    },
  );
}
