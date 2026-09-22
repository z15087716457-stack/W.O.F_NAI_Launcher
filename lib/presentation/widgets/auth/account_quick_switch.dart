import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_manager_provider.dart';
import '../../../data/models/auth/saved_account.dart';
import 'account_avatar.dart';
import 'account_switch_helper.dart';
import 'subscription_expiry_text.dart';

/// 账号快速切换组件
class AccountQuickSwitch extends ConsumerWidget {
  const AccountQuickSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountManagerNotifierProvider);
    final accounts = accountState.accounts;
    final currentAccountId = ref.watch(authNotifierProvider).accountId;

    if (accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpansionTile(
      title: Text(
        context.l10n.auth_savedAccounts,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...accounts.map(
                (account) => _buildAccountTile(
                  context: context,
                  account: account,
                  isCurrent: account.id == currentAccountId,
                  isThirdParty:
                      accountState
                          .accountApiEndpoints[account.id]
                          ?.isThirdParty ??
                      false,
                  onTap: () => AccountSwitchHelper.switchToAccount(
                    context,
                    ref,
                    account,
                  ),
                  onDelete: () => AccountSwitchHelper.removeAccount(
                    context,
                    ref,
                    account,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTile({
    required BuildContext context,
    required SavedAccount account,
    required bool isCurrent,
    required bool isThirdParty,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        // FEAT-30：方形品牌蓝底白字，与公共件同规格
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kAvatarBackground,
            borderRadius: avatarBorderRadius(36),
          ),
          child: Center(
            child: Text(
              account.displayName[0].toUpperCase(),
              style: const TextStyle(
                color: kAvatarForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        title: Text(
          account.displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isThirdParty
                  ? context.l10n.auth_thirdPartyLogin
                  : account.accountType == AccountType.credentials
                  ? context.l10n.auth_credentialsLogin
                  : context.l10n.auth_tokenLogin,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (account.subscriptionExpiresAt != null) ...[
              const SizedBox(height: 2),
              SubscriptionExpiryText(expiresAt: account.subscriptionExpiresAt!),
            ],
          ],
        ),
        trailing: isCurrent
            ? Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, size: 20),
                    onPressed: onTap,
                    tooltip: context.l10n.auth_switchAccount,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: theme.colorScheme.error.withValues(alpha: 0.7),
                    ),
                    onPressed: onDelete,
                    tooltip: context.l10n.auth_deleteAccount,
                  ),
                ],
              ),
        onTap: isCurrent ? null : onTap,
      ),
    );
  }
}
