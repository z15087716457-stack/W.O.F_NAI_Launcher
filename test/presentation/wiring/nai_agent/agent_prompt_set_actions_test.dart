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
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_writer.dart';
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
  for (final model in [
    ImageModels.animeDiffusionV4Full,
    ImageModels.animeDiffusionV45Full,
    ImageModels.animeDiffusionV5Full,
  ]) {
    test(
      'positions import into UI + generation params, partial inheritance and undo: $model',
      () async {
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateModel(model);
        container.read(bridgeDraftWriterProvider)({
          'use_coords': false,
          'characters': [
            {'id': 'first', 'prompt': 'old first', 'x': .1, 'y': .2},
            {'id': 'second', 'prompt': 'old second', 'x': .8, 'y': .9},
            {'id': 'third', 'prompt': 'old third'},
          ],
        });
        // A dormant saved position must survive enabling custom mode too.
        final characters = container.read(characterPromptNotifierProvider);
        container
            .read(characterPromptNotifierProvider.notifier)
            .restoreAgentSnapshot(
              characters.copyWith(
                characters: [
                  characters.characters[0],
                  characters.characters[1].copyWith(
                    positionMode: CharacterPositionMode.aiChoice,
                  ),
                  characters.characters[2],
                ],
              ),
            );
        final before = container.read(characterPromptNotifierProvider);
        final paramsBefore = container.read(generationParamsNotifierProvider);
        final set = promptSetInput();
        set['shared']['characters'] = [
          'silver hair',
          'brown hair',
          'green hair',
          'red hair',
        ];
        set['shared']['positions'] = [
          {'x': .05, 'y': .95},
          null,
          null,
          {'x': .9, 'y': .1},
        ];
        set['items'][0]['positions'] = [
          {'x': .25, 'y': .6},
          null,
          null,
          null,
        ];
        final imported = (await container
            .read(agentPromptSetActionsProvider)
            .importItem(workspace, set, 0, (_) {}))!;
        final config = container.read(characterPromptNotifierProvider);
        final params = container.read(generationParamsNotifierProvider);
        expect(config.globalAiChoice, isFalse);
        expect(params.useCoords, isTrue);
        expect(config.characters, hasLength(4));
        expect(config.characters.first.prompt, 'silver hair, running');
        expect(config.characters.first.customPosition!.column, .25);
        expect(config.characters.first.customPosition!.row, .6);
        expect(
          config.characters[1].customPosition,
          before.characters[1].customPosition,
        );
        expect(
          config.characters[2].customPosition,
          isNotNull,
        ); // Existing normalization fills.
        expect(config.characters[3].customPosition!.column, .9);
        expect(config.characters[3].customPosition!.row, .1);
        for (var j = 0; j < 4; j++) {
          expect(
            config.characters[j].positionMode,
            CharacterPositionMode.custom,
          );
          expect(
            params.characters[j].positionX,
            config.characters[j].customPosition!.column,
          );
          expect(
            params.characters[j].positionY,
            config.characters[j].customPosition!.row,
          );
        }
        expect(imported.restores.map((r) => r.field), contains('use_coords'));
        expect(
          await container
              .read(agentDiffUndoProvider)
              .restoreAll(imported.restores, workspace.agentDirectory),
          isTrue,
        );
        expect(container.read(characterPromptNotifierProvider), before);
        final restored = container.read(generationParamsNotifierProvider);
        expect(restored.useCoords, isFalse);
        expect(restored.characters, paramsBefore.characters);
      },
    );
  }
  for (final useCoords in [false, true]) {
    test(
      'no effective positions leaves existing coordinates and mode unchanged: $useCoords',
      () async {
        container.read(bridgeDraftWriterProvider)({
          'use_coords': useCoords,
          'characters': [
            {'id': 'old', 'prompt': 'old', 'x': .18, 'y': .87},
          ],
        });
        final before = container.read(characterPromptNotifierProvider);
        final paramsBefore = container.read(generationParamsNotifierProvider);
        final set = promptSetInput();
        set['shared']['positions'] = [null];
        set['items'][0]['positions'] = [null];
        final imported = (await container
            .read(agentPromptSetActionsProvider)
            .importItem(workspace, set, 0, (_) {}))!;
        final after = container.read(characterPromptNotifierProvider);
        expect(after.globalAiChoice, before.globalAiChoice);
        expect(
          after.characters.single.copyWith(prompt: 'old'),
          before.characters.single,
        );
        final paramsAfter = container.read(generationParamsNotifierProvider);
        expect(paramsAfter.useCoords, paramsBefore.useCoords);
        expect(paramsAfter.characters.single.positionX, .18);
        expect(paramsAfter.characters.single.positionY, .87);
        expect(
          imported.restores.map((r) => r.field),
          isNot(contains('use_coords')),
        );
      },
    );
  }
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
      final params = container.read(generationParamsNotifierProvider);
      final set = promptSetInput();
      set['shared']['positions'] = [
        {'x': .2, 'y': .7},
      ];
      final imported = (await container
          .read(agentPromptSetActionsProvider)
          .importItem(workspace, set, 0, toasts.add))!;
      expect(
        container.read(generationParamsNotifierProvider).useCoords,
        params.useCoords,
      );
      expect(
        imported.restores.map((r) => r.field),
        isNot(contains('use_coords')),
      );
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
    set['items'][0]['positions'] = [
      null,
      null,
      null,
      null,
      null,
      null,
      {'x': .2, 'y': .8},
    ];
    final before = container.read(characterPromptNotifierProvider);
    final paramsBefore = container.read(generationParamsNotifierProvider);
    final messages = <String>[];
    await container
        .read(agentPromptSetActionsProvider)
        .importItem(workspace, set, 0, messages.add);
    expect(
      container.read(characterPromptNotifierProvider).characters,
      hasLength(6),
    );
    expect(messages, hasLength(1));
    expect(
      container.read(characterPromptNotifierProvider).globalAiChoice,
      before.globalAiChoice,
    );
    expect(
      container.read(generationParamsNotifierProvider).useCoords,
      paramsBefore.useCoords,
    );
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
    'copy text appends effective coordinates with two decimals, keeping missing entries plain',
    () {
      final service = container.read(agentPromptSetActionsProvider),
          set = promptSetInput();
      set['shared']['characters'] = ['silver hair', 'brown hair', 'green hair'];
      set['shared']['positions'] = [
        {'x': .25, 'y': .6},
        {'x': 1, 'y': 0},
      ];
      set['items'][0]['positions'] = [
        null,
        {'x': .1234, 'y': .9876},
      ];
      expect(
        service.copyText(set, 0),
        contains('[character 1] silver hair, running @ (0.25, 0.60)'),
      );
      expect(
        service.copyText(set, 0),
        contains('[character 2] brown hair @ (0.12, 0.99)'),
      );
      expect(service.copyText(set, 0), contains('[character 3] green hair\n'));
      expect(
        service.copyText(set, 1),
        contains('[character 2] brown hair @ (1.00, 0.00)'),
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
