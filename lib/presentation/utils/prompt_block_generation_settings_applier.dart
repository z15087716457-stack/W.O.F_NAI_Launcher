import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/model_spec.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../providers/generation/generation_params_notifier.dart';
import '../providers/prompt_block_library_provider.dart';
import '../providers/uc_preset_provider.dart';

/// 只在用户明确点击「应用设置」时，把块内指定的字段写入当前生图参数。
void applyPromptBlockGenerationSettings(
  WidgetRef ref,
  PromptBlockGenerationSettings settings,
) {
  applyPromptBlockGenerationSettingsWithReader(ref.read, settings);
}

void applyPromptBlockGenerationSettingsWithReader(
  T Function<T>(ProviderListenable<T>) read,
  PromptBlockGenerationSettings settings,
) {
  final current = read(generationParamsNotifierProvider);
  final model = settings.model ?? current.model;
  validatePromptBlockGenerationSettings(settings, model);
  for (final id in [settings.qualityCustomBlockId, settings.ucCustomBlockId]) {
    if (id != null &&
        read(promptBlockLibraryNotifierProvider).valueOrNull?.blockById(id) ==
            null) {
      throw StateError('Custom preset block no longer exists');
    }
  }
  final notifier = read(generationParamsNotifierProvider.notifier);
  if (settings.model != null) notifier.updateModel(settings.model!);
  if (settings.qualityPreset != null) {
    notifier.updateQualityPreset(settings.qualityPreset!);
  }
  if (settings.qualityCustomBlockId != null) {
    notifier.updateCustomQualityPreset(settings.qualityCustomBlockId!);
  }
  if (settings.ucPreset != null) notifier.updateUcPreset(settings.ucPreset!);
  if (settings.ucCustomBlockId != null) {
    read(
      ucPresetNotifierProvider.notifier,
    ).setCustomEntry(settings.ucCustomBlockId!);
  }
  if (settings.steps != null) notifier.updateSteps(settings.steps!);
  if (settings.scale != null) notifier.updateScale(settings.scale!);
  if (settings.sampler != null) notifier.updateSampler(settings.sampler!);
  if (settings.noiseSchedule != null) {
    notifier.updateNoiseSchedule(settings.noiseSchedule!);
  }
  if (settings.cfgRescale != null) {
    notifier.updateCfgRescale(settings.cfgRescale!);
  }
}

/// 先检查整组参数，再写入任何生成状态；旧块里的宽高不属于可复用设置。
void validatePromptBlockGenerationSettings(
  PromptBlockGenerationSettings settings,
  String targetModel,
) {
  final spec = ModelSpecs.of(targetModel);
  if (settings.ucPreset != null &&
      !UcPresetType.values
          .map(UcPresets.toApiValue)
          .contains(settings.ucPreset)) {
    throw StateError('Invalid UC preset');
  }
  if (settings.model != null &&
      !ImageModels.allModels.contains(settings.model)) {
    throw StateError('Unknown model');
  }
  if (settings.steps case final steps?) {
    if (steps < 1 || steps > 50) throw StateError('Invalid steps');
  }
  if (settings.scale case final scale?) {
    if (!scale.isFinite || scale < 1 || scale > 20) {
      throw StateError('Invalid PG');
    }
  }
  if (settings.sampler != null &&
      !Samplers.samplersForModel(targetModel).contains(settings.sampler)) {
    throw StateError('Unsupported sampler');
  }
  if (settings.noiseSchedule != null &&
      (!spec.noiseSchedule ||
          !NoiseSchedules.all.contains(settings.noiseSchedule))) {
    throw StateError('Unsupported noise schedule');
  }
  if (settings.cfgRescale case final rescale?) {
    if (!spec.isV4OrLater || !rescale.isFinite || rescale < 0 || rescale > 1) {
      throw StateError('Unsupported PGR');
    }
  }
}
