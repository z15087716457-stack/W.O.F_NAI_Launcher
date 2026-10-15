import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/model_display.dart';
import '../../core/constants/model_spec.dart';
import '../../core/shortcuts/default_shortcuts.dart';
import '../providers/shortcuts_provider.dart';
import '../../data/models/character/character_prompt.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../../core/services/anlas_calculator.dart';
import '../../core/services/prompt_token_counter_service.dart';
import '../../data/models/user/user_subscription.dart';
import '../../data/services/alias_resolver_service.dart';
import '../../l10n/app_localizations.dart';
import '../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/canvas_settings_provider.dart';
import '../providers/canvas_channel_provider.dart';
import '../providers/canvas_channel_feed_provider.dart';
import '../providers/character_position_canvas_provider.dart';
import '../providers/character_prompt_provider.dart';
import '../providers/cost_estimate_provider.dart';
import '../providers/generation/cloud_upscale_provider.dart';
import '../providers/generation/image_action_providers.dart';
import '../providers/generation/image_workflow_controller.dart';
import '../providers/generation/local_upscale_provider.dart';
import '../providers/generation/preview_selection_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/image_save_settings_provider.dart';
import '../providers/krita/bridge_agent_feedback.dart';
import '../providers/krita/bridge_draft_snapshot.dart';
import '../providers/krita/krita_bridge_notifier.dart';
import '../providers/layout_state_provider.dart';
import '../providers/local_gallery_provider.dart';
import '../providers/prompt_block_library_provider.dart';
import '../providers/prompt_token_counter_provider.dart';
import '../providers/prompt_translation_provider.dart';
import '../providers/quality_preset_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/uc_preset_provider.dart';
import '../screens/generation/widgets/generation_controls/generate_button_copy.dart';
import '../ui/gen/gen_contract.dart';
import '../widgets/bridge/agent_bridge_indicator.dart';
import '../utils/official_image_variations.dart';
import 'generation_backend.dart';
import 'generation_drop_wiring.dart';
import 'generation_reference_identity.dart';
import 'generation_references.dart';
import 'generation_settings.dart';
import 'generation_view_mapping.dart';
import 'tools_generation_wiring.dart';

final generationTranslationRouteLabelProvider = Provider<String?>((ref) {
  final route = ref.watch(promptAssistantConfigProvider).promptTranslationRoute;
  return route == null ? null : '${route.provider.name} · ${route.model.name}';
});
final generationClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
final generationCopySeedProvider = NotifierProvider<GenerationCopySeed, int>(
  GenerationCopySeed.new,
);

class GenerationCopySeed extends Notifier<int> {
  @override
  int build() {
    ref.listen(imagesPerRequestProvider, (_, _) => state++);
    ref.listen(
      generationParamsNotifierProvider.select((value) => value.nSamples),
      (_, _) => state++,
    );
    ref.listen(
      imageGenerationNotifierProvider.select((value) => value.status),
      (previous, next) {
        if (previous == GenerationStatus.generating &&
            next != GenerationStatus.generating) {
          state++;
        }
      },
    );
    return 1;
  }
}

final generationFavoriteImagesProvider = FutureProvider<Set<String>>((
  ref,
) async {
  final state = ref.watch(imageGenerationNotifierProvider);
  final saved = {
    for (final image in state.mergedPanelImages)
      if (image.filePath?.isNotEmpty == true) image.id: image.filePath!,
  };
  if (saved.isEmpty) return {};
  ref.watch(
    localGalleryNotifierProvider.select((value) => value.contentRevision),
  );
  final notifier = ref.read(localGalleryNotifierProvider.notifier);
  final statuses = await Future.wait(
    saved.entries.map(
      (entry) async => (entry.key, await notifier.isFavorite(entry.value)),
    ),
  );
  return {
    for (final entry in statuses)
      if (entry.$2) entry.$1,
  };
});

