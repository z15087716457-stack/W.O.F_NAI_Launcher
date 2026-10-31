import 'package:flutter/material.dart';
import '../kit/ui_colors.dart';
import 'agent_contract.dart';

/// UI-only navigation. It never edits a Pi branch or makes a host request.
class AgentThreadNavigation {
  Future<bool> Function(AgentHistoryEntry)? jump;
  Future<void> Function()? latest;
  final visible = ValueNotifier<Set<String>>({});
  final highlight = ValueNotifier<Object?>(null);
  final turns = <String, GlobalKey>{};
  final users = <String, GlobalKey>{};
  final blocks = <(String, int), GlobalKey>{};
  void dispose() {
    visible.dispose();
    highlight.dispose();
  }
}

class AgentNavigationScope extends InheritedWidget {
  const AgentNavigationScope({
    super.key,
    required this.navigation,
    required super.child,
  });
  final AgentThreadNavigation navigation;
  static AgentThreadNavigation? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AgentNavigationScope>()
      ?.navigation;
  @override
  bool updateShouldNotify(AgentNavigationScope oldWidget) =>
      navigation != oldWidget.navigation;
}

class AgentTurnNavigationScope extends InheritedWidget {
  const AgentTurnNavigationScope({
    super.key,
    required this.turnId,
    required this.blocks,
    required super.child,
  });
  final String turnId;
  final List<AgentBlock> blocks;
  @override
  bool updateShouldNotify(AgentTurnNavigationScope oldWidget) =>
      turnId != oldWidget.turnId || blocks != oldWidget.blocks;
}

Widget agentBlockAnchor(BuildContext context, AgentBlock? block, Widget child) {
  final nav = AgentNavigationScope.of(context);
  if (nav == null || block == null || block is AgentTextBlock) return child;
  final scope = context
      .dependOnInheritedWidgetOfExactType<AgentTurnNavigationScope>()!;
  final target = (scope.turnId, scope.blocks.indexOf(block));
  return AgentNavigationAnchor(
    navigation: nav,
    target: target,
    anchor: nav.blocks.putIfAbsent(target, GlobalKey.new),
    child: child,
  );
}

class AgentNavigationAnchor extends StatelessWidget {
  const AgentNavigationAnchor({
    super.key,
    required this.navigation,
    required this.target,
    required this.anchor,
    required this.child,
  });
  final AgentThreadNavigation navigation;
  final Object target;
  final GlobalKey anchor;
  final Widget child;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Object?>(
    valueListenable: navigation.highlight,
    // Prototype `.jump`: 2px accent ring + 6px soft halo, fading out after.
    builder: (context, value, _) {
      final on = value == target;
      final accent = context.ui.accent;
      return AnimatedContainer(
        key: anchor,
        duration: Duration(milliseconds: on ? 0 : 1200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: on ? accent : accent.withValues(alpha: 0),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: accent.withValues(alpha: on ? .16 : 0),
              spreadRadius: 6,
            ),
          ],
        ),
        child: child,
      );
    },
  );
}
