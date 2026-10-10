import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';

import '../../../data/models/auth/saved_account.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/auth_provider.dart';
import '../common/app_toast.dart';

/// 已保存账号的切换与删除共享逻辑
///
/// 供设置页账号列表、导航栏账号菜单、登录页快速切换三处复用。
/// 切换失败时按错误类型决定是否给出「从列表删除」引导。
abstract final class AccountSwitchHelper {
  /// 切换到指定账号。
  ///
  /// 成功时更新 lastUsed；失败时弹错误 toast，并在凭据缺失或认证类错误时
  /// 追加「是否从列表删除」对话框。
  static Future<void> switchToAccount(
    BuildContext context,
    WidgetRef ref,
    SavedAccount account,
  ) async {
    final token = await ref
        .read(accountManagerNotifierProvider.notifier)
        .getAccountToken(account.id);

    if (!context.mounted) return;

    if (token == null) {
      // 本地凭据缺失，几乎必然失效，直接给出删除引导
      await _showSwitchFailedDeletePrompt(
        context,
        ref,
        account,
        message: context.l10n.auth_switchFailedDeletePromptMissingToken,
      );
      return;
    }

    final success = await ref
        .read(authNotifierProvider.notifier)
        .switchAccount(
          account.id,
          token,
          displayName: account.displayName,
          accountType: account.accountType,
        );

    if (success || !context.mounted) return;

    final authState = ref.read(authNotifierProvider);
    final errorMessage = switch (authState.errorCode) {
      AuthErrorCode.networkTimeout => context.l10n.auth_error_networkTimeout,
      AuthErrorCode.networkError => context.l10n.auth_error_networkError,
      AuthErrorCode.authFailed ||
      AuthErrorCode.tokenInvalid => context.l10n.auth_error_authFailed,
      AuthErrorCode.credentialsLoginUnavailable =>
        context.l10n.auth_error_credentialsLoginUnavailable,
      AuthErrorCode.serverError => context.l10n.auth_error_serverError,
      _ => context.l10n.auth_loginFailed,
    };

    AppToast.error(context, errorMessage);

    // 认证类失败基本可判定账号失效，给出删除引导；网络类错误不弹
    const invalidCredentialErrors = {
      AuthErrorCode.authFailed,
      AuthErrorCode.tokenInvalid,
      AuthErrorCode.credentialsLoginUnavailable,
    };
    if (invalidCredentialErrors.contains(authState.errorCode)) {
      await _showSwitchFailedDeletePrompt(context, ref, account);
    }
  }

  /// 切换失败后的「是否删除」引导对话框
  static Future<void> _showSwitchFailedDeletePrompt(
    BuildContext context,
    WidgetRef ref,
    SavedAccount account, {
    String? message,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.auth_switchAccount),
        content: Text(
          message ?? context.l10n.auth_switchFailedDeletePrompt,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(context.l10n.common_delete),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await removeAccount(context, ref, account);
    }
  }

  /// 删除账号：确认对话框 → removeAccount；删除当前登录账号时先确认并退出登录
  static Future<void> removeAccount(
    BuildContext context,
    WidgetRef ref,
    SavedAccount account,
  ) async {
    final isCurrent =
        ref.read(authNotifierProvider).accountId == account.id;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.auth_deleteAccount),
        content: Text(
          isCurrent
              ? context.l10n.auth_deleteCurrentAccountConfirm(
                  account.displayName,
                )
              : context.l10n.auth_deleteAccountConfirm(account.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(context.l10n.common_delete),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    await ref
        .read(accountManagerNotifierProvider.notifier)
        .removeAccount(account.id);

    if (isCurrent) {
      // 删除当前登录账号：等当前帧结束后登出，避免对话框/菜单销毁期触发路由监听
      SchedulerBinding.instance.endOfFrame.then((_) {
        if (context.mounted) {
          ref.read(authNotifierProvider.notifier).logout();
        }
      });
    }
  }
}
