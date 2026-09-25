import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/subscription_expiry_utils.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/widgets/settings/account_detail_tile.dart';

class _MockAccountManagerNotifier extends AccountManagerNotifier {
  final SavedAccount _account;

  _MockAccountManagerNotifier(this._account);

  @override
  AccountManagerState build() {
    return AccountManagerState(isLoading: false, accounts: [_account]);
  }
}

class _MockAuthNotifier extends AuthNotifier {
  final String _accountId;

  _MockAuthNotifier(this._accountId);

  @override
  AuthState build() {
    return AuthState(
      status: AuthStatus.authenticated,
      accountId: _accountId,
      displayName: 'TestUser',
    );
  }
}

class _MockSubscriptionNotifier extends SubscriptionNotifier {
  final UserSubscription _subscription;

  _MockSubscriptionNotifier(this._subscription);

  @override
  SubscriptionState build() {
    return SubscriptionState.loaded(_subscription);
  }
}

void main() {
  final now = DateTime.now();

  Widget buildTestWidget({
    required SavedAccount account,
    required UserSubscription subscription,
  }) {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _MockAuthNotifier(account.id)),
        accountManagerNotifierProvider.overrideWith(
          () => _MockAccountManagerNotifier(account),
        ),
        subscriptionNotifierProvider.overrideWith(
          () => _MockSubscriptionNotifier(subscription),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AccountDetailTile()),
      ),
    );
  }

  testWidgets('tier == 0 (Paper) 即使有 expiresAt 也不显示到期徽章', (tester) async {
    final account = SavedAccount.create(
      email: 'paper@example.com',
      nickname: 'PaperUser',
    );
    final subscription = UserSubscription(
      tier: 0,
      active: false,
      expiresAt:
          now.add(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000,
    );

    await tester.pumpWidget(
      buildTestWidget(account: account, subscription: subscription),
    );
    await tester.pumpAndSettle();

    // Paper 没有有效订阅：等级徽章显示「无订阅」而不是等级名
    expect(find.text('无订阅'), findsOneWidget);
    expect(find.text('Paper'), findsNothing);
    // 不应有到期相关的徽章文案
    expect(find.textContaining('剩 '), findsNothing);
    expect(find.text('已过期'), findsNothing);
  });

  testWidgets('tier > 0 且临期 (≤7 天) 显示到期徽章及告警颜色', (tester) async {
    final account = SavedAccount.create(
      email: 'opus@example.com',
      nickname: 'OpusUser',
    );
    final expiryDate = now.add(const Duration(days: 5));
    final expiresAt = expiryDate.millisecondsSinceEpoch ~/ 1000;
    final expiryInfo = getSubscriptionExpiryInfo(expiresAt);

    final subscription = UserSubscription(
      tier: 3,
      active: true,
      expiresAt: expiresAt,
    );

    await tester.pumpWidget(
      buildTestWidget(account: account, subscription: subscription),
    );
    await tester.pumpAndSettle();

    expect(find.text('Opus'), findsOneWidget);
    final badgeFinder = find.text('剩 ${expiryInfo.daysLeft} 天');
    expect(badgeFinder, findsOneWidget);

    final textWidget = tester.widget<Text>(badgeFinder);
    expect(textWidget.style?.color, Colors.orange);
  });

  testWidgets('tier > 0 且已过期 显示已过期徽章及 error 颜色', (tester) async {
    final account = SavedAccount.create(
      email: 'scroll@example.com',
      nickname: 'ScrollUser',
    );
    final pastDate = now.subtract(const Duration(days: 3));
    final expiresAt = pastDate.millisecondsSinceEpoch ~/ 1000;

    final subscription = UserSubscription(
      tier: 2,
      active: false,
      expiresAt: expiresAt,
    );

    await tester.pumpWidget(
      buildTestWidget(account: account, subscription: subscription),
    );
    await tester.pumpAndSettle();

    // 订阅已过期：等级徽章显示「无订阅」，到期徽章仍提示已过期
    expect(find.text('无订阅'), findsOneWidget);
    expect(find.text('Scroll'), findsNothing);
    final expiredBadge = find.text('已过期');
    expect(expiredBadge, findsOneWidget);

    final textWidget = tester.widget<Text>(expiredBadge);
    final BuildContext context = tester.element(expiredBadge);
    final expectedErrorColor = Theme.of(context).colorScheme.error;
    expect(textWidget.style?.color, expectedErrorColor);
  });

  testWidgets('tier > 0 且处于宽限期 显示宽限期徽章', (tester) async {
    final account = SavedAccount.create(
      email: 'tablet@example.com',
      nickname: 'TabletUser',
    );
    final pastDate = now.subtract(const Duration(days: 1));
    final expiresAt = pastDate.millisecondsSinceEpoch ~/ 1000;

    final subscription = UserSubscription(
      tier: 1,
      active: false,
      isGracePeriod: true,
      expiresAt: expiresAt,
    );

    await tester.pumpWidget(
      buildTestWidget(account: account, subscription: subscription),
    );
    await tester.pumpAndSettle();

    // 到期时间已过即不算有效订阅（与网页端一致），宽限期由到期徽章提示
    expect(find.text('无订阅'), findsOneWidget);
    expect(find.text('Tablet'), findsNothing);
    final graceBadge = find.text('宽限期');
    expect(graceBadge, findsOneWidget);

    final textWidget = tester.widget<Text>(graceBadge);
    expect(textWidget.style?.color, Colors.orange);
  });
}
