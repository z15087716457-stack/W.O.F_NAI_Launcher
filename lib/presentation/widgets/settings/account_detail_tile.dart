import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/subscription_provider.dart';
import '../auth/account_avatar.dart';
import '../auth/subscription_expiry_text.dart';
import '../common/studio_icons.dart';

class AccountDetailTile extends ConsumerWidget {
  const AccountDetailTile({super.key, this.onEdit, this.onLogin});
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
    Widget overview({bool showArrow = true}) => Row(
      children: [
        if (loaded)
          AccountAvatar(account: account, size: 41)
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
              Text(
                loaded
                    ? account.displayName
                    : context.l10n.settings_notLoggedIn,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                          Text(
                            subscription.hasActiveSubscription
                                ? subscription.tierName
                                : context.l10n.subscriptionTierNone,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          if (subscription.isGracePeriod)
                            Text(
                              context.l10n.subscriptionGracePeriod,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                              ),
                            )
                          else if (subscription.expiresAt != null &&
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
    return Material(
      color: colors.onSurface.withValues(alpha: .035),
      borderRadius: BorderRadius.circular(10),
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
                        child: balance,
                      ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: overview(showArrow: false)),
                  if (loaded) ...[
                    const SizedBox(width: 32),
                    balance,
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
