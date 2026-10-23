import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/krita/bridge_draft_guard.dart';
import '../../../data/models/image/image_params.dart' hide CharacterPrompt;
import '../../../data/models/character/character_prompt.dart';
import '../../providers/character_prompt_provider.dart';
import '../../../core/nai_agent/generation_tools.dart';
import '../../../core/nai_agent/prompt_set_tools.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/services/nai_agent/agent_workspace_files.dart';
import '../../../data/services/nai_agent/agent_workspace_store.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/krita/bridge_draft_snapshot.dart';
import '../../providers/krita/bridge_draft_writer.dart';
import '../../providers/nai_agent/nai_agent_generation_binding.dart';
import '../../providers/prompt_block_library_provider.dart';
import 'agent_diff_undo.dart';
import 'agent_thread_mapper.dart';

class AgentPromptSetImport {
  const AgentPromptSetImport(this.index, this.restores);
  final int index;
  final List<AgentDiffRestore> restores;
  String get version => restores.first.version;
}

final agentPromptSetActionsProvider = Provider(
  (ref) => AgentPromptSetActions(ref),
);

/// Shared guarded draft path. The UI never writes providers directly.
class AgentPromptSetActions {
  AgentPromptSetActions(this.ref);
  final Ref ref;

  Map<String, dynamic> merged(Map<String, dynamic> set, int index) {
    final shared = set['shared'] as Map,
        item = (set['items'] as List)[index] as Map;
    final chars = (shared['characters'] as List? ?? []).cast<String>();
    final additions = (item['characters'] as List? ?? []).cast<String>();
    return {
      'prompt': mergeAgentPrompt(
        shared['main'] as String? ?? '',
        item['main'] as String? ?? '',
      ),
      'negative_prompt': mergeAgentPrompt(
        shared['negative'] as String? ?? '',
        '',
      ),
      'characters': [
        for (var j = 0; j < chars.length; j++)
          mergeAgentPrompt(chars[j], j < additions.length ? additions[j] : ''),
      ],
    };
  }

  Future<AgentPromptSetImport?> importItem(
    AgentWorkspace workspace,
    Map<String, dynamic> set,
    int index,
    void Function(String) toast, {
    void Function()? check,
  }) async {
    void guard() {
      check?.call();
      if (naiAgentGenerationBusy(ref)) {
        throw const NaiAgentToolError(
          'busy',
          'Generation is active; draft was not changed',
        );
      }
    }

    guard();
    final before = readBridgeDraft(ref);
    final originalCharacters = ref.read(characterPromptNotifierProvider);
    CharacterPromptConfig? nextCharacters;
    final patch = merged(set, index);
    final prompts = patch.remove('characters') as List<String>;
    final model = ref.read(generationParamsNotifierProvider).modelSpec;
    final allowed = model.characterPrompts ? model.maxCharacters : 0;
    final positions = effectiveAgentPromptSetPositions(
      set['shared'] as Map,
      (set['items'] as List)[index] as Map,
    );
    // V4/V4.5 accept coordinates too; freeformCharacterPosition is V5-only.
    final importPositions =
        model.isV4OrLater && positions.take(allowed).any((p) => p != null);
    if (prompts.isNotEmpty && allowed == 0) {
      toast(currentL10n.ag_psNoCharacters);
    } else if (prompts.length > allowed) {
      toast(currentL10n.ag_psTooManyCharacters(allowed));
    }
    if (prompts.isNotEmpty && allowed > 0) {
      final chars = agentMaps(
        before.fields['characters'],
      ).map((c) => Map<String, dynamic>.of(c)).toList();
      for (var j = 0; j < prompts.length && j < allowed; j++) {
        if (j >= chars.length) {
          chars.add({'id': const Uuid().v4(), 'prompt': '', 'uc': ''});
        }
        chars[j]['prompt'] = prompts[j];
      }
      patch['characters'] = chars;
      nextCharacters = originalCharacters.copyWith(
        globalAiChoice: importPositions
            ? false
            : originalCharacters.globalAiChoice,
        characters: [
          for (var j = 0; j < chars.length; j++)
            _importCharacter(
              j < originalCharacters.characters.length
                  ? originalCharacters.characters[j]
                  : CharacterPrompt(id: chars[j]['id'] as String),
              j < prompts.length && j < allowed
                  ? prompts[j]
                  : originalCharacters.characters[j].prompt,
              importPositions && j < allowed && j < positions.length
                  ? positions[j]
                  : null,
              custom: importPositions,
            ),
        ],
      );
      if (importPositions) {
        patch['use_coords'] = true;
        nextCharacters = nextCharacters.normalizeCustomPositions();
        // Carry normalization into generation params too, not only the UI.
        for (var j = 0; j < chars.length; j++) {
          final position = nextCharacters.characters[j].customPosition;
          if (position != null) {
            chars[j]['x'] = position.column;
            chars[j]['y'] = position.row;
          }
        }
      }
    }
    validateBridgePatch(patch);
    final ok = await guardedAgentUndo(
      expected: before.acknowledgementVersion,
      version: () {
        guard();
        return ref.read(bridgeDraftVersionProvider);
      },
      backup: () async {
        await backupBridgeDraft(workspace.agentDirectory, before);
      },
      apply: () {
        ref.read(bridgeDraftWriterProvider)(patch);
        if (nextCharacters case final config?) {
          ref
              .read(characterPromptNotifierProvider.notifier)
              .restoreAgentSnapshot(config);
        }
      },
    );
    if (!ok) return null;
    final version = ref.read(bridgeDraftVersionProvider);
    return AgentPromptSetImport(index, [
      for (final field in patch.keys)
        AgentDiffRestore(
          id: 'prompt-set/${set['set_id']}/$field',
          version: version,
          backup:
              jsonDecode(jsonEncode(before.toJson())) as Map<String, dynamic>,
          field: field,
        ),
    ]);
  }

