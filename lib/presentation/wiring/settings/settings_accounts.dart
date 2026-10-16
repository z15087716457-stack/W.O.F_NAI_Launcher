import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/auth/saved_account.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/auth/account_switch_helper.dart';
import '../../widgets/auth/add_account_dialog.dart';
import '../../widgets/settings/account_credentials_dialog.dart';
import '../../widgets/settings/account_profile_sheet.dart';
import '../../ui/settings/settings_contract.dart';

/// Unknown subscription/balance stay null.
/// Reading settings never logs into every saved account to fill its row.
class SettingsAccountFact {
  const SettingsAccountFact({
    required this.account,
    required this.current,
    required this.credentialExpired,
    this.balance,
    this.tier,
  });
  final SavedAccount account;
  final bool current, credentialExpired;
  final int? balance, tier;
}

List<SettingsAccountFact> settingsAccountFacts(WidgetRef ref) {
  final accounts = ref.watch(accountManagerNotifierProvider).accounts;
  final auth = ref.watch(authNotifierProvider);
  final subscription = ref.watch(subscriptionNotifierProvider);
  return [
    for (final account in accounts)
      SettingsAccountFact(
        account: account,
        current: auth.isAuthenticated && account.id == auth.accountId,
        balance: auth.isAuthenticated && account.id == auth.accountId
            ? subscription.balance
            : null,
        tier: auth.isAuthenticated && account.id == auth.accountId
            ? subscription.subscription?.tier
            : null,
        credentialExpired:
            account.id == auth.accountId &&
            const {
              AuthErrorCode.authFailed,
              AuthErrorCode.tokenInvalid,
              AuthErrorCode.credentialsLoginUnavailable,
            }.contains(auth.errorCode),
      ),
  ];
}

SettingsAccountData settingsAccountsData(
  List<SettingsAccountFact> facts, {
  int todayUsed = 0,
}) {
  final current = facts.where((fact) => fact.current).firstOrNull;
  return SettingsAccountData(
    monthlyAnlas: switch (current?.tier) {
      3 => 10000,
      1 || 2 => 1000,
      _ => 0,
    },
    todayUsed: todayUsed,
    accounts: [
      for (final fact in facts)
        SettingsAccount(
          id: fact.account.id,
          name: fact.account.displayName,
          tier: switch (fact.tier) {
            null => null,
            1 => SettingsTier.tablet,
            2 => SettingsTier.scroll,
            3 => SettingsTier.opus,
            _ => SettingsTier.none,
          },
          anlas: fact.balance,
          loginKind: fact.account.accountType == AccountType.credentials
              ? SettingsLoginKind.email
              : SettingsLoginKind.token,
          maskedId: fact.account.accountType == AccountType.credentials
              ? _maskedEmail(fact.account.email)
              : '',
          current: fact.current,
          isDefault: fact.account.isDefault,
          lastUsedAt: fact.account.lastUsedAt,
          expired: fact.credentialExpired,
          renewsAt: fact.account.subscriptionExpiresAt == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  fact.account.subscriptionExpiresAt! * 1000,
                ),
        ),
    ],
  );
}

String _maskedEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return '••••';
  return '${email.substring(0, at > 2 ? 2 : 1)}••••@••••';
}

class SettingsAccountActions {
  SettingsAccountActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;
  SavedAccount account(String id) => ref
      .read(accountManagerNotifierProvider)
      .accounts
      .firstWhere((a) => a.id == id);
  Future<void> add() => AddAccountDialog.show(context, ref);
  Future<void> switchTo(String id) =>
      AccountSwitchHelper.switchToAccount(context, ref, account(id));
  Future<void> edit(String id) =>
      AccountProfileBottomSheet.show(context: context, account: account(id));
  Future<void> credentials(String id) async {
    final selected = account(id);
    await showDialog<bool>(
      context: context,
      builder: (_) => AccountCredentialsDialog(account: selected),
    );
  }

  Future<void> delete(String id) async {
    account(id);
    final original = ref.read(authNotifierProvider);
    await ref.read(accountManagerNotifierProvider.notifier).removeAccount(id);
    if (!context.mounted || original.accountId != id) return;
    await SchedulerBinding.instance.endOfFrame;
    if (context.mounted &&
        identical(ref.read(authNotifierProvider), original)) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  Future<void> portal() async {
    await launchUrl(
      Uri.parse('https://novelai.net'),
      mode: LaunchMode.externalApplication,
    );
  }
}
