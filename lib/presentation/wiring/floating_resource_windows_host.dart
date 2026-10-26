import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/localization_extension.dart';
import '../providers/floating_resource_windows_provider.dart';

/// The main agent supplies all window chrome/content. These handles only wire
/// gestures and state; do not wrap the entire content in a pan recognizer.
typedef FloatingResourceWindowBuilder =
    Widget Function(
      BuildContext context,
      FloatingWindowData window,
      FloatingWindowController controller,
    );

class FloatingWindowController {
  FloatingWindowController(this.manager, this.id);
  final FloatingResourceWindows manager;
  final String id;

  FloatingWindowData? get data => manager.window(id);

  void focus() => manager.focus(id);
  void close() => manager.close(id);
  void setQuery(String query) => manager.setQuery(id, query);
  void setScope(FloatingResourceScope scope) => manager.setScope(id, scope);
  void setMinimized(bool minimized) => manager.setMinimized(id, minimized);
  void moveBy(Offset delta) {
    final window = data;
    if (window != null) manager.move(id, window.rect.shift(delta));
  }

  void resizeBy(Offset delta) {
    final window = data;
    if (window != null) {
      manager.resize(
        id,
        Rect.fromLTWH(
          window.rect.left,
          window.rect.top,
          window.rect.width + delta.dx,
          window.rect.height + delta.dy,
        ),
      );
    }
  }

  Widget moveHandle({Key? key, required Widget child}) => GestureDetector(
    key: key,
    behavior: HitTestBehavior.opaque,
    onPanStart: (_) => focus(),
    onPanUpdate: (event) => moveBy(event.delta),
    child: child,
  );
  Widget resizeHandle({Key? key, required Widget child}) => GestureDetector(
    key: key,
    behavior: HitTestBehavior.opaque,
    onPanStart: (_) => focus(),
    onPanUpdate: (event) => resizeBy(event.delta),
    child: child,
  );
}

/// Install once above the router's child, not inside a route. The separate,
/// non-modal overlay gives drag feedback an Overlay ancestor without blocking
/// hit testing outside windows. Its entries survive navigation.
class FloatingResourceWindowsHost extends StatefulWidget {
  const FloatingResourceWindowsHost({
    super.key,
    required this.child,
    this.builder = floatingResourcePlaceholder,
  });
  final Widget child;
  final FloatingResourceWindowBuilder builder;
  @override
  State<FloatingResourceWindowsHost> createState() =>
      _FloatingResourceWindowsHostState();
}

class _FloatingResourceWindowsHostState
    extends State<FloatingResourceWindowsHost> {
  late final _entry = OverlayEntry(
    builder: (_) => _FloatingResourceLayer(builder: widget.builder),
  );
  @override
  void didUpdateWidget(covariant FloatingResourceWindowsHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.builder != widget.builder) _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    _entry.remove();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      Positioned.fill(child: Overlay(initialEntries: [_entry])),
    ],
  );
}

class _FloatingResourceLayer extends ConsumerWidget {
  const _FloatingResourceLayer({required this.builder});
  final FloatingResourceWindowBuilder builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windows = ref.watch(floatingResourceWindowsProvider);
    final manager = ref.read(floatingResourceWindowsProvider.notifier);
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = MediaQuery.paddingOf(context);
        final viewport = Rect.fromLTRB(
          padding.left,
          padding.top,
          constraints.maxWidth - padding.right,
          constraints.maxHeight - padding.bottom,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) manager.setViewport(viewport);
        });
        return Stack(
          children: [
            for (final window in windows)
              Positioned.fromRect(
                key: ValueKey(window.id),
                rect: window.minimized
                    ? Rect.fromLTWH(
                        window.rect.left,
                        window.rect.top,
                        window.rect.width,
                        32,
                      )
                    : window.rect,
                child: Listener(
                  onPointerDown: (_) => manager.focus(window.id),
                  child: builder(
                    context,
                    window,
                    FloatingWindowController(manager, window.id),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Deliberately unfinished hand-off placeholder, not production window chrome.
/// Main agent replaces the host's builder. Close/minimize/search controls are
/// intentionally not drawn here; the controller exposes those callbacks.
Widget floatingResourcePlaceholder(
  BuildContext context,
  FloatingWindowData window,
  FloatingWindowController controller,
) {
  final l10n = context.l10n;
  final title = switch (window.kind) {
    FloatingResourceKind.gallery => l10n.localGallery_title,
    FloatingResourceKind.blocks => l10n.blocks_title,
    FloatingResourceKind.vibe => l10n.refs_vibeTitle,
    FloatingResourceKind.precise => l10n.refs_preciseTitle,
  };
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        controller.moveHandle(child: SizedBox(height: 32, child: Text(title))),
        if (!window.minimized) ...[
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: controller.resizeHandle(
              child: const SizedBox(width: 20, height: 20),
            ),
          ),
        ],
      ],
    ),
  );
}