final generationViewDataProvider = Provider.autoDispose
    .family<GenViewData, AppLocalizations>((ref, l) {
      final params = ref.watch(generationParamsNotifierProvider);
      final spec = ModelSpecs.of(params.model);
      final request = ref.watch(generationRequestParamsProvider);
      final generation = ref.watch(imageGenerationNotifierProvider);
      final workflow = ref.watch(imageWorkflowControllerProvider);
      final draftWorkflow = ref.watch(draftImageWorkflowProvider);
      final layout = ref.watch(layoutStateNotifierProvider);
      final characters = ref.watch(characterPromptNotifierProvider);
      final quality = ref.watch(qualityPresetNotifierProvider);
      final uc = ref.watch(ucPresetNotifierProvider);
      final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
      final subscription = ref.watch(subscriptionNotifierProvider).subscription;
      final negative = ref.watch(generationNegativeTabProvider);
      final auth = ref.watch(authNotifierProvider);
      ref.watch(bridgeDraftVersionProvider);
      final draft = readBridgeDraft(ref);
      final projectedCharacters = [
        for (var index = 0; index < characters.characters.length; index++)
          characters.characters[index].copyWith(
            prompt: draft.fields['characters'][index]['prompt'] as String,
            negativePrompt: draft.fields['characters'][index]['uc'] as String,
          ),
      ];
      final translationRoute = ref.watch(
        generationTranslationRouteLabelProvider,
      );
      final translating = ref.watch(promptTranslationBusyProvider);
      final resolver = ref.read(aliasResolverServiceProvider.notifier);
      final count = ref.watch(imagesPerRequestProvider);
      final cooldown = ref.watch(generationCooldownProvider).remainingSeconds;
      final pins = ref.watch(canvasPinnedNotifierProvider);
      final pinImages = ref.read(canvasPinnedNotifierProvider.notifier).images;
      final groupSelection = ref.watch(generationCanvasGroupSelectionProvider);
      final preview = ref.watch(generationPreviewSelectionProvider);
      final focus = generationFocusView(
        generation,
        focus: groupSelection,
        selectedImage: preview,
        pinned: pinImages,
      );
      final images = {
        for (final image in [
          ...generation.mergedPanelImages,
          ...generation.displayImages,
          ...pinImages,
        ])
          image.id: image,
      };
      final focusTile =
          focus?.tiles.where((tile) => tile.id == preview).firstOrNull ??
          (groupSelection?.subimage != null &&
                  focus != null &&
                  groupSelection!.subimage! >= 0 &&
                  groupSelection.subimage! < focus.tiles.length
              ? focus.tiles[groupSelection.subimage!]
              : focus?.tiles
                    .where((tile) => images.containsKey(tile.id))
                    .firstOrNull);
      final image = images[focusTile?.id];
      final variationCost = image == null
          ? null
          : ref.watch(imageVariationCostProvider(image));
      final variationCostLoading =
          image != null &&
          variationCost == null &&
          image.canUseAsGenerationInput &&
          OfficialImageVariations.supportsSize(image.width, image.height) &&
          ref.watch(generatedImageMetadataProvider(image)).isLoading;
      final cost = ref.watch(estimatedCostProvider);
      final local = ref.watch(localUpscaleTaskProvider);
      final cloud = ref.watch(cloudUpscaleTaskProvider);
      final toolSheet = ref.watch(toolsSheetProvider);
      final bridge = ref.watch(kritaBridgeNotifierProvider);
      final busy =
          ref.watch(generationEncodingReferencesProvider).isNotEmpty ||
          generation.isGenerating ||
          workflow.isToolRunning ||
          local.running ||
          cloud.running ||
          bridge.isBridgeGenerating;
      final remaining = generation.totalImages < 1 ? 1 : generation.totalImages;
      final done = generation.currentImages
          .where(
            (image) =>
                !image.isVariationOriginal && !image.isFailedStreamSnapshot,
          )
          .length;
      final now = ref.watch(generationClockProvider)();
      final generatedLabel = workflow.isEnhance
          ? (workflow.enhance.localUpscale
                ? l.enhance_localAction
                : l.img2img_enhanceAction)
          : GenerateButtonCopy.pick(
              l10n: l,
              seed: ref.watch(generationCopySeedProvider),
              count: params.nSamples * count,
              now: now,
            );
      final runState = generation.isGenerating
          ? GenRunState.generating
          : busy || !auth.isAuthenticated || request.prompt.trim().isEmpty
          ? GenRunState.blocked
          : cooldown > 0
          ? GenRunState.cooldown
          : GenRunState.ready;
      final positive = spec.v4Prompts
          ? ref
                .watch(
                  promptTokenUsageProvider(PromptTokenCountTarget.positive),
                )
                .valueOrNull
          : null;
      final negativeUsage = spec.v4Prompts
          ? ref
                .watch(
                  promptTokenUsageProvider(PromptTokenCountTarget.negative),
                )
                .valueOrNull
          : null;
      GenTokens tokens(PromptTokenUsage? value) => GenTokens(
        value?.usedTokens ?? 0,
        value?.limit ??
            PromptTokenCounterService.tokenLimitForModel(params.model) ??
            512,
      );
      PromptTokenCountPayload payload(PromptTokenCountTarget target) =>
          buildPromptTokenCountPayload(
            target: target,
            prompt: draft.fields['prompt'] as String,
            negativePrompt: draft.fields['negative_prompt'] as String,
            model: params.model,
            qualityToggle: quality.usesNativePreset,
            qualityTagPreset: quality.nativePreset,
            ucPreset: UcPresets.toApiValue(uc.presetType),
            transparentBackground: params.transparentBackground,
            qualityMode: quality.mode,
            qualityContent: ref.read(currentQualityEntryProvider)?.content,
            ucPresetType: uc.presetType,
            ucPresetContent: ref.read(currentUcEntryProvider)?.content,
            useCustomUcPreset: uc.isCustom,
            characters: spec.characterPrompts ? projectedCharacters : const [],
            resolveAliases: resolver.resolveAliases,
          );
      List<GenPreviewSection> sections(PromptTokenCountTarget target) {
        final content = payload(target);
        return [
          GenPreviewSection(
            label: target == PromptTokenCountTarget.positive
                ? l.prompt_mainPositive
                : l.gen_negative,
            text: content.breakdown[0].texts.join(', '),
          ),
          if (content.breakdown[1].texts.any((text) => text.trim().isNotEmpty))
            GenPreviewSection(
              label: target == PromptTokenCountTarget.positive
                  ? l.qualityTags_positive
                  : l.promptToken_negativePreset,
              text: content.breakdown[1].texts.join(', '),
            ),
          for (var index = 0; index < projectedCharacters.length; index++)
            if (spec.characterPrompts &&
                projectedCharacters[index].enabled &&
                (target == PromptTokenCountTarget.positive
                        ? projectedCharacters[index].prompt
                        : projectedCharacters[index].negativePrompt)
                    .trim()
                    .isNotEmpty)
              GenPreviewSection(
                label: projectedCharacters[index].customName.isNotEmpty
                    ? projectedCharacters[index].customName
                    : l.gen_characterN(index + 1),
                text: resolver.resolveAliases(
                  target == PromptTokenCountTarget.positive
                      ? projectedCharacters[index].prompt
                      : projectedCharacters[index].negativePrompt,
                ),
              ),
        ];
      }

      final translationDocuments = [
        PillDocument.fromJson(
          Map<String, dynamic>.from(
            draft.documents[negative ? 'negative_prompt' : 'prompt'] as Map,
          ),
        ),
        for (final role in projectedCharacters)
          if (role.enabled)
            PillDocument.fromJson(
              Map<String, dynamic>.from(
                draft.documents['characters']['lanes'][role.id][negative
                        ? 'negative'
                        : 'positive']
                    as Map,
              ),
            ),
      ];
      final translations = [
        for (final document in translationDocuments)
          for (final instance in document.instances.values)
            if (instance.translation != null) instance.translation!,
      ];
      final feedback = bridge.enabled
          ? ref.watch(bridgeAgentFeedbackProvider)
          : null;
      final usage = spec.opusUsageLimit ? subscription?.usage : null;
      final cloudCost = image == null
          ? null
          : AnlasCalculator.calculateNovelAiUpscaleCost(
              inputWidth: image.width,
              inputHeight: image.height,
            );
      final localModels = workflow.upscale.backend == UpscaleBackend.novelai
          ? null
          : ref.watch(localUpscaleModelsProvider).valueOrNull;
      final favorites =
          ref.watch(generationFavoriteImagesProvider).valueOrNull ??
          const <String>{};
      return GenViewData(
        model: params.model,
        models: [
          for (final id in {...ImageModels.allModels, params.model})
            GenModel(
              id: id,
              name: ModelDisplay.shortNameOf(id),
              description: ModelDisplay.descriptionOf(l, id),
              legacy: ModelDisplay.groupOf(id) == ModelListGroup.legacy,
            ),
        ],
        furry: spec.v4Prompts ? params.furryMode : null,
        quota: GenQuota(
          anlas: subscription?.anlasBalance,
          opusPercent: usage?.displayPercent,
          opusTip: usage == null ? null : generationOpusTip(l, usage),
        ),
        layout: generationLayoutView(layout),
        prompt: GenPromptData(
          negative: negative,
          positiveTokens: tokens(positive),
          negativeTokens: tokens(negativeUsage),
          qualityPresets: [
            GenOption(
              id: 'standard',
              label: spec.isV5 ? l.qualityTags_standard : l.qualityTags_label,
            ),
            if (spec.isV5) GenOption(id: 'light', label: l.qualityTags_light),
            GenOption(id: 'none', label: l.qualityTags_none),
            for (final id in quality.customEntryIds)
              if (library?.blockById(id) case final block?)
                GenOption(id: 'block:$id', label: block.title),
          ],
          qualityPreset: quality.isCustom
              ? 'block:${quality.customEntryId}'
              : quality.nativePreset.name,
          ucPresets: [
            for (final type in UcPresets.getPresetsForModel(params.model).keys)
              GenOption(id: type.name, label: generationUcLabel(l, type)),
            for (final id in uc.customEntryIds)
              if (library?.blockById(id) case final block?)
                GenOption(id: 'block:$id', label: block.title),
          ],
          ucPreset: uc.isCustom
              ? 'block:${uc.customEntryId}'
              : uc.presetType.name,
          transparent: spec.transparency ? params.transparentBackground : null,
          positivePreview: sections(PromptTokenCountTarget.positive),
          negativePreview: sections(PromptTokenCountTarget.negative),
          tools: GenPromptTools(
            palettePinned: layout.blockPaletteToolPinned,
            dockPinned: layout.blockLibraryPanelToolPinned,
            translatePinned: layout.translationToolPinned,
            agentPinned: layout.naiAgentToolPinned,
            autoFormat: ref.watch(autoFormatPromptSettingsProvider),
            highlight: ref.watch(highlightEmphasisSettingsProvider),
            sdConvert: ref.watch(sdSyntaxAutoConvertSettingsProvider),
            related: ref.watch(cooccurrenceSettingsProvider),
          ),
          translate: GenTranslate(
            busy: translating,
            showing: translations.any((pill) => !pill.showOriginal),
            route: translationRoute,
          ),
          bridge: feedback == null
              ? null
              : GenBridge(
                  phase: switch (feedback.phase) {
                    BridgeAgentPhase.working => GenBridgePhase.working,
                    BridgeAgentPhase.synced => GenBridgePhase.synced,
                    BridgeAgentPhase.failed => GenBridgePhase.failed,
                    _ => GenBridgePhase.idle,
                  },
                  label: bridgeAgentStatus(l, bridge, feedback),
                ),
        ),
        characters: !spec.characterPrompts
            ? null
            : GenCharactersData(
                aiPosition: characters.globalAiChoice,
                max: spec.maxCharacters,
                freeform: spec.freeformCharacterPosition,
                list: [
                  for (final role in projectedCharacters)
                    GenCharacter(
                      id: role.id,
                      name: role.customName.isEmpty ? null : role.customName,
                      gender: GenGender.values.byName(role.gender.name),
                      enabled: role.enabled,
                      positiveTokens: tokens(
                        ref
                            .watch(
                              characterPromptTokenUsageProvider((
                                characterId: role.id,
                                negative: false,
                              )),
                            )
                            .valueOrNull,
                      ),
                      negativeTokens: tokens(
                        ref
                            .watch(
                              characterPromptTokenUsageProvider((
                                characterId: role.id,
                                negative: true,
                              )),
                            )
                            .valueOrNull,
                      ),
                      position:
                          role.customPosition == null ||
                              role.positionMode ==
                                  CharacterPositionMode.aiChoice
                          ? null
                          : Offset(
                              role.customPosition!.column,
                              role.customPosition!.row,
                            ),
                    ),
                ],
              ),
        refs: generationRefsView(
          params,
          draftWorkflow,
          ref.read(generationReferenceIdentityProvider),
          enabled: ref.watch(generationImg2ImgEnabledProvider),
          encoding: ref.watch(generationEncodingReferencesProvider),
          dropHover: ref.watch(generationDropHoverProvider),
          recent: spec.vibetransfer
              ? ref.watch(referencePanelNotifierProvider).recentEntries
              : const [],
        ),
        image: generationImageView(params, imagesPerRequest: count),
        params: generationParamsView(params, lastSeed: image?.metadata?.seed),
        generate: GenGenerateData(
          state: runState,
          label: generation.isGenerating
              ? l.generation_generating
              : generatedLabel,
          cost: cost,
          insufficient: ref.watch(isBalanceInsufficientProvider),
          done: done,
          total: generation.isGenerating ? remaining : params.nSamples * count,
          progress: generation.isGenerating
              ? ((done + generation.progress) / remaining).clamp(0, 1)
              : null,
          cooldown: cooldown,
          blocked: runState == GenRunState.blocked
              ? busy
                    ? l.kritaBridge_busyGenerating
                    : !auth.isAuthenticated
                    ? l.onlineGallery_pleaseLogin
                    : l.generation_pleaseInputPrompt
              : null,
        ),
        canvas: GenCanvasData(
          channel: ref.watch(canvasChannelNotifierProvider),
          channelTop: ref.watch(canvasChannelFeedProvider).top,
          focus: focus,
          info: image == null
              ? null
              : GenFocusInfo(
                  tileId: image.id,
                  width: image.width,
                  height: image.height,
                  seed: image.metadata?.seed,
                  pinned: pins.contains(image.id),
                  canUseAsInput: image.canUseAsGenerationInput,
                  canCompareOriginal: image.canCompareOriginal,
                  variationsCost: variationCost,
                  variationsCostLoading: variationCostLoading,
                  enhanceCost: ref.watch(toolsEnhanceCostProvider(image)),
                ),
          upscale: GenUpscale(
            running: local.running || cloud.running,
            progress: local.progress?.fraction,
            status: toolsUpscaleStatus(local.progress),
            cost:
                workflow.upscale.backend == UpscaleBackend.novelai &&
                    cloudCost != null &&
                    cloudCost >= 0
                ? cloudCost
                : null,
            available: workflow.upscale.backend == UpscaleBackend.novelai
                ? cloudCost != null && cloudCost >= 0
                : ref.watch(toolsWindowsProvider) &&
                      localModels?.any(
                            (model) =>
                                model.installed &&
                                model.id == workflow.upscale.localModel,
                          ) ==
                          true,
            selected: workflow.upscale.backend == UpscaleBackend.novelai
                ? 'novelai'
                : 'local:${workflow.upscale.localModel}',
            options: [
              GenOption(
                id: 'novelai',
                label: l.img2img_novelAiCloudUpscaleTitle,
              ),
              for (final model in localModels ?? const [])
                if (model.installed)
                  GenOption(id: 'local:${model.id}', label: model.name),
            ],
          ),
          backdrop: spec.transparency
              ? ref.watch(canvasImageBackgroundNotifierProvider)
              : null,
          zoomToFill: ref.watch(canvasZoomToFillNotifierProvider),
          positioning: ref.watch(characterPositionCanvasProvider),
          locked: busy,
          generateShortcut:
              ref.watch(effectiveShortcutProvider(ShortcutIds.generateImage)) ??
              '',
          error: generation.status == GenerationStatus.error
              ? GenError(title: l.common_error, detail: generation.errorMessage)
              : null,
          sheet: toolSheet?.image.id == image?.id ? toolSheet?.sheet : null,
        ),
        history: generationHistoryView(
          generation,
          selected: focus?.id,
          favorites: favorites,
          autoSave: ref.watch(imageSaveSettingsNotifierProvider).autoSave,
          pinned: pins.length,
          now: now,
        ),
        now: now,
      );
    });

