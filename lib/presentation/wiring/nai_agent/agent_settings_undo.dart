import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/nai_agent/settings_tools.dart';
import '../../../core/settings/settings_preferences_service.dart';
import '../../providers/nai_agent/nai_agent_settings_binding.dart';
import 'agent_settings_card.dart';

class AgentSettingsUndo {
  AgentSettingsUndo(this.tools);
  final NaiAgentSettingsTools tools;

  Future<bool> restore(AgentSettingsRestore change) async {
    if (!tools.isAlive()) return false;
    final current = tools.service.capture();
    if (!change.matches(current)) return false;
    try {
      await tools.service.apply(
        {for (final key in change.fields) key: change.before[key]},
        expected: current,
        beforeWrite: () {
          if (!tools.isAlive()) throw StateError('Settings binding closed');
        },
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      if (tools.isAlive()) tools.refresh();
    }
  }
}

/// Listen to persisted preference writes without constructing every Settings
/// page provider. A user edit locks an old card even while Agent is idle.
final agentPreferencesProvider = Provider<Map<String, Object?>>((ref) {
  if (Hive.isBoxOpen(StorageKeys.settingsBox)) {
    final subscription = Hive.box(StorageKeys.settingsBox).watch().listen((
      event,
    ) {
      if (SettingsPreferencesService.keys.contains(event.key)) {
        ref.invalidateSelf();
      }
    });
    ref.onDispose(subscription.cancel);
  }
  return SettingsPreferencesService(
    ref.watch(localStorageServiceProvider),
  ).capture();
});

/// Reuses the native preference backup and the binding's single refresh list.
final agentSettingsUndoProvider = Provider.family<AgentSettingsUndo, String>((
  ref,
  path,
) {
  var alive = true;
  ref.onDispose(() => alive = false);
  return AgentSettingsUndo(
    bindNaiAgentSettings(ref, Directory(path), () => alive),
  );
});
