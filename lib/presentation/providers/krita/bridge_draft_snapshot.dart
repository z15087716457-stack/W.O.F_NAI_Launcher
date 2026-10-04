import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/krita/bridge_draft_guard.dart';
import '../../../core/services/anlas_calculator.dart';
import '../../../data/models/image/image_params.dart';
import '../../../data/models/prompt_block/pill_document.dart';
import '../../../data/models/user/user_subscription.dart';
import '../auth_provider.dart';
import '../character_prompt_provider.dart';
import '../image_generation_provider.dart';
import '../pill_workspace_provider.dart';
import '../subscription_provider.dart';
import '../quality_preset_provider.dart';
import '../uc_preset_provider.dart';
import '../prompt_block_library_provider.dart';

BridgeDraftSnapshot readBridgeDraft(Ref ref) {
  final p = ref.read(generationParamsNotifierProvider);
  // An unopened lane has no document yet. Reads must not initialize or rewrite it.
  PillWorkspaceState lane(String scope, String fallback) {
    final provider = pillWorkspaceProvider(scope);
    if (!ref.exists(provider) &&
        ref.read(pillWorkspaceStorageProvider).tryLoadSync(scope) == null) {
      return PillWorkspaceState(
        document: PillDocument(text: fallback, instances: const {}),
        projection: fallback,
      );
    }
    return ref.read(provider);
  }

  final main = lane(PillScopes.main, p.prompt);
  final negative = lane(PillScopes.negative, p.negativePrompt);
  final config = ref.read(characterPromptNotifierProvider);
  final quality = ref.read(qualityPresetNotifierProvider);
  final uc = ref.read(ucPresetNotifierProvider);
  Map<String, dynamic>? selectedPreset(String? id) {
    if (id == null) return null;
    final block = ref
        .read(promptBlockLibraryNotifierProvider)
        .valueOrNull
        ?.blockById(id);
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

Map<String, dynamic> readBridgeBilling(Ref ref, ImageParams p) {
  // Read only the already-loaded account state; a quote never requests an API.
  final auth = ref.read(authNotifierProvider);
  final raw = auth.subscriptionInfo;
  final loaded = ref.exists(subscriptionNotifierProvider)
      ? ref.read(subscriptionNotifierProvider).subscription
      : null;
  final subscription =
      loaded ?? (raw == null ? null : UserSubscription.fromJson(raw));
  final cost = AnlasCalculator.calculateRequestCost(
    width: p.width,
    height: p.height,
    steps: p.steps,
    batchCount: 1,
    batchSize: 1,
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
    oneTimeCost: AnlasCalculator.resolveVibeEncodingCost(p),
    opusUsageExhausted: subscription?.isOpusUsageExhausted ?? false,
  );
  return {
    'estimated_anlas': cost,
    'balance_anlas': subscription?.anlasBalance,
    'balance_source': subscription == null ? 'unavailable' : 'cached_account',
    'samples': 1,
  };
}
