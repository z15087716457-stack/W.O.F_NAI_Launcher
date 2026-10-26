import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/model_spec.dart';
import '../../core/utils/localization_extension.dart';
import '../providers/character_prompt_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/pill_roll_coordinator.dart';
import '../providers/pill_workspace_provider.dart';
import '../providers/tips_provider.dart';
import '../ui/gen/gen_contract.dart';
import '../widgets/prompt/comfyui_import_wrapper.dart';
import '../widgets/common/workspace_text_scale_scope.dart';
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
    this.explore = false,
  });
  final GenEditorTarget target;
  final String? characterId;

  /// 画风探索：正向基础提示词可以切换随机块的进化标记，空白提示用探索的提示语。
  final bool explore;

  @override
  Widget build(BuildContext context, WidgetRef ref) => WorkspaceTextScaleScope(
    child: Builder(builder: (context) => _buildEditor(context, ref)),
  );

  Widget _buildEditor(BuildContext context, WidgetRef ref) {
    final model = ref.watch(
      generationParamsNotifierProvider.select((p) => p.model),
    );
    if (target.negative && !ModelSpecs.of(model).customNegativePrompt) {
      return Text(context.l10n.gen_turboNegative);
    }
    final input = ref.watch(
      generationParamsNotifierProvider.select(
        (params) => (
          model: params.model,
          text: target.isBase
              ? (target.negative ? params.negativePrompt : params.prompt)
              : null,
        ),
      ),
    );
    final index = target.character;
    final character = target.isBase
        ? null
        : ref.watch(
            characterPromptNotifierProvider.select(
              (config) => characterId != null
                  ? config.findCharacterById(characterId!)
                  : index != null &&
                        index >= 0 &&
                        index < config.characters.length
                  ? config.characters[index]
                  : null,
            ),
          );
    if (!target.isBase && character == null) return const SizedBox.shrink();
    final scope = character == null
        ? target.negative
              ? PillScopes.negative
              : PillScopes.main
        : target.negative
        ? PillScopes.charNeg(character.id)
        : PillScopes.charPos(character.id);
    final plain = character == null
        ? input.text!
        : target.negative
        ? character.negativePrompt
        : character.prompt;
    final spec = ModelSpecs.of(input.model);
    final explorePrompt = explore && target.isBase && !target.negative;
    final editorConfig = UnifiedPromptConfig(
      embedded: true,
      enableSyntaxHighlight: ref.watch(highlightEmphasisSettingsProvider),
      numericEmphasisEnabled: spec.v4Prompts,
      enableAutoFormat: ref.watch(autoFormatPromptSettingsProvider),
      enableSdSyntaxAutoConvert: ref.watch(sdSyntaxAutoConvertSettingsProvider),
      showClearButton: false,
      hintText: target.isBase && !target.negative
          ? watchTipHint(
              ref,
              context.l10n,
              explore ? TipSurface.explorePrompt : TipSurface.prompt,
            )
          : null,
      enableComfyuiImport:
          target.isBase && !target.negative && spec.characterPrompts,
    );
    final textStyle = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: target.fullscreen ? 14 : 13, height: 1.5);
    Widget editor(int minLines) => PromptPillEditor(
      key: ValueKey('generation-editor-$scope-${target.fullscreen}'),
      pillScope: scope,
      enableBlurredUndo: true,
      initialPlainText: plain,
      minLines: minLines,
      autoGrow: true,
      allowEvolutionToggle: explorePrompt,
      textStyle: textStyle,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
      ),
      config: editorConfig,
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
    if (target.fullscreen) {
      // 全屏：最少行数撑满面板，点空白处也能落光标；长文在面板里滚动。
      return LayoutBuilder(
        builder: (context, constraints) {
          final lineHeight =
              MediaQuery.textScalerOf(context).scale(textStyle.fontSize!) *
              textStyle.height!;
          final lines = constraints.hasBoundedHeight
              ? (constraints.maxHeight / lineHeight).floor().clamp(8, 80)
              : 8;
          return SingleChildScrollView(child: editor(lines));
        },
      );
    }
    if (!target.isBase) return editor(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final lineHeight =
            MediaQuery.textScalerOf(context).scale(textStyle.fontSize!) *
            textStyle.height!;
        // 卡片高约 0.72×宽；编辑槽比卡片窄 46px，头尾约 92px，
        // 折算后从槽宽的 0.72 倍扣除约 60px。长正文仍可继续增高。
        final minLines = constraints.hasBoundedWidth
            ? ((constraints.maxWidth * .72 - 60) / lineHeight).round().clamp(
                4,
                16,
              )
            : 4;
        return editor(minLines);
      },
    );
  }
}

final generationEditorImportProvider =
    Provider<ComfyuiImportCommit Function(bool Function())>(
      (ref) =>
          (alive) => beginGenerationComfyuiImport(ref, alive: alive),
    );
