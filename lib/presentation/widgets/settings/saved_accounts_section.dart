import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';

import '../../../data/models/auth/saved_account.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/settings/widgets/settings_card.dart';
import '../auth/account_avatar.dart';
import '../auth/account_switch_helper.dart';
import '../auth/add_account_dialog.dart';
import '../auth/subscription_expiry_text.dart';

/// 已保存账号设置板块
///
/// 列出全部已保存账号，支持切换、删除和添加账号。
/// 当前登录账号置顶并带标记。
class SavedAccountsSection extends ConsumerWidget {
  const SavedAccountsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountManagerNotifierProvider);
    final currentAccountId = ref.watch(authNotifierProvider).accountId;

    if (accountState.accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    // 当前账号置顶，其余按最近使用排序
    final notifier = ref.read(accountManagerNotifierProvider.notifier);
    final sorted = notifier.sortedAccounts;
    final ordered = [
      ...sorted.where((a) => a.id == currentAccountId),
      ...sorted.where((a) => a.id != currentAccountId),
    ];
    final defaultAccountId = notifier.defaultAccount?.id;

    return SettingsCard(
      title: context.l10n.settings_savedAccounts,
      icon: Icons.people_alt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...ordered.map(
            (account) => _SavedAccountTile(
              account: account,
              isCurrent: account.id == currentAccountId,
              isDefault: account.id == defaultAccountId,
            ),
          ),
          const SizedBox(height: 4),
          // 添加账号
          _AddAccountTile(
            onTap: () => AddAccountDialog.show(context, ref),
          ),
        ],
      ),
    );
  }
}

/// 单个已保存账号条目
class _SavedAccountTile extends ConsumerWidget {
  final SavedAccount account;
  final bool isCurrent;
  final bool isDefault;

  const _SavedAccountTile({
    required this.account,
    required this.isCurrent,
    required this.isDefault,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrent
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isCurrent
            ? null
            : () => AccountSwitchHelper.switchToAccount(context, ref, account),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              AccountAvatar(account: account, size: 40),
              const SizedBox(width: 12),
              // 名称、邮箱、到期
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            account.displayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
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
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (account.subscriptionExpiresAt != null)
                      SubscriptionExpiryText(
                        expiresAt: account.subscriptionExpiresAt!,
                      ),
                  ],
                ),
              ),
              // 当前账号标识 + 删除
              if (isCurrent)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: theme.colorScheme.error.withValues(alpha: 0.7),
                ),
                onPressed: () =>
                    AccountSwitchHelper.removeAccount(context, ref, account),
                tooltip: context.l10n.auth_deleteAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 添加账号入口行
class _AddAccountTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddAccountTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.add,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.auth_addAccount,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
