import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/krita/bridge_draft_guard.dart';
import '../../../core/services/anlas_calculator.dart';
import '../../../core/utils/pill_document_editor.dart';
import '../../../core/utils/max_enhance_utils.dart';
import '../../../data/models/image/image_params.dart';
import '../../../data/models/prompt_block/pill_document.dart';
import '../../../data/models/user/user_subscription.dart';
import '../auth_provider.dart';
import '../character_prompt_provider.dart';
import '../image_generation_provider.dart';
import '../generation/image_workflow_controller.dart';
import '../pill_workspace_provider.dart';
import '../subscription_provider.dart';
import '../quality_preset_provider.dart';
import '../uc_preset_provider.dart';
import '../prompt_block_library_provider.dart';
import '../generation/image_workflow_snapshot.dart';

final _bridgeDraftFingerprintProvider = Provider<String>((ref) {
  ref.watch(pillWorkspaceRevisionProvider);
  return readBridgeDraft(
    ref,
    reactive: true,
    includeEpoch: false,
  ).acknowledgementVersion;
});

// A content edit invalidates an acknowledgement even when it is later undone.
// Keep the counter in this container, independently of header widget lifetime.
final _bridgeDraftEpochProvider = NotifierProvider<_BridgeDraftEpoch, int>(
  _BridgeDraftEpoch.new,
);

class _BridgeDraftEpoch extends Notifier<int> {
  @override
  int build() {
    ref.listen(_bridgeDraftFingerprintProvider, (previous, next) {
      if (previous != null && previous != next) state++;
    });
    return 0;
  }
}

final bridgeDraftVersionProvider = Provider<String>((ref) {
  ref.watch(_bridgeDraftFingerprintProvider);
  ref.watch(_bridgeDraftEpochProvider);
  return readBridgeDraft(ref).acknowledgementVersion;
});

BridgeDraftSnapshot readBridgeDraft(
  Ref ref, {
  bool reactive = false,
  bool includeEpoch = true,
  ImageParams? imageOverride,
}) {
  T read<T>(ProviderListenable<T> provider) =>
      reactive ? ref.watch(provider) : ref.read(provider);
  final p =
      imageOverride ?? read<ImageParams>(generationParamsNotifierProvider);
  ImageWorkflowState? workflow;
  ImageParams workflowImage = p;
  if (ref.exists(imageWorkflowControllerProvider)) {
    read(imageWorkflowControllerProvider);
    final controller = ref.read(imageWorkflowControllerProvider.notifier);
    workflow = controller.snapshotDraftWorkflow;
    workflowImage = imageOverride ?? controller.snapshotDraftParams;
  }
  // An unopened lane has no document yet. Reads must not initialize or rewrite it.
  PillWorkspaceState lane(String scope, String fallback) {
    final provider = pillWorkspaceProvider(scope);
    if (ref.exists(provider)) return read(provider);
    final document =
        ref.read(pillWorkspaceStorageProvider).tryLoadSync(scope) ??
        PillDocument(text: fallback, instances: const {});
    final library = document.instances.isEmpty
        ? null
        : read(promptBlockLibraryNotifierProvider).valueOrNull;
    return PillWorkspaceState(
      document: document,
      projection: PillDocumentEditor.project(document, (instance) {
        if (instance.translation case final translation?) {
          return translation.source;
        }
        if (instance.settings.hasRoll) return instance.currentRoll;
        final block = library?.blockById(instance.blockId);
        return instance.useNegativeContent
            ? block?.negativeContent
            : block?.content;
      }),
    );
  }

  final main = lane(PillScopes.main, p.prompt);
  final negative = lane(PillScopes.negative, p.negativePrompt);
  final config = read(characterPromptNotifierProvider);
  final quality = read(qualityPresetNotifierProvider);
  final uc = read(ucPresetNotifierProvider);
  final library = quality.customEntryId != null || uc.customEntryId != null
      ? read(promptBlockLibraryNotifierProvider).valueOrNull
      : null;
  Map<String, dynamic>? selectedPreset(String? id) {
    if (id == null) return null;
    final block = library?.blockById(id);
    return {
      'id': id,
      'content': block?.content,
      'negative_content': block?.negativeContent,
    };
  }

  final positives = {
    for (final c in config.characters)
      c.id: lane(PillScopes.charPos(c.id), c.prompt),
  };
  final negatives = {
    for (final c in config.characters)
      c.id: lane(PillScopes.charNeg(c.id), c.negativePrompt),
  };
  return BridgeDraftSnapshot(
    acknowledgementContext: [
      // Includes reference images and other read-only generation parameters.
      // Structural Freezed hash avoids serializing image bytes on every edit.
      p.copyWith(advancedOptionsExpanded: false).hashCode,
      read(generationImg2ImgEnabledProvider),
      // Local upscaler settings can change without changing ImageParams. UI
      // expansion and active jobs are excluded from this content version.
      jsonEncode(encodeImageWorkflowConfiguration(workflow, workflowImage)),
      read(autoFormatPromptSettingsProvider),
      read(sdSyntaxAutoConvertSettingsProvider),
      if (includeEpoch) ref.read(_bridgeDraftEpochProvider),
    ],
    fields: {
      'prompt': main.projection,
      'negative_prompt': negative.projection,
      'model': p.model,
      'width': p.width,
      'height': p.height,
      'steps': p.steps,
      'cfg_scale': p.scale,
      'sampler': p.sampler,
      'seed': p.seed,
      'n_samples': p.nSamples,
      'uc_preset': p.ucPreset,
      'quality_preset': p.effectiveQualityTagPreset.bridgeValue,
      'transparent_background': p.transparentBackground,
      'cfg_rescale': p.cfgRescale,
      'noise_schedule': p.noiseSchedule,
      'variety_plus': p.varietyPlus,
      'smea_auto': p.smeaAuto,
      'smea': p.smea,
      'smea_dyn': p.smeaDyn,
      'use_coords': p.useCoords,
      'characters': [
        for (final c in config.characters)
          {
            'id': c.id,
            'name': c.name,
            'name_is_custom': c.nameIsCustom,
            'prompt': positives[c.id]!.projection,
            'uc': negatives[c.id]!.projection,
            'enabled': c.enabled,
            if (c.customPosition != null) ...{
              'x': c.customPosition!.column,
              'y': c.customPosition!.row,
            },
          },
      ],
    },
    documents: {
      'quality_preset': {
        'mode': quality.mode.name,
        'selected': selectedPreset(quality.customEntryId),
      },
      'uc_preset': {
        'type': uc.presetType.name,
        'selected': selectedPreset(uc.customEntryId),
      },
      'prompt': main.document.toJson(),
      'negative_prompt': negative.document.toJson(),
      'characters': {
        'config': config.toJson(),
        'lanes': {
          for (final c in config.characters)
            c.id: {
              'positive': positives[c.id]!.document.toJson(),
              'negative': negatives[c.id]!.document.toJson(),
            },
        },
      },
    },
  );
}

