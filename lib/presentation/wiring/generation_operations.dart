import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/image_save_utils.dart';
import '../../core/utils/file_explorer_utils.dart';
import '../../core/utils/localization_extension.dart';
import '../../core/utils/zip_utils.dart';
import '../../data/models/vibe/vibe_library_entry.dart';
import '../../data/services/image_metadata_service.dart';
import '../utils/metadata_import_coordinator.dart';
import '../../data/models/vibe/vibe_reference.dart';
import '../../data/services/vibe_library_storage_service.dart';
import '../../data/services/vibe_file_storage_service.dart';
import '../../data/services/precise_ref_library_storage_service.dart';
import '../providers/canvas_settings_provider.dart';
import '../providers/character_prompt_provider.dart';
import '../providers/generation/cloud_upscale_provider.dart';
import '../providers/generation/local_upscale_provider.dart';
import '../providers/generation/image_workflow_controller.dart';
import '../providers/generation/image_action_providers.dart';
import '../providers/image_generation_provider.dart';
import '../providers/local_gallery_provider.dart';
import '../providers/vibe_library_provider.dart';
import '../providers/precise_ref_library_provider.dart';
import '../providers/pill_workspace_provider.dart';
import '../widgets/common/undo_snack_bar.dart';
import '../providers/subscription_provider.dart';
import '../screens/generation/handlers/vibe_import_handler.dart';
import '../screens/generation/widgets/canvas/generated_image_actions.dart';
import '../ui/refs/refs_contract.dart';
import 'generation_reference_picker.dart';
import 'generation_reference_identity.dart';
import '../services/image_workflow_launcher.dart';
import '../ui/gen/gen_contract.dart';
import '../utils/asset_protection_guard.dart';
import '../widgets/common/selectable_image_card.dart'
    show imageClipboardWriterProvider;
import '../utils/precise_ref_library_import_helper.dart';
import '../widgets/character/add_to_library_dialog.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/draggable_memory_image.dart';
import '../widgets/common/image_detail/image_detail_data.dart';
import '../widgets/common/themed_confirm_dialog.dart';
import '../widgets/image_editor/image_editor_screen.dart';
import '../widgets/prompt/blocks/prompt_block_palette.dart';
import 'generation_backend.dart';
import 'generation_blocks_dock.dart';
import 'generation_drop_wiring.dart';
import 'generation_history_actions.dart';
import 'generation_reference_imports.dart';
import 'generation_viewer_wiring.dart';
import 'tools_generation_wiring.dart';

class GenerationOperations {
  GenerationOperations(this.ref, this.context, this.alive);
  final WidgetRef ref;
  final BuildContext context;
  final bool Function() alive;
  bool get mounted => alive() && context.mounted;
  GenerationBackend get backend => ref.read(generationBackendProvider);
  GenerationHistoryActions get history =>
      ref.read(generationHistoryActionsProvider);
  ImageWorkflowController get workflow =>
      ref.read(imageWorkflowControllerProvider.notifier);
  void run(Future<void> Function() task) {
    if (!mounted) return;
    unawaited(
      Future<void>.sync(task).catchError((Object error) {
        if (context.mounted && alive()) {
          AppToast.error(context, error.toString());
        }
      }),
    );
  }

  Widget dock(bool negative) => BlocksDockWiring(
    fallbackScope: negative ? PillScopes.negative : PillScopes.main,
  );
  Widget drop(BuildContext context, GenDropTarget target, Widget child) =>
      GenerationDropWiring(target: target, child: child);
  Widget historyDrag(BuildContext context, String id, Widget child) {
    final image = history.image(id);
    return DraggableMemoryImage(
      imageBytes: image.bytes,
      imageId: id,
      sourceFilePath: image.filePath,
      fileName: '${id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.png',
      enabled: image.canSave,
      feedbackPixelWidth: image.width,
      feedbackPixelHeight: image.height,
      child: child,
    );
  }

  Future<void> clearPrompt(GenEditorTarget target, String? id) async {
    if (id != null &&
        ref.read(characterPromptNotifierProvider).findCharacterById(id)?.id !=
            ref
                .read(characterPromptNotifierProvider)
                .characters
                .elementAtOrNull(target.character ?? -1)
                ?.id) {
      throw StateError(context.l10n.bridge_conflict);
    }
    final undo = await backend.clearPrompt(target, alive: () => mounted);
    if (undo == null || !context.mounted || !alive()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      undoSnackBar(
        duration: const Duration(seconds: 2),
        content: Text(context.l10n.common_clear),
        undoLabel: context.l10n.common_undo,
        onUndo: () => run(() => backend.undoPrompt(undo, alive: () => mounted)),
      ),
    );
  }

