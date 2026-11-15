import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nai_agent_workspace_provider.dart';

/// Read the current UI-owned choice without starting a closed Agent session.
bool naiAgentCanAutoApproveCost(Ref ref, int totalAnlas) {
  if (!ref.exists(naiAgentUiPreferencesProvider)) return false;
  final settings = ref.read(naiAgentUiPreferencesProvider).settings;
  return settings.permissionMode == 'bypass' &&
      (totalAnlas == 0 || totalAnlas > 0 && settings.skipPaidConfirmation);
}
