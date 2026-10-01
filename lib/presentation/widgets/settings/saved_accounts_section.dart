import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/auth/saved_account.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/settings/widgets/settings_card.dart';
import '../../screens/settings/widgets/settings_ui_theme.dart';
import '../auth/account_avatar.dart';
import '../auth/account_switch_helper.dart';
import '../auth/add_account_dialog.dart';
import '../auth/subscription_expiry_text.dart';
import 'account_profile_sheet.dart';

class SavedAccountsSection extends ConsumerWidget {
  const SavedAccountsSection({super.key, this.showAddButton = true});
  final bool showAddButton;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(accountManagerNotifierProvider);
    final current = ref.watch(authNotifierProvider).accountId;
    final manager = ref.read(accountManagerNotifierProvider.notifier);
    final sorted = manager.sortedAccounts;
    final ordered = [
      ...sorted.where((a) => a.id == current),
      ...sorted.where((a) => a.id != current),
    ];
    return SettingsCard(
      title: context.l10n.settings_savedAccounts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ordered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                settingsText(
                  context,
                  '添加账号后，可以在这里快速切换。',
                  'Add accounts to switch between them here.',
                  '追加したアカウントをここで切り替えられます。',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          for (final account in ordered)
            _SavedAccountTile(
              account: account,
              isCurrent: account.id == current,
              isDefault: account.id == manager.defaultAccount?.id,
            ),
          if (showAddButton)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => AddAccountDialog.show(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: Text(context.l10n.auth_addAccount),
              ),
            ),
        ],
      ),
    );
  }
}

class _SavedAccountTile extends ConsumerWidget {
  const _SavedAccountTile({
    required this.account,
    required this.isCurrent,
    required this.isDefault,
  });
  final SavedAccount account;
  final bool isCurrent, isDefault;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    Widget badge(String label, {bool active = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: (active ? colors.primary : colors.onSurface).withValues(
          alpha: .07,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: active ? colors.primary : colors.onSurfaceVariant,
        ),
      ),
    );
    final identity = Row(
      children: [
        AccountAvatar(
          account: account,
          size: 30,
          muted: true,
          showEditBadge: false,
        ),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isCurrent)
                    badge(
                      settingsText(context, '当前', 'Current', '現在'),
                      active: true,
                    ),
                  if (isDefault) badge(context.l10n.settings_defaultAccount),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                account.accountType == AccountType.token
                    ? 'API Token'
                    : settingsText(context, '邮箱登录', 'Email login', 'メールログイン'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (account.subscriptionExpiresAt != null)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SubscriptionExpiryText(
                expiresAt: account.subscriptionExpiresAt!,
              ),
            ),
          ),
        if (!isCurrent)
          OutlinedButton(
            onPressed: () =>
                AccountSwitchHelper.switchToAccount(context, ref, account),
            child: Text(settingsText(context, '切换', 'Switch', '切替')),
          ),
        PopupMenuButton<String>(
          key: ValueKey('settings-account-menu-${account.id}'),
          tooltip: settingsText(context, '账号操作', 'Account actions', 'アカウント操作'),
          icon: Icon(
            Icons.more_horiz,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'profile',
              height: 36,
              child: Text(
                settingsText(context, '编辑资料', 'Edit profile', '情報を編集'),
              ),
            ),
            if (!isDefault)
              PopupMenuItem(
                value: 'default',
                height: 36,
                child: Text(
                  settingsText(context, '设为默认账号', 'Set as default', '既定に設定'),
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              height: 36,
              child: Text(
                context.l10n.auth_deleteAccount,
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
          onSelected: (action) {
            switch (action) {
              case 'profile':
                AccountProfileBottomSheet.show(
                  context: context,
                  account: account,
                );
              case 'default':
                ref
                    .read(accountManagerNotifierProvider.notifier)
                    .setDefaultAccount(account.id);
              case 'delete':
                AccountSwitchHelper.removeAccount(context, ref, account);
            }
          },
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: .5),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 520
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identity,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              )
            : Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 20),
                  actions,
                ],
              ),
      ),
    );
  }
}
