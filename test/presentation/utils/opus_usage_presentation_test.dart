import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/utils/opus_usage_presentation.dart';

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    final l = lookupAppLocalizations(locale);
    test('separates both pools and state in $locale', () {
      final regular = opusUsageTooltip(
        l,
        const OpusUsage(percent: 140, purchasedPercent: 200),
      );
      expect(regular, contains(l.opusUsage_regularRemaining('140.0')));
      expect(regular, contains(l.opusUsage_reserveRemaining('200.0')));
      expect(regular, contains(l.opusUsage_usingRegular));
      expect(regular, isNot(contains(l.opusUsage_usingReserve)));
      final reserve = opusUsageTooltip(
        l,
        const OpusUsage(purchasedPercent: 150, timeUntilNextPercent: 90),
      );
      expect(reserve, contains(l.opusUsage_regularRemaining('0.0')));
      expect(reserve, contains(l.opusUsage_reserveRemaining('150.0')));
      expect(reserve, contains(l.opusUsage_usingReserve));
      expect(
        reserve,
        contains(l.opusUsage_recharging(l.opusUsage_minutesSeconds(1, 30))),
      );
      expect(reserve, isNot(contains(l.opusUsage_exhausted)));
      expect(reserve, isNot(contains('{percent}')));
      expect(reserve, isNot(contains('{time}')));
      final exhausted = opusUsageTooltip(
        l,
        const OpusUsage(percent: 5, isNegative: true),
      );
      expect(exhausted, contains(l.opusUsage_exhausted));
      expect(exhausted, contains(l.opusUsage_notRecharging));
      expect(
        opusUsageTooltip(l, const OpusUsage()),
        contains(l.opusUsage_regularEmpty),
      );
    });
  }

  test('recharge times cover seconds, minutes and hours', () {
    final l = lookupAppLocalizations(const Locale('zh'));
    for (final (seconds, time) in [
      (42, l.opusUsage_seconds(42)),
      (60, l.opusUsage_minutesSeconds(1, 0)),
      (7200, l.opusUsage_hoursMinutes(2, 0)),
    ]) {
      expect(
        opusUsageTooltip(
          l,
          OpusUsage(percent: 20, timeUntilNextPercent: seconds),
        ),
        contains(l.opusUsage_recharging(time)),
      );
    }
  });
}
