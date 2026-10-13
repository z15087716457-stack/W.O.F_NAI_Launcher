import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/nai_agent/nai_agent_window_controller.dart';
import '../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../widgets/nai_agent/nai_agent_dock.dart';

/// The application enables its existing runtime around the router. Standalone
/// page adapters remain usable without initializing a personal Agent store.
class NaiAgentIntegrationScope extends InheritedWidget {
  const NaiAgentIntegrationScope({super.key, required super.child});

  static bool activeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NaiAgentIntegrationScope>() !=
      null;

  @override
  bool updateShouldNotify(NaiAgentIntegrationScope oldWidget) => false;
}

class NaiAgentGenerationHost extends ConsumerWidget {
  const NaiAgentGenerationHost({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!NaiAgentIntegrationScope.activeOf(context)) return child;
    final window = ref.watch(naiAgentWindowControllerProvider);
    final expanded = ref.watch(
      naiAgentUiPreferencesProvider.select(
        (value) => value.settings.panelExpanded,
      ),
    );
    if (!expanded) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (window.docked) {
          return Row(
            children: [
              Expanded(child: child),
              NaiAgentDock(maxWidth: constraints.maxWidth - 8),
            ],
          );
        }
        return Stack(
          children: [
            Positioned.fill(child: child),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: NaiAgentDock(
                maxWidth: constraints.maxWidth,
                resizable: false,
              ),
            ),
          ],
        );
      },
    );
  }
}