  Future<void> characterToLibrary(String id) async {
    final character = ref
        .read(characterPromptNotifierProvider)
        .findCharacterById(id);
    if (character == null) throw StateError(context.l10n.bridge_conflict);
    await AddToLibraryDialog.show(
      context,
      name: character.customName,
      content: character.prompt,
    );
  }

  Future<void> openPalette(Rect rect) =>
      PromptBlockPaletteButton.showAt(context, rect);
  Future<bool> confirm(int cost) => AssetProtectionGuard.confirmHighAnlasCost(
    context: context,
    ref: ref,
    cost: cost,
  );
  Future<void> generate() =>
      backend.generate(confirm: confirm, alive: () => mounted);
  Future<void> retry() => backend.retry(confirm: confirm, alive: () => mounted);
  Future<void> files(GenDropTarget target) =>
      ref.read(generationReferenceImportsProvider).files(target, () async {
        final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: target == GenDropTarget.vibe
              ? ['png', 'jpg', 'jpeg', 'webp', 'naiv4vibe', 'naiv3vibe', 'zip']
              : ['png', 'jpg', 'jpeg', 'webp'],
          allowMultiple: target != GenDropTarget.img2img,
          withData: true,
        );
        if (picked == null) return [];
        return [
          for (final file in picked.files)
            GenerationReferenceFile(
              file.name,
              file.bytes ?? await File(file.path!).readAsBytes(),
            ),
        ];
      }, alive: () => mounted);
  Future<List<VibeReference>> hydrateVibe(VibeLibraryEntry entry) async {
    final service = VibeFileStorageService();
    final path = entry.filePath;
    if (entry.isBundle) {
      if (path != null) return service.extractVibesFromBundle(path);
      return [
        for (var i = 0; i < entry.bundledVibeCount; i++)
          VibeReference(
            displayName: entry.bundledVibeNames![i],
            vibeEncoding: entry.bundledVibeEncodings?.elementAtOrNull(i) ?? '',
            thumbnail: entry.bundledVibePreviews?.elementAtOrNull(i),
            strength:
                entry.bundledVibeStrengths?.elementAtOrNull(i) ??
                entry.strength,
            infoExtracted:
                entry.bundledVibeInfoExtracted?.elementAtOrNull(i) ??
                entry.infoExtracted,
            encodingModel:
                entry.bundledVibeEncodingModels?.elementAtOrNull(i) ??
                entry.encodingModel,
            sourceType: VibeSourceType.naiv4vibebundle,
            bundleSource: entry.displayName,
          ),
      ];
    }
    if (entry.vibeEncoding.isNotEmpty || entry.canReencodeFromRawSource) {
      final normalized = entry.copyWith(
        sourceTypeIndex:
            VibeSourceType.values
                .elementAtOrNull(entry.sourceTypeIndex)
                ?.index ??
            VibeSourceType.rawImage.index,
      );
      return [normalized.toVibeReference()];
    }
    if (path == null) throw StateError(context.l10n.vibeParseFailed);
    final value = await service.loadVibeFromFile(path);
    if (value == null) throw StateError(currentL10n.vibeParseFailed);
    return [
      value.copyWith(
        strength: entry.strength,
        infoExtracted: entry.infoExtracted,
      ),
    ];
  }

  Future<void> library(GenDropTarget target) async {
    GenerationReferenceSelection? selected;
    final origins = <String>[];
    bool inUse(String key) {
      if (selected?.replace == true || target == GenDropTarget.img2img) {
        return false;
      }
      final identity = ref.read(generationReferenceIdentityProvider)
        ..sync(ref.read(generationParamsNotifierProvider));
      final ids = target == GenDropTarget.vibe
          ? identity.vibes
          : identity.precise;
      final sources = ref.read(generationLibraryOriginsProvider);
      return ids.any((id) => sources[id] == key);
    }

    var committed = false;
    void applied() {
      committed = true;
      if (target == GenDropTarget.img2img) return;
      final identity = ref.read(generationReferenceIdentityProvider)
        ..sync(ref.read(generationParamsNotifierProvider));
      final ids = target == GenDropTarget.vibe
          ? identity.vibes
          : identity.precise;
      ref.read(generationLibraryOriginsProvider.notifier).state = {
        ...ref.read(generationLibraryOriginsProvider),
        for (var i = 0; i < origins.length; i++)
          ids[ids.length - origins.length + i]: origins[i],
      };
    }

    if (target == GenDropTarget.vibe) {
      await ref
          .read(generationReferenceImportsProvider)
          .vibes(
            () async {
              selected = await GenerationReferencePicker.show(
                context,
                kind: RefsKind.vibe,
              );
              if (selected == null || !mounted) return [];
              final storage = ref.read(vibeLibraryStorageServiceProvider);
              final result = <VibeReference>[];
              for (final key in selected!.keys.toSet()) {
                if (inUse(key)) continue;
                final entry = await storage.getEntry(key);
                if (entry == null) {
                  throw StateError(currentL10n.bridge_conflict);
                }
                final values = await hydrateVibe(entry);
                origins.addAll(List.filled(values.length, key));
                result.addAll(values);
              }
              return result;
            },
            appendOnly: true,
            alive: () => mounted,
            replaceRequested: () => selected?.replace == true,
            onApplied: applied,
          );
    } else {
      await ref
          .read(generationReferenceImportsProvider)
          .files(
            target,
            () async {
              selected = await GenerationReferencePicker.show(
                context,
                kind: RefsKind.precise,
                single: target == GenDropTarget.img2img,
              );
              if (selected == null || !mounted) return [];
              final storage = ref.read(preciseRefLibraryStorageServiceProvider);
              final files = <GenerationReferenceFile>[];
              final entries = await storage.getAllEntries();
              for (final key in selected!.keys.toSet()) {
                if (inUse(key)) continue;
                final entry = entries
                    .where((entry) => entry.id == key)
                    .firstOrNull;
                final bytes = await storage.readImageBytes(key);
                if (entry == null || bytes == null) {
                  throw StateError(currentL10n.bridge_conflict);
                }
                files.add(
                  GenerationReferenceFile(
                    entry.name,
                    bytes,
                    type: entry.type,
                    strength: entry.strength,
                    fidelity: entry.fidelity,
                  ),
                );
                origins.add(key);
              }
              return files;
            },
            alive: () => mounted,
            replaceRequested: () => selected?.replace == true,
            onApplied: applied,
          );
    }
    if (committed && mounted) {
      for (final key in origins.toSet()) {
        if (!mounted) return;
        if (target == GenDropTarget.vibe) {
          await ref.read(vibeLibraryNotifierProvider.notifier).recordUsage(key);
        } else {
          await ref
              .read(preciseRefLibraryNotifierProvider.notifier)
              .recordUsage(key);
        }
      }
    }
  }

  Future<void> recentVibe(String id) =>
      ref.read(generationReferenceImportsProvider).vibes(() async {
        final entry = await ref
            .read(vibeLibraryStorageServiceProvider)
            .getEntry(id);
        if (entry == null) throw StateError(currentL10n.bridge_conflict);
        return hydrateVibe(entry);
      }, alive: () => mounted);
  Future<void> encodeVibe(String id) => ref
      .read(generationReferenceImportsProvider)
      .encode(
        id,
        confirm: (cost) => ThemedConfirmDialog.show(
          context: context,
          title: context.l10n.vibe_import_confirmCost,
          content:
              '${context.l10n.gen_encodeTip(cost)}\n${context.l10n.gen_anlasTip(ref.read(anlasBalanceProvider)?.toString() ?? '—')}',
          confirmText: context.l10n.common_continue,
          cancelText: context.l10n.common_cancel,
        ),
        alive: () => mounted,
      );
  Future<void> saveVibes() => VibeImportHandler(
    context: context,
    ref: ref,
  ).saveToLibrary(ref.read(generationParamsNotifierProvider).vibeReferencesV4);
  Future<void> savePrecise() async {
    for (final value
        in ref.read(generationParamsNotifierProvider).preciseReferences) {
      if (!context.mounted || !alive()) return;
      await saveBytesToPreciseRefLibrary(
        ref,
        context,
        value.image,
        type: value.type,
      );
    }
  }

  Future<void> removeSource() =>
      backend.mutate(() => workflow.clearSourceImage(), alive: () => mounted);
  Future<void> sketch() async {
    final write = backend.captureDraft(alive: () => mounted);
    final result = await ImageEditorScreen.show(
      context,
      mode: ImageEditorMode.edit,
    );
    if (result?.modifiedImage != null && mounted) {
      await write(
        () =>
            ImageWorkflowLauncher.openImageToImage(ref, result!.modifiedImage!),
      );
    }
  }

  Future<void> editSource(bool inpaint) async {
    final bytes = ref.read(generationParamsNotifierProvider).sourceImage;
    if (bytes != null) await _editBytes(bytes, inpaint);
  }

  Future<void> _editBytes(Uint8List bytes, bool inpaint) async {
    await closeToolSheet();
    if (!context.mounted || !alive()) return;
    final write = backend.captureDraft(alive: () => mounted);
    await ImageWorkflowLauncher.openEditor(
      context,
      ref,
      bytes,
      mode: inpaint ? ImageEditorMode.inpaint : ImageEditorMode.edit,
      writeDraft: write,
    );
  }

  Future<void> placeSource() async {
    final params = ref.read(generationParamsNotifierProvider);
    final bytes = params.sourceImage;
    if (bytes == null) return;
    final id = await ref
        .read(imageGenerationNotifierProvider.notifier)
        .registerExternalImage(
          bytes,
          params: params,
          addToDisplay: true,
          canApply: () => mounted,
        );
    if (id != null && mounted) history.focusTile(id);
  }

  GeneratedImage input(String id) {
    final image = history.image(id);
    if (!image.canUseAsGenerationInput || backend.busy) {
      throw StateError(context.l10n.bridge_conflict);
    }
    return image;
  }

  Future<void> setInit(String id) => backend.mutate(
    () => ImageWorkflowLauncher.openImageToImage(ref, input(id).bytes),
    alive: () => mounted,
  );
  Future<void> enhance(String id) =>
      ToolsGenerationSheetWiring.open(ref, this, id, GenToolSheet.enhance);
  Future<void> edit(String id, bool inpaint) =>
      _editBytes(input(id).bytes, inpaint);
  Future<void> tools(String id) async {
    await closeToolSheet();
    if (!context.mounted || !alive()) return;
    final image = input(id);
    final write = backend.captureDraft(alive: () => mounted);
    await ImageWorkflowLauncher.openDirectorTools(
      context,
      ref,
      image.bytes,
      writeDraft: write,
    );
  }

  Future<void> variations(String id) async {
    final image = input(id);
    final write = backend.captureDraft(alive: () => mounted);
    final cost = ref.read(imageVariationCostProvider(image));
    if (!await confirm(cost ?? 0) || !context.mounted || !alive()) return;
    await write(() {});
    if (!context.mounted || !alive()) return;
    await ImageWorkflowLauncher.generateVariations(
      context,
      ref,
      image.bytes,
      sourceImage: image,
      beforeSubmit: () => write(() {}),
    );
  }

  Future<void> closeToolSheet() async {
    final session = ref.read(toolsSheetProvider);
    if (session != null) {
      await ToolsGenerationSheetWiring.close(ref, this, session);
    }
  }

  Future<void> upscale(String id, {void Function()? onStarted}) async {
    if (ref.read(localUpscaleTaskProvider).running) {
      ref.read(localUpscaleTaskProvider.notifier).cancel();
      return;
    }
    if (ref.read(cloudUpscaleTaskProvider).running) {
      ref.read(cloudUpscaleTaskProvider.notifier).cancel();
      return;
    }
    final image = input(id);
    final write = backend.captureDraft(alive: () => mounted);
    final mode = ref.read(imageWorkflowControllerProvider).upscale.backend;
    if (mode == UpscaleBackend.novelai &&
        !await confirm(ref.read(imageUpscaleCostProvider(image)) ?? 0)) {
      return;
    }
    late Future<void> task;
    await write(() {
      task = mode == UpscaleBackend.novelai
          ? ref.read(cloudUpscaleTaskProvider.notifier).start(image: image)
          : ref.read(localUpscaleTaskProvider.notifier).start(image: image);
      onStarted?.call();
    });
    await task;
  }

  Future<void> upscaleOption(String value) => backend.mutate(() {
    final controller = workflow;
    if (value == 'novelai') {
      controller.updateUpscaleBackend(UpscaleBackend.novelai);
    } else if (value == 'comfyui') {
      controller.updateUpscaleBackend(UpscaleBackend.comfyui);
    } else {
      controller.updateUpscaleBackend(UpscaleBackend.local);
      controller.updateLocalUpscaleModel(
        value.startsWith('local:') ? value.substring(6) : value,
      );
    }
  }, alive: () => mounted);
  Future<void> copySeed(String id) async {
    final image = history.image(id);
    final seed = await ImageSaveUtils.resolveSeed(
      metadata: image.metadata,
      bytes: image.bytes,
    );
    if (seed != null) await Clipboard.setData(ClipboardData(text: '$seed'));
  }

  Future<void> useSeed(String id) async {
    final image = history.image(id);
    final write = backend.captureDraft(alive: () => mounted);
    final seed = await ImageSaveUtils.resolveSeed(
      metadata: image.metadata,
      bytes: image.bytes,
    );
    if (seed != null) {
      await write(
        () => ref
            .read(generationParamsNotifierProvider.notifier)
            .updateSeed(seed),
      );
    }
  }

  Future<void> copyImage(String id) async {
    final image = history.image(id);
    if (!image.canSave) return;
    await ref.read(imageClipboardWriterProvider)(image.bytes);
  }

  Future<void> saveImages(List<String> ids) async {
    for (final id in ids.toSet()) {
      final image = history.image(id);
      if (!image.canSave || !context.mounted || !alive()) continue;
      await GeneratedImageActions(ref).saveImage(
        context,
        GeneratedImageDetailData(
          imageBytes: image.bytes,
          metadata: image.metadata,
          id: id,
        ),
      );
    }
  }

  Future<void> favorite(String id, bool value) async {
    await saveImages([id]);
    if (!mounted) return;
    final path = history.image(id).filePath;
    if (path == null) return;
    final gallery = ref.read(localGalleryNotifierProvider.notifier);
    if (await gallery.isFavorite(path) != value) {
      await gallery.toggleFavorite(path);
    }
  }

  Future<void> reveal(String id) async {
    final path = history.image(id).filePath;
    if (path == null) {
      AppToast.info(context, context.l10n.imageViewer_notSaved);
      return;
    }
    await FileExplorerUtils.revealFile(path);
  }

  Future<void> packImages(List<String> ids) async {
    await saveImages(ids);
    if (!mounted) return;
    final paths = [
      for (final id in ids.toSet())
        if (history.image(id).filePath != null) history.image(id).filePath!,
    ];
    if (paths.isEmpty) return;
    final path = await FilePicker.platform.saveFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      fileName: 'images.zip',
    );
    if (path != null) {
      final safe = await AssetProtectionGuard.resolveNonOverwritingPath(path);
      if (!await ZipUtils.createZipFromImages(paths, safe)) {
        throw StateError(currentL10n.vibeParseFailed);
      }
    }
  }

  Future<void> sendTo(List<String> ids, GenSendTarget target) async {
    final selected = ids.toSet().map(input).toList();
    if (selected.isEmpty) return;
    final dropTarget = switch (target) {
      GenSendTarget.img2img => GenDropTarget.img2img,
      GenSendTarget.vibe => GenDropTarget.vibe,
      GenSendTarget.precise => GenDropTarget.precise,
    };
    await ref
        .read(generationReferenceImportsProvider)
        .files(
          dropTarget,
          () async => [
            for (final image in selected)
              GenerationReferenceFile('${image.id}.png', image.bytes),
          ],
          alive: () => mounted,
        );
  }

  Future<void> reuse(String id, {bool Function()? selected}) async {
    final image = history.image(id);
    bool valid() =>
        mounted &&
        selected?.call() != false &&
        history.images.any((current) => identical(current, image));
    final write = backend.captureDraft(alive: valid);
    final metadata =
        image.metadata ??
        await ImageMetadataService().getMetadataFromBytes(image.bytes);
    if (metadata?.hasData != true || !valid()) return;
    late Future<int> applied;
    await write(() {
      applied = MetadataImportCoordinator.applyOfficialFullReplacement(
        read: ref.read,
        metadata: metadata!,
      );
    });
    await applied;
  }

  Future<void> viewer(String id) =>
      GenerationViewerWiring.open(context, ref, history.images, id);
  Future<void> backdrop(String value) async =>
      ref.read(canvasImageBackgroundNotifierProvider.notifier).set(value);
  void zoomToFill(bool value) =>
      ref.read(canvasZoomToFillNotifierProvider.notifier).set(value);
}
