import 'nai_agent_generation_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/localization_extension.dart';
import '../../core/shortcuts/default_shortcuts.dart';
import '../widgets/shortcuts/shortcut_aware_widget.dart';
import '../widgets/navigation/integrated_title_bar.dart';
import 'tools_generation_wiring.dart';
import '../providers/character_prompt_provider.dart';
import '../providers/canvas_channel_provider.dart';
import '../providers/pill_workspace_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/image_save_settings_provider.dart';
import '../providers/krita/krita_bridge_notifier.dart';
import '../providers/prompt_translation_provider.dart';
import '../providers/subscription_provider.dart';
import '../router/app_router.dart';
import '../ui/gen/gen_contract.dart';
import '../ui/gen/gen_page.dart';
import '../widgets/bridge/agent_bridge_indicator.dart';
import 'generation_backend.dart';
import 'generation_canvas_wiring.dart';
import 'generation_backdrop_wiring.dart';
import 'generation_canvas_menu.dart';
import 'generation_data_wiring.dart';
import 'generation_editor_wiring.dart';
import 'generation_history_actions.dart';
import 'generation_operations.dart';
import 'generation_references.dart';
import 'generation_settings.dart';
import '../providers/simple_output_viewer_provider.dart';
import '../providers/nai_agent/nai_agent_window_controller.dart';
import '../providers/nai_agent/nai_agent_workspace_provider.dart';
import 'nai_agent/agent_toggle_wiring.dart';
import '../widgets/common/prompt_translation_guide.dart';
import '../screens/generation/widgets/generation_welcome.dart';

class GenerationRoute extends ConsumerStatefulWidget {
  const GenerationRoute({super.key});
  @override
  ConsumerState<GenerationRoute> createState() => _GenerationRouteState();
}

