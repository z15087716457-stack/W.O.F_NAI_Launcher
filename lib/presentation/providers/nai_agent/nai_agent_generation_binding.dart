import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/block_tools.dart';
import '../../../core/utils/alias_parser.dart';
import '../../../core/nai_agent/generation_tools.dart';
import '../../../core/nai_agent/generation_snapshot.dart';
import '../../../core/krita/bridge_draft_guard.dart';
import '../../../core/network/nai_api_endpoint_service.dart';
import '../../../data/models/image/image_params.dart';
import '../../../data/services/nai_agent/agent_snapshot_files.dart';
import '../auth_provider.dart';
import '../image_generation_provider.dart';
import '../generation/image_workflow_controller.dart';
import '../generation/image_workflow_snapshot.dart';
import '../prompt_block_library_provider.dart';
import '../krita/bridge_draft_snapshot.dart';
import 'nai_agent_generation_approvals.dart';
import '../style_explore/explore_run_runner.dart';
import '../generation/local_upscale_provider.dart';
import '../generation/cloud_upscale_provider.dart';
import '../director_tools_notifier.dart';
import '../krita/krita_bridge_notifier.dart';

/// Same native busy boundary for model calls and idle prompt-set buttons.
bool naiAgentGenerationBusy(Ref ref) =>
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

NaiAgentGenerationTools bindNaiAgentGeneration(
  Ref ref,
  Directory workspace,
  NaiAgentConversationOwner owner,
  bool Function() busy,
  bool Function() alive, {
  Future<Map<String, dynamic>> Function(
    Map<String, dynamic>,
    List<GeneratedImage>,
  )?
  completed,
}) {
  NaiAgentGenerationInput read(Map<String, dynamic> params) {
    final current = ref.read(generationParamsNotifierProvider);
    final requests = params['requests'] as int? ?? current.nSamples;
    final size =
        params['images_per_request'] as int? ??
        ref.read(imagesPerRequestProvider) ??
        1;
    final raw = current.copyWith(nSamples: requests);
    validateBridgePatch({
      'model': raw.model,
      'width': raw.width,
      'height': raw.height,
      'steps': raw.steps,
      'cfg_scale': raw.scale,
      'sampler': raw.sampler,
      'seed': raw.seed,
    });
    if (raw.action != ImageGenerationAction.generate &&
            raw.sourceImage == null ||
        raw.action == ImageGenerationAction.infill && raw.maskImage == null) {
      throw const NaiAgentToolError(
        'source_missing',
        'This image action requires a source image and, for infill, a mask',
      );
    }
    final effective = ref
        .read(imageGenerationNotifierProvider.notifier)
        .preparePromptParams(raw);
    final billing = readBridgeBilling(
      ref,
      effective,
      batchCount: requests,
      batchSize: size,
    );
    final auth = ref.read(authNotifierProvider);
    final workflow = ref.exists(imageWorkflowControllerProvider)
        ? ref.read(imageWorkflowControllerProvider)
        : null;
    final local = workflow?.isEnhance == true && workflow!.enhance.localUpscale
        ? workflow.upscale
        : null;
    final cooldown = ref.read(generationCooldownProvider);
    final cooling = cooldown.availableAt?.isAfter(DateTime.now()) == true;
    String? blocked;
    if (!auth.isAuthenticated || auth.accountId == null) {
      blocked = 'account_unavailable';
    } else if (billing['balance_anlas'] == null) {
      blocked = 'balance_unavailable';
    } else if ((billing['estimated_anlas'] as int) < 0) {
      blocked = 'invalid_price';
    } else if ((billing['balance_anlas'] as int) <
        (billing['estimated_anlas'] as int)) {
      blocked = 'insufficient_balance';
    } else if (busy()) {
      blocked = 'busy';
    } else if (cooling) {
      blocked = 'cooldown';
    }
    final draft = readBridgeDraft(ref);
    final aliasNames = <String>{
      for (final text in [
        raw.prompt,
        raw.negativePrompt,
        for (final character in draft.fields['characters'] as List) ...[
          character['prompt'] as String,
          character['uc'] as String,
        ],
      ])
        for (final alias in AliasParser.parse(text))
          for (final name in alias.entryNames) name.toLowerCase(),
    };
    final definitions = ref
        .read(promptBlockLibraryNotifierProvider)
        .valueOrNull
        ?.blocks;
    return NaiAgentGenerationInput(
      raw: raw,
      effective: effective,
      draftVersion: draft.acknowledgementVersion,
      promptContextVersion: jsonEncode([
        for (final block in definitions ?? [])
          if (aliasNames.contains(block.title.toLowerCase()))
            naiAgentBlockVersion(block),
      ]),
      batchSize: size,
      billing: billing,
      accountId: auth.accountId,
      accountName: auth.displayName ?? '',
      endpoint: jsonEncode(
        ref.read(naiApiEndpointServiceProvider).current.toJson(),
      ),
      workflowGuard: local,
      localEnhance: local == null
          ? null
          : {'model': local.localModel, 'scale': local.localScale},
      blockedReason: blocked,
    );
  }

  return NaiAgentGenerationTools(
    readInput: read,
    isAlive: alive,
    approve: (quote, token, check) => ref
        .read(naiAgentGenerationApprovalsProvider)
        .request(owner, quote, token, check),
    backup: (_) async {
      final controller = ref.read(imageWorkflowControllerProvider.notifier);
      final image = controller.snapshotDraftParams;
      final saved = await AgentSnapshotFiles(workspace)
          .save('Before Agent generation', {
            'kind': 'generation_before_run',
            'draft': readBridgeDraft(ref, imageOverride: image).toJson(),
            'image': encodeAgentImageParams(image),
            'image_workflow': encodeImageWorkflowConfiguration(
              controller.snapshotDraftWorkflow,
              image,
            ),
          }, backup: true);
      return saved['path'] as String;
    },
    start: (input) =>
        startNaiAgentNativeGeneration(ref, input, alive, completed: completed),
  );
}

