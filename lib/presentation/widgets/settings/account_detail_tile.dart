import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/subscription_provider.dart';
import '../auth/account_avatar.dart';
import '../auth/subscription_expiry_text.dart';
import '../common/studio_icons.dart';
import '../../screens/settings/widgets/settings_ui_theme.dart';

class AccountDetailTile extends ConsumerWidget {
  const AccountDetailTile({
    super.key,
    this.onEdit,
    this.onLogin,
    this.showExpiry = true,
  });
  final bool showExpiry;
  final VoidCallback? onEdit, onLogin;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final auth = ref.watch(authNotifierProvider);
    final account = ref
        .watch(accountManagerNotifierProvider)
        .accounts
        .where((a) => a.id == auth.accountId)
        .firstOrNull;
    final loaded = auth.isAuthenticated && account != null;
    final currentSubscription = ref
        .watch(subscriptionNotifierProvider)
        .maybeWhen(loaded: (value) => value, orElse: () => null);
    Widget overview({bool showArrow = true}) => Row(
      children: [
        if (loaded)
          AccountAvatar(
            account: account,
            size: 42,
            muted: true,
            showEditBadge: false,
          )
        else
          Icon(
            StudioIcons.settingsAccount,
            size: 32,
            color: colors.onSurfaceVariant,
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    loaded
                        ? account.displayName
                        : context.l10n.settings_notLoggedIn,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (loaded && currentSubscription != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.onSurface.withValues(alpha: .055),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        currentSubscription.hasActiveSubscription
                            ? currentSubscription.tierName
                            : context.l10n.subscriptionTierNone,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              if (loaded)
                ref
                    .watch(subscriptionNotifierProvider)
                    .when(
                      initial: () => Text(
                        context.l10n.settings_account,
                        style: theme.textTheme.bodySmall,
                      ),
                      loading: () => const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      loaded: (subscription) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!showExpiry)
                            Row(
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.green.shade400
                                      : Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    settingsText(
                                      context,
                                      subscription.hasActiveSubscription
                                          ? '已登录 · 订阅有效'
                                          : '已登录',
                                      subscription.hasActiveSubscription
                                          ? 'Signed in · Subscription active'
                                          : 'Signed in',
                                      subscription.hasActiveSubscription
                                          ? 'ログイン済み · 有効なサブスクリプション'
                                          : 'ログイン済み',
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.green.shade400
                                          : Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (showExpiry && subscription.isGracePeriod)
                            Text(
                              context.l10n.subscriptionGracePeriod,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                              ),
                            )
                          else if (showExpiry &&
                              subscription.expiresAt != null &&
                              subscription.tier > 0)
                            SubscriptionExpiryText(
                              expiresAt: subscription.expiresAt!,
                              includeDate: false,
                            ),
                        ],
                      ),
                      error: (_) => Icon(
                        Icons.error_outline,
                        size: 15,
                        color: colors.error,
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (!loaded)
          OutlinedButton(
            onPressed: onLogin,
            child: Text(context.l10n.settings_goToLogin),
          )
        else if (showArrow)
          Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceVariant),
      ],
    );
    final balance = loaded
        ? ref
              .watch(subscriptionNotifierProvider)
              .when(
                initial: () => const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_) => const SizedBox.shrink(),
                loaded: (subscription) => Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Anlas',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subscription.anlasBalance.toString().replaceAllMapped(
                        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                        (m) => '${m[1]},',
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 25,
                      ),
                    ),
                  ],
                ),
              )
        : const SizedBox.shrink();
    final balanceControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        balance,
        const SizedBox(width: 8),
        IconButton(
          key: const Key('settings-refresh-account'),
          tooltip: settingsText(
            context,
            '刷新余额与订阅',
            'Refresh balance and subscription',
            '残高と契約を更新',
          ),
          onPressed: () async {
            final notifier = ref.read(subscriptionNotifierProvider.notifier);
            notifier.resetLoadState();
            await notifier.fetchSubscription();
          },
          icon: const Icon(Icons.refresh, size: 16),
        ),
      ],
    );
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: loaded ? onEdit : onLogin,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 440) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    overview(),
                    if (loaded)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: balanceControls,
                        ),
                      ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: overview(showArrow: false)),
                  if (loaded) ...[
                    const SizedBox(width: 32),
                    balanceControls,
                    const SizedBox(width: 24),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
