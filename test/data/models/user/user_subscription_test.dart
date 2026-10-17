import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';

void main() {
  group('Opus quota pools', () {
    test(
      'parses activated backup quota and retains legacy response defaults',
      () {
        final subscription = UserSubscription.fromJson({
          'usage': {'percent': 12.5, 'purchasedPercent': 250.25},
        });
        final usage = subscription.usage!;
        expect(usage.purchasedPercent, 250.25);
        expect(usage.activePercent, 12.5);
        expect(usage.isUsingReserve, isFalse);
        expect(OpusUsage.fromJson(usage.toJson()), usage);
        expect(usage.copyWith(purchasedPercent: 200).purchasedPercent, 200);
        expect(OpusUsage.fromJson({'percent': 140}).reservePercent, 0);
        expect(
          OpusUsage.fromJson({'purchasedPercent': null}).reservePercent,
          0,
        );
      },
    );

    for (final (name, usage, regular, active, reserveActive) in [
      (
        'regular first',
        const OpusUsage(percent: 1, purchasedPercent: 200),
        1,
        1,
        false,
      ),
      (
        'reserve after zero',
        const OpusUsage(purchasedPercent: 200.5),
        0,
        200.5,
        true,
      ),
      ('small reserve', const OpusUsage(purchasedPercent: .25), 0, .25, true),
      ('both zero', const OpusUsage(), 0, 0, false),
      (
        'regular above 100',
        const OpusUsage(percent: 140, purchasedPercent: 400),
        140,
        140,
        false,
      ),
      (
        'negative amount',
        const OpusUsage(percent: -2, purchasedPercent: 30),
        0,
        30,
        true,
      ),
      (
        'invalid reserve',
        const OpusUsage(percent: 4, purchasedPercent: -10),
        4,
        4,
        false,
      ),
      (
        'server exhausted',
        const OpusUsage(percent: 2, purchasedPercent: 100, isNegative: true),
        0,
        0,
        false,
      ),
    ]) {
      test('selects active pool: $name', () {
        expect(usage.regularPercent, regular);
        expect(usage.activePercent, active);
        expect(usage.isUsingReserve, reserveActive);
        expect(usage.displayPercent, active.clamp(0, 100));
        // The server's exhaustion flag remains authoritative for billing.
        expect(
          UserSubscription(usage: usage).isOpusUsageExhausted,
          usage.isNegative,
        );
      });
    }

    test(
      'regular recharge takes priority again without consuming backup locally',
      () {
        const reserve = OpusUsage(
          purchasedPercent: 150,
          timeUntilNextPercent: 20,
        );
        final refilled = reserve.copyWith(percent: 1);
        expect(reserve.isUsingReserve, isTrue);
        expect(refilled.isUsingReserve, isFalse);
        expect(refilled.activePercent, 1);
        expect(refilled.reservePercent, 150);
      },
    );

    test(
      'invalid non-finite display values do not reach percentage formatters',
      () {
        const usage = OpusUsage(
          percent: double.nan,
          purchasedPercent: double.infinity,
        );
        expect(usage.activePercent, 0);
        expect(usage.reservePercent, 0);
        expect(usage.isUsingReserve, isFalse);
      },
    );
  });

  group('UserSubscription balance parsing', () {
    test(
      'supports both current object and legacy numeric balance payloads',
      () {
        final current = UserSubscription.fromJson({
          'trainingStepsLeft': {
            'fixedTrainingStepsLeft': 80,
            'purchasedTrainingSteps': 25,
          },
        });
        final legacy = UserSubscription.fromJson({'trainingStepsLeft': 70});

        expect(current.anlasBalance, 105);
        expect(legacy.anlasBalance, 70);
      },
    );
  });

  group('UserSubscription Opus eligibility', () {
    test('uses the server expiry timestamp when it is available', () {
      final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      expect(
        UserSubscription(
          tier: 3,
          active: false,
          expiresAt: nowInSeconds + 60,
        ).isOpus,
        isTrue,
      );
      expect(
        UserSubscription(
          tier: 3,
          active: true,
          expiresAt: nowInSeconds - 60,
        ).isOpus,
        isFalse,
      );
    });

    test('keeps privileged accounts active and supports legacy responses', () {
      expect(
        const UserSubscription(tier: 3, accountType: 4, expiresAt: 0).isOpus,
        isTrue,
      );
      expect(const UserSubscription(tier: 3, active: true).isOpus, isTrue);
    });
  });
}
