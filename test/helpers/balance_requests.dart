import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_user_info_api_service.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';

/// The balance is asked only at start-up, on a login or an account switch,
/// on a click and right before a stale cached value would mislead the user
/// (user decision, 2026-10-31). Work that costs Anlas asks nothing after it.
///
/// The request after billed work that was removed went out 0.5 s after the
/// work ended (`schedulePostBillingRefresh`); a test that waits this long
/// after the work sees such a request, if one comes back.
const afterBilledWork = Duration(seconds: 1);

/// What `GET /user/subscription` answers: a paying account (not Opus), so
/// every image costs Anlas.
Map<String, dynamic> balanceAnswer(int balance) => {
  'tier': 1,
  'active': true,
  'trainingStepsLeft': {
    'fixedTrainingStepsLeft': balance,
    'purchasedTrainingSteps': 0,
  },
};

/// NovelAI's balance endpoint, counting every request whatever asks it (the
/// start-up fetch, a click, a recheck, a request after billed work).
class BalanceRequests extends NAIUserInfoApiService {
  BalanceRequests({this.balance = 5000})
    : super(Dio(), NaiApiEndpointService());
  int balance;
  int requests = 0;

  @override
  Future<Map<String, dynamic>> getUserSubscription({
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) async {
    requests++;
    return balanceAnswer(balance);
  }
}

/// Logged in; the token validation brought the balance along (it asks the
/// same endpoint), so the real balance notifier starts without a request.
class ValidatedBalanceAuth extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    accountId: 'synthetic-account',
    displayName: 'Synthetic account',
    subscriptionInfo: balanceAnswer(5000),
  );
}

class QuietBalanceAccounts extends AccountManagerNotifier {
  @override
  AccountManagerState build() => const AccountManagerState(isLoading: false);

  @override
  Future<void> updateSubscriptionExpiry(String accountId, int? expiresAt) =>
      Future.value();
}

/// The real balance notifier, logged in, asking [balances]. Leave
/// `subscriptionNotifierProvider` itself unoverridden, and read it before the
/// work, as the screens keep it.
List<Override> realBalanceOverrides(
  BalanceRequests balances, {
  AuthNotifier Function() auth = ValidatedBalanceAuth.new,
}) => [
  authNotifierProvider.overrideWith(auth),
  naiUserInfoApiServiceProvider.overrideWithValue(balances),
  accountManagerNotifierProvider.overrideWith(QuietBalanceAccounts.new),
];
