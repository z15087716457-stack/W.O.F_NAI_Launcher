import '../../data/models/user/user_subscription.dart';
import '../../l10n/app_localizations.dart';

/// Shared by the generation header and compact/mobile quota cells.
String opusUsageTooltip(AppLocalizations l, OpusUsage usage) {
  final seconds = usage.timeUntilNextPercent;
  final time = seconds >= 3600
      ? l.opusUsage_hoursMinutes(seconds ~/ 3600, (seconds % 3600) ~/ 60)
      : seconds >= 60
      ? l.opusUsage_minutesSeconds(seconds ~/ 60, seconds % 60)
      : l.opusUsage_seconds(seconds);
  return [
    l.opusUsage_regularRemaining(usage.regularPercent.toStringAsFixed(1)),
    l.opusUsage_reserveRemaining(usage.reservePercent.toStringAsFixed(1)),
    if (usage.isNegative)
      l.opusUsage_exhausted
    else if (usage.isUsingReserve)
      l.opusUsage_usingReserve
    else if (usage.regularPercent == 0)
      l.opusUsage_regularEmpty
    else
      l.opusUsage_usingRegular,
    seconds > 0 ? l.opusUsage_recharging(time) : l.opusUsage_notRecharging,
    l.opusUsage_clickToRefresh,
  ].join('\n');
}
