import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/anlas_calculator.dart';
import '../../core/utils/max_enhance_utils.dart';
import '../../data/models/image/image_params.dart';
import '../../data/models/user/user_subscription.dart';
import 'image_generation_provider.dart';
import 'generation/image_workflow_controller.dart';
import 'subscription_provider.dart';

part 'cost_estimate_provider.g.dart';

class _GenerationCostInput {
  const _GenerationCostInput({
    required this.width,
    required this.height,
    required this.strength,
  });

  final int width;
  final int height;
  final double strength;
}

_GenerationCostInput _resolveGenerationCostInput(
  ImageParams params,
  ImageWorkflowState workflow,
) {
  final enhanceWidth = workflow.enhanceUsesGenerationSize
      ? params.width
      : workflow.sourceWidth;
  final enhanceHeight = workflow.enhanceUsesGenerationSize
      ? params.height
      : workflow.sourceHeight;
  // 增强 Max✨：请求宽高是源图尺寸，但服务端按端到端放大目标尺寸计费。
  if (workflow.isEnhance &&
      workflow.enhance.maxUpscale &&
      MaxEnhanceMath.isEligible(params.model, enhanceWidth, enhanceHeight)) {
    final target = MaxEnhanceMath.targetSize(
      enhanceWidth ?? params.width,
      enhanceHeight ?? params.height,
    );
    return _GenerationCostInput(
      width: target.width,
      height: target.height,
      strength: params.strength,
    );
  }

  return _GenerationCostInput(
    width: params.effectiveInpaintRequestSize.width,
    height: params.effectiveInpaintRequestSize.height,
    strength: switch (params.action) {
      ImageGenerationAction.img2img => params.strength,
      ImageGenerationAction.infill => params.inpaintStrength,
      ImageGenerationAction.generate => 1.0,
    },
  );
}

int _calculateEstimatedCost(
  Ref ref, {
  required int batchSize,
  bool includeCanvasTool = true,
  int? batchCountOverride,
}) {
  final params = includeCanvasTool
      ? ref.watch(generationRequestParamsProvider)
      : ref.watch(generationParamsNotifierProvider);
  final workflow = includeCanvasTool
      ? ref.watch(imageWorkflowControllerProvider)
      : ref.watch(draftImageWorkflowProvider);
  final subscription = ref.watch(
    subscriptionNotifierProvider.select((state) => state.subscription),
  );
  return generationRequestCost(
    params,
    workflow,
    subscription,
    batchSize,
    batchCountOverride: batchCountOverride,
  );
}

int generationRequestCost(
  ImageParams params,
  ImageWorkflowState workflow,
  UserSubscription? subscription,
  int batchSize, {
  int? batchCountOverride,
}) {
  final subscriptionTier = subscription?.isOpus == true
      ? AnlasCalculator.opusTier
      : 0;

  if (workflow.isUpscale) {
    if (workflow.upscale.backend == UpscaleBackend.comfyui) {
      return 0;
    }

    final inputWidth = workflow.sourceWidth ?? params.width;
    final inputHeight = workflow.sourceHeight ?? params.height;
    return AnlasCalculator.calculateNovelAiUpscaleCost(
      inputWidth: inputWidth,
      inputHeight: inputHeight,
    );
  }

  final batchCount = batchCountOverride ?? params.nSamples;
  if (batchCount <= 0 || batchSize <= 0) {
    return 0;
  }

  final requestInput = _resolveGenerationCostInput(params, workflow);
  return AnlasCalculator.calculateRequestCost(
    width: requestInput.width,
    height: requestInput.height,
    steps: params.steps,
    batchCount: batchCount,
    batchSize: batchSize,
    smea: params.effectiveSmea,
    smeaDyn: params.effectiveSmeaDyn,
    model: params.model,
    subscriptionTier: subscriptionTier,
    strength: requestInput.strength,
    extraPerSampleCost: AnlasCalculator.resolvePreciseReferenceExtraCost(
      params,
    ),
    extraPerRequestCost: AnlasCalculator.resolveVibeReferenceExtraCost(params),
    oneTimeCost: AnlasCalculator.resolveVibeEncodingCost(params),
    opusUsageExhausted: subscription?.isOpusUsageExhausted ?? false,
  );
}

final styleExploreCostForCountProvider = Provider.family<int, int>(
  (ref, count) => _calculateEstimatedCost(
    ref,
    batchSize: 1,
    includeCanvasTool: false,
    batchCountOverride: count,
  ),
);

/// 预估消耗 Provider
///
/// 根据当前参数实时计算的主生成消耗。
@riverpod
int estimatedCost(Ref ref) {
  return _calculateEstimatedCost(
    ref,
    batchSize: ref.watch(imagesPerRequestProvider),
  );
}

/// 指定单次请求批次大小的消耗，用于探索页强制 N×1。
@riverpod
int estimatedCostForBatchSize(Ref ref, int batchSize) {
  return _calculateEstimatedCost(
    ref,
    batchSize: batchSize,
    includeCanvasTool: false,
  );
}

/// 是否免费生成 Provider
///
/// 只有总消耗为 0 时才是免费
@riverpod
bool isFreeGeneration(Ref ref) {
  final cost = ref.watch(estimatedCostProvider);
  return cost == 0;
}

/// 余额是否不足 Provider
@riverpod
bool isBalanceInsufficient(Ref ref) {
  final balance = ref.watch(anlasBalanceProvider);
  final cost = ref.watch(estimatedCostProvider);

  if (balance == null) return false; // 未加载时不显示警告
  return balance < cost;
}
