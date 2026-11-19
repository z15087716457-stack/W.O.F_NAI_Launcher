import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/settings/settings_contract.dart';

final settingsRagStartupProvider =
    NotifierProvider<SettingsRagStartup, SettingsRagSourceKind?>(
      SettingsRagStartup.new,
    );

class SettingsRagStartup extends Notifier<SettingsRagSourceKind?> {
  bool _disposed = false;

  @override
  SettingsRagSourceKind? build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return null;
  }

  Future<void> run(
    SettingsRagSourceKind source,
    Future<void> Function() action,
  ) async {
    if (state != null) return;
    state = source;
    try {
      await action();
    } finally {
      if (!_disposed) state = null;
    }
  }
}