/// All Agent generation modes share native admission, run identity, account
/// cancellation and result collection; source actions only supply the launch.
NaiAgentGenerationRun? startNaiAgentNativeGeneration(
  Ref ref,
  NaiAgentGenerationInput input,
  bool Function() alive, {
  Future<void> Function(ImageGenerationNotifier, GenerationBatchCallback)?
  launch,
  Future<Map<String, dynamic>> Function(
    Map<String, dynamic>,
    List<GeneratedImage>,
  )?
  completed,
}) {
  final generation = ref.read(imageGenerationNotifierProvider.notifier);
  final before = ref.read(imageGenerationNotifierProvider).generationRunId;
  final collected = <String, GeneratedImage>{};
  Future<void> onBatch(GenerationBatchEvent event) async {
    for (final image in event.images) {
      if (image.canSave && !image.isVariationOriginal) {
        collected[image.id] = image;
      }
    }
  }

  final future =
      launch?.call(generation, onBatch) ??
      generation.generate(
        input.raw,
        imagesPerRequestOverride: input.batchSize,
        onBatchEvent: onBatch,
      );
  final admitted = ref.read(imageGenerationNotifierProvider);
  if (admitted.generationRunId == before) {
    // Rejected starts must still observe a possible native failure.
    future.catchError((Object _) {});
    return null;
  }
  final nativeId = admitted.generationRunId;
  bool cancel() {
    if (!alive()) return false;
    final state = ref.read(imageGenerationNotifierProvider);
    if (state.generationRunId != nativeId || !state.isGenerating) {
      return false;
    }
    generation.cancel();
    return true;
  }

  String? stopReason;
  final accountGuard = ref.listen(authNotifierProvider, (_, next) {
    if ((!next.isAuthenticated || next.accountId != input.accountId) &&
        cancel()) {
      stopReason = 'account_changed';
    }
  });
  List<Map<String, dynamic>> imageResults() => [
    for (final image in collected.values)
      {
        'image_id': image.id,
        'path': image.filePath,
        'width': image.width,
        'height': image.height,
        'seed': image.metadata?.seed,
      },
  ];

  return NaiAgentGenerationRun(
    id: const Uuid().v4(),
    cancel: cancel,
    completion: future.whenComplete(accountGuard.close).then((_) async {
      if (!alive()) {
        return {
          'status': 'interrupted',
          'native_generation_id': nativeId,
          'images': imageResults(),
          'balance_after_anlas': null,
          'balance_source': 'owner_closed',
        };
      }
      final state = ref.read(imageGenerationNotifierProvider);
      for (final image in state.mergedPanelImages) {
        if (image.generationRunId == nativeId &&
            image.canSave &&
            !image.isVariationOriginal) {
          collected[image.id] = image;
        }
      }
      final sameAccount =
          ref.read(authNotifierProvider).accountId == input.accountId;
      final result = <String, dynamic>{
        'status': state.generationRunId == nativeId
            ? state.status.name
            : 'interrupted',
        'native_generation_id': nativeId,
        'error': state.generationRunId == nativeId ? state.errorMessage : null,
        'images': imageResults(),
        if (stopReason != null) 'stop_reason': stopReason,
        'balance_after_anlas': sameAccount
            ? readBridgeBilling(ref, input.effective)['balance_anlas']
            : null,
        'balance_source': sameAccount ? 'cached_account' : 'account_changed',
      };
      return completed == null
          ? result
          : await completed(result, List.unmodifiable(collected.values));
    }),
  );
}
