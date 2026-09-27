import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../providers/generation/generation_params_notifier.dart';

/// 只在用户明确点击「应用设置」时，把块内指定的字段写入当前生图参数。
void applyPromptBlockGenerationSettings(
  WidgetRef ref,
  PromptBlockGenerationSettings settings,
) {
  final current = ref.read(generationParamsNotifierProvider);
  final model = settings.model ?? current.model;
  if (settings.sampler != null &&
      !Samplers.samplersForModel(model).contains(settings.sampler)) {
    throw StateError('Sampler is not supported by the selected model');
  }
  final notifier = ref.read(generationParamsNotifierProvider.notifier);
  if (settings.model != null) notifier.updateModel(settings.model!);
  if (settings.width != null && settings.height != null) {
    notifier.updateSize(settings.width!, settings.height!);
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
