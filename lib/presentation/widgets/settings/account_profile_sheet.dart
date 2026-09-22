import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';

import '../../../core/services/avatar_service.dart';
import '../../../core/utils/subscription_expiry_utils.dart';
import '../../../data/models/auth/saved_account.dart';
import '../../providers/account_manager_provider.dart';
import '../auth/account_avatar.dart';
import '../auth/subscription_expiry_text.dart';
import '../common/app_toast.dart';
import '../common/themed_divider.dart';
import 'nickname_edit_dialog.dart';

/// 账号资料底部操作面板
///
/// 用于编辑账号头像、昵称等资料
/// 参考 TagBottomActionSheet 的设计规范：
/// - 毛玻璃背景效果
/// - 顶部拖动指示条
/// - 20px 顶部圆角
/// - isScrollControlled: true
class AccountProfileBottomSheet extends ConsumerStatefulWidget {
  /// 当前账号
  final SavedAccount account;

  const AccountProfileBottomSheet({super.key, required this.account});

  /// 显示底部操作面板
  static Future<void> show({
    required BuildContext context,
    required SavedAccount account,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AccountProfileBottomSheet(account: account),
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
  void _editNickname() {
    // 防止重复点击
    if (_isOperationInProgress) return;

    NicknameEditDialog.show(
      context: context,
      account: currentAccount,
      onSave: (newNickname) async {
        _isOperationInProgress = true;
        try {
          final updatedAccount = currentAccount.copyWith(nickname: newNickname);
          await ref
              .read(accountManagerNotifierProvider.notifier)
              .updateAccount(updatedAccount);

          // 刷新 UI
          setState(() {});

          if (mounted) {
            AppToast.success(context, context.l10n.settings_nicknameUpdated);
          }
        } catch (e) {
          if (mounted) {
            AppToast.error(context, context.l10n.common_error);
          }
        } finally {
          _isOperationInProgress = false;
        }
      },
    );
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
    final theme = Theme.of(context);
    // 使用 ref.watch 实现响应式更新
    final accounts = ref.watch(accountManagerNotifierProvider).accounts;
    final defaultAccount = ref
        .read(accountManagerNotifierProvider.notifier)
        .defaultAccount;
    final isDefaultAccount = defaultAccount?.id == currentAccount.id;
    final hasMultipleAccounts = accounts.length > 1;
    // 账号切换列表已移至设置页「已保存账号」区块

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动指示条
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 内容
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  // 大头像
                  _buildAvatarSection(context),
                  const SizedBox(height: 24),
                  // 头像操作按钮
                  _buildAvatarActions(context),
                  const SizedBox(height: 16),
                  // 分割线
                  const ThemedDivider(),
                  const SizedBox(height: 16),
                  // 昵称行
                  _buildNicknameRow(context),
                  const SizedBox(height: 8),
                  // 账号详情
                  _buildAccountDetails(context),
                  const SizedBox(height: 16),
                  // 设为默认（多账号时显示）
                  if (hasMultipleAccounts) ...[
                    _buildSetAsDefaultRow(context, isDefaultAccount),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建头像区域
  Widget _buildAvatarSection(BuildContext context) {
    return Column(
      children: [
        // 大头像（可点击）
        GestureDetector(
          onTap: _changeAvatar,
          child: Stack(
            children: [
              AccountAvatar(
                account: currentAccount,
                size: 100,
                showEditBadge: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 提示文本
        Text(
          context.l10n.settings_tapToChangeAvatar,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  /// 构建头像操作按钮
  Widget _buildAvatarActions(BuildContext context) {
    final hasCustomAvatar = currentAccount.avatarPath != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 更换头像按钮
        TextButton.icon(
          onPressed: _changeAvatar,
          icon: const Icon(Icons.photo_library),
          label: Text(context.l10n.settings_changeAvatar),
        ),
        if (hasCustomAvatar) ...[
          const SizedBox(width: 16),
          // 移除头像按钮
          TextButton.icon(
            onPressed: _removeAvatar,
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
            label: Text(
              context.l10n.settings_removeAvatar,
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ],
    );
  }

  /// 构建昵称行
  Widget _buildNicknameRow(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: _editNickname,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              Icons.badge_outlined,
              size: 20,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.settings_nickname,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const Spacer(),
            Text(currentAccount.displayName, style: theme.textTheme.bodyMedium),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建账号详情
  Widget _buildAccountDetails(BuildContext context) {
    final endpoint = ref
        .watch(accountManagerNotifierProvider)
        .accountApiEndpoints[currentAccount.id];
    final isThirdParty = endpoint?.isThirdParty ?? false;

    return Column(
      children: [
        // 邮箱
        _buildDetailRow(
          context,
          icon: Icons.email_outlined,
          label: context.l10n.settings_accountEmail,
          value: currentAccount.email,
        ),
        const SizedBox(height: 8),
        // 账号类型
        _buildDetailRow(
          context,
          icon: Icons.account_circle_outlined,
          label: context.l10n.settings_accountType,
          value: isThirdParty
              ? context.l10n.settings_thirdPartyApiAccount
              : currentAccount.accountType == AccountType.credentials
              ? context.l10n.settings_emailAccount
              : context.l10n.settings_tokenAccount,
        ),
        // 订阅到期（档案中上次已知值）
        if (currentAccount.subscriptionExpiresAt != null) ...[
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final info = getSubscriptionExpiryInfo(
                currentAccount.subscriptionExpiresAt!,
              );
              return _buildDetailRow(
                context,
                icon: Icons.event_outlined,
                label: context.l10n.settings_subscriptionExpiry,
                value: SubscriptionExpiryText.dateStatusTextOf(context, info),
                valueColor: SubscriptionExpiryText.statusColor(
                  context,
                  info.status,
                ),
              );
            },
          ),
        ],
        if (isThirdParty && endpoint != null) ...[
          const SizedBox(height: 8),
          _buildDetailRow(
            context,
            icon: Icons.public_outlined,
            label: context.l10n.settings_apiSite,
            value: endpoint.mainBaseUrl,
          ),
        ],
      ],
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.outline),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }

  /// 构建设为默认行
  Widget _buildSetAsDefaultRow(BuildContext context, bool isDefault) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: isDefault ? null : _setAsDefault,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(
              Icons.star_border_outlined,
              size: 20,
              color: isDefault
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.settings_setAsDefault,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDefault
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
            const Spacer(),
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  context.l10n.settings_defaultAccount,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