Future<String> backupBridgeDraft(
  Directory discoveryDirectory,
  BridgeDraftSnapshot draft,
) async {
  final dir = Directory('${discoveryDirectory.path}/draft-backups');
  await dir.create(recursive: true);
  final file = File(
    '${dir.path}/before-agent-${DateTime.now().microsecondsSinceEpoch}.json',
  );
  await file.writeAsString(jsonEncode(draft.toJson()), flush: true);
  return file.path;
}

Map<String, dynamic> readBridgeBilling(
  Ref ref,
  ImageParams p, {
  int batchCount = 1,
  int batchSize = 1,
}) {
  // Read only the already-loaded account state; a quote never requests an API.
  final auth = ref.read(authNotifierProvider);
  final raw = auth.subscriptionInfo;
  final loaded = ref.exists(subscriptionNotifierProvider)
      ? ref.read(subscriptionNotifierProvider).subscription
      : null;
  final subscription =
      loaded ?? (raw == null ? null : UserSubscription.fromJson(raw));
  final requestSize =
      p.upscaledEnhance && MaxEnhanceMath.isEligible(p.model, p.width, p.height)
      ? MaxEnhanceMath.targetSize(p.width, p.height)
      : p.effectiveInpaintRequestSize;
  int estimate(int count, {required int encoding}) =>
      AnlasCalculator.calculateRequestCost(
        width: requestSize.width,
        height: requestSize.height,
        steps: p.steps,
        batchCount: count,
        batchSize: batchSize,
        smea: p.effectiveSmea,
        smeaDyn: p.effectiveSmeaDyn,
        model: p.model,
        subscriptionTier: subscription?.isOpus == true
            ? AnlasCalculator.opusTier
            : 0,
        strength: switch (p.action) {
          ImageGenerationAction.generate => 1.0,
          ImageGenerationAction.img2img => p.strength,
          ImageGenerationAction.infill => p.inpaintStrength,
        },
        extraPerSampleCost: AnlasCalculator.resolvePreciseReferenceExtraCost(p),
        extraPerRequestCost: AnlasCalculator.resolveVibeReferenceExtraCost(p),
        oneTimeCost: encoding,
        opusUsageExhausted: subscription?.isOpusUsageExhausted ?? false,
      );
  final encoding = AnlasCalculator.resolveVibeEncodingCost(p);
  final cost = estimate(batchCount, encoding: encoding);
  return {
    'estimated_anlas': cost,
    'balance_anlas': subscription?.trainingStepsLeft == null
        ? null
        : subscription!.anlasBalance,
    'balance_source': subscription?.trainingStepsLeft == null
        ? 'unavailable'
        : 'cached_account',
    'samples': batchCount * batchSize,
    'requests': batchCount,
    'images_per_request': batchSize,
    'per_request_anlas': estimate(1, encoding: 0),
    'encoding_anlas': encoding,
  };
}
