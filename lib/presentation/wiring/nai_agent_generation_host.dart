import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/nai_agent/panel_layout.dart';
import '../providers/nai_agent/nai_agent_window_controller.dart';
import '../widgets/nai_agent/nai_agent_shared.dart';
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

class NaiAgentGenerationHost extends ConsumerStatefulWidget {
  const NaiAgentGenerationHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<NaiAgentGenerationHost> createState() => _GenerationHostState();
}

class _GenerationHostState extends ConsumerState<NaiAgentGenerationHost>
    with SingleTickerProviderStateMixin {
  late final _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 220),
  );
  bool _expanded = false, _opened = false, _wasNative = false;
  bool _waitingNativeSurface = false;
  double _closedWidth = 0;
  double? _dragWidth;
  int _dragRevision = 0;

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!NaiAgentIntegrationScope.activeOf(context)) return widget.child;
    final window = ref.watch(naiAgentWindowControllerProvider);
    final settings = ref.watch(naiAgentUiPreferencesProvider).settings;
    final expanded = window.presentationExpanded ?? settings.panelExpanded;
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_wasNative &&
        !window.nativeReveal &&
        _waitingNativeSurface &&
        expanded &&
        !reduced) {
      _reveal.forward(from: 0);
    }
    if (expanded != _expanded) {
      _expanded = expanded;
      _opened |= expanded;
      if (reduced || window.nativeReveal) {
        _reveal.value = expanded ? 1 : 0;
      } else if (expanded) {
        _reveal.forward();
      } else {
        _reveal.reverse();
      }
    } else if (reduced && _reveal.isAnimating) {
      _reveal.value = expanded ? 1 : 0;
    }
    _wasNative = window.nativeReveal;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!expanded && !_reveal.isAnimating) {
            _closedWidth = constraints.maxWidth;
          }
          final width = AgentPanelLayout.resolve(
            _dragWidth ?? settings.panelWidth,
            constraints.maxWidth,
          );
          final waitingForSurface =
              _wasNative &&
              expanded &&
              window.openingGrowth > 0 &&
              _closedWidth > 0 &&
              constraints.maxWidth < _closedWidth + window.openingGrowth - 2;
          _waitingNativeSurface = waitingForSurface;
          return AnimatedBuilder(
            animation: _reveal,
            child: widget.child,
            builder: (context, child) {
              final fraction = waitingForSurface
                  ? 0.0
                  : Curves.easeOutCubic.transform(_reveal.value);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Same element, position and parent for every transition.
                  Expanded(child: child!),
                  SizedBox(
                    key: const Key('nai-agent-reveal'),
                    width: (width + AgentPanelLayout.handle) * fraction,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: width + AgentPanelLayout.handle,
                        maxWidth: width + AgentPanelLayout.handle,
                        child: Offstage(
                          offstage: fraction == 0,
                          child: TickerMode(
                            enabled: expanded,
                            child: ExcludeFocus(
                              excluding: !expanded,
                              child: IgnorePointer(
                                ignoring: !expanded,
                                child: _opened
                                    ? NaiAgentDock(
                                        width: width,
                                        onDragStart: () {
                                          _dragRevision++;
                                          setState(() => _dragWidth = width);
                                        },
                                        onDrag: (dx) => setState(() {
                                          _dragWidth = AgentPanelLayout.resolve(
                                            (_dragWidth ?? width) - dx,
                                            constraints.maxWidth,
                                          );
                                        }),
                                        onDragCancel: () =>
                                            setState(() => _dragWidth = null),
                                        onDragEnd: () {
                                          final revision = _dragRevision;
                                          final preferred = _dragWidth ?? width;
                                          agentUiAction(context, () async {
                                            await ref
                                                .read(
                                                  naiAgentControllerProvider,
                                                )
                                                .updateSettings({
                                                  'panelWidth': preferred,
                                                });
                                            if (mounted &&
                                                revision == _dragRevision) {
                                              setState(() => _dragWidth = null);
                                            }
                                          });
                                        },
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
