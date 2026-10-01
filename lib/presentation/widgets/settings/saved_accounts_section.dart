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
    ref.watch(accountManagerNotifierProvider);
    final currentAccountId = ref.watch(authNotifierProvider).accountId;

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
          _AddAccountTile(onTap: () => AddAccountDialog.show(context, ref)),
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

    final colors = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCurrent
            ? null
            : () => AccountSwitchHelper.switchToAccount(context, ref, account),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.outlineVariant.withValues(alpha: .5),
              ),
            ),
          ),
          child: Row(
            children: [
              AccountAvatar(account: account, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          account.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: isCurrent
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        if (isCurrent)
                          Text(
                            context.l10n.auth_currentAccount,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: colors.primary,
                            ),
                          ),
                        if (isDefault)
                          Text(
                            context.l10n.settings_defaultAccount,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    if (account.subscriptionExpiresAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SubscriptionExpiryText(
                          expiresAt: account.subscriptionExpiresAt!,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isDefault)
                IconButton(
                  icon: const Icon(Icons.star_outline, size: 17),
                  tooltip: context.l10n.settings_defaultAccount,
                  onPressed: () => ref
                      .read(accountManagerNotifierProvider.notifier)
                      .setDefaultAccount(account.id),
                ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 17,
                  color: colors.onSurfaceVariant,
                ),
                tooltip: context.l10n.auth_deleteAccount,
                onPressed: () =>
                    AccountSwitchHelper.removeAccount(context, ref, account),
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
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.add, size: 20, color: theme.colorScheme.primary),
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