class _GenerationRouteState extends ConsumerState<GenerationRoute> {
  final wiring = GlobalKey<_GenerationWiringState>();
  @override
  Widget build(BuildContext context) {
    final operations = GenerationOperations(
      ref,
      context,
      () => context.mounted && ModalRoute.of(context)?.isCurrent != false,
    );
    GenViewData getData() => ref.read(generationViewDataProvider(context.l10n));
    final settings = ref.read(generationSettingsProvider);
    GenController? controller() => wiring.currentState?.controller;
    void focused(Future<void> Function(String) action) {
      final id = getData().canvas.info?.tileId;
      if (id != null) operations.run(() => action(id));
    }

    void stop() {
      if (ref.read(kritaBridgeNotifierProvider).isBridgeGenerating) {
        ref.read(kritaBridgeNotifierProvider.notifier).cancelActiveRequest();
      } else if (ref.read(imageGenerationNotifierProvider).isGenerating) {
        ref.read(imageGenerationNotifierProvider.notifier).cancel();
      }
    }

    void clear() {
      final scope = ref.read(pillActiveEditorTargetProvider)?.scope;
      final chars = ref.read(characterPromptNotifierProvider).characters;
      final index = chars.indexWhere(
        (character) =>
            scope == PillScopes.charPos(character.id) ||
            scope == PillScopes.charNeg(character.id),
      );
      final negative = index >= 0
          ? scope == PillScopes.charNeg(chars[index].id)
          : scope == PillScopes.negative ||
                scope == null && ref.read(generationNegativeTabProvider);
      if (scope != null &&
          scope != PillScopes.main &&
          scope != PillScopes.negative &&
          index < 0) {
        return;
      }
      operations.run(
        () => operations.clearPrompt(
          index < 0
              ? GenEditorTarget.base(negative: negative)
              : GenEditorTarget.character(index, negative: negative),
          index < 0 ? null : chars[index].id,
        ),
      );
    }

    return WindowChromePage(
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, box) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ShortcutAwareWidget(
                  contextType: ShortcutContext.generation,
                  autofocus: true,
                  shortcuts: {
                    ShortcutIds.generateImage: () =>
                        operations.run(operations.generate),
                    ShortcutIds.cancelGeneration: stop,
                    ShortcutIds.clearPrompt: clear,
                    ShortcutIds.togglePromptMode: () =>
                        ref.read(generationNegativeTabProvider.notifier).state =
                            !ref.read(generationNegativeTabProvider),
                    ShortcutIds.openTagLibrary: () =>
                        context.go(AppRoutes.promptBlockLibrary),
                    ShortcutIds.saveImage: () =>
                        focused((id) => operations.saveImages([id])),
                    ShortcutIds.copyImage: () => focused(operations.copyImage),
                    ShortcutIds.upscaleImage: () => focused(operations.upscale),
                    ShortcutIds.fullscreenPreview: () =>
                        focused(operations.viewer),
                    ShortcutIds.reuseParams: () => focused(operations.reuse),
                    ShortcutIds.openParamsPanel: () =>
                        controller()?.setDrawer(true),
                    ShortcutIds.openHistoryPanel: () => operations.run(
                      () => settings.layout(
                        getData().layout.copyWith(
                          historyOpen: !getData().layout.historyOpen,
                        ),
                        previous: getData().layout,
                      ),
                    ),
                  },
                  child: NaiAgentGenerationHost(
                    child: GenerationWiring(key: wiring),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

typedef GenerationPageBuilder =
    Widget Function({
      required GenViewData data,
      required GenActions actions,
      required GenSlots slots,
    });

class GenerationWiring extends ConsumerStatefulWidget {
  const GenerationWiring({
    super.key,
    this.builder = GenerationPage.new,
    this.explore = false,
  });
  final GenerationPageBuilder builder;

  /// 画风探索编辑列：正向提示词允许切换进化标记，提示语换成探索的。
  final bool explore;
  @override
  ConsumerState<GenerationWiring> createState() => _GenerationWiringState();
}

class _GenerationWiringState extends ConsumerState<GenerationWiring> {
  GenActions? _actions;
  GenSlots? _slots;
  Object? _slotInputs;

  GenController? get controller {
    GenController? result;
    void locate(Element element) {
      if (element.widget case final GenScope scope) {
        result = scope.controller;
      } else if (result == null) {
        element.visitChildren(locate);
      }
    }

    context.visitChildElements(locate);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(generationViewDataProvider(context.l10n));
    final agentAvailable = NaiAgentIntegrationScope.activeOf(context);
    final agentExpanded =
        agentAvailable &&
        (ref.watch(naiAgentWindowControllerProvider).presentationExpanded ??
            ref.watch(
              naiAgentUiPreferencesProvider.select(
                (value) => value.settings.panelExpanded,
              ),
            ));
    final settings = ref.read(generationSettingsProvider);
    final references = ref.read(generationReferencesProvider);
    final history = ref.read(generationHistoryActionsProvider);
    final operations = GenerationOperations(ref, context, () => mounted);
    GenViewData currentData() =>
        ref.read(generationViewDataProvider(context.l10n));
    String characterId(int index) {
      final characters = ref.read(characterPromptNotifierProvider).characters;
      return index >= 0 && index < characters.length
          ? characters[index].id
          : throw StateError(context.l10n.bridge_conflict);
    }

    void run(Future<void> Function() task) => operations.run(task);
    void focus(void Function() action) {
      if (ref.read(toolsSheetProvider) == null) {
        action();
      } else {
        run(() async {
          await operations.closeToolSheet();
          if (mounted) action();
        });
      }
    }

    final simpleViewer = ref.watch(simpleOutputViewerNotifierProvider);
    final slotInputs = (
      agentAvailable,
      agentExpanded,
      simpleViewer,
      data.prompt.negative,
      widget.explore,
    );
    if (_slots == null || _slotInputs != slotInputs) {
      _slotInputs = slotInputs;
      _slots = GenSlots(
        panelBackdrop: (context, viewport) =>
            GenerationPanelBackdropWiring(canvasViewport: viewport),
        emptyCanvas: (_) => const GenerationWelcome(),
        translationGuide: (_, onBack) => PromptTranslationGuide(onBack: onBack),
        agentToggle: agentAvailable ? const AgentToggleWiring() : null,
        historyCaptionInset: !agentExpanded,
        preserveHistory: agentExpanded,
        canvas: simpleViewer
            ? null
            : (context, tile) => GenerationCanvasWiring(tileBuilder: tile),
        editor: (context, target) => GenerationEditorWiring(
          target: target,
          explore: widget.explore,
          characterId: target.character == null
              ? null
              : characterId(target.character!),
        ),
        dock: operations.dock(data.prompt.negative),
        drop: operations.drop,
        historyDrag: operations.historyDrag,
        toolSheet: const ToolsGenerationSheetWiring(),
      );
    }
    final page = widget.builder(
      data: data,
      slots: _slots!,
      actions: _actions ??= GenActions(
        onChannelChanged: (value) =>
            ref.read(canvasChannelNotifierProvider.notifier).set(value),
        onLayoutChanged: (value) =>
            run(() => settings.layout(value, previous: currentData().layout)),
        onModelChanged: (value) => run(() => settings.model(value)),
        onTurboChanged: (value) => run(() => settings.turbo(value)),
        onFurryChanged: (value) => run(() => settings.furry(value)),
        onOpenQuota: () => run(
          () =>
              ref.read(subscriptionNotifierProvider.notifier).refreshBalance(),
        ),
        onNegativeTab: (value) {
          if (currentData().prompt.negativeSupported) {
            ref.read(generationNegativeTabProvider.notifier).state = value;
          }
        },
        onClearPrompt: (target) => run(
          () => operations.clearPrompt(
            target,
            target.character == null ? null : characterId(target.character!),
          ),
        ),
        onQualityPreset: (value) => run(() => settings.quality(value)),
        onUcPreset: (value) => run(() => settings.uc(value)),
        onTransparentChanged: (value) => run(() => settings.transparent(value)),
        onPromptTool: (tool, value) =>
            run(() => settings.promptTool(tool, value)),
        onOpenPalette: (rect) => run(() => operations.openPalette(rect)),
        onTranslate: () => run(() async {
          await ref
              .read(promptTranslationCoordinatorProvider)
              .translate(currentData().prompt.negative);
        }),
        onToggleTranslation: () => ref
            .read(promptTranslationCoordinatorProvider)
            .toggleAll(currentData().prompt.negative),
        onTranslationSettings: () =>
            context.go('${AppRoutes.settings}?section=promptAssistant'),
        onOpenBridge: (rect) => run(
          () => AgentBridgeIndicator.openPanel(context, ref, anchorRect: rect),
        ),
        onAddCharacter: (gender) => run(() => settings.addCharacter(gender)),
        onClearCharacters: () => run(settings.clearCharacters),
        onRemoveCharacter: (index) =>
            run(() => settings.removeCharacter(characterId(index))),
        onMoveCharacter: (index, delta) =>
            run(() => settings.moveCharacter(characterId(index), delta)),
        onCharacterEnabled: (index, value) =>
            run(() => settings.characterEnabled(characterId(index), value)),
        onRenameCharacter: (index, value) =>
            run(() => settings.renameCharacter(characterId(index), value)),
        onCharacterGender: (index, value) =>
            run(() => settings.characterGender(characterId(index), value)),
        onCharacterToLibrary: (index) =>
            run(() => operations.characterToLibrary(characterId(index))),
        onAiPositionChanged: (value) => run(() => settings.aiPosition(value)),
        onCharacterPosition: (index, value) =>
            run(() => settings.characterPosition(characterId(index), value)),
        onPositioningChanged: (value) => run(() => settings.positioning(value)),
        onImg2ImgUpload: () =>
            run(() => operations.files(GenDropTarget.img2img)),
        onImg2ImgFromLibrary: () =>
            run(() => operations.library(GenDropTarget.img2img)),
        onImg2ImgSketch: () => run(operations.sketch),
        onImg2ImgChanged: (value) => run(
          () => references.img2img(value, previous: currentData().refs.img2img),
        ),
        onImg2ImgEdit: () => run(() => operations.editSource(false)),
        onImg2ImgInpaint: () => run(() => operations.editSource(true)),
        onImg2ImgPlace: () => run(operations.placeSource),
        onImg2ImgRemove: () => run(operations.removeSource),
        onAddVibeFiles: () => run(() => operations.files(GenDropTarget.vibe)),
        onAddVibeFromLibrary: () =>
            run(() => operations.library(GenDropTarget.vibe)),
        onAddRecentVibe: (id) => run(() => operations.recentVibe(id)),
        onVibeChanged: (value) => run(
          () => references.vibe(
            value,
            previous: currentData().refs.vibes?.list
                .where((item) => item.id == value.id)
                .firstOrNull,
          ),
        ),
        onEncodeVibe: (id) => run(() => operations.encodeVibe(id)),
        onRemoveVibe: (id) => run(() => references.removeVibe(id)),
        onClearVibes: () => run(references.clearVibes),
        onSaveVibes: () => run(operations.saveVibes),
        onNormalizeChanged: (value) => run(() => references.normalize(value)),
        onAddPreciseFiles: () =>
            run(() => operations.files(GenDropTarget.precise)),
        onAddPreciseFromLibrary: () =>
            run(() => operations.library(GenDropTarget.precise)),
        onPreciseChanged: (value) => run(
          () => references.precise(
            value,
            previous: currentData().refs.precise?.list
                .where((item) => item.id == value.id)
                .firstOrNull,
          ),
        ),
        onRemovePrecise: (id) => run(() => references.removePrecise(id)),
        onClearPrecise: () => run(references.clearPrecise),
        onSavePrecise: () => run(operations.savePrecise),
        onSizeChanged: (width, height) =>
            run(() => settings.size(width, height)),
        onCountChanged: (value) => run(() => settings.count(value)),
        onRepeatChanged: (value) => run(() => settings.repeat(value)),
        onParamChanged: (param, value) =>
            run(() => settings.param(param, value)),
        onSeedChanged: (value) => run(() => settings.seed(value)),
        onSeedPinned: (value) => run(
          () => settings.pinSeed(value, lastSeed: currentData().params.seed),
        ),
        onSamplerChanged: (value) => run(() => settings.sampler(value)),
        onNoiseChanged: (value) => run(() => settings.noise(value)),
        onVarietyChanged: (value) => run(() => settings.variety(value)),
        onDecrispChanged: (value) => run(() => settings.decrisp(value)),
        onSmeaChanged: (value) => run(() => settings.smea(value)),
        onGenerate: () => run(operations.generate),
        onStop: () {
          ref.read(imageGenerationNotifierProvider.notifier).cancel();
          if (ref.read(kritaBridgeNotifierProvider).isBridgeGenerating) {
            ref
                .read(kritaBridgeNotifierProvider.notifier)
                .cancelActiveRequest();
          }
        },
        onEnhance: (id) => run(() => operations.enhance(id)),
        onVariations: (id) => run(() => operations.variations(id)),
        onUpscale: (id) => run(() => operations.upscale(id)),
        onUpscaleSettings: () {
          final id = currentData().canvas.info?.tileId;
          if (id != null) {
            run(
              () => ToolsGenerationSheetWiring.open(
                ref,
                operations,
                id,
                GenToolSheet.upscale,
              ),
            );
          }
        },
        onUpscaleOption: (value) => run(() => operations.upscaleOption(value)),
        onSetInit: (id) => run(() => operations.setInit(id)),
        onEditImage: (id) => run(() => operations.edit(id, false)),
        onInpaint: (id) => run(() => operations.edit(id, true)),
        onSendToTools: (id) => run(() => operations.tools(id)),
        onUseSeed: (id) => run(() => operations.useSeed(id)),
        onCopySeed: (id) => run(() => operations.copySeed(id)),
        onPin: (id, value) => run(() => history.pin(id, value)),
        onCopyImage: (id) => run(() => operations.copyImage(id)),
        onSaveImage: (id) => run(() => operations.saveImages([id])),
        onOpenViewer: (id) => run(() => operations.viewer(id)),
        onFocusTile: (id) => focus(() => history.focusTile(id)),
        onBackdropChanged: (value) => run(() => operations.backdrop(value)),
        onZoomToFillChanged: operations.zoomToFill,
        onRetry: () => run(operations.retry),
        onDismissError: () =>
            ref.read(imageGenerationNotifierProvider.notifier).clearError(),
        onFocusBatch: (id) => focus(() => history.focusBatch(id)),
        onAutoSaveChanged: (value) => run(
          () => ref
              .read(imageSaveSettingsNotifierProvider.notifier)
              .setAutoSave(value),
        ),
        onFocusPins: () => focus(history.focusPins),
        onSaveImages: (ids) => run(() => operations.saveImages(ids)),
        onPackImages: (ids) => run(() => operations.packImages(ids)),
        onDeleteImages: (ids) => run(() => history.delete(ids)),
        onClearHistory: history.clear,
        onFavorite: (id, value) => run(() => operations.favorite(id, value)),
        onSendTo: (ids, target) => run(() => operations.sendTo([ids], target)),
        onReveal: (id) => run(() => operations.reveal(id)),
      ),
    );
    return GenerationCanvasMenuWiring(child: page);
  }
}
