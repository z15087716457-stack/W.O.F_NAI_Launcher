import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/nai_agent/nai_agent_window_controller.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../ui/agent/agent_glyphs.dart';
import '../../widgets/common/app_toast.dart';
import 'agent_toggle_badge.dart';

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
        // 只在 Agent 已经启动过后看角标：别为了画一个点在启动时就初始化控制器。
        // 第一次展开侧栏会创建控制器并通知窗口控制器，这里随之重建。
        badge: ref.exists(naiAgentControllerProvider)
            ? ref.watch(agentToggleBadgeProvider)
            : AgentToggleBadge.none,
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
