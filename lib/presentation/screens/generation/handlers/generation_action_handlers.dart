import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nai_launcher/core/utils/localization_extension.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/generation/image_workflow_controller.dart';
import '../../../providers/krita/krita_bridge_notifier.dart';
import '../../../utils/asset_protection_guard.dart';
import '../../../widgets/common/app_toast.dart';

/// 带资产保护确认的生成入口（经典布局与官网式布局共用）
Future<void> generateWithProtection(BuildContext context, WidgetRef ref) async {
  if (ref.read(imageWorkflowControllerProvider).isToolRunning) return;
  final currentParams = ref.read(generationRequestParamsProvider);
  if (ref.read(generationCooldownProvider).isActive) {
    return;
  }
  if (ref.read(kritaBridgeNotifierProvider).isBridgeGenerating) {
    AppToast.warning(context, context.l10n.kritaBridge_busyGenerating);
    return;
  }
  if (currentParams.prompt.isEmpty) {
    return;
  }
  final confirmed = await AssetProtectionGuard.confirmHighAnlasCost(
    context: context,
    ref: ref,
  );
  if (!confirmed ||
      !context.mounted ||
      ref.read(imageWorkflowControllerProvider).isToolRunning) {
    return;
  }
  ref.read(imageGenerationNotifierProvider.notifier).generate(currentParams);
}
