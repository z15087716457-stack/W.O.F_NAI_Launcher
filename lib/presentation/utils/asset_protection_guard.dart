import 'dart:io';
import 'dart:async';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../providers/cost_estimate_provider.dart';
import '../providers/share_image_settings_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/themed_confirm_dialog.dart';
import '../widgets/common/anlas_cost_dialog.dart';
import '../../core/services/anlas_calculator.dart';
import '../../core/utils/localization_extension.dart';
import '../../data/services/anlas_usage_metrics.dart';

class AssetProtectionGuard {
  const AssetProtectionGuard._();

  static ShareImageSettings settings(WidgetRef ref) =>
      ref.read(shareImageSettingsProvider);

  static bool shouldPreventOverwrite(WidgetRef ref) =>
      ref.read(shareImageSettingsProvider).effectivePreventOverwrite;

  static Future<bool> confirmDangerousAction({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String content,
    String? confirmText,
    IconData icon = Icons.shield_outlined,
  }) async {
    if (!ref
        .read(shareImageSettingsProvider)
        .effectiveConfirmDangerousActions) {
      return true;
    }
    return ThemedConfirmDialog.show(
      context: context,
      title: title,
      content: content,
      confirmText: confirmText ?? context.l10n.common_continue,
      cancelText: context.l10n.common_cancel,
      type: ThemedConfirmDialogType.warning,
      icon: icon,
    );
  }

  static Future<bool> confirmExternalImageSend({
    required BuildContext context,
    required WidgetRef ref,
    required String targetName,
    int imageCount = 1,
  }) {
    if (!ref.read(shareImageSettingsProvider).effectiveWarnExternalImageSend) {
      return Future.value(true);
    }
    final l10n = context.l10n;
    return ThemedConfirmDialog.show(
      context: context,
      title: l10n.settings_confirmExternalSendTitle,
      content: l10n.settings_confirmExternalSendContent(imageCount, targetName),
      confirmText: l10n.settings_confirmExternalSend,
      cancelText: l10n.common_cancel,
      type: ThemedConfirmDialogType.warning,
      icon: Icons.cloud_upload_outlined,
    );
  }

  static Future<bool> confirmHighAnlasCost({
    required BuildContext context,
    required WidgetRef ref,
    int? cost,
  }) async {
    final int estimatedCost = cost ?? ref.read(estimatedCostProvider);
    if (estimatedCost == AnlasCalculator.invalidCost) {
      AppToast.warning(context, context.l10n.generation_requestCostInvalid);
      return false;
    }
    final container = ProviderScope.containerOf(context, listen: false);
    if (container.exists(subscriptionNotifierProvider)) {
      bool insufficient() {
        final balance = ref.read(subscriptionNotifierProvider).balance;
        return balance != null && balance < estimatedCost;
      }

      if (insufficient()) {
        await ref.read(subscriptionNotifierProvider.notifier).refreshBalance();
        if (!context.mounted) return false;
        if (insufficient()) {
          AppToast.warning(context, context.l10n.api_error_402_hint);
          return false;
        }
      }
    }
    final settings = ref.read(shareImageSettingsProvider);
    if (!settings.effectiveWarnHighAnlasCost) {
      return true;
    }

    if (estimatedCost < settings.highAnlasCostThreshold) {
      return true;
    }

    unawaited(
      ref
          .read(anlasUsageMetricsProvider.notifier)
          .record(warning: true)
          .catchError((Object _) {}),
    );
    return AnlasCostDialog.show(
      context,
      cost: estimatedCost,
      threshold: settings.highAnlasCostThreshold,
    );
  }

  static Future<String> resolveNonOverwritingPath(String requestedPath) async {
    final file = File(requestedPath);
    if (!await file.exists()) {
      return requestedPath;
    }

    final directory = p.dirname(requestedPath);
    final extension = p.extension(requestedPath);
    final baseName = p.basenameWithoutExtension(requestedPath);

    var index = 1;
    while (true) {
      final candidate = p.join(directory, '$baseName ($index)$extension');
      if (!await File(candidate).exists()) {
        return candidate;
      }
      index += 1;
    }
  }
}
