import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/nai_agent/studio_tools.dart';
import '../../../core/nai_agent/vision_access.dart';
import '../../../core/nai_agent/generation_tools.dart';
import '../../../data/models/image/image_params.dart';
import '../image_generation_provider.dart';
import '../generation/preview_selection_provider.dart';
import '../krita/bridge_draft_snapshot.dart';
import '../krita/bridge_draft_writer.dart';
import '../krita/krita_bridge_notifier.dart';
import '../../router/app_router.dart';
import 'nai_agent_knowledge_tools.dart';
import 'nai_agent_snapshot_binding.dart';
import 'nai_agent_block_binding.dart';
import 'nai_agent_generation_binding.dart';
import 'nai_agent_source_generation_binding.dart';
import 'nai_agent_image_tool_binding.dart';
import 'nai_agent_gallery_binding.dart';
import 'nai_agent_reference_binding.dart';
import 'nai_agent_reference_library_binding.dart';
import 'nai_agent_settings_binding.dart';
import 'nai_agent_wiki_images.dart';
import 'nai_agent_explore_binding.dart';
import '../style_explore/explore_run_runner.dart';
import '../generation/image_workflow_controller.dart';
import '../generation/local_upscale_provider.dart';
import '../generation/cloud_upscale_provider.dart';
import '../director_tools_notifier.dart';
import '../prompt_block_library_provider.dart';

/// Explicit dependencies supplied by the workspace/session owner (stage C/D).
typedef NaiAgentStudioFactory =
    NaiAgentStudioTools Function(
      Directory workspace,
      Directory data,
      bool allowsImages, {
      NaiAgentVisionAccess visionAccess,
      NaiAgentConversationOwner? owner,
    });