  CharacterPrompt _importCharacter(
    CharacterPrompt original,
    String prompt,
    AgentPromptSetPosition? position, {
    required bool custom,
  }) => position == null
      ? original.copyWith(
          prompt: prompt,
          positionMode: custom && original.customPosition != null
              ? CharacterPositionMode.custom
              : original.positionMode,
        )
      : original.copyWith(
          prompt: prompt,
          positionMode: CharacterPositionMode.custom,
          customPosition: CharacterPosition(
            mode: CharacterPositionMode.custom,
            column: position.x,
            row: position.y,
          ),
        );

  Future<void> saveBlock(Map<String, dynamic> set) async {
    final atoms = [
      for (var i = 0; i < (set['items'] as List).length; i++)
        merged(set, i)['prompt'] as String,
    ];
    await ref.read(promptBlockLibraryNotifierProvider.future);
    await ref
        .read(promptBlockLibraryNotifierProvider.notifier)
        .createBlock(
          title: set['title'] as String,
          content: atoms.join(', '),
          atoms: atoms,
          folderId: null,
        );
  }

  String copyText(Map<String, dynamic> set, int index) {
    final value = merged(set, index);
    final chars = value['characters'] as List<String>;
    final positions = effectiveAgentPromptSetPositions(
      set['shared'] as Map,
      (set['items'] as List)[index] as Map,
    );
    String coordinates(int j) {
      final p = positions[j];
      return p == null
          ? ''
          : ' @ (${p.x.toStringAsFixed(2)}, ${p.y.toStringAsFixed(2)})';
    }

    return '# ${index + 1}. ${(set['items'] as List)[index]['title']}\n${value['prompt']}\n${[for (var j = 0; j < chars.length; j++) '[character ${j + 1}] ${chars[j]}${coordinates(j)}'].join('\n')}\n[negative] ${value['negative_prompt']}';
  }

  Future<void> copy(Map<String, dynamic> set, int? index) => Clipboard.setData(
    ClipboardData(
      text: index == null
          ? [
              for (var i = 0; i < (set['items'] as List).length; i++)
                copyText(set, i),
            ].join('\n\n')
          : copyText(set, index),
    ),
  );
}

/// Separate binding for idle UI actions, still owned by the current chat.
/// Approval has no dependency on a running Pi turn.
final agentPromptSetGenerationProvider = Provider.autoDispose
    .family<NaiAgentGenerationTools, (String, String, String)>((ref, key) {
      var alive = true;
      ref.onDispose(() => alive = false);
      return bindNaiAgentGeneration(
        ref,
        Directory(key.$1),
        NaiAgentConversationOwner(key.$2, key.$3),
        () => naiAgentGenerationBusy(ref),
        () => alive,
        completed: (result, produced) async {
          if (result['status'] != 'completed') return result;
          final records = <Map<String, dynamic>>[];
          for (final image in produced) {
            final path = await AgentWorkspaceFiles(Directory(key.$1)).export(
              'prompt-set.png',
              image.bytes,
              () {
                if (!alive) {
                  throw const NaiAgentToolError(
                    'closed',
                    'Conversation closed',
                  );
                }
              },
            );
            records.add({
              'image_id': image.id,
              'path': path,
              'width': image.width,
              'height': image.height,
            });
          }
          return {...result, 'images': records};
        },
      );
    });

Future<void> recordAgentPromptSetImages({
  required AgentWorkspace workspace,
  required String setId,
  required int index,
  required Map<String, dynamic> result,
  required void Function() check,
}) async {
  if (result['status'] != 'completed') {
    if (result['status'] == 'cancelled') return;
    throw NaiAgentToolError(
      'generation_failed',
      result['error'] as String? ?? currentL10n.naiAgent_error,
    );
  }
  final images = <Map<String, dynamic>>[];
  for (final image in agentMaps(result['images'])) {
    final path = image['path'];
    if (path is! String || path.isEmpty) continue;
    check();
    // Native paths may live outside the workspace. Persist a workspace-owned
    // byte copy so previews remain safe and survive history/cache eviction.
    // The UI generation binding exported these through the workspace guard.
    await AgentWorkspaceFiles(workspace.directory).read(path);
    final relative = path;
    images.add({
      if (image['image_id'] != null) 'image_id': image['image_id'],
      'path': relative,
      if (image['width'] != null) 'width': image['width'],
      if (image['height'] != null) 'height': image['height'],
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
  check();
  if (images.isNotEmpty) {
    await NaiAgentPromptSets(
      workspace.agentDirectory,
    ).appendImages(setId, index, images);
  }
}
