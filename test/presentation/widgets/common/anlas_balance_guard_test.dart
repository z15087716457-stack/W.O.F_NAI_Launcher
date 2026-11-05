import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/utils/asset_protection_guard.dart';

class _Balance extends SubscriptionNotifier {
  _Balance(this.refreshedBalance);
  final int refreshedBalance;
  int refreshes = 0;

  SubscriptionState _balance(int balance) => SubscriptionState.loaded(
    UserSubscription(
      tier: 2,
      active: true,
      trainingStepsLeft: TrainingStepsInfo(fixedTrainingStepsLeft: balance),
    ),
  );

  @override
  SubscriptionState build() => _balance(2);

  @override
  Future<bool> refreshBalance() async {
    refreshes++;
    state = _balance(refreshedBalance);
    return true;
  }
}

void main() {
  for (final balance in [2, 100]) {
    testWidgets('a low UI balance is checked before blocking ($balance)', (
      t,
    ) async {
      final subscription = _Balance(balance);
      bool? allowed;
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionNotifierProvider.overrideWith(() => subscription),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  ref.watch(subscriptionNotifierProvider);
                  return TextButton(
                    onPressed: () async {
                      allowed = await AssetProtectionGuard.confirmHighAnlasCost(
                        context: context,
                        ref: ref,
                        cost: 12,
                      );
                    },
                    child: const Text('Submit'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Submit'));
      await t.pumpAndSettle();
      expect(subscription.refreshes, 1);
      expect(allowed, balance >= 12);
      await t.pumpWidget(const SizedBox());
    });
  }
}