String generationUcLabel(AppLocalizations l, UcPresetType value) =>
    switch (value) {
      UcPresetType.heavy => l.ucPreset_heavy,
      UcPresetType.light => l.ucPreset_light,
      UcPresetType.furryFocus => l.ucPreset_furryFocus,
      UcPresetType.humanFocus => l.ucPreset_humanFocus,
      UcPresetType.none => l.ucPreset_none,
      UcPresetType.lowQuality => l.ucPreset_lowQuality,
      UcPresetType.badAnatomy => l.ucPreset_badAnatomy,
    };
String generationOpusTip(AppLocalizations l, OpusUsage usage) {
  final seconds = usage.timeUntilNextPercent;
  final time = seconds >= 3600
      ? l.opusUsage_hoursMinutes(seconds ~/ 3600, (seconds % 3600) ~/ 60)
      : seconds >= 60
      ? l.opusUsage_minutesSeconds(seconds ~/ 60, seconds % 60)
      : l.opusUsage_seconds(seconds);
  return [
    usage.isNegative
        ? l.opusUsage_exhausted
        : l.opusUsage_remaining(usage.percent.toStringAsFixed(1)),
    seconds > 0 ? l.opusUsage_recharging(time) : l.opusUsage_notRecharging,
    l.opusUsage_clickToRefresh,
  ].join('\n');
}
