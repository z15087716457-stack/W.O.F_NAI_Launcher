import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/settings/ui_scale_preference.dart';
import '../../core/storage/local_storage_service.dart';

final uiScaleProvider = NotifierProvider<UiScaleController, double>(
  UiScaleController.new,
);

class UiScaleController extends Notifier<double> {
  @override
  double build() => UiScalePreference.read(
    ref.watch(localStorageServiceProvider).getSetting<Object?>,
  );

  Future<void> setScale(double scale) async {
    if (!scale.isFinite) throw ArgumentError.value(scale, 'scale');
    final value = UiScalePreference.normalize(scale);
    await ref
        .read(localStorageServiceProvider)
        .setSetting(StorageKeys.uiScale, value);
    state = value;
  }

  Future<void> reset() => setScale(1);
}
