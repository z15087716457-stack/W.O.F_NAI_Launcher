import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/nai_agent/nai_agent_window_controller.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../ui/agent/agent_glyphs.dart';
import '../../widgets/common/app_toast.dart';

class AgentToggleWiring extends ConsumerWidget {
  const AgentToggleWiring({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(naiAgentWindowControllerProvider);
    final expanded =
        window.presentationExpanded ??
        (ref.watch(naiAgentUiPreferencesProvider).settings.panelExpanded);
    return KeyedSubtree(
      key: const Key('nai-agent-toggle'),
      child: AgentToggleButton(
        expanded: expanded,
        tooltip: context.l10n.naiAgent_title,
        onPressed: () => unawaited(
          window.toggle().catchError((Object _) {
            if (context.mounted) {
              AppToast.error(context, context.l10n.naiAgent_error);
            }
          }),
        ),
      ),
    );
  }
}
