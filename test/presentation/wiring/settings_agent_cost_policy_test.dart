import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_cost_policy.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_edits.dart';

final policy = Provider<bool Function(int)>(
  (ref) =>
      (cost) => naiAgentCanAutoApproveCost(ref, cost),
);

void main() {
  test(
    'only Full access can skip confirmations; missing and invalid costs cannot grant approval',
    () {
      final container = ProviderContainer(
        overrides: [
          naiAgentUiPreferencesProvider.overrideWith(
            (ref) => NaiAgentUiPreferences(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final canSkip = container.read(policy);
      expect(canSkip(0), isFalse);
      expect(container.exists(naiAgentUiPreferencesProvider), isFalse);
      final preferences = container.read(naiAgentUiPreferencesProvider);
      for (final mode in ['auto', 'ask', 'readonly', 'bypass']) {
        for (final skipPaid in [false, true]) {
          preferences.replace(
            AgentSettings(permissionMode: mode, skipPaidConfirmation: skipPaid),
          );
          for (final cost in [-1, 0, 5]) {
            expect(
              canSkip(cost),
              mode == 'bypass' && (cost == 0 || cost > 0 && skipPaid),
              reason: '$mode / $skipPaid / $cost',
            );
          }
        }
      }
      expect(container.exists(naiAgentControllerProvider), isFalse);
    },
  );

  test(
    'paid opt-out defaults off, persists from settings and restores without starting an Agent',
    () async {
      final root = await Directory.systemTemp.createTemp('agent-cost-policy-');
      final store = AgentWorkspaceStore(root);
      final container = ProviderContainer(
        overrides: [
          naiAgentWorkspaceStoreProvider.overrideWithValue(store),
          naiAgentUiPreferencesProvider.overrideWith(
            (ref) => NaiAgentUiPreferences(),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await root.delete(recursive: true);
      });
      expect(const AgentSettings().skipPaidConfirmation, isFalse);
      expect(AgentSettings.fromJson({}).skipPaidConfirmation, isFalse);
      expect(
        AgentSettings.fromJson({
          'skipPaidConfirmation': 'true',
        }).skipPaidConfirmation,
        isFalse,
      );
      const key = SettingKey.agentSkipPaidConfirmation;
      expect(SettingSpec.of(key).defaultValue, false);
      await store.patchSettings({
        'permissionMode': 'bypass',
        'globalInstructions': 'keep me',
      });
      final preferences = container.read(naiAgentUiPreferencesProvider);
      await preferences.load(store);
      final values = container.read(settingsValueStoreProvider);
      await values.write(key, true);
      expect((await store.readSettings()).skipPaidConfirmation, isTrue);
      expect(preferences.settings.skipPaidConfirmation, isTrue);
      final restored = await AgentWorkspaceStore(root).readSettings();
      expect(restored.skipPaidConfirmation, isTrue);
      expect(
        restored.copyWith(permissionMode: 'ask').skipPaidConfirmation,
        isTrue,
      );
      await values.write(key, SettingSpec.of(key).defaultValue);
      final reset = await store.readSettings();
      expect(reset.skipPaidConfirmation, isFalse);
      expect(reset.globalInstructions, 'keep me');
      expect(reset.permissionMode, 'bypass');
      expect(container.exists(naiAgentControllerProvider), isFalse);
    },
  );
}
