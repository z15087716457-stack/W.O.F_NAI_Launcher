import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/subscription_expiry_utils.dart';
import '../../../data/models/user/user_subscription.dart';
import '../auth/subscription_expiry_text.dart';

/// Only the active account receives live subscription data and balance.
class AccountSubscriptionSummary extends StatelessWidget {
  const AccountSubscriptionSummary({
    super.key,
    required this.state,
    required this.credentialAction,
  });

  final SubscriptionState state;
  final Widget credentialAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final subscription = state.subscription;
    Widget metric(String label, Widget value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        value,
      ],
    );
    final status = subscription == null
        ? null
        : subscription.isGracePeriod
        ? context.l10n.subscriptionGracePeriod
        : subscription.hasActiveSubscription
        ? context.l10n.settings_subscriptionActive
        : subscription.tier > 0
        ? context.l10n.subscriptionExpired
        : context.l10n.subscriptionTierNone;
    final statusColor = subscription?.isGracePeriod == true
        ? SubscriptionExpiryText.statusColor(
            context,
            SubscriptionExpiryStatus.expiringSoon,
            subdued: true,
          )
        : subscription?.hasActiveSubscription == true
        ? colors.onSurfaceVariant
        : subscription != null && subscription.tier > 0
        ? SubscriptionExpiryText.statusColor(
            context,
            SubscriptionExpiryStatus.expired,
            subdued: true,
          )
        : colors.onSurfaceVariant;
    final balance = subscription == null
        ? const SizedBox.shrink()
        : metric(
            context.l10n.settings_availableBalance,
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: subscription.anlasBalance.toString().replaceAllMapped(
                      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                      (m) => '${m[1]},',
                    ),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ' Anlas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
    final expiry = subscription == null
        ? const SizedBox.shrink()
        : metric(
            context.l10n.settings_subscriptionExpiry2,
            subscription.tier > 0 && subscription.expiresAt != null
                ? SubscriptionExpiryText(
                    expiresAt: subscription.expiresAt!,
                    fontSize: 13,
                    subdued: true,
                  )
                : Text(
                    status!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                    ),
                  ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: subscription == null
              ? Text(
                  state.isError
                      ? context.l10n.settings_subscriptionDetailsUnavailable
                      : context.l10n.settings_loadingSubscriptionDetails,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth <
                        500 * MediaQuery.textScalerOf(context).scale(1)) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [balance, const SizedBox(height: 16), expiry],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: balance),
                        Container(
                          width: 1,
                          height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          color: colors.outlineVariant.withValues(alpha: .5),
                        ),
                        Expanded(child: expiry),
                      ],
                    );
                  },
                ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final labels = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (status != null)
                    Text(
                      status,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.settings_localDataStaysAvailableAfter,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              );
              if (constraints.maxWidth <
                  500 * MediaQuery.textScalerOf(context).scale(1)) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    labels,
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: credentialAction,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: labels),
                  const SizedBox(width: 16),
                  credentialAction,
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
