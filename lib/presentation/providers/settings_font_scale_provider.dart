import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/storage/local_storage_service.dart';

final settingsFontScaleProvider =
    NotifierProvider<SettingsFontScaleNotifier, double>(
      SettingsFontScaleNotifier.new,
    );

/// Prototype typography starts at 100%; explicit settings scaling stays local.
class SettingsFontScaleNotifier extends Notifier<double> {
  static const baselineScale = 1.0;
  static double effectiveScale(double relative) => baselineScale * relative;

  @override
  double build() {
    final value = ref
        .read(localStorageServiceProvider)
        .getSetting(StorageKeys.settingsFontScale);
    return value is num && value.isFinite ? value.toDouble().clamp(.8, 1.5) : 1;
  }

  Future<void> setFontScale(double relative) async {
    final value = (.8 + ((relative.clamp(.8, 1.5) - .8) / .1).round() * .1)
        .clamp(.8, 1.5);
    await ref
        .read(localStorageServiceProvider)
        .setSetting(StorageKeys.settingsFontScale, value);
    state = value;
  }

  Future<void> reset() => setFontScale(1);
}
