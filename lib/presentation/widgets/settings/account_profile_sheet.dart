import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';

import '../../../core/services/avatar_service.dart';
import '../../../data/models/auth/saved_account.dart';
import '../../providers/account_manager_provider.dart';
import '../auth/account_avatar.dart';
import '../auth/subscription_expiry_text.dart';
import '../common/app_toast.dart';
import '../../screens/settings/widgets/settings_dialog.dart';
import '../../screens/settings/widgets/settings_tile.dart';

/// 居中的桌面账号资料面板，保留类名以兼容现有入口。
class AccountProfileBottomSheet extends ConsumerStatefulWidget {
  /// 当前账号
  final SavedAccount account;

  const AccountProfileBottomSheet({super.key, required this.account});

  /// 显示账号资料面板
  static Future<void> show({
    required BuildContext context,
    required SavedAccount account,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AccountProfileBottomSheet(account: account),
    );
  }

  @override
  ConsumerState<AccountProfileBottomSheet> createState() =>
      _AccountProfileBottomSheetState();
}

class _AccountProfileBottomSheetState
    extends ConsumerState<AccountProfileBottomSheet> {
  /// 头像服务
  final _avatarService = AvatarService();

  /// 操作锁定（防止竞态条件）
  bool _isOperationInProgress = false;

  /// 当前账号（从 Provider 获取最新数据）
  SavedAccount get currentAccount {
    final accounts = ref.read(accountManagerNotifierProvider).accounts;
    return accounts.firstWhere(
      (a) => a.id == widget.account.id,
      orElse: () => widget.account,
    );
  }

  /// 更换头像
  Future<void> _changeAvatar() async {
    // 防止重复点击
    if (_isOperationInProgress) return;
    _isOperationInProgress = true;

    try {
      final result = await _avatarService.pickAndSaveAvatar(currentAccount);

      if (result.isSuccess && result.path != null) {
        final updatedAccount = currentAccount.copyWith(avatarPath: result.path);
        await ref
            .read(accountManagerNotifierProvider.notifier)
            .updateAccount(updatedAccount);

        // 刷新 UI
        setState(() {});

        if (mounted) {
          AppToast.success(context, context.l10n.settings_avatarUpdated);
        }
      } else if (result.isFailure && mounted) {
        // 显示错误信息
        AppToast.error(
          context,
          result.errorMessage ?? context.l10n.common_error,
        );
      }
      // 取消操作不需要提示
    } catch (e) {
      if (mounted) {
        AppToast.error(context, context.l10n.common_error);
      }
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// 移除头像
  Future<void> _removeAvatar() async {
    // 防止重复点击
    if (_isOperationInProgress) return;
    _isOperationInProgress = true;

    try {
      await _avatarService.removeAvatar(currentAccount);

      final updatedAccount = currentAccount.copyWith(avatarPath: null);
      await ref
          .read(accountManagerNotifierProvider.notifier)
          .updateAccount(updatedAccount);

      // 刷新 UI
      setState(() {});

      if (mounted) {
        AppToast.success(context, context.l10n.settings_avatarRemoved);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, context.l10n.common_error);
      }
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// 编辑昵称
  Future<void> _editNickname() async {
    if (_isOperationInProgress) return;
    final controller = TextEditingController(text: currentAccount.nickname);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SettingsDialogFrame(
        title: context.l10n.settings_nickname,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: Text(context.l10n.common_save),
          ),
        ],
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 64,
          decoration: InputDecoration(
            labelText: context.l10n.settings_nickname,
          ),
        ),
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    _isOperationInProgress = true;
    try {
      await ref
          .read(accountManagerNotifierProvider.notifier)
          .updateAccount(currentAccount.copyWith(nickname: value));
      if (mounted) {
        AppToast.success(context, context.l10n.settings_nicknameUpdated);
      }
    } catch (_) {
      if (mounted) AppToast.error(context, context.l10n.common_error);
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// 设为默认账号
  Future<void> _setAsDefault() async {
    // 防止重复点击
    if (_isOperationInProgress) return;
    _isOperationInProgress = true;

    try {
      await ref
          .read(accountManagerNotifierProvider.notifier)
          .setDefaultAccount(currentAccount.id);

      // 刷新 UI
      setState(() {});

      if (mounted) {
        AppToast.success(context, context.l10n.settings_setAsDefaultSuccess);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, context.l10n.common_error);
      }
    } finally {
      _isOperationInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountManagerNotifierProvider).accounts;
    final current =
        accounts.where((a) => a.id == widget.account.id).firstOrNull ??
        widget.account;
    final theme = Theme.of(context);
    final isDefault = current.isDefault;
    return SettingsDialogFrame(
      title: context.l10n.settings_accountDetails,
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AccountAvatar(
                  account: current,
                  size: 54,
                  muted: true,
                  showEditBadge: false,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current.displayName,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.l10n.settings_localAccountProfile,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: _changeAvatar,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(context.l10n.settings_changeAvatar),
                ),
                if (current.avatarPath != null)
                  TextButton(
                    onPressed: _removeAvatar,
                    child: Text(context.l10n.settings_removeAvatar),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsTile(
              controlWrapWidth: 320,
              title: Text(context.l10n.settings_nickname),
              trailing: Text(current.displayName),
              onTap: _editNickname,
            ),
            if (current.email.contains('@'))
              SettingsTile(
                controlWrapWidth: 320,
                title: Text(context.l10n.settings_accountEmail),
                subtitle: Text(current.email),
              ),
            SettingsTile(
              controlWrapWidth: 320,
              title: Text(context.l10n.settings_accountType),
              trailing: Text(
                ref
                        .read(accountManagerNotifierProvider.notifier)
                        .getAccountApiEndpoint(current.id)
                        .isThirdParty
                    ? context.l10n.settings_thirdPartyApiAccount
                    : current.accountType == AccountType.credentials
                    ? context.l10n.settings_emailAccount
                    : context.l10n.settings_tokenAccount,
              ),
            ),
            if (current.subscriptionExpiresAt != null)
              SettingsTile(
                controlWrapWidth: 400,
                title: Text(context.l10n.settings_subscriptionExpiry),
                trailing: SubscriptionExpiryText(
                  expiresAt: current.subscriptionExpiresAt!,
                ),
              ),
            if (accounts.length > 1)
              SettingsTile(
                controlWrapWidth: 320,
                title: Text(context.l10n.settings_setAsDefault),
                trailing: isDefault
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: theme.colorScheme.primary,
                      )
                    : OutlinedButton(
                        onPressed: _setAsDefault,
                        child: Text(context.l10n.settings_setDefault2),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