final naiAgentStudioFactoryProvider = Provider<NaiAgentStudioFactory>((ref) {
  var alive = true;
  ref.onDispose(() => alive = false);
  return (
    workspace,
    data,
    allowsImages, {
    visionAccess = const NaiAgentVisionAccess(),
    owner,
  }) {
    NaiAgentImage? image(String id) {
      if (id.startsWith('draft:')) {
        final params = ref.read(generationParamsNotifierProvider);
        final match = RegExp(r'^draft:(vibe|precise):(\d+)$').firstMatch(id);
        final index = match == null ? null : int.tryParse(match[2]!);
        final bytes = switch (id) {
          'draft:source' => params.sourceImage,
          'draft:mask' => params.maskImage,
          _
              when match?[1] == 'vibe' &&
                  index != null &&
                  index < params.vibeReferencesV4.length =>
            params.vibeReferencesV4[index].rawImageData ??
                params.vibeReferencesV4[index].thumbnail,
          _
              when match?[1] == 'precise' &&
                  index != null &&
                  index < params.preciseReferences.length =>
            params.preciseReferences[index].image,
          _ => null,
        };
        return bytes == null ? null : NaiAgentImage(id: id, bytes: bytes);
      }
      final state = ref.read(imageGenerationNotifierProvider);
      final images = [...state.mergedPanelImages, ...state.displayImages];
      final actualId = id == 'selected'
          ? ref.read(generationPreviewSelectionProvider)
          : id;
      final selected = images
          .where((image) => image.id == actualId)
          .firstOrNull;
      return selected == null
          ? null
          : NaiAgentImage(
              id: selected.id,
              bytes: selected.bytes,
              metadata: selected.metadata?.toJson(),
            );
    }

    bool busy() =>
        ref.read(imageGenerationNotifierProvider).isGenerating ||
        (ref.exists(exploreRunRunnerProvider) &&
            ref.read(exploreRunRunnerProvider).isRunning) ||
        (ref.exists(imageWorkflowControllerProvider) &&
            ref.read(imageWorkflowControllerProvider).isToolRunning) ||
        (ref.exists(localUpscaleTaskProvider) &&
            ref.read(localUpscaleTaskProvider).running) ||
        (ref.exists(cloudUpscaleTaskProvider) &&
            ref.read(cloudUpscaleTaskProvider).running) ||
        (ref.exists(directorToolsNotifierProvider) &&
            ref.read(directorToolsNotifierProvider).isRunning) ||
        (ref.exists(kritaBridgeNotifierProvider) &&
            ref.read(kritaBridgeNotifierProvider).isBridgeGenerating);
    final snapshots = bindNaiAgentSnapshots(ref, workspace, busy, () => alive);
    final blocks = bindNaiAgentBlocks(ref, workspace, busy, () => alive);
    final settings = bindNaiAgentSettings(ref, workspace, () => alive);
    final wikiImages = NaiAgentWikiImages(ref, () => alive);
    final exploration = NaiAgentExploreBinding(
      ref,
      workspace,
      busy,
      () => alive,
      owner: owner,
    );
    final gallery = NaiAgentGalleryBinding(
      ref,
      () => alive,
      workspace: workspace,
      isBusy: busy,
      owner: owner,
    );
    late final NaiAgentStudioTools studio;
    final references = NaiAgentReferenceBinding(
      ref,
      workspace,
      (params, token) => studio.loadImage(params, token),
      busy,
      () => alive,
    );
    final referenceLibrary = NaiAgentReferenceLibraryBinding(
      ref,
      workspace,
      references,
      (params, token) => studio.loadImage(params, token),
      busy,
      () => alive,
    );
    final generation = owner == null
        ? null
        : bindNaiAgentGeneration(ref, workspace, owner, busy, () => alive);
    final imageTools = NaiAgentImageToolBinding(
      ref,
      workspace,
      (params, token) => studio.loadImage(params, token),
      busy,
      () => alive,
      owner: owner,
    );
    final sourceGeneration = owner == null
        ? null
        : NaiAgentSourceGenerationBinding(
            ref,
            workspace,
            owner,
            (params, token) => studio.loadImage(params, token),
            busy,
            () => alive,
          );
    studio = NaiAgentStudioTools(
      workspaceDirectory: workspace,
      allowsImages: allowsImages,
      visionAccess: visionAccess,
      isAlive: () => alive,
      domainTools: {
        'settings_read': settings.read,
        'settings_update': settings.update,
        'explore_manage': exploration.execute,
        'image_tool': imageTools.execute,
        if (sourceGeneration != null)
          'image_generate': sourceGeneration.execute,
        'gallery_query': gallery.query,
        'gallery_manage': gallery.manage,
        'reference_manage': references.execute,
        'reference_library': referenceLibrary.execute,
        if (generation != null) ...{
          'generation_prepare': (params, token) async {
            await ref.read(promptBlockLibraryNotifierProvider.future);
            return generation.prepare(params, token);
          },
          'generation_run': generation.run,
          'generation_cancel': generation.cancel,
        },
        'block_query': blocks.query,
        'block_manage': blocks.manage,
        'snapshot': (params, cancellation) async {
          if (params['action'] == 'save' || params['action'] == 'load') {
            await ref.read(promptBlockLibraryNotifierProvider.future);
            cancellation.check();
          }
          return snapshots.execute(params, cancellation);
        },
        for (final entry in naiAgentKnowledgeTools(
          ref,
          images: wikiImages,
        ).entries)
          entry.key: (params, cancellation) =>
              entry.value(entry.key, params, cancellation),
      },
      readDraft: () => readBridgeDraft(ref),
      readSummary: () {
        final state = ref.read(imageGenerationNotifierProvider);
        final imageParams = ref.read(generationParamsNotifierProvider);
        final selected = image('selected');
        final draft = readBridgeDraft(ref);
        return {
          'page': ref.exists(appRouterProvider)
              ? ref
                    .read(appRouterProvider)
                    .routeInformationProvider
                    .value
                    .uri
                    .path
              : null,
          'generation': {
            'active': state.isGenerating,
            'status': state.status.name,
            'native_generation_id': state.generationRunId,
            'owned_run_id': generation?.activeId,
            'owned_source_run_id': sourceGeneration?.activeId,
            'progress': state.progress,
            'current_image': state.currentImage,
            'total_images': state.totalImages,
          },
          'selection_scope': 'generation_canvas',
          'selected_image': selected == null ? null : {'image_id': selected.id},
          'draft_summary': {
            for (final field in [
              'model',
              'width',
              'height',
              'steps',
              'sampler',
            ])
              field: draft.fields[field],
            'prompt_length': (draft.fields['prompt'] as String).length,
            'negative_prompt_length':
                (draft.fields['negative_prompt'] as String).length,
            'character_count': (draft.fields['characters'] as List).length,
          },
          'model_constraints': imageParams.modelSpec.requestConstraints,
        };
      },
      isGenerating: busy,
      backupDraft: (draft) => backupBridgeDraft(data, draft),
      writeDraft: ref.read(bridgeDraftWriterProvider),
      readImage: image,
      loadImageById: (id, token) => id.startsWith('wiki:')
          ? wikiImages.load(id, token)
          : id.startsWith('explore:')
          ? exploration.loadImage(id, token)
          : id.startsWith('reference:')
          ? referenceLibrary.loadLibraryImage(id, token)
          : gallery.loadImage(id, token),
    );
    return studio;
  };
});
