import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/nai_agent/panel_layout.dart';
import '../providers/nai_agent/nai_agent_window_controller.dart';
import '../widgets/nai_agent/nai_agent_shared.dart';
import '../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../widgets/nai_agent/nai_agent_dock.dart';
import '../widgets/common/drag_preview_divider.dart';
import '../widgets/navigation/window_chrome_layout.dart';

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
  const NaiAgentGenerationHost({
    super.key,
    required this.child,
    this.minimumPageWidth = AgentPanelLayout.minimumPage,
  });
  final Widget child;
  final double minimumPageWidth;
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
  ({double viewport, double width})? _openDock;
  ({double target, double shrink, double width})? _closingDock;
  double? _dragWidth;
  final _preview = DragPreviewController();
  int _dragRevision = 0;

  @override
  void dispose() {
    _preview.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!NaiAgentIntegrationScope.activeOf(context)) return widget.child;
    final window = ref.watch(naiAgentWindowControllerProvider);
    final settings = ref.watch(naiAgentUiPreferencesProvider).settings;
    final expanded = window.presentationExpanded ?? settings.panelExpanded;
    final chrome = context
        .dependOnInheritedWidgetOfExactType<WindowChromeScope>();
    final viewport = MediaQuery.sizeOf(context).width;
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
      final open = _openDock;
      _openDock = null;
      final shrink = window.closingShrink;
      _closingDock = !expanded && open != null && shrink != null
          ? (target: open.viewport - shrink, shrink: shrink, width: open.width)
          : null;
      if (_closingDock != null) {
        _reveal.value = 1;
      } else if (reduced || window.nativeReveal) {
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
    double? closingFraction;
    if (_closingDock case final closing?) {
      // Keep the dock's space until the Flutter viewport actually shrinks.
      if (viewport <= closing.target + 1) {
        _closingDock = null;
        _reveal.value = 0;
      } else if (window.closingShrink == null) {
        _closingDock = null;
        if (reduced) {
          _reveal.value = 0;
        } else {
          _reveal.reverse();
        }
      } else {
        closingFraction = ((viewport - closing.target) / closing.shrink).clamp(
          0.0,
          1.0,
        );
      }
    }
    final closingWidth = _closingDock?.width;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!expanded && closingFraction == null && !_reveal.isAnimating) {
            _closedWidth = constraints.maxWidth;
          }
          final width = AgentPanelLayout.resolve(
            _dragWidth ?? settings.panelWidth,
            constraints.maxWidth,
            minimumPageWidth: widget.minimumPageWidth,
          );
          final waitingForSurface =
              _wasNative &&
              expanded &&
              window.openingGrowth > 0 &&
              _closedWidth > 0 &&
              constraints.maxWidth < _closedWidth + window.openingGrowth - 2;
          _waitingNativeSurface = waitingForSurface;
          if (expanded && !waitingForSurface) {
            _openDock = (viewport: viewport, width: width);
          }
          final dockWidth = closingWidth ?? width;
          return AnimatedBuilder(
            animation: _reveal,
            // The Agent owns the rightmost caption area while docked. Keep
            // this wrapper stable so revealing it never remounts the page.
            child: chrome == null
                ? widget.child
                : WindowChromeScope(
                    enabled:
                        chrome.enabled && !expanded && closingFraction == null,
                    draggable: chrome.draggable,
                    extraWidth: chrome.extraWidth,
                    captionHeight: chrome.captionHeight,
                    child: widget.child,
                  ),
            builder: (context, child) {
              final fraction = waitingForSurface
                  ? 0.0
                  : closingFraction ??
                        Curves.easeOutCubic.transform(_reveal.value);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Same element, position and parent for every transition.
                      Expanded(child: child!),
                      SizedBox(
                        key: const Key('nai-agent-reveal'),
                        width: (dockWidth + AgentPanelLayout.handle) * fraction,
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.centerLeft,
                            minWidth: dockWidth + AgentPanelLayout.handle,
                            maxWidth: dockWidth + AgentPanelLayout.handle,
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
                                            width: dockWidth,
                                            onDragStart: () {
                                              _dragRevision++;
                                              _preview.start(
                                                width,
                                                constraints.maxWidth -
                                                    width -
                                                    AgentPanelLayout.handle / 2,
                                              );
                                            },
                                            onDrag: (dx) => _preview.move(
                                              -dx,
                                              resolve: (v) =>
                                                  AgentPanelLayout.resolve(
                                                    v,
                                                    constraints.maxWidth,
                                                    minimumPageWidth:
                                                        widget.minimumPageWidth,
                                                  ),
                                              position: (v) =>
                                                  constraints.maxWidth -
                                                  v -
                                                  AgentPanelLayout.handle / 2,
                                            ),
                                            onDragCancel: _preview.cancel,
                                            onDragEnd: () {
                                              final preferred = _preview
                                                  .finish();
                                              if (preferred == null) return;
                                              final revision = _dragRevision;
                                              setState(
                                                () => _dragWidth = preferred,
                                              );
                                              agentUiAction(context, () async {
                                                await ref
                                                    .read(
                                                      naiAgentControllerProvider,
                                                    )
                                                    .updateSettings({
                                                      'panelWidth': preferred,
                                                    });
                                                if (mounted &&
                                                    revision == _dragRevision &&
                                                    ref
                                                            .read(
                                                              naiAgentUiPreferencesProvider,
                                                            )
                                                            .settings
                                                            .panelWidth ==
                                                        preferred) {
                                                  // Preferences already notify the host;
                                                  // clearing the equal override needs no frame.
                                                  _dragWidth = null;
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
                  ),
                  DragPreviewDivider(
                    key: const Key('nai-agent-resize-preview'),
                    controller: _preview,
                    color: Theme.of(context).colorScheme.primary,
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
