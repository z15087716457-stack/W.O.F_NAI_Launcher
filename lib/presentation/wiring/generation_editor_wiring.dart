import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/model_spec.dart';
import '../../core/utils/localization_extension.dart';
import '../providers/character_prompt_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/pill_roll_coordinator.dart';
import '../providers/pill_workspace_provider.dart';
import '../ui/gen/gen_contract.dart';
import '../widgets/prompt/comfyui_import_wrapper.dart';
import '../widgets/prompt/pills/prompt_pill_editor.dart';
import '../widgets/prompt/unified/unified_prompt_config.dart';
import 'generation_backend.dart';

ComfyuiImportCommit beginGenerationComfyuiImport(
  Ref ref, {
  bool Function()? alive,
}) {
  final commit = ref.read(generationBackendProvider).captureDraft(alive: alive);
  return (prompt, characters) => commit(() {
    final spec = ModelSpecs.of(
      ref.read(generationParamsNotifierProvider).model,
    );
    if (!spec.characterPrompts || characters.length > spec.maxCharacters) {
      throw StateError(currentL10n.bridge_conflict);
    }
    ref
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately(prompt);
    ref.read(characterPromptNotifierProvider.notifier).replaceAll(characters);
  });
}

class GenerationEditorWiring extends ConsumerWidget {
  const GenerationEditorWiring({
    super.key,
    required this.target,
    this.characterId,
  });
  final GenEditorTarget target;
  final String? characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(generationParamsNotifierProvider);
    final config = ref.watch(characterPromptNotifierProvider);
    final index = target.character;
    final character = target.isBase
        ? null
        : characterId != null
        ? config.findCharacterById(characterId!)
        : index != null && index >= 0 && index < config.characters.length
        ? config.characters[index]
        : null;
    if (!target.isBase && character == null) return const SizedBox.shrink();
    final scope = character == null
        ? target.negative
              ? PillScopes.negative
              : PillScopes.main
        : target.negative
        ? PillScopes.charNeg(character.id)
        : PillScopes.charPos(character.id);
    final plain = character == null
        ? target.negative
              ? params.negativePrompt
              : params.prompt
        : target.negative
        ? character.negativePrompt
        : character.prompt;
    final spec = ModelSpecs.of(params.model);
    final editor = PromptPillEditor(
      key: ValueKey('generation-editor-$scope-${target.fullscreen}'),
      pillScope: scope,
      initialPlainText: plain,
      minLines: target.fullscreen ? 8 : 1,
      autoGrow: true,
      textStyle: DefaultTextStyle.of(
        context,
      ).style.copyWith(fontSize: target.fullscreen ? 14 : 13, height: 1.5),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
      ),
      config: UnifiedPromptConfig(
        embedded: true,
        enableSyntaxHighlight: ref.watch(highlightEmphasisSettingsProvider),
        numericEmphasisEnabled: spec.v4Prompts,
        enableAutoFormat: ref.watch(autoFormatPromptSettingsProvider),
        enableSdSyntaxAutoConvert: ref.watch(
          sdSyntaxAutoConvertSettingsProvider,
        ),
        showClearButton: false,
        enableComfyuiImport:
            target.isBase && !target.negative && spec.characterPrompts,
      ),
      beginComfyuiImport:
          target.isBase && !target.negative && spec.characterPrompts
          ? () =>
                ref.read(generationEditorImportProvider)(() => context.mounted)
          : null,
      onChanged: (value) {
        if (!context.mounted ||
            ref.read(pillWorkspaceProvider(scope)).projection != value) {
          return;
        }
        ref.read(pillRollCoordinatorProvider).syncLaneProjection(scope, value);
      },
    );
    return target.fullscreen ? SingleChildScrollView(child: editor) : editor;
  }
}

final generationEditorImportProvider =
    Provider<ComfyuiImportCommit Function(bool Function())>(
      (ref) =>
          (alive) => beginGenerationComfyuiImport(ref, alive: alive),
    );
