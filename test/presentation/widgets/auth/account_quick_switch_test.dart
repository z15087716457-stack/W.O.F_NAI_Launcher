import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/subscription_expiry_utils.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/widgets/auth/account_quick_switch.dart';

class _MockAccountManagerNotifier extends AccountManagerNotifier {
  final List<SavedAccount> _initialAccounts;

  _MockAccountManagerNotifier(this._initialAccounts);

  @override
  AccountManagerState build() {
    return AccountManagerState(isLoading: false, accounts: _initialAccounts);
  }
}

class _MockAuthNotifier extends AuthNotifier {
  final String? _currentAccountId;

  _MockAuthNotifier(this._currentAccountId);

  @override
  AuthState build() {
    return AuthState(
      status: _currentAccountId != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
      accountId: _currentAccountId,
    );
  }
}

void main() {
  testWidgets('账号切换器行展示到期信息：有到期时间与无到期时间', (tester) async {
    final now = DateTime.now();
    // 5 天后（未过期且临期）
    final futureDate = now.add(const Duration(days: 5));
    final futureExpiry = futureDate.millisecondsSinceEpoch ~/ 1000;
    final futureInfo = getSubscriptionExpiryInfo(futureExpiry);

    // 2 天前（已过期）
    final pastDate = now.subtract(const Duration(days: 2));
    final pastExpiry = pastDate.millisecondsSinceEpoch ~/ 1000;
    final pastInfo = getSubscriptionExpiryInfo(pastExpiry);

    final accountWithFuture = SavedAccount.create(
      email: 'future@example.com',
      nickname: 'FutureUser',
      subscriptionExpiresAt: futureExpiry,
    );

    final accountWithPast = SavedAccount.create(
      email: 'past@example.com',
      nickname: 'PastUser',
      subscriptionExpiresAt: pastExpiry,
    );

    final accountWithoutExpiry = SavedAccount.create(
      email: 'noexpiry@example.com',
      nickname: 'NoExpiryUser',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _MockAuthNotifier(accountWithFuture.id),
          ),
          accountManagerNotifierProvider.overrideWith(
            () => _MockAccountManagerNotifier([
              accountWithFuture,
              accountWithPast,
              accountWithoutExpiry,
            ]),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AccountQuickSwitch()),
        ),
      ),
    );

    // 展开 ExpansionTile
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    // 验证 FutureUser 显示到期日期和剩余天数
    expect(find.textContaining(futureInfo.formattedDate), findsOneWidget);
    expect(find.textContaining('剩 ${futureInfo.daysLeft} 天'), findsOneWidget);

    // 验证 PastUser 显示到期日期和已过期
    expect(find.textContaining(pastInfo.formattedDate), findsOneWidget);
    expect(find.textContaining('已过期'), findsOneWidget);

    // 验证整个界面中只有 2 个包含到期提示的 Text
    expect(find.textContaining('到期 '), findsNWidgets(2));
  });
}
